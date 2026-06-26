# Phase2_M8_Closeout_Completed_v1.0

**Status:** Completed
**Task:** P2-Task044
**Milestone:** Phase2-M8 — Craft & Economy Foundation
**Version:** v1.0
**ProjectDocs:** v3.5.33
**Completed Date:** 2026-06-22

---

## Milestone Summary

Phase2-M8「Craft & Economy Foundation」を正式完了。

Material 取得（Event/Elite/Merchant）→ Blacksmith 消費（Gold + Material）→ 未鑑定 Instance 生成の経済ループが成立。

---

## Completed Tasks

| Task | 内容 | 完了日 |
|---|---|---|
| P2-Task039 | CraftData Foundation（Craft Resource Pack） | 2026-06-22 |
| P2-Task040 | Material Consumption Logic | 2026-06-22 |
| P2-Task041 | BlacksmithScene Foundation | 2026-06-22 |
| P2-Task042 | Craft Output Integration | 2026-06-22 |
| P2-Task043 | Economy Integration（Merchant 素材購入） | 2026-06-22 |
| P2-Task044 | Phase2-M8 Closeout | 2026-06-22 |

---

## Decisions（P2-D139〜145）

| # | 決定事項 |
|---|---|
| P2-D139 | M8「Craft & Economy Foundation」正式 Scope 採用 |
| P2-D140 | CraftData スキーマ SSOT 確定 |
| P2-D141 | MVP レシピ 3 件（leather_armor / bone_armor / silver_ring） |
| P2-D142 | Weapon クラフト MVP 不可 |
| P2-D143 | consume_materials() は GameState 配置 |
| P2-D144 | Merchant 素材購入（relic_shard / ancient_bone 20G） |
| P2-D145 | Task039 は Craft Resource Pack で完了済み |

---

## Exit Criteria

| 項目 | 状態 |
|---|---|
| CraftData 3 件以上（DataRegistry） | ✓ |
| consume_materials() 素材減算 | ✓ |
| Gold 減算（Craft / Merchant） | ✓ |
| 未鑑定 Instance → inventory | ✓ |
| Save → Load inventory 保持 | ✓ |
| Merchant 素材購入（P2-D144） | ✓ |
| Economy 循環（取得→消費） | ✓ |

---

## Deferred Items（M8 外）

| 項目 | 移管先 |
|---|---|
| Weapon クラフト | 将来 Task |
| Weapon Merchant 販売 | MVP 禁止維持 |
| Affix reroll / Legendary / Curse | Phase2 後半〜 |
| Codex UI | **Phase2-M9** |
| 3 ダンジョン目以降 | Phase3-B |
| CraftData.unlock_condition | 将来 |

---

## Next Milestone

**Phase2-M9 — Codex & Discovery Foundation**

- discovery_registry → Codex UI
- Scope Adoption 待ち

---

## ProjectDocs Updated

- CurrentState.md
- CurrentSprint.md
- 11_TASK_INDEX.md
- 02_Roadmap.md
- 04_Development_Master_Plan.md（v1.5）
- CHANGELOG.md（v3.5.33）

---

## Gameplay / Code

**変更なし**（Closeout のみ）
