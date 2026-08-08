# 固有パッシブ差し替え E-K／R-E／W-C（P3-BAL-PASSIVE-EKREWC-001）

**Status:** Decision 承認済（2026-08-08 — オーナー GO）  
**上書き:** `70_PassiveKitLock.md` のエリアス／レノール／ウォール行。職スキルキットは変更しない。  
**id:** 据置（`elias_field_elixir`／`lenore_seal_echo`／`garm_caravan_guard`）

---

## 1. 確定

| キャラ | 案 | display_name | 効果 |
|---|---|---|---|
| エリアス | E-K | 野営の残り香 | `on_combat_end`・生存味方全体・`heal_max_hp_fraction` **0.20**（エリアス生存時のみ） |
| レノール | R-E | 呪印の増幅 | `outgoing_vs_status_mult` **1.45**（任意デバフ。フィルタ無し） |
| ウォール | W-C | 不屈の鼓動 | 戦闘中 **3秒**ごと maxHP **2%** 自己回復＋`threat_base_add` **70** |

---

## 2. 実装メモ

- クリア時のみ `_finalize_combat_cleared` → `on_combat_end`（全滅／逃走では発火しない）
- `combat_regen_defs_for_party` はキャラパッシブも含む（レリック専用から拡張）
- ウォール旧 `death_save_chance`／レノール旧脆弱付与／エリアス旧開幕最傷回復は廃止

---

## 3. SSOT

- `scripts/combat/CombatPassives.gd`
- `scripts/dungeon/DungeonScene.gd`（`_fire_combat_end_passives`）
- `docs/specs/decisions/70_PassiveKitLock.md`
