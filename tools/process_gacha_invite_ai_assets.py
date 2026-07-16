#!/usr/bin/env python3
"""Key chroma-green AI invite sources → assets/ui/gacha_ui/UI_Gacha_Invite_*.png

Usage:
  python3 tools/process_gacha_invite_ai_assets.py \\
    --src-dir /path/to/sources
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/gacha_ui"

# Pure chroma green and near-green fringe.
GREEN_MIN_G = 140
GREEN_DOMINANCE = 35


def key_chroma_green(img: Image.Image) -> Image.Image:
	img = img.convert("RGBA")
	px = img.load()
	w, h = img.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			# Strong green screen
			if g >= GREEN_MIN_G and g > r + GREEN_DOMINANCE and g > b + GREEN_DOMINANCE:
				px[x, y] = (0, 0, 0, 0)
				continue
			# Soft fringe (greenish spill)
			if g > r + 20 and g > b + 20 and g >= 90:
				spill = min(255, (g - max(r, b)) * 3)
				na = max(0, a - spill)
				if na < 16:
					px[x, y] = (0, 0, 0, 0)
				else:
					# Despill toward parchment-neutral
					ng = min(g, max(r, b) + 8)
					px[x, y] = (r, ng, b, na)
	return img


def trim_alpha(img: Image.Image, pad: int = 8) -> Image.Image:
	bbox = img.getbbox()
	if bbox is None:
		return img
	x0, y0, x1, y1 = bbox
	x0 = max(0, x0 - pad)
	y0 = max(0, y0 - pad)
	x1 = min(img.size[0], x1 + pad)
	y1 = min(img.size[1], y1 + pad)
	return img.crop((x0, y0, x1, y1))


def fit_canvas(img: Image.Image, size: tuple[int, int]) -> Image.Image:
	tw, th = size
	img = img.convert("RGBA")
	img.thumbnail((tw - 8, th - 8), Image.Resampling.LANCZOS)
	canvas = Image.new("RGBA", size, (0, 0, 0, 0))
	x = (tw - img.size[0]) // 2
	y = (th - img.size[1]) // 2
	canvas.paste(img, (x, y), img)
	return canvas


def process_letter(src: Path, out_name: str, size: tuple[int, int]) -> None:
	raw = Image.open(src)
	cut = key_chroma_green(raw)
	cut = trim_alpha(cut, pad=10)
	# Light smooth for jagged key edges
	cut = cut.filter(ImageFilter.SMOOTH)
	out = fit_canvas(cut, size)
	OUT.mkdir(parents=True, exist_ok=True)
	path = OUT / out_name
	out.save(path, optimize=True)
	print(f"wrote {path} ({out.size[0]}x{out.size[1]}) from {src.name}")


def process_glow(src: Path, out_name: str, size: tuple[int, int] = (360, 360)) -> None:
	raw = Image.open(src).convert("RGBA")
	cut = key_chroma_green(raw)
	# Rebuild as soft radial if key left little (fallback)
	if cut.getbbox() is None or _opaque_ratio(cut) < 0.02:
		cut = _synth_glow(size)
	else:
		cut = trim_alpha(cut, pad=4)
		cut = fit_canvas(cut, size)
		# Boost alpha falloff cleanliness
		px = cut.load()
		cx, cy = size[0] / 2, size[1] / 2
		max_r = min(size) * 0.48
		for y in range(size[1]):
			for x in range(size[0]):
				r, g, b, a = px[x, y]
				if a == 0:
					continue
				import math

				d = math.hypot(x - cx, y - cy) / max_r
				if d >= 1.0:
					px[x, y] = (0, 0, 0, 0)
				else:
					fa = int((1.0 - d) ** 1.6 * min(a, 200))
					px[x, y] = (255, min(220, g + 40), min(160, b + 20), fa)
	path = OUT / out_name
	cut.save(path, optimize=True)
	print(f"wrote {path} ({cut.size[0]}x{cut.size[1]}) glow")


def _opaque_ratio(img: Image.Image) -> float:
	px = img.load()
	w, h = img.size
	n = 0
	for y in range(h):
		for x in range(w):
			if px[x, y][3] > 16:
				n += 1
	return n / float(w * h)


def _synth_glow(size: tuple[int, int]) -> Image.Image:
	import math

	w, h = size
	img = Image.new("RGBA", size, (0, 0, 0, 0))
	px = img.load()
	cx, cy = w / 2, h / 2
	max_r = min(w, h) * 0.48
	for y in range(h):
		for x in range(w):
			d = math.hypot(x - cx, y - cy) / max_r
			if d >= 1.0:
				continue
			a = int((1.0 - d) ** 2 * 180)
			px[x, y] = (255, 190, 90, a)
	return img.filter(ImageFilter.GaussianBlur(radius=8))


def main() -> None:
	ap = argparse.ArgumentParser()
	ap.add_argument(
		"--src-dir",
		type=Path,
		default=Path("/Users/marte/.local/share/cursor-agent/artifacts/assets"),
	)
	args = ap.parse_args()
	src = args.src_dir
	process_letter(src / "invite_src_sealed_star3.png", "UI_Gacha_Invite_Sealed.png", (320, 220))
	process_letter(src / "invite_src_sealed_star2.png", "UI_Gacha_Invite_Sealed_Star2.png", (320, 220))
	process_letter(src / "invite_src_opening.png", "UI_Gacha_Invite_Opening.png", (320, 240))
	process_glow(src / "invite_src_glow.png", "UI_Gacha_Invite_Glow.png", (360, 360))
	# Keep OpenFrame / SealShard from procedural generator if present; regenerate frame lightly from sealed
	sealed = OUT / "UI_Gacha_Invite_Sealed.png"
	if sealed.exists():
		# Soften open-frame: reuse sealed as decorative border plate (no hole cut — portrait sits above)
		frame = Image.open(sealed).convert("RGBA")
		# Slightly taller canvas for portrait phase optional use
		tall = fit_canvas(frame, (280, 300))
		tall.save(OUT / "UI_Gacha_Invite_OpenFrame.png", optimize=True)
		print(f"wrote {OUT / 'UI_Gacha_Invite_OpenFrame.png'} (from sealed)")


if __name__ == "__main__":
	main()
