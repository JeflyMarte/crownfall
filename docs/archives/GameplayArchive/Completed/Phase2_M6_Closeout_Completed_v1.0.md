# Phase2_M6_Closeout_Completed_v1.0

**Status:** Completed
**Milestone:** Phase2-M6 — Equipment Depth Foundation
**Approved By:** —（Closeout 実施・DevelopmentHQ レビュー待ち）
**Version:** v1.0
**ProjectDocs:** v3.5.17
**Closeout Date:** 2026-06-21

---

## Scope（M6 正式スコープ）

Phase2-M6 = **装備深度基盤**。Affix ループの data → gameplay → UI までを段階統合。

| In Scope | Out of Scope |
|---|---|
| AffixData + 7 サンプル | Affix reroll |
| AffixRoller MVP slot rules | Legendary 特殊 / Curse |
| 鑑定連携 + Instance 保存 | Craft / Blacksmith |
| AffixStatCalculator | Material usage |
| Equipment Affix 表示 | Compare popup / sort / filter |
| | Job combat / Codex / 新 DG |

---

## Completed Tasks

| Task | 内容 | ProjectDocs |
|---|---|---|
| P2-Task028 | AffixData Foundation | v3.5.12 |
| P2-Task029 | Affix Roll System | v3.5.13 |
| P2-Task030 | Affix Appraisal Integration | v3.5.14 |
| P2-Task031 | Affix Stat Application | v3.5.15 |
| P2-Task032 | Equipment Detail UI | v3.5.16 |

---

## Decisions

P2-D085〜P2-D104（Task 別）  
**Milestone Closeout:** P2-D105〜P2-D109

| # | 決定 |
|---|---|
| P2-D105 | Phase2-M6 完了 |
| P2-D106 | Affix ループ確立 |
| P2-D107 | Affix gameplay 効果確立 |
| P2-D108 | 高度 Affix システム Defer |
| P2-D109 | 次候補: Phase2-M7 UI / UX Foundation |

---

## M6 成果物サマリー

| 領域 | 状態 |
|---|---|
| AffixData | 7 サンプル + DataRegistry |
| AffixRoller | weapon P+S / armor P / accessory P |
| 鑑定 | Roll on appraise + prefix_ids/suffix_ids + Save |
| 戦闘 | AffixStatCalculator（7 stat_type） |
| UI | AffixDisplayFormatter + EquipmentScene |
| Core Loop | Weapon Discovery → Appraisal → Affix → Reveal → Stat → Compare UI |

---

## Remaining Deferred Items

| 項目 | 想定 |
|---|---|
| Affix reroll / Legendary / Curse | M6+ / Beta |
| Material Usage / Craft / Blacksmith | M6+ |
| Compare popup / sort / filter / rarity color | M7 候補 |
| Job 戦闘 / UI | M6+ |
| 敵スキル / ボス mechanics | M6+ |
| Codex UI | Beta |
| 3 ダンジョン目 | Phase3 候補 |

---

## Next Milestone Candidate

**Phase2-M7 — UI / UX Foundation**

候補優先度:

1. Base UI readability
2. Dungeon selection presentation
3. Result / Appraisal flow improvement
4. Equipment comparison readability
5. Mobile layout polish

---

## M7 Entry Conditions

- [x] Affix ループ gameplay + UI 接続済み
- [x] 2 ダンジョン完走可能
- [x] SkillExecutor + 武器スキル接続済み
- [ ] M7 スコープ DevelopmentHQ 確定待ち

---

## 参照

- docs/project/CurrentState.md
- docs/specs/core/02_Roadmap.md — Phase2-M7 候補節
- docs/specs/core/04_Development_Master_Plan.md
