#!/usr/bin/env python3
"""Fill Kaiwan equipment silhouette holes with dark red-black only.

Weapons / accessories: morphological closing (close4).
Armor: fill *interior* holes only (edge-connected transparency stays open)
       + fringe harden + lift crushed blacks for InvCell contrast.
Convex-hull fill is banned (ghost aura around silhouette).

Does NOT sample bright red rim pixels for fill (pink washout).
Does NOT globally brighten / wash toward pink.

Usage:
  python3 tools/fill_kaiwan_silhouette_dark.py --apply
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
EQUIP_DIR = ROOT / "assets" / "ui" / "equipment"
BACKUP = ROOT / ".cursor" / "tmp_ban" / "kaiwan_icons_before_bright"
ALPHA_BODY = 40
## バナー／InvCell 上で読める暗赤黒（ピンク禁止）。穴埋め用。
FILL_RGB = (68, 36, 40)
DARK_LUMA_MAX = 95.0
## 潰れた黒の下限（赤縁以外）。上げすぎると茶に寄るので控えめ。
CRUSHED_BLACK_FLOOR = 58


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


def _silhouette_close(body: np.ndarray, radius: int) -> np.ndarray:
	closed = _closing(body, radius)
	exterior = _edge_connected(~closed)
	return closed & ~exterior


def _interior_holes(body: np.ndarray) -> np.ndarray:
	## 外形は広げず、閉じた穴だけ返す。
	exterior = _edge_connected(~body)
	return (~body) & (~exterior)


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


def _lift_crushed_blacks(a: np.ndarray, body: np.ndarray) -> int:
	## 赤縁以外の潰れた黒だけ持ち上げ、InvCell との同化を緩和。
	rgb = a[:, :, :3].astype(np.float32)
	rim = _is_red_rim(rgb)
	mx = rgb.max(axis=2)
	need = body & (~rim) & (mx > 0) & (mx < float(CRUSHED_BLACK_FLOOR))
	lifted = 0
	ys, xs = np.where(need)
	for y, x in zip(ys, xs):
		col = rgb[y, x]
		peak = float(col.max())
		if peak < 1.0:
			a[y, x, :3] = np.array(FILL_RGB, dtype=np.uint8)
		else:
			scale = float(CRUSHED_BLACK_FLOOR) / peak
			a[y, x, :3] = np.clip(col * scale, 0, 255).astype(np.uint8)
		lifted += 1
	return lifted


def fill_icon(img: Image.Image, name: str) -> tuple[Image.Image, dict[str, int]]:
	a = np.array(img.convert("RGBA"), dtype=np.uint8).copy()
	alpha = a[:, :, 3]
	rgb = a[:, :, :3].astype(np.float32)
	body = alpha >= ALPHA_BODY
	lower = name.lower()
	if "ico_arm_" in lower:
		## 内部穴を暗赤で塞ぎ不透明化＋縁硬化＋控えめ黒持ち上げ。
		## 明るい KaiwanArmorMat が穴から透けて茶に見える事故を防ぐ。
		mode = "interior+opaque"
		need = _interior_holes(body)
	else:
		sil = _silhouette_close(body, 4)
		mode = "close4"
		need = sil & (alpha < ALPHA_BODY)

	dark_body = body & (~_is_red_rim(rgb)) & (_luma(rgb) <= DARK_LUMA_MAX)
	filled = 0
	for y, x in zip(*np.where(need)):
		found = _pick_dark_fill(a, dark_body, y, x)
		a[y, x] = (*found.astype(np.uint8), 255)
		filled += 1

	if "ico_arm_" in lower:
		## 赤縁グロー含む近傍の半透明を不透明化（明るいマット透け＝茶化け防止）。
		near = _dilate(body, 1)
		fringe = near & (a[:, :, 3] > 0) & (a[:, :, 3] < 255)
	else:
		body2 = a[:, :, 3] >= ALPHA_BODY
		fringe = (a[:, :, 3] > 0) & (a[:, :, 3] < 255) & (body2 | _dilate(body2, 1))
	hardened = 0
	for y, x in zip(*np.where(fringe)):
		col = a[y, x, :3].astype(np.float32)
		if col.max() < 8:
			col = np.array(FILL_RGB, dtype=np.float32)
		a[y, x] = (*np.clip(col, 0, 255).astype(np.uint8), 255)
		hardened += 1

	lifted = 0
	sealed = 0
	if "ico_arm_" in lower:
		body3 = a[:, :, 3] >= ALPHA_BODY
		lifted = _lift_crushed_blacks(a, body3)
		## シルエット内は完全不透明（下地マットの透け防止）。外形は広げない。
		body4 = a[:, :, 3] >= ALPHA_BODY
		ys, xs = np.where(body4 & (a[:, :, 3] < 255))
		for y, x in zip(ys, xs):
			a[y, x, 3] = 255
			sealed += 1
		## InvCell／明るいマット上で輪郭が消えないよう 1px の暗縁（ゴースト塗りではない）。
		body5 = a[:, :, 3] >= ALPHA_BODY
		ring = _dilate(body5, 1) & ~body5
		for y, x in zip(*np.where(ring)):
			a[y, x] = (22, 12, 14, 255)
			sealed += 1

	stats = {
		"filled": filled,
		"hardened": hardened,
		"plated": sealed,
		"lifted": lifted,
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
			f"hard={stats['hardened']} plate={stats.get('plated', 0)} "
			f"lift={stats.get('lifted', 0)} opaque={stats['opaque']} src={src_path.name}"
		)
		if args.apply:
			fixed.save(EQUIP_DIR / name)
			changed += 1
	print(f"changed={changed} apply={args.apply}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
