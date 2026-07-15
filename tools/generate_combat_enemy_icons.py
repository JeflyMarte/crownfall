#!/usr/bin/env python3
"""Compose combat turn-order enemy icons: Desktop 図鑑 art + モンスターフレーム.

Output: assets/ui/combat/enemy_icons/ICO_ENM_Turn_*.png
Does NOT touch assets/codex/enemies (図鑑は既存のまま).
"""
from __future__ import annotations

import argparse
import unicodedata
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = Path.home() / "Desktop/CrownFall設定画像/モンスター/モンスター図鑑"
FRAME_PATH = Path.home() / "Desktop/CrownFall設定画像/素材/モンスターフレーム.png"
OUT_DIR = ROOT / "assets/ui/combat/enemy_icons"
PREVIEW_DIR = ROOT / "assets/ui/combat/enemy_icons/_preview"

OUT_SIZE = 128
BLACK_HARD = 28
BLACK_SOFT = 48
# Content fill inside the keyed frame hole (corner ornaments need margin).
HOLE_FILL = 0.72
PAD_RATIO = 0.04

# Desktop stem (NFC) → (enemy_id, output filename)
NAME_MAP: dict[str, tuple[str, str]] = {
	"セピアハウンド": ("sepia_hound", "ICO_ENM_Turn_SepiaHound.png"),
	"ルーンローチ": ("rune_roach", "ICO_ENM_Turn_RuneRoach.png"),
	"水晶ハリネズミ": ("crystal_hedgehog", "ICO_ENM_Turn_CrystalHedgehog.png"),
	"冠喰いネズミ": ("crown_eater_rat", "ICO_ENM_Turn_CrownEaterRat.png"),
	"墓鐘バット": ("grave_bell_bat", "ICO_ENM_Turn_GraveBellBat.png"),
	"水晶スコーピオン": ("crystal_scorpion", "ICO_ENM_Turn_CrystalScorpion.png"),
	"骸面マンティス": ("skullface_mantis", "ICO_ENM_Turn_SkullfaceMantis.png"),
	"クロックモス": ("clock_moth", "ICO_ENM_Turn_ClockMoth.png"),
	"水晶骸竜 セルディオン": ("serdion", "ICO_ENM_Turn_Serdion.png"),
}


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def remove_black_matte(img: Image.Image) -> Image.Image:
	img = img.convert("RGBA")
	px = img.load()
	w, h = img.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0:
				px[x, y] = (0, 0, 0, 0)
				continue
			dist = max(r, g, b)
			if dist <= BLACK_HARD:
				px[x, y] = (r, g, b, 0)
			elif dist <= BLACK_SOFT:
				fade = (dist - BLACK_HARD) / max(1, BLACK_SOFT - BLACK_HARD)
				px[x, y] = (r, g, b, int(a * fade))
	return img


def key_black_connected(img: Image.Image, thr: int = 25) -> Image.Image:
	"""Make near-black regions connected to edges or center transparent (frame hole)."""
	img = img.convert("RGBA")
	w, h = img.size
	px = img.load()

	def is_black(c: tuple) -> bool:
		return c[0] <= thr and c[1] <= thr and c[2] <= thr

	vis = [[False] * w for _ in range(h)]
	q: deque[tuple[int, int]] = deque()
	for x in range(w):
		for y in (0, h - 1):
			if is_black(px[x, y]):
				vis[y][x] = True
				q.append((x, y))
	for y in range(h):
		for x in (0, w - 1):
			if not vis[y][x] and is_black(px[x, y]):
				vis[y][x] = True
				q.append((x, y))
	cx, cy = w // 2, h // 2
	if not vis[cy][cx] and is_black(px[cx, cy]):
		vis[cy][cx] = True
		q.append((cx, cy))
	while q:
		x, y = q.popleft()
		for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
			if 0 <= nx < w and 0 <= ny < h and not vis[ny][nx] and is_black(px[nx, ny]):
				vis[ny][nx] = True
				q.append((nx, ny))
	out = img.copy()
	op = out.load()
	for y in range(h):
		for x in range(w):
			if vis[y][x]:
				op[x, y] = (0, 0, 0, 0)
	return out


def frame_hole_rect(frame: Image.Image) -> tuple[int, int, int, int]:
	"""Return (x0, y0, x1, y1) inclusive hole bounds along center axes."""
	px = frame.load()
	w, h = frame.size
	cx, cy = w // 2, h // 2

	def span_x(y: int) -> tuple[int, int]:
		left = cx
		while left > 0 and px[left, y][3] == 0:
			left -= 1
		right = cx
		while right < w - 1 and px[right, y][3] == 0:
			right += 1
		return left + 1, right - 1

	def span_y(x: int) -> tuple[int, int]:
		top = cy
		while top > 0 and px[x, top][3] == 0:
			top -= 1
		bottom = cy
		while bottom < h - 1 and px[x, bottom][3] == 0:
			bottom += 1
		return top + 1, bottom - 1

	x0, x1 = span_x(cy)
	y0, y1 = span_y(cx)
	return x0, y0, x1, y1


def fit_monster(img: Image.Image, box_w: int, box_h: int) -> Image.Image:
	img = remove_black_matte(img)
	bbox = img.getbbox()
	if bbox is None:
		return Image.new("RGBA", (box_w, box_h), (0, 0, 0, 0))
	cropped = img.crop(bbox)
	cw, ch = cropped.size
	pad = max(2, int(round(max(cw, ch) * PAD_RATIO)))
	canvas = Image.new("RGBA", (cw + pad * 2, ch + pad * 2), (0, 0, 0, 0))
	canvas.paste(cropped, (pad, pad), cropped)
	scale = min(box_w / canvas.size[0], box_h / canvas.size[1])
	nw = max(1, int(round(canvas.size[0] * scale)))
	nh = max(1, int(round(canvas.size[1] * scale)))
	resized = canvas.resize((nw, nh), Image.Resampling.LANCZOS)
	out = Image.new("RGBA", (box_w, box_h), (0, 0, 0, 0))
	ox = (box_w - nw) // 2
	oy = (box_h - nh) // 2
	out.paste(resized, (ox, oy), resized)
	return out


def compose(frame: Image.Image, monster: Image.Image) -> Image.Image:
	frame = key_black_connected(frame)
	x0, y0, x1, y1 = frame_hole_rect(frame)
	hole_w = max(1, x1 - x0 + 1)
	hole_h = max(1, y1 - y0 + 1)
	box_w = max(1, int(round(hole_w * HOLE_FILL)))
	box_h = max(1, int(round(hole_h * HOLE_FILL)))
	content = fit_monster(monster, box_w, box_h)

	canvas = Image.new("RGBA", frame.size, (0, 0, 0, 0))
	# Soft dark plate behind the portrait for readability on busy combat UI.
	plate = Image.new("RGBA", (box_w, box_h), (12, 8, 18, 220))
	mask = Image.new("L", (box_w, box_h), 0)
	draw = ImageDraw.Draw(mask)
	rad = max(8, box_w // 10)
	draw.rounded_rectangle((0, 0, box_w - 1, box_h - 1), radius=rad, fill=255)
	plate.putalpha(mask)

	cx = (x0 + x1) // 2
	cy = (y0 + y1) // 2
	ox = cx - box_w // 2
	oy = cy - box_h // 2
	canvas.paste(plate, (ox, oy), plate)
	canvas.paste(content, (ox, oy), content)
	canvas.alpha_composite(frame)
	return canvas.resize((OUT_SIZE, OUT_SIZE), Image.Resampling.LANCZOS)


def resolve_sources() -> dict[str, Path]:
	found: dict[str, Path] = {}
	if not SRC_DIR.is_dir():
		raise SystemExit(f"Source folder missing: {SRC_DIR}")
	for path in SRC_DIR.iterdir():
		if path.suffix.lower() != ".png" or path.name.startswith("."):
			continue
		stem = nfc(path.stem)
		for key in NAME_MAP:
			if stem == key or key in stem or stem in key:
				found[key] = path
				break
	return found


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--preview", action="store_true", help="Also write a contact sheet")
	args = parser.parse_args()

	if not FRAME_PATH.is_file():
		raise SystemExit(f"Frame missing: {FRAME_PATH}")
	frame = Image.open(FRAME_PATH)
	sources = resolve_sources()
	missing = [k for k in NAME_MAP if k not in sources]
	if missing:
		print("WARN missing sources:", missing)

	OUT_DIR.mkdir(parents=True, exist_ok=True)
	composed: list[tuple[str, Image.Image]] = []
	for name, (_enemy_id, out_name) in NAME_MAP.items():
		src = sources.get(name)
		if src is None:
			continue
		icon = compose(frame, Image.open(src))
		dest = OUT_DIR / out_name
		icon.save(dest, "PNG", optimize=True)
		composed.append((out_name, icon))
		print(f"OK {nfc(src.name)} -> {out_name} {icon.size} {dest.stat().st_size}B")

	if args.preview and composed:
		PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
		cols = min(3, len(composed))
		rows = (len(composed) + cols - 1) // cols
		pad = 8
		sheet_w = cols * OUT_SIZE + (cols + 1) * pad
		sheet_h = rows * OUT_SIZE + (rows + 1) * pad
		sheet = Image.new("RGBA", (sheet_w, sheet_h), (28, 22, 36, 255))
		for i, (_name, icon) in enumerate(composed):
			r, c = divmod(i, cols)
			x = pad + c * (OUT_SIZE + pad)
			y = pad + r * (OUT_SIZE + pad)
			sheet.paste(icon, (x, y), icon)
		sheet_path = PREVIEW_DIR / "TurnEnemyIcons_Sheet.png"
		sheet.save(sheet_path, "PNG")
		print(f"PREVIEW {sheet_path}")


if __name__ == "__main__":
	main()
