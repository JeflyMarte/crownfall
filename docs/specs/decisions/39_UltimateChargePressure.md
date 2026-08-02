# 必殺チャージ圧力（ELITE／BOSS）

**Status:** Decision 承認済（2026-08-02 — オーナー「Aで」＝推奨F）  
**Impl:** `P3-BAL-ULTIMATE-PRESSURE-001`  
**関連:** P3-COMBAT-GAUGE-001／P3-BAL-ELITE-BOSS-PRESSURE-001

---

## 1. 方針

ボス／エリートで必殺が乱発されやすい問題を、**グローバル係数は据置**のまま、強敵部屋だけ抑える。

| 原則 | 内容 |
|---|---|
| 対象 | **ELITE／BOSS のみ** |
| 雑魚 COMBAT | 据置（持ち越し・係数とも） |
| レリック／武器倍率 | 据置（圧力倍率の外側で乗算） |
| ゼロリセット | しない（半減まで） |

---

## 2. 確定値

| 項目 | 値 |
|---|---|
| 入場時ゲージ | ×**0.5**（`ULTIMATE_CHARGE_PRESSURE_ENTER_MULT`） |
| 戦中チャージ | ×**0.5**（与ダメ／被ダメ／flat 共通・`ULTIMATE_CHARGE_PRESSURE_MULT`） |
| 基本係数 | `ULTIMATE_CHARGE_DEALT_K` / `TAKEN_K` 据置 |

---

## 3. スコープ外

- 1戦闘1回上限
- 戦闘内「撃ったあと減衰」
- グローバル DEALT_K の再変更
