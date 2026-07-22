# DevelopmentHQ Operations — v1.4

**Status:** SSOT（DevelopmentHQ 承認済）  
**Version:** v1.4  
**Approved:** 2026-06-23（§7.1 追記: 2026-07-17／Cursor 一本化: 2026-07-22）  
**Decisions:** P2-D154〜P2-D156, **P2-D169**（設計フロー v1.1）, **P3-OPS-CURSOR-001**  
**Audience:** プロジェクトオーナー / DevelopmentHQ / Implementation Agent

---

## 1. 概要

Crownfall の **DevelopmentHQ（設計・進行の司令塔）** と **Impl（実装）** は、いずれも **Cursor** 上で運用する。

| 役割 | 担当 |
|---|---|
| DevelopmentHQ | **Cursor HQ セッション** |
| 実装 | **Cursor Impl セッション** |
| 情報の正 | **リポジトリ更新**（Decision / spec / ダッシュボード） |

口頭・チャットでの協議は SSOT にならない。**Proposal → Decision → Spec** のパイプラインを通す。

---

## 2. 役割分担

```
プロジェクトオーナー
  │ 方針承認・プレイテスト・最終 GO
  ▼
DevelopmentHQ（Cursor — HQ セッション）
  │ 設計パイプライン統括 / Scope / Decision / Task / レビュー
  ▼
Implementation Agent（Cursor — Impl セッション）
  │ 指定 Task のみ実装
  ▼
リポジトリ（SSOT）
```

---

## 3. 設計文書の種類（レイヤー）

新規アイデアは、**いきなり spec に書かない**。レイヤーを守る。

| レイヤー | 格納先 | 役割 | 変更頻度 |
|---|---|---|---|
| **Vision** | `26_CombatVision.md` 等 | 体験の不変原則 | 極めて低い（Decision 必須） |
| **World / Lore（戦後生態系）** | `docs/specs/world/`（`00`〜`11`） | 世界観・歴史・生態の正 | Decision 後 |
| **System Spec** | `07_`〜`09_`, `08_` 等 | ゲームルール・数値・スキーマ | Task 単位で更新 |
| **Proposal** | `docs/archives/.../Proposal/` | 未承認の設計案 | レビュー中 |
| **Implementation** | `CODEMAP.md`, コード | 実装の正 | Impl Task で更新 |
| **Backlog** | `05_Backlog.md` | 名前と優先度のみ | Decision / Closeout 後 |

**口頭・チャットでの協議は SSOT にならない。** 必ず Proposal または spec 更新パイプラインを通す。

---

## 4. 設計パイプライン（標準フロー）

```mermaid
flowchart TD
  A[Spark: アイデア / 協議 / プレイ感想] --> B{Vision整合?}
  B -->|No| A2[却下 or 修正]
  B -->|Yes| C[Proposal 起票 archives/Proposal]
  C --> D[HQ レビュー: ワクワク / 命名 / SSOT矛盾 / 工数]
  D --> E{オーナー承認}
  E -->|No| C
  E -->|Yes| F[Decision Log 記録]
  F --> G[Spec 更新 docs/specs/]
  G --> H{Milestone影響?}
  H -->|Yes| I[Scope Adoption / Backlog / Roadmap]
  H -->|No| J[Task チケット発行]
  I --> J
  J --> K[Impl セッション]
  K --> L[HQ レビュー diff]
  L --> M[CurrentState / Task Index 更新]
```

### 各ステップの責務

| Step | 担当 | 成果物 |
|---|---|---|
| **Spark** | オーナー / GD | メモ（SSOT 化前） |
| **Vision 整合** | HQ | Combat Vision / World Bible 原則との照合メモ |
| **Proposal** | HQ | IN/OUT scope、リスク、Task 順案、命名 |
| **HQ レビュー** | HQ | レビュー文書（例: `*_Review_v1.0.md`） |
| **オーナー承認** | オーナー | GO / 修正指示 |
| **Decision** | HQ | `03_Decision_Log.md` |
| **Spec** | HQ | `docs/specs/game/` or `implementation/` |
| **Task** | HQ | Impl チケット（Bundle 付き） |
| **Impl** | Impl | コード + 報告 |
| **HQ レビュー** | HQ | diff 確認・承認 |
| **Closeout** | HQ | Milestone 時: Completed 文書 |

### ショートカット（許可される場合）

| 条件 | 省略可 |
|---|---|
| 1 ファイル・10 行未満の typo / 参照リンク修正 | Proposal |
| 既承認 Decision の文言同期のみ | オーナー再承認 |
| Vision / Spec に既にある内容の実装のみ | 新規 Proposal（Task のみ） |

**新システム（状態異常・属性・戦闘 AI 等）はショートカット不可。**

---

## 5. 戦闘・ビルド系の設計フロー（専用）

戦闘拡張は **Combat Vision（P2-D166）** を必ず最初に読む。

```text
Combat Vision 整合チェック
  ↓
Proposal（戦闘サブシステム単位: 例「状態異常 Tier1」）
  ↓
依存確認: Affix / Skill / Enemy / UI / VFX(Phase3-A)
  ↓
段階採用（Data → Resolver → Combat → UI → Content）
  ↓
Task 分割（1 Task = 1 接続層、≤10 files）
```

**段階統合原則（Incremental Integration）:**

1. **Data** — Resource / enum 定義のみ  
2. **Resolver** — 付与・tick・解除ロジック（CombatController 等）  
3. **Combat 接続** — ダメージ・行動阻害への反映  
4. **UI** — アイコン・ログ・「見て分かる」表現  
5. **Content** — 敵・Affix・スキルへの投入  

一度に Tier 全部を実装しない。

---

## 6. セッション種別

| 種別 | 目的 | 入口 |
|---|---|---|
| **HQ / Design** | Proposal・レビュー・Decision・Scope | 本書 §4、`CurrentState.md` |
| **HQ / Review** | Impl 成果物の diff レビュー | Task 報告 + git diff |
| **Implementation** | 指定 Task の実装 | Task Bundle |
| **Content** | `.tres` 量産 | 承認済み spec |
| **Visual**（Phase3-A） | アセット（**gameplay 変更なし**） | Art Direction |

---

## 7. Task 実装フロー（既存）

1. HQ が Task チケット発行  
2. Impl セッションで実装  
3. HQ がリポジトリでレビュー（§8 チェックリスト）  
4. 合格（オーナー GO）→ **§7.1 のとおりブランチへ反映** → ダッシュボード更新  

### 7.1 ブランチ統合方針（承認後・必須）

**目的:** 「承認したのにプレイビルドに無い」ズレを防ぐ。プレイ用の正は **統合ブランチ ≈ `main`**。

| 承認の種類 | HQ がやること |
|---|---|
| **Decision のみ**（仕様確定・未実装） | マージなし。Decision Log / spec のみ更新 |
| **Impl 完了の承認（GO）** | **必ず** 現行統合ブランチへマージ（＋ push）。**同じタイミングで `main` にも上げる** |
| **未検証／壊れている WIP** | 統合ブランチに仮置き可。**`main` には上げない**（実機 or テスト GO 後に § 上段へ） |

**現行統合ブランチ名:** `cursor/sub-mac-ui-integration-cca2`  
（名称変更時は本節と Cursor ルールを同時更新）

**後修正:**

- 常に **本線先端**（統合＝`main` が揃っている状態）にコミットする  
- 統合だけ先行・`main` 放置を避ける（後マージの衝突が増える）  
- 修正を統合と `main` に別々に入れない（二重メンテ禁止）

**Closeout 確認（Impl 承認時に HQ が見る）:**

1. 実装コミットが統合ブランチに含まれる  
2. 統合ブランチが `main` にマージ済み（または fast-forward 済み）  
3. `origin` へ push 済み  
4. オーナーがプレイする場合は **統合／`main` 先端** を開いていること

---

## 8. HQ レビューチェックリスト

| # | 確認 |
|---|---|
| 1 | Task スコープ・変更ファイル数 ≤ 10 |
| 2 | Decision 先行（新ルールの場合） |
| 3 | Combat Vision 不変原則を侵害していないか |
| 4 | spec / CODEMAP 整合 |
| 5 | Exit Criteria 充足 |
| 6 | 「見るだけで分かる」戦闘表現（該当時） |

---

## 9. ドキュメント更新責任

| タイミング | 更新者 | 対象 |
|---|---|---|
| Proposal 起票 | HQ | `archives/.../Proposal/` |
| 設計承認 | HQ | Decision Log + spec |
| Task 完了 | HQ | CurrentState, Task Index |
| Milestone 終了 | HQ | Closeout, Backlog 整理 |

---

## 10. Phase 順序（P2-D156 / P2-D178）

```
Phase3-A Visual Production  ← 現在（gameplay 変更なし）
  ↓
Phase3-B Content + Combat Depth
  ↓
Phase4 Polish → Phase5 Release
```

## 11. Impl 運用（P3-OPS-CURSOR-001）

| 項目 | 内容 |
|---|---|
| 実装ツール | **Cursor Impl のみ**（外部 Impl ツールは使わない） |
| 並行 | Cursor の複数エージェント／worktree 可。同一ファイルの同時編集は避ける |
| Godot | 実機／エディタ確認は必要に応じて 1〜2 |

（旧 P2-D177「外部 Impl 最大 2 並行」は本 Decision で置換。）

---

## 12. 参照

| 文書 | 用途 |
|---|---|
| `05_Backlog.md` | 未実装機能プール |
| `04_Development_Master_Plan.md` | マイルストーン戦略 |
| `26_CombatVision.md` | 戦闘不変原則 |
| `docs/archives/GameplayArchive/Proposal/Phase3B_Status_Element_Combat_Proposal_v1.0.md` | 状態異常・属性検討案 |

---

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-06-23 | Cursor 移行初版 |
| v1.1 | 2026-06-23 | 設計パイプライン・戦闘設計フロー（P2-D169） |
| v1.2 | 2026-06-23 | M9 完了・旧並行運用・Phase3-A 開始 |
| v1.3 | 2026-07-17 | §7.1 ブランチ統合方針（Impl GO → 統合＋`main` 同時） |
| v1.4 | 2026-07-22 | HQ/Impl とも Cursor 一本化（P3-OPS-CURSOR-001）。§11 更新 |
