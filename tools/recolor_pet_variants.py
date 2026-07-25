#!/usr/bin/env python3
"""Recolor PET_Jack sheets for Ash / Ink companion variants (P3-PET-VARIANT-001)."""
from __future__ import annotations

import colorsys
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SHEET_DIR = ROOT / "assets/dungeon/mourngate"
ICON_DIR = ROOT / "assets/ui/chr_icons"
ANIM_DIR = ROOT / "resources/animation"
PREVIEW_DIR = Path("/tmp/crownfall_pet_variant_preview")


def clamp01(x: float) -> float:
	return 0.0 if x < 0.0 else (1.0 if x > 1.0 else x)


def rgb_to_hsl(r: int, g: int, b: int) -> tuple[float, float, float]:
	return colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)


def hsl_to_rgb(h: float, l: float, s: float) -> tuple[int, int, int]:
	r, g, b = colorsys.hls_to_rgb(h % 1.0, clamp01(l), clamp01(s))
	return int(round(r * 255)), int(round(g * 255)), int(round(b * 255))


def chroma(r: int, g: int, b: int) -> int:
	return max(r, g, b) - min(r, g, b)


def lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t


def mix_rgb(r: int, g: int, b: int, tr: int, tg: int, tb: int, t: float) -> tuple[int, int, int]:
	t = clamp01(t)
	return (
		int(round(lerp(r, tr, t))),
		int(round(lerp(g, tg, t))),
		int(round(lerp(b, tb, t))),
	)


def recolor_ash(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""灰白＋薄金の瞳。"""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	# eyes / warm accents → pale gold
	if l > 0.35 and r > g + 8 and r > b and ch >= 20:
		return (*hsl_to_rgb(0.12, clamp01(0.45 + l * 0.35), min(0.7, s + 0.2)), a)
	# fur → cool ash grey
	if ch < 35:
		if l > 0.45:
			return (*mix_rgb(r, g, b, 220, 220, 228, 0.55), a)
		if l > 0.22:
			return (*mix_rgb(r, g, b, 150, 152, 160, 0.5), a)
		return (*mix_rgb(r, g, b, 70, 72, 80, 0.45), a)
	if ch >= 12:
		return (*hsl_to_rgb(0.6, clamp01(l * 0.95), min(0.25, s * 0.4)), a)
	return (*mix_rgb(r, g, b, 180, 182, 190, 0.25), a)


def recolor_ink(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""黒＋紫の影毛。"""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	# eyes → violet
	if l > 0.35 and r > g + 8 and r > b and ch >= 20:
		return (*hsl_to_rgb(0.78, clamp01(0.4 + l * 0.35), min(0.75, s + 0.25)), a)
	if ch < 35:
		if l > 0.45:
			return (*mix_rgb(r, g, b, 90, 70, 120, 0.55), a)
		if l > 0.22:
			return (*mix_rgb(r, g, b, 40, 28, 56, 0.55), a)
		return (*mix_rgb(r, g, b, 12, 8, 22, 0.55), a)
	if ch >= 12:
		return (*hsl_to_rgb(0.75, clamp01(l * 0.75), min(0.55, s + 0.2)), a)
	return (*mix_rgb(r, g, b, 36, 24, 52, 0.3), a)


VARIANTS = {
	"Ash": recolor_ash,
	"Ink": recolor_ink,
}


def apply_recolor(src: Image.Image, fn) -> Image.Image:
	img = src.convert("RGBA")
	px = img.load()
	w, h = img.size
	out = Image.new("RGBA", (w, h))
	opx = out.load()
	for y in range(h):
		for x in range(w):
			opx[x, y] = fn(*px[x, y])
	return out


def write_tres(stem: str) -> None:
	src = ANIM_DIR / "PET_Jack.tres"
	dst = ANIM_DIR / f"PET_{stem}.tres"
	text = src.read_text(encoding="utf-8")
	text = text.replace("PET_Jack_Sheet.png", f"PET_{stem}_Sheet.png")
	dst.write_text(text, encoding="utf-8")
	print(f"wrote {dst.relative_to(ROOT)}")


def main() -> None:
	PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
	sheet = Image.open(SHEET_DIR / "PET_Jack_Sheet.png")
	icon = Image.open(ICON_DIR / "ICO_CHR_Jack.png")
	for stem, fn in VARIANTS.items():
		out = apply_recolor(sheet, fn)
		out_path = SHEET_DIR / f"PET_{stem}_Sheet.png"
		out.save(out_path, optimize=True)
		print(f"wrote {out_path.relative_to(ROOT)} size={out.size}")
		out.crop((0, 0, 96, 96)).save(PREVIEW_DIR / f"PET_{stem}.png")
		write_tres(stem)
		ico = apply_recolor(icon, fn)
		ico_path = ICON_DIR / f"ICO_CHR_{stem}.png"
		ico.save(ico_path, optimize=True)
		print(f"wrote {ico_path.relative_to(ROOT)}")
	print(f"previews → {PREVIEW_DIR}")


if __name__ == "__main__":
	main()
