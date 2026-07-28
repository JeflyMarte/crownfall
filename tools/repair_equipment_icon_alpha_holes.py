#!/usr/bin/env python3
"""Repair equipment icon alpha holes from over-aggressive black keying.

Dark metal often gets punched through so rarity-cell backgrounds show inside
the silhouette. This tool:

1. Morphological closing seals thin tunnels to the exterior
2. Small enclosed holes are inpainted (large openings like bow strings kept)
3. Soft mid-alpha swiss-cheese pixels are hardened
4. Crushed near-black opaque metal is lifted slightly for contrast

Usage:
  python3 tools/repair_equipment_icon_alpha_holes.py --apply
  python3 tools/repair_equipment_icon_alpha_holes.py --apply --only ValgardAntique ChronosToki
  python3 tools/repair_equipment_icon_alpha_holes.py --scan
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
EQUIP_DIR = ROOT / "assets" / "ui" / "equipment"
ALPHA_BG = 40
OPAQUE_HARD = 220

# Hand-drawn / unique art that over-keying damaged (not shared templates).
DEFAULT_ONLY = [
	"ValgardAntique",
	"ChronosToki",
	"SerdionWardPlate",
	"SeradisArchiveSeal",
	"PharosBeaconRing",
	"FrostridgeBoundarySignet",
]


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


def _binary_closing(mask: np.ndarray, radius: int) -> np.ndarray:
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


def _params_for(name: str) -> tuple[int, int]:
	"""Return (close_radius, max_hole_px). Bows keep large string gaps."""
	lower = name.lower()
	if "bow" in lower or "arrow" in lower:
		return 2, 120
	if any(k in lower for k in ("ring", "seal", "signet", "amulet", "orb", "charm")):
		return 2, 280
	if "armor" in lower or "plate" in lower or "mail" in lower:
		return 4, 900
	return 3, 400


def count_swiss(arr: np.ndarray) -> int:
	h, w = arr.shape[:2]
	n = 0
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if arr[y, x, 3] > ALPHA_BG:
				continue
			c = sum(
				int(arr[y + dy, x + dx, 3] > ALPHA_BG)
				for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1))
			)
			if c >= 3:
				n += 1
	return n


def count_enclosed(arr: np.ndarray) -> int:
	trans = arr[:, :, 3] <= ALPHA_BG
	exterior = _edge_connected(trans)
	return int((trans & ~exterior).sum())


def repair_icon(
	img: Image.Image,
	close_r: int,
	max_hole: int,
	black_lift: int = 32,
	black_th: int = 30,
) -> tuple[Image.Image, dict[str, int]]:
	a = np.array(img.convert("RGBA"), dtype=np.uint8).copy()
	h, w = a.shape[:2]
	opaque = a[:, :, 3] > ALPHA_BG
	closed = _binary_closing(opaque, close_r)
	exterior = _edge_connected(~closed)
	holes = (~closed) & (~exterior)

	labels = np.zeros((h, w), dtype=np.int32)
	cur = 0
	keep = np.zeros_like(holes)
	for y in range(h):
		for x in range(w):
			if not holes[y, x] or labels[y, x]:
				continue
			cur += 1
			q: deque[tuple[int, int]] = deque([(x, y)])
			labels[y, x] = cur
			cells = [(x, y)]
			while q:
				cx, cy = q.popleft()
				for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
					if 0 <= nx < w and 0 <= ny < h and holes[ny, nx] and labels[ny, nx] == 0:
						labels[ny, nx] = cur
						q.append((nx, ny))
						cells.append((nx, ny))
			if len(cells) <= max_hole:
				for cx, cy in cells:
					keep[cy, cx] = True

	bridge = closed & ~opaque & _dilate(opaque, close_r + 1)
	target = opaque | keep | bridge

	filled = 0
	yy, xx = np.where(target & (a[:, :, 3] <= ALPHA_BG))
	for y, x in zip(yy, xx):
		found = None
		for rad in range(1, 14):
			patch = a[
				max(0, y - rad) : min(h, y + rad + 1),
				max(0, x - rad) : min(w, x + rad + 1),
			]
			m = patch[:, :, 3] > ALPHA_BG
			if not m.any():
				continue
			mean = patch[m][:, :3].mean(axis=0)
			if mean.max() < black_th:
				mean = np.clip(mean + black_lift + 8, 0, 255)
			found = tuple(int(c) for c in mean)
			break
		a[y, x] = (*(found or (78, 64, 52)), 255)
		filled += 1

	lifted = 0
	op = a[:, :, 3] >= OPAQUE_HARD
	dark = (
		op
		& (a[:, :, 0] < black_th)
		& (a[:, :, 1] < black_th)
		& (a[:, :, 2] < black_th)
	)
	for y, x in zip(*np.where(dark)):
		patch = a[max(0, y - 2) : min(h, y + 3), max(0, x - 2) : min(w, x + 3)]
		m = patch[:, :, 3] >= OPAQUE_HARD
		mean = (
			patch[m][:, :3].mean(axis=0)
			if m.any()
			else np.array([70.0, 58.0, 48.0])
		)
		if mean.max() < black_th + 5:
			a[y, x, :3] = np.clip(a[y, x, :3].astype(int) + black_lift, 0, 255)
		else:
			a[y, x, :3] = np.clip(
				(0.3 * a[y, x, :3] + 0.7 * mean).astype(int), 0, 255
			)
		lifted += 1

	hardened = 0
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			al = int(a[y, x, 3])
			if al == 0 or al >= OPAQUE_HARD:
				continue
			cols: list[np.ndarray] = []
			n = 0
			for dy, dx in (
				(-1, 0),
				(1, 0),
				(0, -1),
				(0, 1),
				(-1, -1),
				(-1, 1),
				(1, -1),
				(1, 1),
			):
				if a[y + dy, x + dx, 3] >= 180:
					n += 1
					cols.append(a[y + dy, x + dx, :3])
			if n < 3:
				continue
			mean = np.mean(cols, axis=0)
			col = a[y, x, :3].astype(float)
			if col.max() < black_th:
				col = mean
			else:
				col = 0.4 * col + 0.6 * mean
			if col.max() < black_th:
				col = np.clip(col + black_lift, 0, 255)
			a[y, x] = (*np.clip(col, 0, 255).astype(int), 255)
			hardened += 1

	# Pepper pass: isolated transparent pixels inside solid metal.
	pepper = 0
	for _ in range(8):
		changed = 0
		out = a.copy()
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				if a[y, x, 3] > ALPHA_BG:
					continue
				cols = []
				n = 0
				for dy in (-1, 0, 1):
					for dx in (-1, 0, 1):
						if dy == 0 and dx == 0:
							continue
						if a[y + dy, x + dx, 3] > ALPHA_BG:
							n += 1
							cols.append(a[y + dy, x + dx, :3])
				if n < 5:
					continue
				mean = np.mean(cols, axis=0)
				if mean.max() < 28:
					mean = np.clip(mean + 35, 0, 255)
				out[y, x] = (*mean.astype(int), 255)
				changed += 1
		a = out
		pepper += changed
		if changed == 0:
			break

	a[exterior & ~target] = (0, 0, 0, 0)
	stats = {
		"filled": filled,
		"lifted": lifted,
		"hardened": hardened,
		"pepper": pepper,
		"opaque": int((a[:, :, 3] > ALPHA_BG).sum()),
	}
	return Image.fromarray(a, mode="RGBA"), stats


def _iter_paths(only: list[str] | None) -> list[Path]:
	paths = sorted(
		p
		for p in EQUIP_DIR.glob("ICO_*.png")
		if p.name.startswith(("ICO_WPN_", "ICO_ARM_", "ICO_ACC_"))
	)
	if only:
		paths = [p for p in paths if any(s in p.name for s in only)]
	return paths


def main() -> int:
	ap = argparse.ArgumentParser()
	ap.add_argument("--apply", action="store_true")
	ap.add_argument("--scan", action="store_true", help="Report swiss/enclosed only")
	ap.add_argument(
		"--only",
		nargs="*",
		default=None,
		help="Substring filters (default: antique/chronos + known damaged hand-drawn)",
	)
	ap.add_argument(
		"--min-swiss",
		type=int,
		default=15,
		help="Skip icons with swiss < this unless --force-all-only",
	)
	ap.add_argument(
		"--force-all-only",
		action="store_true",
		help="Repair every path matched by --only regardless of swiss score",
	)
	args = ap.parse_args()
	only = args.only if args.only is not None else DEFAULT_ONLY
	paths = _iter_paths(only)

	if args.scan:
		rows: list[tuple[int, int, str]] = []
		for path in paths:
			arr = np.array(Image.open(path).convert("RGBA"))
			sw = count_swiss(arr)
			enc = count_enclosed(arr)
			if sw >= args.min_swiss or enc >= 80:
				rows.append((sw + enc, sw, enc, path.name))
		rows.sort(reverse=True)
		for _t, sw, enc, name in rows:
			print(f"{name}: swiss={sw} enclosed={enc}")
		print(f"flagged={len(rows)}")
		return 0

	changed = 0
	for path in paths:
		src = Image.open(path)
		arr = np.array(src.convert("RGBA"))
		sw_before = count_swiss(arr)
		enc_before = count_enclosed(arr)
		if not args.force_all_only and sw_before < args.min_swiss and enc_before < 40:
			continue
		close_r, max_hole = _params_for(path.name)
		fixed, stats = repair_icon(src, close_r=close_r, max_hole=max_hole)
		arr2 = np.array(fixed)
		sw_after = count_swiss(arr2)
		enc_after = count_enclosed(arr2)
		print(
			f"{path.name}: swiss {sw_before}->{sw_after} enclosed {enc_before}->{enc_after} "
			f"filled={stats['filled']} hard={stats['hardened']} pepper={stats['pepper']} "
			f"(r={close_r}, mh={max_hole})"
		)
		if args.apply and (sw_after < sw_before or enc_after < enc_before or stats["filled"] > 0):
			fixed.save(path)
			changed += 1

	print(f"changed={changed} apply={args.apply}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
