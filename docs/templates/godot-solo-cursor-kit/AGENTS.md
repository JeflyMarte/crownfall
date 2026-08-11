# PROJECT_NAME — AGENTS.md

Cursor 上の HQ / Impl 共通の入口。**実装も設計判断も Cursor に一本化**（ソロ運用）。

---

## Primary Entry Points

| ファイル | 役割 |
|---|---|
| `docs/project/CurrentState.md` | **プロジェクト状態の正** — フェーズ、完了、Next、Known Issues |
| `docs/project/CurrentSprint.md` | **現在の焦点** — 目標、優先、Blocker |
| `docs/specs/core/00_Operations.md` | **運用 SSOT** — 完了条件、コミット、STOP、Closeout |

セッション開始時は必ず上記から読む。古いフェーズ前提を使わない。

---

## セッション種別

| 種別 | 役割 |
|---|---|
| **HQ** | Scope / Decision / レビュー / Closeout |
| **Impl** | 指定 Task の実装のみ（仕様独断変更禁止） |

ソロでも役割を分ける。同じチャットでも「いま HQ／いま Impl」を明示してよい。

---

## SSOT

正式仕様の正は **`docs/specs/`**。

| 場所 | 内容 |
|---|---|
| `docs/specs/decisions/` | 承認済み方針（元仕様を上書き） |
| `docs/specs/game/` | ゲーム仕様 |
| `docs/specs/implementation/` | 実装ルール・CODEMAP |

- `docs/specs/` 全文をデフォルトで読まない（Task に必要な分だけ）
- archives / 草案は **Proposal**。承認前は実装根拠にしない

---

## 設計・実装の境界

- 設計判断・Decision 承認は HQ
- Impl はスコープ外実装・仕様変更をしない
- 仕様不足・矛盾・曖昧さは推測せず確認
- 体験・面白さ・システム懸念は **STOP → オーナー確認**（`.cursor/rules/hq-response-minimal.mdc`）
- **修正完了の既定**はコミット＋本線反映（オーナーが止めた場合／STOP／WIP を除く）

---

## Cursor 応答

伝えること: **何をしたか／残り・推奨／疑義（あれば STOP）**  
書かないこと: 修正パス羅列、編集過程  

詳細: `.cursor/rules/hq-response-minimal.mdc`

---

## 必須ルール（Day1）

| ルール | 内容 |
|---|---|
| `pitfalls-startup.mdc` | 起動・パース即死（常時・短冊） |
| `known-pitfalls.mdc` | 全既往カタログ（按需） |
| `recurrence-prevention.mdc` | 直す→カタログ→ルール化 |
| `hq-ops.mdc` | コミット／本線／WIP／Closeout |
| `hq-response-minimal.mdc` | 応答と STOP |
| `player-copy.mdc` | プレイヤー文言・オミット同期 |
| `gdscript.mdc` | Godot / GDScript 慣習 |
| `git-wip-safety.mdc` | stash／退避事故防止 |

---

## 完了報告（Impl）

- 変更の要約（何が変わったか）
- テスト手順と結果
- 懸念点
- 再発防止を置いたか（該当時）

HQ がリポジトリを確認して Closeout する。
