# P2_Task021_Multi_Dungeon_Foundation_Completed_v1.0

**Status:** Completed
**Task:** P2-Task021
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.5.0

---

## 概要

Phase2-M4 Multi-Dungeon Foundation。`royal_ruins` hardcode を除去し、`GameState.current_dungeon_id` + DataRegistry 経由で DungeonData を起動。

---

## 選択フロー

```text
BaseScene → GameState.current_dungeon_id（空なら royal_ruins）
         → DungeonScene → get_active_dungeon_id()
         → DungeonController.start_dungeon(id)
         → DataRegistry.get_dungeon_data(id)
```

---

## 実装

| ファイル | 変更 |
|---|---|
| `Constants.gd` | `DEFAULT_DUNGEON_ID` |
| `GameState.gd` | `get_active_dungeon_id()` |
| `DungeonController.gd` | `start_dungeon(dungeon_id)` + DataRegistry |
| `DungeonScene.gd` | hardcode 除去 |
| `BaseScene.gd` | 探索開始時 id 設定 |
| `SaveManager.gd` | `current_dungeon_id` save/load |

---

## 検証

- `royal_ruins` 探索開始・完走（従来同等）
- `get_dungeon_data("royal_ruins")` パス有効
- hardcode path なし

---

## 非実装

- Base ダンジョン選択 UI（Task022）
- 白骸墓地コンテンツ（Task023）
- EVENTS/MERCHANT の DG 別分離

---

## Decision

P2-D045〜P2-D047

---

## 参照

- docs/specs/game/05_ダンジョン.md — Multi-Dungeon Foundation 節
- docs/specs/implementation/04_シーン構成.md
