# P2_Task031_Affix_Stat_Application_Completed_v1.0

**Status:** Completed
**Task:** P2-Task031
**Milestone:** Phase2-M6 — Equipment Depth Foundation
**Approved By:** —（実装完了・DevelopmentHQ レビュー待ち）
**Version:** v1.0
**ProjectDocs:** v3.5.15
**Completed Date:** 2026-06-21

---

## 概要

鑑定済み装備の Affix を `AffixStatCalculator` で集計し、戦闘ダメージ・防御・HP・報酬に最小反映。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| AffixStatCalculator.gd | Equipment Detail UI |
| Attack / Defense / HP / Critical | Attack Speed |
| Gold Gain / Material Gain / Healing | Skill Power / Cooldown |
| 未対応 stat_type 安全無視 | Affix reroll |

---

## Supported stat_type

| stat_type | 効果 | 接続 |
|---|---|---|
| Attack | flat 加算 | `_calc_attack_base` |
| Defense | defense 加算 | `_calc_enemy_damage_to_member` |
| HP | max HP 加算 | `_init_party_hp` |
| Critical | crit_rate 加算 | `_calc_attack_base` |
| Gold Gain | 倍率 1.0+Σvalue | `accumulate_rewards` |
| Material Gain | 取得量 flat | Event / Elite material |
| Healing | 回復量 flat | HEAL / Event / Merchant |

---

## Ignored stat_type（サンプル）

| stat_type | 例 |
|---|---|
| Attack Speed | swift |

---

## Before / After Example

**武器: sharp (+3 Attack) + of_might (+2 Attack)**

- Before: base_damage = 12
- After: base_damage = 17

**装飾品: fortune (+0.1 Gold Gain)**

- Before: 敵 Gold 10 → run +10
- After: 敵 Gold 10 → run +11

---

## Decision

P2-D097〜P2-D100

---

## Deferred

- Attack Speed / Skill Power / Cooldown
- Equipment Detail UI
- Crit damage affix

---

## Files

- `scripts/equipment/AffixStatCalculator.gd`
- `scripts/dungeon/DungeonScene.gd`
- `scripts/dungeon/DungeonController.gd`
- `scripts/combat/CombatController.gd`
