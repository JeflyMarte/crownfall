#!/usr/bin/env python3
"""Import Blackshore codex portraits from Desktop モンスター図鑑.

Source: ~/Desktop/CrownFall設定画像/モンスター/モンスター図鑑/ブラックショア/*.png
Output: assets/codex/enemies/ART_ENM_*.png / ART_BOSS_Nereion.png (512×512)

白マット／黒マットはエッジ＋囲み穴の flood-fill で透過化する。
IconPaths の enemy: キーは既存パスを維持（差替のみ）。
"""
from __future__ import annotations

import unicodedata
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC_PARENT = Path.home() / "Desktop/CrownFall設定画像/モンスター/モンスター図鑑"
OUT = ROOT / "assets/codex/enemies"
CODEX_SIZE = 512

# Desktop stem (NFC) → output ART filename
NAME_MAP: dict[str, str] = {
	"アンダーテイカー": "ART_ENM_UndertakerShark.png",
	"ヴォイドテンタクル": "ART_ENM_VoidTentacle.png",
	"サムライフィッシュ": "ART_ENM_SamuraiFish.png",
	"スカルタートル": "ART_ENM_SkullTurtle.png",
	"ドレッドジョー": "ART_ENM_DreadJaw.png",
	"ニンジャオクトパス": "ART_ENM_NinjaOctopus.png",
	"潮灯": "ART_ENM_TideLamp.png",
	"潮鳴王 ネレイオン": "ART_BOSS_Nereion.png",
	"船喰らい": "ART_ENM_ShipEaterCrab.png",
}


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def find_src_dir() -> Path:
	want = nfc("ブラックショア")
	if not SRC_PARENT.is_dir():
		raise SystemExit(f"missing: {SRC_PARENT}")
	for p in SRC_PARENT.iterdir():
		if p.is_dir() and want in nfc(p.name):
			return p
	raise SystemExit(f"not found: {want} under {SRC_PARENT}")


def is_light_bg(r: int, g: int, b: int, a: int, light: int = 238) -> bool:
	if a < 10:
		return True
	if r >= light and g >= light and b >= light:
		return True
	if max(r, g, b) - min(r, g, b) < 16 and min(r, g, b) >= 210:
		return True
	return False


def strip_edge_light(img: Image.Image, light: int = 238) -> Image.Image:
	img = img.convert("RGBA")
	w, h = img.size
	px = img.load()
	q: deque[tuple[int, int]] = deque()
	seen = [[False] * w for _ in range(h)]
	for x in range(w):
		q.append((x, 0))
		q.append((x, h - 1))
	for y in range(h):
		q.append((0, y))
		q.append((w - 1, y))
	while q:
		x, y = q.popleft()
		if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
			continue
		seen[y][x] = True
		r, g, b, a = px[x, y]
		if not is_light_bg(r, g, b, a, light):
			continue
		px[x, y] = (0, 0, 0, 0)
		q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
	return img


def strip_enclosed_light(img: Image.Image, light: int = 245) -> Image.Image:
	"""Remove near-white islands (between tentacles etc.)."""
	img = img.convert("RGBA")
	w, h = img.size
	px = img.load()
	seeds: list[tuple[int, int]] = []
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a < 10:
				continue
			if r >= light and g >= light and b >= light:
				seeds.append((x, y))
	seen = [[False] * w for _ in range(h)]
	for sx, sy in seeds:
		if seen[sy][sx]:
			continue
		q: deque[tuple[int, int]] = deque([(sx, sy)])
		comp: list[tuple[int, int]] = []
		while q:
			x, y = q.popleft()
			if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
				continue
			r, g, b, a = px[x, y]
			if a < 10:
				seen[y][x] = True
				continue
			if not (
				r >= light - 8
				and g >= light - 8
				and b >= light - 8
				and max(r, g, b) - min(r, g, b) < 20
			):
				continue
			seen[y][x] = True
			comp.append((x, y))
			q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
		for x, y in comp:
			px[x, y] = (0, 0, 0, 0)
	return img


def strip_dark_edge(img: Image.Image, dark_threshold: int = 85) -> Image.Image:
	img = img.convert("RGBA")
	w, h = img.size
	px = img.load()
	seeds = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
	opaque = [c for c in seeds if c[3] > 8]
	if not opaque:
		return img
	sr = sum(c[0] for c in opaque) // len(opaque)
	sg = sum(c[1] for c in opaque) // len(opaque)
	sb = sum(c[2] for c in opaque) // len(opaque)
	if max(sr, sg, sb) > dark_threshold + 40:
		return img
	tol = 30
	seen = [[False] * w for _ in range(h)]
	q: deque[tuple[int, int]] = deque()
	for x in range(w):
		q.append((x, 0))
		q.append((x, h - 1))
	for y in range(h):
		q.append((0, y))
		q.append((w - 1, y))
	while q:
		x, y = q.popleft()
		if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
			continue
		seen[y][x] = True
		r, g, b, a = px[x, y]
		if a < 8:
			matte = True
		elif abs(r - sr) > tol or abs(g - sg) > tol or abs(b - sb) > tol:
			matte = False
		elif max(r, g, b) - min(r, g, b) > 22:
			matte = False
		else:
			matte = True
		if not matte:
			continue
		px[x, y] = (0, 0, 0, 0)
		q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
	return img


def soften_near_white_halo(img: Image.Image) -> Image.Image:
	img = img.convert("RGBA")
	px = img.load()
	w, h = img.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0 or a == 255:
				continue
			if min(r, g, b) >= 220 and a < 200:
				px[x, y] = (0, 0, 0, 0)
	return img


def prepare(img: Image.Image) -> Image.Image:
	work = img.convert("RGBA")
	work = strip_edge_light(work, 238)
	work = strip_enclosed_light(work, 245)
	work = strip_edge_light(work, 235)
	work = strip_dark_edge(work)
	work = soften_near_white_halo(work)
	return work


def fit_square(img: Image.Image, size: int = CODEX_SIZE) -> Image.Image:
	bbox = img.getbbox()
	if bbox is None:
		return Image.new("RGBA", (size, size), (0, 0, 0, 0))
	cropped = img.crop(bbox)
	cw, ch = cropped.size
	canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	ratio = min((size * 0.92) / cw, (size * 0.92) / ch)
	nw, nh = max(1, int(cw * ratio)), max(1, int(ch * ratio))
	resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
	ox = (size - nw) // 2
	oy = (size - nh) // 2
	canvas.paste(resized, (ox, oy), resized)
	return canvas


def resolve_sources(src_dir: Path) -> dict[str, Path]:
	found_files = {nfc(p.stem): p for p in src_dir.glob("*.png")}
	out: dict[str, Path] = {}
	for stem in NAME_MAP:
		for key, path in found_files.items():
			if key == stem or stem in key or key in stem:
				out[stem] = path
				break
	return out


def clear_import_cache(names: list[str]) -> None:
	imported = ROOT / ".godot" / "imported"
	if not imported.is_dir():
		return
	n = 0
	for p in imported.iterdir():
		if any(name.replace(".png", "") in p.name for name in names):
			p.unlink(missing_ok=True)
			n += 1
	print(f"cleared {n} import caches")


def main() -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	src_dir = find_src_dir()
	sources = resolve_sources(src_dir)
	missing = [k for k in NAME_MAP if k not in sources]
	if missing:
		raise SystemExit(f"missing sources: {missing}")
	written: list[str] = []
	for stem, out_name in NAME_MAP.items():
		src = sources[stem]
		processed = fit_square(prepare(Image.open(src)))
		dest = OUT / out_name
		processed.save(dest, "PNG", optimize=True)
		written.append(out_name)
		print(f"OK {nfc(src.name)} -> {out_name} {processed.size}")
	clear_import_cache(written)
	print("done — reopen Godot if portraits look stale")


if __name__ == "__main__":
	main()
