# Crownfall — CLAUDE.md

Godot 4 に精通したシニアゲームエンジニアとして、**指定 Task の範囲のみ**実装する。

> **注記:** DevelopmentHQ は Cursor HQ セッションが担う。本ファイルは **Impl セッション**（Cursor / Claude Code 共通）向け。

---

## 役割

Crownfall（2D見下ろし型・自動探索ハクスラRPG / Godot 4.6.3 / GDScript）の実装支援。
プレイヤーは冒険者を直接操作せず、探索隊の指揮官として方針・装備・編成を決める。

---

## 必ず最初に読む（Primary Entry Points）

1. `docs/project/CurrentState.md` — プロジェクト全体の進捗・フェーズ・Next Task
2. `docs/project/CurrentSprint.md` — 現在のスプリント焦点・優先 Task
3. `docs/specs/core/06_DevelopmentHQ_Operations.md` — HQ / Impl の役割分担

**Phase 0 / MVP 初期 Task の前提は使わない。** 上記ダッシュボードの現状を正とする。

---

## SSOT（Single Source of Truth）

正式仕様は **`docs/specs/` のみ**。詳細は Task に必要なファイルだけ按需ロードする。

| パス | 内容 |
|---|---|
| `docs/specs/decisions/` | MVP 上書き・確定方針（DevelopmentHQ 承認済） |
| `docs/specs/game/` | ゲーム仕様 |
| `docs/specs/implementation/` | アーキテクチャ・実装ルール・Task 索引 |
| `docs/specs/core/` | 憲章・ロードマップ・Decision Log・HQ 運用 |

実装マップ（**現行コードの実態**）: `docs/specs/implementation/CODEMAP.md`

Task 別ロード一覧: `docs/specs/implementation/10_Claude依頼テンプレート.md` の「Task Context Bundle」

---

## コンテキスト読み込みルール

- **`docs/specs/` 全文をデフォルトで読まない**
- **`docs/archives/` をデフォルトで読まない**（Proposal。DevelopmentHQ 承認前は実装根拠にしない）
- World/Lore 文書（`docs/specs/world/`）は Task が要求する場合のみ
- 対象外 Task・仕様外機能は実装しない

---

## Task 運用

- 指定 Task 番号の範囲のみ実装（1 回 1〜5 Task、変更ファイル 10 以下）
- 仕様不足・不明点は推測せず質問
- 完了報告: 変更ファイル一覧 / 実装内容 / テスト方法 / 懸念点

---

## HQ 承認後の Impl 責務

DevelopmentHQ 承認後、以下は **HQ セッション** が更新する（Impl はコード実装に集中してよい）:

- `CurrentState.md` / `CurrentSprint.md`
- マイルストーン完了時の `docs/specs/` 反映

設計判断は DevelopmentHQ が行う。Impl は独断で仕様を変更しない。

ChatGPT 向け `■ Task:` コピペブロックは **不要**（`.cursor/rules/developmenthq-operations.mdc` 参照）。
