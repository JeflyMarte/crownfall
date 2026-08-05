# 必殺チャージ圧力（ELITE／BOSS）

**Status:** Decision 承認済（2026-08-02 — オーナー「Aで」＝推奨F）  
**Impl:** `P3-BAL-ULTIMATE-PRESSURE-001`  
**関連:** P3-COMBAT-GAUGE-001／P3-BAL-ULTIMATE-TIME-001／`46_UltimateChargeTime.md`／P3-BAL-ELITE-BOSS-PRESSURE-001  
**追記（2026-08-05）:** 圧力無効化（×1.0）。全部屋100秒統一 → `78_UltimateChargeUnify100.md`

---

## 1. 方針（履歴）

ボス／エリートで必殺が乱発されやすい問題を、強敵部屋だけ抑える意図だった。  
**現行は圧力オフ**（通常と同じ100秒）。数値の正は `78`。

| 原則（現行） | 内容 |
|---|---|
| 対象 | ELITE／BOSS も **通常と同速** |
| 倍率 | 入場・戦中とも **×1.0** |

---

## 2. 確定値（現行）

| 項目 | 値 |
|---|---|
| 入場時ゲージ | ×**1.0**（`ULTIMATE_CHARGE_PRESSURE_ENTER_MULT`） |
| 戦中チャージ速度 | ×**1.0**（`ULTIMATE_CHARGE_PRESSURE_MULT`） |
| 基本 | `ULTIMATE_CHARGE_FILL_SECONDS`（**100秒**） |

---

## 3. スコープ外

- 1戦闘1回上限
- 戦闘内「撃ったあと減衰」
