# 降臨イベント群れ率（P3-BAL-DESCENT-SWARM-001）

**Status:** Decision 承認済（2026-08-02 — オーナー「降臨はノーマルでも群れ率を上げて」）  
**Impl:** `P3-BAL-DESCENT-SWARM-001`  
**関連:** P3-BAL-SWARM-002／P3-DG-CHRONOS-DESCENT-001／P3-DG-VALGARD-DESCENT-001

---

## 1. 方針

時間帯降臨（時環／境界）は本編ノーマルの群れ率（0.45）だと薄い。  
**ノーマルでも群れを厚く**し、曜日イベント帯より一段多くする。

| 項目 | 確定 |
|---|---|
| 対象 | `EventDungeonSchedule.uses_hourly_windows`（現状 chronos／valgard） |
| 率 | `DESCENT_EVENT_SWARM_CHANCE=0.72`（キャップ前。ティア倍率は乗算） |
| 頭数 | 2〜4（上限5・ティア size bonus 可） |
| 優先 | tres の `forced_swarm_chance>=0` があればデータ側を優先 |
| 除外 | 安全優先半減・序盤群れ緩和は適用しない |
| 据置 | 曜日イベント forced_swarm・影狩・本編 |

---

## 2. SSOT

`BalanceConfig.DESCENT_EVENT_*` ／ `DungeonController._is_descent_event_dungeon`
