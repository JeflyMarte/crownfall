#!/usr/bin/env python3
"""Import dedicated battle dots for Mourngate enemies that reused other sheets.

Sources (Desktop PixelLab zips):
  墓鐘バット → grave_bell_bat
  水晶スコーピオン → crystal_scorpion
  骸面マンティス → skullface_mantis

Output: assets/dungeon/mourngate/ENM_*_Sheet.png + resources/animation/ENM_*.tres
Game anims: idle / attack / hurt / death (9 frames each, 96px cell — Mourngate trash scale)
"""
from __future__ import annotations

import shutil
import unicodedata
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DESKTOP = Path("/Users/marte/Desktop/CrownFall設定画像/モンスター/モンスタードット絵")
WORK = Path("/tmp/crownfall_mg_missing_dots")
OUT_DIR = ROOT / "assets/dungeon/mourngate"
ANIM_DIR = ROOT / "resources/animation"
FRAME = 96
DIRECTION = "south-west"
SPEED = {"idle": 6.0, "attack": 10.0, "hurt": 8.0, "death": 6.0}

# Desktop zip stem (NFC) → (enemy_id, sheet/tres Pascal stem)
ENEMY_MAP = {
	"墓鐘バット": ("grave_bell_bat", "GraveBellBat"),
	"水晶スコーピオン": ("crystal_scorpion", "CrystalScorpion"),
	"骸面マンティス": ("skullface_mantis", "SkullfaceMantis"),
}

# PixelLab folder → game anim id, loop
ANIMATIONS: list[tuple[str, str, bool]] = [
	("Idle", "idle", True),
	("Atack", "attack", False),
	("hurt", "hurt", False),
	("Death", "death", False),
]


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


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


def extract_zips() -> Path:
	if WORK.exists():
		shutil.rmtree(WORK)
	WORK.mkdir(parents=True)
	found: dict[str, Path] = {}
	for zpath in DESKTOP.glob("*.zip"):
		stem = nfc(zpath.stem)
		if stem not in ENEMY_MAP:
			continue
		dest = WORK / stem
		dest.mkdir(parents=True, exist_ok=True)
		with zipfile.ZipFile(zpath) as zf:
			zf.extractall(dest)
		found[stem] = dest
		print(f"extracted {stem}")
	missing = sorted(set(ENEMY_MAP) - set(found))
	if missing:
		raise SystemExit(f"Desktop zip missing: {missing}")
	return WORK


def anim_folder(root: Path, anim_name: str) -> Path:
	matches = list(root.rglob(f"animations/{anim_name}/{DIRECTION}"))
	if not matches:
		# case-insensitive fallback
		for p in root.rglob("animations"):
			for child in p.iterdir():
				if child.is_dir() and child.name.lower() == anim_name.lower():
					d = child / DIRECTION
					if d.is_dir():
						return d
		raise FileNotFoundError(f"{anim_name}/{DIRECTION} under {root}")
	return matches[0]


def load_anim_frames(root: Path, anim_name: str) -> list[Image.Image]:
	folder = anim_folder(root, anim_name)
	paths = sorted(folder.glob("frame_*.png"))
	if not paths:
		raise FileNotFoundError(f"no frames in {folder}")
	return [fit_frame(Image.open(p), FRAME) for p in paths]


def write_tres(sheet_res: str, tres_path: Path, meta: list[tuple[str, bool, int, int]]) -> None:
	total = sum(item[3] for item in meta)
	lines = [
		'[gd_resource type="SpriteFrames" load_steps=2 format=3]',
		"",
		f'[ext_resource type="Texture2D" path="{sheet_res}" id="1_sheet"]',
		"",
	]
	atlas_ids: list[str] = []
	for i in range(total):
		lines.extend(
			[
				f'[sub_resource type="AtlasTexture" id="f{i}"]',
				'atlas = ExtResource("1_sheet")',
				f"region = Rect2({i * FRAME}, 0, {FRAME}, {FRAME})",
				"",
			]
		)
		atlas_ids.append(f"f{i}")

	anim_entries: list[str] = []
	cursor = 0
	for anim_id, loop, _start, count in meta:
		speed = SPEED.get(anim_id, 8.0)
		frame_refs = ", ".join(
			f'{{"duration": 1.0, "texture": SubResource("{atlas_ids[cursor + i]}") }}'
			for i in range(count)
		)
		anim_entries.append(
			f'{{"frames": [{frame_refs}], "loop": {"true" if loop else "false"}, '
			f'"name": &"{anim_id}", "speed": {speed}}}'
		)
		cursor += count

	lines.append("[resource]")
	lines.append(f"animations = [{', '.join(anim_entries)}]")
	lines.append("")
	tres_path.write_text("\n".join(lines), encoding="utf-8")


def import_one(stem: str, src_root: Path) -> str:
	_enemy_id, pascal = ENEMY_MAP[stem]
	all_frames: list[Image.Image] = []
	meta: list[tuple[str, bool, int, int]] = []
	for src_name, anim_id, loop in ANIMATIONS:
		start = len(all_frames)
		frames = load_anim_frames(src_root, src_name)
		all_frames.extend(frames)
		meta.append((anim_id, loop, start, len(frames)))
		print(f"  {stem} {anim_id}: {len(frames)} frames")

	sheet = Image.new("RGBA", (FRAME * len(all_frames), FRAME), (0, 0, 0, 0))
	for i, frame in enumerate(all_frames):
		sheet.paste(frame, (i * FRAME, 0), frame)

	OUT_DIR.mkdir(parents=True, exist_ok=True)
	sheet_path = OUT_DIR / f"ENM_{pascal}_Sheet.png"
	sheet.save(sheet_path)
	sheet_res = f"res://assets/dungeon/mourngate/ENM_{pascal}_Sheet.png"
	tres_path = ANIM_DIR / f"ENM_{pascal}.tres"
	write_tres(sheet_res, tres_path, meta)
	print(f"  wrote {sheet_path.name} ({sheet.size[0]}x{sheet.size[1]}) + {tres_path.name}")
	return f"res://{tres_path.relative_to(ROOT).as_posix()}"


def patch_dungeon_scene(tres_by_id: dict[str, str]) -> None:
	path = ROOT / "scripts/dungeon/DungeonScene.gd"
	text = path.read_text(encoding="utf-8")
	for enemy_id, tres in tres_by_id.items():
		old = None
		for line in text.splitlines():
			if line.strip().startswith(f'"{enemy_id}":'):
				old = line
				break
		if old is None:
			raise SystemExit(f"ENEMY_SPRITE_MAP missing key: {enemy_id}")
		indent = old[: len(old) - len(old.lstrip("\t"))]
		new = f'{indent}"{enemy_id}": "{tres}",'
		text = text.replace(old, new, 1)
		print(f"  map {enemy_id} -> {tres}")
	path.write_text(text, encoding="utf-8")


def main() -> None:
	if not DESKTOP.is_dir():
		raise SystemExit(f"Desktop folder missing: {DESKTOP}")
	work = extract_zips()
	tres_by_id: dict[str, str] = {}
	for stem, (enemy_id, _pascal) in ENEMY_MAP.items():
		tres_by_id[enemy_id] = import_one(stem, work / stem)
	patch_dungeon_scene(tres_by_id)
	print("done")


if __name__ == "__main__":
	main()
