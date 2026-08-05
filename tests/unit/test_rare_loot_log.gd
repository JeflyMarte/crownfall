extends GutTest

## レリック／レジェンド拾得の戦闘ログ文言。

const _DungeonScene := preload("res://scripts/dungeon/DungeonScene.gd")


func _pick_weapon_id_by_rarity(rarity: int) -> String:
	for data: Variant in DataRegistry.get_all_weapon_data():
		if data == null:
			continue
		if int(data.rarity) != rarity:
			continue
		var wid: String = str(data.id) if "id" in data else ""
		if wid.is_empty() and "weapon_id" in data:
			wid = str(data.weapon_id)
		if wid.is_empty():
			continue
		return wid
	return ""


func test_format_equip_drop_log_legendary_wording() -> void:
	var scene: Node = _DungeonScene.new()
	add_child_autofree(scene)
	var legendary_id: String = _pick_weapon_id_by_rarity(Enums.Rarity.LEGENDARY)
	assert_false(legendary_id.is_empty(), "レジェンド武器が1本以上あること")
	var line: String = scene._format_equip_drop_log("武器", legendary_id, "weapon")
	assert_true(line.begins_with("レジェンド装備入手:"), line)
	assert_false(line.begins_with("L "), line)


func test_format_equip_drop_log_common_keeps_kind() -> void:
	var scene: Node = _DungeonScene.new()
	add_child_autofree(scene)
	var common_id: String = _pick_weapon_id_by_rarity(Enums.Rarity.COMMON)
	if common_id.is_empty():
		common_id = "iron_sword"
	var line: String = scene._format_equip_drop_log("武器", common_id, "weapon")
	assert_true(line.begins_with("武器ドロップ:"), line)


func test_color_log_highlights_relic_and_legend_pickup() -> void:
	var scene: Node = _DungeonScene.new()
	add_child_autofree(scene)
	var relic_bb: String = scene._color_log_tags("レリック入手: 試し")
	assert_true(relic_bb.contains("[color="), relic_bb)
	var leg_bb: String = scene._color_log_tags("レジェンド装備入手: 試し")
	assert_true(leg_bb.contains("[color="), leg_bb)
