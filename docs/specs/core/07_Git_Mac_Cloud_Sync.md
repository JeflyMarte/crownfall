# Git / Mac / Cloud 同期運用 — v1.0

**Status:** SSOT（DevelopmentHQ 承認済）  
**Version:** v1.0  
**Approved:** 2026-07-12  
**Decisions:** P3-OPS-GIT-001  
**Audience:** プロジェクトオーナー / Cursor HQ・Impl / Cloud Agent

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

## 4. オーナー向け — 指示は2種類だけ

オーナーは次の **開始フレーズのみ** 送ればよい。詳細 git 操作はエージェントが行う。

| # | オーナーが言う | 意味 |
|---|---|---|
| 1 | **遠隔で作業開始** | Cloud Agent セッションを、リポジトリ最新・正ブランチ・Task 文脈で開始する |
| 2 | **MACで作業開始** | Mac ローカルを、GitHub と同じコミット・正ブランチで Godot 確認可能な状態にする |

表記ゆれ（`Mac` / `MAC` / `mac`、句読点なし等）はエージェントが同一トリガーとして扱う。

### 4.1 遠隔で作業開始 — エージェントが行うこと

1. `git fetch origin`
2. `git status -sb` と `git stash list | head -5`（`git-wip-safety` 準拠）
3. `docs/project/CurrentState.md` / `CurrentSprint.md` を読み、Next Task を把握
4. 作業対象ブランチを決定して checkout
   - 新規 Task → `main` から `cursor/<slug>-cca2` を作成
   - 継続 Task → 既存 feature / 統合ブランチを checkout
5. 未 push / 未コミット WIP があれば報告し、コミット方針を決める
6. オーナーへ **1行で** 報告: 現在ブランチ・HEAD コミット・これから着手する Task

### 4.2 MACで作業開始 — エージェントが行うこと

Mac 上のターミナルで実行するコマンドを **そのまま提示** する（オーナーがコピペ実行）。

1. 作業ディレクトリ確認: `cd /Users/marte/Projects/crownfall`
2. `git fetch origin`
3. 未コミットがあれば `git stash push -m "mac wip"` を案内（任意・オーナー判断）
4. **作業ブランチ** を checkout + pull  
   - 統合確認中 → `cursor/sub-mac-ui-integration-cca2`（または HQ が指定したブランチ）  
   - 通常 → `main`（マージ済み後）
5. `git log -1 --oneline` の期待値を明示
6. Godot: **⌘+Q で完全終了** → 同フォルダから再起動
7. stash がある場合は `git stash list` を確認し、復元要否をオーナーに確認（勝手に `drop` しない）

**Mac 開始テンプレート（統合ブランチ例）:**

```bash
cd /Users/marte/Projects/crownfall
git fetch origin
git stash push -m "mac wip"   # 未コミットがあるときのみ
git checkout cursor/sub-mac-ui-integration-cca2
git pull origin cursor/sub-mac-ui-integration-cca2
git log -1 --oneline
```

---

## 5. 遠隔作業終了時（エージェント必須）

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
- `.cursor/rules/git-mac-cloud-sync.mdc`
