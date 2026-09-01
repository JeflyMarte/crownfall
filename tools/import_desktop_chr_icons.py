#!/usr/bin/env python3
"""Import regenerated character bust icons from Desktop/キャラアイコン.

Maps Japanese filenames →:
  - starters → assets/ui/chr_icons/ICO_CHR_*.png
  - helpers  → assets/gacha/portraits/ART_HELPER_helper_*.png

Black matte is removed via border flood (does not punch dark clothing holes).
Does not resize (sources are already 1254×1254).

Usage:
  python3 tools/import_desktop_chr_icons.py           # dry-run
  python3 tools/import_desktop_chr_icons.py --apply
"""
from __future__ import annotations

import argparse
import shutil
import unicodedata
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = Path.home() / "Desktop" / "キャラアイコン"
CHR_DIR = ROOT / "assets" / "ui" / "chr_icons"
HELPER_DIR = ROOT / "assets" / "gacha" / "portraits"
IMPORTED = ROOT / ".godot" / "imported"

# NFC Japanese stem → (kind, basename without extension)
# kind: "chr" | "helper"
NAME_MAP: dict[str, tuple[str, str]] = {
	"アルド": ("chr", "ICO_CHR_Ald"),
	"リーヴァ": ("chr", "ICO_CHR_Riva"),
	"エリアス": ("chr", "ICO_CHR_Elias"),
	"ガレン": ("chr", "ICO_CHR_Garen"),
	"ミレイ": ("chr", "ICO_CHR_Mirei"),
	"ヴァルデン": ("helper", "ART_HELPER_helper_a"),
	"イヴァル": ("helper", "ART_HELPER_helper_b"),
	"セリン": ("helper", "ART_HELPER_helper_c"),
	"ルーシェ": ("helper", "ART_HELPER_helper_e"),
	"カイダ": ("helper", "ART_HELPER_helper_f"),
	"ウォール": ("helper", "ART_HELPER_helper_i"),
	"レノール": ("helper", "ART_HELPER_helper_k"),
	"シアン": ("helper", "ART_HELPER_helper_m"),
	"ボルグ": ("helper", "ART_HELPER_helper_n"),
	"ネリ": ("helper", "ART_HELPER_helper_o"),
	"火鷹": ("helper", "ART_HELPER_helper_p"),
}

BLACK_HARD = 18
BLACK_SOFT = 36


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def flood_from_border(passable: np.ndarray) -> np.ndarray:
	h, w = passable.shape
	reached = np.zeros((h, w), dtype=bool)
	stack: list[tuple[int, int]] = []
	for x in range(w):
		if passable[0, x]:
			stack.append((0, x))
		if passable[h - 1, x]:
			stack.append((h - 1, x))
	for y in range(h):
		if passable[y, 0]:
			stack.append((y, 0))
		if passable[y, w - 1]:
			stack.append((y, w - 1))
	for y, x in stack:
		reached[y, x] = True
	while stack:
		y, x = stack.pop()
		for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
			if 0 <= ny < h and 0 <= nx < w and passable[ny, nx] and not reached[ny, nx]:
				reached[ny, nx] = True
				stack.append((ny, nx))
	return reached


def remove_black_matte_border(img: Image.Image) -> Image.Image:
	"""Erase black background connected to the image border; soften near threshold."""
	rgba = np.array(img.convert("RGBA"))
	rgb = rgba[:, :, :3].astype(np.int16)
	mx = np.maximum(np.maximum(rgb[:, :, 0], rgb[:, :, 1]), rgb[:, :, 2])
	hard = mx <= BLACK_HARD
	soft = (mx > BLACK_HARD) & (mx <= BLACK_SOFT)
	matte = flood_from_border(hard | soft)
	out = rgba.copy()
	hard_kill = matte & hard
	soft_kill = matte & soft
	out[hard_kill, 3] = 0
	# soft edge: fade alpha by brightness
	if soft_kill.any():
		fade = ((mx[soft_kill] - BLACK_HARD) / max(1, BLACK_SOFT - BLACK_HARD)).clip(0, 1)
		out[soft_kill, 3] = (out[soft_kill, 3].astype(np.float32) * fade).astype(np.uint8)
	# zero RGB on fully transparent for cleaner mipmaps
	clear = out[:, :, 3] == 0
	out[clear, 0:3] = 0
	return Image.fromarray(out, "RGBA")


def resolve_sources() -> dict[str, Path]:
	if not SRC.is_dir():
		raise SystemExit(f"Source folder missing: {SRC}")
	found: dict[str, Path] = {}
	for path in SRC.iterdir():
		if path.suffix.lower() != ".png" or path.name.startswith("."):
			continue
		stem = nfc(path.stem)
		if stem in NAME_MAP:
			found[stem] = path
		else:
			print(f"  skip unknown: {path.name!r} (NFC stem={stem!r})")
	return found


def dest_for(kind: str, basename: str) -> Path:
	if kind == "chr":
		return CHR_DIR / f"{basename}.png"
	return HELPER_DIR / f"{basename}.png"


def clear_imported_cache(dest: Path) -> int:
	if not IMPORTED.is_dir():
		return 0
	n = 0
	prefix = dest.name
	for p in IMPORTED.glob(f"{prefix}*"):
		p.unlink(missing_ok=True)
		n += 1
	return n


def main() -> None:
	ap = argparse.ArgumentParser()
	ap.add_argument("--apply", action="store_true")
	args = ap.parse_args()
	found = resolve_sources()
	missing = [k for k in NAME_MAP if k not in found]
	if missing:
		print("MISSING sources:", ", ".join(missing))
	print(f"Found {len(found)}/{len(NAME_MAP)}  apply={args.apply}")
	for stem, src in sorted(found.items(), key=lambda kv: kv[0]):
		kind, basename = NAME_MAP[stem]
		dest = dest_for(kind, basename)
		img = remove_black_matte_border(Image.open(src))
		alpha0 = float(np.mean(np.array(img)[:, :, 3] == 0))
		exists = dest.exists()
		print(
			f"  {stem} → {dest.relative_to(ROOT)}  "
			f"size={img.size} alpha0={alpha0:.3f} replace={exists}"
		)
		if not args.apply:
			continue
		dest.parent.mkdir(parents=True, exist_ok=True)
		if exists:
			bak = dest.with_suffix(dest.suffix + ".bak_chr_import")
			shutil.copy2(dest, bak)
		img.save(dest, "PNG")
		cleared = clear_imported_cache(dest)
		print(f"    wrote; cleared imported cache entries={cleared}")
	if not args.apply:
		print("Dry-run only. Re-run with --apply to write.")


if __name__ == "__main__":
	main()
