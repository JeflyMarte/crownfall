# P2_Task018_Discovery_System_Completed_v1.0

**Status:** Completed
**Task:** P2-Task018
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.4.4

---

## 概要

Phase2-M3 最小 Discovery System。探索中の重要発見を category:entry_id で登録。
Codex UI / Achievement / 報酬なし。

---

## 仕様

### ストレージ

- `GameState.discovery_registry: Dictionary`
- キー: `"category:entry_id"` → `true`
- `SaveManager` で永続化

### カテゴリ

| category | トリガー |
|---|---|
| room | Special Room 入室（heal/treasure/merchant/event/elite） |
| enemy | 戦闘開始 |
| event | Event Room 入室（event id） |
| lore | Event lore outcome |
| material | Event material outcome / Elite material bonus |

### 可視化

初回のみ LabelLog: `【新規発見】category / entry_id`

### 別系統（維持）

`dungeon_progress.discovery` float — 進行度メーター。戦闘バランス無関係。

---

## 実装

- `scripts/discovery/DiscoveryRegistry.gd` — register / format
- `GameState.discovery_registry`
- `SaveManager` save/load
- `DungeonScene` フック

---

## 非実装

- Codex UI
- History Bible 閲覧
- Achievement / Collection rewards
- Discovery stat bonuses

---

## Decision

P2-D034〜P2-D038

---

## 参照

- docs/specs/game/05_ダンジョン.md — Discovery System 節
