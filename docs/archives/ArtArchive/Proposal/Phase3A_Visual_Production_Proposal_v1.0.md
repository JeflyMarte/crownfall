# Phase3-A Visual Production Proposal v1.0

**Status:** Proposal
**Type:** Visual Production Design Package
**Phase:** Phase3-A Visual Production
**Created:** 2026-06-22
**Owner:** Pixel Apprentice（P2-D129/130）
**Approved By:** 承認待ち（DevelopmentHQ）

**Design Basis:**
- `Phase2_Art_Direction_v1.1.md`（ArtArchive Completed）
- `Phase2_Accessory_Visual_Direction_v1.0.md`（ArtArchive Completed）
- `docs/specs/game/14_アートディレクション.md`
- `docs/specs/game/15_アセット一覧.md`

---

## 0. 前提

Phase3-A はビジュアルアセットの本番化フェーズ。

- ゲームプレイ仕様は **一切変更しない**
- Phase2_Art_Direction_v1.1 の承認済み方針をすべて継承する
- Pixel Apprentice が本書を制作基準として使用する
- 本 Proposal は DevelopmentHQ 承認後に `ArtArchive/Completed/` へ移動する

---

# 1. Visual Style Guide

## 1-1. Core Vision

**テーマ:** 「静かな滅び」と「武器が主役」のダークファンタジー

Crownfall のビジュアルは以下の感覚を伝える。

- 遺跡の重さと時間の堆積
- 冒険者ではなく武器を見る視点
- 静けさの中に潜む危険

## 1-2. Design Priorities

| 順位 | 優先項目 | 内容 |
|---|---|---|
| 1 | 視認性 | 暗い背景でも要素が判別できること |
| 2 | 武器の存在感 | 武器アイコン・スプライトが画面の主役 |
| 3 | プレイアビリティ | UI が邪魔にならない |
| 4 | 制作効率 | 量産可能な一貫スタイル |
| 5 | 世界観 | 上記すべてを満たした上での演出 |

## 1-3. Color Palette

### 基本色（低彩度・暗色中心）

| 色名 | 用途 | 目安値（参考） |
|---|---|---|
| Void Black | 最暗背景・アウトライン | `#0d0d0d` |
| Stone Dark | ダンジョン床・壁 | `#1e1e2a` |
| Stone Mid | 壁面・影 | `#2e2e3e` |
| Stone Light | ハイライト・縁 | `#4a4a5e` |
| Ash | キャラ肌・骨・岩 | `#9a9a8e` |
| Bone White | アンデッド・古代素材 | `#d4cbb8` |

### アクセント色（使用を絞る）

| 色名 | 用途 | 目安値（参考） |
|---|---|---|
| Gold | Legendary・Gold UI・Bronze 縁 | `#c8a040` |
| Blood Red | HP・出血エフェクト・危険 | `#a02020` |
| Soul Blue | MP・魔法・特殊エフェクト | `#4060a0` |
| Heal Green | 回復エフェクト・HEAL Room | `#40a060` |
| Rare Purple | Rare 以上アイテム演出 | `#7040a0` |

### 使用制限

- アクセント色は **1 画面に 2 色まで** を目標とする
- Gold は Legendary アイテム演出・UI 縁のみ（背景には使わない）
- Pure White / Pure Black は使わない（Void Black / Bone White で代替）

## 1-4. Line Art Rules

- アウトライン: **1px Dark**（Void Black か Stone Dark）
- アウトラインは内側に描く（スプライトサイズを超えない）
- Sub-pixel は使わない
- Anti-Aliasing 禁止

## 1-5. Light Source

- 全アセット共通: **左上 45°** 固定
- 影は右下方向

---

# 2. Pixel Art Production Pipeline

## 2-1. フロー概要

```
DevelopmentHQ / Game Designer
  → Asset Request（本書 §8 参照）
  → Pixel Apprentice 制作
  → assets/ へ配置
  → Godot Editor でインポート確認
  → DevelopmentHQ レビュー
  → 承認 → SSOT 登録（15_アセット一覧.md）
  → 差し替え実装（Scene .tscn）
```

## 2-2. ツール要件

| 項目 | 要件 |
|---|---|
| 制作ツール | ピクセルアートエディタ（Aseprite 推奨） |
| 出力形式 | PNG（透明背景） |
| カラーモード | RGB / 8bit |
| Compression | Lossless（PNG 最適化なし） |

## 2-3. Godot インポート設定（全アセット共通）

| 設定 | 値 |
|---|---|
| Filter | **Off**（Nearest / Pixel） |
| Mipmaps | **Off** |
| Repeat | Disabled |
| Compression | Lossless |

## 2-4. ディレクトリ構成（Phase3-A 完了後の想定）

```
assets/
├── sprites/
│   ├── characters/
│   │   ├── adventurers/
│   │   ├── enemies/
│   │   └── bosses/
│   ├── weapons/
│   ├── armors/
│   ├── accessories/
│   └── npcs/
├── tiles/
│   ├── royal_ruins/
│   ├── graveyard/
│   └── factory/         （Phase3-B）
├── icons/
│   ├── weapons/
│   ├── armors/
│   ├── accessories/
│   ├── materials/
│   └── ui/
├── fx/
│   ├── hit/
│   ├── heal/
│   └── status/
├── ui/
│   ├── frames/
│   ├── buttons/
│   └── hud/
└── audio/               （本 Proposal 対象外）
```

## 2-5. 制作優先順位（Phase3-A）

| 順位 | カテゴリ | 理由 |
|---|---|---|
| 1 | UI Theme / HUD | 全シーンに影響する基盤 |
| 2 | Weapon Icons | ゲームの主役・全周回で表示 |
| 3 | Armor / Accessory Icons | 装備 UI に直結 |
| 4 | Material Icons | Blacksmith UI（M8） |
| 5 | Enemy Sprites（王都跡） | 最初のダンジョン |
| 6 | Boss Sprite（王都守護兵長） | クライマックス体験 |
| 7 | Adventurer Sprites | パーティ表示 |
| 8 | Dungeon Tileset（王都跡） | 背景・空間演出 |
| 9 | VFX / FX | ポリッシュ層 |
| 10 | NPC（Merchant） | 商人画像 |

---

# 3. Sprite Production Rules

## 3-1. Canvas 基準

| カテゴリ | Canvas | 有効描画エリア | 備考 |
|---|---|---|---|
| 冒険者 | 32×32 px | 24〜28 px | 頭・胴・足で3分割 |
| 通常敵 | 32×32 px | 24〜28 px | 見下ろし視点 |
| ボス | 64×64 px | 48〜56 px | 画面上部固定表示 |
| NPC（Merchant） | 32×32 px | 24〜28 px | 立ち絵のみ |
| 武器（スプライト） | 32×32 px | 24×8 px | アイコンと共通ベース可 |

## 3-2. キャラクタースプライト詳細

### 冒険者 3 体（warrior / guardian / scout）

| 体型 | warrior | guardian | scout |
|---|---|---|---|
| 体格 | 普通 | 重装・大柄 | 細身・小柄 |
| 配色 | 鉄/革 | 鉄/盾 | 革/布 |
| 特徴 | 大剣所持 | 盾前面 | 弓携行 |

### 敵スプライト（王都跡）

| id | display_name | 体型 | 特徴 |
|---|---|---|---|
| fallen_soldier | 亡国兵 | 人間・普通 | 錆びた剣・ぼろ鎧 |
| ruined_guard | 崩れた衛兵 | 人間・重め | 壁にもたれた姿勢 |
| ruins_looter | 王都の盗掘者 | 人間・細身 | 袋を持つ・フード |
| rusted_knight | 朽ちた騎士 | 重装・大きめ | 甲冑・腐食表現 |

**elite_pool:**

| id | display_name | 特徴 |
|---|---|---|
| rusted_knight | 朽ちた騎士 | 上記 elite 版（別スプライト不要・HP のみ差分） |
| ruins_looter | 王都の盗掘者 | 上記 elite 版 |

### 敵スプライト（白骸墓地）

| id | display_name | 体型 | 特徴 |
|---|---|---|---|
| bone_walker | 骸骨兵 | 骨格・細い | 剣または槍 |
| grave_bat | 墓コウモリ | 小型・翼 | 素早い動き感 |
| hollow_gravedigger | 死体運び | 丸め・大柄 | シャベル所持 |
| pale_hound | 白骸の番犬 | 四足 | 骨が透ける犬 |

**elite_pool（白骸墓地）:**

| id | display_name | 特徴 |
|---|---|---|
| ossuary_knight | 骨廟の騎士 | 全身骨甲冑・Elite 専用 |

### ボス

| id | display_name | Canvas | 特徴 |
|---|---|---|---|
| royal_guard_captain | 王都守護兵長 | 64×64 | 大剣・完全甲冑・金縁 |
| gravekeeper | 千鐘の墓守 | 64×64 | 大きな鐘・ローブ・骨装飾 |

## 3-3. アイコン仕様（武器 / 防具 / 装飾品 / 素材）

| 項目 | 値 |
|---|---|
| Canvas | 64×64 px |
| ゲーム内表示 | 32×32 px |
| Small UI | 16〜20 px |
| Safe Area | 48×48 px（境界 8px のマージン） |
| Outline | 1px Dark |
| Color | 8〜16 色 |
| Light Source | 左上 45°固定 |
| Background | 透明 |

### 武器アイコン（MVP 対象）

| id | display_name | 武器種 |
|---|---|---|
| iron_sword | 鉄の剣 | 大剣 |
| rusted_blade | 錆びた刃 | 大剣 |

### 防具アイコン

| id | display_name |
|---|---|
| leather_armor | 革鎧 |

### 装飾品アイコン

| id | display_name |
|---|---|
| silver_ring | 銀の指輪 |

### 素材アイコン

| id | display_name | category |
|---|---|---|
| relic_shard | 遺跡の欠片 | relic |
| elite_relic_shard | 高品質遺跡の欠片 | relic |
| ancient_bone | 古き骨 | bone |
| cursed_iron | 呪いの鉄 | metal |

### 未鑑定アイコン（共通）

| 種別 | ファイル名 |
|---|---|
| 未鑑定・武器 | `ICO_WPN_Unidentified` |
| 未鑑定・防具 | `ICO_ARM_Unidentified` |
| 未鑑定・装飾品 | `ICO_ACC_Unidentified` |

---

# 4. TileSet Production Rules

## 4-1. グリッド基準

| 項目 | 値 |
|---|---|
| 基本グリッド | 32×32 px |
| Sub-tile | 16×16 px（Decoration / Overlay / Decal のみ） |
| TileSet 形式 | Godot 4 `TileSet` Resource |

## 4-2. 王都跡（royal_ruins）Tileset

**テーマ:** 崩れた石造宮殿・砂と瓦礫の遺跡

| タイル | 内容 | 優先 |
|---|---|---|
| Floor_Stone_01〜03 | 基本石床（亀裂バリエーション） | P0 |
| Floor_Stone_Cracked | 大ヒビ床 | P1 |
| Wall_Stone_01〜02 | 石壁 | P0 |
| Wall_Pillar | 崩れた柱 | P1 |
| Wall_Arch | アーチ壁 | P2 |
| Corner_Inner | 内角 | P0 |
| Corner_Outer | 外角 | P0 |
| Door_Ruined | 壊れた扉 | P1 |
| Deco_Rubble | 瓦礫 | P1 |
| Deco_Torch | たいまつ（光源演出） | P2 |
| Deco_Crack | ひびデカール | P2 |
| Object_Altar | 崩れた祭壇（Event Room） | P1 |
| Object_Chest | 宝箱（Treasure Room） | P0 |
| Object_Exit | 出口門（EXIT Room） | P0 |

## 4-3. 白骸墓地（graveyard）Tileset

**テーマ:** 白い砂と骨・朽ちた墓石の墓地

| タイル | 内容 | 優先 |
|---|---|---|
| Floor_Grave_01〜02 | 砂・草混じりの土床 | P0 |
| Floor_Grave_Dark | 影の多い暗床 | P1 |
| Wall_Grave_01〜02 | 苔むした石壁 | P0 |
| Wall_Tombstone | 墓石・壁面に立つ | P1 |
| Corner_Inner / Outer | 内外角 | P0 |
| Deco_Bone | 骨デカール | P1 |
| Deco_Coffin | 棺 | P2 |
| Object_Bell | 鐘（MID_BOSS Room） | P1 |
| Object_Chest | 宝箱 | P0 |
| Object_Exit | 出口（錆びた鉄格子） | P0 |

## 4-4. タイル共通ルール

- すべてのタイルは **32×32 px** に収める
- タイル間のシームレス接続（隣接タイルとの辺が一致）
- Sub-tile（16×16）は Overlay / Decal 専用
- 自動タイリング（AutoTile）用 Bitflag に対応したマスクを付属する
- 背景は **透明**（Dungeon Room Background と合成を前提とする）

---

# 5. UI Theme Production Guide

## 5-1. 現行テーマ

`assets/ui/mvp_theme.tres`（MVP プレースホルダー）をベースとして Phase3-A Production Theme を作成する。

出力先: `assets/ui/production_theme.tres`

## 5-2. Design Language

| 要素 | 指定 |
|---|---|
| スタイル | Dark Flat Design |
| 縁 | Thin Bronze Border（1〜2px / Color: `#7a5c28`） |
| グリッド | 8px ベースグリッド |
| コントラスト | 高コントラスト（文字は Bone White / Stone Light） |
| 装飾 | 最小限（機能 UI に装飾は入れない） |
| 角丸 | 0〜2px（ハードエッジ優先） |

## 5-3. 画面別 UI 仕様

### HUD（DungeonScene）

| 要素 | 仕様 |
|---|---|
| HP Bar | 赤系グラデーション・キャラ名付き・3 本縦並び |
| Gold 表示 | ICO_Gold アイコン + テキスト |
| ログエリア | 半透明黒背景・最小フォント |
| 部屋情報 | 上部バー / 現在部屋タイプ表示 |

### Equipment / Appraisal

| 要素 | 仕様 |
|---|---|
| リストアイテム | 64×64 アイコン + 名称 + レアリティ色 |
| Unidentified | `ICO_WPN_Unidentified` アイコン・グレーアウト |
| Affix 行 | サブテキスト・14px 相当 |

### Merchant

| 要素 | 仕様 |
|---|---|
| 商品行 | アイコン + 名称 + 価格（ICO_Gold + 数値） |
| Gold 残高 | 常時表示・右上 |
| 購入不可 | 価格テキストを赤でグレーアウト |

### Build Summary（M7 Task037）

| 要素 | 仕様 |
|---|---|
| Job 表示 | Job アイコン + 名称 |
| Stat 行 | ATK / DEF / HP / CRT 縦並び |
| Skill 行 | Primary / Secondary SkillData 名 |

### Codex（M9 候補）

| 要素 | 仕様 |
|---|---|
| カテゴリタブ | 上部タブ（Room / Enemy / Event / Lore / Material） |
| Entry 行 | アイコン + 名称（未発見は `???` で表示） |
| Discovery 率 | プログレスバー |

## 5-4. Font

| 用途 | 推奨 |
|---|---|
| 本文 | 等幅・可読性重視（Bitmap Font 推奨） |
| タイトル | 少し太め・同系 |
| 最小サイズ | 12px 相当（モバイル 1x 換算） |

---

# 6. VFX Production Guide

## 6-1. VFX 設計方針

- VFX は **補助的**。武器・キャラを隠さない
- フレーム数は最小（4〜8 frame）
- Canvas は エフェクト内容に合わせて 32×32 または 64×64
- ループしない（1 shot 再生後に非表示）

## 6-2. MVP VFX 一覧

### 戦闘

| id | 用途 | Canvas | Frame 数 | 色 |
|---|---|---|---|---|
| `FX_Hit_Normal` | 通常命中 | 32×32 | 4 | Stone Light / Ash |
| `FX_Hit_Critical` | クリティカル命中 | 32×32 | 6 | Gold → White |
| `FX_Hit_Bleed` | 出血 | 32×32 | 5 | Blood Red |
| `FX_Hit_Miss` | ミス | 32×32 | 3 | Ash（薄い） |

### 回復・バフ

| id | 用途 | Canvas | Frame 数 | 色 |
|---|---|---|---|---|
| `FX_Heal` | HP 回復 | 32×32 | 5 | Heal Green |
| `FX_Buff_Attack` | 攻撃バフ | 32×32 | 4 | Soul Blue |

### Room 演出

| id | 用途 | Canvas | Frame 数 | 色 |
|---|---|---|---|---|
| `FX_Treasure_Open` | 宝箱開封 | 64×32 | 6 | Gold |
| `FX_Boss_Intro` | ボス登場 | 64×64 | 8 | Blood Red + Stone Dark |

## 6-3. VFX 実装メモ（Phase3-A での接続先）

| FX | 接続先（実装済み） |
|---|---|
| `FX_Hit_Normal` | `DungeonScene._do_party_attack` / 敵ダメージログ |
| `FX_Hit_Critical` | `DungeonScene` クリティカル判定後 |
| `FX_Heal` | `CombatController.heal_party` |
| `FX_Treasure_Open` | `DungeonController.generate_treasure_loot` |

**Phase3-A での実装:** FX は `AnimatedSprite2D` または `GPUParticles2D` で接続。接続実装は Phase3-A Task として別途定義する。

---

# 7. Animation Guidelines

## 7-1. アニメーション共通ルール

- FPS: **6〜12 fps**（ピクセルアート向け）
- ループ: Idle / Walk のみ（それ以外は 1 shot）
- Easing: なし（フレーム単位で直接制御）
- フレームは **SpriteSheet** で管理（横並び、行 = animation）

## 7-2. 冒険者アニメーション

| アニメーション | フレーム数 | ループ | 備考 |
|---|---|---|---|
| Idle | 4 | Yes | わずかな上下動 |
| Attack | 6 | No | 振り / 突き / 射 |
| Hurt | 3 | No | のけぞり |
| Death | 6 | No | 崩れ落ち |

Attack は Job/武器種で差分可（将来）。Phase3-A では **汎用 Attack 1 種** のみ。

## 7-3. 敵アニメーション

| アニメーション | フレーム数 | ループ | 備考 |
|---|---|---|---|
| Idle | 4 | Yes | わずかな揺れ |
| Attack | 4 | No | 攻撃動作 |
| Hurt | 2 | No | |
| Death | 4 | No | 消滅 / 倒れ |

## 7-4. ボスアニメーション

| アニメーション | フレーム数 | ループ | 備考 |
|---|---|---|---|
| Idle | 6 | Yes | 重厚な動き |
| Attack | 8 | No | 大きな動作 |
| Hurt | 3 | No | |
| Death | 8 | No | 崩壊演出 |

## 7-5. SpriteSheet レイアウト

```
行 0: Idle（4〜6 frames）
行 1: Attack（4〜8 frames）
行 2: Hurt（2〜4 frames）
行 3: Death（4〜8 frames）
```

- Sheet サイズ = Canvas × 最大フレーム数（横）× アニメーション数（縦）
- 例: 冒険者 32×32 / 最大 6 frame / 4 アニメーション → `192×128 px`

---

# 8. Asset Naming Convention

## 8-1. プレフィックス一覧

| カテゴリ | プレフィックス | 例 |
|---|---|---|
| Character（冒険者） | `CHR_` | `CHR_Warrior` |
| Enemy（通常敵） | `ENM_` | `ENM_FallenSoldier` |
| Boss | `BOSS_` | `BOSS_RoyalGuardCaptain` |
| NPC | `NPC_` | `NPC_Merchant` |
| Weapon スプライト | `WPN_` | `WPN_Sword_Iron` |
| Weapon アイコン | `ICO_WPN_` | `ICO_WPN_IronSword` |
| Armor アイコン | `ICO_ARM_` | `ICO_ARM_LeatherArmor` |
| Accessory アイコン | `ICO_ACC_` | `ICO_ACC_SilverRing` |
| Material アイコン | `ICO_MAT_` | `ICO_MAT_RelicShard` |
| UI 汎用アイコン | `ICO_` | `ICO_Gold` |
| Tile | `TILE_` | `TILE_RoyalRuins_Floor_01` |
| Sub-tile / Deco | `DECO_` | `DECO_RoyalRuins_Crack_01` |
| VFX | `FX_` | `FX_Hit_Normal` |
| UI Frame | `UI_Frame_` | `UI_Frame_Panel` |
| UI Button | `UI_Btn_` | `UI_Btn_Normal` |
| UI Background | `UI_BG_` | `UI_BG_Dark` |
| SpriteSheet | プレフィックス + `_Sheet` | `CHR_Warrior_Sheet` |

## 8-2. 命名規則詳細

### 一般規則

```
{PREFIX}_{SubCategory}_{Variant}_{Index}
```

| 要素 | ルール |
|---|---|
| PREFIX | 上表のプレフィックス（必須） |
| SubCategory | 武器種・ダンジョン名など（任意） |
| Variant | バリエーション識別（Iron / Stone / 01 など） |
| Index | 同種の複数アセット（01〜99） |
| 区切り | アンダースコア `_` のみ |
| 大文字小文字 | PascalCase（各単語頭大文字） |

### 例

| ファイル名 | 内訳 |
|---|---|
| `ENM_BoneWalker_Sheet.png` | Enemy / BoneWalker / SpriteSheet |
| `ICO_WPN_IronSword.png` | Icon / Weapon / IronSword |
| `TILE_RoyalRuins_Floor_01.png` | Tile / RoyalRuins / Floor / Index01 |
| `TILE_RoyalRuins_Wall_01.png` | Tile / RoyalRuins / Wall / Index01 |
| `FX_Hit_Critical.png` | FX / Hit / Critical |
| `BOSS_RoyalGuardCaptain_Sheet.png` | Boss / RoyalGuardCaptain / Sheet |
| `ICO_ARM_Unidentified.png` | Icon / Armor / Unidentified |
| `NPC_Merchant.png` | NPC / Merchant |

## 8-3. ダンジョン識別子

| ダンジョン | 識別子 |
|---|---|
| 王都跡 | `RoyalRuins` |
| 白骸墓地 | `Graveyard` |
| 地下工廠（将来） | `Factory` |

## 8-4. 禁止事項

- スペース禁止（`CHR Warrior.png` → NG）
- 日本語禁止（ファイル名のみ。表示名は日本語可）
- ハイフン禁止（`CHR-Warrior` → NG）
- 連番なしの「_alt」「_new」「_fix」禁止
- 未使用ファイルをリポジトリに残さない

---

# 9. Phase3-A Asset Master List

## 9-1. 制作対象（Phase3-A 確定スコープ）

### Characters

| ファイル名 | 種別 | Priority |
|---|---|---|
| `CHR_Warrior_Sheet.png` | 冒険者 SpriteSheet | P1 |
| `CHR_Guardian_Sheet.png` | 冒険者 SpriteSheet | P1 |
| `CHR_Scout_Sheet.png` | 冒険者 SpriteSheet | P1 |
| `ENM_FallenSoldier_Sheet.png` | 敵 SpriteSheet | P0 |
| `ENM_RuinedGuard_Sheet.png` | 敵 SpriteSheet | P1 |
| `ENM_RuinsLooter_Sheet.png` | 敵 SpriteSheet | P1 |
| `ENM_RustedKnight_Sheet.png` | 敵 SpriteSheet（elite兼用） | P1 |
| `ENM_BoneWalker_Sheet.png` | 敵 SpriteSheet | P1 |
| `ENM_GraveBat_Sheet.png` | 敵 SpriteSheet | P1 |
| `ENM_HollowGravedigger_Sheet.png` | 敵 SpriteSheet | P1 |
| `ENM_PaleHound_Sheet.png` | 敵 SpriteSheet | P1 |
| `ENM_OssuaryKnight_Sheet.png` | 敵 SpriteSheet（elite専用） | P1 |
| `BOSS_RoyalGuardCaptain_Sheet.png` | ボス SpriteSheet | P0 |
| `BOSS_Gravekeeper_Sheet.png` | ボス SpriteSheet | P1 |
| `NPC_Merchant.png` | NPC 立ち絵 | P2 |

### Weapon Icons

| ファイル名 | 武器 | Priority |
|---|---|---|
| `ICO_WPN_IronSword.png` | iron_sword | P0 |
| `ICO_WPN_RustedBlade.png` | rusted_blade | P0 |
| `ICO_WPN_Unidentified.png` | 未鑑定共通 | P0 |

### Armor / Accessory Icons

| ファイル名 | アイテム | Priority |
|---|---|---|
| `ICO_ARM_LeatherArmor.png` | leather_armor | P0 |
| `ICO_ARM_Unidentified.png` | 未鑑定防具 | P0 |
| `ICO_ACC_SilverRing.png` | silver_ring | P0 |
| `ICO_ACC_Unidentified.png` | 未鑑定装飾品 | P0 |

### Material Icons

| ファイル名 | 素材 | Priority |
|---|---|---|
| `ICO_MAT_RelicShard.png` | relic_shard | P1 |
| `ICO_MAT_EliteRelicShard.png` | elite_relic_shard | P1 |
| `ICO_MAT_AncientBone.png` | ancient_bone | P1 |
| `ICO_MAT_CursedIron.png` | cursed_iron | P2 |

### UI Icons

| ファイル名 | 用途 | Priority |
|---|---|---|
| `ICO_Gold.png` | Gold 表示全般 | P0 |
| `ICO_HP.png` | HP 表示 | P0 |
| `ICO_ATK.png` | 攻撃力表示 | P1 |
| `ICO_DEF.png` | 防御力表示 | P1 |
| `ICO_CRT.png` | クリティカル率表示 | P1 |

### Tiles

| ファイル名 | ダンジョン | Priority |
|---|---|---|
| `TILE_RoyalRuins_Floor_01.png` | 王都跡 | P0 |
| `TILE_RoyalRuins_Floor_02.png` | 王都跡 | P1 |
| `TILE_RoyalRuins_Floor_Cracked.png` | 王都跡 | P1 |
| `TILE_RoyalRuins_Wall_01.png` | 王都跡 | P0 |
| `TILE_RoyalRuins_Wall_02.png` | 王都跡 | P1 |
| `TILE_RoyalRuins_Corner_Inner.png` | 王都跡 | P0 |
| `TILE_RoyalRuins_Corner_Outer.png` | 王都跡 | P0 |
| `TILE_Graveyard_Floor_01.png` | 白骸墓地 | P1 |
| `TILE_Graveyard_Floor_02.png` | 白骸墓地 | P1 |
| `TILE_Graveyard_Wall_01.png` | 白骸墓地 | P1 |
| `TILE_Graveyard_Wall_Tombstone.png` | 白骸墓地 | P1 |
| `TILE_Graveyard_Corner_Inner.png` | 白骸墓地 | P1 |
| `TILE_Graveyard_Corner_Outer.png` | 白骸墓地 | P1 |

### Objects / Props

| ファイル名 | 用途 | Priority |
|---|---|---|
| `OBJ_TreasureChest_Closed.png` | Treasure Room | P0 |
| `OBJ_TreasureChest_Open.png` | 開封後 | P1 |
| `OBJ_ExitGate_RoyalRuins.png` | EXIT Room（王都跡） | P0 |
| `OBJ_ExitGate_Graveyard.png` | EXIT Room（白骸墓地） | P1 |
| `OBJ_Altar_Ruined.png` | Event Room（崩れた祭壇） | P1 |

### VFX

| ファイル名 | 用途 | Priority |
|---|---|---|
| `FX_Hit_Normal.png` | 通常命中 | P1 |
| `FX_Hit_Critical.png` | クリティカル命中 | P1 |
| `FX_Hit_Bleed.png` | 出血 | P2 |
| `FX_Heal.png` | 回復 | P1 |
| `FX_Buff_Attack.png` | 攻撃バフ | P2 |
| `FX_Treasure_Open.png` | 宝箱開封 | P2 |

### UI Frames

| ファイル名 | 用途 | Priority |
|---|---|---|
| `UI_Frame_Panel.png` | 汎用パネル背景 | P0 |
| `UI_Btn_Normal.png` | ボタン通常状態 | P0 |
| `UI_Btn_Pressed.png` | ボタン押下状態 | P0 |
| `UI_Btn_Disabled.png` | ボタン無効状態 | P0 |
| `UI_BG_Dark.png` | シーン背景 | P0 |

---

# 10. Suggested Decisions（採番なし）

| 項目 | 内容 | 理由 |
|---|---|---|
| Phase3-A Scope Adoption | 本 Proposal をスコープとして正式採用 | Phase3-A 実装開始前に必要 |
| Production Theme 分離 | `mvp_theme.tres` → `production_theme.tres` への移行方法確認 | 既存シーンへの影響を事前把握 |
| Boss Canvas 64×64 確定 | ボス 64×64 / 通常敵 32×32 の区別 | DungeonScene の表示エリアとの整合 |
| FX 接続 Task 設定 | FX アセット完成後の Scene 接続を Task として切り出す | Phase3-A Task 構成に影響 |
| Pixel Apprentice 制作順序 | §2-5 の優先順位を Pixel Apprentice へ伝達 | 制作キューの整理 |
| SpriteSheet 行レイアウト確定 | §7-5 の行順を全アセットで統一 | AnimationPlayer 設定の一貫性 |
| TileSet AutoTile 方式確認 | Godot 4 TileSet の AutoTile vs 手動マッピング | Pixel Apprentice の出力形式に影響 |

---

# 11. Future（Phase3-A 対象外）

| 項目 | 対象 Phase |
|---|---|
| 地下工廠 Tileset | Phase3-B（3 ダンジョン目） |
| 敵スキル VFX | Phase3-B |
| ボス固有演出 | Phase3-B |
| Legendary 発光エフェクト | Phase3-B |
| Job ジョブ別 Attack アニメ | Phase3-B |
| Codex カテゴリアイコン | M9 以降 |
| Affix Cursed 演出 | Phase3-B 以降 |
| UI フルリデザイン | Phase4 Polish |
| BGM / SE | Phase4 以降 |
