# P2_Task022_Base_Dungeon_Select_Completed_v1.0

**Status:** Completed
**Task:** P2-Task022
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.5.1

---

## 概要

Phase2-M4 Base Dungeon Select。拠点でダンジョンを選んでから探索開始。

---

## UI

| 要素 | 動作 |
|---|---|
| ButtonSelectRoyalRuins | 王都跡を選択 |
| ButtonSelectGraveyard | 白骸墓地 — 準備中（disabled） |
| LabelSelectedDungeon | 選択中表示 |
| ButtonDungeon | 探索開始（有効 DG のみ） |

---

## フロー

```text
BaseScene → 王都跡選択 → GameState.current_dungeon_id = royal_ruins
         → 探索開始 → DungeonScene（Task021 フロー）
```

---

## 実装

- `scenes/base/BaseScene.tscn` — DungeonSelectRow 追加
- `scripts/base/BaseScene.gd` — 選択・可用性チェック
- `Constants.GRAVEYARD_DUNGEON_ID` = graveyard（placeholder id）

---

## 検証

- 王都跡選択 → 探索開始 → royal_ruins 起動
- 白骸墓地は disabled「準備中」
- graveyard .tres 未作成（Task023）

---

## Decision

P2-D048〜P2-D050

---

## 参照

- docs/specs/game/05_ダンジョン.md — Base Dungeon Select 節
- docs/specs/implementation/04_シーン構成.md
