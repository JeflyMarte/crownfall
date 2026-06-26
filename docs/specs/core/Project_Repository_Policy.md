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

以下は当面 **`docs/specs/game/`** を正式配置先とする。

- `16_HistoryBible.md`
- `17_WorldBible.md`
- `18_LoreDeliveryGuide.md`

`docs/archives/WorldArchive/` への移動は **Lore システム完成後**に再検討。

関連 Decision: **P2-D083**

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
- `AGENTS.md` / `CLAUDE.md` / `README.md`
- 実装コード（`scripts/`, `resources/`, `scenes/` 等）— Cleanup Task 対象外

---

## 7. 参照

- `docs/archives/GameplayArchive/Completed/Repository_Cleanup_Policy_Completed_v1.0.md`
- `docs/archives/README.md`
- `docs/specs/core/03_Decision_Log.md`
