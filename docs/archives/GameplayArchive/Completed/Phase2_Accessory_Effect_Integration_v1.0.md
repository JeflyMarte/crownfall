# Phase2_Accessory_Effect_Integration_v1.0

**Status:** Completed
**Task:** P2-Task012
**Approved By:** DevelopmentHQ
**Version:** v1.0

---

## 概要

AccessoryData の効果値を戦闘・ステータス・UIへ統合。
Weapon / Armor / Accessory の装備拡張設計（P2-D001）を戦闘ループへ完結させた。

---

## 実装内容

### 効果値適用

| 効果 | 適用先 | 実装 |
|---|---|---|
| hp_bonus | player_max_hp | BASE_HP + armor.hp + acc.hp |
| attack_bonus | _calc_damage() | weapon.rolled_attack + acc.attack_bonus |
| defense_bonus | _calc_enemy_damage() | armor.rolled_defense + acc.defense_bonus |
| crit_rate_bonus | _calc_damage() | weapon.critical_rate + acc.crit_rate_bonus |
| luck_bonus | _get_effective_stats() | 保持・表示のみ（将来接続） |

### 戦闘計算式（確定版）

```
player_max_hp = BASE_PLAYER_HP(50) + armor.hp_bonus + accessory.hp_bonus

damage = weapon.rolled_attack(or FALLBACK=10) + accessory.attack_bonus
crit_rate = weapon.critical_rate + accessory.crit_rate_bonus
クリティカル時: damage = int(damage * 1.5)

total_defense = armor.rolled_defense + accessory.defense_bonus
final_enemy_dmg = max(1, enemy.attack - total_defense)
```

### アーキテクチャ

DungeonScene に `_cache_accessory_data()` を追加。ダンジョン入室時に AccessoryData を1回 `load()` してキャッシュ（毎攻撃 load 回避）。

`_get_effective_stats()` を追加。hp / attack / defense / crit_rate / luck を一箇所で集約計算。将来の Loot / Appraisal 接続ポイント。

### Combat Log

「防具軽減」→「軽減」へ変更（Armor + Accessory 合算値を表示するため）。

### Equipment UI

装飾品表示: `装飾品: silver_ring  HP+5  ATK+0  DEF+0  CRT+2%  LCK+0.1`

---

## 変更ファイル

```
scripts/dungeon/DungeonScene.gd
scripts/equipment/EquipmentScene.gd
scripts/appraisal/AppraisalScene.gd
```
