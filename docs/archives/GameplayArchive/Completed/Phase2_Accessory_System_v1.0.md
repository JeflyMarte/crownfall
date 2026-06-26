# Phase2_Accessory_System_v1.0

**Status:** Completed
**Task:** P2-Task010
**Approved By:** DevelopmentHQ
**Version:** v1.0

---

## 概要

Accessory システムの基盤を実装。
Weapon / Armor と同一設計思想（P2-D001）で拡張。

---

## 実装内容

### AccessoryData (Resource)

```
id, display_name, rarity, icon, description
hp_bonus, attack_bonus, defense_bonus, crit_rate_bonus, luck_bonus
```

### AccessoryInstance (Resource)

```
instance_id, accessory_id, is_appraised
```

乱数ロール値なし。効果値は AccessoryData をIDで参照。

### GameState 拡張

```
accessory_inventory: Array = []
equipped_accessory: Resource = null
```

### Save / Load

SaveManager に以下を追加（旧セーブ後方互換）。

- `_serialize_accessory_inventory()`
- `_serialize_equipped_accessory()`
- `_deserialize_accessory_inventory()`
- `_restore_equipped_accessory()`

### Equipment

- EquipmentController: `get_appraised_accessories()`, `equip_accessory()`
- EquipmentScene: 装飾品枠（LabelAccessoryEquipped / AccessoryList）
- BaseScene: LabelAccessoryEquipped 追加

---

## 変更ファイル

```
scripts/data/AccessoryData.gd              新規
scripts/domain/AccessoryInstance.gd        新規
scripts/autoload/GameState.gd
scripts/save/SaveManager.gd
scripts/equipment/EquipmentController.gd
scripts/equipment/EquipmentScene.gd
scenes/equipment/EquipmentScene.tscn
scripts/base/BaseScene.gd
scenes/base/BaseScene.tscn
```
