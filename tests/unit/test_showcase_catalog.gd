extends GutTest

## P3-SHOWCASE-001: スタッフ作例ビルドとセーブ欄。

const ShowcaseCatalogScript = preload("res://scripts/showcase/ShowcaseCatalog.gd")

func test_staff_presets_build_members() -> void:
	var presets: Array = ShowcaseCatalogScript.staff_presets()
	assert_eq(presets.size(), 5, "ideal build staff presets")
	var idx: int = 0
	for raw: Variant in presets:
		assert_true(raw is Dictionary)
		var preset: Dictionary = raw
		var member: Resource = ShowcaseCatalogScript.build_member_from_preset(preset)
		assert_not_null(member, "member for %s" % str(preset.get("id", "")))
		assert_false(str(member.display_name).is_empty())
		assert_false(str(preset.get("player_name", "")).is_empty(), "player_name for %s" % str(preset.get("id", "")))
		assert_false(str(preset.get("build_name", "")).is_empty(), "build_name for %s" % str(preset.get("id", "")))
		assert_false(str(preset.get("character_id", "")).is_empty(), "character_id for %s" % str(preset.get("id", "")))
		assert_eq(str(member.id), str(preset.get("character_id", "")))
		idx += 1
		assert_eq(str(preset.get("player_name", "")), "スタッフ%d" % idx)
		var plate: String = ShowcaseCatalogScript.staff_nameplate_text(preset)
		assert_eq(
			plate,
			"%s(%s)" % [str(preset.get("display_name", "")), str(preset.get("build_name", ""))]
		)
		assert_true(plate.begins_with(str(member.display_name)))
		assert_false(str(member.job_id).is_empty())
		assert_eq(int(member.level), 50)
		var skills: Array[String] = GameState.get_equipped_skill_ids(member)
		assert_gte(skills.size(), 1, "equipped skill for %s" % str(preset.get("id", "")))
		var expected_skills: Array = preset.get("equipped_skill_ids", [])
		if expected_skills is Array and not expected_skills.is_empty():
			assert_eq(skills[0], str(expected_skills[0]))
		assert_not_null(member.equipped_weapon)
		assert_eq(str(member.equipped_weapon.weapon_id), str(preset.get("weapon_id", "")))
		assert_eq(int(member.equipped_weapon.equip_level), int(preset.get("equip_level", 50)))
		assert_eq(int(member.equipped_weapon.enhance_level), int(preset.get("enhance_level", 4)))
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
			assert_ne(rarity, Enums.Rarity.MYTHIC, "no mythic in staff ideal builds")
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
	var own_tab: Rect2 = ShowcaseUiTokens.MODE_TAB_OWN
	assert_eq(power.size.x, own_tab.size.x)
	assert_gt(power.position.y, change.position.y)
	assert_gt(change.position.x, equip.position.x)
	assert_lt(change.position.x + change.size.x, stats.position.x + 8.0)
	## ステ枠を食い込まない。
	assert_lt(change.position.x + change.size.x, stats.position.x)


func test_power_frame_asset_exists() -> void:
	assert_true(ResourceLoader.exists(ShowcaseUiTokens.POWER_FRAME))
	var tex: Texture2D = ShowcaseUiTokens.power_frame_texture()
	assert_not_null(tex)


func test_staff_list_button_matches_change_member_rect() -> void:
	## スタッフキャラ＝自分の展示のキャラ変更と同位置。
	assert_eq(ShowcaseUiTokens.STAFF_LIST_RECT, ShowcaseUiTokens.CHANGE_MEMBER_RECT)


func test_skills_rect_sits_below_stats() -> void:
	var stats: Rect2 = ShowcaseUiTokens.STATS_RECT
	var skills: Rect2 = ShowcaseUiTokens.SKILLS_RECT
	assert_eq(skills.position.x, stats.position.x)
	assert_eq(skills.size.x, stats.size.x)
	assert_gt(skills.position.y, stats.position.y + stats.size.y - 1.0)
	assert_lt(skills.position.y + skills.size.y, ShowcaseUiTokens.POWER_RECT.position.y)


func test_showcase_scene_shows_equipped_skill_card() -> void:
	var packed: PackedScene = load("res://scenes/showcase/ShowcaseScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene.call("_set_mode", scene.Mode.STAFF)
	await get_tree().process_frame
	var skills_panel: PanelContainer = scene.get("_skills_panel") as PanelContainer
	assert_not_null(skills_panel)
	assert_true(skills_panel.visible)
	var skills_r: Rect2 = ShowcaseUiTokens.SKILLS_RECT
	assert_eq(skills_panel.position, skills_r.position)
	assert_eq(skills_panel.size, skills_r.size)
	var col: Control = scene.get("_skills_col") as Control
	assert_not_null(col)
	assert_gte(col.get_child_count(), 2)
	var header: Label = col.get_child(0) as Label
	assert_not_null(header)
	assert_eq(header.text, ShowcaseUiTokens.SKILL_HEADER_TEXT)
	var name_lbl: Label = col.get_child(1) as Label
	assert_not_null(name_lbl)
	assert_false(str(name_lbl.text).is_empty())
	assert_ne(name_lbl.text, ShowcaseUiTokens.SKILL_HEADER_TEXT)
	var footer: Label = scene.get("_footer_name") as Label
	assert_not_null(footer)
	assert_eq(footer.text, "アルド(出血主砲ビルド)")


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
	assert_eq(btn.text, "スタッフキャラ")
	assert_false(bool(scene.get_node("StaffStrip").visible))


func test_name_frame_top_rule_sits_above_footer_name() -> void:
	var rule: Rect2 = ShowcaseUiTokens.NAME_FRAME_TOP_RULE
	var footer: Rect2 = ShowcaseUiTokens.FOOTER_RECT
	assert_gte(rule.position.y, footer.position.y - 2.0)
	assert_lt(rule.position.y, footer.position.y + 20.0)
	assert_gt(rule.size.x, 100.0)


func test_empty_own_hides_baked_name_frame_with_mask() -> void:
	## 自慢キャラなしでは焼込名札枠を BG 切り抜きで隠す（黒 ColorRect 禁止）。
	var packed: PackedScene = load("res://scenes/showcase/ShowcaseScene.tscn")
	assert_not_null(packed)
	var prev_id: String = GameState.showcase_member_id
	GameState.set_showcase_member_id("")
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var mask: TextureRect = scene.get("_name_frame_mask") as TextureRect
	assert_not_null(mask)
	assert_true(mask.visible)
	assert_true(mask.texture != null)
	assert_false(bool(scene.get_node("Footer").visible))
	var mask_r: Rect2 = ShowcaseUiTokens.NAME_FRAME_MASK_RECT
	assert_eq(mask.position, mask_r.position)
	assert_eq(mask.size, mask_r.size)
	GameState.showcase_member_id = prev_id


func test_empty_panel_has_no_black_card() -> void:
	var sb: StyleBox = ShowcaseUiTokens.empty_panel_style()
	assert_true(sb is StyleBoxEmpty)


func test_power_frame_center_is_transparent() -> void:
	## 総合戦力の裏の黒マットを除去済みであること。
	var tex: Texture2D = ShowcaseUiTokens.power_frame_texture()
	assert_not_null(tex)
	var img: Image = tex.get_image()
	assert_not_null(img)
	var center: Color = img.get_pixel(img.get_width() / 2, img.get_height() / 2)
	assert_lt(center.a, 0.05, "power frame fill must be clear")
