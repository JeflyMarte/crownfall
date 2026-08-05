# Decision: 敵全体攻撃は Threat按分なし（全員フル威力）

**ID:** P3-BAL-AOE-FULL-001  
**日付:** 2026-08-05  
**状態:** 承認（オーナー GO・案A）

## 要旨

ボス／敵の `all_party` ダメージが Threat按分＋スキル減衰で後衛にほぼ入らず、全体攻撃の圧が感じられなかった。  
**全体攻撃は対象全員にスキル威力フル**を適用する。列AoE（`party_front`／`party_back`）の Threat按分は据置。

## 決定

| # | 内容 |
|---|---|
| 1 | 敵 `target_type=all_party` のダメージシェアは各対象 **1.0**（Threat按分しない） |
| 2 | 列AoE（`party_front`／`party_back`）は従来どおり Threat按分 |
| 3 | スキル側 `power_multiplier`（吐息×0.5・Hex×0.25 等）は据置 |
| 4 | **SSOT**＝本 Decision。P3-BAL-COMBAT-AUDIT-001-5（全体も按分）を上書き |

## 非目標

- 列AoEの按分廃止
- 吐息／Hex の威力再調整（別 Task）
- 味方の `all_enemies` 与ダメ変更
