---
name: impl-closeout
description: Crownfall Impl セッションの Task 完了報告を生成する。実装完了・HQ 承認依頼・Closeout 時に使う。
---

# Impl Closeout

Impl セッション完了時の報告を生成する。HQ がリポジトリで diff 確認後に承認する。

## 報告に含めるもの（必須）

1. **変更ファイル一覧** — パスのみ
2. **実装要約** — 何をしたか 3〜5 行
3. **テスト手順と結果** — 実行コマンドと PASS/FAIL
4. **懸念点** — なければ「なし」

## テスト実行

完了報告前に可能なら実行:

```bash
bash tools/smoke_test.sh
bash tools/run_tests.sh
```

## テンプレート

```markdown
## Task XXX 完了報告

### 変更ファイル
- path/to/file.gd
- ...

### 実装要約
- ...

### テスト
- `bash tools/run_tests.sh` → PASS/FAIL
- 手動: ...

### 懸念点
- なし / ...
```

## 禁止

- 仕様外機能の独断追加
- CurrentState.md / CurrentSprint.md の更新（HQ 担当）
