extends GutTest

## P3-EQ-PET-HEAL-BUILD-001 — ペット／ヒーラービルド装備（Decision 54）


func test_pet_healer_l_defs() -> void:
	var mantle: Resource = DataRegistry.get_armor_data("beastcall_mantle")
	assert_not_null(mantle)
	assert_eq(str(mantle.fixed_passive_id), "eq_beastcall_mantle")
	var robe: Resource = DataRegistry.get_armor_data("field_salve_robe")
	assert_not_null(robe)
	assert_eq(str(robe.fixed_passive_id), "eq_field_salve_robe")
	var staff: Resource = DataRegistry.get_weapon_data("mendweaver_staff")
	assert_not_null(staff)
	assert_eq(str(staff.fixed_passive_id), "eq_wpn_mendweaver_staff")
	assert_eq(str(staff.weapon_type), "staff")
	var pet_def: Dictionary = CombatPassives.get_def("eq_beastcall_mantle")
	assert_eq(float(pet_def.get("pet_outgoing_mult", 0.0)), 1.18)
	var heal_wpn: Dictionary = CombatPassives.get_def("eq_wpn_mendweaver_staff")
	assert_eq(float(heal_wpn.get("heal_power_mult", 0.0)), 1.22)
	var heal_arm: Dictionary = CombatPassives.get_def("eq_field_salve_robe")
	assert_eq(float(heal_arm.get("heal_power_mult", 0.0)), 1.15)


func test_mid_e_stairs() -> void:
	var whistle: Resource = DataRegistry.get_accessory_data("pack_whistle_charm")
	assert_not_null(whistle)
	assert_eq(int(whistle.rarity), Enums.Rarity.EPIC)
	assert_eq(str(whistle.fixed_passive_id), "eq_pack_whistle_charm")
	var band: Resource = DataRegistry.get_accessory_data("salve_band")
	assert_not_null(band)
	assert_eq(int(band.rarity), Enums.Rarity.EPIC)
	assert_eq(str(band.fixed_passive_id), "eq_salve_band")
	assert_eq(float(CombatPassives.get_def("eq_pack_whistle_charm").get("pet_outgoing_mult", 0.0)), 1.08)
	assert_eq(float(CombatPassives.get_def("eq_salve_band").get("heal_power_mult", 0.0)), 1.08)


func test_mid_e_in_biome_pools() -> void:
	assert_true("pack_whistle_charm" in DataRegistry.get_dungeon_data("whisperwood").accessory_pool)
	assert_true("pack_whistle_charm" in DataRegistry.get_dungeon_data("mistfen").accessory_pool)
	assert_true("salve_band" in DataRegistry.get_dungeon_data("mourngate").accessory_pool)
	assert_true("salve_band" in DataRegistry.get_dungeon_data("blackshore").accessory_pool)


func test_icon_paths() -> void:
	for key in [
		"armor:beastcall_mantle",
		"armor:field_salve_robe",
		"weapon:mendweaver_staff",
		"accessory:pack_whistle_charm",
		"accessory:salve_band",
	]:
		assert_false(str(IconPaths.ICON_MAP.get(key, "")).is_empty(), key)
