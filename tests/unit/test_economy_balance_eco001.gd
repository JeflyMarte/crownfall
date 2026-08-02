extends GutTest

## P3-BAL-ECO-001 — 魔晶石／日課／素材供給／ゴールドシンク

const _AbyssMilestoneRewards := preload("res://scripts/dungeon/AbyssMilestoneRewards.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _DungeonController := preload("res://scripts/dungeon/DungeonController.gd")


func test_abyss_milestone_token_first_rewards() -> void:
	assert_eq(int(_AbyssMilestoneRewards.REWARDS[33]["first"]["tokens"]), 100)
	assert_eq(int(_AbyssMilestoneRewards.REWARDS[66]["first"]["tokens"]), 200)
	assert_eq(int(_AbyssMilestoneRewards.REWARDS[99]["first"]["tokens"]), 300)
	assert_eq(int(_AbyssMilestoneRewards.REWARDS[66]["repeat"]["tokens"]), 25)
	assert_eq(int(_AbyssMilestoneRewards.REWARDS[99]["repeat"]["tokens"]), 50)


func test_abyss_33_first_grants_raised_tokens() -> void:
	var saved_progress: Dictionary = GameState.dungeon_progress.duplicate(true)
	var saved_mats: Dictionary = GameState.material_inventory.duplicate(true)
	GameState.dungeon_progress = {}
	GameState.material_inventory = {}
	GameState.last_run_token_reward = 0
	GameState.begin_run_material_tracking()
	_AbyssMilestoneRewards.try_claim_for_floor("abyss_mourngate", 33)
	assert_eq(GameState.last_run_token_reward, 100)
	GameState.dungeon_progress = saved_progress
	GameState.material_inventory = saved_mats


func test_daily_kill_enemies_has_gold_and_token() -> void:
	var mission: Resource = load("res://resources/daily_missions/daily_kill_enemies.tres")
	assert_not_null(mission)
	## Gold は P3-BAL-DAILY-TREASURE-GOLD-001 で 150。石・素材は ECO-001 据置。
	assert_eq(int(mission.reward_gold), 150)
	assert_eq(int(mission.reward_gacha_token), 15)
	assert_eq(int(mission.reward_material_qty), 2)


func test_forge_gold_sink_raised() -> void:
	## P3-BAL-FORGE-GOLD-HEAVY-001: 底上げ＋全段レア倍率。
	assert_eq(EquipmentEnhancer.get_gold_cost(1), 100)
	assert_eq(EquipmentEnhancer.get_gold_cost(5), 560)
	assert_eq(EquipmentEnhancer.get_gold_cost(5, Enums.Rarity.COMMON), 560)
	assert_eq(EquipmentEnhancer.get_gold_cost(5, Enums.Rarity.RARE), 700)
	assert_eq(EquipmentEnhancer.get_gold_cost(5, Enums.Rarity.EPIC), 896)
	assert_eq(EquipmentEnhancer.get_gold_cost(5, Enums.Rarity.LEGENDARY), 1680)
	assert_eq(EquipmentEnhancer.get_gold_cost(1, Enums.Rarity.LEGENDARY), 300)
	assert_eq(EquipmentEnhancer.get_gold_cost(5, Enums.Rarity.SET), 1960)
	assert_eq(EquipmentEnhancer.get_gold_cost(5, Enums.Rarity.MYTHIC), 2240)
	assert_eq(EquipmentEnhancer.ALCHEMY_GOLD_PER_GAIN, 60)
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(10, 20), 600)
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(10, 40), 900)


func test_elite_and_boss_material_chances() -> void:
	assert_almost_eq(_DungeonController.ELITE_MATERIAL_CHANCE, 0.25, 0.0001)
	assert_almost_eq(_DungeonController.BOSS_EPIC_ORE_CHANCE, 0.45, 0.0001)


func test_hard_combat_can_pick_rare_ore() -> void:
	var saved_tier: int = GameState.current_dungeon_tier
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_HARD
	var saw_rare: bool = false
	for _i in range(200):
		if EquipmentEnhancer.pick_combat_drop_material() == EquipmentEnhancer.RARE_ORE_ID:
			saw_rare = true
			break
	GameState.current_dungeon_tier = saved_tier
	assert_true(saw_rare, "Hard combat should occasionally yield ancient_bone")


func test_normal_combat_stays_base_pool() -> void:
	var saved_tier: int = GameState.current_dungeon_tier
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	for _i in range(40):
		var mat_id: String = EquipmentEnhancer.pick_combat_drop_material()
		assert_true(
			mat_id == EquipmentEnhancer.BASE_ORE_ID or mat_id == EquipmentEnhancer.COMMON_MATERIAL_ID,
			"Normal combat must stay base_ore/relic_shard, got %s" % mat_id
		)
	GameState.current_dungeon_tier = saved_tier
