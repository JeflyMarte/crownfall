#!/usr/bin/env python3
"""Import AI-generated build legendary armor/accessory icons to 64x64 RGBA.

Usage:
  python3 tools/import_build_legendary_icons.py
  python3 tools/import_build_legendary_icons.py --src /opt/cursor/artifacts/assets
"""
from __future__ import annotations

import argparse
import sys
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SRC = Path("/opt/cursor/artifacts/assets")
WIP_DIR = ROOT / "assets/ui/equipment/_wip"
OUT_DIR = ROOT / "assets/ui/equipment"
TARGET_SIZE = 64
SAFE_SCALE = 0.82

# (filename, category) — category unused for output path (filename is already final).
ICON_FILES: list[str] = [
	"ICO_ARM_BloodpactPlate.png",
	"ICO_ARM_FlurryLightMail.png",
	"ICO_ARM_BulwarkRolePlate.png",
	"ICO_ARM_CoverAegisCloak.png",
	"ICO_ARM_HexweaveRobe.png",
	"ICO_ACC_BladeDanceRing.png",
	"ICO_ACC_PierceCharm.png",
	"ICO_ACC_PulseAmulet.png",
	"ICO_ACC_BeastlordFang.png",
	"ICO_ACC_ApothecaryVial.png",
	# ペット／ヒーラービルドL（P3-EQ-PET-HEAL-BUILD-001）
	"ICO_ARM_BeastcallMantle.png",
	"ICO_ARM_FieldSalveRobe.png",
	"ICO_WPN_MendweaverStaff.png",
]


def _is_bg(r: int, g: int, b: int, threshold: int) -> bool:
	return r <= threshold and g <= threshold and b <= threshold


def remove_edge_black(img: Image.Image, threshold: int = 28) -> Image.Image:
	"""Edge-connected near-black → transparent（内部の暗い金属は残す）."""
	img = img.convert("RGBA")
	w, h = img.size
	px = img.load()
	visited = [[False] * w for _ in range(h)]
	q: deque[tuple[int, int]] = deque()

	def try_push(x: int, y: int) -> None:
		if x < 0 or y < 0 or x >= w or y >= h or visited[y][x]:
			return
		r, g, b, a = px[x, y]
		if a == 0 or not _is_bg(r, g, b, threshold):
			return
		visited[y][x] = True
		q.append((x, y))

	for x in range(w):
		try_push(x, 0)
		try_push(x, h - 1)
	for y in range(h):
		try_push(0, y)
		try_push(w - 1, y)

	while q:
		x, y = q.popleft()
		r, g, b, _a = px[x, y]
		px[x, y] = (r, g, b, 0)
		try_push(x + 1, y)
		try_push(x - 1, y)
		try_push(x, y + 1)
		try_push(x, y - 1)
	return img


def scrub_caption_band(img: Image.Image, band_frac: float = 0.14) -> Image.Image:
	"""下部のキャプション帯を透過（縁連結の明るい文字を落とす）."""
	img = img.convert("RGBA")
	w, h = img.size
	band_y = int(h * (1.0 - band_frac))
	px = img.load()
	# 帯内で縁から繋がる近黒／低彩度ピクセルと、細い明文字を消す
	for y in range(band_y, h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			mx = max(r, g, b)
			mn = min(r, g, b)
			# 帯内の暗い背景／薄いラベル文字（低彩度）
			if mx <= 40 or (mx - mn <= 28 and mx >= 80):
				px[x, y] = (r, g, b, 0)
	return img


def fit_to_canvas(img: Image.Image, size: int = TARGET_SIZE) -> Image.Image:
	img = remove_edge_black(img)
	img = scrub_caption_band(img)
	# 再洪水で帯処理後の穴を背景に繋げる
	img = remove_edge_black(img, threshold=32)
	bbox = img.getbbox()
	if bbox is None:
		return Image.new("RGBA", (size, size), (0, 0, 0, 0))
	cropped = img.crop(bbox)
	max_dim = int(size * SAFE_SCALE)
	cw, ch = cropped.size
	scale = min(max_dim / cw, max_dim / ch)
	nw = max(1, int(round(cw * scale)))
	nh = max(1, int(round(ch * scale)))
	resized = cropped.resize((nw, nh), Image.LANCZOS)
	canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	ox = (size - nw) // 2
	oy = (size - nh) // 2 + 1
	canvas.paste(resized, (ox, oy), resized)
	return canvas


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("--src", type=Path, default=DEFAULT_SRC)
	args = parser.parse_args()
	src_dir: Path = args.src
	if not src_dir.exists():
		print(f"Missing source dir: {src_dir}", file=sys.stderr)
		return 1

	WIP_DIR.mkdir(parents=True, exist_ok=True)
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	imported = 0
	missing: list[str] = []
	for fname in ICON_FILES:
		src = src_dir / fname
		if not src.exists():
			missing.append(fname)
			continue
		# WIP に原画コピー（監査用）
		wip_path = WIP_DIR / fname
		Image.open(src).convert("RGBA").save(wip_path, "PNG")
		icon = fit_to_canvas(Image.open(src))
		out = OUT_DIR / fname
		icon.save(out, "PNG")
		print(f"imported {fname} <- {src} ({icon.size[0]}x{icon.size[1]})")
		imported += 1

	if missing:
		print("missing:", ", ".join(missing))
	print(f"done: {imported}/{len(ICON_FILES)}")
	return 0 if not missing else 1


if __name__ == "__main__":
	raise SystemExit(main())
