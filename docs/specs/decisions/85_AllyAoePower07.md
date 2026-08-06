# 味方全体攻撃威力 0.7 統一

**ID:** P3-BAL-ALLY-AOE-07-001  
**日付:** 2026-08-07  
**状態:** 承認（オーナー指示）  
**Overrides:** `84_VanguardKitTune.md` の `menace_strike` 威力 1.0

## 要旨

自キャラの **敵全体ダメージスキル**の `power_multiplier` を **0.7** に統一する。  
**必殺（`slot_type=ultimate`）は除外**。敵／ボスの全体は対象外。

## 確定

| 項目 | 値 |
|---|---|
| 対象 | `skill_type`≠enemy/boss かつ `target_type=all_enemies` かつ `effect_type=damage` かつ非必殺 |
| 威力 | **0.7**（`BalanceConfig.ALLY_AOE_DAMAGE_POWER_MULT`） |
| 必殺 | データ値のまま（例: 奥義・裂断、ビーストドミニオン） |
| 実行時 | `BalanceConfig.effective_skill_power_multiplier` → `SkillExecutor` |

## データ同期（非必殺・当時）

`blade_tempest` / `blood_mist_slash` / `volley_shot` / `menace_strike` ほか既に 0.7 の全体技。

## SSOT

- `BalanceConfig.ALLY_AOE_DAMAGE_POWER_MULT`
- `resources/skills/*.tres`（表示・手引き用も 0.7）
