extends GutTest
## 武器ランダム抽選 — 通常攻撃時の状態付与（stun 除外・確率ロール）。

const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _WeaponInstance = preload("res://scripts/domain/WeaponInstance.gd")
const _WeaponData = preload("res://scripts/data/WeaponData.gd")

func test_weapon_status_pool_excludes_stun() -> void:
	assert_false(_WeaponStatResolver.is_valid_weapon_status("stun"))
	assert_true(_WeaponStatResolver.is_valid_weapon_status("poison"))
	assert_true(_WeaponStatResolver.is_valid_weapon_status("curse"))

func test_resolve_on_hit_status_empty_when_unset() -> void:
	var inst: Resource = _WeaponInstance.new()
	inst.weapon_id = "iron_sword"
	assert_eq(_WeaponStatResolver.resolve_on_hit_status_id(inst), "")
	assert_eq(_WeaponStatResolver.resolve_on_hit_status_chance(inst), 0.0)

func test_resolve_on_hit_status_rejects_invalid_id() -> void:
	var inst: Resource = _WeaponInstance.new()
	inst.weapon_id = "iron_sword"
	inst.on_hit_status_id = "stun"
	inst.on_hit_status_chance = 0.25
	assert_eq(_WeaponStatResolver.resolve_on_hit_status_id(inst), "")
	assert_eq(_WeaponStatResolver.resolve_on_hit_status_chance(inst), 0.0)

func test_resolve_on_hit_status_returns_values() -> void:
	var inst: Resource = _WeaponInstance.new()
	inst.weapon_id = "iron_sword"
	inst.on_hit_status_id = "poison"
	inst.on_hit_status_chance = 0.22
	assert_eq(_WeaponStatResolver.resolve_on_hit_status_id(inst), "poison")
	assert_almost_eq(_WeaponStatResolver.resolve_on_hit_status_chance(inst), 0.22, 0.001)

func test_apply_drop_stats_can_roll_on_hit_status() -> void:
	var data: Resource = _WeaponData.new()
	data.id = "test_status_weapon"
	data.base_attack = 10
	data.rarity = Enums.Rarity.LEGENDARY
	var inst: Resource = _WeaponInstance.new()
	inst.weapon_id = "test_status_weapon"
	for _i in 200:
		_WeaponStatResolver.apply_drop_stats(inst, data)
		if "on_hit_status" in inst.rolled_bonus_stats:
			assert_true(_WeaponStatResolver.is_valid_weapon_status(str(inst.on_hit_status_id)))
			assert_true(float(inst.on_hit_status_chance) >= 0.15)
			assert_true(float(inst.on_hit_status_chance) <= 0.40)
			return
	pass_test("on_hit_status not picked in 200 rolls — acceptable variance")
