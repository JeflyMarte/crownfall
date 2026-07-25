# 深層マイルストーン報酬（P3-DG-ABYSS-001-B）

**Status:** SSOT（Decision 承認済）  
**Approved:** 2026-07-25  
**Parent:** `09_BiomeAbyss.md`

## 方針

案R（推奨数量）＋66Fは **R1（★3限界突破券）**。

## 確定表

| 到達 | 初回 | 2回目以降 |
|---|---|---|
| **33F** | 魔晶石8＋`epic_ore`×5＋`elite_relic_shard`×2 | `epic_ore`×2 |
| **66F** | 魔晶石20＋`ticket_lb_star3`×1＋`epic_ore`×8＋`elite_relic_shard`×3 | 魔晶石5＋`epic_ore`×3 |
| **99F** | 深層限定レジェンド確定（本体は **001-C**）＋魔晶石30＋`elite_relic_shard`×5 | 魔晶石10＋`elite_relic_shard`×3 |
| **100F〜**（10の倍数） | `epic_ore`×1（各階・一生一回） | — |

## 付与ルール

- ラン中に当該階へ到達した時点で付与判定
- 初回フラグは `dungeon_progress[abyss_id].abyss_milestones`
- 魔晶石は Result bank 経由（`last_run_token_reward`）
- 素材は即インベントリ（Result の material gains に載る）

## SSOT 実装

`scripts/dungeon/AbyssMilestoneRewards.gd`
