#!/usr/bin/env python3
"""Preprocess owner stat icon art for Equipment screen preview.

Source (default): ~/Desktop/CrownFall設定画像/素材
Output: assets/ui/equipment_ui/preview/

Usage:
  python3 tools/preprocess_equipment_stat_icons.py
  python3 tools/preprocess_equipment_stat_icons.py --apply
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SRC = Path.home() / "Desktop/CrownFall設定画像/素材"
PREVIEW_OUT = ROOT / "assets/ui/equipment_ui/preview"
PROD_OUT = ROOT / "assets/ui/equipment_ui"
FORGE_OUT = ROOT / "assets/ui/forge"

# Japanese source filename -> equipment stat key / output filename
SOURCE_MAP: dict[str, tuple[str, str]] = {
	"攻撃力.png": ("attack", "ICO_Equip_Stat_ATK.png"),
	"防御力.png": ("defense", "ICO_Equip_Stat_DEF.png"),
	"HP.png": ("hp", "ICO_Equip_Stat_HP.png"),
	"攻撃速度.png": ("speed", "ICO_Equip_Stat_SPD.png"),
	"クリティカル.png": ("crit_rate", "ICO_Equip_Stat_CRIT.png"),
	"会心ダメ.png": ("crit_damage", "ICO_Equip_Stat_CRITDMG.png"),
	"属性.png": ("element", "ICO_Equip_Stat_ELEMENT.png"),
	"生物特効.png": ("bane", "ICO_Equip_Stat_BANE.png"),
}

# Forge screen reuses the same art under its own filenames (atk/def/crit/hp).
FORGE_MAP: dict[str, str] = {
	"攻撃力.png": "ICO_Forge_Stat_ATK.png",
	"防御力.png": "ICO_Forge_Stat_DEF.png",
	"HP.png": "ICO_Forge_Stat_HP.png",
	"クリティカル.png": "ICO_Forge_Stat_CRIT.png",
}

DESIGN_PX = 72
DISPLAY_PX = 28

WHITE_THRESHOLD = 240
BLACK_THRESHOLD = 28


def corner_bg_kind(img: Image.Image) -> str:
	rgb = img.convert("RGB")
	w, h = rgb.size
	corners = [
		rgb.getpixel((0, 0)),
		rgb.getpixel((w - 1, 0)),
		rgb.getpixel((0, h - 1)),
		rgb.getpixel((w - 1, h - 1)),
	]
	if all(r >= WHITE_THRESHOLD and g >= WHITE_THRESHOLD and b >= WHITE_THRESHOLD for r, g, b in corners):
		return "white"
	if all(r <= BLACK_THRESHOLD and g <= BLACK_THRESHOLD and b <= BLACK_THRESHOLD for r, g, b in corners):
		return "black"
	avg = tuple(sum(c[i] for c in corners) // 4 for i in range(3))
	if sum(avg) / 3 >= WHITE_THRESHOLD:
		return "white"
	if sum(avg) / 3 <= BLACK_THRESHOLD:
		return "black"
	return "unknown"


def remove_matte_bg(img: Image.Image, kind: str, hard: int = 28, soft: int = 42) -> Image.Image:
	img = img.convert("RGBA")
	px = img.load()
	w, h = img.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if kind == "black":
				dist = max(r, g, b)
			elif kind == "white":
				dist = max(255 - r, 255 - g, 255 - b)
			else:
				continue
			if dist <= hard:
				px[x, y] = (r, g, b, 0)
			elif dist <= soft:
				fade = (dist - hard) / max(1, soft - hard)
				px[x, y] = (r, g, b, int(a * fade))
	return img


def trim_transparent(img: Image.Image) -> Image.Image:
	bbox = img.getbbox()
	if bbox is None:
		return img
	return img.crop(bbox)


def fit_icon(img: Image.Image, size: int = DESIGN_PX, margin_ratio: float = 0.08) -> Image.Image:
	content_max = max(8, int(size * (1.0 - margin_ratio * 2.0)))
	w, h = img.size
	if w <= 0 or h <= 0:
		return Image.new("RGBA", (size, size), (0, 0, 0, 0))
	scale = min(content_max / w, content_max / h)
	nw = max(1, int(round(w * scale)))
	nh = max(1, int(round(h * scale)))
	resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
	canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	canvas.paste(resized, ((size - nw) // 2, (size - nh) // 2), resized)
	return canvas


def audit_icon(path: Path) -> dict:
	img = Image.open(path).convert("RGBA")
	w, h = img.size
	px = img.load()
	transparent = sum(1 for y in range(h) for x in range(w) if px[x, y][3] < 128)
	corners = [px[0, 0][3], px[w - 1, 0][3], px[0, h - 1][3], px[w - 1, h - 1][3]]
	return {
		"size": (w, h),
		"transparent_ratio": transparent / (w * h),
		"corner_alpha": corners,
		"bytes": path.stat().st_size,
	}


def make_preview_sheet(out_dir: Path, icons: dict[str, Path]) -> Path:
	cell = 96
	pad = 12
	cols = 3
	rows = (len(icons) + cols - 1) // cols
	w = cols * cell + (cols + 1) * pad
	h = rows * (cell + 28) + (rows + 1) * pad
	sheet = Image.new("RGBA", (w, h), (24, 20, 16, 255))
	for i, (label, icon_path) in enumerate(sorted(icons.items())):
		col = i % cols
		row = i // cols
		x0 = pad + col * (cell + pad)
		y0 = pad + row * (cell + 28 + pad)
		icon = Image.open(icon_path).convert("RGBA")
		icon = icon.resize((cell, cell), Image.Resampling.LANCZOS)
		sheet.paste(icon, (x0, y0), icon)
	out = out_dir / "PREVIEW_stat_icons_sheet.png"
	sheet.save(out, optimize=True)
	return out


def process_source(src_path: Path, out_path: Path) -> dict:
	src = Image.open(src_path)
	kind = corner_bg_kind(src)
	if kind == "unknown":
		raise ValueError(f"unknown background kind for {src_path.name}")
	cut = trim_transparent(remove_matte_bg(src, kind))
	icon = fit_icon(cut, DESIGN_PX)
	out_path.parent.mkdir(parents=True, exist_ok=True)
	icon.save(out_path, optimize=True)
	return audit_icon(out_path)


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("--src", type=Path, default=DEFAULT_SRC)
	parser.add_argument("--apply", action="store_true", help="copy preview icons into equipment_ui/")
	args = parser.parse_args()

	src_dir: Path = args.src
	if not src_dir.exists():
		print(f"ERROR: source dir missing: {src_dir}")
		return 1

	PREVIEW_OUT.mkdir(parents=True, exist_ok=True)
	results: dict[str, dict] = {}
	preview_paths: dict[str, Path] = {}

	print(f"Source: {src_dir}")
	print(f"Preview: {PREVIEW_OUT}")
	print()

	for src_name, (stat_key, out_name) in SOURCE_MAP.items():
		src_path = src_dir / src_name
		out_path = PREVIEW_OUT / out_name
		if not src_path.exists():
			print(f"MISSING  {src_name} -> {out_name} ({stat_key})")
			continue
		info = process_source(src_path, out_path)
		results[out_name] = info
		preview_paths[stat_key] = out_path
		print(
			f"OK       {src_name} -> preview/{out_name} "
			f"{info['size'][0]}x{info['size'][1]} "
			f"transparent={info['transparent_ratio']*100:.1f}% "
			f"{info['bytes']}B"
		)

	missing_targets: dict[str, str] = {}
	print()
	if missing_targets:
		print("Not in source folder (keep current icons):")
		for label, fname in missing_targets.items():
			prod = PROD_OUT / fname
			status = "exists" if prod.exists() else "missing"
			print(f"  {label}: {fname} [{status}]")
	else:
		print("All mapped stat icons processed.")

	if preview_paths:
		sheet = make_preview_sheet(PREVIEW_OUT, preview_paths)
		print(f"\nPreview sheet: {sheet.relative_to(ROOT)}")

	if args.apply:
		print("\n--apply: copying preview icons to production paths")
		for _, (_, out_name) in SOURCE_MAP.items():
			src = PREVIEW_OUT / out_name
			if not src.exists():
				continue
			dst = PROD_OUT / out_name
			dst.write_bytes(src.read_bytes())
			print(f"  applied {out_name}")
		print("\n--apply: forge screen icons")
		FORGE_OUT.mkdir(parents=True, exist_ok=True)
		for src_name, forge_name in FORGE_MAP.items():
			equip_name = SOURCE_MAP[src_name][1]
			src = PREVIEW_OUT / equip_name
			if not src.exists():
				continue
			dst = FORGE_OUT / forge_name
			dst.write_bytes(src.read_bytes())
			print(f"  applied forge/{forge_name}")

	print("\nDisplay check: EquipmentUiTokens.STAT_ICON_PX =", DISPLAY_PX)
	print("Godot: open Equipment scene and compare preview icons on dark panel.")
	return 0 if results else 1


if __name__ == "__main__":
	sys.exit(main())
