extends GutTest

## P3-EQ-JOB-WPN-001 — 職別武器種制限（各職2種）。剣＝sword。

const _JobCalc = preload("res://scripts/equipment/JobStatCalculator.gd")
const _EquipCtrl = preload("res://scripts/equipment/EquipmentController.gd")


func before_each() -> void:
	## 先行テストの reset_for_new_game で1人編成残るため、職別検証前に5人揃える。
	GameState.seed_all_starters_unlocked()


func _make_weapon(weapon_id: String) -> Resource:
	var inst: Resource = WeaponInstance.new()
	inst.instance_id = "t_%s_%d" % [weapon_id, randi() % 100000]
	inst.weapon_id = weapon_id
	inst.is_appraised = true
	return inst


func _find_job_member(job_id: String) -> Resource:
	for m: Resource in GameState.roster:
		if m != null and str(m.job_id) == job_id:
			return m
	return null


func test_allowed_types_match_job_data() -> void:
	assert_true("bow" in _JobCalc.allowed_weapon_types("ranger"))
	assert_true("sword" in _JobCalc.allowed_weapon_types("ranger"))
	assert_false("dual_blades" in _JobCalc.allowed_weapon_types("ranger"))
	assert_true("staff" in _JobCalc.allowed_weapon_types("alchemist"))
	assert_true("dual_blades" in _JobCalc.allowed_weapon_types("alchemist"))
	assert_false("bow" in _JobCalc.allowed_weapon_types("alchemist"))
	assert_true("bow" in _JobCalc.allowed_weapon_types("beast_tamer"))
	assert_true("staff" in _JobCalc.allowed_weapon_types("beast_tamer"))
	assert_true("sword" in _JobCalc.allowed_weapon_types("swordsman"))
	assert_true("dual_blades" in _JobCalc.allowed_weapon_types("swordsman"))
	assert_true("staff" in _JobCalc.allowed_weapon_types("vanguard"))
	assert_true("sword" in _JobCalc.allowed_weapon_types("vanguard"))
	assert_false("dual_blades" in _JobCalc.allowed_weapon_types("vanguard"))


func test_ranger_can_equip_sword_family() -> void:
	var ranger: Resource = _find_job_member("ranger")
	assert_not_null(ranger)
	var sword: Resource = _make_weapon("iron_sword")
	assert_true(_JobCalc.can_equip_weapon(ranger, sword))
	var bow: Resource = _make_weapon("hunting_bow")
	assert_true(_JobCalc.can_equip_weapon(ranger, bow))
	var blades: Resource = _make_weapon("ember_fang")
	assert_false(_JobCalc.can_equip_weapon(ranger, blades))


func test_equip_controller_rejects_mismatch() -> void:
	var alchemist: Resource = _find_job_member("alchemist")
	assert_not_null(alchemist)
	var idx: int = -1
	for i in GameState.party_members.size():
		if GameState.party_members[i] == alchemist:
			idx = i
			break
	if idx < 0:
		pass_test("alchemist not in active party — skip controller path")
		return
	var saved: Resource = alchemist.equipped_weapon
	var bow: Resource = _make_weapon("hunting_bow")
	GameState.inventory.append(bow)
	var ctrl: Node = _EquipCtrl.new()
	add_child_autofree(ctrl)
	ctrl.equip_weapon(bow, idx)
	assert_ne(alchemist.equipped_weapon, bow, "非適合は装備されない")
	alchemist.equipped_weapon = saved
	GameState.inventory.erase(bow)


func test_strip_incompatible_unequips() -> void:
	var ranger: Resource = _find_job_member("ranger")
	assert_not_null(ranger)
	var saved: Resource = ranger.equipped_weapon
	var blades: Resource = _make_weapon("ember_fang")
	GameState.inventory.append(blades)
	ranger.equipped_weapon = blades
	var n: int = GameState.strip_incompatible_equipped_weapons()
	assert_gt(n, 0)
	assert_null(ranger.equipped_weapon)
	assert_true(blades in GameState.inventory)
	ranger.equipped_weapon = saved
	GameState.inventory.erase(blades)
