# 必殺：エリクサー強化＋デッドアイ即時

**ID:** P3-BAL-ULT-ELIXIR-DEADEYE-001  
**日付:** 2026-08-05  
**状態:** 承認（オーナー指示）

## 決定

| # | 内容 |
|---|---|
| 1 | `dead_eye` 詠唱 **なし**（cast_time 0） |
| 2 | `grand_elixir` 詠唱 **なし**（cast_time 0） |
| 3 | `grand_elixir` 回復 **全体各員 20%**（旧16%） |
| 4 | `grand_elixir` に **状態異常解除**（味方生存者のデバフ全解除・`cleanse` タグ） |
| 5 | タイタンロア追加バフは別途オーナー選定（本 Decision 外） |

## 上書き

- `41_UltimateRoleSplit.md` の grand_elixir 行（詠唱1・旧回復）
- `42_HealMaxHpFraction.md` の grand_elixir 割合

## SSOT

- `resources/skills/dead_eye.tres` / `grand_elixir.tres`
- `BalanceConfig.HEAL_FRAC_GRAND_ELIXIR`
- `DungeonScene._cleanse_all_party_debuffs`
