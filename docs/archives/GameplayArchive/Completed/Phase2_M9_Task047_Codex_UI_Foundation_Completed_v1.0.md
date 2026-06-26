# Phase2_M9_Task047_Codex_UI_Foundation_Completed_v1.0

**Status:** Completed
**Task:** P2-Task047
**Milestone:** Phase2-M9 — Codex & Discovery Foundation
**Version:** v1.0
**ProjectDocs:** v3.5.36
**Completed Date:** 2026-06-22

---

## 概要

CatalogHelper を利用した Codex 最小 UI。5 カテゴリタブ・一覧・詳細パネル。BaseScene から遷移。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| CodexScene.tscn / CodexScene.gd | Discovery 登録フック |
| Category Tabs × 5 | Save 形式変更 |
| Entry List + Detail（名前・説明） | Gameplay / Combat / Dungeon 変更 |
| BaseScene 図鑑ボタン | DataRegistry 直接アクセス |
| 未発見 `???` 表示 | アイコン表示（Detail 拡張は Task048） |

---

## UI 構成

```
CodexScene
├── LabelTitle（図鑑）
├── TabRow（Enemy / Dungeon / Material / Weapon / History）
├── EntryListScroll → EntryListContainer（動的 Button 一覧）
├── Detail（LabelDetailName / LabelDetailDescription）
└── ButtonBack
```

---

## Navigation

```
BaseScene → [図鑑] → CodexScene → [戻る] → BaseScene
```

---

## Data Flow

- カテゴリ切替 → `CatalogHelper.get_*_entries()`
- Entry 選択 → Detail に `display_name` / `description` 表示
- `discovered == false` → 名前・説明とも `???`

---

## Files

| ファイル | 変更 |
|---|---|
| `scenes/codex/CodexScene.tscn` | 新規 |
| `scripts/codex/CodexScene.gd` | 新規 |
| `scenes/base/BaseScene.tscn` | ButtonCodex 追加 |
| `scripts/base/BaseScene.gd` | Codex 遷移 |

---

## Verification

- [x] Enemy / Dungeon / Material / Weapon / History 一覧表示
- [x] Category 切替
- [x] Detail 表示（名前・説明）
- [x] 未発見 `???`
- [x] CatalogHelper のみ利用
- [x] linter OK

---

## Next

**P2-Task048** — Discovery Detail View
