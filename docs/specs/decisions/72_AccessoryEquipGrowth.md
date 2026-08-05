# Decision: 装飾の装備Lv成長を厚くする（案A）

**ID:** P3-EQ-ACC-LVL-001  
**日付:** 2026-08-05  
**状態:** 承認（オーナー GO・案A）

## 要旨

装飾は基礎ステが小さく、武防と同じ装備Lv成長率（k=0.04）だと伸びが見えない。  
**装飾のみ成長率を 0.08** にし、武器・防具は据置。

## 決定

| # | 内容 |
|---|---|
| 1 | `EquipmentEnhancer.ACCESSORY_EQUIP_GROWTH_RATE = 0.08` |
| 2 | 武防は `EQUIP_GROWTH_RATE = 0.04` 据置 |
| 3 | レジェンド倍率（×1.25）は装飾にも従来どおり適用 |
| 4 | 適用経路=`effective_accessory_int_bonus` / `effective_accessory_float_bonus` |

## 非目標

- 装飾から装備Lvを外す（案C）
- 平坦加算への切替（案B）
- 武防の成長率変更
