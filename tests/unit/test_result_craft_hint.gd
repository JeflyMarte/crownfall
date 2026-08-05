extends GutTest
## Result「赤鉄の工房で作成可能」ヒント（P3-D141 × P3-CRAFT-DISCOVER-001）。


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.unlocked_craft_outputs.clear()
	GameState.gold = 0
	GameState.material_inventory = {}
	GameState.last_run_material_gains = {}
	GameState.last_run_gold_reward = 0


## Result と同じ条件: 素材差分あり AND get_craftable_recipes 非空。
func _result_would_show_hint() -> bool:
	var gains: Dictionary = GameState.last_run_material_gains
	var had: bool = false
	for k in gains.keys():
		if int(gains[k]) > 0:
			had = true
			break
	if not had:
		return false
	return not CraftHelper.get_craftable_recipes().is_empty()


func test_no_material_gains_hides_hint_even_if_craftable() -> void:
	CraftHelper.try_unlock("weapon", "iron_sword")
	GameState.gold = 999
	GameState.add_material("relic_shard", 5)
	GameState.add_material("base_ore", 5)
	assert_false(CraftHelper.get_craftable_recipes().is_empty())
	GameState.last_run_material_gains = {}
	assert_false(_result_would_show_hint())


func test_gains_plus_affordable_unlocked_shows_hint() -> void:
	CraftHelper.try_unlock("weapon", "iron_sword")
	GameState.gold = 999
	GameState.add_material("relic_shard", 5)
	GameState.add_material("base_ore", 5)
	GameState.last_run_material_gains = {"relic_shard": 2}
	assert_true(_result_would_show_hint())
	var recipes: Array = CraftHelper.get_craftable_recipes()
	var names: PackedStringArray = []
	for craft in recipes:
		names.append(str(craft.display_name))
	var hint: String = "赤鉄の工房で作成可能: " + " / ".join(names)
	assert_true(hint.contains("の作成"), hint)
	assert_true(hint.contains("王国制式剣") or hint.contains("鉄剣"), hint)


func test_drop_unlock_then_common_mats_make_craftable() -> void:
	var inst: Resource = WeaponInstance.new()
	inst.instance_id = "drop_1"
	inst.weapon_id = "hunting_bow"
	GameState.note_equipment_obtained(inst)
	assert_true(CraftHelper.is_unlocked("weapon", "hunting_bow"))
	## COMMON コスト（P3-BAL-FORGE-GOLD-HEAVY）: relic_shard1 + base_ore1 + gold80
	GameState.gold = 80
	GameState.add_material("relic_shard", 1)
	GameState.add_material("base_ore", 1)
	GameState.last_run_material_gains = {"base_ore": 1}
	var recipes: Array = CraftHelper.get_craftable_recipes()
	var found: bool = false
	for craft in recipes:
		if str(craft.output_id) == "hunting_bow":
			found = true
			break
	assert_true(found)
	assert_true(_result_would_show_hint())


func test_gains_but_cannot_afford_hides_hint() -> void:
	CraftHelper.try_unlock("weapon", "iron_sword")
	GameState.gold = 0
	GameState.material_inventory = {}
	GameState.last_run_material_gains = {"relic_shard": 1}
	assert_true(CraftHelper.get_craftable_recipes().is_empty())
	assert_false(_result_would_show_hint())


func test_banked_gold_enables_craftable_like_result() -> void:
	## Result は _bank_rewards 後に判定するため、報酬 Gold 込みで足りる（COMMON=80）
	CraftHelper.try_unlock("weapon", "iron_sword")
	GameState.gold = 10
	GameState.last_run_gold_reward = 70
	GameState.add_material("relic_shard", 1)
	GameState.add_material("base_ore", 1)
	GameState.last_run_material_gains = {"base_ore": 1}
	assert_true(CraftHelper.get_craftable_recipes().is_empty(), "before bank")
	GameState.gold += GameState.last_run_gold_reward
	assert_false(CraftHelper.get_craftable_recipes().is_empty(), "after bank")
	assert_true(_result_would_show_hint())


func test_mythic_excluded_from_hint_list() -> void:
	GameState.gold = 9999
	for mat_id in ["relic_shard", "base_ore", "ancient_bone", "epic_ore", "elite_relic_shard"]:
		GameState.add_material(mat_id, 99)
	assert_false(CraftHelper.try_unlock("weapon", "burial_crown_greatsword"))
	GameState.unlocked_craft_outputs["weapon:burial_crown_greatsword"] = true
	GameState.last_run_material_gains = {"elite_relic_shard": 1}
	for craft in CraftHelper.get_craftable_recipes():
		assert_ne(str(craft.output_id), "burial_crown_greatsword")
