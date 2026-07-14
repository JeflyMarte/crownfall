#!/usr/bin/env python3
"""Import Mourngate codex portraits from Desktop モンスター図鑑.

Source: ~/Desktop/CrownFall設定画像/モンスター/モンスター図鑑/*.png
Output: assets/codex/enemies/ART_ENM_*.png / ART_BOSS_Serdion.png (256×256, keyed)
"""
from __future__ import annotations

import unicodedata
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = Path.home() / "Desktop/CrownFall設定画像/モンスター/モンスター図鑑"
OUT = ROOT / "assets/codex/enemies"
SIZE = 256
BLACK_HARD = 28
BLACK_SOFT = 48
PAD_RATIO = 0.06

# Desktop display name (NFC) → output filename
NAME_MAP: dict[str, str] = {
	"セピアハウンド": "ART_ENM_SepiaHound.png",
	"ルーンローチ": "ART_ENM_RuneRoach.png",
	"水晶ハリネズミ": "ART_ENM_CrystalHedgehog.png",
	"冠喰いネズミ": "ART_ENM_CrownEaterRat.png",
	"墓鐘バット": "ART_ENM_GraveBellBat.png",
	"水晶スコーピオン": "ART_ENM_CrystalScorpion.png",
	"骸面マンティス": "ART_ENM_SkullfaceMantis.png",
	"クロックモス": "ART_ENM_ClockMoth.png",
	"水晶骸竜 セルディオン": "ART_BOSS_Serdion.png",
}


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def remove_black_matte(img: Image.Image) -> Image.Image:
	img = img.convert("RGBA")
	px = img.load()
	w, h = img.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0:
				px[x, y] = (0, 0, 0, 0)
				continue
			dist = max(r, g, b)
			if dist <= BLACK_HARD:
				px[x, y] = (r, g, b, 0)
			elif dist <= BLACK_SOFT:
				fade = (dist - BLACK_HARD) / max(1, BLACK_SOFT - BLACK_HARD)
				px[x, y] = (r, g, b, int(a * fade))
	return img


def fit_square(img: Image.Image, size: int = SIZE) -> Image.Image:
	bbox = img.getbbox()
	if bbox is None:
		return Image.new("RGBA", (size, size), (0, 0, 0, 0))
	cropped = img.crop(bbox)
	cw, ch = cropped.size
	pad = max(2, int(round(max(cw, ch) * PAD_RATIO)))
	canvas = Image.new("RGBA", (cw + pad * 2, ch + pad * 2), (0, 0, 0, 0))
	canvas.paste(cropped, (pad, pad), cropped)
	side = max(canvas.size)
	square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
	ox = (side - canvas.size[0]) // 2
	oy = (side - canvas.size[1]) // 2
	square.paste(canvas, (ox, oy), canvas)
	return square.resize((size, size), Image.Resampling.LANCZOS)


def resolve_sources() -> dict[str, Path]:
	found: dict[str, Path] = {}
	if not SRC.is_dir():
		raise SystemExit(f"Source folder missing: {SRC}")
	for path in SRC.iterdir():
		if path.suffix.lower() != ".png" or path.name.startswith("."):
			continue
		stem = nfc(path.stem)
		# tolerate slight spelling variants
		for key in NAME_MAP:
			if stem == key or key in stem or stem in key:
				found[key] = path
				break
	return found


def main() -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	sources = resolve_sources()
	missing = [k for k in NAME_MAP if k not in sources]
	if missing:
		print("WARN missing sources:", missing)
	for name, out_name in NAME_MAP.items():
		src = sources.get(name)
		if src is None:
			continue
		img = Image.open(src)
		processed = fit_square(remove_black_matte(img))
		dest = OUT / out_name
		processed.save(dest, "PNG", optimize=True)
		print(f"OK {nfc(src.name)} -> {out_name} {processed.size} {dest.stat().st_size}B")


if __name__ == "__main__":
	main()
