#!/usr/bin/env python3
"""Strip soft grey/dark mats from ticket icons (edge flood-fill).

AI 由来のチケット PNG は角 alpha=0 でも、本体外に半透明の灰／暗マットが残り、
マイページの所持チケット枠で矩形ノイズとして見える。縁から連結するマットだけ透過化する。

Usage:
  python3 tools/strip_ticket_icon_mats.py --dry-run
  python3 tools/strip_ticket_icon_mats.py --apply
"""
from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
TICKET_DIR = ROOT / "assets/ui/tickets"

# 半透明マット判定（縁から BFS）。本体の金／色付きグローは sat が高めで残る。
ALPHA_BG = 100
SAT_MAX = 40
LUM_MAX = 140
DARK_LUM_MAX = 45
DARK_SAT_MAX = 35
SOFT_NEAR_TRANS = 48
PASS2_ALPHA_MAX = 220
PASS2_SAT_MAX = 45
PASS2_LUM_MAX = 170
PASS2_ALPHA_BG = 110


def _is_mat_pixel(
	r: int,
	g: int,
	b: int,
	a: int,
	*,
	alpha_bg: int = ALPHA_BG,
	sat_max: int = SAT_MAX,
	lum_max: int = LUM_MAX,
) -> bool:
	if a <= alpha_bg:
		return True
	sat = max(r, g, b) - min(r, g, b)
	lum = (r + g + b) / 3.0
	if sat <= sat_max and lum <= lum_max and a < 245:
		return True
	if lum <= DARK_LUM_MAX and sat <= DARK_SAT_MAX and a < 250:
		return True
	return False


def _flood_clear(img: Image.Image, predicate) -> tuple[Image.Image, int]:
	img = img.convert("RGBA")
	w, h = img.size
	px = img.load()
	visited: set[tuple[int, int]] = set()
	q: deque[tuple[int, int]] = deque()

	def try_seed(x: int, y: int) -> None:
		if (x, y) in visited:
			return
		r, g, b, a = px[x, y]
		if predicate(r, g, b, a) or a == 0:
			visited.add((x, y))
			q.append((x, y))

	for x in range(w):
		try_seed(x, 0)
		try_seed(x, h - 1)
	for y in range(h):
		try_seed(0, y)
		try_seed(w - 1, y)

	# 既存の完全透過からも拡張（島状マットの種）
	for y in range(h):
		for x in range(w):
			if px[x, y][3] == 0:
				try_seed(x, y)

	cleared = 0
	while q:
		x, y = q.popleft()
		r, g, b, a = px[x, y]
		if a > 0 and predicate(r, g, b, a):
			px[x, y] = (0, 0, 0, 0)
			cleared += 1
		for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
			if nx < 0 or ny < 0 or nx >= w or ny >= h or (nx, ny) in visited:
				continue
			rr, gg, bb, aa = px[nx, ny]
			if aa == 0 or predicate(rr, gg, bb, aa):
				visited.add((nx, ny))
				q.append((nx, ny))

	# 透過に隣接する極薄フリンジを落とす
	fringe = 0
	to_clear: list[tuple[int, int]] = []
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0 or a >= SOFT_NEAR_TRANS:
				continue
			near_t = False
			for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
				if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
					near_t = True
					break
			if near_t:
				to_clear.append((x, y))
	for x, y in to_clear:
		px[x, y] = (0, 0, 0, 0)
		fringe += 1

	return img, cleared + fringe


def strip_ticket_mat(img: Image.Image) -> tuple[Image.Image, int]:
	def pass1(r: int, g: int, b: int, a: int) -> bool:
		return _is_mat_pixel(r, g, b, a)

	out, n1 = _flood_clear(img, pass1)

	def pass2(r: int, g: int, b: int, a: int) -> bool:
		if a <= PASS2_ALPHA_BG:
			return True
		sat = max(r, g, b) - min(r, g, b)
		lum = (r + g + b) / 3.0
		return sat <= PASS2_SAT_MAX and lum <= PASS2_LUM_MAX and a < PASS2_ALPHA_MAX

	out, n2 = _flood_clear(out, pass2)
	return out, n1 + n2


def process_one(path: Path, apply: bool) -> str:
	src = Image.open(path)
	out, cleared = strip_ticket_mat(src)
	if apply:
		out.save(path, "PNG", optimize=True)
		return f"fixed cleared={cleared}"
	return f"dry-run cleared={cleared}"


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--apply", action="store_true")
	parser.add_argument("--dry-run", action="store_true")
	args = parser.parse_args()
	apply = bool(args.apply)
	if not apply and not args.dry_run:
		parser.error("specify --apply or --dry-run")

	paths = sorted(TICKET_DIR.glob("ICO_Ticket_*.png"))
	if not paths:
		raise SystemExit(f"no ticket icons under {TICKET_DIR}")

	for path in paths:
		result = process_one(path, apply=apply)
		print(f"{path.relative_to(ROOT)}: {result}")


if __name__ == "__main__":
	main()
