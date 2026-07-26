#!/usr/bin/env python3
"""Import Chronos Wave boss dots + codex art from ~/Downloads.

Sources:
  ~/Downloads/時環の共鳴龍クロノス・ウェーブ.zip  (PixelLab animations)
  ~/Downloads/時環の共鳴龍クロノス・ウェーブ.png  (codex key art)

Outputs:
  assets/battle/bosses/BOSS_ChronosWave_Sheet.png
  resources/animation/BOSS_ChronosWave.tres
  assets/codex/enemies/ART_BOSS_ChronosWave.png
  assets/ui/combat/enemy_icons/ICO_ENM_Turn_ChronosWave.png
  wiki/docs/assets/monsters/ART_BOSS_ChronosWave.png (mirror)
"""
from __future__ import annotations

import shutil
import unicodedata
import zipfile
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads"
ZIP_STEM_NFC = "時環の共鳴龍クロノス・ウェーブ"
OUT_SHEET = ROOT / "assets/battle/bosses/BOSS_ChronosWave_Sheet.png"
OUT_TRES = ROOT / "resources/animation/BOSS_ChronosWave.tres"
OUT_CODEX = ROOT / "assets/codex/enemies/ART_BOSS_ChronosWave.png"
OUT_TURN = ROOT / "assets/ui/combat/enemy_icons/ICO_ENM_Turn_ChronosWave.png"
OUT_WIKI = ROOT / "wiki/docs/assets/monsters/ART_BOSS_ChronosWave.png"
WORK = Path("/tmp/crownfall_chronos_wave_import")

FRAME = 128
DIRECTION = "south-west"
ANIMATIONS: list[tuple[str, str, bool, int]] = [
	("Idle", "idle", True, 9),
	("Attack", "attack", False, 9),
	("Hurt", "hurt", False, 9),
	("Death", "death", False, 9),
]
TURN_SIZE = 128
CODEX_KEEP_SIZE = True  # Moldgar-style: keep 1536×1024 after keying


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def resolve_download(suffix: str) -> Path:
	want = nfc(ZIP_STEM_NFC + suffix)
	for p in DOWNLOADS.iterdir():
		if nfc(p.name) == want:
			return p
	raise SystemExit(f"Missing Downloads/{want}")


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


def extract_zip(zpath: Path) -> Path:
	if WORK.exists():
		shutil.rmtree(WORK)
	WORK.mkdir(parents=True)
	with zipfile.ZipFile(zpath) as zf:
		zf.extractall(WORK)
	# Find animations root
	for p in WORK.rglob("animations"):
		if p.is_dir():
			return p
	raise SystemExit(f"No animations/ in {zpath}")


def load_frames(anim_root: Path, anim_name: str, count: int) -> list[Image.Image]:
	folder = anim_root / anim_name / DIRECTION
	if not folder.is_dir():
		# Case-insensitive fallback
		for sub in anim_root.iterdir():
			if sub.is_dir() and sub.name.lower() == anim_name.lower():
				folder = sub / DIRECTION
				break
	frames: list[Image.Image] = []
	for i in range(count):
		path = folder / f"frame_{i:03d}.png"
		if not path.exists():
			raise FileNotFoundError(path)
		frames.append(fit_frame(Image.open(path), FRAME))
	return frames


def build_sheet(anim_root: Path) -> tuple[Image.Image, list[tuple[str, bool, int, int]]]:
	all_frames: list[Image.Image] = []
	meta: list[tuple[str, bool, int, int]] = []
	for src_name, anim_id, loop, count in ANIMATIONS:
		start = len(all_frames)
		all_frames.extend(load_frames(anim_root, src_name, count))
		meta.append((anim_id, loop, start, count))
	sheet = Image.new("RGBA", (FRAME * len(all_frames), FRAME), (0, 0, 0, 0))
	for i, frame in enumerate(all_frames):
		sheet.paste(frame, (i * FRAME, 0), frame)
	return sheet, meta


def write_tres(meta: list[tuple[str, bool, int, int]]) -> None:
	total = sum(item[3] for item in meta)
	lines = [
		'[gd_resource type="SpriteFrames" load_steps=2 format=3]',
		"",
		'[ext_resource type="Texture2D" path="res://assets/battle/bosses/BOSS_ChronosWave_Sheet.png" id="1_sheet"]',
		"",
	]
	idx = 0
	atlas_ids: list[str] = []
	for _ in range(total):
		lines.extend(
			[
				f'[sub_resource type="AtlasTexture" id="f{idx}"]',
				'atlas = ExtResource("1_sheet")',
				f"region = Rect2({idx * FRAME}, 0, {FRAME}, {FRAME})",
				"",
			]
		)
		atlas_ids.append(f"f{idx}")
		idx += 1

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
	OUT_TRES.parent.mkdir(parents=True, exist_ok=True)
	OUT_TRES.write_text("\n".join(lines), encoding="utf-8")


def flood_key_near_white(img: Image.Image, thr: int = 248) -> Image.Image:
	"""Edge-connected near-white → transparent (codex RGB matte)."""
	img = img.convert("RGBA")
	w, h = img.size
	px = img.load()

	def is_matte(c: tuple) -> bool:
		r, g, b, a = c
		if a == 0:
			return True
		return r >= thr and g >= thr and b >= thr

	vis = [[False] * w for _ in range(h)]
	q: deque[tuple[int, int]] = deque()
	for x in range(w):
		for y in (0, h - 1):
			if is_matte(px[x, y]):
				vis[y][x] = True
				q.append((x, y))
	for y in range(h):
		for x in (0, w - 1):
			if not vis[y][x] and is_matte(px[x, y]):
				vis[y][x] = True
				q.append((x, y))
	while q:
		x, y = q.popleft()
		for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
			if 0 <= nx < w and 0 <= ny < h and not vis[ny][nx] and is_matte(px[nx, ny]):
				vis[ny][nx] = True
				q.append((nx, ny))
	out = img.copy()
	op = out.load()
	for y in range(h):
		for x in range(w):
			if vis[y][x]:
				op[x, y] = (0, 0, 0, 0)
	return out


def soft_white_fringe(img: Image.Image, soft: int = 235) -> Image.Image:
	"""Fade remaining near-white fringe that is not edge-connected."""
	img = img.convert("RGBA")
	px = img.load()
	w, h = img.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			mn = min(r, g, b)
			if mn >= soft and abs(r - g) < 12 and abs(g - b) < 12:
				# Keep bronze/gold midtones; only kill pale matte
				mx = max(r, g, b)
				if mx >= 245:
					fade = (255 - mn) / max(1, 255 - soft)
					px[x, y] = (r, g, b, int(a * min(1.0, fade)))
	return img


def process_codex(src: Path) -> Image.Image:
	img = flood_key_near_white(Image.open(src))
	img = soft_white_fringe(img)
	if CODEX_KEEP_SIZE:
		return img
	# 256 square fallback (Serdion-style)
	bbox = img.getbbox()
	if bbox is None:
		return Image.new("RGBA", (256, 256), (0, 0, 0, 0))
	cropped = img.crop(bbox)
	side = max(cropped.size)
	square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
	ox = (side - cropped.size[0]) // 2
	oy = (side - cropped.size[1]) // 2
	square.paste(cropped, (ox, oy), cropped)
	return square.resize((256, 256), Image.Resampling.LANCZOS)


def make_turn_icon(idle0: Image.Image) -> Image.Image:
	"""Content-only turn icon — NO baked plate (known-pitfalls)."""
	return fit_frame(idle0, TURN_SIZE)


def main() -> None:
	zpath = resolve_download(".zip")
	cpath = resolve_download(".png")
	anim_root = extract_zip(zpath)
	sheet, meta = build_sheet(anim_root)
	OUT_SHEET.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(OUT_SHEET)
	write_tres(meta)
	print(f"Wrote {OUT_SHEET} ({sheet.size[0]}x{sheet.size[1]})")
	print(f"Wrote {OUT_TRES}")

	codex = process_codex(cpath)
	OUT_CODEX.parent.mkdir(parents=True, exist_ok=True)
	codex.save(OUT_CODEX)
	OUT_WIKI.parent.mkdir(parents=True, exist_ok=True)
	shutil.copy2(OUT_CODEX, OUT_WIKI)
	print(f"Wrote {OUT_CODEX} ({codex.size[0]}x{codex.size[1]})")
	print(f"Wrote {OUT_WIKI}")

	idle0_path = anim_root / "Idle" / DIRECTION / "frame_000.png"
	turn = make_turn_icon(Image.open(idle0_path))
	OUT_TURN.parent.mkdir(parents=True, exist_ok=True)
	turn.save(OUT_TURN)
	print(f"Wrote {OUT_TURN} ({turn.size[0]}x{turn.size[1]})")


if __name__ == "__main__":
	main()
