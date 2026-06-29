# Crownfall — Asset Credits

外部アセットの出典・ライセンス記録。CC0 / Public Domain は表記義務なしだが、
再配布元と入手日を管理目的で控える。

## 武器アイコン（AI生成）

- **属性武器インベントリアイコン 6種**（HeaterBlade / FrostBlade / BoltKnife / ApprenticeStaff / HuntingBow / SanctifiedDagger）
  - 生成: Cursor 組み込み画像生成（既存 ICO_WPN_IronSword を参照にスタイル統一）
  - 後処理: 余白トリミング→正方形パディング→64×64 へ縮小（PIL）
  - 配置: `assets/ui/batch2/ICO_WPN_*.png`
  - 作成日: 2026-06-29

## VFX（属性別 命中エフェクト）

- **Spell Effects（Fireball / Icespear / Thundersphere）**
  - Author: StarsteelGaming
  - Source: https://opengameart.org/content/spell-effects-by-starsteelgaming
  - License: Public Domain (CC0 相当)
  - 使用箇所: `assets/vfx/elements/{fire,ice,thunder}/`、
    `resources/animation/FX_Hit_{Fire,Ice,Thunder}.tres`
  - 取得日: 2026-06-29

### 未取得（フォールバック動作中）

- 闇 (`dark`) / 聖 (`holy`) の専用VFXは未配置。
  該当属性は `FX_Hit_Normal` を属性色でティント表示してフォールバックする。
  CC0素材を `resources/animation/FX_Hit_Dark.tres` / `FX_Hit_Holy.tres` に
  追加すれば自動採用される。
