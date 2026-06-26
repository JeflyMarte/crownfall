# P2_Task034_Job_Modifier_Combat_Integration_Completed_v1.0

**Status:** Completed
**Task:** P2-Task034
**Milestone:** Phase2-M7 — Job & Build Foundation
**Version:** v1.0
**ProjectDocs:** v3.5.21
**Completed Date:** 2026-06-21

---

## 概要

`JobStatCalculator` を戦闘 HP / Attack / Defense に per-member 接続。P2-D115 合成順序を実装。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| CombatController HP | Job UI |
| DungeonScene ATK/DEF | Build Summary |
| P2-D115 合成順序 | starting_skill_ids |
| per-member modifier | SkillExecutor 改修 |
| fallback 1.0 | Save Format |

---

## Combat Calculation Flow

```
HP (CombatController._init_party_hp)
  base_stats / BASE_MEMBER_HP
  → + Affix hp_flat
  → × Job hp_multiplier

Attack (DungeonScene._calc_attack_base(index))
  weapon + accessory + Affix attack_flat
  → × Job attack_multiplier
  → crit / run mult (_calc_damage)

Defense (DungeonScene._calc_enemy_damage_to_member(index))
  armor + accessory + Affix defense_flat
  → × Job defense_multiplier (被弾メンバー)
  → enemy_attack - defense
```

---

## Job Modifier Verification

| job_id | hp_mult | atk_mult | def_mult | 効果 |
|---|---|---|---|---|
| warrior | 1.0 | 1.1 | 1.0 | 与ダメ↑ |
| guardian | 1.2 | 0.9 | 1.2 | max HP↑ / 被ダメ↓ / 与ダメ↓ |
| scout | 0.95 | 1.0 | 0.9 | max HP↓ / 被ダメ↑ |

同一装備でも 3 人で HP / 与ダメ / 被ダメに差が出る。

---

## Fallback

JobData 欠落 / 空 job_id → multiplier 1.0（Task033 同型）

---

## Decision

P2-D126〜P2-D128

---

## Files

- `scripts/combat/CombatController.gd`
- `scripts/dungeon/DungeonScene.gd`

---

## Deferred

- starting_skill_ids（Task035）
- Build Summary（Task037）
