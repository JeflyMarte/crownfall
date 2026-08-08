extends GutTest

const _PassiveIconHelper = preload("res://scripts/ui/PassiveIconHelper.gd")


func test_battle_fervor_icon_loads() -> void:
	var icon: Control = _PassiveIconHelper.make_icon("battle_fervor")
	if not ResourceLoader.exists("res://assets/ui/passives/ICO_PASSIVE_BattleFervor.png"):
		pass_test("passive art not installed")
		return
	assert_not_null(icon)
	assert_true(icon is TextureRect)


func test_foresight_icon_loads() -> void:
	if not ResourceLoader.exists("res://assets/ui/passives/ICO_PASSIVE_Foresight.png"):
		pass_test("foresight art not installed")
		return
	assert_not_null(_PassiveIconHelper.make_icon("foresight"))


func test_unknown_passive_uses_fallback_icon() -> void:
	if not ResourceLoader.exists(_PassiveIconHelper.FALLBACK_PATH):
		pass_test("fallback passive art not installed")
		return
	assert_not_null(_PassiveIconHelper.make_icon("nonexistent_passive"))


func test_elias_field_elixir_uses_hex_not_sword_fallback() -> void:
	var hex: String = "res://assets/ui/skills/base/ICO_SKILL_BASE_Hex_fg.png"
	if not ResourceLoader.exists(hex):
		pass_test("hex art not installed")
		return
	var path: String = _PassiveIconHelper.resolve_texture_path("elias_field_elixir")
	assert_eq(path, hex)
	assert_ne(path, _PassiveIconHelper.FALLBACK_PATH)


func test_base_roster_passive_icons_are_thematic() -> void:
	var expected: Dictionary = {
		"ald_royal_flame": "res://assets/ui/status/ICO_STA_Bleed.png",
		"riva_lone_focus": "res://assets/ui/skills/base/ICO_SKILL_BASE_Mark_fg.png",
		"elias_field_elixir": "res://assets/ui/skills/base/ICO_SKILL_BASE_Hex_fg.png",
		"galen_sacred_bastion": "res://assets/ui/passives/ICO_PASSIVE_Bulwark.png",
		"mirei_swarm_resonance": "res://assets/ui/status/ICO_STA_Poison.png",
	}
	for pid: String in expected.keys():
		var want: String = str(expected[pid])
		if not ResourceLoader.exists(want):
			pass_test("missing art for %s" % pid)
			return
		assert_eq(_PassiveIconHelper.resolve_texture_path(pid), want, pid)


func test_gacha_character_passives_do_not_fall_to_sword_unless_intended() -> void:
	## 剣イメージが妥当な剣士系以外は BattleFervor フォールバック禁止。
	var sword_ok: Array[String] = [
		"leon_sword_focus", "kaida_arena_edge", "lenore_seal_echo",
		"torva_frost_breath", "hodaka_blood_price",
	]
	var check_ids: Array[String] = [
		"durante_vial_echo", "ivar_trail_sight", "serin_quick_mend",
		"mira_beast_call", "valden_iron_oath", "garm_caravan_guard",
		"borg_gate_voice", "neri_waterfowl_call", "sian_silent_line",
	]
	check_ids.append_array(sword_ok)
	for pid: String in check_ids:
		var path: String = _PassiveIconHelper.resolve_texture_path(pid)
		assert_false(path.is_empty(), pid)
		if pid in sword_ok:
			continue
		assert_ne(path, _PassiveIconHelper.FALLBACK_PATH, "%s should not use sword fallback" % pid)
