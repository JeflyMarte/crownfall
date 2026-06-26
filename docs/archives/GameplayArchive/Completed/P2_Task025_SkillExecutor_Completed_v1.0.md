# P2_Task025_SkillExecutor_Completed_v1.0

**Status:** Completed
**Task:** P2-Task025
**Milestone:** Phase2-M5 — Combat Depth Foundation
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.5.6
**Completed Date:** 2026-06-21

---

## 概要

最小 SkillExecutor を実装し、`slash_attack` を自動戦闘に接続。SkillData が実際のダメージに影響する M5 第一 Task。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| SkillExecutor.gd | Skill UI |
| slash_attack 戦闘接続 | Job System |
| cooldown tick | 敵スキル / ボススキル |
| 戦闘ログ | Affix / Codex |
| damage effect_type | heal / buff 実行 |

---

## SkillExecutor API

| メソッド | 役割 |
|---|---|
| `reset()` | 戦闘開始時 cooldown クリア |
| `tick(delta)` | cooldown 減算 |
| `can_cast(skill_data)` | cooldown 就绪判定 |
| `calculate_damage(...)` | base × power_multiplier × crit × run_mult |
| `execute_damage_skill(...)` | 実行 + cooldown 開始 |

---

## slash_attack 接続

| 項目 | 値 |
|---|---|
| id | slash_attack |
| power_multiplier | 1.5 |
| cooldown | 3.0s |
| effect_type | damage |
| 発動 | 通常攻撃後、cooldown 就绪時に追加ダメージ |

---

## 戦闘ログ例

```
攻撃: 30ダメージ
【スキル】斬撃: 45ダメージ
```

（base 10・装備なし・run_mult 1.0 時: 通常 10×3=30 / スキル 10×1.5×3=45）

---

## Decision

P2-D061〜P2-D064

---

## Deferred

- 武器 fixed_skill_id 接続
- heal / buff effect_type
- 敵スキル
- Skill UI
- Job スキル

---

## 参照

- `scripts/combat/SkillExecutor.gd`
- `scripts/dungeon/DungeonScene.gd`
- `docs/specs/game/08_戦闘_AI.md` — SkillExecutor 節
