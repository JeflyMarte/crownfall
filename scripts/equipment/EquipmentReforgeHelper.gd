class_name EquipmentReforgeHelper
extends RefCounted

## 鍛冶屋「焼直し」— 武器／防具／装飾の random_mods 1枠再抽選（P3-FORGE-REFORGE-001）。

const _ERM = preload("res://scripts/equipment/EquipmentRandomMods.gd")
const _Enh = preload("res://scripts/equipment/EquipmentEnhancer.gd")

## P3-BAL-FORGE-GOLD-HEAVY-001: 焼直しも底上げ。L／エンシェント／ミシックは重い。
const GOLD_BY_RARITY: Dictionary = {
	Enums.Rarity.COMMON: 100,
	Enums.Rarity.RARE: 160,
	Enums.Rarity.EPIC: 250,
	Enums.Rarity.LEGENDARY: 500,
	Enums.Rarity.MYTHIC: 800,
	Enums.Rarity.SET: 700,
}


static func get_gold_cost(item_rarity: int) -> int:
	var r: int = clampi(item_rarity, Enums.Rarity.COMMON, Enums.Rarity.SET)
	return int(GOLD_BY_RARITY.get(r, 100))


static func get_material_cost(item_rarity: int) -> Dictionary:
	var r: int = clampi(item_rarity, Enums.Rarity.COMMON, Enums.Rarity.LEGENDARY)
	match r:
		Enums.Rarity.COMMON, Enums.Rarity.RARE:
			return {
				_Enh.COMMON_MATERIAL_ID: 1,
				_Enh.BASE_ORE_ID: 1,
			}
		Enums.Rarity.EPIC:
			return {
				_Enh.COMMON_MATERIAL_ID: 2,
				_Enh.RARE_ORE_ID: 1,
			}
		Enums.Rarity.LEGENDARY:
			return {
				_Enh.COMMON_MATERIAL_ID: 2,
				_Enh.LEGEND_ORE_ID: 1,
			}
		_:
			return {_Enh.COMMON_MATERIAL_ID: 1, _Enh.BASE_ORE_ID: 1}


static func is_mod_reforgeable(mod: Dictionary) -> bool:
	return _ERM.is_mod_reforgeable(mod)


static func can_reforge(item: Resource, mod_index: int) -> Dictionary:
	var fail := func(reason: String) -> Dictionary:
		return {"ok": false, "reason": reason, "gold_cost": 0, "materials": {}}
	if item == null:
		return fail.call("装備が選択されていません")
	var category: String = _Enh.item_category(item)
	if category != "weapon" and category != "armor" and category != "accessory":
		return fail.call("焼直しできない装備です")
	if not bool(item.is_appraised):
		return fail.call("未鑑定の装備は焼直しできません")
	if mod_index < 0:
		var any_reforgeable: bool = false
		for m: Variant in _ERM.get_mods(item):
			if m is Dictionary and is_mod_reforgeable(m as Dictionary):
				any_reforgeable = true
				break
		if not any_reforgeable:
			return fail.call("焼直しできる効果がありません")
		return fail.call("再抽選する効果を選んでください")
	var mods: Array = _ERM.get_mods(item)
	if mod_index >= mods.size():
		return fail.call("効果の選択が不正です")
	var mod: Variant = mods[mod_index]
	if not mod is Dictionary:
		return fail.call("効果の選択が不正です")
	if not is_mod_reforgeable(mod as Dictionary):
		return fail.call("この効果は焼直しできません")
	var rarity: int = _Enh.item_rarity(item)
	var gold_cost: int = get_gold_cost(rarity)
	var materials: Dictionary = get_material_cost(rarity)
	if GameState.gold < gold_cost:
		return fail.call("ゴールドが足りません")
	if not CraftHelper.has_enough_materials(materials):
		return fail.call("素材が足りません")
	return {
		"ok": true,
		"reason": "",
		"gold_cost": gold_cost,
		"materials": materials,
		"category": category,
	}


static func reforge_mod(item: Resource, mod_index: int) -> Dictionary:
	var check: Dictionary = can_reforge(item, mod_index)
	if not bool(check.get("ok", false)):
		return check
	var gold_cost: int = int(check.get("gold_cost", 0))
	var materials: Dictionary = check.get("materials", {})
	var category: String = str(check.get("category", _Enh.item_category(item)))
	var rolled: Dictionary = _ERM.reroll_mod_at(item, mod_index)
	if not bool(rolled.get("ok", false)):
		return {
			"ok": false,
			"reason": str(rolled.get("reason", "焼直しに失敗しました")),
			"gold_cost": gold_cost,
			"materials": materials,
		}
	GameState.gold -= gold_cost
	GameState.consume_materials(materials)
	return {
		"ok": true,
		"reason": "",
		"gold_cost": gold_cost,
		"materials": materials,
		"old_mod": rolled.get("old_mod", {}),
		"new_mod": rolled.get("new_mod", {}),
		"display_name": _Enh.get_display_name(item),
		"category": category,
	}
