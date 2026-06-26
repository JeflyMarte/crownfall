# Phase2_M9_Closeout_Completed_v1.0

**Status:** Completed  
**Task:** P2-Task050  
**Milestone:** Phase2-M9 — Codex & Discovery Foundation  
**Version:** v1.0  
**ProjectDocs:** v3.5.44  
**Completed Date:** 2026-06-23

---

## Milestone Summary

Phase2-M9「Codex & Discovery Foundation」を正式完了。

`discovery_registry` を Base から閲覧できる Codex UI へ接続。5 カテゴリ Tab・Entry List・Detail・History/Dungeon Bible 連携を実装済み。

---

## Completed Tasks

| Task | 内容 | 完了日 |
|---|---|---|
| P2-Task045 | Codex Scope Adoption | 2026-06-22 |
| P2-Task046 | Codex Data Foundation | 2026-06-22 |
| P2-Task047 | Codex UI Foundation | 2026-06-22 |
| P2-Task048 | Discovery Detail View | 2026-06-22 |
| P2-Task049 | History / Dungeon Bible Link | 2026-06-22 |
| P2-Task050 | Phase2-M9 Closeout | 2026-06-23 |

---

## Decisions（P2-D148〜153, P2-D176）

| # | 決定事項 |
|---|---|
| P2-D148 | M9 Scope 正式採用 |
| P2-D149 | Codex MVP 5 カテゴリ |
| P2-D150 | discovery_registry Save 形式不変 |
| P2-D151 | Codex 閲覧専用（報酬なし） |
| P2-D152 | History Bible サブセット表示 |
| P2-D153 | Task045〜050 計画 |
| P2-D176 | **Phase2-M9 完了宣言** |

---

## Exit Criteria

| # | 項目 | 状態 | 備考 |
|---|---|---|---|
| EC-1 | Base → CodexScene 遷移 | ✓ | `BaseScene.gd` |
| EC-2 | 5 カテゴリ Tab + List + Detail | ✓ | `CodexScene` |
| EC-3 | 発見済み名称・詳細表示 | ✓ | |
| EC-4 | 未発見 `???`・クラッシュなし | ✓ | |
| EC-5 | Enemy / Material は既存 discovery で Discovered | ✓ | `DungeonScene` フック |
| EC-6 | Dungeon / Weapon 新規 register フック | **Defer** | Phase3-B 候補（Known Issue） |
| EC-7 | History / Dungeon Bible Detail | ✓ | Task049 |
| EC-8 | Save → Load 後 Codex 一致 | ✓ | `SaveManager` |
| EC-9 | 2 DG 完走（戦闘回帰なし） | ✓ | 手動 QA 前提 |
| EC-10 | Achievement / 報酬 gameplay なし | ✓ | |

---

## Deferred Items（M9 外 → 移管）

| 項目 | 移管先 |
|---|---|
| dungeon / weapon discovery 登録フック | Phase3-B（Codex 体験強化） |
| Codex Search / Filter | Phase4 Polish |
| Achievement / Collection Rewards | Backlog |
| Map UI | Backlog |
| room / event Codex Tab | 将来 |

---

## 主要ファイル

| ファイル | 役割 |
|---|---|
| `scripts/codex/CatalogHelper.gd` | Entry 取得・Bible parse・Discovery 判定 |
| `scripts/codex/CodexScene.gd` | UI |
| `scenes/codex/CodexScene.tscn` | Scene |
| `scripts/base/BaseScene.gd` | 図鑑遷移 |

---

## Next Milestone

**Phase3-A — Visual Production**（P2-D156）

- gameplay 仕様変更なし
- mvp_theme → production 方向

**並行候補（Phase3-B）:** discovery フック、Phase3-B-M1 状態異常（別 Decision 済み・実装待ち）
