#!/usr/bin/env python3
"""Generate ICO_SKILL_BASE_Buff_* and Ultimate_* from Heal/Slash templates."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/ui/skills/base"

# Warm amber buff (from heal), gold-red ultimate (from slash).
RECIPES = (
    ("Heal", "Buff", (1.18, 1.08, 0.72)),
    ("Slash", "Ultimate", (1.22, 1.05, 0.65)),
)


def tint_rgba(src: Path, dst: Path, rgb_mult: tuple[float, float, float]) -> None:
    im = Image.open(src).convert("RGBA")
    mr, mg, mb = rgb_mult
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (
                min(255, int(r * mr)),
                min(255, int(g * mg)),
                min(255, int(b * mb)),
                a,
            )
    dst.parent.mkdir(parents=True, exist_ok=True)
    im.save(dst)
    print(f"wrote {dst.relative_to(ROOT)}")


def main() -> None:
    for src_token, dst_token, mult in RECIPES:
        for layer in ("fg", "bg"):
            src = BASE / f"ICO_SKILL_BASE_{src_token}_{layer}.png"
            dst = BASE / f"ICO_SKILL_BASE_{dst_token}_{layer}.png"
            if not src.is_file():
                raise SystemExit(f"missing template: {src}")
            tint_rgba(src, dst, mult)


if __name__ == "__main__":
    main()
