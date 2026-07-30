extends GutTest
## デバッグ所持で強化詳細と同様に先頭焼直し枠を自動選択したとき can_reforge が通るか。

const _Reforge = preload("res://scripts/equipment/EquipmentReforgeHelper.gd")
const _ERM = preload("res://scripts/equipment/EquipmentRandomMods.gd")


func test_auto_select_first_mod_enables_reforge_after_debug() -> void:
	DebugFullUnlock.apply()
	assert_gt(GameState.inventory.size(), 0)
	var enabled_count: int = 0
	var sample_fail: String = ""
	for raw: Variant in GameState.inventory:
		var item: Resource = raw as Resource
		if item == null:
			continue
		var mods: Array = _ERM.get_mods(item)
		var idx: int = -1
		for i: int in mods.size():
			if mods[i] is Dictionary and _Reforge.is_mod_reforgeable(mods[i] as Dictionary):
				idx = i
				break
		if idx < 0:
			continue
		var check: Dictionary = _Reforge.can_reforge(item, idx)
		if bool(check.get("ok", false)):
			enabled_count += 1
		elif sample_fail.is_empty():
			sample_fail = "%s idx=%d %s" % [str(item.weapon_id), idx, str(check)]
	assert_gt(enabled_count, 0, sample_fail)
	## 未選択では不可
	var first: Resource = GameState.inventory[0] as Resource
	var no_sel: Dictionary = _Reforge.can_reforge(first, -1)
	assert_false(bool(no_sel.get("ok", false)))
