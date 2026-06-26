# Phase2 Art Direction v1.1

**Status:** Approved
**Approved By:** DevelopmentHQ
**Version:** v1.1
**Source:** Phase2_Art_Direction_Proposal_v1.1

---

# Purpose

本仕様は Phase2（Alpha）以降で使用するアートディレクションの承認済み仕様である。

対象

- UI
- ドット絵
- キャラクター
- 武器
- 背景
- タイルセット
- エフェクト
- カラーパレット

Pixel Apprentice の制作基準として使用する。

---

# Core Vision

「静かな滅び」と「武器が主役」のダークファンタジー

優先順位

1. 視認性
2. 武器の存在感
3. プレイアビリティ
4. 制作効率
5. 世界観

---

# UI

- Dark Flat Design
- Thin Bronze Border
- Theme Resource運用
- 8px Grid
- High Contrast
- 装飾最小限

---

# Pixel Art

- Pixel Perfect
- Filter Off
- Mipmaps Off
- Anti-Aliasing禁止
- 1px Outline
- 8〜16色
- 2〜3段階シェーディング

---

# Character

Canvas: 32×32 px
Draw Size: 24〜28 px

Animation

- Idle
- Walk
- Attack
- Pickup
- Death

---

# Weapon

制作サイズ: 64×64 px
ゲーム内表示: 32×32 px

武器はゲーム全体の主役とする。

素材表現

- Iron
- Steel
- Bone
- Crystal
- Ancient

Legendaryのみ発光。

---

# Tiles

基本グリッド: 32×32 px

16×16は

- Decoration
- Overlay
- Decal
- Sub Tile

用途のみ。

---

# Color

低彩度・暗色中心。

Accent

- Gold
- Blue
- Green
- Red

---

# Effects

- Dust
- Slash
- Hit
- Spark
- Pickup

---

# Naming Rules

- CHR_Player
- WPN_Sword_Iron
- TILE_Floor_01
- ICO_Gold

Gameplay仕様と命名規則を統一する。

---

# Production Priority

1. UI
2. Weapon Icons
3. Player
4. Enemy
5. Tileset
6. Background
7. Effects

---

# Approved Decisions

- 32×32グリッドを維持する。
- 武器制作サイズは64×64、ゲーム内表示は32×32とする。
- Pickupを基本アニメーションへ含める。
- Gameplay仕様と命名規則を統一する。
- 武器をアート上の主役とする。
