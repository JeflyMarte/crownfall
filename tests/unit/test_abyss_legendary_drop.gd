extends GutTest

## P3-DG-ABYSS-001-D — 深層レジェンド低確率＋ソフト天井。

const _AbyssMilestoneRewards := preload("res://scripts/dungeon/AbyssMilestoneRewards.gd")
const _AbyssLegendaryDrop := preload("res://scripts/dungeon/AbyssLegendaryDrop.gd")

var _saved_progress: Dictionary = {}
var _saved_inventory: Array = []
var _saved_notices: Array = []
var _saved_mats: Dictionary = {}
var _saved_token: int = 0


func before_each() -> void:
	_saved_progress = GameState.dungeon_progress.duplicate(true)
	_saved_inventory = GameState.inventory.duplicate()
	_saved_notices = (
		GameState.last_run_abyss_notices.duplicate()
		if GameState.last_run_abyss_notices is Array
		else []
	)
	_saved_mats = GameState.material_inventory.duplicate(true)
	_saved_token = GameState.last_run_token_reward
	GameState.dungeon_progress = {}
	GameState.inventory = []
	GameState.last_run_abyss_notices = []
	GameState.material_inventory = {}
	GameState.last_run_token_reward = 0
	GameState.begin_run_material_tracking()


func after_each() -> void:
	GameState.dungeon_progress = _saved_progress
	GameState.inventory = _saved_inventory
	GameState.last_run_abyss_notices = _saved_notices
	GameState.material_inventory = _saved_mats
	GameState.last_run_token_reward = _saved_token


func _mark_99_first(dungeon_id: String) -> void:
	_AbyssMilestoneRewards.try_claim_for_floor(dungeon_id, 99)
	GameState.inventory = []
	GameState.last_run_abyss_notices = []


func test_ineligible_before_99_or_non_decade() -> void:
	assert_true(_AbyssLegendaryDrop.try_on_floor("abyss_mourngate", 100).is_empty())
	_mark_99_first("abyss_mourngate")
	assert_true(_AbyssLegendaryDrop.try_on_floor("abyss_mourngate", 105).is_empty())
	assert_true(_AbyssLegendaryDrop.try_on_floor("abyss_mourngate", 99).is_empty())


func test_miss_increments_pity() -> void:
	_mark_99_first("abyss_whisperwood")
	var result: Dictionary = _AbyssLegendaryDrop.try_on_floor(
		"abyss_whisperwood", 100, null, 0.99
	)
	assert_eq(str(result.get("kind", "")), "miss")
	assert_eq(_AbyssLegendaryDrop.get_pity("abyss_whisperwood"), 1)


func test_base_chance_can_drop() -> void:
	_mark_99_first("abyss_mistfen")
	var before: int = GameState.inventory.size()
	var result: Dictionary = _AbyssLegendaryDrop.try_on_floor(
		"abyss_mistfen", 110, null, 0.01
	)
	assert_eq(str(result.get("kind", "")), "drop")
	assert_eq(GameState.inventory.size(), before + 1)
	assert_eq(str(GameState.inventory.back().weapon_id), "abyss_mirestaff")
	assert_eq(_AbyssLegendaryDrop.get_pity("abyss_mistfen"), 0)
	assert_false(bool(result.get("guaranteed", false)))


func test_soft_ceiling_guarantees() -> void:
	_mark_99_first("abyss_blackshore")
	_AbyssLegendaryDrop.set_pity("abyss_blackshore", _AbyssLegendaryDrop.SOFT_CEILING)
	var result: Dictionary = _AbyssLegendaryDrop.try_on_floor(
		"abyss_blackshore", 120, null, 0.99
	)
	assert_eq(str(result.get("kind", "")), "drop")
	assert_true(bool(result.get("guaranteed", false)))
	assert_eq(str(result.get("weapon_id", "")), "abyss_netherbow")
	assert_eq(_AbyssLegendaryDrop.get_pity("abyss_blackshore"), 0)
	var joined: String = " ".join(PackedStringArray(GameState.last_run_abyss_notices))
	assert_true(joined.contains("天井"), joined)


func test_note_abyss_floor_wires_drop() -> void:
	_mark_99_first("abyss_frostridge")
	_AbyssLegendaryDrop.set_pity("abyss_frostridge", _AbyssLegendaryDrop.SOFT_CEILING)
	var before: int = GameState.inventory.size()
	GameState.note_abyss_floor_reached("abyss_frostridge", 130)
	assert_eq(GameState.inventory.size(), before + 1)
	assert_eq(str(GameState.inventory.back().weapon_id), "abyss_riftclaw")


func test_constants() -> void:
	assert_eq(_AbyssLegendaryDrop.DROP_FLOOR_START, 100)
	assert_eq(_AbyssLegendaryDrop.DROP_FLOOR_STEP, 10)
	assert_almost_eq(_AbyssLegendaryDrop.BASE_CHANCE, 0.05, 0.0001)
	assert_eq(_AbyssLegendaryDrop.SOFT_CEILING, 10)
