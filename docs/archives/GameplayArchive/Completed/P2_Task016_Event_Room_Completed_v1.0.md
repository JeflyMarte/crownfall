# P2_Task016_Event_Room_Completed_v1.0

**Status:** Completed
**Task:** P2-Task016
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.4.2

---

## 概要

Phase2-M3 Special Room として Event Room を SSOT 確定。
2 択・即時解決の非戦闘イベント。Branch Route（UNKNOWN）および固定シーケンスから出現。

---

## 仕様

### 出現

- `RoomType.EVENT`
- Branch: UNKNOWN_POOL
- 固定: `ROOM_SEQUENCE` index 2, 5（王都跡 branch_enabled=false でも体験可）

### イベント一覧（5 種・ランダム 1 件）

| id | 説明 | 選択A | 報酬 type |
|---|---|---|---|
| fallen_altar | 崩れた祭壇 | 触れる | heal +8 HP |
| ancient_tome | 古文書 | 解読する | gold +25 |
| sealed_door | 封印された扉 | 開ける | buff x1.15 |
| ruined_crate | 朽ちた木箱 | 調べる | material（placeholder） |
| faded_inscription | 色あせた碑文 | 記録する | lore（placeholder） |

選択B は全イベント「何も起こらない」。

### 報酬処理

| type | 実装 |
|---|---|
| heal | `CombatController.heal_party()` |
| gold | `accumulate_rewards(0, amount)` |
| buff | `DungeonController.run_damage_multiplier` → `_calc_damage()` |
| material | ログのみ |
| lore | ログのみ |

### UI

- `EventContainer`: LabelEventDesc + ButtonEventA/B
- 選択後 UI 非表示、Branch/次部屋ボタン復帰

---

## 実装変更（P2-Task016）

- `sealed_door`: exp → buff（設計カテゴリ整合）
- `ruined_crate` / `faded_inscription` 追加
- `run_damage_multiplier` 追加（周回内攻撃補正）

---

## 非実装 / 将来

- Shrine 機能
- Discovery 連動
- material / lore の永続化（MaterialData / Codex）
- イベント確率分岐（現在は確定 outcome）

---

## 関連 Decision

- P2-D024〜P2-D028

---

## 参照

- `docs/specs/game/05_ダンジョン.md` — EVENT Room 節
- `scripts/dungeon/DungeonController.gd` — EVENTS
- `scripts/dungeon/DungeonScene.gd` — Event UI
