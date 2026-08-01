#!/usr/bin/env python3
"""Strip baked ornate frames from CHR icons (案A).

Ald / Garen icons shipped with a decorative perimeter frame baked into the PNG.
Other starters / pets are frameless; roster UI already supplies chrome, so the
baked frame makes only those two look framed.

Garen's frame may already be job-tint purple after P3-UI-CHR-GLOW-JOB-001.

Only border-connected / corner-geometry frame pixels are erased so character
gold (lion crest, rim light) is preserved.

Usage:
  python3 tools/strip_chr_icon_frames.py              # dry-run preview
  python3 tools/strip_chr_icon_frames.py --apply      # rewrite PNGs
  python3 tools/strip_chr_icon_frames.py --apply --ids Ald Garen
"""
from __future__ import annotations

import argparse
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
CHR_DIR = ROOT / "assets" / "ui" / "chr_icons"
IMPORTED = ROOT / ".godot" / "imported"
PREVIEW_DIR = Path("/tmp/chr_strip_frame")

DEFAULT_IDS = ("Ald", "Garen")
RING = 40
CORNER = 155
OUTER_RING = 34


def dilate(mask: np.ndarray, it: int = 1) -> np.ndarray:
	im = Image.fromarray((mask.astype(np.uint8) * 255), "L")
	for _ in range(it):
		im = im.filter(ImageFilter.MaxFilter(3))
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


def frame_like(rgb: np.ndarray, a: np.ndarray) -> np.ndarray:
	r = rgb[:, :, 0].astype(np.int16)
	g = rgb[:, :, 1].astype(np.int16)
	b = rgb[:, :, 2].astype(np.int16)
	mx = np.maximum(np.maximum(r, g), b)
	mn = np.minimum(np.minimum(r, g), b)
	ch = mx - mn
	ok = (a > 8) | (mx > 20)
	gold = ok & (r >= 55) & (r >= g - 40) & (r > b) & (mx >= 28) & (ch >= 8) & (b <= 210)
	cream = ok & (r >= 200) & (g >= 170) & (b >= 140) & (r >= b) & (ch >= 8)
	purple = (
		ok
		& (ch >= 10)
		& (mx >= 24)
		& (g < np.maximum(r, b) * 0.92)
		& (((b >= 35) & (r >= 30)) | ((r >= 70) & (b >= 50)))
	)
	dark = ok & (mx >= 8) & (mx <= 120) & (ch >= 4)
	return gold | cream | purple | dark


def purple_crumb(rgb: np.ndarray, a: np.ndarray) -> np.ndarray:
	r = rgb[:, :, 0].astype(np.int16)
	g = rgb[:, :, 1].astype(np.int16)
	b = rgb[:, :, 2].astype(np.int16)
	mx = np.maximum(np.maximum(r, g), b)
	mn = np.minimum(np.minimum(r, g), b)
	ch = mx - mn
	return (
		((a > 8) | (mx > 20))
		& (ch >= 8)
		& (mx >= 18)
		& (b + 10 >= g)
		& (r + 10 >= g)
		& (g < np.maximum(r, b) * 0.92)
		& ~((r > g + 20) & (r > b + 20))
	)


def corner_flourish_mask(h: int, w: int, c: int = 140, diag: int = 200) -> np.ndarray:
	yy, xx = np.ogrid[:h, :w]
	m = np.zeros((h, w), dtype=bool)
	m |= (xx < c) & (yy < c) & ((xx + yy) < diag)
	m |= (xx >= w - c) & (yy < c) & (((w - 1 - xx) + yy) < diag)
	m |= (xx < c) & (yy >= h - c) & ((xx + (h - 1 - yy)) < diag)
	m |= (xx >= w - c) & (yy >= h - c) & (((w - 1 - xx) + (h - 1 - yy)) < diag)
	return m


def strip_frame(src: Image.Image) -> tuple[Image.Image, int]:
	arr = np.array(src.convert("RGBA"))
	h, w = arr.shape[:2]
	rgb = arr[:, :, :3]
	a = arr[:, :, 3]
	mx = rgb.max(2)
	near_black = ((a < 20) & (mx <= 12)) | ((a >= 20) & (mx <= 8))
	fl = frame_like(rgb, a)

	peri = np.zeros((h, w), dtype=bool)
	peri[:RING, :] = True
	peri[-RING:, :] = True
	peri[:, :RING] = True
	peri[:, -RING:] = True
	peri[:CORNER, :CORNER] = True
	peri[:CORNER, -CORNER:] = True
	peri[-CORNER:, :CORNER] = True
	peri[-CORNER:, -CORNER:] = True

	passable = near_black | (fl & peri)
	reached = flood_from_border(passable)
	erase = reached & fl & peri
	erase = erase | (peri & dilate(erase, 2) & fl)

	ring = np.zeros((h, w), dtype=bool)
	ring[:OUTER_RING, :] = True
	ring[-OUTER_RING:, :] = True
	ring[:, :OUTER_RING] = True
	ring[:, -OUTER_RING:] = True
	erase = erase | (ring & fl)

	corn = corner_flourish_mask(h, w)
	erase = erase | (corn & fl) | (corn & purple_crumb(rgb, a))

	out = arr.copy()
	## 透過で消す（不透明黒だとセル／灰色UI上に黒四角が残る）。
	out[erase] = (0, 0, 0, 0)
	junk = peri & (a < 40) & (mx > 5)
	out[junk] = (0, 0, 0, 0)

	pur = purple_crumb(out[:, :, :3], out[:, :, 3])
	near2 = (out[:, :, 3] < 20) | (out[:, :, :3].max(2) <= 8)
	pass2 = near2 | (pur & peri)
	reached2 = flood_from_border(pass2)
	erase2 = reached2 & pur & peri
	erase2 = erase2 | (peri & dilate(erase2, 2) & pur) | (ring & pur) | (corn & pur)
	out[erase2] = (0, 0, 0, 0)
	return Image.fromarray(out), int(erase.sum() + erase2.sum() + junk.sum())


def clear_imported(stem: str) -> int:
	if not IMPORTED.is_dir():
		return 0
	n = 0
	for p in IMPORTED.glob(f"*{stem}*"):
		p.unlink(missing_ok=True)
		n += 1
	return n


def main() -> int:
	ap = argparse.ArgumentParser(description=__doc__)
	ap.add_argument("--apply", action="store_true")
	ap.add_argument("--ids", nargs="*", default=list(DEFAULT_IDS))
	ap.add_argument("--preview-dir", type=Path, default=PREVIEW_DIR)
	args = ap.parse_args()

	args.preview_dir.mkdir(parents=True, exist_ok=True)
	for name in args.ids:
		path = CHR_DIR / f"ICO_CHR_{name}.png"
		if not path.is_file():
			print(f"SKIP missing {path}")
			continue
		src = Image.open(path)
		out, n = strip_frame(src)
		preview = args.preview_dir / f"{name}_stripped.png"
		out.save(preview)
		s = src.convert("RGBA").resize((360, 360), Image.NEAREST)
		d = out.resize((360, 360), Image.NEAREST)
		both = Image.new("RGBA", (728, 360), (0, 0, 0, 255))
		both.paste(s, (0, 0))
		both.paste(d, (368, 0))
		both.save(args.preview_dir / f"{name}_compare.png")
		if args.apply:
			bak = args.preview_dir / f"{name}_orig.png"
			if not bak.exists():
				shutil.copy2(path, bak)
			out.save(path)
			cleared = clear_imported(path.stem)
			print(f"APPLY {path.relative_to(ROOT)} erased≈{n} cleared_import={cleared}")
		else:
			print(f"PREVIEW {name} erased≈{n} → {preview}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
