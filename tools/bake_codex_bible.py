#!/usr/bin/env python3
"""Bake world bible Markdown into exportable JSON for Codex.

Source of truth remains docs/specs/world/*.md (editor / HQ).
Runtime CatalogHelper reads resources/codex/*.json so iOS/Android
exports (which omit docs/) still show History / Fragments.

Usage:
  python3 tools/bake_codex_bible.py
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HISTORY_MD = ROOT / "docs/specs/world/01_History.md"
FRAGMENTS_MD = ROOT / "docs/specs/world/12_Fragments.md"
OUT_DIR = ROOT / "resources/codex"
HISTORY_JSON = OUT_DIR / "history_entries.json"
FRAGMENTS_JSON = OUT_DIR / "fragment_entries.json"


def _collect_sections(
    lines: list[str],
    start: int,
    section_prefix: str,
    stop_prefix: str,
) -> tuple[dict[str, str], int]:
    sections: dict[str, str] = {}
    i = start
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith(stop_prefix):
            return sections, i
        if line.startswith(section_prefix):
            name = line[len(section_prefix) :].strip()
            i += 1
            parts: list[str] = []
            while i < len(lines):
                inner = lines[i].strip()
                if (
                    inner.startswith(section_prefix)
                    or inner.startswith(stop_prefix)
                    or inner == "---"
                ):
                    break
                if inner:
                    parts.append(inner)
                i += 1
            sections[name] = "\n".join(parts)
            continue
        i += 1
    return sections, i


def _parse_related_ids(section_body: str) -> list[str]:
    ids: list[str] = []
    if not section_body:
        return ids
    for line in section_body.split("\n"):
        trimmed = line.strip()
        if not trimmed.startswith("- "):
            continue
        rest = trimmed[2:].strip()
        if not rest.startswith("HE-"):
            continue
        he_id = rest.split()[0]
        if he_id and he_id not in ids:
            ids.append(he_id)
    return ids


def parse_history(text: str) -> list[dict]:
    lines = text.split("\n")
    entries: list[dict] = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line.startswith("# HE-"):
            i += 1
            continue
        body = line[2:].strip()
        space = body.find(" ")
        he_id = body[:space] if space >= 0 else body
        title = body[space + 1 :].strip() if space >= 0 else ""
        i += 1
        sections, i = _collect_sections(lines, i, "## ", "# HE-")
        entries.append(
            {
                "id": he_id,
                "title": title,
                "overview": sections.get("Overview", ""),
                "era": sections.get("Era", ""),
                "related_entries": _parse_related_ids(
                    sections.get("Related History Entries", "")
                ),
            }
        )
    return entries


def parse_fragments(text: str) -> list[dict]:
    lines = text.split("\n")
    entries: list[dict] = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line.startswith("# LF "):
            i += 1
            continue
        body_text = line[5:].strip()
        space = body_text.find(" ")
        lf_id = body_text[:space] if space >= 0 else body_text
        title = body_text[space + 1 :].strip() if space >= 0 else ""
        i += 1
        sections, i = _collect_sections(lines, i, "## ", "# LF ")
        entries.append(
            {
                "id": lf_id,
                "title": title,
                "body": sections.get("Body", ""),
                "medium": sections.get("Medium", ""),
                "source": sections.get("Source", ""),
            }
        )
    return entries


def _write_json(path: Path, data: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    if not HISTORY_MD.is_file():
        raise SystemExit(f"missing {HISTORY_MD}")
    if not FRAGMENTS_MD.is_file():
        raise SystemExit(f"missing {FRAGMENTS_MD}")

    history = parse_history(HISTORY_MD.read_text(encoding="utf-8"))
    fragments = parse_fragments(FRAGMENTS_MD.read_text(encoding="utf-8"))

    if len(history) < 50:
        raise SystemExit(f"expected >=50 HE entries, got {len(history)}")
    if not any(e["id"] == "HE-001" for e in history):
        raise SystemExit("HE-001 missing")
    if len(fragments) < 1:
        raise SystemExit("expected >=1 LF entries")

    _write_json(HISTORY_JSON, history)
    _write_json(FRAGMENTS_JSON, fragments)
    print(f"bake_codex_bible: history={len(history)} -> {HISTORY_JSON.relative_to(ROOT)}")
    print(f"bake_codex_bible: fragments={len(fragments)} -> {FRAGMENTS_JSON.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
