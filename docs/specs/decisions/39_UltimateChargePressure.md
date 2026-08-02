# 必殺チャージ圧力（ELITE／BOSS）

**Status:** Decision 承認済（2026-08-02 — オーナー「Aで」＝推奨F）  
**Impl:** `P3-BAL-ULTIMATE-PRESSURE-001`  
**関連:** P3-COMBAT-GAUGE-001／P3-BAL-ULTIMATE-TIME-001／`46_UltimateChargeTime.md`／P3-BAL-ELITE-BOSS-PRESSURE-001

---

## 1. 方針

ボス／エリートで必殺が乱発されやすい問題を、強敵部屋だけ抑える。  
基本チャージは **時間制**（`46`）。本 Decision はその速度／持ち越しへの圧力。

| 原則 | 内容 |
|---|---|
| 対象 | **ELITE／BOSS のみ** |
| 雑魚 COMBAT | 圧力なし（時間25秒ベース） |
| レリック／武器倍率 | 据置（圧力倍率の外側で乗算） |
| ゼロリセット | しない（半減まで） |

---

## 2. 確定値

| 項目 | 値 |
|---|---|
| 入場時ゲージ | ×**0.5**（`ULTIMATE_CHARGE_PRESSURE_ENTER_MULT`） |
| 戦中チャージ速度 | ×**0.5**（時間／flat 共通・`ULTIMATE_CHARGE_PRESSURE_MULT`） |
| 基本 | `ULTIMATE_CHARGE_FILL_SECONDS`（通常50秒。ダメ係数は廃止） |

---

## 3. スコープ外

- 1戦闘1回上限
- 戦闘内「撃ったあと減衰」
