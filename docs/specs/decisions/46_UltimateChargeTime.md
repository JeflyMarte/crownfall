# 必殺チャージ＝戦闘時間制

**Status:** Decision 承認済（2026-08-02 — オーナー GO＝案A）  
**Impl:** `P3-BAL-ULTIMATE-TIME-001`  
**関連:** P3-COMBAT-GAUGE-001（上書き）／P3-BAL-ULTIMATE-PRESSURE-001／`39_UltimateChargePressure.md`  
**追記（2026-08-05）:** 全部屋100秒統一 → `78_UltimateChargeUnify100.md`

---

## 1. 方針

与ダメ／被ダメ連動は火力インフレで後半必殺が連打化するため廃止する。  
**戦闘中・生存中の時間**だけで溜まる。

| 原則 | 内容 |
|---|---|
| 溜まり方 | 戦闘クロック（×1 基準秒。速度倍率込み・一時停止除外） |
| ダメージ | 与／被ともチャージに使わない |
| flat | 開幕／クリ発火などの `ultimate_charge_flat` は据置 |
| レリック／武器倍率 | `ultimate_charge_dealt_mult` 鍵は互換維持し、**チャージ速度**に適用 |

---

## 2. 確定値

| 項目 | 値 |
|---|---|
| 満タン目安（全部屋） | **100 秒**（`ULTIMATE_CHARGE_FILL_SECONDS`・P3-BAL-ULTIMATE-UNIFY-100-001） |
| 上限 | 100（`ULTIMATE_CHARGE_MAX`） |
| ELITE／BOSS 入場 | 減衰なし（圧力×1.0） |
| ELITE／BOSS 戦中 | 通常と同速（圧力×1.0） |
| 発動後 | 0 に戻して再チャージ |

---

## 3. 上書き

| 旧 | 新 |
|---|---|
| P3-COMBAT-GAUGE-001-3／4（与ダメ・被ダメ係数） | 本 Decision |
| `39` 「基本係数 DEALT_K／TAKEN_K 据置」 | 係数削除。圧力は時間速度に掛かる |

---

## 4. SSOT

- `Constants.ULTIMATE_CHARGE_FILL_SECONDS`
- `CombatController.tick_ultimate_charge_over_time`
- `BalanceConfig.ULTIMATE_CHARGE_PRESSURE_*`
