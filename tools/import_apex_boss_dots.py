#!/usr/bin/env python3
"""Import apex conquest boss dots from ~/Downloads/アップデートVer2 zips.

Outputs per boss:
  assets/battle/bosses/BOSS_{Stem}_Sheet.png
  resources/animation/BOSS_{Stem}.tres
  assets/ui/combat/enemy_icons/ICO_ENM_Turn_{Stem}.png  (idle frame, no baked plate)

Usage:
  python3 tools/import_apex_boss_dots.py
  python3 tools/import_apex_boss_dots.py アルバーク
"""
from __future__ import annotations

import shutil
import sys
import unicodedata
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads"
DOWNLOADS_VER2 = DOWNLOADS / "アップデートVer2"
WORK = Path("/tmp/crownfall_apex_boss_import")

FRAME = 128
DIRECTION = "south-west"
TURN_SIZE = 128

# zip stem (NFC) → (enemy_id, tres/file stem e.g. Albark)
BOSS_MAP: dict[str, tuple[str, str]] = {
	"アルバーク": ("albark", "Albark"),
	"フォージ・ドルミエント": ("forgedormient", "Forgedormient"),
}

SRC_ANIMS: list[tuple[str, str, bool]] = [
	("Idle", "idle", True),
	("Attack", "attack", False),
	("Hurt", "hurt", False),
	("Death", "death", False),
]


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def find_zip(stem: str) -> Path:
	for base in (DOWNLOADS_VER2, DOWNLOADS):
		if not base.is_dir():
			continue
		for zpath in base.glob("*.zip"):
			if nfc(zpath.stem) == stem:
				return zpath
	raise SystemExit(f"Missing zip for {stem} under Downloads or アップデートVer2")


def fit_frame(src: Image.Image, size: int) -> Image.Image:
	img = src.convert("RGBA")
	bbox = img.getbbox()
	if bbox is None:
		return Image.new("RGBA", (size, size), (0, 0, 0, 0))
	cropped = img.crop(bbox)
	cw, ch = cropped.size
	margin = int(size * 0.08)
	target = size - margin * 2
	ratio = min(target / cw, target / ch)
	nw, nh = max(1, int(cw * ratio)), max(1, int(ch * ratio))
	resized = cropped.resize((nw, nh), Image.Resampling.NEAREST)
	frame = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	ox = (size - nw) // 2
	oy = size - nh - margin
	frame.paste(resized, (ox, oy), resized)
	return frame


def extract_zip(zpath: Path, dest: Path) -> Path:
	if dest.exists():
		shutil.rmtree(dest)
	dest.mkdir(parents=True)
	with zipfile.ZipFile(zpath) as zf:
		zf.extractall(dest)
	for p in dest.rglob("animations"):
		if p.is_dir():
			return p
	raise SystemExit(f"No animations/ in {zpath}")


def anim_dir(anim_root: Path, src_name: str) -> Path:
	direct = anim_root / src_name
	if direct.is_dir():
		return direct
	for child in anim_root.iterdir():
		if child.is_dir() and child.name.lower() == src_name.lower():
			return child
	raise FileNotFoundError(f"missing animation folder {src_name} under {anim_root}")


def direction_dir(anim_folder: Path) -> Path:
	by_name = {d.name: d for d in anim_folder.iterdir() if d.is_dir()}
	if DIRECTION in by_name:
		return by_name[DIRECTION]
	for pref in ("south-west", "south", "north-east", "east"):
		if pref in by_name:
			return by_name[pref]
	children = [d for d in anim_folder.iterdir() if d.is_dir()]
	if not children:
		raise FileNotFoundError(f"no direction under {anim_folder}")
	return children[0]


def load_anim_frames(anim_root: Path, src_name: str) -> list[Image.Image]:
	folder = direction_dir(anim_dir(anim_root, src_name))
	frames = sorted(folder.glob("frame_*.png"))
	if not frames:
		raise FileNotFoundError(f"no frames in {folder}")
	return [fit_frame(Image.open(fp), FRAME) for fp in frames]


def build_sheet(anim_root: Path) -> tuple[Image.Image, list[tuple[str, bool, int, int]]]:
	all_frames: list[Image.Image] = []
	meta: list[tuple[str, bool, int, int]] = []
	for src_name, anim_id, loop in SRC_ANIMS:
		start = len(all_frames)
		chunk = load_anim_frames(anim_root, src_name)
		all_frames.extend(chunk)
		meta.append((anim_id, loop, start, len(chunk)))
	sheet = Image.new("RGBA", (FRAME * len(all_frames), FRAME), (0, 0, 0, 0))
	for i, frame in enumerate(all_frames):
		sheet.paste(frame, (i * FRAME, 0), frame)
	return sheet, meta


def write_tres(stem: str, meta: list[tuple[str, bool, int, int]]) -> Path:
	sheet_name = f"BOSS_{stem}_Sheet.png"
	out_tres = ROOT / "resources" / "animation" / f"BOSS_{stem}.tres"
	total = sum(item[3] for item in meta)
	lines = [
		'[gd_resource type="SpriteFrames" load_steps=2 format=3]',
		"",
		f'[ext_resource type="Texture2D" path="res://assets/battle/bosses/{sheet_name}" id="1_sheet"]',
		"",
	]
	atlas_ids: list[str] = []
	for idx in range(total):
		lines.extend(
			[
				f'[sub_resource type="AtlasTexture" id="f{idx}"]',
				'atlas = ExtResource("1_sheet")',
				f"region = Rect2({idx * FRAME}, 0, {FRAME}, {FRAME})",
				"",
			]
		)
		atlas_ids.append(f"f{idx}")

	anim_entries: list[str] = []
	cursor = 0
	for anim_id, loop, _start, count in meta:
		frame_refs = ", ".join(
			f'{{"duration": 1.0, "texture": SubResource("{atlas_ids[cursor + i]}")}}'
			for i in range(count)
		)
		anim_entries.append(
			f'{{"frames": [{frame_refs}], "loop": {"true" if loop else "false"}, '
			f'"name": &"{anim_id}", "speed": 8.0}}'
		)
		cursor += count

	lines.append("[resource]")
	lines.append(f"animations = [{', '.join(anim_entries)}]")
	lines.append("")
	out_tres.write_text("\n".join(lines), encoding="utf-8")
	return out_tres


def import_boss(zip_stem: str, enemy_id: str, file_stem: str) -> None:
	print(f"\n== {zip_stem} → {enemy_id} ==")
	zpath = find_zip(zip_stem)
	work_dir = WORK / zip_stem
	anim_root = extract_zip(zpath, work_dir)
	sheet, meta = build_sheet(anim_root)
	out_sheet = ROOT / "assets" / "battle" / "bosses" / f"BOSS_{file_stem}_Sheet.png"
	out_sheet.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(out_sheet)
	out_tres = write_tres(file_stem, meta)
	idle0 = load_anim_frames(anim_root, "Idle")[0]
	out_turn = ROOT / "assets/ui/combat/enemy_icons" / f"ICO_ENM_Turn_{file_stem}.png"
	out_turn.parent.mkdir(parents=True, exist_ok=True)
	idle0.resize((TURN_SIZE, TURN_SIZE), Image.Resampling.NEAREST).save(out_turn)
	print(f"  sheet {out_sheet.relative_to(ROOT)} ({sheet.size[0]}x{sheet.size[1]})")
	print(f"  tres  {out_tres.relative_to(ROOT)}")
	print(f"  turn  {out_turn.relative_to(ROOT)}")


def main() -> None:
	only: set[str] | None = None
	if len(sys.argv) > 1:
		only = {nfc(a) for a in sys.argv[1:]}
		unknown = only - set(BOSS_MAP)
		if unknown:
			raise SystemExit(f"unknown boss name(s): {sorted(unknown)}")
	if WORK.exists():
		shutil.rmtree(WORK)
	targets = only if only is not None else set(BOSS_MAP)
	for zip_stem in sorted(targets):
		enemy_id, file_stem = BOSS_MAP[zip_stem]
		import_boss(zip_stem, enemy_id, file_stem)
	print("\nDONE")


if __name__ == "__main__":
	main()
