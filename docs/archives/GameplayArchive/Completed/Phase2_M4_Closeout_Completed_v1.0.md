# Phase2_M4_Closeout_Completed_v1.0

**Status:** Completed
**Milestone:** Phase2-M4 — World Expansion Foundation
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.5.5
**Closeout Date:** 2026-06-21

---

## Scope（M4 正式スコープ）

Phase2-M4 = **世界拡張基盤**。新戦闘システム・Affix・Job 本実装は含まない。

| In Scope | Out of Scope（M5+） |
|---|---|
| Multi-Dungeon 基盤 | SkillExecutor |
| Base DG 選択 | Job 本実装 |
| 白骸墓地 + 敵セット | Affix |
| MaterialData 基盤 | クラフト / Codex |
| 2 DG playable | 3 ダンジョン目 |

---

## Completed Tasks

| Task | 内容 | ProjectDocs |
|---|---|---|
| P2-Task021 | Multi-Dungeon Foundation | v3.5.0 |
| P2-Task022 | Base Dungeon Select | v3.5.1 |
| P2-Task023 | Graveyard Dungeon + Enemy | v3.5.2 |
| P2-Task024 | MaterialData Foundation | v3.5.3 |

**Design reference（非 SSOT）:** Crownfall Product Vision Completed v1.0（v3.5.4）

---

## Decisions

P2-D045〜P2-D056（Task 別）  
**Milestone:** P2-D057〜P2-D060

| # | 決定 |
|---|---|
| P2-D057 | Phase2-M4 完了 |
| P2-D058 | Multi-Dungeon 基盤確立 |
| P2-D059 | MaterialData 基盤確立 |
| P2-D060 | Combat Depth は M5 で開始 |

---

## M4 成果物サマリー

| 領域 | 状態 |
|---|---|
| ダンジョン | royal_ruins + graveyard |
| 敵 | 王都跡 5 + 白骸墓地 6 |
| Base | DG 選択 UI |
| 素材 | MaterialData 4 + material_inventory |
| DataRegistry | 7 カテゴリ（+materials） |

---

## Remaining Deferred Items

| 項目 | 想定 |
|---|---|
| SkillExecutor | M5 P2-Task025 |
| 素材 UI / クラフト | M5+ |
| ancient_bone / cursed_iron ドロップ | 将来 DG/Event |
| EVENTS/MERCHANT DG 分離 | 将来 |
| Codex UI | Beta |
| 地下工廠 | Phase3 候補 |

---

## M5 Entry Conditions

- [x] 2 プレイアブル DG
- [x] SkillData SSOT（M3 Task019）
- [x] DataRegistry SSOT（M3 Task020）
- [x] Material placeholder 解消
- [ ] SkillExecutor 未実装 → **M5 開始条件を満たす**

---

## Next Milestone

**Phase2-M5 — Combat Depth Foundation**

推奨 Task: **P2-Task025 SkillExecutor**

---

## 参照

- docs/project/CurrentState.md
- docs/specs/core/02_Roadmap.md — Phase2-M5 節
