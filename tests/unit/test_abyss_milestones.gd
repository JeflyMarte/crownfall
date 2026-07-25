extends GutTest

## P3-DG-ABYSS-001-B — 深層マイルストーン報酬。

const _AbyssMilestoneRewards := preload("res://scripts/dungeon/AbyssMilestoneRewards.gd")
const _TicketInventory := preload("res://scripts/tickets/TicketInventory.gd")

var _saved_progress: Dictionary = {}
var _saved_mats: Dictionary = {}
var _saved_tickets: Dictionary = {}
var _saved_token: int = 0


func before_each() -> void:
	_saved_progress = GameState.dungeon_progress.duplicate(true)
	_saved_mats = GameState.material_inventory.duplicate(true)
	_saved_tickets = GameState.ticket_inventory.duplicate(true)
	_saved_token = GameState.gacha_token
	GameState.dungeon_progress = {}
	GameState.material_inventory = {}
	GameState.ticket_inventory = {}
	GameState.gacha_token = 0
	GameState.begin_run_material_tracking()


func after_each() -> void:
	GameState.dungeon_progress = _saved_progress
	GameState.material_inventory = _saved_mats
	GameState.ticket_inventory = _saved_tickets
	GameState.gacha_token = _saved_token


func test_33_first_then_repeat() -> void:
	var g1: Array = _AbyssMilestoneRewards.try_claim_for_floor("abyss_mourngate", 33)
	assert_eq(g1.size(), 1)
	assert_eq(str(g1[0].get("kind", "")), "first")
	assert_eq(GameState.last_run_token_reward, 8)
	assert_eq(GameState.get_material_quantity("epic_ore"), 5)
	assert_eq(GameState.get_material_quantity("elite_relic_shard"), 2)
	GameState.material_inventory = {}
	GameState.begin_run_material_tracking()
	var g2: Array = _AbyssMilestoneRewards.try_claim_for_floor("abyss_mourngate", 33)
	assert_eq(g2.size(), 1)
	assert_eq(str(g2[0].get("kind", "")), "repeat")
	assert_eq(GameState.last_run_token_reward, 0)
	assert_eq(GameState.get_material_quantity("epic_ore"), 2)


func test_66_grants_limit_break_ticket() -> void:
	_AbyssMilestoneRewards.try_claim_for_floor("abyss_whisperwood", 66)
	assert_eq(_TicketInventory.get_qty("ticket_lb_star3"), 1)
	assert_eq(GameState.last_run_token_reward, 20)


func test_endless_bag_once_per_floor() -> void:
	var a: Array = _AbyssMilestoneRewards.try_claim_for_floor("abyss_mistfen", 100)
	assert_eq(a.size(), 1)
	assert_eq(GameState.get_material_quantity("epic_ore"), 1)
	GameState.material_inventory = {}
	GameState.begin_run_material_tracking()
	var b: Array = _AbyssMilestoneRewards.try_claim_for_floor("abyss_mistfen", 100)
	assert_eq(b.size(), 0)
	assert_eq(GameState.get_material_quantity("epic_ore"), 0)


func test_99_grants_abyss_legendary_weapon() -> void:
	var saved_inv: Array = GameState.inventory.duplicate()
	GameState.inventory = []
	GameState.last_run_abyss_notices = []
	_AbyssMilestoneRewards.try_claim_for_floor("abyss_frostridge", 99)
	assert_eq(GameState.inventory.size(), 1)
	assert_eq(str(GameState.inventory[0].weapon_id), "abyss_riftclaw")
	GameState.inventory = saved_inv
