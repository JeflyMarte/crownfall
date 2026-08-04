# 撃破経験値 ×1.5（P3-BAL-KILL-EXP-150-001）

**Status:** Decision 承認済（2026-08-04 — オーナー案B）  
**定数:** `BalanceConfig.COMBAT_KILL_EXP_MULT`  
**関連:** `P3-BAL-CLEAR-EXP-001`（クリア +25% は積立経由で絶対量も ×1.5）

---

## 1. 方針

| # | 項目 | 確定 |
|---|---|---|
| 1 | 対象 | 戦闘撃破のキャラ EXP（雑魚／エリート／ボス） |
| 2 | 倍率 | **×1.5**（`COMBAT_KILL_EXP_MULT`） |
| 3 | クリアボーナス | **比率 +25% 据置**。撃破プールが ×1.5 のため絶対量も ×1.5 |
| 4 | 据置 | 調査室派遣・装備強化EXP・敵 `exp_reward` 生値・既存の部屋／ティア／曜日等の上乗せ |

---

## 2. SSOT

- `BalanceConfig.COMBAT_KILL_EXP_MULT`
- 付与: `DungeonScene` 撃破報酬（`final_exp`）
- クリア: `DungeonController.apply_clear_exp_bonus()`（変更なし・連動のみ）
