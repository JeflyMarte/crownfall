extends GutTest
## P3-GACHA-LIMIT-001 — 限界突破（案B・パッシブ強化）。

const _LimitBreak := preload("res://scripts/gacha/GachaLimitBreak.gd")
const _GachaRarityConfig := preload("res://scripts/gacha/GachaRarityConfig.gd")

var _saved_party: Array = []
var _saved_owned: Dictionary = {}


func before_each() -> void:
	_saved_party = GameState.party_members.duplicate()
	_saved_owned = GameState.owned_helpers.duplicate()
	GameState.owned_helpers.clear()


func after_each() -> void:
	GameState.party_members = _saved_party
	GameState.owned_helpers = _saved_owned
	_saved_party = []
	_saved_owned = {}


func test_breakthrough_from_owned_count() -> void:
	assert_eq(_LimitBreak.breakthrough_from_owned_count(0), 0)
	assert_eq(_LimitBreak.breakthrough_from_owned_count(1), 0)
	assert_eq(_LimitBreak.breakthrough_from_owned_count(2), 1)
	assert_eq(_LimitBreak.breakthrough_from_owned_count(6), 5)
	assert_eq(_LimitBreak.breakthrough_from_owned_count(99), 5)


func test_effect_scale() -> void:
	assert_eq(_LimitBreak.effect_scale(0), 1.0)
	assert_eq(_LimitBreak.effect_scale(1), 1.1)
	assert_eq(_LimitBreak.effect_scale(5), 1.5)


func test_scale_outgoing_mult() -> void:
	var scaled: Dictionary = _LimitBreak.scale_passive_def({"outgoing_mult": 1.10}, 5)
	assert_almost_eq(float(scaled["outgoing_mult"]), 1.15, 0.001)


func test_scale_heal_value() -> void:
	var scaled: Dictionary = _LimitBreak.scale_passive_def(
		{"effect": "heal", "value": 14, "target": "party"}, 5
	)
	assert_eq(int(scaled["value"]), 21)


func test_half_refund_table() -> void:
	assert_eq(_GachaRarityConfig.get_refund(2), 50)
	assert_eq(_GachaRarityConfig.get_refund(3), 100)
	assert_eq(_GachaRarityConfig.get_refund(4), 150)


func test_kaida_and_garm_have_passives() -> void:
	var kaida: Resource = DataRegistry.get_gacha_helper_data("helper_f")
	var garm: Resource = DataRegistry.get_gacha_helper_data("helper_i")
	assert_not_null(kaida)
	assert_not_null(garm)
	assert_eq(str(kaida.passive_id), "kaida_arena_edge")
	assert_eq(str(garm.passive_id), "garm_caravan_guard")
	assert_false(CombatPassives.get_def("kaida_arena_edge").is_empty())
	assert_false(CombatPassives.get_def("garm_caravan_guard").is_empty())


func test_core_passives_scale_for_gacha_member() -> void:
	GameState.owned_helpers["helper_a"] = 6
	var adv = load("res://scripts/domain/Adventurer.gd").new()
	adv.id = "gacha_helper_a"
	adv.job_id = "vanguard"
	adv.rarity = 4
	adv.display_name = "ヴァルデン"
	var defs: Array = CombatPassives.for_member(adv)
	var found_scaled: bool = false
	for d: Variant in defs:
		if str(d.get("id", "")) == "valden_iron_oath":
			## incoming 0.88 → 軽減幅 0.12 * 1.5 = 0.18 → 0.82
			assert_almost_eq(float(d.get("incoming_mult", 1.0)), 0.82, 0.001)
			## party ward 0.90 → 軽減幅 0.10 * 1.5 = 0.15 → 0.85
			assert_almost_eq(float(d.get("mult", 1.0)), 0.85, 0.001)
			found_scaled = true
	assert_true(found_scaled, "valden_iron_oath should be present and scaled")


func test_stat_passive_scales_via_core() -> void:
	GameState.owned_helpers["helper_f"] = 6
	var adv = load("res://scripts/domain/Adventurer.gd").new()
	adv.id = "gacha_helper_f"
	adv.job_id = "swordsman"
	adv.rarity = 2
	GameState.party_members = [adv]
	var mods: Dictionary = CombatPassives.character_stat_modifiers_for_member(0, 0.4)
	## 1.30 → excess 0.30 * 1.5 = 0.45 → 1.45（HP50%以下時）
	assert_almost_eq(float(mods.get("outgoing_mult", 1.0)), 1.45, 0.001)
