#!/usr/bin/env python3
"""Fill Kaiwan equipment silhouette holes with dark red-black only.

Armor uses convex-hull fill (swiss-cheese keyed art). Weapons/accessories use
morphological closing so open crescents stay open.

Does NOT sample bright red rim pixels for fill (pink washout).
Does NOT brighten existing opaque art.

Usage:
  python3 tools/fill_kaiwan_silhouette_dark.py --apply
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.spatial import ConvexHull

ROOT = Path(__file__).resolve().parents[1]
EQUIP_DIR = ROOT / "assets" / "ui" / "equipment"
BACKUP = ROOT / ".cursor" / "tmp_ban" / "kaiwan_icons_before_bright"
ALPHA_BODY = 40
## バナー上で読める暗赤黒（ピンク禁止）
FILL_RGB = (58, 30, 34)
DARK_LUMA_MAX = 95.0


def _luma(rgb: np.ndarray) -> np.ndarray:
	return 0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]


def _is_red_rim(rgb: np.ndarray) -> np.ndarray:
	r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
	return (r > 90) & (r > g * 1.35) & (r > b * 1.2)


def _dilate(mask: np.ndarray, radius: int) -> np.ndarray:
	im = Image.fromarray((mask.astype(np.uint8) * 255))
	for _ in range(radius):
		im = im.filter(ImageFilter.MaxFilter(3))
	return np.array(im) > 127


def _erode(mask: np.ndarray, radius: int) -> np.ndarray:
	im = Image.fromarray((mask.astype(np.uint8) * 255))
	for _ in range(radius):
		im = im.filter(ImageFilter.MinFilter(3))
	return np.array(im) > 127


def _closing(mask: np.ndarray, radius: int) -> np.ndarray:
	return _erode(_dilate(mask, radius), radius)


def _edge_connected(bg_mask: np.ndarray) -> np.ndarray:
	h, w = bg_mask.shape
	seen = np.zeros_like(bg_mask, dtype=bool)
	q: deque[tuple[int, int]] = deque()
	for x in range(w):
		for y in (0, h - 1):
			if bg_mask[y, x]:
				seen[y, x] = True
				q.append((x, y))
	for y in range(h):
		for x in (0, w - 1):
			if bg_mask[y, x] and not seen[y, x]:
				seen[y, x] = True
				q.append((x, y))
	while q:
		x, y = q.popleft()
		for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
			if 0 <= nx < w and 0 <= ny < h and bg_mask[ny, nx] and not seen[ny, nx]:
				seen[ny, nx] = True
				q.append((nx, ny))
	return seen


def _silhouette_armor(body: np.ndarray) -> np.ndarray:
	ys, xs = np.where(body)
	if len(xs) < 8:
		return body
	pts = np.stack([xs, ys], axis=1)
	hull = ConvexHull(pts)
	ordered = pts[hull.vertices]
	h, w = body.shape
	mask = Image.new("L", (w, h), 0)
	ImageDraw.Draw(mask).polygon([tuple(map(int, p)) for p in ordered], fill=255)
	sil = np.array(mask) > 0
	return _dilate(sil, 1)


def _silhouette_close(body: np.ndarray, radius: int) -> np.ndarray:
	closed = _closing(body, radius)
	exterior = _edge_connected(~closed)
	return closed & ~exterior


def _pick_dark_fill(a: np.ndarray, dark_body: np.ndarray, y: int, x: int) -> np.ndarray:
	h, w = a.shape[:2]
	rgb = a[:, :, :3].astype(np.float32)
	for rad in range(1, 12):
		ys0, ys1 = max(0, y - rad), min(h, y + rad + 1)
		xs0, xs1 = max(0, x - rad), min(w, x + rad + 1)
		patch_dark = dark_body[ys0:ys1, xs0:xs1]
		if not patch_dark.any():
			continue
		cols = rgb[ys0:ys1, xs0:xs1][patch_dark]
		found = np.percentile(cols, 35, axis=0)
		if found[0] > 110 and found[0] > found[1] * 1.3:
			return np.array(FILL_RGB, dtype=np.float32)
		return np.clip(found, 0, 90)
	return np.array(FILL_RGB, dtype=np.float32)


def fill_icon(img: Image.Image, name: str) -> tuple[Image.Image, dict[str, int]]:
	a = np.array(img.convert("RGBA"), dtype=np.uint8).copy()
	alpha = a[:, :, 3]
	rgb = a[:, :, :3].astype(np.float32)
	body = alpha >= ALPHA_BODY
	lower = name.lower()
	if "ico_arm_" in lower:
		sil = _silhouette_armor(body)
		mode = "convex"
	elif "ico_acc_" in lower:
		sil = _silhouette_close(body, 4)
		mode = "close4"
	else:
		sil = _silhouette_close(body, 4)
		mode = "close4"

	dark_body = body & (~_is_red_rim(rgb)) & (_luma(rgb) <= DARK_LUMA_MAX)
	need = sil & (alpha < ALPHA_BODY)
	filled = 0
	for y, x in zip(*np.where(need)):
		found = _pick_dark_fill(a, dark_body, y, x)
		a[y, x] = (*found.astype(np.uint8), 255)
		filled += 1

	fringe = sil & (a[:, :, 3] > 0) & (a[:, :, 3] < 255)
	hardened = 0
	for y, x in zip(*np.where(fringe)):
		col = a[y, x, :3].astype(np.float32)
		if col.max() < 8:
			col = np.array(FILL_RGB, dtype=np.float32)
		a[y, x] = (*np.clip(col, 0, 255).astype(np.uint8), 255)
		hardened += 1

	stats = {
		"filled": filled,
		"hardened": hardened,
		"opaque": int((a[:, :, 3] >= ALPHA_BODY).sum()),
		"mode": mode,
	}
	return Image.fromarray(a, mode="RGBA"), stats


def _source_path(name: str) -> Path:
	bak = BACKUP / name
	if bak.is_file():
		return bak
	return EQUIP_DIR / name


def main() -> int:
	ap = argparse.ArgumentParser()
	ap.add_argument("--apply", action="store_true")
	args = ap.parse_args()
	names = sorted(p.name for p in EQUIP_DIR.glob("ICO_*Kaiwan*.png"))
	if not names and BACKUP.is_dir():
		names = sorted(p.name for p in BACKUP.glob("ICO_*Kaiwan*.png"))
	changed = 0
	for name in names:
		src_path = _source_path(name)
		src = Image.open(src_path)
		fixed, stats = fill_icon(src, name)
		print(
			f"{name}: mode={stats['mode']} filled={stats['filled']} "
			f"hard={stats['hardened']} opaque={stats['opaque']} src={src_path.name}"
		)
		if args.apply:
			fixed.save(EQUIP_DIR / name)
			changed += 1
	print(f"changed={changed} apply={args.apply}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
