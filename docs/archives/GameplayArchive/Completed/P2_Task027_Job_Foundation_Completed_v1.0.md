# P2_Task027_Job_Foundation_Completed_v1.0

**Status:** Completed
**Task:** P2-Task027
**Milestone:** Phase2-M5 — Combat Depth Foundation
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.5.8
**Completed Date:** 2026-06-21

---

## 概要

将来の job build 向け JobData データ層を確立。DataRegistry lookup のみ。戦闘・UI 未接続。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| JobData Resource | Job 選択 UI |
| 3 サンプル job.tres | Job レベル |
| get_job_data | 戦闘スキル接続 |
| Constants パス | パーティ class 変更 |

---

## JobData スキーマ

id, display_name, description, role, base_hp_modifier, base_attack_modifier, base_defense_modifier, preferred_weapon_types, starting_skill_ids, passive_tag_ids

---

## サンプルジョブ

| id | display_name | role | 特徴 |
|---|---|---|---|
| warrior | 戦士 | dps | atk 1.1, starting slash_attack |
| guardian | 守護者 | tank | hp/def 1.2 |
| scout | 斥候 | scout | 機動型, dual_blades/bow |

---

## DataRegistry

```gdscript
func get_job_data(job_id: String) -> Resource:
    return load(Constants.RESOURCE_JOBS_PATH + job_id + ".tres")
```

---

## Decision

P2-D069〜P2-D072

---

## Deferred

- Adventurer.job_id → JobData 自動解決
- starting_skill_ids 戦闘接続
- Job UI / レベル / パッシブ実装

---

## 参照

- `scripts/data/JobData.gd`
- `resources/jobs/`
- `docs/specs/implementation/03_Resource設計.md` — JobData 節
