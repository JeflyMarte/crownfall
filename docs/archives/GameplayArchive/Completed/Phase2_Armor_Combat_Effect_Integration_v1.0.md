# Phase2_Armor_Combat_Effect_Integration_v1.0

**Status:** Completed
**Task:** P2-Task009
**Approved By:** DevelopmentHQ
**Version:** v1.0

---

## 概要

ArmorDataに保持されている防御性能を MVP戦闘へ接続した。
装備Armorが「防御効果のある防具」として機能する状態を実現。

---

## 実装内容

### 防御計算式

```
defense = equipped_armor.rolled_defense（未装備時 0）
final_enemy_dmg = max(1, enemy_attack - defense)
mitigated = enemy_attack - final_enemy_dmg
```

### HP Bonus

ダンジョン入室時（_ready()）に1回計算。

```
player_max_hp = BASE_PLAYER_HP(50) + equipped_armor.hp_bonus
player_hp = player_max_hp
```

### UI

- DungeonScene に LabelPlayerHp 追加（「隊HP: 43 / 70」形式）
- Combat Log に軽減ログ追加（「敵の攻撃: 12 → 防具軽減 5 → 7ダメージ」形式）

### 対象外（将来 Task）

- Resistance（属性ダメージ接続）
- Weight（速度・回避補正）
- プレイヤーHP0時のゲームオーバー

---

## 変更ファイル

```
scripts/dungeon/DungeonScene.gd
scenes/dungeon/DungeonScene.tscn
```
