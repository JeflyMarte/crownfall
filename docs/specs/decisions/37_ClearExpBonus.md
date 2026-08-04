# ダンジョンクリア経験値ボーナス（P3-BAL-CLEAR-EXP-001）

**Status:** Decision 承認済（2026-08-02 オーナー GO・案A）  
**定数:** `BalanceConfig.CLEAR_EXP_BONUS_RATIO`  
**関連:** 撃破プール倍率は `63_CombatKillExpMult.md`（P3-BAL-KILL-EXP-150-001）。比率 +25% は据置で絶対量連動。

---

## 1. 目的

完走（CLEAR）に対する育成インセンティブを足す。撃破 EXP のみだとリタイアとの差が薄いため、**クリア時のみ**獲得 EXP にボーナスを乗せる。

---

## 2. 方針（案A）

| 項目 | 内容 |
|---|---|
| 条件 | **CLEAR のみ**（リタイア／全滅はなし） |
| 量 | そのランで積んだ獲得 EXP の **+25%**（四捨五入） |
| 対象 | 出撃パーティ（現行のメンバー別積立と同じ経路） |
| 表示 | Result 情報行に「クリアボーナス +N」。入手経験値はボーナス込み合計 |

---

## 3. 実装メモ

- 付与直前に `DungeonController.apply_clear_exp_bonus()` で `run_exp_reward` と `run_exp_by_member` へ加算
- `GameState.last_run_exp_clear_bonus` は表示用（セーブ不要・ラン揮発）
- 深層リタイア・全滅経路ではボーナスを付けず `last_run_exp_clear_bonus = 0`
