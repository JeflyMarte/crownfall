# P2_Task033_Party_Job_Alignment_Completed_v1.0

**Status:** Completed
**Task:** P2-Task033
**Milestone:** Phase2-M7 — Job & Build Foundation
**Approved By:** —（実装完了・DevelopmentHQ レビュー待ち）
**Version:** v1.0
**ProjectDocs:** v3.5.20
**Completed Date:** 2026-06-21

---

## 概要

パーティ job_id を JobData SSOT に整合。`JobStatCalculator` で modifier Dictionary を安全取得。戦闘未接続。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| GameState party job_id | 戦闘 HP/ATK/DEF 反映 |
| JobStatCalculator.gd | starting_skill_ids |
| 安全 fallback | Job UI / Build Summary |

---

## Party job_id Result

| adventurer_id | display_name | job_id |
|---|---|---|
| adventurer_0 | 戦士 | warrior |
| adventurer_1 | 守護者 | guardian |
| adventurer_2 | 斥候 | scout |

---

## JobStatCalculator

```gdscript
JobStatCalculator.get_member_modifiers(adventurer) -> Dictionary
```

| job_id | hp_mult | atk_mult | def_mult |
|---|---|---|---|
| warrior | 1.0 | 1.1 | 1.0 |
| guardian | 1.2 | 0.9 | 1.2 |
| scout | 0.95 | 1.0 | 0.9 |

---

## Fallback

| 条件 | 結果 |
|---|---|
| adventurer == null | multiplier 1.0, 空 metadata |
| job_id == "" | 同上 |
| JobData 欠落 | multiplier 1.0, display_name = job_id |
| modifier ≤ 0 | 1.0 |

---

## Decision

P2-D123〜P2-D125

---

## Deferred

- Combat integration（Task034）
- Job UI（Task036）

---

## Files

- `scripts/equipment/JobStatCalculator.gd`
- `scripts/autoload/GameState.gd`
