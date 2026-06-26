# Phase2_M5_Closeout_Completed_v1.0

**Status:** Completed
**Milestone:** Phase2-M5 — Combat Depth Foundation
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.5.9
**Closeout Date:** 2026-06-21

---

## Scope（M5 正式スコープ）

Phase2-M5 = **戦闘深度基盤**。Affix / Job 本実装 / 敵スキルは含まない。

| In Scope | Out of Scope（M6+） |
|---|---|
| SkillExecutor | Job 戦闘接続 |
| Weapon fixed_skill_id スキル | Job UI |
| JobData + DataRegistry | Affix 本実装 |
| slash_attack 戦闘接続 | 敵スキル / Codex |

---

## Completed Tasks

| Task | 内容 | ProjectDocs |
|---|---|---|
| P2-Task025 | SkillExecutor | v3.5.6 |
| P2-Task026 | Weapon Skill Link | v3.5.7 |
| P2-Task027 | Job Foundation | v3.5.8 |

---

## Decisions

P2-D061〜P2-D072（Task 別）  
**Milestone:** P2-D073〜P2-D076

| # | 決定 |
|---|---|
| P2-D073 | Phase2-M5 完了 |
| P2-D074 | SkillExecutor + 武器スキル接続確立 |
| P2-D075 | JobData 基盤（lookup のみ） |
| P2-D076 | 次候補: M6 Equipment Depth Foundation |

---

## M5 成果物サマリー

| 領域 | 状態 |
|---|---|
| 戦闘スキル | SkillExecutor + cooldown |
| 武器連動 | fixed_skill_id → SkillData |
| フォールバック | DEFAULT_PLAYER_SKILL_ID (slash_attack) |
| ジョブ | JobData 3 体（lookup のみ） |
| DataRegistry | +get_job_data |

---

## Remaining Deferred Items

| 項目 | 想定 |
|---|---|
| Job 戦闘 / UI | M6+ |
| 追加 SkillData | M6+ |
| 敵スキル / ボススキル | M6+ |
| Affix | M6 候補 |
| Codex UI | Beta |
| クラフト / 鍛冶 | 将来 |

---

## Next Milestone Candidate

**Phase2-M6 — Equipment Depth Foundation**

候補優先度:

1. AffixData Foundation
2. Affix Roll / Appraisal Integration
3. Equipment Detail UI improvement
4. Material Usage Planning

---

## M6 Entry Conditions

- [x] SkillExecutor SSOT
- [x] Weapon fixed_skill_id 接続
- [x] JobData lookup 基盤
- [ ] AffixData 未実装 → **M6 開始条件を満たす**

---

## 参照

- docs/project/CurrentState.md
- docs/specs/core/02_Roadmap.md — Phase2-M6 節
