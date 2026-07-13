#!/usr/bin/env python3
"""Import blacksmith hero detail weapon background from Desktop owner art.

Source: ~/Desktop/CrownFall設定画像/アイコン/ぶき/武器背景.png
Output: assets/ui/forge/UI_Forge_HeroItemBg.png
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/forge/UI_Forge_HeroItemBg.png"
# Matches ForgeUiTokens.HERO_PEDESTAL_PX (detail hero pedestal).
TARGET_PX = 240
DESKTOP_CANDIDATES = [
    Path.home() / "Desktop/CrownFall設定画像/武器背景.png",
    Path.home() / "Desktop/CrownFall設定画像/アイコン/ぶき/武器背景.png",
    ROOT / "assets/ui/equipment_ui/_wip/UI_Equip_ItemBg.png",
]


def resolve_source() -> Path | None:
    for path in DESKTOP_CANDIDATES:
        if path.exists():
            return path
    return None


def main() -> int:
    src = resolve_source()
    if src is None:
        print("missing source: 武器背景.png")
        return 1
    img = Image.open(src).convert("RGBA")
    if img.size != (TARGET_PX, TARGET_PX):
        img = img.resize((TARGET_PX, TARGET_PX), Image.Resampling.LANCZOS)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, optimize=True)
    print(f"wrote {OUT} from {src} ({OUT.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
