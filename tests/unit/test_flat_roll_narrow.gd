extends GutTest
## P3-EQ-FLAT-ROLL-NARROW-001 — 平坦ランダム帯（案C）。

const _ERM = preload("res://scripts/equipment/EquipmentRandomMods.gd")


func test_ceiling_tables_are_narrowed() -> void:
	assert_eq(int(WeaponStatResolver.ATTACK_ROLL_MAX[Enums.Rarity.LEGENDARY]), 80)
	assert_eq(int(ArmorStatResolver.DEFENSE_ROLL_MAX[Enums.Rarity.LEGENDARY]), 80)
	assert_eq(int(ArmorStatResolver.HP_ROLL_MAX[Enums.Rarity.LEGENDARY]), 144)
	assert_eq(int(AccessoryStatResolver.ATTACK_ROLL_MAX[Enums.Rarity.LEGENDARY]), 64)
	assert_almost_eq(BalanceConfig.FLAT_ROLL_CEILING_MULT, 0.70, 0.001)
	assert_almost_eq(BalanceConfig.FLAT_ROLL_FLOOR_RATIO, 0.55, 0.001)


func test_flat_roll_bounds_floor_ratio() -> void:
	var band: Dictionary = _ERM._flat_roll_bounds(80)
	assert_eq(int(band["max"]), 80)
	assert_eq(int(band["min"]), 44)  # round(80*0.55)
	var small: Dictionary = _ERM._flat_roll_bounds(16)
	assert_eq(int(small["max"]), 16)
	assert_eq(int(small["min"]), 9)


func test_weapon_attack_up_rolls_inside_band() -> void:
	var wd: Resource = DataRegistry.get_weapon_data("iron_sword")
	assert_not_null(wd)
	var rarity: int = int(wd.rarity)
	var band: Dictionary = _ERM._flat_roll_bounds(
		int(WeaponStatResolver.ATTACK_ROLL_MAX.get(rarity, 32))
	)
	var lo: int = int(band["min"])
	var hi: int = int(band["max"])
	for _i: int in 40:
		var mod: Dictionary = _ERM._roll_weapon_pool_mod("attack_up", wd, rarity)
		assert_eq(str(mod.get("kind", "")), "attack_up")
		var v: int = int(mod.get("value", 0))
		assert_true(v >= lo and v <= hi, "attack_up=%d not in %d..%d" % [v, lo, hi])
		assert_eq(int(mod.get("min_v", 0)), lo)
		assert_eq(int(mod.get("max_v", 0)), hi)


func test_weapon_defense_up_band_unchanged() -> void:
	## 武器の防御アップ 8〜16 は据置（狭帯のまま）。
	var wd: Resource = DataRegistry.get_weapon_data("iron_sword")
	var mod: Dictionary = _ERM._roll_weapon_pool_mod("defense_up", wd, Enums.Rarity.COMMON)
	assert_eq(int(mod.get("min_v", 0)), 8)
	assert_eq(int(mod.get("max_v", 0)), 16)
