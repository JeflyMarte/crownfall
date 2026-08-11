# Godot ソロ開発 — Cursor Agent キット

Crownfall の運用反省を蒸留した、**次プロジェクト用の雛形**。

## 使い方

1. 新しい Godot リポジトリを作る
2. 本ディレクトリの中身をリポジトリルートへコピーする  
   （`.cursor/`・`AGENTS.md`・`docs/` など）
3. 全文検索で `PROJECT_NAME` を実際のタイトルに置換する
4. Godot バージョン（例: 4.6.x）を `AGENTS.md` / `gdscript.mdc` に合わせて直す
5. 最初の起動即死が起きたら `pitfalls-startup.mdc` に追記を始める

## 含まれるもの

| パス | 役割 |
|---|---|
| `AGENTS.md` | エージェント入口 |
| `CLAUDE.md` | 互換ポインタ |
| `.cursor/rules/*.mdc` | 常時／按需ルール |
| `docs/project/CurrentState.md` | 状態の正（スタブ） |
| `docs/project/CurrentSprint.md` | スプリント焦点（スタブ） |
| `docs/specs/core/00_Operations.md` | ソロ運用 SSOT |

## 設計方針（短く）

- **起動即死だけ常時**、詳細カタログは按需（トークン節約）
- **直したらコミット＋本線**が既定
- **修正＝再発防止まで**が完了
- **プレイヤー文言は SSOT＋禁止語＋同期テスト**
- **オミットはフラグと文言を同ターン**
- 体験・セーブ破壊の懸念は **STOP → 確認**
