# Phase2_M9_Task049_History_Dungeon_Bible_Link_Completed_v1.0

**Status:** Completed
**Task:** P2-Task049
**Milestone:** Phase2-M9 — Codex & Discovery Foundation
**Version:** v1.0
**ProjectDocs:** v3.5.38
**Completed Date:** 2026-06-22

---

## 概要

Codex の History / Dungeon カテゴリを Bible 文書（Read-Only parse）と接続。Detail に Era / Location / Theme / Related を追加。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| CatalogHelper Bible parse | Bible 本文変更 |
| History Entry 拡張 | Save 形式変更 |
| Dungeon Entry 拡張 | Discovery 登録 |
| CodexScene Detail 強化 | Gameplay 変更 |
| Fallback 処理 | DataRegistry 仕様変更 |

---

## Bible Link Structure

### History Entry（CatalogHelper）

| フィールド | ソース |
|---|---|
| id | `# HE-xxx` ヘッダ |
| title / display_name | ヘッダタイトル |
| description (overview) | `## Overview` |
| era | `## Era` |
| related_entries | `## Related History Entries`（HE id 抽出） |

### Dungeon Entry（CatalogHelper）

| フィールド | ソース |
|---|---|
| id | DataRegistry dungeon id |
| display_name | Dungeon Bible 名（なければ .tres） |
| description (overview) | `### Overview` |
| location | `### Location` |
| exploration_theme | `### Exploration Theme` |
| related_history | `### Related History Entries` |

### ID マップ

| Game ID | Bible ID |
|---|---|
| royal_ruins | Dungeon-001 |
| graveyard | Dungeon-002 |

---

## Display Examples

### History discovered

```
Entry ID: HE-010
Name: Black Forge Kingdom
Status: Discovered
Category: History
Era: Age of Kingdoms

Overview:
A mountain kingdom renowned for master smiths...

Related:
HE-001, HE-002
```

### Dungeon discovered

```
Entry ID: royal_ruins
Name: White Capital
Status: Discovered
Category: Dungeon
Location: 中央平原（White Kingdom首都）
Theme: 王国時代の政治・王家の遺産。...

Overview:
White Kingdom首都の巨大遺跡。...

Related History:
HE-005, HE-006, HE-007, HE-008
```

### Undiscovered

- Entry ID / Name / Overview: `???`
- Related: 非表示

---

## Fallback Behavior

| 条件 | 動作 |
|---|---|
| Bible ファイル不存在 | 既存 Entry のみ（overview 空可） |
| Bible entry 未対応 | DataRegistry display_name のみ |
| related 空 | Related 行非表示 |
| era が `—` | Era 行非表示 |

---

## Files

| ファイル | 変更 |
|---|---|
| `scripts/codex/CatalogHelper.gd` | Bible parse |
| `scripts/codex/CodexScene.gd` | Detail 表示 |
| `scenes/codex/CodexScene.tscn` | ラベル追加 |

---

## Verification

- [x] History Bible 由来 Detail
- [x] Dungeon Bible 由来 Detail
- [x] 未発見表示維持
- [x] Bible 欠落フォールバック
- [x] CatalogHelper のみ（CodexScene）
- [x] linter OK
- [x] Regression なし

---

## Next

**P2-Task050** — Phase2-M9 Closeout
