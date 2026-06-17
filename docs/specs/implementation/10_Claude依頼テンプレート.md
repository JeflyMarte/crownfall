# 10_Claude依頼テンプレート

## 基本テンプレート

```text
あなたはGodot 4に精通したシニアゲームエンジニアです。

CrownfallのMVPを実装します。

以下の仕様書を前提にしてください。

- implementation/00_CLAUDE_README.md
- implementation/01_Godotアーキテクチャ.md
- implementation/05_実装ロードマップ.md

今回の対象Task：
TaskXXX〜TaskYYY

実装してほしいこと：
-

実装しないこと：
-

完了条件：
-

完了後に以下を報告してください。
- 変更ファイル一覧
- 実装内容
- テスト方法
- 懸念点
```

## 初回依頼例

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

## 自動戦闘依頼例

```text
Task017〜Task022を実装してください。

目的は、王都跡の通常戦闘が自動で進む状態を作ることです。

実装対象：
- EnemyData
- UnitController
- CombatController
- DamageCalculator
- 自動通常攻撃
- HP管理
- 敵全滅時の部屋クリア
```
