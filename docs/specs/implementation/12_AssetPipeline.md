# 12_AssetPipeline

## フロー

仕様書
↓
Claude Code
↓
Pixel Apprenticeで素材生成
↓
assets/へ保存
↓
Godot Import
↓
Sceneへ組み込み
↓
ゲーム内確認

## 命名規則

characters/{name}_{action}.png
enemies/{name}_{action}.png
tiles/{tileset}.png
icons/{icon}.png

## サイズ

キャラ:32x32
ボス:64x64
タイル:32x32
UI:必要サイズ
