#!/usr/bin/env python3
"""Normalize biome stage dungeon icons to 1024x1024 PNG.

Copies/normalizes raw generated icons into:
  assets/dungeon/<biome>/stages/ICO_DG_<Name>_<chapter>_<stage>.png

Usage:
  python3 tools/generate_biome_stage_icons.py --from-dir /opt/cursor/artifacts/assets
  python3 tools/generate_biome_stage_icons.py --input path/to/raw.png --biome mistfen --stage 3
"""
from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
TARGET = 1024

BIOMES = {
	"mistfen": {
		"dir": ROOT / "assets/dungeon/mistfen/stages",
		"prefix": "ICO_DG_Mistfen_3",
		"chapter": 3,
	},
	"blackshore": {
		"dir": ROOT / "assets/dungeon/blackshore/stages",
		"prefix": "ICO_DG_Blackshore_4",
		"chapter": 4,
	},
	"frostridge": {
		"dir": ROOT / "assets/dungeon/frostridge/stages",
		"prefix": "ICO_DG_Frostridge_5",
		"chapter": 5,
	},
}


def normalize_icon(src: Path, dst: Path) -> None:
	img = Image.open(src).convert("RGBA")
	w, h = img.size
	side = min(w, h)
	left = (w - side) // 2
	top = (h - side) // 2
	img = img.crop((left, top, left + side, top + side))
	img = img.resize((TARGET, TARGET), Image.Resampling.LANCZOS)
	dst.parent.mkdir(parents=True, exist_ok=True)
	img.save(dst, optimize=True)
	print(f"wrote {dst} ({TARGET}x{TARGET})")


def install_from_dir(raw_dir: Path) -> int:
	missing = 0
	for biome, meta in BIOMES.items():
		chapter = meta["chapter"]
		out_dir = meta["dir"]
		for stage in range(1, 6):
			name = f"{meta['prefix']}_{stage}"
			candidates = [
				raw_dir / f"{name}_raw.png",
				raw_dir / f"{name}.png",
			]
			src = next((p for p in candidates if p.exists()), None)
			if src is None:
				print(f"missing raw for {biome} {chapter}-{stage}")
				missing += 1
				continue
			normalize_icon(src, out_dir / f"{name}.png")
	return missing


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("--from-dir", type=Path, help="Directory of *_raw.png icons")
	parser.add_argument("--input", type=Path, help="Single raw PNG")
	parser.add_argument("--biome", choices=sorted(BIOMES), help="Biome for --input")
	parser.add_argument("--stage", type=int, choices=range(1, 6), help="Stage 1-5 for --input")
	parser.add_argument(
		"--copy-raw-sidecar",
		action="store_true",
		help="Also keep a non-normalized copy next to output as .source.png",
	)
	args = parser.parse_args()

	if args.from_dir is not None:
		missing = install_from_dir(args.from_dir)
		return 1 if missing else 0

	if args.input is not None:
		if args.biome is None or args.stage is None:
			parser.error("--biome and --stage are required with --input")
		meta = BIOMES[args.biome]
		dst = meta["dir"] / f"{meta['prefix']}_{args.stage}.png"
		normalize_icon(args.input, dst)
		if args.copy_raw_sidecar:
			shutil.copy2(args.input, dst.with_suffix(".source.png"))
		return 0

	parser.error("Provide --from-dir or --input")
	return 2


if __name__ == "__main__":
	raise SystemExit(main())
