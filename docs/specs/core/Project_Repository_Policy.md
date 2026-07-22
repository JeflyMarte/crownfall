# Project Repository Policy

**Status:** SSOT（DevelopmentHQ 承認済）  
**Version:** v1.0  
**ProjectDocs:** v3.5.11  
**Approved:** 2026-06-21  
**Decisions:** P2-D081〜P2-D084

---

## 1. SSOT の所在

| 種別 | 正規の場所 |
|---|---|
| ゲーム・実装仕様 | `docs/specs/` |
| プロジェクト状態 | `docs/project/`（CurrentState / CurrentSprint） |
| 変更履歴 | `CHANGELOG.md`（ProjectDocs 版） |
| 設計履歴・Bible | `docs/archives/` |

**ProjectDocs ZIP は SSOT ではない。** 正式 SSOT は常に `docs/` ツリー。

---

## 2. ProjectDocs ZIP（Release Artifact）

- ZIP は **Release Artifact** として生成する
- **Git リポジトリには含めない**（最新版・旧版問わず保持しない）
- 保管先: NAS / Drive / Release 配布チャネル等、リポジトリ外

関連 Decision: **P2-D081**

---

## 3. Archives 運用

### Proposal と Completed

| 種別 | 役割 |
|---|---|
| `Proposal/` | 設計提案・レビュー前原文 |
| `Completed/` | DevelopmentHQ 承認済み正式成果物 |

- **Completed 作成後も Proposal は削除しない**
- 履歴: Proposal → Completed → Decision Log

関連 Decision: **P2-D082**

### Proposal 欠落

Completed が Supersedes する Proposal が欠落している場合、**可能な限り Proposal を復元**して履歴を維持する。

例: `Affix_Bible_v1.0` Proposal（要復元候補）

---

## 4. Lore 文書の配置

世界観・ロアの正式配置先は **`docs/specs/world/`** とする（戦後生態系 SSOT, 12 文書: `00_Overview`〜`11_Glossary`）。

- 数値・システム仕様はゲーム仕様側（`docs/specs/game/`）に置く（例: ジョブ数値 = `06_キャラクター_ジョブ.md` / 図鑑システム = `33_EcologyCodex.md`）。
- 旧 World/Lore Bible（`game/16`〜`25`）および旧刷新版（`game/29`〜`37`）は `world/` へ統合・削除済（git 履歴に保持）。

関連 Decision: **P2-D083**（旧）/ 世界観刷新・cutover（`03_Decision_Log.md` P3-D040 / P3-D041 / P3-D041b）

---

## 5. Git Commit 方針

- **Milestone 単位**で整理する
- 大量の一括 Commit を避ける

推奨分割単位:

| 単位 | 例 |
|---|---|
| Milestone | Phase2-M5 Closeout |
| Gameplay | P2-Task025 実装 |
| ProjectDocs | specs / Decision Log 更新 |
| Cleanup | .DS_Store 削除等（方針承認後） |

関連 Decision: **P2-D084**

### 5.1 Impl 承認後のブランチ（要約）

正式手順: `06_DevelopmentHQ_Operations.md` §7.1

- **Impl GO** → 統合ブランチへマージし、**同じタイミングで `main` へ上げる**（＋ push）
- Decision のみ・未検証 WIP は `main` に上げない
- 後修正は本線先端のみ（統合と `main` の二重メンテ禁止）

---

## 6. Repository Cleanup

### 削除許可（方針承認済）

| 対象 | 条件 |
|---|---|
| `.DS_Store` | リポジトリ内の全箇所 |
| `.gitkeep` | **中身が存在するディレクトリ内**のもののみ |

### 削除禁止

- `docs/specs/**`
- `docs/project/**`
- `docs/archives/**`（Proposal / Completed / Bible 含む）
- `CHANGELOG.md`
- `AGENTS.md` / `README.md`
- 実装コード（`scripts/`, `resources/`, `scenes/` 等）— Cleanup Task 対象外

---

## 7. 参照

- `docs/archives/GameplayArchive/Completed/Repository_Cleanup_Policy_Completed_v1.0.md`
- `docs/archives/README.md`
- `docs/specs/core/03_Decision_Log.md`
