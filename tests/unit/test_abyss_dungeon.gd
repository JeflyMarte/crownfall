extends GutTest

## P3-DG-ABYSS-001-A — 深層データ枠・解放・階数帯・最高到達F。

const _AbyssDungeonConfig := preload("res://scripts/dungeon/AbyssDungeonConfig.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")

var _saved_progress: Dictionary = {}
var _saved_stage: Dictionary = {}

func before_each() -> void:
	_saved_progress = GameState.dungeon_progress.duplicate(true)
	_saved_stage = GameState.stage_progress.duplicate(true)
	GameState.dungeon_progress = {}
	GameState.stage_progress = {}

func after_each() -> void:
	GameState.dungeon_progress = _saved_progress
	GameState.stage_progress = _saved_stage


func test_abyss_resources_exist() -> void:
	for abyss_id in _AbyssDungeonConfig.PARENT_BIOME_BY_ABYSS.keys():
		var data: Resource = DataRegistry.get_dungeon_data(str(abyss_id))
		assert_not_null(data, abyss_id)
		assert_eq(str(data.route_type), "abyss", abyss_id)
		assert_true(str(data.display_name).begins_with("無限"), abyss_id)
		assert_true(str(data.display_name).ends_with("の最果て"), abyss_id)
		assert_eq(str(data.boss_id), "", "深層に本編Bossを付けない")


func test_abyss_unlock_after_parent_clear() -> void:
	if not Constants.ABYSS_DUNGEONS_PLAYABLE:
		pass_test("ABYSS off")
		return
	assert_false(GameState.is_dungeon_unlocked("abyss_mourngate"), "親未クリアはロック")
	GameState.mark_dungeon_cleared("mourngate")
	assert_true(GameState.is_dungeon_unlocked("abyss_mourngate"), "親クリアで解放")
	assert_false(GameState.is_dungeon_unlocked("abyss_whisperwood"), "他Biomeは別解放")


func test_abyss_playable_flag_independent_of_sub() -> void:
	assert_eq(Constants.is_playable_dungeon_route("abyss"), Constants.ABYSS_DUNGEONS_PLAYABLE)
	assert_eq(Constants.is_playable_dungeon_route("side"), Constants.SUB_DUNGEONS_PLAYABLE)


func test_synthetic_tier_bands() -> void:
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(1), _DungeonTierConfig.TIER_NORMAL)
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(32), _DungeonTierConfig.TIER_NORMAL)
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(33), _DungeonTierConfig.TIER_HARD)
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(65), _DungeonTierConfig.TIER_HARD)
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(66), _DungeonTierConfig.TIER_NIGHTMARE)
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(120), _DungeonTierConfig.TIER_NIGHTMARE)


func test_endless_level_bonus_ramps() -> void:
	var at_99: int = _AbyssDungeonConfig.enemy_level_bonus_for_floor(99)
	var at_104: int = _AbyssDungeonConfig.enemy_level_bonus_for_floor(104)
	assert_gt(at_104, at_99, "100F以降は緩やかに上積み")


func test_highest_floor_save() -> void:
	assert_eq(GameState.get_abyss_highest_floor("abyss_mourngate"), 0)
	GameState.note_abyss_floor_reached("abyss_mourngate", 12)
	assert_eq(GameState.get_abyss_highest_floor("abyss_mourngate"), 12)
	GameState.note_abyss_floor_reached("abyss_mourngate", 8)
	assert_eq(GameState.get_abyss_highest_floor("abyss_mourngate"), 12, "後退しない")
	GameState.note_abyss_floor_reached("abyss_mourngate", 40)
	assert_eq(GameState.get_abyss_highest_floor("abyss_mourngate"), 40)
