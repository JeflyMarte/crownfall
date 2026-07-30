extends GutTest

const _Reforge = preload("res://scripts/equipment/EquipmentReforgeHelper.gd")
const _ERM = preload("res://scripts/equipment/EquipmentRandomMods.gd")


func test_debug_full_unlock_can_reforge_some_weapon() -> void:
	DebugFullUnlock.apply()
	assert_gt(GameState.gold, 0)
	assert_gt(int(GameState.material_inventory.get("relic_shard", 0)), 0)
	assert_gt(int(GameState.material_inventory.get("base_ore", 0)), 0)
	var found: bool = false
	for raw: Variant in GameState.inventory:
		var item: Resource = raw as Resource
		if item == null:
			continue
		var mods: Array = _ERM.get_mods(item)
		for i: int in mods.size():
			if not mods[i] is Dictionary:
				continue
			if not _Reforge.is_mod_reforgeable(mods[i] as Dictionary):
				continue
			var check: Dictionary = _Reforge.can_reforge(item, i)
			assert_true(bool(check.get("ok", false)), str(check) + " weapon=" + str(item.weapon_id))
			found = true
			break
		if found:
			break
	assert_true(found, "debug inventory should have at least one reforgeable weapon mod")
