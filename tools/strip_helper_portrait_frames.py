#!/usr/bin/env python3
"""Strip baked decorative gold frames from ART_HELPER portraits (案A).

Some helper portraits shipped with an ornate gold/bronze border baked into the
PNG. Roster / gacha UI already provide their own chrome, so the baked frame
makes only those helpers look "framed".

Strategies:
  - Opaque black-margin portraits (helper_g/h/j): detect the gold rectangle
    adjacent to the outer black margin and erase gold on that perimeter only.
  - Transparent-margin portraits (helper_m): erase gold on the bottom bar and
    four corner boxes only (no flood into character gold).

Usage:
  python3 tools/strip_helper_portrait_frames.py            # dry-run report
  python3 tools/strip_helper_portrait_frames.py --apply    # rewrite PNGs
  python3 tools/strip_helper_portrait_frames.py --apply --ids helper_m helper_g
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PORTRAIT_ROOT = ROOT / "assets" / "gacha" / "portraits"
IMPORTED = ROOT / ".godot" / "imported"

INSET_MIN = 12
INSET_MAX = 32
PERIMETER_THICKNESS = 18
CORNER_BOX = 110
BOTTOM_BAR = 56
TOP_BAR = 48


def is_frame_color(r: int, g: int, b: int, a: int) -> bool:
	if a < 40:
		return False
	if max(r, g, b) < 60:
		return False
	# Include bright metallic highlights (g can exceed 200).
	if r >= 85 and 40 <= g <= 255 and b <= 160 and r > b + 20 and r >= g - 40:
		return True
	if 65 <= r <= 150 and 35 <= g <= 110 and b <= 75 and r > g >= b - 5:
		return True
	return False


def is_frame_outline(r: int, g: int, b: int, a: int) -> bool:
	"""Dark brown anti-alias / shadow that hugs the gold frame."""
	if a < 40:
		return False
	m = max(r, g, b)
	if m < 18 or m > 85:
		return False
	return r >= g >= b and r >= b + 8 and b <= 40


def is_outer_margin(r: int, g: int, b: int, a: int) -> bool:
	if a < 40:
		return True
	return max(r, g, b) <= 8


def side_gold_ratios(px, w: int, h: int, inset: int, step: int = 3) -> dict[str, float]:
	sides = {"top": [], "bottom": [], "left": [], "right": []}
	for x in range(inset, w - inset, step):
		sides["top"].append(px[x, inset])
		sides["bottom"].append(px[x, h - 1 - inset])
	for y in range(inset, h - inset, step):
		sides["left"].append(px[inset, y])
		sides["right"].append(px[w - 1 - inset, y])
	out: dict[str, float] = {}
	for name, samples in sides.items():
		if not samples:
			out[name] = 0.0
			continue
		gold = sum(1 for r, g, b, a in samples if is_frame_color(r, g, b, a))
		out[name] = gold / len(samples)
	return out


def looks_like_frame(sides: dict[str, float]) -> bool:
	top = sides["top"]
	bottom = sides["bottom"]
	left = sides["left"]
	right = sides["right"]
	if top >= 0.15 and bottom >= 0.15:
		return True
	if bottom >= 0.45 and max(left, right) >= 0.12:
		return True
	return False


def detect_frame_inset(px, w: int, h: int) -> tuple[int, float, dict[str, float]] | None:
	best_inset = -1
	best_score = 0.0
	best_sides: dict[str, float] = {}
	for inset in range(INSET_MIN, INSET_MAX + 1):
		sides = side_gold_ratios(px, w, h, inset)
		if not looks_like_frame(sides):
			continue
		score = sides["top"] + sides["bottom"] + 0.5 * (sides["left"] + sides["right"])
		if score > best_score:
			best_score = score
			best_inset = inset
			best_sides = sides
	if best_inset < 0:
		return None
	return best_inset, best_score / 2.0, best_sides


def outer_fill_color(px, w: int, h: int) -> tuple[int, int, int, int]:
	edge = []
	for x in range(0, w, 16):
		edge.append(px[x, 0])
		edge.append(px[x, h - 1])
	for y in range(0, h, 16):
		edge.append(px[0, y])
		edge.append(px[w - 1, y])
	trans = sum(1 for _r, _g, _b, a in edge if a < 40)
	if trans >= len(edge) // 2:
		return (0, 0, 0, 0)
	return (0, 0, 0, 255)


def find_rect_frame(px, w: int, h: int) -> tuple[int, int, int, int] | None:
	"""Return (left, top, right, bottom) of gold bars adjacent to black margin."""
	# Top: first row with strong gold across the middle third.
	top = -1
	for y in range(0, min(h // 3, 80)):
		gold = 0
		total = 0
		for x in range(w // 4, 3 * w // 4, 2):
			total += 1
			if is_frame_color(*px[x, y]):
				gold += 1
		if total and gold / total >= 0.25:
			top = y
			break
	bottom = -1
	for y in range(h - 1, max(h - 80, 2 * h // 3), -1):
		gold = 0
		total = 0
		for x in range(w // 4, 3 * w // 4, 2):
			total += 1
			if is_frame_color(*px[x, y]):
				gold += 1
		if total and gold / total >= 0.25:
			bottom = y
			break
	def _outside_is_margin(x: int, toward: int) -> bool:
		"""True if pixels just outside this column are black/near-black margin.

		Frame anti-alias can sit between pure black and the gold bar, so check
		a few columns outward and allow slightly brighter near-black.
		"""
		for step in (1, 2, 3, 4, 5):
			ox = x + toward * step
			if not (0 <= ox < w):
				return True
			dark = 0
			total = 0
			for y in range(h // 6, 5 * h // 6, 8):
				total += 1
				r, g, b, a = px[ox, y]
				if a < 40 or max(r, g, b) <= 28:
					dark += 1
			if total and dark / total >= 0.7:
				return True
		return False

	# Left/right: first column with a tall thin gold run next to margin.
	left = -1
	for x in range(0, w // 2):
		gold_rows = 0
		for y in range(h // 6, 5 * h // 6, 2):
			if is_frame_color(*px[x, y]):
				gold_rows += 1
		if gold_rows >= 80 and _outside_is_margin(x, -1):
			left = x
			break
	right = -1
	for x in range(w - 1, w // 2, -1):
		gold_rows = 0
		for y in range(h // 6, 5 * h // 6, 2):
			if is_frame_color(*px[x, y]):
				gold_rows += 1
		if gold_rows >= 80 and _outside_is_margin(x, 1):
			right = x
			break
	if min(top, bottom, left, right) < 0:
		return None
	if right - left < w // 3 or bottom - top < h // 3:
		return None
	return left, top, right, bottom


def mask_rect_perimeter(px, w: int, h: int, rect: tuple[int, int, int, int]) -> list[list[bool]]:
	left, top, right, bottom = rect
	t = PERIMETER_THICKNESS
	keep = [[False] * w for _ in range(h)]
	for y in range(h):
		for x in range(w):
			on_left = abs(x - left) <= t and top - t <= y <= bottom + t
			on_right = abs(x - right) <= t and top - t <= y <= bottom + t
			on_top = abs(y - top) <= t and left - t <= x <= right + t
			on_bottom = abs(y - bottom) <= t and left - t <= x <= right + t
			if not (on_left or on_right or on_top or on_bottom):
				continue
			r, g, b, a = px[x, y]
			if is_frame_color(r, g, b, a) or is_frame_outline(r, g, b, a):
				keep[y][x] = True
	# Corner flourish boxes (slightly larger).
	c = max(CORNER_BOX, t + 24)
	corners = (
		(left, top),
		(right, top),
		(left, bottom),
		(right, bottom),
	)
	for cx, cy in corners:
		x0 = max(0, cx - c)
		x1 = min(w, cx + c + 1)
		y0 = max(0, cy - c)
		y1 = min(h, cy + c + 1)
		for y in range(y0, y1):
			for x in range(x0, x1):
				r, g, b, a = px[x, y]
				if is_frame_color(r, g, b, a) or is_frame_outline(r, g, b, a):
					keep[y][x] = True
	return keep


def _near_outer_margin(px, w: int, h: int, x: int, y: int, radius: int = 2) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			nx, ny = x + dx, y + dy
			if 0 <= nx < w and 0 <= ny < h and is_outer_margin(*px[nx, ny]):
				return True
	return False


def mask_transparent_bottom_corners(px, w: int, h: int) -> list[list[bool]]:
	"""helper_m style: bottom bar + corner flourishes only."""
	keep = [[False] * w for _ in range(h)]
	for y in range(h - BOTTOM_BAR, h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if is_frame_color(r, g, b, a):
				keep[y][x] = True
			elif is_frame_outline(r, g, b, a) and (
				y >= h - 20 or _near_outer_margin(px, w, h, x, y)
			):
				keep[y][x] = True
	for y in range(0, TOP_BAR):
		for x in range(w):
			r, g, b, a = px[x, y]
			if is_frame_color(r, g, b, a):
				keep[y][x] = True
			elif is_frame_outline(r, g, b, a) and (
				y < 16 or _near_outer_margin(px, w, h, x, y)
			):
				keep[y][x] = True
	c = CORNER_BOX
	for y in range(h):
		for x in range(w):
			in_corner = (x < c or x >= w - c) and (y < c or y >= h - c)
			if not in_corner:
				continue
			r, g, b, a = px[x, y]
			if is_frame_color(r, g, b, a):
				keep[y][x] = True
			elif is_frame_outline(r, g, b, a) and _near_outer_margin(px, w, h, x, y):
				keep[y][x] = True
	return keep


def collect_frame_mask(px, w: int, h: int, fill: tuple[int, int, int, int]) -> tuple[list[list[bool]], str]:
	if fill[3] == 0:
		return mask_transparent_bottom_corners(px, w, h), "transparent_corners"
	rect = find_rect_frame(px, w, h)
	if rect is None:
		# Fallback: top/bottom bars near edge + corner boxes.
		return mask_transparent_bottom_corners(px, w, h), "fallback_bars"
	return mask_rect_perimeter(px, w, h, rect), f"rect{rect}"


def strip_frame(img: Image.Image) -> tuple[Image.Image, dict]:
	src = img.convert("RGBA")
	w, h = src.size
	px = src.load()
	detected = detect_frame_inset(px, w, h)
	if detected is None:
		return src, {"changed": False, "reason": "no_ring"}
	inset, ratio, sides = detected
	fill = outer_fill_color(px, w, h)
	mask, strategy = collect_frame_mask(px, w, h, fill)
	removed = 0
	out = src.copy()
	opx = out.load()
	for y in range(h):
		for x in range(w):
			if not mask[y][x]:
				continue
			opx[x, y] = fill
			removed += 1
	return out, {
		"changed": removed > 0,
		"inset": inset,
		"ratio": round(ratio, 3),
		"sides": {k: round(v, 3) for k, v in sides.items()},
		"removed": removed,
		"fill": fill,
		"strategy": strategy,
	}


def clear_imported_cache(png_name: str) -> int:
	if not IMPORTED.is_dir():
		return 0
	n = 0
	for p in IMPORTED.glob(f"{png_name}-*"):
		p.unlink(missing_ok=True)
		n += 1
	return n


def main() -> int:
	ap = argparse.ArgumentParser(description=__doc__)
	ap.add_argument("--apply", action="store_true", help="Rewrite PNGs in place")
	ap.add_argument("--ids", nargs="*", default=[])
	ap.add_argument("--preview-dir", type=Path, default=None)
	args = ap.parse_args()

	if args.ids:
		paths = [PORTRAIT_ROOT / f"ART_HELPER_{hid}.png" for hid in args.ids]
	else:
		paths = sorted(PORTRAIT_ROOT.glob("ART_HELPER_*.png"))

	if args.preview_dir is not None:
		args.preview_dir.mkdir(parents=True, exist_ok=True)

	changed_any = False
	for path in paths:
		if not path.is_file():
			print(f"MISS  {path.name}")
			continue
		img = Image.open(path)
		out, info = strip_frame(img)
		if not info.get("changed"):
			print(f"SKIP  {path.name} ({info.get('reason', 'unchanged')})")
			continue
		print(
			f"{'APPLY' if args.apply else 'NEED '} {path.name} "
			f"inset={info['inset']} strategy={info['strategy']} "
			f"removed={info['removed']} fill={info['fill']}"
		)
		if args.preview_dir is not None:
			img.convert("RGBA").resize((160, 160), Image.LANCZOS).save(
				args.preview_dir / f"{path.stem}_before.png"
			)
			out.resize((160, 160), Image.LANCZOS).save(args.preview_dir / f"{path.stem}_after.png")
		if args.apply:
			out.save(path, format="PNG", optimize=True)
			cleared = clear_imported_cache(path.name)
			print(f"  wrote {path.relative_to(ROOT)} (cleared {cleared} import cache)")
			changed_any = True

	if not args.apply:
		print("Dry-run only. Re-run with --apply to rewrite.")
	elif not changed_any:
		print("Nothing applied.")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
