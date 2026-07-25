#!/usr/bin/env python3
"""Import Frostridge battle dots + codex arts.

Sources (Desktop):
  モンスター/モンスタードット絵/フロストリッジ/*.zip
  モンスター/モンスター図鑑/フロストリッジ/*.{png,PNG}

Outputs:
  assets/battle/enemies/ENM_*_Sheet.png  (boss → assets/battle/bosses/BOSS_*_Sheet.png)
  resources/animation/ENM_*.tres / BOSS_*.tres
  assets/codex/enemies/ART_ENM_*.png / ART_BOSS_*.png
  assets/ui/combat/enemy_icons/ICO_ENM_Turn_*.png

Patches DungeonScene ENEMY_SPRITE_MAP / BOSS_ENEMY_SPRITE_MAP and IconPaths.
"""
from __future__ import annotations

import re
import shutil
import unicodedata
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DESKTOP_MON = Path("/Users/marte/Desktop/CrownFall設定画像/モンスター")
WORK = Path("/tmp/crownfall_frostridge_dots")
BATTLE_DIR = ROOT / "assets/battle/enemies"
BOSS_DIR = ROOT / "assets/battle/bosses"
ANIM_DIR = ROOT / "resources/animation"
CODEX_DIR = ROOT / "assets/codex/enemies"
TURN_DIR = ROOT / "assets/ui/combat/enemy_icons"
FRAME = 96
CODEX_SIZE = 512
TURN_SIZE = 64
DIRECTION_PREF = ("south-west", "west", "south", "south-east", "east")
SPEED = {"idle": 6.0, "attack": 10.0, "hurt": 8.0, "death": 6.0}

# Desktop zip/png stem (NFC) → (enemy_id, Pascal, is_boss)
ENEMY_MAP: dict[str, tuple[str, str, bool]] = {
	"氷爪ラプター": ("frost_claw_raptor", "FrostClawRaptor", False),
	"ヴェルガロン": ("vergaron", "Vergaron", False),
	"ストームジョー": ("storm_joe", "StormJoe", False),
	"オルドレクス": ("oldrex", "Oldrex", False),
	"グレイオス": ("greios", "Greios", False),
	"氷河の番人": ("glacier_warden", "GlacierWarden", False),
	"スノーストーム": ("wind_ripper", "WindRipper", False),
	"始祖の竜 エルディオン": ("eldion", "Eldion", True),
}

# 図鑑ファイル名の揺れ
CODEX_ALIASES: dict[str, str] = {
	"霜爪ラプター": "氷爪ラプター",
	"始祖の竜エルディオン": "始祖の竜 エルディオン",
	"エルディオン": "始祖の竜 エルディオン",
}


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def find_named_dir(parent: Path, needle: str) -> Path:
	want = nfc(needle)
	if not parent.exists():
		raise FileNotFoundError(parent)
	for p in parent.iterdir():
		if p.is_dir() and want in nfc(p.name):
			return p
	raise FileNotFoundError(f"{needle} under {parent}")


def find_desktop_subdir(category: str, biome: str) -> Path:
	cat = find_named_dir(DESKTOP_MON, category)
	return find_named_dir(cat, biome)


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


def strip_edge_bg(img: Image.Image, light_threshold: int = 245) -> Image.Image:
	img = img.convert("RGBA")
	w, h = img.size
	px = img.load()
	visited = [[False] * w for _ in range(h)]
	stack: list[tuple[int, int]] = []

	def is_light(x: int, y: int) -> bool:
		r, g, b, a = px[x, y]
		if a < 8:
			return True
		return r >= light_threshold and g >= light_threshold and b >= light_threshold

	for x in range(w):
		stack.append((x, 0))
		stack.append((x, h - 1))
	for y in range(h):
		stack.append((0, y))
		stack.append((w - 1, y))
	while stack:
		x, y = stack.pop()
		if x < 0 or y < 0 or x >= w or y >= h or visited[y][x]:
			continue
		visited[y][x] = True
		if not is_light(x, y):
			continue
		px[x, y] = (0, 0, 0, 0)
		stack.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
	return img


def list_anim_dirs(root: Path) -> dict[str, Path]:
	out: dict[str, Path] = {}
	for anim_root in root.rglob("animations"):
		if not anim_root.is_dir():
			continue
		for child in anim_root.iterdir():
			if not child.is_dir():
				continue
			chosen: Path | None = None
			for dname in DIRECTION_PREF:
				cand = child / dname
				if cand.is_dir() and list(cand.glob("frame_*.png")):
					chosen = cand
					break
			if chosen is None:
				for sub in child.iterdir():
					if sub.is_dir() and list(sub.glob("frame_*.png")):
						chosen = sub
						break
			if chosen is not None:
				out[nfc(child.name).lower()] = chosen
	return out


def pick_anim_dir(dirs: dict[str, Path], keywords: tuple[str, ...]) -> Path | None:
	for key, path in dirs.items():
		for kw in keywords:
			if kw in key:
				return path
	return None


def load_frames(folder: Path) -> list[Image.Image]:
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


def import_battle_zip(stem: str, src_root: Path, is_boss: bool) -> tuple[str, str, Image.Image]:
	enemy_id, pascal, _ = ENEMY_MAP[stem]
	dirs = list_anim_dirs(src_root)
	plan: list[tuple[str, bool, tuple[str, ...]]] = [
		("idle", True, ("idle", "stand", "rest", "undulat", "weight_shift")),
		("attack", False, ("attack", "atack")),
		("hurt", False, ("hurt", "hit", "recoil", "wince", "hunches")),
		("death", False, ("death", "down", "convulse")),
	]
	all_frames: list[Image.Image] = []
	meta: list[tuple[str, bool, int, int]] = []
	idle_frames: list[Image.Image] | None = None
	for anim_id, loop, kws in plan:
		folder = pick_anim_dir(dirs, kws)
		if folder is None:
			if anim_id == "attack" and idle_frames is not None:
				print(f"  {stem} attack: fallback to idle ({len(idle_frames)} frames)")
				frames = idle_frames
			else:
				raise FileNotFoundError(f"{stem}: missing anim for {anim_id} in {list(dirs)}")
		else:
			frames = load_frames(folder)
			print(f"  {stem} {anim_id}: {len(frames)} ({folder.parent.name}/{folder.name})")
		if anim_id == "idle":
			idle_frames = frames
		start = len(all_frames)
		all_frames.extend(frames)
		meta.append((anim_id, loop, start, len(frames)))

	sheet = Image.new("RGBA", (FRAME * len(all_frames), FRAME), (0, 0, 0, 0))
	for i, frame in enumerate(all_frames):
		sheet.paste(frame, (i * FRAME, 0), frame)

	prefix = "BOSS" if is_boss else "ENM"
	out_dir = BOSS_DIR if is_boss else BATTLE_DIR
	out_dir.mkdir(parents=True, exist_ok=True)
	sheet_path = out_dir / f"{prefix}_{pascal}_Sheet.png"
	sheet_res = f"res://{sheet_path.relative_to(ROOT).as_posix()}"
	tres_path = ANIM_DIR / f"{prefix}_{pascal}.tres"

	sheet.save(sheet_path)
	write_tres(sheet_res, tres_path, meta)
	print(f"  wrote {sheet_path.relative_to(ROOT)} + {tres_path.name}")
	tres_res = f"res://{tres_path.relative_to(ROOT).as_posix()}"
	return enemy_id, tres_res, all_frames[0]


def save_codex(pascal: str, src: Image.Image, is_boss: bool) -> Path:
	CODEX_DIR.mkdir(parents=True, exist_ok=True)
	prefix = "BOSS" if is_boss else "ENM"
	out = CODEX_DIR / f"ART_{prefix}_{pascal}.png"
	img = strip_edge_bg(src)
	bbox = img.getbbox()
	if bbox:
		img = img.crop(bbox)
	canvas = Image.new("RGBA", (CODEX_SIZE, CODEX_SIZE), (0, 0, 0, 0))
	cw, ch = img.size
	ratio = min((CODEX_SIZE * 0.92) / cw, (CODEX_SIZE * 0.92) / ch)
	nw, nh = max(1, int(cw * ratio)), max(1, int(ch * ratio))
	resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
	ox = (CODEX_SIZE - nw) // 2
	oy = (CODEX_SIZE - nh) // 2
	canvas.paste(resized, (ox, oy), resized)
	canvas.save(out)
	print(f"  codex {out.name}")
	return out


def save_turn_icon(pascal: str, idle: Image.Image) -> Path:
	TURN_DIR.mkdir(parents=True, exist_ok=True)
	out = TURN_DIR / f"ICO_ENM_Turn_{pascal}.png"
	fit_frame(idle, TURN_SIZE).save(out)
	print(f"  turn {out.name}")
	return out


def patch_map_line(path: Path, key: str, value: str) -> None:
	text = path.read_text(encoding="utf-8")
	pattern = re.compile(rf'^(\t+)"{re.escape(key)}":\s*"[^"]*",', re.M)
	m = pattern.search(text)
	if not m:
		raise SystemExit(f"{path.name}: missing key {key}")
	indent = m.group(1)
	new = f'{indent}"{key}": "{value}",'
	text = text[: m.start()] + new + text[m.end() :]
	path.write_text(text, encoding="utf-8")
	print(f"  patch {path.name} {key} -> {value}")


def ensure_icon_key(path: Path, key: str, value: str, after_key: str) -> None:
	text = path.read_text(encoding="utf-8")
	if f'"{key}"' in text:
		patch_map_line(path, key, value)
		return
	pattern = re.compile(rf'^(\t+)"{re.escape(after_key)}":\s*"[^"]*",', re.M)
	m = pattern.search(text)
	if not m:
		raise SystemExit(f"{path.name}: cannot insert after {after_key}")
	indent = m.group(1)
	insert = f'{indent}"{key}": "{value}",\n'
	text = text[: m.end()] + "\n" + insert + text[m.end() :]
	path.write_text(text, encoding="utf-8")
	print(f"  insert {path.name} {key}")


def resolve_codex_pngs(codex_root: Path) -> dict[str, Path]:
	raw: dict[str, Path] = {}
	for p in codex_root.iterdir():
		if p.suffix.lower() != ".png":
			continue
		raw[nfc(p.stem)] = p
	out: dict[str, Path] = {}
	for stem, path in raw.items():
		canon = CODEX_ALIASES.get(stem, stem)
		canon = canon.replace("\u3000", " ").strip()
		out[canon] = path
	return out


def main() -> None:
	dot_root = find_desktop_subdir("モンスタードット絵", "フロストリッジ")
	codex_root = find_desktop_subdir("モンスター図鑑", "フロストリッジ")
	if WORK.exists():
		shutil.rmtree(WORK)
	WORK.mkdir(parents=True)

	zips = {nfc(z.stem): z for z in dot_root.glob("*.zip")}
	pngs = resolve_codex_pngs(codex_root)
	print(f"zips: {sorted(zips)}")
	print(f"pngs: {sorted(pngs)}")

	connected: list[str] = []
	dungeon = ROOT / "scripts/dungeon/DungeonScene.gd"
	icons = ROOT / "scripts/ui/IconPaths.gd"

	for stem, (enemy_id, pascal, is_boss) in ENEMY_MAP.items():
		has_zip = stem in zips
		has_png = stem in pngs
		if not has_zip and not has_png:
			print(f"SKIP {stem}: no zip/png")
			continue

		idle0: Image.Image | None = None
		if has_zip:
			dest = WORK / stem
			dest.mkdir(parents=True, exist_ok=True)
			with zipfile.ZipFile(zips[stem]) as zf:
				zf.extractall(dest)
			print(f"extract {stem}")
			eid, tres, idle0 = import_battle_zip(stem, dest, is_boss)
			if is_boss:
				patch_map_line(dungeon, eid, tres)
			else:
				patch_map_line(dungeon, eid, tres)
		else:
			print(f"CODEX-ONLY {stem}")
			eid = enemy_id

		prefix = "BOSS" if is_boss else "ENM"
		codex_res = f"res://assets/codex/enemies/ART_{prefix}_{pascal}.png"
		if has_png:
			save_codex(pascal, Image.open(pngs[stem]), is_boss)
		elif idle0 is not None:
			print(f"  WARN no codex png for {stem}; using idle frame")
			save_codex(pascal, idle0, is_boss)
		else:
			print(f"  WARN no art for {stem}")
			continue

		patch_map_line(icons, f"enemy:{eid}", codex_res)

		if idle0 is not None:
			save_turn_icon(pascal, idle0)
			turn_res = f"res://assets/ui/combat/enemy_icons/ICO_ENM_Turn_{pascal}.png"
			ensure_icon_key(icons, f"enemy_turn:{eid}", turn_res, f"enemy:{eid}")
		connected.append(eid)

	print("---")
	print(f"frostridge connected: {', '.join(connected)}")
	missing = [eid for stem, (eid, _, _) in ENEMY_MAP.items() if eid not in connected]
	if missing:
		print(f"NOT connected: {', '.join(missing)}")
	print("NOTE: polar_tricera は P3-ENEMY-FR-OMIT-001 でプール除外（データ残置）")


if __name__ == "__main__":
	import sys

	only = None
	if len(sys.argv) >= 3 and sys.argv[1] == "--only":
		only = nfc(sys.argv[2])
		# Filter ENEMY_MAP in place for this run
		keys = [k for k in ENEMY_MAP if k == only or ENEMY_MAP[k][0] == only]
		if not keys:
			raise SystemExit(f"unknown --only {sys.argv[2]}")
		keep = {k: ENEMY_MAP[k] for k in keys}
		ENEMY_MAP.clear()
		ENEMY_MAP.update(keep)
	main()
