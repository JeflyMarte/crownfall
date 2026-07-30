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
			## セル上の文字バッジはロゴ画像へ置換済み（常に空）。
			assert_eq(EquipmentUiHelper.rarity_stars_text(rarity), "")
			if rarity == Enums.Rarity.SET:
				assert_eq(EquipmentUiHelper.rarity_label_text(rarity), "エンシェントレア")
				assert_not_null(EquipmentUiTokens.tier_badge(rarity))
			elif rarity <= Enums.Rarity.EPIC:
				assert_not_null(EquipmentUiTokens.corner_rarity_badge(rarity))
			elif rarity == Enums.Rarity.MYTHIC:
				assert_not_null(EquipmentUiTokens.tier_badge(rarity))
			elif rarity == Enums.Rarity.LEGENDARY:
				assert_not_null(EquipmentUiTokens.tier_badge(rarity))
				assert_null(EquipmentUiTokens.corner_rarity_badge(rarity))


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


func test_power_and_change_member_layout_rects() -> void:
	## 総合戦力＝名札上、キャラ変更＝装備とステのあいだ（やや右寄せ・短め）。
	var power: Rect2 = ShowcaseUiTokens.POWER_RECT
	var change: Rect2 = ShowcaseUiTokens.CHANGE_MEMBER_RECT
	var equip: Rect2 = ShowcaseUiTokens.EQUIP_RECT
	var stats: Rect2 = ShowcaseUiTokens.STATS_RECT
	assert_gt(power.position.y, change.position.y)
	assert_gt(change.position.x, equip.position.x)
	assert_lt(change.position.x + change.size.x, stats.position.x + 8.0)
	## ステ枠を食い込まない。
	assert_lt(change.position.x + change.size.x, stats.position.x)


func test_power_frame_asset_exists() -> void:
	assert_true(ResourceLoader.exists(ShowcaseUiTokens.POWER_FRAME))
	var style: StyleBox = ShowcaseUiTokens.power_frame_style()
	assert_not_null(style)
	assert_true(style is StyleBoxTexture)


func test_staff_list_button_does_not_overlap_power() -> void:
	var staff: Rect2 = ShowcaseUiTokens.STAFF_LIST_RECT
	var power: Rect2 = ShowcaseUiTokens.POWER_RECT
	assert_lt(staff.position.x + staff.size.x, power.position.x + 1.0)
	assert_eq(staff.position.y, power.position.y)


func test_showcase_scene_has_staff_list_button() -> void:
	var packed: PackedScene = load("res://scenes/showcase/ShowcaseScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene.call("_set_mode", scene.Mode.STAFF)
	await get_tree().process_frame
	var btn: Button = scene.get("_btn_staff_list") as Button
	assert_not_null(btn)
	assert_true(btn.visible)
	assert_false(bool(scene.get_node("StaffStrip").visible))


func test_name_frame_top_rule_sits_above_footer_name() -> void:
	var rule: Rect2 = ShowcaseUiTokens.NAME_FRAME_TOP_RULE
	var footer: Rect2 = ShowcaseUiTokens.FOOTER_RECT
	assert_gte(rule.position.y, footer.position.y - 2.0)
	assert_lt(rule.position.y, footer.position.y + 20.0)
	assert_gt(rule.size.x, 100.0)
