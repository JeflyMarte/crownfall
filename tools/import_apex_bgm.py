#!/usr/bin/env python3
"""Import apex conquest BGM from ~/Downloads/アップデートBGM.

Maps:
  天空の塔　通常.mp3 → assets/audio/bgm/north_reach.mp3
  天空の塔　ボス.mp3 → assets/audio/bgm/north_reach_boss.mp3
  星炉火口　通常.mp3 → assets/audio/bgm/red_forge_depths.mp3
  星炉火口　ボス.mp3 → assets/audio/bgm/red_forge_depths_boss.mp3

Usage:
  python3 tools/import_apex_bgm.py
"""
from __future__ import annotations

import shutil
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads" / "アップデートBGM"
OUT = ROOT / "assets" / "audio" / "bgm"

# NFC source stem → output filename
MAP: dict[str, str] = {
	"天空の塔　通常": "north_reach.mp3",
	"天空の塔　ボス": "north_reach_boss.mp3",
	"星炉火口　通常": "red_forge_depths.mp3",
	"星炉火口　ボス": "red_forge_depths_boss.mp3",
}


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def find_src(stem: str) -> Path:
	if not DOWNLOADS.is_dir():
		raise SystemExit(f"Missing folder: {DOWNLOADS}")
	for p in DOWNLOADS.iterdir():
		if p.is_file() and nfc(p.stem) == stem and p.suffix.lower() == ".mp3":
			return p
	raise SystemExit(f"Missing mp3 for {stem!r} under {DOWNLOADS}")


def main() -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	for stem, out_name in MAP.items():
		src = find_src(stem)
		dest = OUT / out_name
		shutil.copy2(src, dest)
		old_imp = dest.with_suffix(dest.suffix + ".import")
		if old_imp.exists():
			old_imp.unlink()
		print(f"  {src.name} → {dest.relative_to(ROOT)} ({dest.stat().st_size} bytes)")
	print("\nDONE — run Godot --import")


if __name__ == "__main__":
	main()
