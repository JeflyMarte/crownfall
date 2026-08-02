# ボス開幕オーラ＋テンポ／火力（案A）（P3-BAL-BOSS-AURA-A-001）

**Status:** Decision 承認済（2026-08-02 — オーナー「案Aでいきましょう。火力もっと上げていい」）  
**Impl:** `P3-BAL-BOSS-AURA-A-001`  
**関連:** `38_EliteBossPressure`／P3-BAL-BOSS-PRESSURE-001／P3-D084

---

## 1. 方針

4対1の CT 戦でボスが行動回数負けする問題を、**開幕デバフ（パッシブ扱い）＋人数連動速度＋ボス火力**で解消する。本編ボスは単体のまま。

| 項目 | 確定 |
|---|---|
| 開幕 | 入場時に当該ボスの `boss_*_hex` 状態を味方全員へ付与 |
| 戦闘中 hex | 維持。CD 8→**6** |
| 速度 | BOSSのみ人数係数（3人×1.0／4人×1.25／5+×1.40） |
| 火力 | `BOSS_ATK_MULT=1.22`＋ボス人数ATK share 0.50 |
| 対象 | 本体ボスのみ（護衛・群れ追加枠にはオーラなし） |
| 据置 | グローバル敵ATK、人数HP補正、必殺圧力、本編ボス単体 |

---

## 2. SSOT

| 定数 | 場所 |
|---|---|
| `BOSS_ATK_MULT` / `BOSS_PARTY_*` / `boss_party_speed_mult` | `BalanceConfig` |
| 開幕付与 | `CombatController._apply_boss_opening_aura` |
| hex CD | `resources/skills/boss_*_hex.tres` = 6.0 |

---

## 3. スコープ外

- 本編ボスへの群れ付与
- エリートへの同オーラ横展開
- 状態 duration のボス専用延長（既存 tick を流用）
