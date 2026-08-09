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
	## P3-BAL-ABYSS-BOSS-TIER-ALIGN-001: 33=N／66=H／99=NM（ボスが帯の最終階）。
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(1), _DungeonTierConfig.TIER_NORMAL)
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(33), _DungeonTierConfig.TIER_NORMAL)
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(34), _DungeonTierConfig.TIER_HARD)
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(66), _DungeonTierConfig.TIER_HARD)
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(67), _DungeonTierConfig.TIER_NIGHTMARE)
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(99), _DungeonTierConfig.TIER_NIGHTMARE)
	assert_eq(_AbyssDungeonConfig.synthetic_tier_for_floor(120), _DungeonTierConfig.TIER_NIGHTMARE)


func test_floor_level_curve_anchors() -> void:
	assert_eq(_AbyssDungeonConfig.enemy_level_for_floor(1), 1)
	assert_eq(_AbyssDungeonConfig.enemy_level_for_floor(2), 2)
	assert_eq(_AbyssDungeonConfig.enemy_level_for_floor(10), 5)
	assert_eq(_AbyssDungeonConfig.enemy_level_for_floor(32), 28)
	assert_eq(_AbyssDungeonConfig.enemy_level_for_floor(33), 32)
	assert_eq(_AbyssDungeonConfig.enemy_level_for_floor(66), 80)
	assert_eq(_AbyssDungeonConfig.enemy_level_for_floor(99), 110)
	## 階数＝Lv ではない（例: 20F≠20）。
	assert_ne(_AbyssDungeonConfig.enemy_level_for_floor(20), 20)
	assert_lt(_AbyssDungeonConfig.enemy_level_for_floor(20), 20)
	## 単調非減少。
	var prev: int = 0
	for f in [1, 2, 10, 20, 32, 33, 50, 65, 66, 80, 99]:
		var lv: int = _AbyssDungeonConfig.enemy_level_for_floor(f)
		assert_gte(lv, prev, "F%d Lvが下がらない" % f)
		prev = lv


func test_endless_level_ramps() -> void:
	var at_99: int = _AbyssDungeonConfig.enemy_level_for_floor(99)
	var at_104: int = _AbyssDungeonConfig.enemy_level_for_floor(104)
	assert_gt(at_104, at_99, "100F以降は緩やかに上積み")


func test_abyss_get_enemy_level_ignores_biome_base() -> void:
	GameState.mark_dungeon_cleared("whisperwood")
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.start_stage("abyss_whisperwood_1_1")
	## 章リソースの enemy_level=10 でも 1F は絶対Lv=1。
	assert_eq(dc.get_display_floor_current(), 1)
	assert_eq(dc.get_enemy_level(), 1)


func test_highest_floor_save() -> void:
	assert_eq(GameState.get_abyss_highest_floor("abyss_mourngate"), 0)
	GameState.note_abyss_floor_reached("abyss_mourngate", 12)
	assert_eq(GameState.get_abyss_highest_floor("abyss_mourngate"), 12)
	GameState.note_abyss_floor_reached("abyss_mourngate", 8)
	assert_eq(GameState.get_abyss_highest_floor("abyss_mourngate"), 12, "後退しない")
	GameState.note_abyss_floor_reached("abyss_mourngate", 40)
	assert_eq(GameState.get_abyss_highest_floor("abyss_mourngate"), 40)


func test_select_scene_shows_abyss_best_left_of_depart() -> void:
	if not Constants.ABYSS_DUNGEONS_PLAYABLE:
		pass_test("ABYSS off")
		return
	GameState.mark_dungeon_cleared("mourngate")
	GameState.note_abyss_floor_reached("abyss_mourngate", 66)
	var packed: PackedScene = load("res://scenes/dungeon/DungeonSelectScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene.set("_featured_dungeon_id", "abyss_mourngate")
	scene.set("_route_tab", "abyss")
	scene.call("_refresh_featured")
	await get_tree().process_frame
	var best_lbl: Label = scene.get("_label_featured_abyss_best") as Label
	var btn: Button = scene.get("_btn_featured_select") as Button
	assert_not_null(best_lbl)
	assert_not_null(btn)
	assert_true(best_lbl.visible)
	assert_eq(best_lbl.text, "最高到達 F66")
	assert_eq(best_lbl.get_index(), btn.get_index() - 1, "出発ボタンの左")
	assert_false(str(scene.get("_label_featured_meta").text).contains("最高到達"), "メタ行には載せない")


func test_abyss_biomes_have_one_stage_distinct_from_parent() -> void:
	## イベント同様: 親バナー下に1章。章名は親「無限〜の最果て」と分離。
	var expected: Dictionary = {
		"abyss_mourngate": ["abyss_mourngate_1_1", "虚脈の深廊"],
		"abyss_whisperwood": ["abyss_whisperwood_1_1", "根葬の暗路"],
		"abyss_mistfen": ["abyss_mistfen_1_1", "封緘の澱井戸"],
		"abyss_blackshore": ["abyss_blackshore_1_1", "灯なき潮溝"],
		"abyss_frostridge": ["abyss_frostridge_1_1", "氷裂の底縁"],
	}
	for abyss_id in expected.keys():
		var stages: Array = DataRegistry.get_stages_for_biome(str(abyss_id))
		assert_eq(stages.size(), 1, abyss_id)
		var stage: Resource = stages[0]
		var parent: Resource = DataRegistry.get_dungeon_data(str(abyss_id))
		assert_eq(str(stage.id), str(expected[abyss_id][0]), abyss_id)
		assert_eq(str(stage.display_name), str(expected[abyss_id][1]), abyss_id)
		assert_ne(str(stage.display_name), str(parent.display_name), abyss_id)
		GameState.mark_dungeon_cleared(_AbyssDungeonConfig.parent_biome_id(str(abyss_id)))
		assert_true(GameState.is_stage_unlocked(str(stage.id)), abyss_id)


func test_start_abyss_stage_keeps_endless_and_run_name() -> void:
	GameState.mark_dungeon_cleared("mourngate")
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.start_stage("abyss_mourngate_1_1")
	assert_eq(dc.room_sequence.size(), 10)
	## 初チャンク（1〜10F）にボス無し。33Fごと。
	assert_false(Enums.RoomType.BOSS in dc.room_sequence)
	assert_eq(dc.get_run_display_name(), "1-1 虚脈の深廊")
	assert_eq(dc.get_display_floor_text(), "1F/??")
	## チャンク最終Fでも結果画面判定にしない（10Fで追い出されるバグ再発防止）。
	dc.current_room_index = dc.room_sequence.size() - 1
	assert_true(dc.is_on_last_floor())
	assert_false(dc.is_on_last_floor_before_exit())
	## チャンク末尾を超えても完走せず延長する。
	dc.advance_room()
	assert_false(dc.is_completed)
	assert_gt(dc.room_sequence.size(), 10)
	assert_eq(GameState.get_stage_progress_label("abyss_mourngate"), "")
	assert_eq(dc.get_display_floor_text(), "11F/??")
	assert_true(dc.last_abyss_weather_rerolled, "11F で天候再抽選")


func test_abyss_weather_stable_within_10f_block() -> void:
	## フロア途中（2〜10F）では天候 id を触らない。再抽選は 11F 境界のみ。
	GameState.mark_dungeon_cleared("mourngate")
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.start_stage("abyss_mourngate_1_1")
	var weather0: String = str(GameState.get_weather())
	for _i: int in range(9):
		dc.advance_room()
		assert_false(dc.last_abyss_weather_rerolled, "チャンク内で再抽選しない")
		assert_false(dc.last_abyss_weather_changed)
		assert_eq(str(GameState.get_weather()), weather0, "2〜10F は天候不変")
	assert_eq(dc.get_display_floor_current(), 10)
	dc.advance_room()
	assert_eq(dc.get_display_floor_current(), 11)
	assert_true(dc.last_abyss_weather_rerolled, "11F で再抽選実行")


func test_main_run_weather_never_rerolls_on_advance() -> void:
	## 本編は run 開始1回のみ（P3-D101-1）。advance で変えない。
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.start_stage("mourngate_1_1")
	var weather0: String = str(GameState.get_weather())
	var floors: int = mini(5, dc.room_sequence.size() - 1)
	for _i: int in range(floors):
		dc.advance_room()
		assert_false(dc.last_abyss_weather_rerolled)
		assert_eq(str(GameState.get_weather()), weather0)


func test_abyss_block_helpers_for_weather_and_bg() -> void:
	assert_eq(_AbyssDungeonConfig.floor_block_index(1), 0)
	assert_eq(_AbyssDungeonConfig.floor_block_index(10), 0)
	assert_eq(_AbyssDungeonConfig.floor_block_index(11), 1)
	assert_eq(_AbyssDungeonConfig.floor_block_index(21), 2)
	assert_true(_AbyssDungeonConfig.is_block_start_floor(1))
	assert_true(_AbyssDungeonConfig.is_block_start_floor(11))
	assert_false(_AbyssDungeonConfig.is_block_start_floor(10))
	assert_true(_AbyssDungeonConfig.uses_early_battle_bg_for_floor(1))
	assert_true(_AbyssDungeonConfig.uses_early_battle_bg_for_floor(10))
	assert_false(_AbyssDungeonConfig.uses_early_battle_bg_for_floor(11))
	assert_true(_AbyssDungeonConfig.uses_early_battle_bg_for_floor(21))


func test_abyss_boss_every_33_floors_uses_parent_boss() -> void:
	assert_true(_AbyssDungeonConfig.is_boss_floor(33))
	assert_true(_AbyssDungeonConfig.is_boss_floor(66))
	assert_true(_AbyssDungeonConfig.is_boss_floor(99))
	assert_true(_AbyssDungeonConfig.is_boss_floor(132))
	assert_false(_AbyssDungeonConfig.is_boss_floor(1))
	assert_false(_AbyssDungeonConfig.is_boss_floor(32))
	assert_false(_AbyssDungeonConfig.is_boss_floor(34))
	assert_eq(_AbyssDungeonConfig.parent_boss_id("abyss_mourngate"), "serdion")
	assert_eq(_AbyssDungeonConfig.parent_boss_id("abyss_whisperwood"), "granvel")
	GameState.mark_dungeon_cleared("mourngate")
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.start_stage("abyss_mourngate_1_1")
	while dc.room_sequence.size() < 99:
		dc.current_room_index = dc.room_sequence.size() - 1
		dc.advance_room()
	assert_eq(dc.room_sequence[32], Enums.RoomType.BOSS, "33F")
	assert_eq(dc.room_sequence[65], Enums.RoomType.BOSS, "66F")
	assert_eq(dc.room_sequence[98], Enums.RoomType.BOSS, "99F")
	assert_ne(dc.room_sequence[0], Enums.RoomType.BOSS)
	assert_ne(dc.room_sequence[31], Enums.RoomType.BOSS)
	dc.current_room_index = 32
	dc.current_room_type = Enums.RoomType.BOSS
	var boss: Resource = dc.pick_boss_enemy_data()
	assert_not_null(boss)
	assert_eq(str(boss.id), "serdion")


func test_abyss_boss_pack_kinds_by_floor() -> void:
	assert_eq(_AbyssDungeonConfig.boss_pack_kind(1), "solo")
	assert_eq(_AbyssDungeonConfig.boss_pack_kind(33), "boss_swarm_12")
	assert_eq(_AbyssDungeonConfig.boss_pack_kind(66), "boss_elite")
	assert_eq(_AbyssDungeonConfig.boss_pack_kind(99, 0.0), "boss_elite_minion")
	assert_eq(_AbyssDungeonConfig.boss_pack_kind(99, 0.9), "boss_swarm_3")
	assert_eq(_AbyssDungeonConfig.boss_pack_kind(132, 0.0), "boss_elite_minion")
	assert_eq(_AbyssDungeonConfig.boss_pack_kind(132, 0.5), "boss_swarm_3")
	assert_eq(_AbyssDungeonConfig.boss_pack_kind(132, 0.9), "boss_elite_swarm_2")


func test_abyss_boss_combat_group_has_pack() -> void:
	GameState.mark_dungeon_cleared("mourngate")
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.start_stage("abyss_mourngate_1_1")
	while dc.room_sequence.size() < 40:
		dc.current_room_index = dc.room_sequence.size() - 1
		dc.advance_room()
	## 33F: ボス＋雑魚1〜2
	dc.current_room_index = 32
	dc.current_room_type = Enums.RoomType.BOSS
	var saw_swarm := false
	for _i in 16:
		var group: Array = dc.pick_combat_enemy_group()
		assert_eq(str(group[0].id), "serdion")
		assert_gte(group.size(), 2)
		assert_lte(group.size(), 3)
		if group.size() >= 2:
			saw_swarm = true
			assert_eq(int(group[0].enemy_type), int(Enums.EnemyType.BOSS))
			for j in range(1, group.size()):
				assert_ne(int(group[j].enemy_type), int(Enums.EnemyType.BOSS))
	assert_true(saw_swarm)
	## 66F: ボス＋エリート
	while dc.room_sequence.size() < 70:
		dc.current_room_index = dc.room_sequence.size() - 1
		dc.advance_room()
	dc.current_room_index = 65
	dc.current_room_type = Enums.RoomType.BOSS
	var group66: Array = dc.pick_combat_enemy_group()
	assert_eq(str(group66[0].id), "serdion")
	assert_eq(group66.size(), 2)
	assert_eq(int(group66[1].enemy_type), int(Enums.EnemyType.ELITE))


func test_abyss_select_meta_hides_fixed_floor_and_rec_level() -> void:
	## 選択UIは固定10F／推奨Lvを出さず？？表記（無限の性質）。
	var packed: PackedScene = load("res://scenes/dungeon/DungeonSelectScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	var stage: Resource = DataRegistry.get_stage_data("abyss_mourngate_1_1")
	assert_not_null(stage)
	var meta: String = scene.call("_format_stage_meta_text", stage)
	assert_eq(meta, "？？F  推奨レベル？？")
	var main_stage: Resource = DataRegistry.get_stage_data("mourngate_1_1")
	if main_stage != null:
		var main_meta: String = scene.call("_format_stage_meta_text", main_stage)
		assert_true(main_meta.contains("F"), main_meta)
		assert_false(main_meta.begins_with("？？"), main_meta)
