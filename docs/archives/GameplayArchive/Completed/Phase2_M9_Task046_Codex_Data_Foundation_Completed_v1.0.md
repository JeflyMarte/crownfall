# Phase2_M9_Task046_Codex_Data_Foundation_Completed_v1.0

**Status:** Completed
**Task:** P2-Task046
**Milestone:** Phase2-M9 — Codex & Discovery Foundation
**Version:** v1.0
**ProjectDocs:** v3.5.35
**Completed Date:** 2026-06-22

---

## 概要

Codex 用 CatalogHelper を実装。5 カテゴリの Entry 取得と Discovery 判定。UI 未接続。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| CatalogHelper.gd | CodexScene / UI |
| DataRegistry 一覧 API | BaseScene |
| Entry 整形 + discovered | Discovery 登録フック |
| History Bible parse | Save Format 変更 |

---

## API

```gdscript
CatalogHelper.get_enemy_entries() -> Array
CatalogHelper.get_dungeon_entries() -> Array
CatalogHelper.get_material_entries() -> Array
CatalogHelper.get_weapon_entries() -> Array
CatalogHelper.get_history_entries() -> Array
CatalogHelper.is_discovered(category, id) -> bool
```

---

## Entry Format

```gdscript
{
  "id": "fallen_soldier",
  "display_name": "亡国兵",  # undiscovered → "???"
  "icon": "",
  "description": "",
  "discovered": true,
}
```

---

## Discovery Rules

| category | 判定 |
|---|---|
| enemy | `enemy:{id}` |
| material | `material:{id}` |
| dungeon | `dungeon:{id}` |
| weapon | `weapon:{id}` |
| history | HE-001〜004 常時 / `history:{id}` / lore→HE マップ |

---

## Files

- `scripts/codex/CatalogHelper.gd`
- `scripts/autoload/DataRegistry.gd`

---

## Next

**P2-Task047** — Codex UI Foundation
