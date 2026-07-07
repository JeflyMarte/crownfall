---
name: run-gut-tests
description: Crownfall の GUT ユニットテストまたは smoke test を実行し、結果を報告する。テスト実行・検証・CI 確認時に使う。
---

# Run GUT Tests

Crownfall のテストを実行して結果を報告する。

## 手順

1. プロジェクトルートで以下のいずれかを実行:
   - ユニットテスト: `bash tools/run_tests.sh`
   - Smoke test: `bash tools/smoke_test.sh`
   - 両方: 先に smoke、続けて unit
2. 終了コードと出力を確認する
3. 失敗時は失敗テスト名・ファイル・エラーメッセージを報告する

## Cursor Tasks

VS Code / Cursor の Tasks からも実行可能:

- `GUT Unit Tests` — デフォルト test task
- `Smoke Test`

## 報告フォーマット

```
テスト: GUT / Smoke
結果: PASS / FAIL (exit N)
失敗: （あれば test 名と要約）
```

## 注意

- Godot 4.6.3 が PATH または `/Applications/Godot*.app` に必要
- 初回は `.godot` インポートが走ることがある（run_tests.sh 内で処理）
