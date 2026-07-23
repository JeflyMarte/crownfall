#!/usr/bin/env python3
"""Import Whisperwood battle dots + codex arts, and Other event enemy portraits.

Sources (Desktop):
  モンスター/モンスタードット絵/ウィスパーウッド/*.zip
  モンスター/モンスター図鑑/ウィスパーウッド/*.png
  モンスター/モンスター図鑑/その他/{コズミックダック,宝冠レイヴン}.png

Outputs:
  assets/battle/enemies/ENM_*_Sheet.png  (boss → assets/battle/bosses/BOSS_*)
  resources/animation/ENM_*.tres / BOSS_Granvel.tres
  assets/codex/enemies/ART_ENM_*.png / ART_BOSS_Granvel.png
  assets/ui/combat/enemy_icons/ICO_ENM_Turn_*.png

Patches DungeonScene ENEMY_SPRITE_MAP / BOSS_ENEMY_SPRITE_MAP and IconPaths.

Note: ブルームサーペントは P3-ENEMY-WW-OMIT-001 でプールオミット。素材があっても本スクリプトでは取り込まない。
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
WORK = Path("/tmp/crownfall_whisperwood_dots")
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
# bloom_serpent はオミット（プール外）。再投入時にここへ戻す。
ENEMY_MAP: dict[str, tuple[str, str, bool]] = {
	"モスボア": ("moss_boar", "MossBoar", False),
	"モスシェル": ("moss_shell", "MossShell", False),
	"スポアウィドウ": ("spore_widow", "SporeWidow", False),
	"鋭刀甲虫": ("iron_horn", "IronHorn", False),
	"ブラッドブルーム": ("blood_bloom", "BloodBloom", False),
	"ルーンカルキノス": ("rune_carcinos", "RuneCarcinos", False),
	"深霧ワイバーン": ("mist_wyvern", "MistWyvern", False),
	"ミラーボア": ("mirror_boa", "MirrorBoa", False),
	"フローラベア グランヴェル": ("granvel", "Granvel", True),
}

OTHER_CODEX: dict[str, tuple[str, str]] = {
	"コズミックダック": ("cosmic_duck", "ART_ENM_CosmicDuck.png"),
	"宝冠レイヴン": ("crown_raven", "ART_ENM_CrownRaven.png"),
	"ゴールデンスカラベ": ("golden_scarab", "ART_ENM_GoldenScarab.png"),
	"影狩": ("shadow_stalker", "ART_ENM_ShadowStalker.png"),
}


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def find_named_dir(parent: Path, needle: str) -> Path:
	want = nfc(needle)
	for p in parent.iterdir():
		if p.is_dir() and want in nfc(p.name):
			return p
	raise FileNotFoundError(f"{needle} under {parent}")


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


def import_battle_zip(stem: str, src_root: Path) -> tuple[str, str, Image.Image]:
	enemy_id, pascal, is_boss = ENEMY_MAP[stem]
	dirs = list_anim_dirs(src_root)
	plan: list[tuple[str, bool, tuple[str, ...]]] = [
		("idle", True, ("idle", "stand", "rest", "weight_shift", "firmly")),
		("attack", False, ("attack", "atack")),
		("hurt", False, ("hurt", "hit")),
		("death", False, ("death", "down")),
	]
	all_frames: list[Image.Image] = []
	meta: list[tuple[str, bool, int, int]] = []
	for anim_id, loop, kws in plan:
		folder = pick_anim_dir(dirs, kws)
		if folder is None:
			raise FileNotFoundError(f"{stem}: missing anim for {anim_id} in {list(dirs)}")
		frames = load_frames(folder)
		start = len(all_frames)
		all_frames.extend(frames)
		meta.append((anim_id, loop, start, len(frames)))
		print(f"  {stem} {anim_id}: {len(frames)} ({folder.parent.name}/{folder.name})")

	sheet = Image.new("RGBA", (FRAME * len(all_frames), FRAME), (0, 0, 0, 0))
	for i, frame in enumerate(all_frames):
		sheet.paste(frame, (i * FRAME, 0), frame)

	if is_boss:
		BOSS_DIR.mkdir(parents=True, exist_ok=True)
		sheet_path = BOSS_DIR / f"BOSS_{pascal}_Sheet.png"
		sheet_res = f"res://assets/battle/bosses/BOSS_{pascal}_Sheet.png"
		tres_path = ANIM_DIR / f"BOSS_{pascal}.tres"
	else:
		BATTLE_DIR.mkdir(parents=True, exist_ok=True)
		sheet_path = BATTLE_DIR / f"ENM_{pascal}_Sheet.png"
		sheet_res = f"res://assets/battle/enemies/ENM_{pascal}_Sheet.png"
		tres_path = ANIM_DIR / f"ENM_{pascal}.tres"

	sheet.save(sheet_path)
	write_tres(sheet_res, tres_path, meta)
	print(f"  wrote {sheet_path.relative_to(ROOT)} + {tres_path.name}")
	tres_res = f"res://{tres_path.relative_to(ROOT).as_posix()}"
	return enemy_id, tres_res, all_frames[0]


def save_codex(pascal: str, is_boss: bool, src: Image.Image) -> Path:
	CODEX_DIR.mkdir(parents=True, exist_ok=True)
	name = f"ART_BOSS_{pascal}.png" if is_boss else f"ART_ENM_{pascal}.png"
	out = CODEX_DIR / name
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


def import_whisperwood() -> list[str]:
	dot_root = find_named_dir(DESKTOP_MON / "モンスタードット絵", "ウィスパーウッド")
	codex_root = find_named_dir(DESKTOP_MON / "モンスター図鑑", "ウィスパーウッド")
	if WORK.exists():
		shutil.rmtree(WORK)
	WORK.mkdir(parents=True)

	zips = {nfc(z.stem): z for z in dot_root.glob("*.zip")}
	pngs = {nfc(p.stem): p for p in codex_root.glob("*.png")}
	missing_zip = sorted(set(ENEMY_MAP) - set(zips))
	missing_png = sorted(set(ENEMY_MAP) - set(pngs))
	if missing_zip:
		print(f"WARN missing battle zips: {missing_zip}")
	if missing_png:
		print(f"WARN missing codex pngs: {missing_png}")

	connected: list[str] = []
	dungeon = ROOT / "scripts/dungeon/DungeonScene.gd"
	icons = ROOT / "scripts/ui/IconPaths.gd"

	for stem, (enemy_id, pascal, is_boss) in ENEMY_MAP.items():
		if stem not in zips:
			continue
		dest = WORK / stem
		dest.mkdir(parents=True, exist_ok=True)
		with zipfile.ZipFile(zips[stem]) as zf:
			zf.extractall(dest)
		print(f"extract {stem}")
		eid, tres, idle0 = import_battle_zip(stem, dest)
		patch_map_line(dungeon, eid, tres)
		if stem in pngs:
			save_codex(pascal, is_boss, Image.open(pngs[stem]))
		else:
			save_codex(pascal, is_boss, idle0)
		codex_name = f"ART_BOSS_{pascal}.png" if is_boss else f"ART_ENM_{pascal}.png"
		patch_map_line(icons, f"enemy:{eid}", f"res://assets/codex/enemies/{codex_name}")
		save_turn_icon(pascal, idle0)
		icon_text = icons.read_text(encoding="utf-8")
		if f'"enemy_turn:{eid}"' in icon_text:
			patch_map_line(
				icons,
				f"enemy_turn:{eid}",
				f"res://assets/ui/combat/enemy_icons/ICO_ENM_Turn_{pascal}.png",
			)
		connected.append(eid)
	return connected


def import_other_codex() -> None:
	other = find_named_dir(DESKTOP_MON / "モンスター図鑑", "その他")
	icons = ROOT / "scripts/ui/IconPaths.gd"
	found = {nfc(p.stem): p for p in other.glob("*.png")}
	for stem, (enemy_id, out_name) in OTHER_CODEX.items():
		if stem not in found:
			print(f"WARN missing other portrait: {stem}")
			continue
		img = strip_edge_bg(Image.open(found[stem]))
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
		CODEX_DIR.mkdir(parents=True, exist_ok=True)
		out = CODEX_DIR / out_name
		canvas.save(out)
		patch_map_line(icons, f"enemy:{enemy_id}", f"res://assets/codex/enemies/{out_name}")
		print(f"other codex {enemy_id} <- {stem}")


def main() -> None:
	connected = import_whisperwood()
	import_other_codex()
	print("---")
	print(f"whisperwood connected: {', '.join(connected)}")
	missing = [eid for stem, (eid, _, _) in ENEMY_MAP.items() if eid not in connected]
	if missing:
		print(f"NOT connected (no zip): {', '.join(missing)}")


if __name__ == "__main__":
	main()
