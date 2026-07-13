#!/usr/bin/env python3
"""Generate per-dungeon treasure/exit objects and Dark/Holy/Critical hit VFX sheets."""
from __future__ import annotations

import colorsys
from pathlib import Path

from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
MG_ENV = ROOT / "assets/dungeon/mourngate/env"
VFX_DIR = ROOT / "assets/vfx/batch6"
VFX_ELEMENTS_DIR = ROOT / "assets/vfx/elements"

# batch6 ヒット／回復は暗青緑の未キー背景が残りやすい（max RGB ~25）。宝箱は従来閾値のまま。
VFX_KEY_MAX_RGB = 42
VFX_KEY_MAX_LUM = 38

DUNGEONS: list[tuple[str, str, float | None]] = [
    ("mourngate", "Mourngate", None),
    ("astoria_ruins", "AstoriaRuins", 0.08),
    ("whisperwood", "Whisperwood", 0.30),
    ("green_hollow", "GreenHollow", 0.33),
    ("mistfen", "Mistfen", 0.42),
    ("broken_marsh", "BrokenMarsh", 0.06),
    ("blackshore", "Blackshore", 0.54),
    ("westbay_flats", "WestbayFlats", 0.11),
    ("frostridge", "Frostridge", 0.58),
    ("frostwall_path", "FrostwallPath", 0.56),
]

CHEST_CLOSED_SRC = MG_ENV / "OBJ_TreasureChest_Closed.png"
EXIT_SRC = MG_ENV / "OBJ_ExitGate_Mourngate.png"
HIT_SRC = VFX_DIR / "FX_Hit_Normal.png"


def remove_black_bg(img: Image.Image, threshold: int = 24) -> Image.Image:
    """宝箱・扉など単色暗背景向け（従来互換）。"""
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r <= threshold and g <= threshold and b <= threshold:
                px[x, y] = (0, 0, 0, 0)
    return sanitize_alpha(img)


def sanitize_alpha(img: Image.Image) -> Image.Image:
    """alpha=0 のピクセル RGB をゼロ化（加算合成のゴミ防止）。"""
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            r, g, b, a = px[x, y]
            if a == 0:
                px[x, y] = (0, 0, 0, 0)
    return img


def key_dark_background(
    img: Image.Image,
    max_rgb: int = VFX_KEY_MAX_RGB,
    max_lum: float = VFX_KEY_MAX_LUM,
) -> Image.Image:
    """戦闘 VFX 向け — 暗青緑マット等を透過にする。"""
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            r, g, b, a = px[x, y]
            if a == 0:
                px[x, y] = (0, 0, 0, 0)
                continue
            lum = (r + g + b) / 3.0
            if max(r, g, b) <= max_rgb and lum <= max_lum:
                px[x, y] = (0, 0, 0, 0)
    return img


def clean_vfx_image(img: Image.Image) -> Image.Image:
    return sanitize_alpha(key_dark_background(img))


def derive_open_chest(closed: Image.Image) -> Image.Image:
    """Closed 32×32 chest → open variant (lid up + gold interior)."""
    closed = closed.convert("RGBA")
    w, h = closed.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src = closed.load()
    dst = out.load()

    for y in range(13, h):
        for x in range(w):
            c = src[x, y]
            if c[3]:
                dst[x, y] = c

    for y in range(12, 21):
        for x in range(8, 24):
            edge = x in (8, 23) or y in (12, 20)
            if edge:
                dst[x, y] = (58, 38, 24, 255)
            else:
                dst[x, y] = (
                    (228, 186, 58, 255) if (x + y) % 3 else (196, 148, 36, 255)
                )

    for y in range(13, 18):
        for x in range(w):
            c = src[x, y]
            if c[3] and c[0] > 140:
                dst[x, y] = c

    for y in range(2, 13):
        for x in range(w):
            c = src[x, y]
            if c[3] == 0:
                continue
            ny = max(1, y - 6)
            dst[x, ny] = c
            if ny + 1 < 13:
                dst[x, ny + 1] = (
                    max(0, c[0] - 40),
                    max(0, c[1] - 35),
                    max(0, c[2] - 25),
                    c[3],
                )

    for x, y in ((11, 15), (16, 16), (20, 14), (14, 18), (18, 17)):
        dst[x, y] = (255, 240, 160, 255)
    return out


def tint_image(img: Image.Image, hue: float, sat_mult: float = 1.2) -> Image.Image:
    img = img.convert("RGBA")
    rgb = Image.merge("RGB", img.split()[:3])
    hsv = rgb.convert("HSV")
    h, s, v = hsv.split()
    h_data = h.load()
    s_data = s.load()
    target = int(hue * 255) % 256
    for y in range(h.size[1]):
        for x in range(h.size[0]):
            if s_data[x, y] > 10:
                h_data[x, y] = target
            s_data[x, y] = min(255, int(s_data[x, y] * sat_mult))
    tinted = Image.merge("HSV", (h, s, v)).convert("RGBA")
    tinted.putalpha(img.split()[3])
    return tinted


def gold_tint(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            lum = (r + g + b) / 3.0
            px[x, y] = (
                min(255, int(lum * 1.2 + 40)),
                min(255, int(lum * 0.95 + 20)),
                min(255, int(lum * 0.35)),
                a,
            )
    return img


def purple_tint(img: Image.Image) -> Image.Image:
    return tint_image(img, 0.78, 1.25)


def holy_tint(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            lum = (r + g + b) / 3.0
            px[x, y] = (
                min(255, int(lum * 1.1 + 30)),
                min(255, int(lum * 1.05 + 25)),
                min(255, int(lum * 0.7 + 10)),
                a,
            )
    return img


def _enhance_chest_pair(closed: Image.Image, dungeon_id: str) -> tuple[Image.Image, Image.Image]:
    opened = derive_open_chest(closed)
    if dungeon_id in ("frostridge", "frostwall_path"):
        closed = ImageEnhance.Brightness(closed).enhance(1.08)
        opened = ImageEnhance.Brightness(opened).enhance(1.08)
    if dungeon_id == "blackshore":
        closed = ImageEnhance.Color(closed).enhance(1.15)
        opened = ImageEnhance.Color(opened).enhance(1.15)
    return closed, opened


def generate_dungeon_objects() -> int:
    closed_base = remove_black_bg(Image.open(CHEST_CLOSED_SRC))
    exit_base = remove_black_bg(Image.open(EXIT_SRC))
    count = 0
    for dungeon_id, theme, hue in DUNGEONS:
        out_dir = ROOT / "assets/dungeon" / dungeon_id / "env"
        out_dir.mkdir(parents=True, exist_ok=True)
        if hue is None:
            closed = closed_base.copy()
        else:
            closed = tint_image(closed_base, hue)
        closed, opened = _enhance_chest_pair(closed, dungeon_id)
        gate = tint_image(exit_base, hue) if hue is not None else exit_base.copy()
        if dungeon_id in ("frostridge", "frostwall_path") and hue is not None:
            gate = ImageEnhance.Brightness(gate).enhance(1.08)
        closed.save(out_dir / "OBJ_TreasureChest_Closed.png", "PNG")
        opened.save(out_dir / "OBJ_TreasureChest_Open.png", "PNG")
        if hue is not None:
            gate.save(out_dir / f"OBJ_ExitGate_{theme}.png", "PNG")
            count += 3
            print(f"  {dungeon_id}: chest closed/open + exit")
        else:
            count += 2
            print(f"  {dungeon_id}: chest closed/open (base)")
    return count


def generate_vfx_sheets() -> None:
    base = clean_vfx_image(Image.open(HIT_SRC))
    sanitize_alpha(gold_tint(base.copy())).save(VFX_DIR / "FX_Hit_Critical.png", "PNG")
    sanitize_alpha(purple_tint(base.copy())).save(VFX_DIR / "FX_Hit_Dark.png", "PNG")
    sanitize_alpha(holy_tint(base.copy())).save(VFX_DIR / "FX_Hit_Holy.png", "PNG")
    base.save(VFX_DIR / "FX_Hit_Normal.png", "PNG")
    print("  FX_Hit_Normal/Critical/Dark/Holy.png")


def fix_batch6_vfx() -> None:
    clean_vfx_image(Image.open(HIT_SRC)).save(HIT_SRC, "PNG")
    heal_path = VFX_DIR / "FX_Heal.png"
    clean_vfx_image(Image.open(heal_path)).save(heal_path, "PNG")
    print("  FX_Hit_Normal (source), FX_Heal.png keyed")
    generate_vfx_sheets()


def fix_element_vfx() -> int:
    count = 0
    if not VFX_ELEMENTS_DIR.exists():
        return count
    for path in sorted(VFX_ELEMENTS_DIR.rglob("*.png")):
        clean_vfx_image(Image.open(path)).save(path, "PNG")
        count += 1
    print(f"  elements: {count} PNGs sanitized")
    return count


def write_spriteframes_tres(name: str, sheet: str, speed: float = 12.0) -> None:
    frames = []
    for i in range(4):
        frames.append(
            f"""[sub_resource type="AtlasTexture" id="f{i}"]
atlas = ExtResource("1_sheet")
region = Rect2({i * 32}, 0, 32, 32)
"""
        )
    text = f"""[gd_resource type="SpriteFrames" load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://{sheet}" id="1_sheet"]

{"".join(frames)}
[resource]
animations = [{{
"frames": [{{"duration": 1.0, "texture": SubResource("f0")}}, {{"duration": 1.0, "texture": SubResource("f1")}}, {{"duration": 1.0, "texture": SubResource("f2")}}, {{"duration": 1.0, "texture": SubResource("f3")}}],
"loop": false,
"name": &"default",
"speed": {speed}
}}]
"""
    out = ROOT / "resources/animation" / f"{name}.tres"
    out.write_text(text, encoding="utf-8")
    print(f"  {out.name}")


def generate_vfx_tres() -> None:
    write_spriteframes_tres("FX_Hit_Dark", "assets/vfx/batch6/FX_Hit_Dark.png")
    write_spriteframes_tres("FX_Hit_Holy", "assets/vfx/batch6/FX_Hit_Holy.png")
    write_spriteframes_tres("FX_Hit_Critical", "assets/vfx/batch6/FX_Hit_Critical.png", 14.0)


if __name__ == "__main__":
    print("Dungeon env objects...")
    n = generate_dungeon_objects()
    print(f"Generated {n} object PNGs.")
    print("VFX sheets...")
    fix_batch6_vfx()
    fix_element_vfx()
    generate_vfx_tres()
    print("Done.")
