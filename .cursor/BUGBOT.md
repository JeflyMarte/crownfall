# Crownfall — Bugbot レビュー指針

Godot 4.6.3 / GDScript プロジェクト向け PR レビュールール。

## 必須チェック

### Godot 4 構文

- Godot 3 構文（`yield`, `onready var`, `export`, 文字列 `connect`）がないか
- `@export`, `@onready`, `await`, `signal.connect(callable)` を使っているか

### アーキテクチャ違反

- UI から GameState を直接大規模変更していないか
- DataRegistry を経由せず `.tres` を散在ロードしていないか
- SceneRouter を迂回したシーン遷移がないか
- 新規巨大 Singleton の追加がないか

### データ整合

- `res://` パスが実在するか（存在しないアセット参照）
- EventBus シグナル名の typo
- DataRegistry の id（weapon_id, dungeon_id 等）が既存マスタと一致するか

### テスト

- ロジック変更に `res://tests/unit/` の GUT テスト追加・更新があるか
- CI（`tools/smoke_test.sh`, `tools/run_tests.sh`）が通る構成か

## スコープ

- 1 PR = 1 Task 程度の小さな差分を推奨
- `docs/specs/` にない仕様追加は差戻し
- `docs/archives/` の Proposal を根拠にした実装は差戻し

## 命名

- スクリプト: PascalCase（`FooBar.gd`）
- 変数: snake_case
- 定数: UPPER_SNAKE_CASE

## 参照

- `docs/specs/implementation/CODEMAP.md`
- `docs/specs/implementation/07_コーディングルール.md`
- `.cursor/rules/gdscript.mdc`
