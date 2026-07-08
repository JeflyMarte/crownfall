#!/usr/bin/env python3
"""Validate IconPaths mappings against resources and files on disk."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ICON_PATHS = ROOT / "scripts/ui/IconPaths.gd"

CHECKS = [
    ("enemy", "resources/enemies", "id"),
    ("weapon", "resources/weapons", "id"),
    ("material", "resources/materials", "id"),
    ("dungeon", "resources/dungeons", "id"),
    ("stage", "resources/stages", "id"),
    ("armor", "resources/armors", "armor_id"),
    ("accessory", "resources/accessories", "id"),
    ("skill", "resources/skills", "id"),
]


def load_icon_map() -> dict[str, str]:
    text = ICON_PATHS.read_text(encoding="utf-8")
    return {m.group(1): m.group(2) for m in re.finditer(r'"([^"]+)":\s*"([^"]+)"', text)}


def resource_ids(folder: str, field: str) -> list[str]:
    ids: list[str] = []
    for path in sorted((ROOT / folder).glob("*.tres")):
        text = path.read_text(encoding="utf-8")
        m = re.search(rf'^{field}\s*=\s*"([^"]+)"', text, re.M)
        if m and m.group(1) not in ("unidentified",):
            ids.append(m.group(1))
    return ids


def main() -> int:
    icon_map = load_icon_map()
    errors: list[str] = []

    for category, folder, field in CHECKS:
        for rid in resource_ids(folder, field):
            key = f"{category}:{rid}"
            if key not in icon_map:
                errors.append(f"missing map: {key}")
                continue
            rel = icon_map[key].replace("res://", "")
            if not (ROOT / rel).exists():
                errors.append(f"missing file: {key} -> {rel}")

    for key, path in sorted(icon_map.items()):
        if not key.startswith(("enemy:", "weapon:", "material:", "dungeon:", "stage:", "armor:", "accessory:", "skill:")):
            continue
        rel = path.replace("res://", "")
        if not (ROOT / rel).exists():
            errors.append(f"orphan map file missing: {key} -> {rel}")

    if errors:
        print("IconPaths validation FAILED:")
        for err in errors:
            print(f"  - {err}")
        return 1

    print("IconPaths validation OK")
    for category, folder, field in CHECKS:
        print(f"  {category}: {len(resource_ids(folder, field))} checked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
