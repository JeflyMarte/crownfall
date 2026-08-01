#!/usr/bin/env python3
"""Generate 4 distinct generic accessory silhouettes (Ring / Charm / Talisman / Seal).

Plan A: shape-category generics so charms are not shown as rings.
Writes:
  assets/ui/equipment/ICO_ACC_Generic_{Ring,Charm,Talisman,Seal}.png
  assets/ui/equipment/_templates/ICO_ACC_Generic_{...}.png  (same bytes)
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets/ui/equipment"
TEMPLATE_DIR = OUT_DIR / "_templates"
SIZE = 128


def _new_canvas() -> Image.Image:
	return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def _paste_soft(base: Image.Image, layer: Image.Image) -> Image.Image:
	out = base.copy()
	out.alpha_composite(layer)
	return out


def _metal_disc(
	draw: ImageDraw.ImageDraw,
	bbox: tuple[int, int, int, int],
	fill: tuple[int, int, int, int],
	rim: tuple[int, int, int, int],
	width: int = 3,
) -> None:
	draw.ellipse(bbox, fill=fill, outline=rim, width=width)


def _shade(img: Image.Image) -> Image.Image:
	"""Soft drop-ish contrast without baking a square mat."""
	blur = img.filter(ImageFilter.GaussianBlur(0.6))
	return Image.alpha_composite(blur, img)


def make_ring() -> Image.Image:
	img = _new_canvas()
	layer = _new_canvas()
	d = ImageDraw.Draw(layer)
	# Outer band
	_metal_disc(d, (28, 28, 100, 100), (196, 168, 96, 255), (72, 52, 28, 255), 4)
	# Inner hole (transparent punch)
	d.ellipse((48, 48, 80, 80), fill=(0, 0, 0, 0))
	# Re-draw inner rim on a mask by compositing
	hole = _new_canvas()
	hd = ImageDraw.Draw(hole)
	hd.ellipse((48, 48, 80, 80), fill=(0, 0, 0, 255))
	# Punch: keep ring pixels where hole is transparent
	px = layer.load()
	hx = hole.load()
	for y in range(SIZE):
		for x in range(SIZE):
			if hx[x, y][3] > 0:
				px[x, y] = (0, 0, 0, 0)
	# Inner rim stroke
	d.ellipse((48, 48, 80, 80), outline=(92, 68, 36, 255), width=3)
	# Gem on top
	d.ellipse((56, 22, 72, 40), fill=(96, 168, 220, 255), outline=(40, 72, 110, 255), width=2)
	d.ellipse((60, 25, 67, 32), fill=(210, 236, 255, 220))
	# Highlight arc
	d.arc((34, 34, 94, 94), 200, 300, fill=(245, 230, 180, 180), width=3)
	return _shade(_paste_soft(img, layer))


def make_charm() -> Image.Image:
	img = _new_canvas()
	layer = _new_canvas()
	d = ImageDraw.Draw(layer)
	# Cord loop
	d.ellipse((54, 14, 74, 34), outline=(150, 120, 70, 255), width=4)
	# Plaque body (rounded rect via polygon-ish)
	body = [(40, 36), (88, 36), (94, 48), (90, 104), (38, 104), (34, 48)]
	d.polygon(body, fill=(178, 142, 78, 255), outline=(68, 48, 24, 255))
	# Inner plate
	d.rounded_rectangle((44, 46, 84, 96), radius=8, fill=(120, 88, 48, 255), outline=(90, 64, 32, 255), width=2)
	# Rune mark
	d.line((54, 58, 74, 58), fill=(230, 200, 120, 255), width=3)
	d.line((64, 58, 64, 86), fill=(230, 200, 120, 255), width=3)
	d.ellipse((58, 72, 70, 84), outline=(230, 200, 120, 220), width=2)
	# Highlight
	d.line((42, 42, 42, 96), fill=(240, 220, 160, 90), width=2)
	return _shade(_paste_soft(img, layer))


def make_talisman() -> Image.Image:
	img = _new_canvas()
	layer = _new_canvas()
	d = ImageDraw.Draw(layer)
	# Cord
	d.line((64, 12, 64, 28), fill=(140, 110, 70, 255), width=4)
	d.ellipse((56, 8, 72, 24), outline=(150, 120, 70, 255), width=3)
	# Crystal / fang body
	crystal = [(64, 26), (92, 70), (76, 112), (52, 112), (36, 70)]
	d.polygon(crystal, fill=(120, 170, 190, 255), outline=(40, 70, 90, 255))
	# Facet
	d.polygon([(64, 30), (84, 70), (64, 100), (48, 70)], fill=(160, 210, 230, 200))
	d.line((64, 30, 64, 100), fill=(230, 250, 255, 160), width=2)
	# Metal cap
	d.polygon([(50, 28), (78, 28), (72, 42), (56, 42)], fill=(190, 160, 90, 255), outline=(70, 50, 28, 255))
	return _shade(_paste_soft(img, layer))


def make_seal() -> Image.Image:
	img = _new_canvas()
	layer = _new_canvas()
	d = ImageDraw.Draw(layer)
	# Wax body
	_metal_disc(d, (26, 26, 102, 102), (150, 58, 58, 255), (70, 28, 28, 255), 4)
	# Inner ring
	d.ellipse((38, 38, 90, 90), outline=(210, 150, 90, 255), width=3)
	# Stamp diamond
	stamp = [(64, 44), (82, 64), (64, 84), (46, 64)]
	d.polygon(stamp, fill=(220, 180, 100, 255), outline=(90, 60, 30, 255))
	d.line((64, 50, 64, 78), fill=(90, 60, 30, 200), width=2)
	d.line((52, 64, 76, 64), fill=(90, 60, 30, 200), width=2)
	# Soft highlight
	d.arc((32, 32, 96, 96), 210, 300, fill=(255, 200, 180, 120), width=3)
	return _shade(_paste_soft(img, layer))


def main() -> None:
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	TEMPLATE_DIR.mkdir(parents=True, exist_ok=True)
	makers = {
		"Ring": make_ring,
		"Charm": make_charm,
		"Talisman": make_talisman,
		"Seal": make_seal,
	}
	for name, fn in makers.items():
		img = fn()
		fname = f"ICO_ACC_Generic_{name}.png"
		out = OUT_DIR / fname
		tpl = TEMPLATE_DIR / fname
		img.save(out, "PNG")
		img.save(tpl, "PNG")
		print(f"  wrote {out.relative_to(ROOT)} ({out.stat().st_size} bytes)")
		print(f"  wrote {tpl.relative_to(ROOT)}")


if __name__ == "__main__":
	main()
