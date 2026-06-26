# Phase2-M7 Closeout Completed v1.0

Status: Completed
Date: 2026-06-22
ProjectDocs: v3.5.27
Milestone: Phase2-M7 — Job & Build Foundation

---

Milestone Summary

Phase2-M7「Job & Build Foundation」が正式完了。JobData を gameplay に接続し、Build Identity とビルド可読性を確立した。Weapon-Centric 原則（Job は支援層）を維持したまま、Job modifier / Secondary Skill / Job UI / Build Summary の 4 本柱が実装された。

---

Completed Tasks

P2-Task033 — Party Job Alignment + JobStatCalculator（2026-06-21）
  - パーティ job_id を warrior / guardian / scout に整合
  - JobStatCalculator.gd（AffixStatCalculator 同型 RefCounted）新規作成

P2-Task034 — Job Modifier Combat Integration（2026-06-21）
  - CombatController._init_party_hp に per-member HP multiplier 接続
  - DungeonScene に per-member ATK / DEF multiplier 接続（P2-D115 合成順序）

P2-Task035 — starting_skill_ids Combat Link（2026-06-22）
  - _get_job_skill_data / _try_cast_secondary_skill を DungeonScene に追加
  - Primary と同一 ID の Secondary はスキップ（P2-D116/117）
  - guardian / scout（空）は正常系として Secondary なし

P2-Task036 — Job UI（2026-06-22）
  - BaseScene._format_member_job_line 追加
  - 3 メンバーの Job 名 / role / non-default modifier 表示（読み取り専用 P2-D120）
  - DataRegistry.get_job_data に ResourceLoader.exists() guard 追加

P2-Task037 — Build Summary UI（2026-06-22）
  - EquipmentScene に LabelBuildSummary 追加（P2-D121）
  - Weapon / Armor / Accessory / 鑑定済み Affix / Jobs / Build tag を 1 ブロック表示
  - Build tag: Affix stat_type + Job role から推定（Attack / Critical / Survival / Exploration）

P2-Task038 — Phase2-M7 Closeout（2026-06-22）
  - ProjectDocs 同期（本文書含む）

---

Decisions（M7 実装 Decision）

P2-D123: MVP パーティ初期 job_id = warrior / guardian / scout
P2-D124: JobStatCalculator — Job modifier 標準ヘルパー
P2-D125: Task033 は Calculator + party 整合のみ
P2-D126: Task034 で P2-D115 合成順序を実装
P2-D127: Job 戦闘接続は CombatController + DungeonScene のみ
P2-D128: 被弾 Defense は被弾メンバー index の job def modifier
P2-D134: _get_job_skill_data で starting_skill_ids[0] を解決
P2-D135: Primary と同一 id の Secondary は実行しない
P2-D136: Secondary 未設定・未取得は安全スキップ
P2-D137: Phase2-M7 Completed（本 Closeout）
P2-D138: 次マイルストーン候補 = Phase2-M8 Craft & Economy Foundation

採用済み Scope Decision（P2-D113〜122）は Phase2-M7_Scope_Adoption_Completed_v1.0.md 参照。

---

Exit Criteria 確認

EC-1: Job modifier connected → 達成（P2-Task034）
EC-2: starting_skill_ids connected → 達成（P2-Task035）
EC-3: Job UI → 達成（P2-Task036）
EC-4: Build Summary UI → 達成（P2-Task037）
EC-5（Closeout）→ 本文書（P2-Task038）

---

Deferred Items（M7 外 → 後続 Milestone）

- Craft / Economy / Material usage → Phase2-M8
- Affix reroll / Legendary / Curse → Future
- Codex UI → Phase2-M9
- 新ダンジョン → Phase3-B
- Job 選択・転職 UI → Future
- Job レベル / パッシブ → Future
- preferred_weapon_types ペナルティ → Future
- 敵スキル / ボス固有 mechanics → Future

---

GameplayArchive

Phase2_M7_Task035_starting_skill_ids_Completed_v1.0.md
Phase2_M7_Task036_Job_UI_Completed_v1.0.md
Phase2_M7_Task037_Build_Summary_UI_Completed_v1.0.md
Phase2_M7_Closeout_Completed_v1.0.md（本文書）

---

Next Milestone

Phase2-M8 — Craft & Economy Foundation（未着手）
- Material usage / Craft / Blacksmith 最小ループ
- 依存: Material data（M4）、Job / 装備基盤（M7）
- 開始: DevelopmentHQ による M8 Scope Proposal 承認後
