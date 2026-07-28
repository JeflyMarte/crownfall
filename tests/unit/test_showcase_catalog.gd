extends GutTest

## P3-SHOWCASE-001: スタッフ作例ビルドとセーブ欄。

const ShowcaseCatalogScript = preload("res://scripts/showcase/ShowcaseCatalog.gd")

func test_staff_presets_build_members() -> void:
	var presets: Array = ShowcaseCatalogScript.staff_presets()
	assert_gt(presets.size(), 0, "staff presets exist")
	for raw: Variant in presets:
		assert_true(raw is Dictionary)
		var preset: Dictionary = raw
		var member: Resource = ShowcaseCatalogScript.build_member_from_preset(preset)
		assert_not_null(member, "member for %s" % str(preset.get("id", "")))
		assert_false(str(member.display_name).is_empty())
		assert_false(str(preset.get("player_name", "")).is_empty(), "player_name for %s" % str(preset.get("id", "")))
		assert_false(str(member.job_id).is_empty())
		assert_gt(int(member.level), 0)
		var stats: Dictionary = RosterUiHelper.compute_member_stats(member)
		assert_gt(int(stats.get("hp", 0)), 0)
		## 展示装備はレア枠スタイルを解決できること（装備品一覧と同系）。
		for pair: Array in [
			[member.equipped_weapon, "weapon"],
			[member.equipped_armor, "armor"],
			[member.equipped_accessory, "accessory"],
		]:
			var item: Resource = pair[0]
			if item == null:
				continue
			var cat: String = str(pair[1])
			var data: Resource = null
			match cat:
				"weapon":
					data = DataRegistry.get_weapon_data(str(item.weapon_id))
				"armor":
					data = DataRegistry.get_armor_data(str(item.armor_id))
				"accessory":
					data = DataRegistry.get_accessory_data(str(item.accessory_id))
			assert_not_null(data, "%s data for %s" % [cat, str(preset.get("id", ""))])
			assert_true("rarity" in data)
			var rarity: int = int(data.rarity)
			var cell_px: int = ShowcaseUiTokens.EQUIP_CELL_PX
			var style: StyleBox = EquipmentUiTokens.rarity_slot_style(rarity, false, cell_px)
			assert_not_null(style)
			if rarity != Enums.Rarity.SET:
				assert_false(EquipmentUiHelper.rarity_stars_text(rarity).is_empty())


func test_showcase_equip_cell_size_matches_catalog_style_inputs() -> void:
	## 一覧セルより小さいが、レア枠／inset が壊れない下限を維持。
	assert_gte(ShowcaseUiTokens.EQUIP_CELL_PX, 64)
	assert_eq(ShowcaseUiTokens.EQUIP_ICON_OFFSETS.size(), 3)


func test_showcase_member_id_roundtrip_helpers() -> void:
	var prev: String = GameState.showcase_member_id
	GameState.set_showcase_member_id("  adventurer_0  ")
	assert_eq(GameState.showcase_member_id, "adventurer_0")
	GameState.set_showcase_member_id("")
	assert_eq(GameState.showcase_member_id, "")
	GameState.showcase_member_id = prev
