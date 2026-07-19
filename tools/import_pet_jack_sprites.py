#!/usr/bin/env python3
"""Import battle dots for pet Jack from ~/Downloads/ジャック.zip.

Output:
  assets/dungeon/mourngate/PET_Jack_Sheet.png
  resources/animation/PET_Jack.tres
  resources/pets/pet_jack.tres  (sprite_resource_path)
  scripts/pets/PetSystem.gd     (PLACEHOLDER → PET_Jack)
"""
from __future__ import annotations

import re
import shutil
import unicodedata
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads"
WORK = Path("/tmp/crownfall_pet_jack_import")
OUT_DIR = ROOT / "assets/dungeon/mourngate"
ANIM_DIR = ROOT / "resources/animation"
PET_TRES = ROOT / "resources/pets/pet_jack.tres"
PET_SYSTEM = ROOT / "scripts/pets/PetSystem.gd"
FRAME = 96
SPEED = {"idle": 6.0, "attack": 10.0, "hurt": 8.0, "death": 6.0}
TRES_RES = "res://resources/animation/PET_Jack.tres"
SHEET_RES = "res://assets/dungeon/mourngate/PET_Jack_Sheet.png"

# game anim → (keywords, preferred facings)
# Idle zip は south（正面）のみ → 戦闘 idle は味方CHR同様、横向き walk を使う。
ANIM_SPEC: list[tuple[str, bool, tuple[str, ...], tuple[str, ...]]] = [
	("idle", True, ("steps_forward", "rhythmic_gait", "walk"), ("north-east", "north", "east", "south-east")),
	("attack", False, ("attack_animation", "attack"), ("north-east", "north", "south-east", "east")),
	("hurt", False, ("head_turned", "initially_standing", "hit", "hurt"), ("north-east", "north", "south")),
	("death", False, ("slowly_lowers", "death", "down"), ("north-east", "north", "south")),
]


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def find_zip() -> Path:
	for zpath in DOWNLOADS.glob("*.zip"):
		if nfc(zpath.stem) == "ジャック":
			return zpath
	raise FileNotFoundError("Downloads/ジャック.zip not found")


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


def list_anim_dirs(root: Path) -> dict[str, Path]:
	out: dict[str, Path] = {}
	for anim_root in root.rglob("animations"):
		if not anim_root.is_dir():
			continue
		for child in anim_root.iterdir():
			if child.is_dir():
				out[child.name] = child
	return out


def pick_anim_dir(anim_dirs: dict[str, Path], keywords: tuple[str, ...]) -> Path:
	# Prefer longer / more specific keyword matches first
	scored: list[tuple[int, Path]] = []
	for name, path in anim_dirs.items():
		name_l = name.lower()
		for kw in keywords:
			if kw.lower() in name_l:
				scored.append((len(kw), path))
				break
	if not scored:
		raise FileNotFoundError(f"no anim matching {keywords} in {list(anim_dirs)}")
	scored.sort(key=lambda t: t[0], reverse=True)
	return scored[0][1]


def pick_facing(anim_dir: Path, prefs: tuple[str, ...]) -> Path:
	dirs = [d for d in anim_dir.iterdir() if d.is_dir()]
	if not dirs:
		raise FileNotFoundError(f"no facing under {anim_dir}")
	by_name = {d.name: d for d in dirs}
	for pref in prefs:
		if pref in by_name:
			return by_name[pref]
	return dirs[0]


def load_frames(anim_dir: Path, prefs: tuple[str, ...]) -> list[Image.Image]:
	facing = pick_facing(anim_dir, prefs)
	paths = sorted(facing.glob("frame_*.png"))
	if not paths:
		raise FileNotFoundError(f"no frames in {facing}")
	print(f"    facing={facing.name} n={len(paths)}")
	return [fit_frame(Image.open(p), FRAME) for p in paths]


def write_tres(meta: list[tuple[str, bool, int]]) -> None:
	total = sum(c for _a, _l, c in meta)
	lines = [
		'[gd_resource type="SpriteFrames" load_steps=2 format=3]',
		"",
		f'[ext_resource type="Texture2D" path="{SHEET_RES}" id="1_sheet"]',
		"",
	]
	ids: list[str] = []
	for i in range(total):
		lines.extend(
			[
				f'[sub_resource type="AtlasTexture" id="f{i}"]',
				'atlas = ExtResource("1_sheet")',
				f"region = Rect2({i * FRAME}, 0, {FRAME}, {FRAME})",
				"",
			]
		)
		ids.append(f"f{i}")
	entries: list[str] = []
	cursor = 0
	for anim_id, loop, count in meta:
		speed = SPEED.get(anim_id, 8.0)
		refs = ", ".join(
			f'{{"duration": 1.0, "texture": SubResource("{ids[cursor + i]}") }}'
			for i in range(count)
		)
		entries.append(
			f'{{"frames": [{refs}], "loop": {"true" if loop else "false"}, '
			f'"name": &"{anim_id}", "speed": {speed}}}'
		)
		cursor += count
	lines.append("[resource]")
	lines.append(f"animations = [{', '.join(entries)}]")
	lines.append("")
	tres_path = ANIM_DIR / "PET_Jack.tres"
	tres_path.write_text("\n".join(lines), encoding="utf-8")
	print(f"wrote {tres_path}")


def patch_pet_data() -> None:
	text = PET_TRES.read_text(encoding="utf-8")
	new, n = re.subn(
		r'sprite_resource_path = ".*"',
		f'sprite_resource_path = "{TRES_RES}"',
		text,
		count=1,
	)
	if n == 0:
		raise SystemExit("pet_jack.tres: sprite_resource_path not found")
	PET_TRES.write_text(new, encoding="utf-8")
	print(f"patched {PET_TRES.name}")


def patch_pet_system() -> None:
	text = PET_SYSTEM.read_text(encoding="utf-8")
	new, n = re.subn(
		r'const PLACEHOLDER_SPRITE: String = ".*"',
		f'const PLACEHOLDER_SPRITE: String = "{TRES_RES}"',
		text,
		count=1,
	)
	if n == 0:
		raise SystemExit("PetSystem.gd: PLACEHOLDER_SPRITE not found")
	PET_SYSTEM.write_text(new, encoding="utf-8")
	print(f"patched {PET_SYSTEM.name}")


def main() -> None:
	zpath = find_zip()
	if WORK.exists():
		shutil.rmtree(WORK)
	WORK.mkdir(parents=True)
	with zipfile.ZipFile(zpath) as zf:
		zf.extractall(WORK)
	print(f"extracted {zpath.name}")

	anim_dirs = list_anim_dirs(WORK)
	all_frames: list[Image.Image] = []
	meta: list[tuple[str, bool, int]] = []
	used: set[Path] = set()
	for anim_id, loop, keywords, prefs in ANIM_SPEC:
		adir = pick_anim_dir(anim_dirs, keywords)
		if adir in used and anim_id != "idle":
			# avoid reusing Attack for hurt etc.
			remaining = {k: v for k, v in anim_dirs.items() if v not in used}
			adir = pick_anim_dir(remaining, keywords)
		used.add(adir)
		print(f"  {anim_id} <- {adir.name}")
		frames = load_frames(adir, prefs)
		all_frames.extend(frames)
		meta.append((anim_id, loop, len(frames)))

	OUT_DIR.mkdir(parents=True, exist_ok=True)
	ANIM_DIR.mkdir(parents=True, exist_ok=True)
	sheet = Image.new("RGBA", (FRAME * len(all_frames), FRAME), (0, 0, 0, 0))
	for i, frame in enumerate(all_frames):
		sheet.paste(frame, (i * FRAME, 0), frame)
	sheet_path = OUT_DIR / "PET_Jack_Sheet.png"
	sheet.save(sheet_path)
	print(f"wrote {sheet_path.name} ({sheet.size[0]}x{sheet.size[1]})")
	write_tres(meta)
	patch_pet_data()
	patch_pet_system()
	print("done")


if __name__ == "__main__":
	main()
