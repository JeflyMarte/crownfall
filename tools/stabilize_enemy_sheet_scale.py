#!/usr/bin/env python3
"""Stabilize enemy battle-sheet idle by dropping zoom-pulse frames.

PixelLab ENM idle strips sometimes shrink the body toward the feet
(looks like scale pulse in combat). Upscaling those cells fattens the
silhouette; instead, replace unstable idle cells by cycling stable early
frames (height within --max-dh of idle[0]).

Sheet layout: horizontal 96x96 cells, idle = frames 0..8.

Usage:
  python3 tools/stabilize_enemy_sheet_scale.py ENM_Oldrex --all-tiers
  python3 tools/stabilize_enemy_sheet_scale.py ENM_WindRipper --all-tiers --max-dh 8
  python3 tools/stabilize_enemy_sheet_scale.py ENM_Oldrex_Sheet.png --dry-run
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

DEFAULT_CELL = 96
DEFAULT_IDLE_COUNT = 9
DEFAULT_MAX_DH = 1
BATTLE_DIR = Path(__file__).resolve().parents[1] / "assets" / "battle" / "enemies"


def used_h(cell: Image.Image) -> int:
	bb = cell.split()[-1].getbbox()
	return 0 if bb is None else bb[3] - bb[1]


def stabilize_sheet(
	path: Path,
	*,
	cell: int,
	idle_count: int,
	max_dh: int,
	dry_run: bool,
	freeze: bool = False,
) -> int:
	im = Image.open(path).convert("RGBA")
	w, h = im.size
	if h != cell:
		print(f"unexpected height {h} (want {cell}): {path}", file=sys.stderr)
		return 1
	n_cells = w // cell
	if n_cells < idle_count:
		print(f"too few cells ({n_cells}): {path}", file=sys.stderr)
		return 1

	cells = [im.crop((i * cell, 0, (i + 1) * cell, cell)) for i in range(n_cells)]
	ref_h = used_h(cells[0])
	if ref_h <= 0:
		print(f"empty idle[0]: {path}", file=sys.stderr)
		return 1

	heights = [used_h(cells[i]) for i in range(idle_count)]
	if freeze:
		stable = [0]
	else:
		stable = [i for i in range(idle_count) if abs(heights[i] - ref_h) <= max_dh]
		if not stable:
			stable = [0]

	print(
		f"{path.name}: ref_h={ref_h} max_dh={max_dh} freeze={freeze} "
		f"idle_h={heights} stable={stable}"
	)
	changed = 0
	for i in range(idle_count):
		src = stable[i % len(stable)]
		if i == src and not freeze:
			continue
		if freeze and i == 0:
			continue
		print(f"  idle[{i}] <- idle[{src}] (was h={heights[i]})")
		cells[i] = cells[src].copy()
		changed += 1

	if dry_run:
		print(f"  would replace {changed} cells dry_run=True")
		return 0

	out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	for i, c in enumerate(cells):
		out.paste(c, (i * cell, 0))
	out.save(path)
	print(f"  wrote {path} (replaced {changed})")
	return 0


def enemy_stem(basename: str) -> str:
	"""ENM_Foo / ENM_Foo_Sheet / ENM_Foo_Hard_Sheet → ENM_Foo."""
	stem = basename
	if stem.endswith(".png"):
		stem = stem[: -len(".png")]
	for suffix in ("_Nightmare_Sheet", "_Hard_Sheet", "_Sheet"):
		if stem.endswith(suffix):
			return stem[: -len(suffix)]
	return stem


def resolve_paths(arg: str, all_tiers: bool) -> list[Path]:
	base = Path(arg).name
	if all_tiers:
		stem = enemy_stem(base)
		cands = [
			BATTLE_DIR / f"{stem}_Sheet.png",
			BATTLE_DIR / f"{stem}_Hard_Sheet.png",
			BATTLE_DIR / f"{stem}_Nightmare_Sheet.png",
		]
		found = [p for p in cands if p.is_file()]
		if found:
			return found
	p = Path(arg)
	if not p.is_file():
		candidate = base if base.endswith(".png") else f"{base}.png"
		p = BATTLE_DIR / candidate
		if not p.is_file() and not candidate.endswith("_Sheet.png"):
			p = BATTLE_DIR / f"{enemy_stem(base)}_Sheet.png"
	return [p] if p.is_file() else []


def main() -> int:
	ap = argparse.ArgumentParser(description=__doc__)
	ap.add_argument(
		"sheet",
		help="Sheet basename or path (e.g. ENM_Oldrex_Sheet.png / ENM_WindRipper)",
	)
	ap.add_argument(
		"--all-tiers",
		action="store_true",
		help="Also process Hard/Nightmare sheets for the same enemy stem",
	)
	ap.add_argument("--cell", type=int, default=DEFAULT_CELL)
	ap.add_argument("--idle-count", type=int, default=DEFAULT_IDLE_COUNT)
	ap.add_argument(
		"--max-dh",
		type=int,
		default=DEFAULT_MAX_DH,
		help="Keep idle frames whose body height is within this many px of idle[0]",
	)
	ap.add_argument(
		"--freeze",
		action="store_true",
		help="Replace all idle cells with an exact copy of idle[0] (no residual breath)",
	)
	ap.add_argument("--dry-run", action="store_true")
	args = ap.parse_args()
	paths = resolve_paths(args.sheet, args.all_tiers)
	if not paths:
		print(f"no sheets found for {args.sheet}", file=sys.stderr)
		return 1
	rc = 0
	for path in paths:
		rc |= stabilize_sheet(
			path,
			cell=args.cell,
			idle_count=args.idle_count,
			max_dh=0 if args.freeze else args.max_dh,
			dry_run=args.dry_run,
			freeze=args.freeze,
		)
	return rc


if __name__ == "__main__":
	raise SystemExit(main())
