#!/usr/bin/env python3
"""Install owner passive skill icons (job passives 02-15).

Source: ~/Desktop/CrownFall設定画像/アイコン/パッシブスキル
Output: assets/ui/passives/ICO_PASSIVE_{PascalCase}.png

Usage:
  python3 tools/install_passive_icons.py
  python3 tools/install_passive_icons.py --apply
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SRC = Path.home() / "Desktop/CrownFall設定画像/アイコン/パッシブスキル"
OUT_DIR = ROOT / "assets/ui/passives"
PREVIEW_DIR = OUT_DIR / "preview"
DESIGN_PX = 128

# 全角番号ソース → passive_id（01=battle_fervor はリポジトリ済み）
SOURCE_TO_PASSIVE: dict[str, str] = {
	"２.png": "foresight",
	"３.png": "bulwark",
	"４.png": "field_medic",
	"５.png": "pack_instinct",
	"６.png": "sword_charge",
	"７.png": "wind_reading",
	"８.png": "unyielding_stance",
	"９.png": "spare_vial",
	"１０.png": "tamer_whistle",
	"１１.png": "royal_sword_doctrine",
	"１２.png": "formation_eye",
	"１３.png": "greatshield_order",
	"１４.png": "panacea_gift",
	"１５.png": "herd_king_roar",
}

WHITE_THRESHOLD = 240
BLACK_THRESHOLD = 28


def passive_id_to_filename(passive_id: str) -> str:
	parts = [p for p in passive_id.split("_") if p]
	pascal = "".join(p[:1].upper() + p[1:] for p in parts)
	return f"ICO_PASSIVE_{pascal}.png"


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
	return img.crop(bbox) if bbox else img


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


def process_source(src_path: Path, out_path: Path) -> None:
	src = Image.open(src_path)
	kind = corner_bg_kind(src)
	if kind == "unknown":
		raise ValueError(f"unknown background: {src_path.name}")
	icon = fit_icon(trim_transparent(remove_matte_bg(src, kind)), DESIGN_PX)
	out_path.parent.mkdir(parents=True, exist_ok=True)
	icon.save(out_path, optimize=True)


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("--src", type=Path, default=DEFAULT_SRC)
	parser.add_argument("--apply", action="store_true")
	args = parser.parse_args()
	src_dir: Path = args.src
	if not src_dir.exists():
		print(f"ERROR: missing {src_dir}")
		return 1
	out_dir = OUT_DIR if args.apply else PREVIEW_DIR
	out_dir.mkdir(parents=True, exist_ok=True)
	ok = 0
	for src_name, pid in SOURCE_TO_PASSIVE.items():
		src_path = src_dir / src_name
		out_name = passive_id_to_filename(pid)
		out_path = out_dir / out_name
		if not src_path.exists():
			print(f"MISSING  {src_name} -> {out_name}")
			continue
		process_source(src_path, out_path)
		print(f"OK       {src_name} -> {out_path.relative_to(ROOT)} ({pid})")
		ok += 1
	if ok == 0:
		return 1
	if not args.apply:
		print(f"\nPreview in {out_dir.relative_to(ROOT)} — rerun with --apply")
	return 0


if __name__ == "__main__":
	sys.exit(main())
