# ビッグコズミックダック Hard+ 展開（P3-ENEMY-BIG-COSMIC-DUCK-002）

**Status:** Decision 承認済（2026-08-03 — オーナー「推奨案で go」）  
**Impl:** `P3-ENEMY-BIG-COSMIC-DUCK-002`  
**関連:** P3-ENEMY-BIG-COSMIC-DUCK-001／P3-WANDER-002／`WanderingEnemyConfig`／`cosmic_rift`

---

## 1. 方針

| # | 項目 | 確定（推奨案 A） |
|---|---|---|
| 1 | 通常DG Hard+ | 放浪コズミックダック抽選成功時にビッグへ昇格（H **25%**／NM **40%**） |
| 2 | 対象 | 放浪が有効な本編のみ（裂け目は `disable_wandering` 据置） |
| 3 | 裂け目 Hard+ | COMBAT で通常ダック経路の代わりにビッグ **1〜2**（H **20%**／NM **30%**）。最終ボスは据置1体 |
| — | 据置 | Normal・敵ステ本体・日次1回・放浪逃走はビッグは逃走しない（既存 tres） |

---

## 2. SSOT

- `WanderingEnemyConfig.UPGRADE_TO_BIG_CHANCE_*`／`maybe_promote_cosmic_duck_to_big`
- `WanderingEnemyConfig.RIFT_BIG_COMBAT_*`／`roll_cosmic_rift_big_combat_count`
- 適用: `try_roll_wandering_id`（計画・ライブ共通）／`DungeonController._try_cosmic_rift_big_combat_group`
