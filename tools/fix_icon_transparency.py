#!/usr/bin/env python3
"""Remove matte backgrounds from UI icons and save as RGBA PNGs."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

ICON_DIRS = [
    ROOT / "assets/ui/relics",
    ROOT / "assets/ui/materials",
    ROOT / "assets/ui/equipment",
]

BLACK_THRESHOLD = 28
WHITE_THRESHOLD = 240


def corner_bg_kind(img: Image.Image) -> str:
    rgb = img.convert("RGB")
    w, h = rgb.size
    corners = [
        rgb.getpixel((0, 0)),
        rgb.getpixel((w - 1, 0)),
        rgb.getpixel((0, h - 1)),
        rgb.getpixel((w - 1, h - 1)),
    ]
    if all(r <= BLACK_THRESHOLD and g <= BLACK_THRESHOLD and b <= BLACK_THRESHOLD for r, g, b in corners):
        return "black"
    if all(r >= WHITE_THRESHOLD and g >= WHITE_THRESHOLD and b >= WHITE_THRESHOLD for r, g, b in corners):
        return "white"
    avg = tuple(sum(c[i] for c in corners) // 4 for i in range(3))
    if sum(avg) / 3 <= BLACK_THRESHOLD:
        return "black"
    if sum(avg) / 3 >= WHITE_THRESHOLD:
        return "white"
    return "unknown"


def remove_matte_bg(img: Image.Image, kind: str, hard: int = 28, soft: int = 42) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if kind == "black":
                dist = max(r, g, b)
            elif kind == "white":
                dist = max(255 - r, 255 - g, 255 - b)
            else:
                continue

            if dist <= hard:
                px[x, y] = (r, g, b, 0)
            elif dist <= soft:
                fade = (dist - hard) / max(1, soft - hard)
                px[x, y] = (r, g, b, int(a * fade))

    return img


def process(path: Path, dry_run: bool = False) -> str:
    img = Image.open(path)
    if img.mode == "RGBA":
        rgba = img.convert("RGBA")
        corners = [
            rgba.getpixel((0, 0))[3],
            rgba.getpixel((rgba.width - 1, 0))[3],
            rgba.getpixel((0, rgba.height - 1))[3],
            rgba.getpixel((rgba.width - 1, rgba.height - 1))[3],
        ]
        if all(a == 0 for a in corners):
            return "skip_ok"
        kind = corner_bg_kind(img.convert("RGB"))
        if kind == "unknown":
            return "skip_unknown"
    else:
        kind = corner_bg_kind(img)
        if kind == "unknown":
            return "skip_unknown"

    out = remove_matte_bg(img, kind)
    if dry_run:
        return f"would_fix_{kind}"

    out.save(path, "PNG")
    return f"fixed_{kind}"


def audit(paths: list[Path]) -> dict[str, list[str]]:
    buckets: dict[str, list[str]] = {}
    for path in paths:
        img = Image.open(path).convert("RGBA")
        w, h = img.size
        corners = [
            img.getpixel((0, 0))[3],
            img.getpixel((w - 1, 0))[3],
            img.getpixel((0, h - 1))[3],
            img.getpixel((w - 1, h - 1))[3],
        ]
        px = img.load()
        transparent = sum(1 for y in range(h) for x in range(w) if px[x, y][3] < 128)
        ratio = transparent / (w * h)
        if all(a == 0 for a in corners) and ratio > 0.05:
            key = "ok"
        elif all(a == 255 for a in corners) and ratio < 0.01:
            key = "opaque"
        else:
            key = "partial"
        buckets.setdefault(key, []).append(str(path.relative_to(ROOT)))
    return buckets


def collect_targets(extra_dirs: list[Path] | None = None) -> list[Path]:
    dirs = list(ICON_DIRS)
    if extra_dirs:
        dirs.extend(extra_dirs)
    paths: list[Path] = []
    for d in dirs:
        if not d.exists():
            continue
        paths.extend(sorted(d.glob("*.png")))
    return paths


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--audit-only", action="store_true")
    args = parser.parse_args()

    paths = collect_targets()
    if args.audit_only:
        buckets = audit(paths)
        for key in ("ok", "partial", "opaque"):
            items = buckets.get(key, [])
            print(f"{key}: {len(items)}")
            for item in items[:8]:
                print(f"  {item}")
            if len(items) > 8:
                print(f"  ... +{len(items) - 8}")
        return

    stats: dict[str, int] = {}
    for path in paths:
        result = process(path, dry_run=args.dry_run)
        stats[result] = stats.get(result, 0) + 1
        if result.startswith("fixed") or result.startswith("would_fix"):
            print(f"{result}: {path.relative_to(ROOT)}")

    print("\n--- process stats ---")
    for k, v in sorted(stats.items()):
        print(f"{k}: {v}")

    if not args.dry_run:
        buckets = audit(paths)
        print("\n--- post-audit ---")
        for key in ("ok", "partial", "opaque"):
            print(f"{key}: {len(buckets.get(key, []))}")


if __name__ == "__main__":
    main()
