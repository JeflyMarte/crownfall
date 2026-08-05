# Decision: 敵マルチターゲット攻撃は Threat按分なし（各対象フル威力）

**ID:** P3-BAL-AOE-FULL-001  
**日付:** 2026-08-05（列按分撤廃追記: 2026-08-06）  
**状態:** 承認（オーナー GO・案A／列も撤廃指示）

## 要旨

ボス／敵の `all_party` および列AoE（`party_front`／`party_back`）ダメージが Threat按分で薄まり、薙ぎ・全体の圧が感じられなかった。  
**敵のマルチターゲット攻撃は対象全員にスキル威力フル**を適用する。

## 決定

| # | 内容 |
|---|---|
| 1 | 敵 `target_type=all_party` のダメージシェアは各対象 **1.0**（Threat按分しない） |
| 2 | 列AoE（`party_front`／`party_back`）も各対象 **1.0**（Threat按分しない） |
| 3 | スキル側 `power_multiplier`（吐息×0.5・Hex×0.25・薙ぎ×0.4 等）は据置 |
| 4 | **SSOT**＝本 Decision。P3-BAL-COMBAT-AUDIT-001-5（全体も按分）および旧「列は据置」を上書き |

## 非目標

- 吐息／Hex／薙ぎ等の `power_multiplier` 再調整（別 Task）
- 味方の `all_enemies` 与ダメ変更
