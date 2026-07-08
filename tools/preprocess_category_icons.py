#!/usr/bin/env python3
"""Preprocess owner category-tab icons for Equipment and Forge screens.

Source (default): ~/Desktop/CrownFall設定画像/素材
  - 鍛冶屋武器.png -> weapon tab
  - 鍛冶屋防具.png -> armor tab
  - 装飾品.png     -> accessory tab

Outputs (with --apply):
  assets/ui/equipment_ui/ICO_Equip_Cat_{Weapon,Armor,Accessory}.png  (96px)
  assets/ui/forge/ICO_Forge_Cat_{Weapon,Armor,Accessory}.png         (144px)

Individual equipment item icons under assets/ui/equipment/ are untouched.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SRC = Path.home() / "Desktop/CrownFall設定画像/素材"
PREVIEW_OUT = ROOT / "assets/ui/equipment_ui/preview"
EQUIP_OUT = ROOT / "assets/ui/equipment_ui"
FORGE_OUT = ROOT / "assets/ui/forge"

SOURCE_MAP: dict[str, tuple[str, str]] = {
	"鍛冶屋武器.png": ("weapon", "ICO_Equip_Cat_Weapon.png"),
	"鍛冶屋防具.png": ("armor", "ICO_Equip_Cat_Armor.png"),
	"装飾品.png": ("accessory", "ICO_Equip_Cat_Accessory.png"),
}

FORGE_NAMES: dict[str, str] = {
	"weapon": "ICO_Forge_Cat_Weapon.png",
	"armor": "ICO_Forge_Cat_Armor.png",
	"accessory": "ICO_Forge_Cat_Accessory.png",
}

EQUIP_PX = 96
FORGE_PX = 144

# 装飾枠を切り落とす外周比率（金枠 ~4% + 内側の暗背景まで少し余裕）。
FRAME_CROP_RATIO = 0.085
# 暗背景を透過にする閾値（RGB 全チャンネルがこの値以下なら背景とみなす）。
# 石目テクスチャの地色まで抜くため広めに取る。被写体（金属/宝石）は十分明るい。
BG_DARK_HARD = 60
BG_DARK_SOFT = 110


def crop_frame(img: Image.Image, ratio: float) -> Image.Image:
	src = img.convert("RGBA")
	w, h = src.size
	dx = int(round(w * ratio))
	dy = int(round(h * ratio))
	return src.crop((dx, dy, w - dx, h - dy))


def remove_dark_bg(img: Image.Image) -> Image.Image:
	src = img.convert("RGBA")
	px = src.load()
	w, h = src.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			m = max(r, g, b)
			if m <= BG_DARK_HARD:
				px[x, y] = (r, g, b, 0)
			elif m < BG_DARK_SOFT:
				alpha = int(a * (m - BG_DARK_HARD) / (BG_DARK_SOFT - BG_DARK_HARD))
				px[x, y] = (r, g, b, min(a, alpha))
	return src


def fit_square(img: Image.Image, size: int) -> Image.Image:
	src = img.convert("RGBA")
	scale = min(size / src.width, size / src.height)
	new_w = max(1, int(round(src.width * scale)))
	new_h = max(1, int(round(src.height * scale)))
	resized = src.resize((new_w, new_h), Image.Resampling.LANCZOS)
	canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	ox = (size - new_w) // 2
	oy = (size - new_h) // 2
	canvas.alpha_composite(resized, (ox, oy))
	return canvas


def process_one(src_path: Path, category: str, equip_name: str, apply: bool) -> None:
	img = Image.open(src_path)
	cropped = crop_frame(img, FRAME_CROP_RATIO)
	cleaned = remove_dark_bg(cropped)
	equip_icon = fit_square(cleaned, EQUIP_PX)
	forge_icon = fit_square(cleaned, FORGE_PX)
	preview_dir = PREVIEW_OUT / category
	preview_dir.mkdir(parents=True, exist_ok=True)
	equip_icon.save(preview_dir / equip_name, optimize=True)
	forge_icon.save(preview_dir / FORGE_NAMES[category], optimize=True)
	print(f"  preview {category}: {equip_name} ({EQUIP_PX}px), {FORGE_NAMES[category]} ({FORGE_PX}px)")
	if apply:
		EQUIP_OUT.mkdir(parents=True, exist_ok=True)
		FORGE_OUT.mkdir(parents=True, exist_ok=True)
		equip_icon.save(EQUIP_OUT / equip_name, optimize=True)
		forge_icon.save(FORGE_OUT / FORGE_NAMES[category], optimize=True)
		print(f"    -> applied to production")


def main() -> int:
	parser = argparse.ArgumentParser(description="Preprocess category tab icons")
	parser.add_argument("--src", type=Path, default=DEFAULT_SRC, help="Source folder")
	parser.add_argument("--apply", action="store_true", help="Write to production asset dirs")
	args = parser.parse_args()
	src_dir: Path = args.src
	if not src_dir.is_dir():
		print(f"Source folder not found: {src_dir}", file=sys.stderr)
		return 1
	print(f"Source: {src_dir}")
	for filename, (category, equip_name) in SOURCE_MAP.items():
		src_path = src_dir / filename
		if not src_path.is_file():
			print(f"Missing source: {src_path}", file=sys.stderr)
			return 1
		process_one(src_path, category, equip_name, args.apply)
	if args.apply:
		print("\nApplied category tab icons (equipment + forge). Item icons unchanged.")
	else:
		print(f"\nPreview written under {PREVIEW_OUT.relative_to(ROOT)}")
		print("Re-run with --apply to update production assets.")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
