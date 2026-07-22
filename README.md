# Crownfall

2D見下ろし型・自動探索ハクスラRPG（スマホ向け）

## 概要

プレイヤーは冒険者を直接操作しない。探索隊の指揮官として、方針・装備・編成を決める。滅びた旧世界の遺跡を周回し、伝説の武器を発掘・厳選するゲーム。

## 技術スタック

- Godot 4.6.3 Standard
- GDScript
- iOS優先 / Android対応
- Landscape固定 / 1280×720

## 開発状況

**最新状態:** [`docs/project/CurrentState.md`](docs/project/CurrentState.md)  
**現在のスプリント:** [`docs/project/CurrentSprint.md`](docs/project/CurrentSprint.md)

## ドキュメント

```
docs/project/              進捗ダッシュボード（AI 入口）
docs/specs/core/           憲章・ロードマップ・DevelopmentHQ 運用
docs/specs/game/             ゲーム仕様
docs/specs/implementation/   Godotアーキテクチャ・実装ルール・CODEMAP
docs/specs/decisions/        確定済みMVP方針
```

## AI 開発ルール

| 役割 | 入口 |
|---|---|
| DevelopmentHQ（設計・進行） | [`docs/specs/core/06_DevelopmentHQ_Operations.md`](docs/specs/core/06_DevelopmentHQ_Operations.md) |
| Implementation（実装） | [`AGENTS.md`](AGENTS.md) |

開発は **Cursor に一本化**（HQ / Impl とも Cursor）。
