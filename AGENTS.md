# Crownfall — AGENTS.md

Cursor AI およびその他 AI アシスタント共通の入口指示。

---

## Primary Entry Points

| ファイル | 役割 |
|---|---|
| `docs/project/CurrentState.md` | **プロジェクト状態の正** — フェーズ、完了 Task、Next Task、Known Issues |
| `docs/project/CurrentSprint.md` | **現在の Task 焦点** — スプリント目標、優先順位、Blocker |
| `docs/specs/core/06_DevelopmentHQ_Operations.md` | **DevelopmentHQ 運用 SSOT** — セッション種別・ワークフロー・レビュー |
| `docs/specs/core/07_Git_Mac_Cloud_Sync.md` | **Git / Mac / Cloud 同期** — オーナー短指示「遠隔で作業開始」「MACで作業開始」 |

セッション開始時は必ず上記から読む。Phase 0 や MVP 初期 Task の前提は使わない。

オーナーが **「遠隔で作業開始」** または **「MACで作業開始」** とだけ指示した場合、`.cursor/rules/git-mac-cloud-sync.mdc` が `07_Git_Mac_Cloud_Sync.md` **§4 変換ルール** に従い詳細手順へ変換する。

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
- 仕様不足・矛盾・曖昧な指示は推測せず確認する
- 体験・面白さ・システムへの懸念がある指示は **STOP してオーナー確認**（詳細: `.cursor/rules/hq-response-minimal.mdc`）

---

## Cursor 応答

- **伝える:** 何をしたか／残り・推奨アクション／疑義（あれば STOP）
- **書かない:** 修正ファイルパスの羅列、編集過程
- 承認依頼・Impl 依頼プロンプトは詳しく書いてよい
- 詳細: `.cursor/rules/hq-response-minimal.mdc`

---

## Cursor Skills（Impl 向け）

Task 種別に応じて `.cursor/skills/` を使う:

| Skill | 用途 |
|---|---|
| `spec-bundle` | Impl 開始・Task 依頼時の spec 読み込み |
| `run-gut-tests` | GUT / smoke 実行と結果報告 |
| `impl-closeout` | Task 完了報告の生成 |

---

## 関連

- DevelopmentHQ 運用: `docs/specs/core/06_DevelopmentHQ_Operations.md`
- 実装ルール: `docs/specs/implementation/06_Claude運用ルール.md`, `07_コーディングルール.md`
- Task 依頼形式: `docs/specs/implementation/10_Claude依頼テンプレート.md`
- Cursor ルール: `.cursor/rules/developmenthq-operations.mdc`, `.cursor/rules/hq-response-minimal.mdc`, `.cursor/rules/ui-layout.mdc`, `.cursor/rules/git-wip-safety.mdc`, `.cursor/rules/git-mac-cloud-sync.mdc`
- Git / Mac / Cloud: `docs/specs/core/07_Git_Mac_Cloud_Sync.md`

---

## 完了報告（Impl セッション）

Task 完了時は以下を報告する（ChatGPT コピペブロックは **不要**）。`impl-closeout` skill を使ってよい:

- 変更ファイル一覧
- 実装要約
- テスト手順と結果
- 懸念点

HQ がリポジトリを直接確認して承認する。
