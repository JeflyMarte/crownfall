#!/usr/bin/env python3
"""Bake job/pet-colored radial glow into CHR icons and helper portraits.

Recolors only the sunburst / frame-adjacent glow behind bust portraits, using
PartyLogColors hues. Character pixels are protected by a hard bust ellipse plus
non-glow body pigments. Simple whole-image modulate is intentionally avoided.

Usage:
  python3 tools/recolor_chr_icon_job_glow.py                 # dry-run → /tmp
  python3 tools/recolor_chr_icon_job_glow.py --apply         # rewrite assets
  python3 tools/recolor_chr_icon_job_glow.py --apply --ids Ald Garen helper_a
"""
from __future__ import annotations

import argparse
import colorsys
import re
import shutil
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
CHR_DIR = ROOT / "assets" / "ui" / "chr_icons"
HELPER_DIR = ROOT / "assets" / "gacha" / "portraits"
HELPER_TRES_DIRS = [
	ROOT / "resources" / "gacha_helpers",
	ROOT / "resources" / "gacha_helpers" / "_omitted",
]
IMPORTED = ROOT / ".godot" / "imported"
PREVIEW_DIR = Path("/tmp/chr_job_glow_preview")

# PartyLogColors.gd — keep in sync.
JOB_RGB: dict[str, tuple[int, int, int]] = {
	"swordsman": (0xE5, 0xB8, 0x70),
	"ranger": (0x88, 0xC0, 0xD0),
	"alchemist": (0xA3, 0xBE, 0x8C),
	"vanguard": (0xB4, 0x8E, 0xAD),
	"beast_tamer": (0xD0, 0x87, 0x70),
}
PET_RGB: dict[str, tuple[int, int, int]] = {
	"jack": (0xC4, 0xA8, 0x82),
	"ash": (0xB8, 0xB0, 0xA0),
	"ink": (0x7A, 0x6A, 0x8C),
}

CHR_TARGETS: dict[str, tuple[int, int, int]] = {
	"Ald": JOB_RGB["swordsman"],
	"Riva": JOB_RGB["ranger"],
	"Elias": JOB_RGB["alchemist"],
	"Garen": JOB_RGB["vanguard"],
	"Mirei": JOB_RGB["beast_tamer"],
	"Jack": PET_RGB["jack"],
	"Ash": PET_RGB["ash"],
	"Ink": PET_RGB["ink"],
}


def dilate(mask: np.ndarray, it: int = 1) -> np.ndarray:
	im = Image.fromarray((mask.astype(np.uint8) * 255), "L")
	for _ in range(it):
		im = im.filter(ImageFilter.MaxFilter(3))
	return np.array(im) > 128


def erode(mask: np.ndarray, it: int = 1) -> np.ndarray:
	im = Image.fromarray((mask.astype(np.uint8) * 255), "L")
	for _ in range(it):
		im = im.filter(ImageFilter.MinFilter(3))
	return np.array(im) > 128


def flood_from_border(passable: np.ndarray) -> np.ndarray:
	h, w = passable.shape
	reached = np.zeros((h, w), dtype=bool)
	stack: list[tuple[int, int]] = []
	for x in range(w):
		if passable[0, x]:
			stack.append((0, x))
		if passable[h - 1, x]:
			stack.append((h - 1, x))
	for y in range(h):
		if passable[y, 0]:
			stack.append((y, 0))
		if passable[y, w - 1]:
			stack.append((y, w - 1))
	for y, x in stack:
		reached[y, x] = True
	while stack:
		y, x = stack.pop()
		for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
			if 0 <= ny < h and 0 <= nx < w and passable[ny, nx] and not reached[ny, nx]:
				reached[ny, nx] = True
				stack.append((ny, nx))
	return reached


def rgb_to_hls_arr(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
	r = rgb[:, :, 0].astype(np.float32) / 255.0
	g = rgb[:, :, 1].astype(np.float32) / 255.0
	b = rgb[:, :, 2].astype(np.float32) / 255.0
	mx = np.maximum(np.maximum(r, g), b)
	mn = np.minimum(np.minimum(r, g), b)
	l = (mx + mn) / 2.0
	chroma = mx - mn
	s = np.zeros_like(l)
	denom = np.where(l <= 0.5, 2.0 * l, 2.0 - 2.0 * l)
	np.divide(chroma, denom, out=s, where=denom > 1e-5)
	h = np.zeros_like(l)
	safe = chroma > 1e-5
	rc = np.zeros_like(l)
	gc = np.zeros_like(l)
	bc = np.zeros_like(l)
	np.divide(mx - r, chroma, out=rc, where=safe)
	np.divide(mx - g, chroma, out=gc, where=safe)
	np.divide(mx - b, chroma, out=bc, where=safe)
	h = np.where(safe & (mx == r), (bc - gc) / 6.0, h)
	h = np.where(safe & (mx == g), (2.0 + rc - bc) / 6.0, h)
	h = np.where(safe & (mx == b), (4.0 + gc - rc) / 6.0, h)
	return np.mod(h, 1.0), l, s


def local_dark_ratio(mx: np.ndarray, win: int = 9) -> np.ndarray:
	dark = (mx <= 16).astype(np.float32)
	p = win // 2
	padded = np.pad(dark, p, mode="edge")
	integ = np.pad(padded, ((1, 0), (1, 0)), mode="constant").cumsum(0).cumsum(1)
	h, w = mx.shape
	sm = (
		integ[win : win + h, win : win + w]
		- integ[0:h, win : win + w]
		- integ[win : win + h, 0:w]
		+ integ[0:h, 0:w]
	)
	return sm / float(win * win)


def hue_near(h: np.ndarray, center: float, width: float = 0.09) -> np.ndarray:
	d = np.minimum(np.abs(h - center), 1.0 - np.abs(h - center))
	return d <= width


def build_glow_mask(arr: np.ndarray, *, recolor_frame: bool = False) -> np.ndarray:
	rgb = arr[:, :, :3]
	a = arr[:, :, 3]
	mx = rgb.max(2).astype(np.int16)
	h, l, s = rgb_to_hls_arr(rgb)
	H, W = mx.shape
	yy, xx = np.ogrid[:H, :W]
	rad = np.sqrt((yy - H * 0.42) ** 2 + (xx - W * 0.5) ** 2) / (min(H, W) * 0.5)
	dark_r = local_dark_ratio(mx, 9)

	band = np.zeros((H, W), dtype=bool)
	t = 38
	band[:t, :] = True
	band[-t:, :] = True
	band[:, :t] = True
	band[:, -t:] = True

	non_black = (a > 20) & (mx > 12)
	near_black = (a < 20) | (mx <= 12)

	# Bust hard-core: face / hair / torso must never be recolored.
	hard = ((yy - 0.48 * H) / (0.52 * H)) ** 2 + ((xx - 0.50 * W) / (0.46 * W)) ** 2 <= 1.0
	hard = erode(hard, 1)

	sample = non_black & (dark_r >= 0.22) & (s >= 0.10) & (rad >= 0.32)
	modes = [
		b / 36.0
		for b, c in Counter((h[sample] * 36).astype(int).tolist()).most_common(12)
		if c >= 400
	]
	glow_h = np.zeros((H, W), dtype=bool)
	for center in modes[:5]:
		glow_h |= hue_near(h, center, 0.09)
	glow_h |= ((h >= 0.02) & (h <= 0.17) & (s >= 0.14)) | (
		(h >= 0.45) & (h <= 0.85) & (s >= 0.08)
	)
	glow_h &= non_black & (s >= 0.07)

	body = non_black & ~glow_h
	protect = dilate(body | hard, 5)
	if recolor_frame:
		protect = protect & ~band

	passable = (near_black | glow_h) & ~protect
	bg = flood_from_border(passable)
	glow = bg & glow_h & non_black & ~protect
	glow = glow | (dilate(glow, 1) & glow_h & ~protect & (dark_r >= 0.20))
	return glow


def recolor_pixel(r: int, g: int, b: int, target: tuple[int, int, int]) -> tuple[int, int, int]:
	tr, tg, tb = [c / 255.0 for c in target]
	th, _, ts = colorsys.rgb_to_hls(tr, tg, tb)
	_, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
	nl = l
	if l < 0.14:
		nl = min(0.46, l * 1.85 + 0.05)
	if l < 0.28:
		nl = min(0.50, nl + 0.03)
	ns = min(1.0, max(s * 0.70, ts * 0.88))
	nr, ng, nb = colorsys.hls_to_rgb(th, nl, ns)
	return int(round(nr * 255)), int(round(ng * 255)), int(round(nb * 255))


def recolor_image(src: Image.Image, target: tuple[int, int, int], *, recolor_frame: bool = False) -> Image.Image:
	arr = np.array(src.convert("RGBA"))
	glow = build_glow_mask(arr, recolor_frame=recolor_frame)
	out = arr.copy()
	ys, xs = np.where(glow)
	for y, x in zip(ys, xs):
		r, g, b = map(int, out[y, x, :3])
		out[y, x, 0], out[y, x, 1], out[y, x, 2] = recolor_pixel(r, g, b, target)
	return Image.fromarray(out)


def parse_helper_jobs() -> dict[str, str]:
	jobs: dict[str, str] = {}
	for d in HELPER_TRES_DIRS:
		if not d.is_dir():
			continue
		for path in sorted(d.glob("helper_*.tres")):
			text = path.read_text(encoding="utf-8")
			m_id = re.search(r'^id\s*=\s*"([^"]+)"', text, re.M)
			m_job = re.search(r'^job_id\s*=\s*"([^"]+)"', text, re.M)
			if m_id and m_job:
				jobs[m_id.group(1)] = m_job.group(1)
	return jobs


def clear_imported(stem: str) -> int:
	if not IMPORTED.is_dir():
		return 0
	n = 0
	for p in IMPORTED.glob(f"*{stem}*"):
		p.unlink(missing_ok=True)
		n += 1
	return n


def collect_jobs(ids: list[str] | None) -> list[tuple[str, Path, tuple[int, int, int]]]:
	helper_jobs = parse_helper_jobs()
	items: list[tuple[str, Path, tuple[int, int, int]]] = []
	for name, rgb in CHR_TARGETS.items():
		key = name
		if ids and key not in ids and f"ICO_CHR_{name}" not in ids:
			continue
		path = CHR_DIR / f"ICO_CHR_{name}.png"
		if path.is_file():
			items.append((key, path, rgb))
	for hid, job in sorted(helper_jobs.items()):
		if ids and hid not in ids and f"helper_{hid}" not in ids and hid.replace("helper_", "") not in ids:
			# allow --ids helper_a
			if ids and not any(hid == i or hid.endswith(i) or i.endswith(hid) for i in ids):
				continue
		if job not in JOB_RGB:
			continue
		path = HELPER_DIR / f"ART_HELPER_{hid}.png"
		if not path.is_file():
			continue
		if ids and hid not in ids and f"ART_HELPER_{hid}" not in ids:
			continue
		items.append((hid, path, JOB_RGB[job]))
	return items


def main() -> int:
	ap = argparse.ArgumentParser(description=__doc__)
	ap.add_argument("--apply", action="store_true", help="Rewrite asset PNGs in-place")
	ap.add_argument("--ids", nargs="*", default=None, help="Subset of Ald/Garen/helper_a/...")
	ap.add_argument("--frame", action="store_true", help="Also tint perimeter frame gold")
	ap.add_argument("--preview-dir", type=Path, default=PREVIEW_DIR)
	args = ap.parse_args()

	items = collect_jobs(args.ids)
	if not items:
		print("No targets matched.")
		return 1

	args.preview_dir.mkdir(parents=True, exist_ok=True)
	print(f"targets={len(items)} apply={args.apply} frame={args.frame}")
	for key, path, rgb in items:
		src = Image.open(path)
		out = recolor_image(src, rgb, recolor_frame=args.frame)
		preview = args.preview_dir / path.name
		out.save(preview)
		# side-by-side
		s = src.convert("RGBA").resize((360, 360), Image.NEAREST)
		d = out.resize((360, 360), Image.NEAREST)
		both = Image.new("RGBA", (728, 360), (0, 0, 0, 255))
		both.paste(s, (0, 0))
		both.paste(d, (368, 0))
		both.save(args.preview_dir / f"{path.stem}_compare.png")
		if args.apply:
			# backup once beside preview
			bak = args.preview_dir / f"{path.stem}_orig.png"
			if not bak.exists():
				shutil.copy2(path, bak)
			out.save(path)
			cleared = clear_imported(path.stem)
			print(f"APPLY {path.relative_to(ROOT)} rgb={rgb} cleared_import={cleared}")
		else:
			print(f"PREVIEW {key} → {preview} rgb={rgb}")
	print(f"preview_dir={args.preview_dir}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
