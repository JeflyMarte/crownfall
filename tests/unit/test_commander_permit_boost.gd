extends GutTest
## P3-CMD-PERMIT-BOOST-001 — 特権強化（略奪／成長／戦力）。

const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderPermitBoost = preload("res://scripts/commander/CommanderPermitBoost.gd")
const _CommanderLifetime = preload("res://scripts/commander/CommanderLifetime.gd")
const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")


func before_each() -> void:
	GameState.discovery_registry = {}
	GameState.stage_progress = {}
	GameState.enemy_codex = {}
	GameState.gold = 0
	GameState.gacha_token = 0
	GameState.commander = _CommanderLifetime.default_commander_dict()
	GameState.party_members = []


func test_display_name_and_ui_unlock_at_s() -> void:
	assert_eq(_CommanderPermitBoost.DISPLAY_NAME, "特権強化")
	GameState.commander["acknowledged_rank"] = "A"
	_CommanderProfile.ensure_commander()
	assert_false(_CommanderPermitBoost.is_ui_unlocked())
	GameState.commander["acknowledged_rank"] = "S"
	assert_true(_CommanderPermitBoost.is_ui_unlocked())
	GameState.commander["acknowledged_rank"] = "S+1"
	assert_true(_CommanderPermitBoost.is_ui_unlocked())


func test_sync_earned_from_existing_s_plus() -> void:
	GameState.commander["acknowledged_rank"] = "S+3"
	GameState.commander["rank_reward_ranks"] = ["C", "B", "A", "S", "S+1", "S+2", "S+3"]
	_CommanderPermitBoost.ensure_and_sync()
	assert_eq(_CommanderPermitBoost.points_earned(), 3)
	assert_eq(_CommanderPermitBoost.points_unspent(), 3)


func test_grant_on_s_plus_acknowledge() -> void:
	GameState.commander["acknowledged_rank"] = "S"
	GameState.commander["rank_reward_ranks"] = ["C", "B", "A", "S"]
	_fill_enemy_discovery_for_sp(2600)
	assert_eq(_CommanderProfile.rank_from_sp_only(), "S+1")
	_CommanderProfile.acknowledge_rank("S+1")
	assert_eq(_CommanderPermitBoost.points_earned(), 1)
	assert_eq(_CommanderPermitBoost.points_unspent(), 1)


func test_alloc_and_respec_free() -> void:
	GameState.commander["permit_points_earned"] = 5
	_CommanderPermitBoost.ensure()
	assert_eq(_CommanderPermitBoost.set_alloc(_CommanderPermitBoost.TRACK_PLUNDER, 3), 3)
	assert_eq(_CommanderPermitBoost.set_alloc(_CommanderPermitBoost.TRACK_GROWTH, 3), 2)
	assert_eq(_CommanderPermitBoost.points_unspent(), 0)
	assert_eq(_CommanderPermitBoost.set_alloc(_CommanderPermitBoost.TRACK_PLUNDER, 0), 0)
	assert_eq(_CommanderPermitBoost.points_unspent(), 3)
	assert_eq(_CommanderPermitBoost.set_alloc(_CommanderPermitBoost.TRACK_POWER, 3), 3)


func test_bonus_mults() -> void:
	GameState.commander["permit_points_earned"] = 10
	_CommanderPermitBoost.ensure()
	_CommanderPermitBoost.set_alloc(_CommanderPermitBoost.TRACK_PLUNDER, 5)
	_CommanderPermitBoost.set_alloc(_CommanderPermitBoost.TRACK_GROWTH, 3)
	_CommanderPermitBoost.set_alloc(_CommanderPermitBoost.TRACK_POWER, 2)
	assert_almost_eq(_CommanderPermitBoost.gold_mult(), 1.10, 0.001)
	assert_almost_eq(_CommanderPermitBoost.material_mult(), 1.10, 0.001)
	assert_almost_eq(_CommanderPermitBoost.exp_mult(), 1.06, 0.001)
	assert_almost_eq(_CommanderPermitBoost.hp_mult(), 1.04, 0.001)
	assert_eq(_CommanderPermitBoost.defense_flat(), 4)
	assert_eq(_AffixStatCalculator.apply_gold_bonus(100), 110)
	assert_eq(_AffixStatCalculator.apply_exp_bonus(100), 106)
	assert_eq(_AffixStatCalculator.apply_material_bonus(10), 11)


func _fill_enemy_discovery_for_sp(target_sp: int) -> void:
	var need: int = int(ceili(float(target_sp) / 3.0))
	GameState.discovery_registry.clear()
	for i in need:
		GameState.discovery_registry["enemy:fill_%d" % i] = true
