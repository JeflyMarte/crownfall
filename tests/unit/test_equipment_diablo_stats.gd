extends GutTest

## P3-EQ-DIABLO-001 — 固定攻撃＋ランダムmods。

const _WSR = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ASR = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _Enh = preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _Detail = preload("res://scripts/equipment/EquipmentItemDetailHelper.gd")
const _ERM = preload("res://scripts/equipment/EquipmentRandomMods.gd")


func test_stat_icon_keys_cover_random_kinds() -> void:
	var _Tokens = load("res://scripts/equipment/EquipmentUiTokens.gd")
	var kinds: Array[String] = [
		"attack_up", "defense_up", "hp_up", "attack_speed", "crit_rate", "crit_damage",
		"on_hit_status", "gold_gain", "exp_gain", "rare_drop", "healing", "evasion",
		"resist_elements", "status_immunities", "chill_chance", "shock_chance",
		"ignite_chance", "poison_chance", "bane",
		"element_power:fire", "element_power:ice", "element_power:thunder",
		"element_power:dark", "element_power:holy",
	]
	for k in kinds:
		assert_not_null(_Tokens.stat_icon(k), k)


func test_element_power_detail_key_uses_element() -> void:
	var _Tokens = load("res://scripts/equipment/EquipmentUiTokens.gd")
	var key: String = _Tokens.detail_stat_icon_key({
		"kind": "element_power",
		"meta": {"element": "fire"},
	})
	assert_eq(key, "element_power:fire")
	assert_not_null(_Tokens.stat_icon(key))


func test_weapon_base_attack_fixed_and_has_mods() -> void:
	var wd: Resource = DataRegistry.get_weapon_data("iron_sword")
	assert_not_null(wd)
	var inst: Resource = WeaponInstance.new()
	inst.instance_id = "t_diablo_wpn"
	inst.weapon_id = str(wd.id)
	_WSR.apply_drop_stats(inst, wd)
	assert_eq(int(inst.rolled_attack), int(wd.base_attack), "基礎攻撃は固定")
	assert_true(inst.random_mods is Array)
	assert_eq(inst.random_mods.size(), _ERM.get_mods(inst).size())
	var expected: int = int(load("res://scripts/equipment/EquipmentRollHelper.gd").random_stat_count(int(wd.rarity)))
	## A2: 属性／特攻がある場合は枠内に含まれる
	assert_eq(inst.random_mods.size(), expected, "ランダム本数はレア表どおり")
	assert_true(inst.prefix_ids.is_empty())
	assert_true(inst.suffix_ids.is_empty())
	var rows: Array = _Detail.stat_rows(inst, "weapon")
	assert_gt(rows.size(), 0)
	assert_eq(str(rows[0].get("label", "")), "攻撃力")
	assert_eq(str(rows[0].get("value", "")), str(_Enh.get_effective_attack(inst)))
	assert_eq(_Detail.affix_text(inst), "")


func test_armor_base_defense_fixed() -> void:
	var ad: Resource = DataRegistry.get_armor_data("leather_armor")
	assert_not_null(ad)
	var inst: Resource = ArmorInstance.new()
	inst.instance_id = "t_diablo_arm"
	inst.armor_id = str(ad.armor_id)
	_ASR.apply_drop_stats(inst, ad)
	assert_eq(int(inst.rolled_defense), int(ad.base_defense))
	assert_eq(inst.random_mods.size(), int(load("res://scripts/equipment/EquipmentRollHelper.gd").random_stat_count(int(ad.rarity))))


func test_status_chance_mods_roll_within_rarity_range() -> void:
	## 冷却／感電／炎上／毒は固定25%ではなくレア度レンジでバラつく。
	var seen: Dictionary = {}
	for _i: int in 80:
		var chill: Dictionary = _ERM._roll_status_chance_mod("chill_chance", "冷却付与", Enums.Rarity.COMMON)
		var v: float = float(chill.get("value", 0.0))
		assert_true(v >= 0.15 - 0.001 and v <= 0.25 + 0.001, "COMMON chill=%s" % v)
		assert_almost_eq(float(chill.get("min_v", 0.0)), 0.15, 0.001)
		assert_almost_eq(float(chill.get("max_v", 0.0)), 0.25, 0.001)
		seen[snappedf(v, 0.01)] = true
	assert_gt(seen.size(), 1, "付与率が複数値にバラけていること")
	var epic: Dictionary = _ERM._roll_status_chance_mod("shock_chance", "感電付与", Enums.Rarity.EPIC)
	var ev: float = float(epic.get("value", 0.0))
	assert_true(ev >= 0.25 - 0.001 and ev <= 0.35 + 0.001, "EPIC shock=%s" % ev)


func test_migrate_legacy_attack_roll_to_mod() -> void:
	var wd: Resource = DataRegistry.get_weapon_data("iron_sword")
	assert_not_null(wd)
	var inst: Resource = WeaponInstance.new()
	inst.instance_id = "t_mig"
	inst.weapon_id = str(wd.id)
	inst.is_appraised = true
	inst.rolled_attack = int(wd.base_attack) + 12
	var prefixes: Array[String] = ["sharp"]
	var empty_sfx: Array[String] = []
	inst.prefix_ids = prefixes
	inst.suffix_ids = empty_sfx
	inst.random_mods = []
	_ERM.ensure_migrated(inst)
	assert_eq(int(inst.rolled_attack), int(wd.base_attack))
	assert_gt(inst.random_mods.size(), 0)
	var has_up: bool = false
	for m: Variant in inst.random_mods:
		if m is Dictionary and str(m.get("kind", "")) == "attack_up":
			has_up = true
	assert_true(has_up, "旧ロール差分が攻撃力アップへ")
