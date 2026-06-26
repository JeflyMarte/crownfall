# Crownfall — AGENTS.md

Cursor AI およびその他 AI アシスタント共通の入口指示。

---

## Primary Entry Points

| ファイル | 役割 |
|---|---|
| `docs/project/CurrentState.md` | **プロジェクト状態の正** — フェーズ、完了 Task、Next Task、Known Issues |
| `docs/project/CurrentSprint.md` | **現在の Task 焦点** — スプリント目標、優先順位、Blocker |
| `docs/specs/core/06_DevelopmentHQ_Operations.md` | **DevelopmentHQ 運用 SSOT** — セッション種別・ワークフロー・レビュー |

セッション開始時は必ず上記から読む。Phase 0 や MVP 初期 Task の前提は使わない。

---

## セッション種別

| 種別 | 役割 |
|---|---|
| **HQ セッション** | DevelopmentHQ — Scope / Decision / レビュー / Closeout |
| **Impl セッション** | 指定 Task の実装のみ |

詳細: `docs/specs/core/06_DevelopmentHQ_Operations.md`

---

## SSOT

正式仕様（ProjectDocs）の唯一の正は **`docs/specs/`**。

- `docs/specs/decisions/` — DevelopmentHQ 承認済みの確定方針（元仕様を上書き）
- `docs/specs/game/` — ゲーム仕様
- `docs/specs/implementation/` — 実装ルール・アーキテクチャ・Task 索引

現行コードの実態: `docs/specs/implementation/CODEMAP.md`

---

## コンテキスト読み込み

- Task に必要な spec のみ按需ロード（Bundle 一覧: `docs/specs/implementation/10_Claude依頼テンプレート.md`）
- **`docs/specs/` 全文をデフォルトで読まない**
- **`docs/archives/` をデフォルトで読まない**
- archives 内の文書は **Proposal**。DevelopmentHQ 承認前は実装根拠にしない
- ロア・世界観 Bible は Task が明示的に要求する場合のみ

---

## 設計・実装の境界

- **DevelopmentHQ（Cursor HQ セッション）** が設計判断・Decision 承認を行う
- Impl セッションは独断でゲームデザインや仕様変更を決定しない
- 指定 Task スコープ外の実装・仕様外機能の追加をしない
- 仕様不足・矛盾は推測せず質問する

---

## Cursor 応答（トークン節約）

- **詳しく書くのは 2 種のみ:** オーナー承認依頼 / Claude Code 用プロンプト
- それ以外は最小限（判定・ブロッカー・変更パス程度）
- 詳細: `.cursor/rules/hq-response-minimal.mdc`

---

## 関連

- DevelopmentHQ 運用: `docs/specs/core/06_DevelopmentHQ_Operations.md`
- 実装ルール: `docs/specs/implementation/06_Claude運用ルール.md`, `07_コーディングルール.md`
- Task 依頼形式: `docs/specs/implementation/10_Claude依頼テンプレート.md`
- Cursor ルール: `.cursor/rules/developmenthq-operations.mdc`, `.cursor/rules/hq-response-minimal.mdc`

---

## 完了報告（Impl セッション）

Task 完了時は以下を報告する（ChatGPT コピペブロックは **不要**）:

- 変更ファイル一覧
- 実装要約
- テスト手順と結果
- 懸念点

HQ がリポジトリを直接確認して承認する。
