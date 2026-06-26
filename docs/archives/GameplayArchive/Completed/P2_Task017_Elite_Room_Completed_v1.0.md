# P2_Task017_Elite_Room_Completed_v1.0

**Status:** Completed
**Task:** P2-Task017
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.4.3

---

## 概要

Phase2-M3 最終コア Special Room として Elite Room を SSOT 確定。
常に戦闘・elite_pool 敵・高報酬（x1.5 + ボーナスドロップ）。

---

## 仕様

### 出現

- `RoomType.ELITE`
- Branch: DANGEROUS_POOL（COMBAT / ELITE）
- 固定: `ROOM_SEQUENCE` index 4

### 敵選択

- `pick_elite_enemy_data()` → `DungeonData.elite_pool`
- 王都跡: rusted_knight, ruins_looter（enemy_type=ELITE）

### 報酬

| 種別 | 率/倍率 |
|---|---|
| EXP / Gold | x1.5 |
| Armor（leather_armor） | 35% |
| Accessory（silver_ring） | 25% |
| 高品質素材 | 15% placeholder ログ |

### 戦闘

- 既存 CombatTimer 自動戦闘
- ボス mechanics / Discovery 連動なし

---

## 実装変更（P2-Task017）

- `apply_elite_bonus_loot()` 追加
- Elite 撃破ログ拡張
- 入室ログ `【エリート】`  prefix
- rusted_knight / ruins_looter → enemy_type=ELITE

---

## 非実装 / 将来

- 素材永続化（MaterialData）
- Elite 固有 AI / スキル
- Discovery 連動

---

## 関連 Decision

- P2-D029〜P2-D033

---

## 参照

- docs/specs/game/05_ダンジョン.md — ELITE Room 節
- docs/specs/game/08_戦闘_AI.md — Elite Room 戦闘節
- scripts/dungeon/DungeonController.gd
