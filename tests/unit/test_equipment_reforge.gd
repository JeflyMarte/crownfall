extends GutTest
## P3-FORGE-REFORGE-001 — 焼直し（武器 random_mods 1枠再抽選）。

const _ERM = preload("res://scripts/equipment/EquipmentRandomMods.gd")
const _WSR = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _Reforge = preload("res://scripts/equipment/EquipmentReforgeHelper.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.gold = 9999
	GameState.material_inventory = {}
	for mat_id in ["relic_shard", "base_ore", "ancient_bone", "epic_ore", "elite_relic_shard"]:
		GameState.add_material(mat_id, 20)


func _make_weapon(weapon_id: String) -> Resource:
	var wd: Resource = DataRegistry.get_weapon_data(weapon_id)
	assert_not_null(wd, weapon_id)
	var inst: Resource = WeaponInstance.new()
	inst.instance_id = "reforge_%s_%d" % [weapon_id, randi()]
	inst.weapon_id = weapon_id
	_WSR.apply_drop_stats(inst, wd)
	inst.is_appraised = true
	return inst


func _first_reforgeable_index(item: Resource) -> int:
	var mods: Array = _ERM.get_mods(item)
	for i: int in mods.size():
		if mods[i] is Dictionary and _ERM.is_mod_reforgeable(mods[i] as Dictionary):
			return i
	return -1


func _bane_index(item: Resource) -> int:
	var mods: Array = _ERM.get_mods(item)
	for i: int in mods.size():
		if mods[i] is Dictionary and str((mods[i] as Dictionary).get("kind", "")) == "bane":
			return i
	return -1


func test_bane_not_reforgeable() -> void:
	## iron_sword は特攻持ち想定。無ければスキップ相当で別武器を探す。
	var ids: Array[String] = ["iron_sword", "hunting_bow", "apprentice_staff"]
	var found: bool = false
	for wid: String in ids:
		var inst: Resource = _make_weapon(wid)
		var bi: int = _bane_index(inst)
		if bi < 0:
			continue
		found = true
		assert_false(_ERM.is_mod_reforgeable(_ERM.get_mods(inst)[bi]))
		var check: Dictionary = _Reforge.can_reforge(inst, bi)
		assert_false(bool(check.get("ok", false)))
		break
	if not found:
		## 特攻なしでも is_mod_reforgeable(bane) は false
		assert_false(_ERM.is_mod_reforgeable({"kind": "bane", "label": "特効"}))


func test_element_power_rerolls_value_only() -> void:
	var inst: Resource = _make_weapon("tinder_bow")
	var mods: Array = _ERM.get_mods(inst)
	var idx: int = -1
	var elem: String = ""
	for i: int in mods.size():
		if mods[i] is Dictionary and str((mods[i] as Dictionary).get("kind", "")) == "element_power":
			idx = i
			elem = str((mods[i] as Dictionary).get("meta", {}).get("element", ""))
			break
	assert_gte(idx, 0, "tinder_bow should have element_power")
	assert_eq(elem, "fire")
	var result: Dictionary = _ERM.reroll_weapon_mod_at(inst, idx)
	assert_true(bool(result.get("ok", false)), str(result))
	var new_mod: Dictionary = result.get("new_mod", {})
	assert_eq(str(new_mod.get("kind", "")), "element_power")
	assert_eq(str(new_mod.get("meta", {}).get("element", "")), elem)


func test_pool_reroll_replaces_slot_no_duplicate_kind() -> void:
	var inst: Resource = _make_weapon("iron_sword")
	var mods: Array = _ERM.get_mods(inst)
	var idx: int = -1
	for i: int in mods.size():
		if not mods[i] is Dictionary:
			continue
		var kind: String = str((mods[i] as Dictionary).get("kind", ""))
		if kind == "bane" or kind == "element_power":
			continue
		idx = i
		break
	if idx < 0:
		## プール枠が無いレアは属性のみ等 — 強制で attack_up を差し込む
		mods = _ERM.get_mods(inst)
		mods.append({
			"id": "attack_up", "label": "攻撃力アップ", "kind": "attack_up",
			"value": 5, "min_v": 1, "max_v": 20, "perfect": false, "meta": {},
		})
		inst.random_mods = mods
		idx = mods.size() - 1
	var before_kinds: Dictionary = {}
	for i: int in _ERM.get_mods(inst).size():
		if i == idx:
			continue
		var m: Variant = _ERM.get_mods(inst)[i]
		if m is Dictionary:
			before_kinds[str((m as Dictionary).get("kind", ""))] = true
	var result: Dictionary = _ERM.reroll_weapon_mod_at(inst, idx)
	assert_true(bool(result.get("ok", false)), str(result))
	var new_kind: String = str((result.get("new_mod", {}) as Dictionary).get("kind", ""))
	assert_false(new_kind.is_empty())
	assert_false(before_kinds.has(new_kind), "duplicate kind %s" % new_kind)
	assert_ne(new_kind, "bane")


func test_can_reforge_requires_gold_and_mats() -> void:
	var inst: Resource = _make_weapon("iron_sword")
	var idx: int = _first_reforgeable_index(inst)
	assert_gte(idx, 0)
	GameState.gold = 0
	var check: Dictionary = _Reforge.can_reforge(inst, idx)
	assert_false(bool(check.get("ok", false)))
	GameState.gold = 9999
	GameState.material_inventory = {}
	check = _Reforge.can_reforge(inst, idx)
	assert_false(bool(check.get("ok", false)))


func test_reforge_mod_consumes_and_works_at_max_forge() -> void:
	var inst: Resource = _make_weapon("iron_sword")
	inst.enhance_level = 5
	var idx: int = _first_reforgeable_index(inst)
	assert_gte(idx, 0)
	var gold_before: int = GameState.gold
	var check: Dictionary = _Reforge.can_reforge(inst, idx)
	assert_true(bool(check.get("ok", false)), str(check))
	var result: Dictionary = _Reforge.reforge_mod(inst, idx)
	assert_true(bool(result.get("ok", false)), str(result))
	assert_eq(GameState.gold, gold_before - int(check.get("gold_cost", 0)))
	assert_eq(inst.enhance_level, 5)


func test_armor_rejected() -> void:
	var ad: Resource = DataRegistry.get_armor_data("leather_armor")
	var arm: Resource = ArmorInstance.new()
	arm.instance_id = "reforge_armor"
	arm.armor_id = str(ad.armor_id)
	arm.is_appraised = true
	arm.random_mods = [{
		"id": "hp_up", "label": "HPアップ", "kind": "hp_up",
		"value": 10, "min_v": 4, "max_v": 20, "perfect": false, "meta": {},
	}]
	var check: Dictionary = _Reforge.can_reforge(arm, 0)
	assert_false(bool(check.get("ok", false)))


func test_cost_table_by_rarity() -> void:
	assert_eq(_Reforge.get_gold_cost(Enums.Rarity.COMMON), 50)
	assert_eq(_Reforge.get_gold_cost(Enums.Rarity.RARE), 80)
	assert_eq(_Reforge.get_gold_cost(Enums.Rarity.EPIC), 120)
	assert_eq(_Reforge.get_gold_cost(Enums.Rarity.LEGENDARY), 200)
	var epic_mats: Dictionary = _Reforge.get_material_cost(Enums.Rarity.EPIC)
	assert_eq(int(epic_mats.get("relic_shard", 0)), 2)
	assert_eq(int(epic_mats.get("ancient_bone", 0)), 1)
