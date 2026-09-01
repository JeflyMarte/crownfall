#!/usr/bin/env python3
"""Import engineer helper bust icons from ~/Downloads/アップデートアイコン.

Maps:
  トリム.png → assets/gacha/portraits/ART_HELPER_helper_q.png
  ブラン.png → assets/gacha/portraits/ART_HELPER_helper_r.png
  オルソ.png → assets/gacha/portraits/ART_HELPER_helper_s.png
  トリム.png → assets/ui/chr_icons/ICO_CHR_Trim.png  (job engineer)

Black matte removed via import_desktop_chr_icons logic; output 512² RGBA.

Usage:
  python3 tools/import_engineer_helper_icons.py
  python3 tools/import_engineer_helper_icons.py --dry-run
"""
from __future__ import annotations

import argparse
import shutil
import sys
import unicodedata
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads" / "アップデートアイコン"
PORTRAIT_DIR = ROOT / "assets" / "gacha" / "portraits"
CHR_DIR = ROOT / "assets" / "ui" / "chr_icons"
IMPORTED = ROOT / ".godot" / "imported"
TARGET = 512

sys.path.insert(0, str(ROOT / "tools"))
from import_desktop_chr_icons import clear_imported_cache, nfc, remove_black_matte_border  # noqa: E402

PORTRAIT_MAP: dict[str, str] = {
	"トリム": "ART_HELPER_helper_q",
	"ブラン": "ART_HELPER_helper_r",
	"オルソ": "ART_HELPER_helper_s",
}

ENGINEER_CHR_STEM = "トリム"
ENGINEER_CHR_BASENAME = "ICO_CHR_Trim"


def find_src(stem: str) -> Path:
	if not DOWNLOADS.is_dir():
		raise SystemExit(f"Missing folder: {DOWNLOADS}")
	for p in DOWNLOADS.iterdir():
		if p.is_file() and nfc(p.stem) == stem and p.suffix.lower() == ".png":
			return p
	raise SystemExit(f"Missing png for {stem!r} under {DOWNLOADS}")


def prepare_icon(src: Path) -> Image.Image:
	img = remove_black_matte_border(Image.open(src))
	if img.size != (TARGET, TARGET):
		img = img.resize((TARGET, TARGET), Image.Resampling.LANCZOS)
	return img


def write_icon(img: Image.Image, dest: Path) -> None:
	dest.parent.mkdir(parents=True, exist_ok=True)
	if dest.exists():
		shutil.copy2(dest, dest.with_suffix(dest.suffix + ".bak_icon_import"))
	old_imp = dest.with_suffix(dest.suffix + ".import")
	if old_imp.exists():
		old_imp.unlink()
	img.save(dest, format="PNG", optimize=True)
	cleared = clear_imported_cache(dest)
	print(f"  → {dest.relative_to(ROOT)} ({img.size[0]}x{img.size[1]}) cache={cleared}")


def main() -> int:
	ap = argparse.ArgumentParser()
	ap.add_argument("--dry-run", action="store_true")
	args = ap.parse_args()
	for stem, basename in sorted(PORTRAIT_MAP.items()):
		src = find_src(stem)
		print(f"== {stem} portrait ==")
		img = prepare_icon(src)
		dest = PORTRAIT_DIR / f"{basename}.png"
		if args.dry_run:
			print(f"  would write {dest.relative_to(ROOT)} size={img.size}")
			continue
		write_icon(img, dest)
	print(f"== {ENGINEER_CHR_STEM} job icon ==")
	chr_src = find_src(ENGINEER_CHR_STEM)
	chr_img = prepare_icon(chr_src)
	chr_dest = CHR_DIR / f"{ENGINEER_CHR_BASENAME}.png"
	if args.dry_run:
		print(f"  would write {chr_dest.relative_to(ROOT)} size={chr_img.size}")
	else:
		write_icon(chr_img, chr_dest)
	if not args.dry_run:
		print("\nDONE — run Godot --import")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
