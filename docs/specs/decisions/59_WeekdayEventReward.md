# 曜日イベント撃破報酬×2（P3-BAL-WEEKDAY-EVENT-REWARD-001）

**Status:** Decision 承認済（2026-08-03 — オーナー「推奨案で go」）  
**Impl:** `P3-BAL-WEEKDAY-EVENT-REWARD-001`  
**関連:** P3-DG-EVENT-WEEKDAY-001／P3-BAL-DESCENT-SWARM-001／`EventDungeonSchedule`

---

## 1. 方針

曜日枠イベントDGは日次1回のため、1ランあたりの EXP／Gold を厚くする。  
時間帯降臨（時環／境界）は別枠のため対象外。

| 項目 | 確定 |
|---|---|
| 対象 | `EventDungeonSchedule.PRIMARY_WEEKDAY`（裂け目／巣／砂金／影狩／群れ道） |
| 除外 | `uses_hourly_windows`（chronos／valgard）・本編・深層 |
| 倍率 | 撃破 EXP／Gold × **2.0**（`BalanceConfig.WEEKDAY_EVENT_REWARD_MULT`） |
| 据置 | 敵ステ・装備／素材ドロップ・日次1回・CLEAR ボーナス経路・野外 `EventSystem` MOD_* |
| ログ | 撃破ログに `[曜日]` タグ |

---

## 2. SSOT

- 定数: `BalanceConfig.WEEKDAY_EVENT_REWARD_MULT`
- 判定: `EventDungeonSchedule.is_weekday_event`
- 適用: `DungeonScene` 撃破報酬（`_award_enemy_kill_at`）
