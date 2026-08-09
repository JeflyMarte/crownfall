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


func test_whisperwood_is_dot_shell_not_fire() -> void:
	## 霜（火）と被らない。DoT＋DEF厚が本体。
	var shell: Resource = DataRegistry.get_enemy_data("moss_shell")
	assert_not_null(shell)
	assert_gte(int(shell.defense), 110)
	assert_false("fire" in shell.element_weakness)
	assert_eq(str(shell.on_hit_status_id), "poison")
	var widow: Resource = DataRegistry.get_enemy_data("spore_widow")
	assert_not_null(widow)
	assert_false("fire" in widow.element_weakness)
	var hint: String = _Themes.select_hint("whisperwood")
	assert_true(hint.contains("DoT") or hint.contains("毒"), hint)
	assert_false(hint.contains("火属性"), hint)
	var frost_hint: String = _Themes.select_hint("frostridge")
	assert_true(frost_hint.contains("火"), frost_hint)


func test_frostridge_keeps_fire_weak_identity() -> void:
	var raptor: Resource = DataRegistry.get_enemy_data("frost_claw_raptor")
	assert_not_null(raptor)
	assert_true("fire" in raptor.element_weakness)


func test_signature_enemies_wired() -> void:
	assert_eq(str(_Themes.SIGNATURE_ENEMY_IDS["blackshore"]), "black_tide_shark")
	var dread: Resource = DataRegistry.get_enemy_data("black_tide_shark")
	assert_not_null(dread)
	assert_gte(int(dread.attack), 210)
	assert_gte(float(dread.attack_speed), 1.35)
	assert_true("enemy_dread_rally" in dread.skill_ids)
	var frog: Resource = DataRegistry.get_enemy_data("dead_poison_frog")
	assert_not_null(frog)
	assert_true("enemy_mire_toxin_bloom" in frog.skill_ids)
	var shell: Resource = DataRegistry.get_enemy_data("moss_shell")
	assert_not_null(shell)
	assert_gte(int(shell.defense), 150)
	assert_true("enemy_moss_carapace" in shell.skill_ids)
	var raptor: Resource = DataRegistry.get_enemy_data("frost_claw_raptor")
	assert_not_null(raptor)
	assert_gte(int(raptor.attack), 160)
	var haste: Resource = DataRegistry.get_skill_data("enemy_frost_haste")
	assert_not_null(haste)
	assert_eq(str(haste.target_type), "all_allies")
	var mantis: Resource = DataRegistry.get_enemy_data("skullface_mantis")
	assert_not_null(mantis)
	assert_gte(int(mantis.attack), 155)
	var ward: Resource = DataRegistry.get_skill_data("enemy_hull_ward")
	assert_not_null(ward)
	assert_eq(str(ward.target_type), "all_allies")


func test_mire_toxin_amplifies_poison_dot() -> void:
	const _StatusResolver := preload("res://scripts/combat/StatusResolver.gd")
	var resolver = _StatusResolver.new()
	assert_true(resolver.apply_status("party_0", "poison", 1, 0))
	var base_ticks: Array = resolver.tick_unit("party_0")
	assert_eq(base_ticks.size(), 1)
	var base_dmg: int = int(base_ticks[0].get("damage", 0))
	assert_gt(base_dmg, 0)
	resolver.clear_all()
	assert_true(resolver.apply_status("party_0", "poison", 1, 0))
	assert_true(resolver.apply_status("party_0", "mire_toxin", 1, 0))
	var amp_ticks: Array = resolver.tick_unit("party_0")
	assert_eq(amp_ticks.size(), 1)
	var amp_dmg: int = int(amp_ticks[0].get("damage", 0))
	assert_gte(amp_dmg, int(round(float(base_dmg) * 1.35)))
