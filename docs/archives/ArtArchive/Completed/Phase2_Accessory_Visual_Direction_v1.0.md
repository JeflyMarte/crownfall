# Phase2_Accessory_Visual_Direction_v1.0

**Status:** Approved

**Approved By:** DevelopmentHQ

**Version:** v1.0

**Destination** `docs/archives/ArtArchive/Completed/`

------------------------------------------------------------------------

# 1. Purpose

本仕様はAccessory
Systemで使用するアクセサリーのビジュアル仕様を定義する。

対象はPixel
Apprenticeによるアセット制作であり、ゲームロジックや実装仕様は含まない。

目的

-   アクセサリーカテゴリの統一
-   武器中心の世界観との整合
-   高い視認性
-   アイコン量産の効率化

------------------------------------------------------------------------

# 2. Art Principles

Accessoryは武器より目立ってはならない。

優先順位

1.  視認性
2.  武器との調和
3.  素材感
4.  レアリティ表現
5.  装飾性

画面の主役は常に武器とする。

------------------------------------------------------------------------

# 3. Accessory Category (MVP)

-   Ring
-   Necklace
-   Charm
-   Talisman

------------------------------------------------------------------------

# 4. Visual Direction

## Primary Shape

  Category   Shape
  ---------- -----------
  Ring       Circle
  Necklace   Drop
  Charm      Bundle
  Talisman   Rectangle

制作サイズ：64×64 px

ゲーム内表示：32×32 px

UI縮小表示：16〜24 px

素材：

-   Iron
-   Bronze
-   Silver
-   Gold
-   Bone
-   Leather
-   Crystal
-   Ancient Stone

レアリティは色ではなく、

-   素材
-   加工
-   装飾
-   発光

で差別化する。

------------------------------------------------------------------------

# 5. Rarity Direction

## Common

鉄・木・革・骨

## Uncommon

金属縁・小宝石

## Rare

大型宝石・軽い光沢

## Epic

複数素材・彫刻・微弱発光

## Legendary

専用シルエット・古代文明・金装飾・明確な発光

------------------------------------------------------------------------

# 6. Icon Specification

-   Canvas：64×64 px
-   Game：32×32 px
-   Small UI：16〜20 px
-   Safe Area：48×48 px
-   Outline：1px Dark
-   Color：8〜16色
-   Highlight：1段階
-   Shadow：2段階
-   Background：Transparent

Godot Import

-   Filter Off
-   Mipmaps Off
-   Repeat Disabled
-   Lossless Compression

Light Source：左上固定

------------------------------------------------------------------------

# 7. UI Display

Equipment / Appraisal / Result / Inventoryで共通仕様を適用。

未鑑定アイコン：

`ICO_ACC_Unidentified`

------------------------------------------------------------------------

# 8. Production Rules

固定事項

-   共通アウトライン
-   共通ライティング
-   共通影方向
-   共通パレット

------------------------------------------------------------------------

# 9. Naming

Asset

-   ACC_Ring\_\*
-   ACC_Necklace\_\*
-   ACC_Charm\_\*
-   ACC_Talisman\_\*

Icon

-   ICO_ACC\_\*
-   ICO_ACC_Unidentified

------------------------------------------------------------------------

# 10. MVP Scope

## Included

-   Ring
-   Necklace
-   Charm
-   Talisman

Common〜Rare

## Excluded

-   Animated Icon
-   Set Effects
-   Legendary UI
-   Aura
-   3D表現

------------------------------------------------------------------------

# 11. Future

-   Animated Icon
-   Legendary Glow
-   Set Items
-   Cursed
-   Relic
-   Unique
-   Seasonal

------------------------------------------------------------------------

# 12. Approved Decisions

-   Accessoryカテゴリは Ring / Necklace / Charm / Talisman を採用
-   制作64×64・表示32×32を標準とする
-   レアリティは素材・加工・装飾・発光で差別化する
-   命名規則は ACC\_\* / ICO_ACC\_\* を採用する
