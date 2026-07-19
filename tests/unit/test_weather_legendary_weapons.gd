extends GutTest

## P3-EQ-WEATHER-LEG-001 — 天候シンクロ・レジェンド武器。

const WEATHER_WEAPONS: Dictionary = {
	"stormveil_needle": "eq_wpn_stormveil_needle",
	"noctumbra_fang": "eq_wpn_noctumbra_fang",
	"mistpierce_halberd": "eq_wpn_mistpierce_halberd",
}


func after_each() -> void:
	GameState.set_weather("")
	GameState.party_members = []


func test_weather_legendaries_exist() -> void:
	for weapon_id in WEATHER_WEAPONS.keys():
		var wd: Resource = DataRegistry.get_weapon_data(weapon_id)
		assert_not_null(wd, weapon_id)
		assert_eq(wd.rarity, Enums.Rarity.LEGENDARY, weapon_id)
		assert_eq(str(wd.fixed_passive_id), WEATHER_WEAPONS[weapon_id], weapon_id)
		assert_eq(str(wd.fixed_skill_id), "", weapon_id)


func test_rain_boosts_stormveil_thunder_mult() -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "wx_rain"
	var weapon: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	weapon.weapon_id = "stormveil_needle"
	member.equipped_weapon = weapon
	GameState.party_members = [member]
	GameState.set_weather("")
	var clear_mods: Dictionary = CombatPassives.weapon_stat_modifiers_for_member(0)
	assert_almost_eq(float(clear_mods["element_outgoing_mult"].get("thunder", 1.0)), 1.15, 0.001)
	GameState.set_weather(CombatWeather.RAIN)
	var rain_mods: Dictionary = CombatPassives.weapon_stat_modifiers_for_member(0)
	assert_almost_eq(float(rain_mods["element_outgoing_mult"].get("thunder", 1.0)), 1.40, 0.001)


func test_night_refund_only_when_night() -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "wx_night"
	var weapon: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	weapon.weapon_id = "noctumbra_fang"
	member.equipped_weapon = weapon
	GameState.party_members = [member]
	GameState.set_weather("")
	assert_almost_eq(CombatPassives.on_kill_refund_fraction(0), 0.0, 0.001)
	GameState.set_weather(CombatWeather.NIGHT)
	assert_almost_eq(CombatPassives.on_kill_refund_fraction(0), 0.50, 0.001)
	var night_mods: Dictionary = CombatPassives.weapon_stat_modifiers_for_member(0)
	assert_almost_eq(float(night_mods["element_outgoing_mult"].get("dark", 1.0)), 1.40, 0.001)


func test_fog_boosts_outgoing_and_crit() -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "wx_fog"
	var weapon: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	weapon.weapon_id = "mistpierce_halberd"
	member.equipped_weapon = weapon
	GameState.party_members = [member]
	GameState.set_weather("")
	var clear_mods: Dictionary = CombatPassives.weapon_stat_modifiers_for_member(0)
	assert_almost_eq(float(clear_mods.get("crit_rate_add", 0.0)), 0.03, 0.001)
	var clear_out: Dictionary = CombatPassives.character_stat_modifiers_for_member(0)
	assert_almost_eq(float(clear_out.get("outgoing_mult", 1.0)), 1.0, 0.001)
	GameState.set_weather(CombatWeather.FOG)
	var fog_mods: Dictionary = CombatPassives.weapon_stat_modifiers_for_member(0)
	assert_almost_eq(float(fog_mods.get("crit_rate_add", 0.0)), 0.13, 0.001)
	var fog_out: Dictionary = CombatPassives.character_stat_modifiers_for_member(0)
	assert_almost_eq(float(fog_out.get("outgoing_mult", 1.0)), 1.263, 0.001)
