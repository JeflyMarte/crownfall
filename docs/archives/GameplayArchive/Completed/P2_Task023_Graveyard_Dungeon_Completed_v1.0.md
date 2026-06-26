# P2_Task023_Graveyard_Dungeon_Completed_v1.0

**Status:** Completed
**Task:** P2-Task023
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.5.2

---

## 概要

Phase2-M4 2 つ目のプレイアブルダンジョン「白骸墓地」+ 敵 6 体。Multi-Dungeon 初回完成。

---

## Graveyard DungeonData

| 項目 | 値 |
|---|---|
| id | graveyard |
| display_name | 白骸墓地 |
| difficulty | 2 |
| branch_enabled | true |
| enemy_pool | 4 通常 |
| elite_pool | ossuary_knight |
| boss_id | gravekeeper |

---

## Enemy Set

| id | 表示名 | type |
|---|---|---|
| bone_walker | 骨の歩兵 | NORMAL |
| grave_bat | 墓蝙蝠 | NORMAL |
| hollow_gravedigger | 死体運び | NORMAL |
| pale_hound | 白骨の番犬 | NORMAL |
| ossuary_knight | 納骨堂の騎士 | ELITE |
| gravekeeper | 千鐘の墓守 | BOSS |

ステータス: 王都跡比 +10〜20% 目安。

---

## 最小修正（コンテンツ接続）

- `pick_combat_enemy_data()` — BOSS/MID_BOSS/ELITE/COMBAT 振分
- `pick_boss_enemy_data()` — `DungeonData.boss_id` 使用
- enemy pick を DataRegistry 経由に（2 箇所）

---

## Base 選択

白骸墓地ボタン有効化（Task022 UI + graveyard.tres）。

---

## Decision

P2-D051〜P2-D053

---

## 非実装

- MaterialData / SkillExecutor / DG 別 EVENTS
- 地下工廠
