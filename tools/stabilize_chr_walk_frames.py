#!/usr/bin/env python3
"""Stabilize combat walk PNGs by cancelling baked horizontal root motion.

Combat locks AnimatedSprite2D offset from idle/walk frame 0. Frames whose
torso drifts left/right inside the canvas look like they slide in place.

This tool translates each walk_*.png so torso center X matches frame 0.
Vertical foot Y is left alone (bob preserved). Canvas size is unchanged.

Usage:
  python3 tools/stabilize_chr_walk_frames.py helper_n
  python3 tools/stabilize_chr_walk_frames.py helper_n --dry-run
"""

from __future__ import annotations

import argparse
import glob
import os
import sys

from PIL import Image

ALPHA_MIN = 16
TORSO_FRAC = 0.55  # upper portion of used rect = torso (ignore swinging limbs)


def used_bounds(im: Image.Image) -> tuple[int, int, int, int] | None:
	px = im.load()
	w, h = im.size
	x0, y0, x1, y1 = w, h, 0, 0
	found = False
	for y in range(h):
		for x in range(w):
			if px[x, y][3] > ALPHA_MIN:
				found = True
				if x < x0:
					x0 = x
				if y < y0:
					y0 = y
				if x >= x1:
					x1 = x + 1
				if y >= y1:
					y1 = y + 1
	if not found:
		return None
	return x0, y0, x1, y1


def torso_cx(im: Image.Image) -> float | None:
	bounds = used_bounds(im)
	if bounds is None:
		return None
	x0, y0, x1, y1 = bounds
	y_cut = y0 + int((y1 - y0) * TORSO_FRAC)
	px = im.load()
	sx = 0
	cnt = 0
	for y in range(y0, y_cut + 1):
		for x in range(x0, x1):
			if px[x, y][3] > ALPHA_MIN:
				sx += x
				cnt += 1
	if cnt == 0:
		return float(x0 + x1) * 0.5
	return sx / cnt


def blit_shifted(src: Image.Image, dx: int) -> Image.Image:
	"""Copy src onto transparent canvas of same size, shifted by dx (pixels)."""
	w, h = src.size
	out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	# Paste with negative offset: PIL paste clips automatically.
	out.paste(src, (dx, 0))
	return out


def stabilize_folder(folder: str, dry_run: bool) -> int:
	paths = sorted(glob.glob(os.path.join(folder, "walk_*.png")))
	if not paths:
		print(f"no walk frames: {folder}", file=sys.stderr)
		return 1
	images = [Image.open(p).convert("RGBA") for p in paths]
	ref = torso_cx(images[0])
	if ref is None:
		print(f"empty frame 0: {paths[0]}", file=sys.stderr)
		return 1
	print(f"{folder}: {len(paths)} frames, ref torso_cx={ref:.1f}")
	max_abs = 0.0
	for i, (path, im) in enumerate(zip(paths, images)):
		cx = torso_cx(im)
		if cx is None:
			print(f"  skip empty {os.path.basename(path)}")
			continue
		dx = int(round(ref - cx))
		max_abs = max(max_abs, abs(ref - cx))
		print(f"  {os.path.basename(path)}: torso_cx={cx:.1f} dx={dx:+d}")
		if dx == 0:
			continue
		out = blit_shifted(im, dx)
		if dry_run:
			continue
		out.save(path)
	print(f"max |drift| before={max_abs:.1f}px dry_run={dry_run}")
	return 0


def main() -> int:
	ap = argparse.ArgumentParser(description=__doc__)
	ap.add_argument(
		"folder_id",
		help="Character folder under assets/characters/ (e.g. helper_n)",
	)
	ap.add_argument("--dry-run", action="store_true")
	args = ap.parse_args()
	root = os.path.join(
		os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
		"assets",
		"characters",
		args.folder_id,
	)
	if not os.path.isdir(root):
		print(f"missing folder: {root}", file=sys.stderr)
		return 1
	return stabilize_folder(root, args.dry_run)


if __name__ == "__main__":
	raise SystemExit(main())
