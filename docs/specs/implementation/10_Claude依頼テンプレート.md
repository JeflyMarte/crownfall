# 10_Claude依頼テンプレート

## 基本テンプレート

```text
あなたはGodot 4に精通したシニアゲームエンジニアです。

Crownfallを実装します。

必ず最初に読む：
- docs/project/CurrentState.md
- docs/project/CurrentSprint.md

Task Context Bundle（本ファイル参照）に従い、必要な spec のみ読む。

今回の対象Task：
TaskXXX〜TaskYYY

実装してほしいこと：
-

実装しないこと：
-

完了条件：
-

完了後に以下を報告してください（HQ がリポジトリで確認して承認）。
- 変更ファイル一覧
- 実装内容
- テスト方法
- 懸念点

ChatGPT コピペブロック（■ Task:）は不要。
```

---

## Task Context Bundle

Task 種別に応じた Bundle を使う。各 Bundle の **Read** のみ読む。**Do Not Read** は明示指示がない限り読まない。

### General Start（全 Task 共通）

**Read**
- `docs/project/CurrentState.md`
- `docs/project/CurrentSprint.md`

**Do Not Read**
- `docs/archives/**`
- World/Lore 文書（`docs/specs/game/29`〜`37`）
- `docs/archives/**/Completed/**`
- `docs/specs/` 全文

---

### Room / Branch Task

**Read**
- `docs/project/CurrentState.md`
- `docs/project/CurrentSprint.md`
- `docs/specs/implementation/CODEMAP.md`
- `docs/specs/game/05_ダンジョン.md`
- 該当 Decision: `docs/specs/decisions/01_MVP方針決定.md`, `docs/specs/core/03_Decision_Log.md`（該当行のみ）

**Do Not Read**
- World/Lore 文書（`docs/specs/game/29`〜`37`）
- `docs/specs/game/14_アートディレクション.md`, `15_アセット一覧.md`
- `docs/archives/**/Completed/**`
- 無関係な game / implementation spec

---

### Equipment / Loot Task

**Read**
- `docs/project/CurrentState.md`
- `docs/specs/implementation/CODEMAP.md`
- `docs/specs/game/07_武器_装備.md`
- `docs/specs/implementation/03_Resource設計.md`

**Do Not Read**
- World/Lore 文書（`docs/specs/game/29`〜`37`）
- `docs/archives/**/Completed/**`
- `docs/specs/game/05_ダンジョン.md`

---

### Combat Task

**Read**
- `docs/project/CurrentState.md`
- `docs/specs/implementation/CODEMAP.md`
- `docs/specs/game/08_戦闘_AI.md`

**Do Not Read**
- World/Lore 文書（`docs/specs/game/29`〜`37`）
- `docs/archives/**`
- `docs/specs/game/14_アートディレクション.md`, `15_アセット一覧.md`
- `docs/specs/game/05_ダンジョン.md`

---

### ProjectDocs Update Task

**Read**
- `docs/project/CurrentState.md`
- `docs/project/CurrentSprint.md`
- 更新対象 spec のみ

**Do Not Read**
- `docs/specs/` 全文
- World/Lore 文書（`docs/specs/game/29`〜`37`）
- `docs/archives/**/Completed/**`

---

## 初回依頼例（参考・完了済み）

```text
Task001〜Task007を実装してください。

目的は、Godotプロジェクトの基本構造と画面遷移を作ることです。

実装対象：
- BootScene
- BaseScene
- DungeonScene
- ResultScene
- GameState
- SceneRouter

まだ戦闘、ドロップ、鑑定は実装しないでください。
```

## 自動戦闘依頼例（参考・完了済み）

```text
Task017〜Task022を実装してください。

目的は、王都跡の通常戦闘が自動で進む状態を作ることです。

実装対象：
- EnemyData
- CombatController
- 自動通常攻撃
- HP管理
- 敵全滅時の部屋クリア
```

※ `UnitController`, `DamageCalculator` は target 構成。現行実装は `CODEMAP.md` を参照。
