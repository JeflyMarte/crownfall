# セルディオン（序盤ボス）小幅弱体

**ID:** P3-BAL-SERDION-SOFT-001  
**日付:** 2026-09-06  
**状態:** 承認（オーナー GO・序盤ボスが痛い／エリート据置）  
**Overrides:** `74_SerdionPressureA.md` の ATK145・咆哮×0.75／`86_GranvelBLaterBossNerf.md` の「セルディオン据置」

## 要旨

序盤（モーンゲート）のボス圧が過強とのフィードバック。痛みの主因はボス。  
**エリート護衛は据置。** セルディオンのみ、後続メイン梯子（Decision 86）と同型の小幅弱体を当てる。

## 決定

| # | 内容 |
|---|---|
| 1 | ATK **145→125**（175/203 を乗算・四捨五入。後続梯子と同比率） |
| 2 | 即時全体 `enemy_serdion_roar` **×0.75→0.6** |
| 3 | F1 `skill_weight` の咆哮 **2.2→1.6** |
| 4 | 据置 — Hex×0.25／通常爪×1.7・薙ぎ×1.0／断罪波動×2.0／開幕オーラ／`BOSS_ATK_MULT`／エリート護衛・エリートスキル |

## 対象外

- グランヴェル以降のボス（既に Decision 86）
- イベント／征討ボス
- モーンゲート雑魚・群れルール

## SSOT

- `resources/enemies/serdion.tres`
- `resources/skills/enemy_serdion_roar.tres`
- `scripts/combat/CombatBossPhases.gd`（serdion F1）
