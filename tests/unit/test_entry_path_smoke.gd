extends GutTest
## 起動〜選択〜ダンジョン入場の回帰スモーク（極限リリース前硬化）。
## 実戦闘は回さず、シーン instantiate＋ヘッダー更新で即死／再入を拾う。

const _IntroTutorialConfig := preload("res://scripts/intro/IntroTutorialConfig.gd")
const _ExtremeMissionConfig := preload("res://scripts/dungeon/ExtremeMissionConfig.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")

const DUNGEON_SCENE := "res://scenes/dungeon/DungeonScene.tscn"
const SELECT_SCENE := "res://scenes/dungeon/DungeonSelectScene.tscn"
const TITLE_SCENE := "res://scenes/title/TitleScene.tscn"
const BASE_SCENE := "res://scenes/base/BaseScene.tscn"
const BLACKSMITH_SCENE := "res://scenes/blacksmith/BlacksmithScene.tscn"


func before_each() -> void:
	GameState.debug_full_unlock = false
	_ExtremeMissionConfig.debug_day_key_override = ""
	GameState.dungeon_progress.clear()
	GameState.stage_progress.clear()
	GameState.dungeon_tier_cleared.clear()
	GameState.extreme_mission_progress.clear()
	GameState.current_dungeon_id = ""
	GameState.current_stage_id = ""
	GameState.tutorial_flags.clear()
	if GameState.party_members.is_empty():
		GameState._init_party()
		if Constants.STARTER_STORY_RECRUIT:
			GameState.seed_all_starters_unlocked()


func after_each() -> void:
	_ExtremeMissionConfig.debug_day_key_override = ""
	GameState.debug_full_unlock = false


func _clear_all_main_normal() -> void:
	for biome_id: String in _DungeonTierConfig.MAIN_BIOME_IDS:
		GameState.mark_dungeon_cleared(biome_id)


func _instantiate_scene(path: String) -> Node:
	var packed: PackedScene = load(path) as PackedScene
	assert_not_null(packed, path)
	var scene: Node = packed.instantiate()
	assert_not_null(scene, "instantiate %s" % path)
	add_child_autofree(scene)
	return scene


func _await_stable(scene: Node) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(is_instance_valid(scene))


func _enter_dungeon_scene(dungeon_id: String, stage_id: String = "") -> Node:
	GameState.current_dungeon_id = dungeon_id
	GameState.current_stage_id = stage_id
	var scene: Node = _instantiate_scene(DUNGEON_SCENE)
	await _await_stable(scene)
	var header: Label = scene.get_node_or_null("MainVBox/HeaderBar/LabelDungeonName") as Label
	if header == null:
		## ノード名揺れに備え、ヘッダー更新 API を直接叩く。
		if scene.has_method("_update_dungeon_header"):
			var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
			var nm: String = str(data.display_name) if data != null else dungeon_id
			scene.call("_update_dungeon_header", nm)
			scene.call("_fit_dungeon_header_name_font")
	else:
		## 狭い幅でも font-fit 再入が死なないこと。
		header.size = Vector2(96, header.size.y)
		if scene.has_method("_fit_dungeon_header_name_font"):
			scene.call("_fit_dungeon_header_name_font")
			scene.call("_fit_dungeon_header_name_font")
	return scene


func test_hub_and_select_scenes_instantiate() -> void:
	## Equipment は裏読み await があるため Select/Title/Hub/鍛冶屋に限定。
	for path: String in [TITLE_SCENE, BASE_SCENE, SELECT_SCENE, BLACKSMITH_SCENE]:
		var scene: Node = _instantiate_scene(path)
		await _await_stable(scene)


func test_intro_and_main_dungeon_entry_smoke() -> void:
	assert_true(GameState.select_intro_starter("adventurer_0"))
	_IntroTutorialConfig.mark_pending()
	_IntroTutorialConfig.begin_run()
	await _enter_dungeon_scene(
		_IntroTutorialConfig.DUNGEON_ID,
		_IntroTutorialConfig.STAGE_ID
	)
	GameState.current_stage_id = ""
	await _enter_dungeon_scene("mourngate")


func test_long_name_descent_and_extreme_header_fit() -> void:
	## 降臨・極限の長い表示名で font-fit 再入が落ちないこと。
	await _enter_dungeon_scene("chronos_mausoleum")
	await _enter_dungeon_scene("nereion_flagship")
	_ExtremeMissionConfig.debug_day_key_override = _ExtremeMissionConfig.DAILY_ROTATION_ANCHOR_DAY_KEY
	_clear_all_main_normal()
	await _enter_dungeon_scene(Constants.EX_TOMB_SEAL_DUNGEON_ID)
	## 長めの極限名も確認。
	await _enter_dungeon_scene("ex_spore_dense")
	await _enter_dungeon_scene("north_reach")


func test_extreme_select_clears_featured_when_locked() -> void:
	## 未解放の極限タブで本編 Featured が残ると誤入場になる穴の回帰。
	GameState.debug_full_unlock = false
	GameState.dungeon_progress.clear()
	GameState.current_dungeon_id = "mourngate"
	var select: Node = _instantiate_scene(SELECT_SCENE)
	await _await_stable(select)
	assert_true(select.has_method("_on_route_tab_pressed"))
	select.call("_on_route_tab_pressed", "extreme")
	await get_tree().process_frame
	assert_eq(str(select.get("_featured_dungeon_id")), "")
	var btn: Button = select.get_node_or_null(
		"MainColumn/FeaturedPanel/FeaturedVBox/FeaturedActionRow/BtnFeaturedSelect"
	) as Button
	if btn != null:
		assert_true(btn.disabled)


func test_extreme_select_features_first_mission_when_unlocked() -> void:
	## 解放後は全任務出現。Featured は EX 番号先頭（EX-01）。
	_clear_all_main_normal()
	var select: Node = _instantiate_scene(SELECT_SCENE)
	await _await_stable(select)
	select.call("_on_route_tab_pressed", "extreme")
	await get_tree().process_frame
	assert_eq(str(select.get("_featured_dungeon_id")), "ex_tomb_seal")
	assert_true(GameState.can_attempt_event_dungeon("ex_tomb_seal"))
	assert_true(GameState.can_attempt_event_dungeon("ex_grave_siege"))
	assert_true(GameState.can_attempt_event_dungeon("ex_white_night"))
	## バナー上タイトルがあるので説明欄のタイトル行は非表示。制約文のみ。
	var name_lbl: Label = select.get_node_or_null(
		"MainColumn/FeaturedPanel/FeaturedVBox/FeaturedInfo/LabelFeaturedName"
	) as Label
	assert_not_null(name_lbl)
	assert_false(name_lbl.visible)
	var flavor: RichTextLabel = select.get_node_or_null(
		"MainColumn/FeaturedPanel/FeaturedVBox/FeaturedInfo/LabelFeaturedFlavor"
	) as RichTextLabel
	assert_not_null(flavor)
	assert_true(flavor.visible)
	assert_true(str(flavor.text).find("特殊制約") >= 0)


func test_can_attempt_extreme_open_regardless_of_day() -> void:
	_clear_all_main_normal()
	_ExtremeMissionConfig.debug_day_key_override = "2026-09-20"
	assert_true(GameState.can_attempt_event_dungeon("ex_tomb_seal"))
	assert_true(GameState.can_attempt_event_dungeon("ex_grave_siege"))
	_ExtremeMissionConfig.debug_day_key_override = "2026-09-21"
	assert_true(GameState.can_attempt_event_dungeon("ex_tomb_seal"))
	assert_true(GameState.can_attempt_event_dungeon("ex_grave_siege"))
