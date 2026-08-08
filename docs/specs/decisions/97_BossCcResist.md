# ボス／エリート CC（行動SKIP）耐性 案A

**ID:** P3-BAL-BOSS-CC-RESIST-001  
**日付:** 2026-08-09  
**状態:** 承認（オーナー GO・案A）

## 要旨

ボスに行動SKIP系が雑魚と同強度で効きすぎる。耐性を付け、複数状態の重ね抽選もやめる。

## 確定

### 1. SKIP 抽選は1行動1回

付与中の SKIP 系から **最大確率を1つ** 取り、1回だけ `randf` する。  
（恐怖＋冷却の二重抽選を廃止）

対象確率の取り方:

- `skip_action_chance > 0` → その値  
- それ以外で `interval_multiplier > 1`（鈍化）→ 代理 **0.5**

### 2. 敵ランク耐性（`EnemyType`）

| ランク | SKIP 確率倍率 | スタン duration |
|---|---|---|
| BOSS | **×0.5** | **1 tick**（通常2→短縮） |
| ELITE | **×0.75** | 据置（2） |
| NORMAL／召喚連れ | ×1.0 | 据置 |

例（ボス）: スタン実効50%・1刻／恐怖・冷却 25%／鈍化代理 25%／感電 15%。

味方への状態・ボス以外の雑魚は変更なし。

## SSOT

- `scripts/combat/StatusResolver.gd`（1回抽選）
- `scripts/combat/CombatController.gd`（ランク倍率・スタン短縮）
- `scripts/combat/BalanceConfig.gd`（定数）
