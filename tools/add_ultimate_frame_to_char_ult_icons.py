#!/usr/bin/env python3
"""Add the gold ultimate frame (draw_ultimate_frame) onto character ultimate skill icons.

Reuses the same frame geometry/colors as tools/generate_skill_ultimate_ouga_retsudan.py.
Does NOT modify EngFullArmCascade / OugaRetsudan (already framed).
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "assets/ui/skills"
SIZE = 128
INSET = 12  # paste content inside inset so frame (outer ~10px) remains visible

GOLD = (212, 175, 72, 255)
GOLD_HI = (255, 232, 140, 255)
GOLD_LO = (140, 108, 42, 255)
BG = (42, 44, 50, 255)

# Character ultimates that currently lack the gold frame
TARGETS = [
    "ICO_SKILL_BreakEdge.png",
    "ICO_SKILL_CriticalStorm.png",
    "ICO_SKILL_MarkShot.png",
    "ICO_SKILL_SilenceWeb.png",
    "ICO_SKILL_IronAura.png",
    "ICO_SKILL_VgGateCounter.png",
    "ICO_SKILL_Heartbeat.png",
    "ICO_SKILL_CurseBurst.png",
    "ICO_SKILL_ElementalBoost.png",
    "ICO_SKILL_PetCommand.png",
    "ICO_SKILL_BloodDrain.png",
]

# Already framed — never touch
SKIP = {
    "ICO_SKILL_EngFullArmCascade.png",
    "ICO_SKILL_OugaRetsudan.png",
}


def draw_ultimate_frame(draw: ImageDraw.ImageDraw) -> None:
    draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=8, fill=GOLD_LO)
    draw.rounded_rectangle((3, 3, SIZE - 4, SIZE - 4), radius=7, fill=GOLD)
    draw.rounded_rectangle((6, 6, SIZE - 7, SIZE - 7), radius=6, fill=GOLD_LO)
    draw.rounded_rectangle((10, 10, SIZE - 11, SIZE - 11), radius=5, fill=BG, outline=GOLD_HI, width=1)
    for cx, cy, dx, dy in (
        (14, 14, 1, 1),
        (114, 14, -1, 1),
        (14, 114, 1, -1),
        (114, 114, -1, -1),
        (64, 12, 0, 1),
        (64, 116, 0, -1),
        (12, 64, 1, 0),
        (116, 64, -1, 0),
    ):
        draw.polygon(
            [(cx, cy), (cx + 8 * dx, cy + 2 * dy), (cx + 2 * dx, cy + 8 * dy)],
            fill=GOLD_HI,
        )


def _content_bbox(im: Image.Image) -> tuple[int, int, int, int] | None:
    """Tight bbox of non-transparent pixels, or None if empty."""
    alpha = im.split()[-1]
    bbox = alpha.getbbox()
    return bbox


def framed_icon(src: Image.Image) -> Image.Image:
    src = src.convert("RGBA")
    if src.size != (SIZE, SIZE):
        src = src.resize((SIZE, SIZE), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    draw_ultimate_frame(draw)

    inner = SIZE - 2 * INSET  # 104
    bbox = _content_bbox(src)
    if bbox is None:
        content = src
    else:
        content = src.crop(bbox)

    cw, ch = content.size
    scale = min(inner / max(cw, 1), inner / max(ch, 1))
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    scaled = content.resize((nw, nh), Image.Resampling.LANCZOS)

    ox = INSET + (inner - nw) // 2
    oy = INSET + (inner - nh) // 2
    canvas.paste(scaled, (ox, oy), scaled)
    return canvas


def main() -> None:
    updated: list[Path] = []
    for name in TARGETS:
        if name in SKIP:
            print(f"SKIP (protected): {name}")
            continue
        path = SKILLS / name
        if not path.is_file():
            raise FileNotFoundError(path)
        out = framed_icon(Image.open(path))
        out.save(path, "PNG")
        updated.append(path)
        print(f"Updated {path.relative_to(ROOT)}")

    print(f"Done: {len(updated)} files")
    for p in updated:
        print(f"  - {p}")


if __name__ == "__main__":
    main()
