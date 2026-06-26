# 12_AssetPipeline

## フロー

仕様書
↓
Claude Code（Task 仕様化）
↓
Pixel Apprentice（素材生成 — P3-D013 で PA 必須のみ）
↓
assets/ へ保存
↓
Godot Import（下記参照）
↓
Scene へ組み込み（Impl CC）
↓
ゲーム内確認 / Headless Smoke（下記参照）

## 素材生成分担（P3-D013 — 2026-06-25）

| 担当 | 対象 | 例 |
|---|---|---|
| **Pixel Apprentice** | 一貫性が必要な **スプライトシート** | ENM / BOSS / CHR / ICO / VFX / 32×32 タイル |
| **ChatGPT（オーナー生成）** | **代替可能なビジュアル** | ダンジョン背景・雰囲気 art・UI 参考 |
| **HQ 判定** | 発注前に PA 必須か確認 | Phase UI-1 バトル背景 → ChatGPT 可 |

**原則:** PA Batch は Impl 接続に必須なピクセルアートのみ。背景は ChatGPT → Godot `TextureRect` 等で暫定可。

## 命名規則（Phase3-A 確定 — P3-D003/004）

| カテゴリ | パターン | 例 |
|---|---|---|
| 敵スプライト | `ENM_{PascalName}_Sheet.png` | `ENM_BoneWalker_Sheet.png` |
| ボス | `BOSS_{PascalName}_Sheet.png` | `BOSS_RoyalGuardCaptain_Sheet.png` |
| 冒険者 | `CHR_{PascalName}_Sheet.png` | `CHR_Warrior_Sheet.png` |
| タイル | `TILE_{DG}_{Desc}_NN.png` | `TILE_RoyalRuins_Wall_01.png` |
| オブジェクト | `OBJ_{PascalName}.png` | `OBJ_TreasureChest_Closed.png` |
| UI フレーム / ボタン | `UI_{PascalName}.png` | `UI_Btn_Normal.png` |
| アイコン | `ICO_{PREFIX}_{PascalName}.png` | `ICO_WPN_IronSword.png` |
| VFX | `FX_{PascalName}.png` | `FX_Hit_Normal.png` |

**サイズ:**

| 種別 | Canvas |
|---|---|
| 通常敵（1 フレーム） | 32×32 |
| ボス（1 フレーム） | 64×64 |
| タイル / Object | 32×32 |
| アイコン（武器/防具/装飾品/素材） | 64×64 |
| アイコン（Gold/HP/ATK/DEF/CRT） | 32×32 |
| UI ボタン | 128×32 |
| シーン背景 | 1280×720 |

**SpriteSheet レイアウト（ENM / CHR 共通）:**

```
通常敵（512×32 横ストリップ、32px/frame）:
  col  0- 3: Idle×4    (x=  0,  32,  64,  96)
  col  4- 7: Attack×4  (x=128, 160, 192, 224)
  col  8- 9: Hurt×2    (x=256, 288)  ← col 10-11 スキップ
  col 12-15: Death×4   (x=384, 416, 448, 480)

ボス（64px/frame）:
  col  0- 5: Idle×6
  col  6-13: Attack×8
  col 14-16: Hurt×3
  col 17-24: Death×8
```

---

## Godot Import

### 正常フロー（Godot Editor あり）

PNG を `assets/` 配下に配置後、Godot Editor を開くだけで自動インポートされる。
`.import` ファイルが自動生成される。

### .import 未生成の場合（Godot Editor なし環境）

batch5（白骸墓地 ENM）など `.import` ファイルが存在しない PNG は、
Editor を一度も開いていない環境では実行時にロードエラーになる。

**対処手順:**

```bash
# Godot 4.6 インストール済みの場合
# 1. headless でプロジェクトを開き import を走らせて即終了
godot4 --headless --editor --quit
# または（Editor フラグが効かない環境では）
godot4 --headless --quit-after 1

# 2. .import ファイルが生成されたことを確認
ls assets/dungeon/graveyard/batch5/*.import
```

**実装側の対処（現行）:** `DungeonScene.gd` の `_show_enemy_sprite()` は
`ResourceLoader.exists()` と `load() as SpriteFrames` の null チェックで
.import 未生成時に graceful fallback（sprite 非表示）する。クラッシュはしない。

---

## Headless Smoke Test

Godot Editor を起動せずに起動エラー・Autoload クラッシュを検出する手順。  
Phase2-M7 Task035 で確立（参照: `11_TASK_INDEX.md` P2-Task038）。

### コマンド

```bash
# Step 1: アセットインポート（.import 生成）
godot4 --headless --editor --quit

# Step 2: ゲーム起動 smoke（N フレーム後に自動終了）
godot4 --headless --quit-after 120

# 終了コードを確認（0 = 正常）
echo "Exit: $?"
```

### 期待される出力（正常）

```
Godot Engine v4.6.xxx
...
INFO: Autoload initialized: GameState
INFO: Autoload initialized: DataRegistry
INFO: Autoload initialized: SceneRouter
INFO: Autoload initialized: EventBus
INFO: BootScene ready
Exit: 0
```

- `ERROR:` / `SCRIPT ERROR:` が出力されないこと
- 終了コード `0`

### 既知の出力（非致命的）

| メッセージ | 原因 | 対処 |
|---|---|---|
| `ERROR: Failed to load resource "res://assets/dungeon/graveyard/batch5/ENM_*.png"` | .import 未生成（batch5） | Editor で import 実行 |
| `ERROR: Failed to load resource "res://assets/dungeon/royal_ruins/batch4/ENM_RuinsLooter_Sheet.png"` | .import 未生成（batch4 一部） | 同上 |
| `WARNING: AnimatedSprite2D has no SpriteFrames` | 上記ロード失敗の連鎖 | 非致命的、Editor import 後に解消 |

### 落とし穴

- **`--headless --editor --quit` が効かない場合:** `--quit-after 1` に切り替える。インポートは起動初回に自動実行される。
- **Autoload クラッシュ:** `SCRIPT ERROR` + Exit 1。Autoload スクリプトの構文エラーまたは依存リソース欠損が原因。
- **MacBook Air 16GB 環境:** Godot Editor を同時に開かない（メモリ競合）。smoke test は Editor 終了後に実行する。
- **パスの差異:** macOS では `godot4`、Linux CI では `godot` または `./Godot_v4.6_linux.x86_64` など環境依存。

### 実行スクリプト

上記手順をまとめたスクリプトを用意している:

```bash
# import + smoke test（推奨）
bash tools/smoke_test.sh

# import のみ
bash tools/smoke_test.sh --import-only
```

スクリプト: `tools/smoke_test.sh`
- godot4 / godot (PATH) → `/Applications/Godot*.app` の順でバイナリを自動検索
- Step 1 import 失敗時は `--quit-after 1` にフォールバック
- 終了コード: 0 = PASS、非 0 = FAIL
