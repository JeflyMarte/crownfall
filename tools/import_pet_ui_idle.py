#!/usr/bin/env python3
"""Import front-facing (south) UI idle frames for pets into assets/characters/pet_*.

Source: PixelLab character "Royal Guardian Wolf" (Jack) Idle south.
Ash / Ink are recolored from Jack frames (same as tools/recolor_pet_variants.py).

Usage:
  python3 tools/import_pet_ui_idle.py
"""
from __future__ import annotations

import colorsys
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT_ROOT = ROOT / "assets" / "characters"
TMP = Path("/tmp/crownfall_pet_ui_idle")
TARGET = 232
PAD_RATIO = 0.08

# PixelLab Royal Guardian Wolf — Idle south (P3 pet Jack)
CHAR_ID = "14f98a4a-b360-4040-8271-da8728ce09d4"
ANIM_ID = "ff440f53-f00c-475a-8244-feea4a28af3f"
FRAME_URL = (
	"https://backblaze.pixellab.ai/file/pixellab-characters/"
	f"8db9307c-ddfc-4a8c-8210-027b24029315/{CHAR_ID}/animations/{ANIM_ID}/south/{{i}}.png"
)
FRAME_COUNT = 9


def fit_square(im: Image.Image, size: int = TARGET) -> Image.Image:
	im = im.convert("RGBA")
	bbox = im.split()[-1].getbbox()
	if bbox is None:
		return Image.new("RGBA", (size, size), (0, 0, 0, 0))
	cropped = im.crop(bbox)
	cw, ch = cropped.size
	pad = int(max(cw, ch) * PAD_RATIO)
	side = max(cw, ch) + pad * 2
	square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
	square.paste(cropped, ((side - cw) // 2, (side - ch) // 2), cropped)
	return square.resize((size, size), Image.Resampling.NEAREST)


def write_import(png_path: Path, folder_id: str) -> None:
	import hashlib

	rel = f"{folder_id}/{png_path.name}"
	src = f"res://assets/characters/{rel}"
	h = hashlib.md5(src.encode()).hexdigest()
	uid_body = "".join(c for c in f"{folder_id}_{png_path.stem}" if c.isalnum())[:18]
	ctex = f"res://.godot/imported/{png_path.name}-{h}.ctex"
	imp = png_path.with_suffix(png_path.suffix + ".import")
	imp.write_text(
		f"""[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://{uid_body}"
path="{ctex}"
metadata={{
"vram_texture": false
}}

[deps]

source_file="{src}"
dest_files=["{ctex}"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
""",
		encoding="utf-8",
	)


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
	if a < 8:
		return r, g, b, a
	_h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.35 and r > g + 8 and r > b and ch >= 20:
		return (*hsl_to_rgb(0.12, clamp01(0.45 + l * 0.35), min(0.7, s + 0.2)), a)
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
	if a < 8:
		return r, g, b, a
	_h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.35 and r > g + 8 and r > b and ch >= 20:
		return (*hsl_to_rgb(0.78, clamp01(0.4 + l * 0.35), min(0.75, s + 0.25)), a)
	if ch < 35:
		if l > 0.45:
			return (*mix_rgb(r, g, b, 90, 70, 120, 0.55), a)
		if l > 0.22:
			return (*mix_rgb(r, g, b, 45, 35, 65, 0.55), a)
		return (*mix_rgb(r, g, b, 20, 15, 30, 0.5), a)
	return (*hsl_to_rgb(0.78, clamp01(l * 0.85), min(0.55, s + 0.15)), a)


def apply_recolor(img: Image.Image, fn) -> Image.Image:
	out = img.copy()
	px = img.load()
	opx = out.load()
	w, h = img.size
	for y in range(h):
		for x in range(w):
			opx[x, y] = fn(*px[x, y])
	return out


def download_frames() -> list[Image.Image]:
	TMP.mkdir(parents=True, exist_ok=True)
	frames: list[Image.Image] = []
	for i in range(FRAME_COUNT):
		url = FRAME_URL.format(i=i)
		dest = TMP / f"src_{i}.png"
		subprocess.check_call(["curl", "-sL", "-A", "Mozilla/5.0", "-o", str(dest), url])
		frames.append(fit_square(Image.open(dest)))
		print(f"  frame {i} ok ({dest.stat().st_size}b)")
	return frames


def main() -> None:
	print("download Jack south idle…")
	frames = download_frames()
	variants: dict[str, object | None] = {
		"pet_jack": None,
		"pet_ash": recolor_ash,
		"pet_ink": recolor_ink,
	}
	for folder_id, fn in variants.items():
		out_dir = OUT_ROOT / folder_id
		out_dir.mkdir(parents=True, exist_ok=True)
		for i, fr in enumerate(frames):
			img = apply_recolor(fr, fn) if fn else fr
			path = out_dir / f"idle_{i}.png"
			img.save(path, optimize=True)
			write_import(path, folder_id)
		print(f"wrote {folder_id}/idle_0..{FRAME_COUNT - 1}.png")
	print("done")


if __name__ == "__main__":
	main()
