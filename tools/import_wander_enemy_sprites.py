#!/usr/bin/env python3
"""Import battle dots for cosmic_duck / crown_raven from Downloads PixelLab zips.

Sources:
  ~/Downloads/コズミックダック.zip
  ~/Downloads/トレジャーレイヴン.zip

Output:
  assets/dungeon/mourngate/ENM_*_Sheet.png
  resources/animation/ENM_*.tres
  assets/codex/enemies/ART_ENM_*.png  (idle frame 0)
  assets/ui/combat/enemy_icons/ICO_ENM_Turn_*.png

Also patches DungeonScene.gd ENEMY_SPRITE_MAP and IconPaths.gd.
"""
from __future__ import annotations

import shutil
import unicodedata
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path("/Users/marte/Downloads")
WORK = Path("/tmp/crownfall_wander_dots")
OUT_DIR = ROOT / "assets/dungeon/mourngate"
ANIM_DIR = ROOT / "resources/animation"
CODEX_DIR = ROOT / "assets/codex/enemies"
TURN_DIR = ROOT / "assets/ui/combat/enemy_icons"
FRAME = 96
CODEX_SIZE = 256
TURN_SIZE = 64
DIRECTION = "south-west"
SPEED = {"idle": 6.0, "attack": 10.0, "hurt": 8.0, "death": 6.0}

# zip stem (NFC) → (enemy_id, Pascal stem)
ENEMY_MAP = {
	"コズミックダック": ("cosmic_duck", "CosmicDuck"),
	"トレジャーレイヴン": ("crown_raven", "CrownRaven"),
}

# game anim → folder name keywords (matched case-insensitive against anim dir stem)
ANIM_KEYWORDS: list[tuple[str, bool, tuple[str, ...]]] = [
	("idle", True, ("idle",)),
	("attack", False, ("attack", "wind_attack", "dark_wind")),
	("hurt", False, ("hit", "hurt")),
	("death", False, ("death", "down")),
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


def find_zip(stem: str) -> Path:
	want = nfc(stem)
	for zpath in DOWNLOADS.glob("*.zip"):
		if nfc(zpath.stem) == want:
			return zpath
	raise FileNotFoundError(f"zip not found in Downloads: {stem}.zip")


def extract_zips() -> dict[str, Path]:
	if WORK.exists():
		shutil.rmtree(WORK)
	WORK.mkdir(parents=True)
	found: dict[str, Path] = {}
	for stem in ENEMY_MAP:
		zpath = find_zip(stem)
		dest = WORK / stem
		dest.mkdir(parents=True, exist_ok=True)
		with zipfile.ZipFile(zpath) as zf:
			zf.extractall(dest)
		found[stem] = dest
		print(f"extracted {stem} from {zpath.name}")
	return found


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
	lower_map = {name.lower(): path for name, path in anim_dirs.items()}
	for key in keywords:
		key_l = key.lower()
		for name_l, path in lower_map.items():
			if key_l in name_l:
				return path
	raise FileNotFoundError(f"no anim matching {keywords} in {list(anim_dirs)}")


def load_anim_frames(anim_dir: Path) -> list[Image.Image]:
	facing = anim_dir / DIRECTION
	if not facing.is_dir():
		# any single facing folder
		subs = [d for d in anim_dir.iterdir() if d.is_dir()]
		if not subs:
			raise FileNotFoundError(f"no facing under {anim_dir}")
		facing = subs[0]
	paths = sorted(facing.glob("frame_*.png"))
	if not paths:
		raise FileNotFoundError(f"no frames in {facing}")
	return [fit_frame(Image.open(p), FRAME) for p in paths]


def write_tres(sheet_res: str, tres_path: Path, meta: list[tuple[str, bool, int]]) -> None:
	total = sum(count for _a, _l, count in meta)
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
	for anim_id, loop, count in meta:
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


def write_codex_and_turn(pascal: str, idle0: Image.Image) -> None:
	CODEX_DIR.mkdir(parents=True, exist_ok=True)
	TURN_DIR.mkdir(parents=True, exist_ok=True)
	codex = fit_frame(idle0, CODEX_SIZE)
	turn = fit_frame(idle0, TURN_SIZE)
	codex_path = CODEX_DIR / f"ART_ENM_{pascal}.png"
	turn_path = TURN_DIR / f"ICO_ENM_Turn_{pascal}.png"
	codex.save(codex_path)
	turn.save(turn_path)
	print(f"  wrote {codex_path.name} + {turn_path.name}")


def import_one(stem: str, src_root: Path) -> str:
	enemy_id, pascal = ENEMY_MAP[stem]
	anim_dirs = list_anim_dirs(src_root)
	all_frames: list[Image.Image] = []
	meta: list[tuple[str, bool, int]] = []
	idle0: Image.Image | None = None
	for anim_id, loop, keywords in ANIM_KEYWORDS:
		adir = pick_anim_dir(anim_dirs, keywords)
		frames = load_anim_frames(adir)
		if anim_id == "idle" and frames:
			# original before fit for codex — re-open first source frame
			facing = adir / DIRECTION
			if not facing.is_dir():
				facing = next(d for d in adir.iterdir() if d.is_dir())
			src0 = sorted(facing.glob("frame_*.png"))[0]
			idle0 = Image.open(src0).convert("RGBA")
		all_frames.extend(frames)
		meta.append((anim_id, loop, len(frames)))
		print(f"  {stem} {anim_id}: {len(frames)} from {adir.name}")

	sheet = Image.new("RGBA", (FRAME * len(all_frames), FRAME), (0, 0, 0, 0))
	for i, frame in enumerate(all_frames):
		sheet.paste(frame, (i * FRAME, 0), frame)

	OUT_DIR.mkdir(parents=True, exist_ok=True)
	ANIM_DIR.mkdir(parents=True, exist_ok=True)
	sheet_path = OUT_DIR / f"ENM_{pascal}_Sheet.png"
	sheet.save(sheet_path)
	sheet_res = f"res://assets/dungeon/mourngate/ENM_{pascal}_Sheet.png"
	tres_path = ANIM_DIR / f"ENM_{pascal}.tres"
	write_tres(sheet_res, tres_path, meta)
	print(f"  wrote {sheet_path.name} ({sheet.size[0]}x{sheet.size[1]}) + {tres_path.name}")
	if idle0 is not None:
		write_codex_and_turn(pascal, idle0)
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


def patch_icon_paths() -> None:
	path = ROOT / "scripts/ui/IconPaths.gd"
	text = path.read_text(encoding="utf-8")
	replacements = {
		'"enemy:cosmic_duck":': (
			'\t"enemy:cosmic_duck":           "res://assets/codex/enemies/ART_ENM_CosmicDuck.png",'
		),
		'"enemy:crown_raven":': (
			'\t"enemy:crown_raven":           "res://assets/codex/enemies/ART_ENM_CrownRaven.png",'
		),
	}
	# also add turn icons if missing
	turn_lines = {
		"cosmic_duck": '\t"enemy_turn:cosmic_duck":     "res://assets/ui/combat/enemy_icons/ICO_ENM_Turn_CosmicDuck.png",',
		"crown_raven": '\t"enemy_turn:crown_raven":     "res://assets/ui/combat/enemy_icons/ICO_ENM_Turn_CrownRaven.png",',
	}
	lines = text.splitlines()
	out: list[str] = []
	seen_turn: set[str] = set()
	for line in lines:
		stripped = line.strip()
		replaced = False
		for prefix, new_line in replacements.items():
			if stripped.startswith(prefix):
				out.append(new_line)
				replaced = True
				break
		if replaced:
			continue
		for eid in turn_lines:
			if stripped.startswith(f'"enemy_turn:{eid}":'):
				out.append(turn_lines[eid])
				seen_turn.add(eid)
				replaced = True
				break
		if replaced:
			continue
		out.append(line)
		# insert turn entries after enemy:crown_raven line if absent
		if stripped.startswith('"enemy:crown_raven":'):
			for eid, tline in turn_lines.items():
				if eid not in seen_turn and f'"enemy_turn:{eid}":' not in text:
					out.append(tline)
					seen_turn.add(eid)
	path.write_text("\n".join(out) + "\n", encoding="utf-8")
	print("  patched IconPaths.gd")


def main() -> None:
	found = extract_zips()
	tres_by_id: dict[str, str] = {}
	for stem in ENEMY_MAP:
		tres_by_id[ENEMY_MAP[stem][0]] = import_one(stem, found[stem])
	patch_dungeon_scene(tres_by_id)
	patch_icon_paths()
	print("done")


if __name__ == "__main__":
	main()
