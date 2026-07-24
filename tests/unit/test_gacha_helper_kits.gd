extends GutTest

## P3-GACHA-STAGED-002 — 個人ステ・固有パッシブ。

const _Bonuses = preload("res://scripts/roster/CharacterStatBonuses.gd")


func test_helper_personal_bonuses() -> void:
	var k: Dictionary = _Bonuses.for_helper_id("helper_k")
	assert_eq(int(k.get("hp", 0)), 220)
	assert_eq(int(k.get("attack", 0)), 24)
	var l: Dictionary = _Bonuses.for_helper_id("helper_l")
	assert_eq(int(l.get("attack", 0)), 205)
	assert_true(int(l.get("hp", 0)) < 0)


func test_staged_passive_defs_exist() -> void:
	for pid: String in [
		"lenore_seal_echo",
		"torva_frost_breath",
		"sian_silent_line",
		"borg_gate_voice",
		"neri_waterfowl_call",
	]:
		var def: Dictionary = CombatPassives.get_def(pid)
		assert_false(def.is_empty(), pid)


func test_helper_tres_passive_wired() -> void:
	var k: Resource = DataRegistry.get_gacha_helper_data("helper_k")
	assert_not_null(k)
	assert_eq(str(k.passive_id), "lenore_seal_echo")
	var n: Resource = DataRegistry.get_gacha_helper_data("helper_n")
	assert_eq(str(n.passive_id), "borg_gate_voice")
	var def: Dictionary = CombatPassives.get_def(str(n.passive_id))
	assert_almost_eq(float(def.get("threat_base_add", 0.0)), 2.0, 0.001)


func test_threat_base_add_helper() -> void:
	var member: Resource = Adventurer.new()
	member.id = "gacha_helper_n"
	member.job_id = "vanguard"
	member.display_name = "ボルグ"
	assert_almost_eq(CombatPassives.threat_base_add_for_member(member), 2.0, 0.001)
