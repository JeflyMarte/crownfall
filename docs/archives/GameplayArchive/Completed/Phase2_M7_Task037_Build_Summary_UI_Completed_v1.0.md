# Phase2-M7 Task037 — Build Summary UI Completed v1.0

Status: Completed
Date: 2026-06-22
ProjectDocs: v3.5.26
Milestone: Phase2-M7 — Job & Build Foundation
Task: P2-Task037

---

Purpose

EquipmentScene に Build Summary を 1 ブロックで追加し、装備・Affix・Job の概要をプレイヤーが読み取れる状態にする（P2-D121）。

---

Display Format

=== Build Summary ===
Weapon: iron_sword  ATK 17
Armor: leather_armor  DEF 5
Accessory: silver_ring

Affix:
- 鋭利: Attack +3
- 偉力: Attack +2

Jobs:
- 戦士: ATK x1.10
- 守護者: HP x1.20 DEF x1.20
- 斥候: scout

Build: Attack / Survival

---

Implementation

変更ファイル:
- scenes/equipment/EquipmentScene.tscn
- scripts/equipment/EquipmentScene.gd

EquipmentScene.tscn:
- LabelBuildSummary（Label / autowrap_mode = 3）を ButtonBack の直前に追加

EquipmentScene.gd 追加関数:
- _update_build_summary(): LabelBuildSummary.text に _build_summary_text() をセット
- _build_summary_text(): 全セクションを結合してテキスト生成
- _collect_affix_lines(): is_appraised 確認後、prefix_ids / suffix_ids を走査して表示行を生成
- _format_affix_stat(affix_data): stat_type + value をフォーマット（% 系は百分率変換）
- _collect_job_lines(): party_members を走査し Job 名 + non-default modifier を生成
- _estimate_build_tags(): Affix stat_type と Job role からタグ推定

Build tag 判定ルール:
- Affix stat_type に "attack" → Attack
- Affix stat_type に "critical" → Critical
- Affix stat_type に "hp" / "defense" / "healing" → Survival
- Job role = dps → Attack
- Job role = tank → Survival
- Job role = scout → Exploration
- タグなし → Basic

---

Fallback Behavior

- 未装備: "Weapon: None" / "Armor: None" / "Accessory: None"
- 未鑑定 Affix: Affix セクション非表示（is_appraised = false はスキップ）
- JobData 欠落: job_id をそのまま表示
- AffixData 欠落: affix_id をそのまま表示
- クラッシュ: なし（全パスに null チェック）

---

Verification

- EquipmentScene に Build Summary 表示: OK（LabelBuildSummary ノード追加）
- Weapon / Armor / Accessory 表示: OK
- 鑑定済み Affix 表示: OK（is_appraised チェック済み）
- 未鑑定 Affix 非表示: OK
- Party Job Summary 表示: OK
- Build tag 表示: OK（warrior=dps → Attack、guardian=tank → Survival が必ず入る）
- 未装備クラッシュなし: OK（null ガード）
- JobData / AffixData 欠落クラッシュなし: OK（null チェック）
- Headless 検証: エラーなし
- Combat Regression: CombatController / DungeonScene 未変更
- Save Regression: SaveManager 未変更
- Equipment 変更 Regression: 装備変更ロジック未変更

---

Next Task

P2-Task038 — Phase2-M7 Closeout
