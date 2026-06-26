# P2_Task019_SkillData_Completed_v1.0

**Status:** Completed
**Task:** P2-Task019
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.4.5

---

## 概要

Phase2-M3 最小 SkillData Resource 基盤。プレイヤー / 敵 / ボス / ジョブスキル共通のデータ定義。
SkillExecutor・戦闘接続・スキル UI は対象外。

---

## スキーマ

| フィールド | 型 | 説明 |
|---|---|---|
| id | String | 一意 ID（ファイル名と一致） |
| display_name | String | 表示名 |
| description | String | 説明文 |
| skill_type | String | player / enemy / boss / job |
| target_type | String | enemy / ally / self / all |
| power_multiplier | float | ダメージ・回復等の倍率 |
| cooldown | float | クールダウン秒（trigger_type=cooldown 時） |
| trigger_type | String | M3 placeholder: "cooldown" |
| effect_type | String | damage / heal / buff / none |
| tags | Array[String] | 分類タグ（physical, melee 等） |

---

## サンプル

`resources/skills/slash_attack.tres`

- id: slash_attack
- skill_type: player
- power_multiplier: 1.5
- effect_type: damage
- tags: physical, melee

---

## 参照

- `scripts/data/SkillData.gd`
- `DataRegistry.get_skill_data(id)` → `resources/skills/{id}.tres`

---

## 将来フェーズ

1. SkillExecutor — cooldown / trigger 処理
2. WeaponData.fixed_skill_id → SkillData 参照
3. EnemyData / JobData から skill id リスト参照
4. CombatController へのスキル発動接続

---

## 非実装

- SkillExecutor
- スキル UI
- 戦闘バランス変更
- 敵 / ボス / ジョブ用 .tres（スキーマのみ対応）

---

## Decision

P2-D039〜P2-D041

---

## 参照 SSOT

- docs/specs/implementation/03_Resource設計.md — SkillData 節
- docs/specs/game/08_戦闘_AI.md — SkillData 節
