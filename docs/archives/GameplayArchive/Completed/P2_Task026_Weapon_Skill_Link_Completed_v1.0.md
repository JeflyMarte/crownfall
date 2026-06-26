# P2_Task026_Weapon_Skill_Link_Completed_v1.0

**Status:** Completed
**Task:** P2-Task026
**Milestone:** Phase2-M5 — Combat Depth Foundation
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.5.7
**Completed Date:** 2026-06-21

---

## 概要

装備武器の `WeaponData.fixed_skill_id` を SkillExecutor に接続。スキルが武器駆動になり、Crownfall の武器主役 progression を強化。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| WeaponData.fixed_skill_id | Skill UI |
| 戦闘スキル解決フロー | Job System |
| slash_attack フォールバック | 敵スキル / Affix |
| 戦闘ログ改善 | 新武器生成 / UI 再設計 |

---

## Weapon → SkillData フロー

```
GameState.equipped_weapon.weapon_id
  → DataRegistry.get_weapon_data(id)
  → fixed_skill_id
  → DataRegistry.get_skill_data(id)
  → SkillExecutor.execute_damage_skill()
```

---

## 武器設定

| weapon_id | fixed_skill_id | 挙動 |
|---|---|---|
| iron_sword | slash_attack | 武器固有スキル |
| rusted_blade | （空） | DEFAULT_PLAYER_SKILL_ID フォールバック |
| 未装備 | — | slash_attack フォールバック |

---

## 戦闘ログ例

```
攻撃: 30ダメージ
【スキル】鉄の剣 / 斬撃: 45ダメージ
```

フォールバック時:
```
【スキル】斬撃: 45ダメージ
```

---

## Decision

P2-D065〜P2-D068

---

## Deferred

- 追加 SkillData / 武器スキルバリエーション
- Job スキル
- 敵スキル
- Skill UI

---

## 参照

- `scripts/data/WeaponData.gd`
- `scripts/dungeon/DungeonScene.gd` — `_get_player_skill_data()`
- `docs/specs/game/08_戦闘_AI.md`
