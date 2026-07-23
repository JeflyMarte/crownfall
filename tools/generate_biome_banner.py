#!/usr/bin/env python3
"""Normalize biome title banners for dungeon select accordion headers.

Output: assets/ui/dungeon/BAN_DG_{BiomePascal}.png

Default mode preserves the source aspect (title-baked key art).
Dungeon select list / Featured banners (main + event) must match main strip size:
  --strip-height 232  → 1408×232（一覧表示高さ ~112px @680幅）
  メイン同様の金枠は BAN_DG_Frame_Strip.png を重ねる（--with-frame / 既定 ON for strip）。
  中央ネームプレート（ダンジョン名用の二重金枠）は --with-nameplate。

Usage:
  python3 tools/generate_biome_banner.py --input path/to.png --biome mourngate --strip-height 232
  python3 tools/generate_biome_banner.py --input path/to.png --biome rock_stampede --strip-height 232 --with-nameplate
  python3 tools/generate_biome_banner.py --extract-frame  # rebuild frame strip from Mourngate
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

from PIL import Image, ImageDraw

try:
	RESAMPLE_LANCZOS = Image.Resampling.LANCZOS
except AttributeError:
	RESAMPLE_LANCZOS = Image.LANCZOS

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets/ui/dungeon"
FRAME_STRIP_PATH = OUT_DIR / "BAN_DG_Frame_Strip.png"
NAMEPLATE_STRIP_PATH = OUT_DIR / "BAN_DG_Nameplate_Strip.png"
TARGET_W = 1408
WHITE_THRESHOLD = 235
WHITE_SOFT = 250
## メイン Biome と同型の中央ネームプレート（二重金枠＋半透明暗板）。UI ラベルが載る。
NAMEPLATE_MARGIN_X = 56
NAMEPLATE_MARGIN_Y = 48
NAMEPLATE_RADIUS = 9
NAMEPLATE_FILL = (6, 6, 10, 185)
NAMEPLATE_GOLD_OUTER = (205, 170, 78, 255)
NAMEPLATE_GOLD_INNER = (230, 200, 110, 255)


def biome_filename(biome_id: str) -> str:
	parts = biome_id.split("_")
	pascal = "".join(p.capitalize() for p in parts)
	return f"BAN_DG_{pascal}.png"


def remove_light_matte(img: Image.Image) -> Image.Image:
	img = img.convert("RGBA")
	px = img.load()
	w, h = img.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			dist = max(255 - r, 255 - g, 255 - b)
			if dist <= 255 - WHITE_THRESHOLD:
				px[x, y] = (r, g, b, 0)
			elif dist <= 255 - WHITE_SOFT:
				fade = (dist - (255 - WHITE_THRESHOLD)) / max(1, WHITE_THRESHOLD - WHITE_SOFT)
				px[x, y] = (r, g, b, int(a * fade))
	return img


def extract_frame_strip(
	main_path: Path | None = None,
	atm_path: Path | None = None,
	strip_height: int = 232,
) -> Image.Image:
	"""Extract gold ornate frame overlay from a finished main banner vs its atmosphere raw."""
	main_path = main_path or (OUT_DIR / "BAN_DG_Mourngate.png")
	atm_path = atm_path or (OUT_DIR / "BAN_DG_Mourngate_atmosphere_raw.png")
	main = Image.open(main_path).convert("RGBA")
	atm = Image.open(atm_path).convert("RGBA")
	w = TARGET_W
	h = strip_height
	aw, ah = atm.size
	scale = w / float(aw)
	rh = max(1, int(round(ah * scale)))
	atm_r = atm.resize((w, rh), RESAMPLE_LANCZOS)
	top = max(0, (rh - h) // 2)
	atm_c = atm_r.crop((0, top, w, top + h))
	if main.size != (w, h):
		main = main.resize((w, h), RESAMPLE_LANCZOS)
	mpx = main.load()
	apx = atm_c.load()
	overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	opx = overlay.load()
	for y in range(h):
		for x in range(w):
			edge = min(x, w - 1 - x, y, h - 1 - y)
			if edge > 42:
				continue
			r1, g1, b1, a1 = mpx[x, y]
			r2, g2, b2, _a2 = apx[x, y]
			dr = abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
			is_gold = r1 > 120 and g1 > 80 and (r1 - b1) > 25 and r1 + g1 > b1 * 1.8
			is_struct = edge < 14 and dr > 45
			if is_gold or is_struct:
				alpha = 255 if is_gold else max(0, 255 - edge * 12)
				opx[x, y] = (r1, g1, b1, alpha)
	return overlay


def ensure_frame_strip(strip_height: int = 232) -> Image.Image | None:
	if FRAME_STRIP_PATH.exists():
		frame = Image.open(FRAME_STRIP_PATH).convert("RGBA")
		if frame.size == (TARGET_W, strip_height):
			return frame
	main = OUT_DIR / "BAN_DG_Mourngate.png"
	atm = OUT_DIR / "BAN_DG_Mourngate_atmosphere_raw.png"
	if not main.exists() or not atm.exists():
		print(f"warn: cannot build frame strip (missing {main.name} or {atm.name})")
		return None
	frame = extract_frame_strip(main, atm, strip_height)
	FRAME_STRIP_PATH.parent.mkdir(parents=True, exist_ok=True)
	frame.save(FRAME_STRIP_PATH, optimize=True)
	print(f"wrote {FRAME_STRIP_PATH} ({frame.size[0]}x{frame.size[1]})")
	return frame


def apply_frame(img: Image.Image, frame: Image.Image | None) -> Image.Image:
	if frame is None:
		return img
	if frame.size != img.size:
		frame = frame.resize(img.size, RESAMPLE_LANCZOS)
	return Image.alpha_composite(img.convert("RGBA"), frame.convert("RGBA"))


def make_nameplate_strip(size: tuple[int, int] = (TARGET_W, 232)) -> Image.Image:
	"""中央にダンジョン名用の二重金枠＋暗板（メイン Biome バナーと同型）。"""
	w, h = size
	plate = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	draw = ImageDraw.Draw(plate)
	x0, y0 = NAMEPLATE_MARGIN_X, NAMEPLATE_MARGIN_Y
	x1, y1 = w - NAMEPLATE_MARGIN_X, h - NAMEPLATE_MARGIN_Y
	draw.rounded_rectangle(
		[x0 + 2, y0 + 2, x1 - 2, y1 - 2],
		radius=max(2, NAMEPLATE_RADIUS - 1),
		fill=NAMEPLATE_FILL,
	)
	draw.rounded_rectangle(
		[x0, y0, x1, y1],
		radius=NAMEPLATE_RADIUS,
		outline=NAMEPLATE_GOLD_OUTER,
		width=3,
	)
	draw.rounded_rectangle(
		[x0 + 5, y0 + 5, x1 - 5, y1 - 5],
		radius=max(2, NAMEPLATE_RADIUS - 3),
		outline=NAMEPLATE_GOLD_INNER,
		width=2,
	)
	return plate


def ensure_nameplate_strip(strip_height: int = 232) -> Image.Image:
	plate = make_nameplate_strip((TARGET_W, strip_height))
	NAMEPLATE_STRIP_PATH.parent.mkdir(parents=True, exist_ok=True)
	plate.save(NAMEPLATE_STRIP_PATH, optimize=True)
	return plate


def normalize_banner(
	src: Path,
	dst: Path,
	strip_height: int | None = None,
	with_frame: bool = False,
	with_nameplate: bool = False,
) -> None:
	img = remove_light_matte(Image.open(src))
	w, h = img.size
	scale = TARGET_W / float(w)
	resized_h = max(1, int(round(h * scale)))
	img = img.resize((TARGET_W, resized_h), RESAMPLE_LANCZOS)
	if strip_height is not None and strip_height > 0:
		target_h = strip_height
		if resized_h > target_h:
			top = (resized_h - target_h) // 2
			img = img.crop((0, top, TARGET_W, top + target_h))
		elif resized_h < target_h:
			canvas = Image.new("RGBA", (TARGET_W, target_h), (0, 0, 0, 0))
			offset_y = (target_h - resized_h) // 2
			canvas.paste(img, (0, offset_y), img)
			img = canvas
	if with_frame:
		img = apply_frame(img, ensure_frame_strip(img.size[1]))
	if with_nameplate:
		img = apply_frame(img, ensure_nameplate_strip(img.size[1]))
	dst.parent.mkdir(parents=True, exist_ok=True)
	img.save(dst, optimize=True)
	print(f"wrote {dst} ({img.size[0]}x{img.size[1]})")


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("--input", type=Path, help="Raw banner PNG")
	parser.add_argument("--biome", type=str, default="mourngate", help="Biome id (e.g. mourngate)")
	parser.add_argument(
		"--strip-height",
		type=int,
		default=None,
		help="Optional center-crop height (legacy thin strip). Omit to preserve aspect.",
	)
	parser.add_argument(
		"--with-frame",
		action="store_true",
		default=None,
		help="Composite BAN_DG_Frame_Strip gold frame (default: on when --strip-height set).",
	)
	parser.add_argument(
		"--no-frame",
		action="store_true",
		help="Do not composite the gold frame strip.",
	)
	parser.add_argument(
		"--extract-frame",
		action="store_true",
		help="Rebuild BAN_DG_Frame_Strip.png from Mourngate main vs atmosphere.",
	)
	parser.add_argument(
		"--with-nameplate",
		action="store_true",
		help="Composite central gold nameplate (main-biome style) for UI dungeon title.",
	)
	parser.add_argument(
		"--write-nameplate",
		action="store_true",
		help="Rewrite BAN_DG_Nameplate_Strip.png only.",
	)
	args = parser.parse_args()

	if args.extract_frame:
		frame = extract_frame_strip()
		FRAME_STRIP_PATH.parent.mkdir(parents=True, exist_ok=True)
		frame.save(FRAME_STRIP_PATH, optimize=True)
		print(f"wrote {FRAME_STRIP_PATH} ({frame.size[0]}x{frame.size[1]})")
		return 0

	if args.write_nameplate:
		plate = ensure_nameplate_strip()
		print(f"wrote {NAMEPLATE_STRIP_PATH} ({plate.size[0]}x{plate.size[1]})")
		return 0

	if args.input is not None:
		if not re.fullmatch(r"[a-z0-9_]+", args.biome):
			parser.error("invalid biome id")
		with_frame = False
		if args.no_frame:
			with_frame = False
		elif args.with_frame is True:
			with_frame = True
		elif args.strip_height is not None:
			## 一覧向けストリップはメイン同様に金枠を重ねる（イベント含む）。
			with_frame = True
		normalize_banner(
			args.input,
			OUT_DIR / biome_filename(args.biome),
			args.strip_height,
			with_frame,
			args.with_nameplate,
		)
		return 0

	raw = OUT_DIR / "BAN_DG_Mourngate_raw.png"
	if raw.exists():
		normalize_banner(raw, OUT_DIR / "BAN_DG_Mourngate.png")
	else:
		print(f"skip missing: {raw}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
