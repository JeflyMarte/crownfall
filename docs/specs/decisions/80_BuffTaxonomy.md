# バフ分類見直し（推奨パッケージ）

**ID:** P3-BAL-BUFF-TAXONOMY-001  
**日付:** 2026-08-05  
**状態:** 承認（オーナー「全て推奨値」）

## 決定

| # | 内容 |
|---|---|
| 1 | `empower_minor` 表示名 **小さな鼓舞→小鼓舞**（id 据置。旧表記は alias） |
| 2 | **鼓舞**＝味方の攻バフ（×1.30・被ダメ据置）／**激昂**＝主に敵の狂化（×1.50・被ダメ×1.25） |
| 3 | `empower_pet`（相棒鼓舞）＝与ダメ **×1.30**＋被ダメ **×0.85**・持続4（本鼓舞並み火力＋守り） |
| 3b | **追記 2026-08-06** — 相棒鼓舞スキルにペット **maxHP 10%** 回復を付帯（`pet_maxhp_heal`／`HEAL_FRAC_PET_BOND_RALLY`） |
| 4 | レジェンド／UI一行は攻守両方あるとき併記 |

## 確定値

| ID | 表示 | 与ダメ | 被ダメ | tick |
|---|---|---:|---:|---:|
| `empower_minor` | 小鼓舞 | ×1.15 | ×1.0 | 3 |
| `empower` | 鼓舞 | ×1.30 | ×1.0 | 3 |
| `enrage` | 激昂 | ×1.50 | ×1.25 | 3 |
| `empower_pet` | 相棒鼓舞 | ×1.30 | ×0.85 | 4 |

スキル `pet_bond_rally` は上記バフに加え、発動時にペットを **maxHP×10%** 回復する（階層表は `42_HealMaxHpFraction`／`BalanceConfig.HEAL_FRAC_PET_BOND_RALLY`）。

## SSOT

- `resources/status/empower_*.tres` / `enrage.tres`
- `resources/skills/pet_bond_rally.tres`（`pet_maxhp_heal`）
- `BalanceConfig.HEAL_FRAC_PET_BOND_RALLY`
- `StatusEffectLinkHelper`／図鑑・wiki 追随
