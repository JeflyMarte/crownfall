# CurrentState.md — Crownfall Project Dashboard

---

## Last Update

2026-06-25（**Phase3-A Closeout 完了** — EC-1〜7 PASS / EC-8 P2 defer 記録）

---

## Project Version

ProjectDocs **v3.5.46**

---

## Current Phase

**Phase3-B — Content Expansion**（次マイルストーン候補）

---

## Current Milestone

**Phase3-A — Visual Production** — **完了**（2026-06-25）

| 項目 | 状態 |
|---|---|
| Scope Adoption | **完了**（P3-D001〜007） |
| P0 / P1 PA 全 Batch | **完了**（Batch 1〜7） |
| Impl P3-A-001〜008 | **完了** |
| P3-A-009 Closeout | **完了**（EC-1〜7 PASS） |

---

## Phase3-A Exit Criteria

| EC | 条件 | 状態 |
|---|---|---|
| EC-1 | P0 アセット配置・import | ✅ |
| EC-2 | production_theme 適用 | ✅ |
| EC-3 | 王都跡完走で全敵・ボス production 表示 | ✅ import + smoke |
| EC-4 | 装備 UI production アイコン | ✅ |
| EC-5 | 未鑑定 Unidentified アイコン | ✅ |
| EC-6 | 王都跡 Tileset 適用 | ✅ |
| EC-7 | Hit / Heal VFX | ✅ import + smoke |
| EC-8 | P1 アセット（墓地・CHR 等） | ✅（P2 defer: Hit_Critical / RoyalRuins 補完タイル 3 — P3-D008） |

---

## Previous Milestone

Phase2-M9 — Codex & Discovery Foundation（完了 2026-06-23）

---

## Development Workflow（P2-D177）

| 役割 | ツール |
|---|---|
| HQ | Cursor |
| Impl | Claude Code × **2 並行**（worktree 任意） |
| Visual | Pixel Apprentice（オーナー + Pixellab） |

---

## Current Playable Features

（Phase2 Alpha + Phase3-A ビジュアル）

| 領域 | 内容 |
|---|---|
| ダンジョン | 王都跡 / 白骸墓地（2 DG・完走可能） |
| ビジュアル | production タイル・敵/ボス/CHR スプライト・VFX |
| Base | DG 選択・鍛冶屋・図鑑 |
| Special Rooms | Branch / Heal / Treasure / Merchant / Event / Elite |
| 戦闘 | 自動戦闘・Skill・Affix・Job |
| 装備 | 3 枠・鑑定・Build Summary・production アイコン |
| 経済・クラフト | 素材・Merchant・Blacksmith |
| 発見 | discovery_registry・Codex UI |

---

## Active Tasks

（Phase3-A 完了 — 次マイルストーン待ち）

| ID | 内容 | 担当 | 状態 |
|---|---|---|---|
| OD-UI-001 | モック寄せ方針 Decision | HQ | **未**（Closeout 後） |
| Phase3-B | Content Expansion 着手 | HQ | **未** |

---

## Next Recommended（HQ）

1. **HQ** — **OD-UI-001** モック寄せ方針 Decision
2. **HQ** — Phase3-B Scope / 次スプリント策定
3. 新環境セットアップ: `bash tools/smoke_test.sh --import-only`（P3-D010）

---

## Known Issues

| 課題 | 詳細 |
|---|---|
| モック vs 現 UI | 部屋ステップ UI は MVP 確定。モック再現は Closeout 後 Decision |
| Combat Vision vs 実装 | リアルタイム戦闘・位置 AI 未実装（`26_CombatVision.md`） |
| 状態異常・属性 | SSOT 済。Phase3-B-M1 で実装 |

---

## Design References

| 文書 | 用途 |
|---|---|
| [UI_Reference_Notes.md](../art/reference/UI_Reference_Notes.md) | モック 001 + 002（公式ペア） |
| [Phase3A_Scope_Adoption_Completed_v1.1.md](../archives/ArtArchive/Completed/Phase3A_Scope_Adoption_Completed_v1.1.md) | Phase3-A Scope 正 |
| [06_DevelopmentHQ_Operations.md](../specs/core/06_DevelopmentHQ_Operations.md) | HQ / Impl 運用 |
| [26_CombatVision.md](../specs/game/26_CombatVision.md) | 戦闘ビジョン |
| [SessionHandoff.md](./SessionHandoff.md) | 新 Cursor チャット入口 |
