#!/usr/bin/env python3
"""Import battle dots + codex for wander rares and rock_bison.

Sources (Desktop):
  モンスター/モンスタードット絵/{ゴールデンスカラベ,影狩り,ロックバイソン}.zip
  モンスター/モンスター図鑑/その他/{ゴールデンスカラベ,影狩,ロックバイソン}.png

Outputs:
  assets/battle/enemies/ENM_*_Sheet.png
  resources/animation/ENM_*.tres
  assets/codex/enemies/ART_ENM_*.png
  assets/ui/combat/enemy_icons/ICO_ENM_Turn_*.png

Patches DungeonScene ENEMY_SPRITE_MAP and IconPaths.
"""
from __future__ import annotations

import argparse
import re
import shutil
import unicodedata
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DESKTOP_MON = Path("/Users/marte/Desktop/CrownFall設定画像/モンスター")
DOT_DIR = DESKTOP_MON / "モンスタードット絵"
CODEX_OTHER = DESKTOP_MON / "モンスター図鑑" / "その他"
WORK = Path("/tmp/crownfall_wander_dots_p3")
BATTLE_DIR = ROOT / "assets/battle/enemies"
ANIM_DIR = ROOT / "resources/animation"
CODEX_DIR = ROOT / "assets/codex/enemies"
TURN_DIR = ROOT / "assets/ui/combat/enemy_icons"
FRAME = 96
CODEX_SIZE = 512
TURN_SIZE = 64
DIRECTION = "south-west"
SPEED = {"idle": 6.0, "attack": 10.0, "hurt": 8.0, "death": 6.0}

# zip stem (NFC) → (enemy_id, Pascal)
ENEMY_MAP: dict[str, tuple[str, str]] = {
	"ゴールデンスカラベ": ("golden_scarab", "GoldenScarab"),
	"影狩り": ("shadow_stalker", "ShadowStalker"),
	"ロックバイソン": ("rock_bison", "RockBison"),
}

# 図鑑 PNG stem (NFC) → enemy_id（影狩りだけファイル名が「影狩」）
CODEX_STEMS: dict[str, str] = {
	"ゴールデンスカラベ": "golden_scarab",
	"影狩": "shadow_stalker",
	"影狩り": "shadow_stalker",
	"ロックバイソン": "rock_bison",
}

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
		stack.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
	return img


def strip_dark_edge_bg(img: Image.Image, dark_threshold: int = 85) -> Image.Image:
	"""Flood-fill near-black/gray matte connected to edges (影狩りなど暗背景)。"""
	img = img.convert("RGBA")
	w, h = img.size
	px = img.load()
	# Seed from corner average — only remove colors close to the matte, not cloak black.
	seeds = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
	opaque_seeds = [c for c in seeds if c[3] > 8]
	if not opaque_seeds:
		return img
	sr = sum(c[0] for c in opaque_seeds) // len(opaque_seeds)
	sg = sum(c[1] for c in opaque_seeds) // len(opaque_seeds)
	sb = sum(c[2] for c in opaque_seeds) // len(opaque_seeds)
	# Skip if corners are already transparent / not a flat dark plate.
	if max(sr, sg, sb) > dark_threshold + 40:
		return img
	tol = 28
	visited = [[False] * w for _ in range(h)]
	stack: list[tuple[int, int]] = []

	def is_matte(x: int, y: int) -> bool:
		r, g, b, a = px[x, y]
		if a < 8:
			return True
		if abs(r - sr) > tol or abs(g - sg) > tol or abs(b - sb) > tol:
			return False
		# keep saturated aura (purple smoke)
		if max(r, g, b) - min(r, g, b) > 22:
			return False
		return True

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
		if not is_matte(x, y):
			continue
		px[x, y] = (0, 0, 0, 0)
		stack.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
	return img


def prepare_codex_src(src: Image.Image) -> Image.Image:
	img = strip_edge_bg(src)
	img = strip_dark_edge_bg(img)
	return img


def find_zip(stem: str) -> Path:
	want = nfc(stem)
	for zpath in DOT_DIR.glob("*.zip"):
		if nfc(zpath.stem) == want:
			return zpath
	raise FileNotFoundError(f"zip not found: {DOT_DIR}/{stem}.zip")


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


def save_codex(pascal: str, src: Image.Image) -> Path:
	CODEX_DIR.mkdir(parents=True, exist_ok=True)
	out = CODEX_DIR / f"ART_ENM_{pascal}.png"
	img = prepare_codex_src(src)
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
	print(f"  codex {out.name} {canvas.size}")
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
	path.write_text(text[: m.start()] + new + text[m.end() :], encoding="utf-8")
	print(f"  patch {path.name} {key} -> {value}")


def import_battle(stem: str, src_root: Path) -> tuple[str, str, Image.Image]:
	enemy_id, pascal = ENEMY_MAP[stem]
	anim_dirs = list_anim_dirs(src_root)
	all_frames: list[Image.Image] = []
	meta: list[tuple[str, bool, int]] = []
	idle0: Image.Image | None = None
	for anim_id, loop, keywords in ANIM_KEYWORDS:
		adir = pick_anim_dir(anim_dirs, keywords)
		frames = load_anim_frames(adir)
		if anim_id == "idle" and frames:
			facing = adir / DIRECTION
			if not facing.is_dir():
				facing = next(d for d in adir.iterdir() if d.is_dir())
			src0 = sorted(facing.glob("frame_*.png"))[0]
			idle0 = Image.open(src0).convert("RGBA")
		all_frames.extend(frames)
		meta.append((anim_id, loop, len(frames)))
		print(f"  {stem} {anim_id}: {len(frames)} from {adir.name}")

	if idle0 is None:
		raise SystemExit(f"{stem}: no idle frame")

	sheet = Image.new("RGBA", (FRAME * len(all_frames), FRAME), (0, 0, 0, 0))
	for i, frame in enumerate(all_frames):
		sheet.paste(frame, (i * FRAME, 0), frame)

	BATTLE_DIR.mkdir(parents=True, exist_ok=True)
	ANIM_DIR.mkdir(parents=True, exist_ok=True)
	sheet_path = BATTLE_DIR / f"ENM_{pascal}_Sheet.png"
	sheet.save(sheet_path)
	sheet_res = f"res://assets/battle/enemies/ENM_{pascal}_Sheet.png"
	tres_path = ANIM_DIR / f"ENM_{pascal}.tres"
	write_tres(sheet_res, tres_path, meta)
	print(f"  wrote {sheet_path.relative_to(ROOT)} ({sheet.size[0]}x{sheet.size[1]})")
	tres_res = f"res://{tres_path.relative_to(ROOT).as_posix()}"
	save_turn_icon(pascal, idle0)
	return enemy_id, tres_res, idle0


def import_codex_portraits(only: set[str] | None = None) -> dict[str, str]:
	"""Returns enemy_id → ART filename."""
	found = {nfc(p.stem): p for p in CODEX_OTHER.glob("*.png")}
	out: dict[str, str] = {}
	pascal_by_id = {eid: pascal for _stem, (eid, pascal) in ENEMY_MAP.items()}
	for stem, enemy_id in CODEX_STEMS.items():
		if enemy_id not in pascal_by_id:
			continue
		if only is not None and enemy_id not in only:
			continue
		if stem not in found:
			continue
		pascal = pascal_by_id[enemy_id]
		save_codex(pascal, Image.open(found[stem]))
		out[enemy_id] = f"ART_ENM_{pascal}.png"
		print(f"  portrait {enemy_id} <- {stem}")
	needed = [eid for eid in pascal_by_id if only is None or eid in only]
	missing = [eid for eid in needed if eid not in out]
	if missing:
		raise SystemExit(f"missing codex portraits for: {missing}")
	return out


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument(
		"--only",
		nargs="*",
		default=None,
		help="enemy_id filter (default: all in ENEMY_MAP)",
	)
	args = parser.parse_args()
	only = set(args.only) if args.only else None

	if WORK.exists():
		shutil.rmtree(WORK)
	WORK.mkdir(parents=True)

	dungeon = ROOT / "scripts/dungeon/DungeonScene.gd"
	icons = ROOT / "scripts/ui/IconPaths.gd"

	for stem, (enemy_id, pascal) in ENEMY_MAP.items():
		if only is not None and enemy_id not in only:
			continue
		zpath = find_zip(stem)
		dest = WORK / stem
		dest.mkdir(parents=True, exist_ok=True)
		with zipfile.ZipFile(zpath) as zf:
			zf.extractall(dest)
		print(f"extract {stem} from {zpath.name}")
		eid, tres, _idle = import_battle(stem, dest)
		patch_map_line(dungeon, eid, tres)
		patch_map_line(
			icons,
			f"enemy_turn:{eid}",
			f"res://assets/ui/combat/enemy_icons/ICO_ENM_Turn_{pascal}.png",
		)

	portraits = import_codex_portraits(only)
	for enemy_id, art_name in portraits.items():
		patch_map_line(
			icons,
			f"enemy:{enemy_id}",
			f"res://assets/codex/enemies/{art_name}",
		)

	# stale .godot cache for replaced textures
	imported = ROOT / ".godot" / "imported"
	if imported.is_dir():
		stems = ("GoldenScarab", "ShadowStalker", "RockBison")
		if only is not None:
			stems = tuple(
				pascal for _stem, (eid, pascal) in ENEMY_MAP.items() if eid in only
			)
		for p in imported.iterdir():
			if any(s in p.name for s in stems):
				p.unlink(missing_ok=True)
				print(f"  cleared cache {p.name}")

	print("done")


if __name__ == "__main__":
	main()
