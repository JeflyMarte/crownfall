extends GutTest

## P3-BAL-BIOME-BUILD-THEME-001 — 章別ビルドテーマ

const _Themes = preload("res://scripts/dungeon/BiomeBuildThemes.gd")


func test_hints_exist_for_main_five() -> void:
	for biome_id: String in [
		"mourngate", "whisperwood", "mistfen", "blackshore", "frostridge"
	]:
		var hint: String = _Themes.select_hint(biome_id)
		assert_false(hint.is_empty(), biome_id)
		assert_true(hint.begins_with("傾向:"), biome_id)


func test_abyss_inherits_parent_hint() -> void:
	assert_eq(
		_Themes.select_hint("abyss_mistfen"),
		_Themes.select_hint("mistfen")
	)
	assert_eq(_Themes.select_hint("cosmic_rift"), "")


func test_mistfen_normals_resist_incoming_status() -> void:
	for eid: String in [
		"blood_leech", "marsh_king", "spore_needle_wasp", "great_claw"
	]:
		var data: Resource = DataRegistry.get_enemy_data(eid)
		assert_not_null(data, eid)
		assert_lt(float(data.incoming_status_chance_mult), 1.0, eid)


func test_blackshore_exclusive_atk_above_old_band() -> void:
	## 章専用雑魚は壁テーマ用に ATK を引き上げ済み（旧中央付近 128〜160 超）。
	var data: Resource = DataRegistry.get_enemy_data("samurai_fish")
	assert_not_null(data)
	assert_gte(int(data.attack), 180)


func test_frostridge_exclusive_hp_raised() -> void:
	var data: Resource = DataRegistry.get_enemy_data("oldrex")
	assert_not_null(data)
	assert_gte(int(data.max_hp), 1100)


func test_shared_rock_bison_untouched_by_biome_tips() -> void:
	## 横断種は章尖りの対象外。
	var data: Resource = DataRegistry.get_enemy_data("rock_bison")
	assert_not_null(data)
	assert_almost_eq(float(data.incoming_status_chance_mult), 1.0, 0.001)


func test_whisperwood_shells_are_def_thick_and_fire_weak() -> void:
	var shell: Resource = DataRegistry.get_enemy_data("moss_shell")
	assert_not_null(shell)
	assert_gte(int(shell.defense), 110)
	assert_true("fire" in shell.element_weakness)
	var widow: Resource = DataRegistry.get_enemy_data("spore_widow")
	assert_not_null(widow)
	assert_true("fire" in widow.element_weakness)
	var hint: String = _Themes.select_hint("whisperwood")
	assert_true(hint.contains("火属性"), hint)
	assert_true(hint.contains("殻") or hint.contains("物理"), hint)
