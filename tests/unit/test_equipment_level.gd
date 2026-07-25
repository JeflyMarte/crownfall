extends GutTest
## P3-EQ-LVL-001 — 装備レベル成長・Biome 連動ドロップ。

const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")


func test_scale_stat_grows_with_level() -> void:
	assert_eq(_EquipmentEnhancer.scale_equip_stat(14, 1, Enums.Rarity.LEGENDARY), 14)
	var lv50: int = _EquipmentEnhancer.scale_equip_stat(14, 50, Enums.Rarity.LEGENDARY)
	assert_true(lv50 > 30, "Lv50 レジェンドは base14 から大幅成長 (got %d)" % lv50)


func test_legendary_grows_faster_than_common() -> void:
	var common: int = _EquipmentEnhancer.scale_equip_stat(20, 30, Enums.Rarity.COMMON)
	var legend: int = _EquipmentEnhancer.scale_equip_stat(20, 30, Enums.Rarity.LEGENDARY)
	assert_gt(legend, common)


func test_resolve_drop_level_from_stage() -> void:
	seed(42)
	GameState.current_dungeon_tier = 0
	var stage: Resource = DataRegistry.get_stage_data("mourngate_1_1")
	var lv: int = _EquipmentEnhancer.resolve_drop_equip_level(stage, null)
	assert_true(lv >= 1 and lv <= 2, "1-1 enemy_level=1 → Lv1〜2 (got %d)" % lv)
	var late: Resource = DataRegistry.get_stage_data("mourngate_1_5")
	var late_lv: int = _EquipmentEnhancer.resolve_drop_equip_level(late, null)
	assert_true(late_lv >= 4 and late_lv <= 6, "1-5 enemy_level=5 → Lv4〜6 (got %d)" % late_lv)


func test_resolve_drop_level_follows_hard_tier() -> void:
	## P3-BAL-TIER-001: Hard 1-1 は実効敵Lv≈50帯
	seed(7)
	var Tier = preload("res://scripts/dungeon/DungeonTierConfig.gd")
	var cap: int = Tier.main_normal_cap_level()
	GameState.current_dungeon_tier = Tier.TIER_HARD
	var stage: Resource = DataRegistry.get_stage_data("mourngate_1_1")
	var lv: int = _EquipmentEnhancer.resolve_drop_equip_level(stage, null)
	var expect_lo: int = (1 + cap) - 1
	var expect_hi: int = (1 + cap) + 1
	assert_true(
		lv >= expect_lo and lv <= expect_hi,
		"Hard 1-1 drop Lv should be %d〜%d (got %d)" % [expect_lo, expect_hi, lv]
	)
	GameState.current_dungeon_tier = Tier.TIER_NORMAL


func test_spawn_weapon_gets_drop_level() -> void:
	GameState.inventory.clear()
	GameState.current_dungeon_tier = 0
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_stage("whisperwood_2_3")
	dc._spawn_weapon("iron_sword")
	assert_eq(GameState.inventory.size(), 1)
	var lv: int = _EquipmentEnhancer.get_equip_level(GameState.inventory[0])
	assert_true(lv >= 11 and lv <= 13, "② enemy_level=12 帯 (got %d)" % lv)


func test_spawn_weapon_hard_uses_combat_enemy_level() -> void:
	## get_enemy_level() 経由で Hard 加算が乗る
	GameState.inventory.clear()
	var Tier := preload("res://scripts/dungeon/DungeonTierConfig.gd")
	GameState.current_dungeon_tier = Tier.TIER_HARD
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_stage("mourngate_1_1")
	dc._spawn_weapon("iron_sword")
	var lv: int = _EquipmentEnhancer.get_equip_level(GameState.inventory[0])
	var combat_lv: int = dc.get_enemy_level()
	assert_true(
		lv >= combat_lv - 1 and lv <= combat_lv + 1,
		"Hard spawn Lv≈combat %d±1 (got %d)" % [combat_lv, lv]
	)
	GameState.current_dungeon_tier = Tier.TIER_NORMAL


func test_combat_exp_levels_equipped_weapon() -> void:
	var member: Resource = GameState.party_members[0]
	var weapon: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	weapon.weapon_id = "iron_sword"
	weapon.rolled_attack = 10
	weapon.is_appraised = true
	weapon.equip_level = 1
	weapon.equip_exp = 0
	member.equipped_weapon = weapon
	member.level = 20
	for _i in 20:
		_EquipmentEnhancer.grant_party_combat_exp(10, GameState.party_members)
	assert_gt(_EquipmentEnhancer.get_equip_level(weapon), 1)
