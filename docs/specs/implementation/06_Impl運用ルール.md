# 06_Impl運用ルール

**対象:** Cursor **Impl セッション**（実装は Cursor に一本化）。

## 基本方針

Implementation Agent には、必ず **Task 単位** で依頼する。

悪い依頼

```text
このゲームを全部作って
```

良い依頼

```text
P2-Task050 を実装してください。
Exit Criteria に従い、M9 Closeout 文書と CurrentState 更新までを実装してください。
```

## 1回の依頼範囲

- 1〜5 Task まで
- 変更ファイル数は 10 以下
- 大きな設計変更は別依頼（HQ Decision 必須）

## 完了報告テンプレート

```text
■ 実装対象
Task 番号：

■ 参照仕様
ファイル：

■ 実装内容（要約）

■ 変更ファイル一覧

■ テスト手順と結果

■ 懸念点
```

HQ セッションがリポジトリを直接確認して承認する。

## レビュー観点（HQ が確認）

- 仕様から逸脱していないか
- Godot 4 構文として正しいか
- Resource 中心設計になっているか
- UI とロジックが分離されているか
- マジックナンバーがないか
- 拡張しやすいか

## 参照

- `docs/specs/core/06_DevelopmentHQ_Operations.md`
- `docs/specs/implementation/10_Impl依頼テンプレート.md`
- `AGENTS.md`
