# Git / Mac / Cloud 同期運用 — v1.0

**Status:** SSOT（DevelopmentHQ 承認済）  
**Version:** v1.1  
**Approved:** 2026-07-12  
**Decisions:** P3-OPS-GIT-001  
**Audience:** プロジェクトオーナー / Cursor HQ・Impl / Cloud Agent

> **v1.1** — §4「短指示 → 変換ルール」を SSOT として独立記載（Cursor ルールと双方向参照）

---

## 1. 目的

Crownfall は **Mac ローカル（Godot 実機確認）** と **Cursor Cloud Agent（遠隔実装）** の2環境で開発する。  
本書は、オーナーが **短い開始フレーズだけ** 指示し、エージェントが詳細手順に変換して実行するための SSOT である。

関連:

- WIP / stash 安全: `.cursor/rules/git-wip-safety.mdc`
- エージェント向けトリガー変換: `.cursor/rules/git-mac-cloud-sync.mdc`

---

## 2. 環境の正

| 環境 | 場所 | 用途 |
|---|---|---|
| **Mac ローカル** | `/Users/marte/Projects/crownfall` | Godot 起動・プレイテスト・画面確認 |
| **Cursor Cloud** | GitHub クローン（`/workspace` 等） | 実装・テスト・PR 作成 |
| **Git 正** | `origin`（GitHub `JeflyMarte/crownfall`） | 両環境の唯一の同期点 |

**Godot が開くフォルダと `git` の cwd は必ず同一** にする。別フォルダの clone を混在させない。

---

## 3. ブランチ方針

| 種別 | 命名 | 用途 |
|---|---|---|
| **本線** | `main` | マージ済みの正。長期の作業基点 |
| **遠隔 feature** | `cursor/<task-slug>-cca2` | Cloud Agent が 1 Task 単位で push |
| **Mac 統合（一時）** | 例: `cursor/sub-mac-ui-integration-cca2` | 未マージの複数 feature を Mac で一括確認 |

原則:

- 遠隔作業は **`main` 直 commit しない**（feature ブランチ + PR）
- Mac で「最新 UI が見えない」場合、多くは **`main` が古い** か **別ブランチ未 checkout** が原因
- 統合ブランチは **一時的**。`main` へマージ後は Mac も `main` のみでよい

---

## 4. 短指示 → 変換ルール（SSOT）

オーナーの **1行指示** を、エージェント（Cursor HQ / Impl / Cloud Agent）が **追加質問なしで** 実行手順に変換するための正規表。  
Cursor 実装: `.cursor/rules/git-mac-cloud-sync.mdc`（本 §4 と内容を一致させる）。

### 4.0 変換の原則

| 原則 | 内容 |
|---|---|
| **オーナーは git を書かない** | ブランチ名・fetch・stash 等はエージェントが決定・案内 |
| **エージェントは実行する** | 「遠隔で作業開始」は Cloud 側で実際に git / 読書を行う |
| **Mac はコピペブロック** | 「MACで作業開始」は Mac ターミナル用コマンドを **1ブロック** で渡す |
| **表記ゆれは同一** | 下表「同義トリガー」はすべて同じ変換にマップ |
| **応答は短く** | 変換後の報告はブランチ・HEAD・次 Task の **1〜3行**（`hq-response-minimal`） |

### 4.1 トリガー登録表

| ID | 正規トリガー | 同義トリガー（例） | 実行環境 |
|---|---|---|---|
| **T-REMOTE-START** | 遠隔で作業開始 | 遠隔作業開始 / cloud で作業開始 / クラウドで作業開始 | Cursor Cloud |
| **T-MAC-START** | MACで作業開始 | Macで作業開始 / macで作業開始 / ローカルで作業開始 | Mac ローカル（案内） |
| **T-REMOTE-END** | （明示フレーズなし） | 遠隔作業完了 / 実装完了 / PR 更新後 | Cursor Cloud |

`T-REMOTE-END` はオーナーが言わなくても、遠隔で実装・レビューを終えたエージェントが **必ず** 適用する（§5）。

### 4.2 T-REMOTE-START → 変換フロー

```
オーナー: 「遠隔で作業開始」
    │
    ▼
[1] git fetch origin
[2] git status -sb  +  git stash list | head -5
[3] CurrentState.md / CurrentSprint.md を読む
[4] ブランチ決定（§4.5 決定木）
[5] checkout / 新規なら branch 作成
[6] WIP が大きければ WIP commit を優先（stash のみに依存しない）
[7] オーナーへ短報告（§4.6 テンプレート A）
    │
    ▼
通常 Task 着手（オーナー追加指示待ち）
```

**エージェントが実行するコマンド（Cloud）:**

```bash
git fetch origin
git status -sb
git stash list | head -5
# ブランチ決定後
git checkout <branch>   # または git checkout -b cursor/<slug>-cca2 origin/main
git log -1 --oneline
```

**やってはいけないこと:** 「どのブランチにしますか？」と丸投げ / fetch せずに着手 / stash 無確認 drop

### 4.3 T-MAC-START → 変換フロー

```
オーナー: 「MACで作業開始」
    │
    ▼
[1] 作業ブランチを決定（§4.5）
[2] 期待 HEAD を特定（直前 PR / 統合ブランチ tip）
[3] Mac 用コピペブロックを1つ提示（§4.4）
[4] 期待 git log -1 を明記
[5] Godot ⌘+Q → 同フォルダ再起動を添える
[6] stash 残存があれば報告（drop しない）
    │
    ▼
オーナーが Mac で実行 → Godot 確認
```

**エージェントは Cloud 上で Mac の git を実行しない**（案内のみ）。  
Mac 正パス: **`/Users/marte/Projects/crownfall`**（推測禁止）。

### 4.4 T-MAC-START → 出力テンプレート（コピペブロック）

`<branch>` と期待コミットはセッション文脈で埋める。

```bash
cd /Users/marte/Projects/crownfall
git fetch origin
git stash push -m "mac wip"   # 未コミットがあるときのみ
git checkout <branch>
git pull origin <branch>
git log -1 --oneline
```

**統合確認中（HQ 未指定時のデフォルト）:** `<branch>` = `cursor/sub-mac-ui-integration-cca2`  
**main のみでよいとき:** `<branch>` = `main`

### 4.5 ブランチ決定木（両トリガー共通）

```
CurrentState / 直前 PR / 会話文脈に「継続ブランチ」あり？
  ├─ YES → そのブランチ
  └─ NO
       ├─ Mac 統合 UI 確認中？ → cursor/sub-mac-ui-integration-cca2
       ├─ 新規 Task（遠隔）？ → main から cursor/<slug>-cca2 新規作成
       └─ それ以外 → main
```

HQ がブランチを明示した場合は **決定木より HQ 指定を優先**。

### 4.6 エージェント応答テンプレート

**A — T-REMOTE-START 完了報告（例）**

```
遠隔作業を開始した。
ブランチ: cursor/xxx-cca2 @ abc1234（1行メッセージ）
着手: P3-XXX-YYY（CurrentSprint より）
```

**B — T-MAC-START 案内（例）**

```
Mac で以下を実行してください。期待: abc1234 fix(forge): …
（§4.4 のコードブロック）
Godot は ⌘+Q で終了してから、同フォルダで開き直してください。
```

**C — T-REMOTE-END 添付（実装完了時・必須）**

```
PR #N を更新した。Mac 確認用:
（T-MAC-START と同型のコードブロック + 期待 log -1）
```

### 4.7 オーナー向け — 指示は2種類だけ

| # | オーナーが言う | 変換 ID |
|---|---|---|
| 1 | **遠隔で作業開始** | T-REMOTE-START |
| 2 | **MACで作業開始** | T-MAC-START |

表記ゆれ（`Mac` / `MAC` / `mac`、句読点なし等）は同一トリガー。

---

## 5. 遠隔作業終了時（T-REMOTE-END・エージェント必須）

遠隔セッションで実装を終えたら、**報告だけで終わらせない**。

1. 変更を **commit + push**（`git push -u origin <branch>`）
2. PR を create / update
3. オーナー向けに **MACで作業開始** 用の pull ブロックを **必ず** 添える（対象ブランチ名・期待 `git log -1`）

---

## 6. よくある事故と対処

| 症状 | 典型原因 | 対処 |
|---|---|---|
| Mac で直した UI が消えた | Cloud 退避 stash / 別ブランチ | `git stash list` → 内容確認 → オーナー確認後に復元 |
| Mac で新機能が見えない | 古い `main` のまま | fetch → 正ブランチ checkout → `git log -1` 確認 |
| Godot と git の内容が違う | **別フォルダ** のプロジェクトを開いている | `/Users/marte/Projects/crownfall` のみ使用 |
| 分解タブが 🔒 | `.tscn` の `disabled` 等が未マージ | 統合ブランチまたは該当 PR を Mac に pull |

---

## 7. 禁止

- 未 push のまま「完了」と報告する
- オーナー確認なしに `git stash drop` / `stash clear`
- Mac パスを推測して別 clone を前提にする
- Cloud Agent 移管前に大きな未コミット塊を放置する（`git-wip-safety` 参照）

---

## 8. 参照

- `docs/specs/core/03_Decision_Log.md` — P3-OPS-GIT-001
- `docs/specs/core/06_DevelopmentHQ_Operations.md`
- `.cursor/rules/git-wip-safety.mdc`
- `.cursor/rules/git-mac-cloud-sync.mdc` — §4 変換ルールの Cursor 実装（alwaysApply）
