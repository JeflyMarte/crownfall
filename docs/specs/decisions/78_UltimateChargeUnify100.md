# 必殺チャージ＝全部屋100秒統一

**ID:** P3-BAL-ULTIMATE-UNIFY-100-001  
**日付:** 2026-08-05  
**状態:** 承認（オーナー指示）

## 要旨

通常／エリート／ボスで溜まり方が違った必殺ゲージを、**すべて約100秒で満タン**に揃える。

## 決定

| # | 内容 |
|---|---|
| 1 | `ULTIMATE_CHARGE_FILL_SECONDS` **50→100** |
| 2 | ELITE／BOSS 戦中速度圧力 **×0.5→×1.0**（無効化） |
| 3 | ELITE／BOSS 入場持ち越し減衰 **×0.5→×1.0**（無効化） |
| 4 | 上限100・時間制・装備／レリック速度倍率は据置 |

## 上書き

- `46_UltimateChargeTime.md`（通常50秒）
- `39_UltimateChargePressure.md`（ELITE/BOSS×0.5）

## SSOT

- `Constants.ULTIMATE_CHARGE_FILL_SECONDS`
- `BalanceConfig.ULTIMATE_CHARGE_PRESSURE_*`
- `GuideCatalog` COMBAT-G007
