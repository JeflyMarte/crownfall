# Phase2-M8 Scope Adoption Completed v1.0

Status: Completed
Date: 2026-06-22
ProjectDocs: v3.5.28
Task Type: Scope Adoption（コード変更なし）

---

## Purpose

Phase2-M8「Craft & Economy Foundation」の Scope を正式採用し、ProjectDocs へ反映した。
本 Task は仕様採用のみ。Gameplay 実装は P2-Task040 以降。

---

## Design Input

- docs/archives/GameplayArchive/Proposal/Phase2-M8_Craft_Economy_Foundation_Design_v1.0.md
- docs/archives/GameplayArchive/Proposal/Phase2-M8_Task_Proposal_v1.0.md
- docs/archives/GameplayArchive/Completed/Phase2_M8_Craft_Resource_Pack_v1.0.md

---

## Adopted Decisions（P2-D139〜145）

| # | 決定事項 |
|---|---|
| P2-D139 | Phase2-M8「Craft & Economy Foundation」正式 Scope 採用（Design v1.0 + Task Proposal v1.0） |
| P2-D140 | CraftData スキーマ（7 フィールド）SSOT 確定 |
| P2-D141 | MVP レシピ 3 件採用（craft_leather_armor / craft_silver_ring / craft_bone_armor） |
| P2-D142 | MVP では Weapon クラフト不可。output_type="weapon" は将来拡張予約のみ |
| P2-D143 | consume_materials() は GameState に配置（専用 CraftController なし） |
| P2-D144 | Merchant Materials 購入（P2-Task043）を M8 スコープとして正式計画。価格: relic_shard 20G / ancient_bone 20G |
| P2-D145 | P2-Task039（CraftData Foundation）は Craft Resource Pack で完了済み。M8 実装開始は P2-Task040 から |

---

## M8 Task Plan（P2-Task039〜044）

| Task | 内容 | 状態 |
|---|---|---|
| P2-Task039 | CraftData Foundation | 完了（Craft Resource Pack） |
| P2-Task040 | Material Consumption Logic（GameState.consume_materials） | 未着手 |
| P2-Task041 | BlacksmithScene Foundation（新規シーン + BaseScene 遷移） | 未着手 |
| P2-Task042 | Craft Output Integration（作成 → Instance 生成 → Inventory） | 未着手 |
| P2-Task043 | Economy Integration（Merchant 素材購入） | 未着手 |
| P2-Task044 | Phase2-M8 Closeout | 未着手 |

---

## M8 Exit Criteria

| 確認項目 | 内容 |
|---|---|
| CraftData 定義 | DataRegistry から 3 件以上のレシピが取得できる |
| Material 消費 | consume_materials() が素材と Gold を正しく減算する |
| Instance 生成 | 作成後に未鑑定 Instance が inventory に追加される |
| Save/Load | クラフト後に Save → Load で inventory が保持される |
| Economy 循環 | Event/Elite で取得した Materials が Blacksmith で消費できる |
| UI 表示 | 素材不足・Gold 不足時に「作成」ボタンが無効になる |

---

## Economy Design（採用済み）

Gold Economy:
- 既存 Sink: Appraisal（100G）、Merchant（run 中）
- M8 追加: Blacksmith（Base・任意）— craft_leather_armor 50G / craft_bone_armor 40G / craft_silver_ring 80G

Material Economy:
- 供給: Event Room（relic_shard）/ Elite Room（elite_relic_shard）
- M8 追加消費先: Blacksmith クラフト

---

## Updated ProjectDocs

- docs/specs/core/03_Decision_Log.md: P2-D139〜145 追加
- docs/specs/core/02_Roadmap.md: M8 進行中・Task 一覧
- docs/specs/core/04_Development_Master_Plan.md: v1.5、M8 全 Scope
- docs/specs/implementation/11_TASK_INDEX.md: Phase2-M8 Section 追加
- docs/project/CurrentState.md: M8 進行中
- docs/project/CurrentSprint.md: M8 Sprint 開始
- CHANGELOG.md: v3.5.28

---

## Next

P2-Task040 — Material Consumption Logic（GameState.consume_materials）
