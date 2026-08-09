# 宝箱 Gold 難易度別（P3-BAL-TREASURE-GOLD-TIER-001）

**日付:** 2026-08-09  
**状態:** 承認（オーナー指定数値）

## 要旨

宝箱成功の Gold を難易度帯で大きく底上げする。失敗半額は連動。

## 決定

| ID | 決定 | 理由 |
|---|---|---|
| P3-BAL-TREASURE-GOLD-TIER-001-1 | **N=1000／H=3000／NM=5000** | オーナー指定 |
| P3-BAL-TREASURE-GOLD-TIER-001-2 | **SSOT** — `BalanceConfig.TREASURE_GOLD_BY_TIER`／`treasure_gold(tier)` | 成功率と同型 |
| P3-BAL-TREASURE-GOLD-TIER-001-3 | **失敗** — 成功額の半額（従来どおり） | 据置ルール |
| P3-BAL-TREASURE-GOLD-TIER-001-4 | **上書き** — `P3-BAL-DAILY-TREASURE-GOLD-001` の宝箱120G | 本 Decision が正 |

## 非スコープ

- 碑文 Gold（別途相談）
- 宝箱装備確定ルール
- 日課ミッション報酬
