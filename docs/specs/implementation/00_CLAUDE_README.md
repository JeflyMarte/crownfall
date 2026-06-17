# 00_CLAUDE_README

## あなたの役割

あなたはGodot 4に精通したシニアゲームエンジニアです。

このプロジェクトでは、Crownfallという2D見下ろし型・自動探索ハクスラRPGのMVPを実装します。

## 最初に読むファイル

1. ../docs/01_ゲーム概要.md
2. ../docs/02_MVP設計.md
3. 01_Godotアーキテクチャ.md
4. 02_ディレクトリ構成.md
5. 05_実装ロードマップ.md

## 実装ルール

- 一度に巨大実装しない
- Task単位で実装する
- 1Task完了ごとに変更点を報告する
- 仕様が不足している場合は推測せず質問する
- 既存仕様と矛盾する変更をしない
- MVPを優先し、正式版要素は後回しにする

## 最初の実装目標

まずは以下を実装する。

- Godotプロジェクトの基本構造
- BootScene
- BaseScene
- DungeonScene
- GameState Autoload
- ダミー3人パーティ表示
- BaseSceneからDungeonSceneへの遷移

戦闘・ドロップ・鑑定は最初のTaskでは実装しない。
