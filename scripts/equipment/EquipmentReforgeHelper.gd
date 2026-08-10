class_name EquipmentReforgeHelper
extends RefCounted

## 鍛冶屋「焼直し」— 武器／防具／装飾の random_mods 1枠再抽選（P3-FORGE-REFORGE-001）。
## Gold／素材は炉研ぎと同じ（次段。上限到達時は +5 相当 — P3-BAL-REFORGE-MATCH-FORGE-001）。

const _ERM = preload("res://scripts/equipment/EquipmentRandomMods.gd")
const _Enh = preload("res://scripts/equipment/EquipmentEnhancer.gd")


## 炉研ぎの「次に払う段」（+5 済みなら +5 コスト）。
static func forge_step_level(item: Resource) -> int:
	var cur: int = _Enh.get_enhance_level(item)
	if cur >= _Enh.MAX_FORGE_LEVEL:
		return _Enh.MAX_FORGE_LEVEL
	return cur + 1


static func get_gold_cost(item: Resource) -> int:
	if item == null:
		return 0
	return _Enh.get_gold_cost(forge_step_level(item), _Enh.item_rarity(item))


static func get_material_cost(item: Resource) -> Dictionary:
	if item == null:
		return {}
	return _Enh.get_material_cost(forge_step_level(item), _Enh.item_rarity(item))


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
		return fail.call("その効果は選べません")
	var mod: Variant = mods[mod_index]
	if not mod is Dictionary:
		return fail.call("その効果は選べません")
	if not is_mod_reforgeable(mod as Dictionary):
		return fail.call("この効果は焼直しできません")
	var gold_cost: int = get_gold_cost(item)
	var materials: Dictionary = get_material_cost(item)
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
