#!/usr/bin/env python3
"""Chroma-key mythic equipment icons + cyan inv cell → assets/ui/

Usage:
  python3 tools/process_mythic_equipment_assets.py --src-dir PATH
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
EQ = ROOT / "assets/ui/equipment"
EQ_UI = ROOT / "assets/ui/equipment_ui"


def key_green(img: Image.Image) -> Image.Image:
	img = img.convert("RGBA")
	px = img.load()
	w, h = img.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			if g >= 140 and g > r + 35 and g > b + 35:
				px[x, y] = (0, 0, 0, 0)
				continue
			if g > r + 18 and g > b + 18 and g >= 90:
				spill = min(255, (g - max(r, b)) * 3)
				na = max(0, a - spill)
				px[x, y] = (0, 0, 0, 0) if na < 16 else (r, min(g, max(r, b) + 8), b, na)
	return img


def trim(img: Image.Image, pad: int = 4) -> Image.Image:
	bbox = img.getbbox()
	if bbox is None:
		return img
	x0, y0, x1, y1 = bbox
	return img.crop((max(0, x0 - pad), max(0, y0 - pad), min(img.size[0], x1 + pad), min(img.size[1], y1 + pad)))


def fit(img: Image.Image, size: int) -> Image.Image:
	img = img.convert("RGBA")
	img.thumbnail((size - 4, size - 4), Image.Resampling.LANCZOS)
	canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	canvas.paste(img, ((size - img.size[0]) // 2, (size - img.size[1]) // 2), img)
	return canvas


def process_icon(src: Path, out: Path, size: int = 128) -> None:
	cut = key_green(Image.open(src))
	cut = trim(cut, 6)
	out.parent.mkdir(parents=True, exist_ok=True)
	fit(cut, size).save(out, optimize=True)
	print(f"wrote {out}")


def make_cyan_cell(size: int = 144) -> Image.Image:
	"""Flashy cyan mythic inventory cell (SSR-like structure)."""
	img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	draw = ImageDraw.Draw(img)
	# dark plate
	draw.rounded_rectangle((8, 8, size - 8, size - 8), radius=10, fill=(18, 28, 40, 245))
	# inner glow wash
	glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	gd = ImageDraw.Draw(glow)
	for i, a in enumerate((30, 55, 80)):
		m = 14 + i * 3
		gd.rounded_rectangle((m, m, size - m, size - m), radius=8, outline=(80, 220, 255, a), width=2)
	img = Image.alpha_composite(img, glow)
	draw = ImageDraw.Draw(img)
	# outer cyan double border
	cyan = (90, 230, 255, 255)
	cyan_hi = (180, 250, 255, 255)
	cyan_deep = (30, 140, 200, 255)
	draw.rounded_rectangle((6, 6, size - 6, size - 6), radius=12, outline=cyan_deep, width=4)
	draw.rounded_rectangle((10, 10, size - 10, size - 10), radius=10, outline=cyan, width=3)
	# corner flares
	for (x, y, dx, dy) in ((14, 14, 1, 1), (size - 14, 14, -1, 1), (14, size - 14, 1, -1), (size - 14, size - 14, -1, -1)):
		draw.line((x, y, x + dx * 16, y), fill=cyan_hi, width=3)
		draw.line((x, y, x, y + dy * 16), fill=cyan_hi, width=3)
	# bottom notch accent
	cx = size // 2
	draw.polygon([(cx - 10, size - 12), (cx, size - 4), (cx + 10, size - 12)], outline=cyan_hi)
	# faint center emblem
	draw.ellipse((size // 2 - 22, size // 2 - 22, size // 2 + 22, size // 2 + 22), outline=(70, 180, 220, 70), width=2)
	draw.line((size // 2, size // 2 - 16, size // 2, size // 2 + 16), fill=(90, 220, 255, 60), width=2)
	draw.line((size // 2 - 16, size // 2, size // 2 + 16, size // 2), fill=(90, 220, 255, 60), width=2)
	return img.filter(ImageFilter.SMOOTH_MORE)


def process_cell(src: Path | None, out: Path) -> None:
	if src is not None and src.exists():
		cut = key_green(Image.open(src))
		# If mostly empty after key, fall back
		if cut.getbbox() is None:
			cell = make_cyan_cell()
		else:
			# Keep as full square frame: don't trim hard; fit to 144
			cell = fit(trim(cut, 2), 144)
			# If center became transparent hole, composite dark plate
			plate = Image.new("RGBA", (144, 144), (0, 0, 0, 0))
			pd = ImageDraw.Draw(plate)
			pd.rounded_rectangle((12, 12, 132, 132), radius=8, fill=(18, 28, 40, 230))
			cell = Image.alpha_composite(plate, cell)
	else:
		cell = make_cyan_cell()
	# Prefer procedural flashy cell as final (consistent chrome)
	cell = make_cyan_cell()
	out.parent.mkdir(parents=True, exist_ok=True)
	cell.save(out, optimize=True)
	print(f"wrote {out}")


def main() -> None:
	ap = argparse.ArgumentParser()
	ap.add_argument(
		"--src-dir",
		type=Path,
		default=Path("/Users/marte/.local/share/cursor-agent/artifacts/assets"),
	)
	args = ap.parse_args()
	src = args.src_dir
	process_icon(src / "mythic_src_wpn_burial_crown.png", EQ / "ICO_WPN_BurialCrownGreatsword.png")
	process_icon(src / "mythic_src_arm_cenotaph.png", EQ / "ICO_ARM_ImmortalCenotaphPlate.png")
	process_icon(src / "mythic_src_acc_hegemony.png", EQ / "ICO_ACC_CouncilHegemonySeal.png")
	process_cell(src / "mythic_src_invcell_cyan.png", EQ_UI / "UI_Equip_InvCell_MYTHIC.png")
	# Mythic badge: cyan ribbon variant from legendary size
	badge = Image.new("RGBA", (256, 69), (0, 0, 0, 0))
	bd = ImageDraw.Draw(badge)
	bd.rounded_rectangle((8, 12, 248, 56), radius=8, fill=(20, 60, 90, 235), outline=(120, 240, 255, 255), width=3)
	bd.polygon([(20, 34), (40, 18), (40, 50)], fill=(80, 220, 255, 255))
	bd.polygon([(236, 34), (216, 18), (216, 50)], fill=(80, 220, 255, 255))
	# simple MYTH text bars
	bd.rectangle((70, 28, 186, 40), fill=(180, 250, 255, 220))
	badge_path = EQ_UI / "ICO_Equip_MythicBadge.png"
	badge.save(badge_path, optimize=True)
	print(f"wrote {badge_path}")


if __name__ == "__main__":
	main()
