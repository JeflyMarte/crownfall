# グランヴェル案B＋以降メインボス弱体

**ID:** P3-BAL-GRANVEL-B-LATER-001  
**日付:** 2026-08-07  
**状態:** 承認（オーナー GO・案B＋以降横展開）  
**Overrides:** `75_BossPressureAlignA.md` の該当ボス即時全体×0.75／ATK（グランヴェル以降メイン梯子のみ）

## 要旨

グランヴェルが召喚削除後も過強のため案Bで弱体化し、同じ比率をメイン梯子の後続ボスへ横展開する。  
セルディオン・イベントボスは据置。

## 対象（メイン梯子）

`granvel` → `moldgar` → `nereion` → `eldion` → `chronos_wave`

## 決定

| # | 内容 |
|---|---|
| 1 | ATK — granvel/moldgar/eldion **203→175**、nereion **222→191**、chronos_wave **290→250**（175/203 を乗算・四捨五入） |
| 2 | 即時全体 — 上記5体の圧力AoE **×0.75→0.6** |
| 3 | F1 `skill_weight` の即時全体 **2.2→1.6**（呼び出し・大技・Hex は据置） |
| 4 | 据置 — Hex×0.25／通常薙ぎ×1.0／大技×2.0／セルディオン咆哮×0.75／イベントボス |

## 即時全体スキル

| ボス | スキル |
|---|---|
| granvel | `enemy_granvel_verdant_wave` |
| moldgar | `enemy_moldgar_abyss_surge` |
| nereion | `enemy_nereion_tidal_wail` |
| eldion | `enemy_eldion_glacial_breath` |
| chronos_wave | `enemy_chronos_wave_resonance` |

## SSOT

- `resources/enemies/{granvel,moldgar,nereion,eldion,chronos_wave}.tres`
- 上記スキル `.tres`
- `CombatBossPhases.gd` F1 重み
