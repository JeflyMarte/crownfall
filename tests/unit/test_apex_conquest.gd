extends GutTest

## P3-DG-APEX-REDEFINE-001 — 征討パイロット（地図なき主／天望の塔）


func test_north_reach_conquest_data() -> void:
	var data: Resource = DataRegistry.get_dungeon_data(Constants.NORTH_REACH_DUNGEON_ID)
	assert_not_null(data)
	assert_eq(str(data.route_type), "apex")
	assert_eq(int(data.floor_count), 20)
	assert_eq(str(data.boss_id), "albark")
	assert_eq(str(data.display_name), "地図なき主　征討")
	assert_eq(str(data.favored_element), "holy")
	assert_true(bool(data.disable_wandering))
	assert_eq(str(data.unlock_after_dungeon_id), "frostridge")
	assert_true("rock_bison" in data.enemy_pool)
	assert_true("greios" in data.elite_pool)


func test_apex_conquest_playable_helpers() -> void:
	assert_true(Constants.is_apex_conquest_playable("north_reach"))
	assert_true(Constants.is_apex_conquest_playable("red_forge_depths"))
	assert_false(Constants.is_apex_conquest_playable("thunder_peak"))
	assert_true(Constants.is_playable_dungeon("north_reach", "apex"))
	assert_true(Constants.is_playable_dungeon("red_forge_depths", "apex"))
	assert_false(Constants.is_playable_dungeon("thunder_peak", "apex"))
	assert_eq(Constants.is_playable_dungeon_route("apex"), Constants.SUB_DUNGEONS_PLAYABLE)


func test_conquest_always_open_and_unlock() -> void:
	const _Schedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
	const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
	assert_true(_Schedule.is_open_now("north_reach"))
	assert_eq(_Schedule.open_schedule_label("north_reach"), "常設")
	assert_true(_Schedule.is_open_now("red_forge_depths"))
	assert_eq(_Schedule.open_schedule_label("red_forge_depths"), "常設")
	GameState.debug_full_unlock = false
	GameState.dungeon_progress.clear()
	GameState.stage_progress.clear()
	assert_false(GameState.is_dungeon_unlocked("north_reach"))
	assert_false(GameState.is_dungeon_unlocked("red_forge_depths"))
	GameState.mark_stage_cleared("frostridge_5_5", _DungeonTierConfig.TIER_NORMAL)
	assert_true(GameState.is_dungeon_unlocked("north_reach"))
	assert_false(GameState.is_dungeon_unlocked("red_forge_depths"), "天望クリア前は星炉ロック")
	GameState.mark_dungeon_cleared("north_reach")
	assert_true(GameState.is_dungeon_unlocked("red_forge_depths"))


func test_other_apex_still_omitted() -> void:
	GameState.debug_full_unlock = false
	GameState.dungeon_progress.clear()
	GameState.stage_progress.clear()
	assert_false(GameState.is_dungeon_unlocked("thunder_peak"))
	assert_false(GameState.is_dungeon_unlocked("blackshore_abyss"))


## P3-DG-APEX-FORGE-001 — 星炉火口
func test_red_forge_conquest_volcano_data() -> void:
	var data: Resource = DataRegistry.get_dungeon_data(Constants.RED_FORGE_DEPTHS_DUNGEON_ID)
	assert_not_null(data)
	assert_eq(str(data.route_type), "apex")
	assert_eq(int(data.floor_count), 20)
	assert_eq(str(data.boss_id), "forgedormient")
	assert_eq(str(data.display_name), "星炉の寝主　征討")
	assert_eq(str(data.favored_element), "ice")
	assert_true(bool(data.disable_wandering))
	assert_eq(str(data.unlock_after_dungeon_id), "north_reach")
	assert_eq(int(data.daily_attempt_limit), 0)
	assert_true("rock_bison" in data.enemy_pool)
	assert_true("oldrex" in data.enemy_pool)
	assert_true("greios" in data.elite_pool)
	assert_false("frost_claw_raptor" in data.enemy_pool)
	assert_false("sepia_hound" in data.enemy_pool)


func test_red_forge_weather_heat_bias_no_snow() -> void:
	var w: Dictionary = CombatWeather.weights_for_dungeon("red_forge_depths")
	assert_eq(int(w.get(CombatWeather.CLEAR, -1)), 30)
	assert_eq(int(w.get(CombatWeather.FOG, -1)), 15)
	assert_eq(int(w.get(CombatWeather.RAIN, -1)), 5)
	assert_eq(int(w.get(CombatWeather.NIGHT, -1)), 10)
	assert_eq(int(w.get(CombatWeather.HEAT, -1)), 40)
	assert_eq(int(w.get(CombatWeather.SNOW, -1)), 0)
	assert_eq(CombatWeather.weather_biome_key("red_forge_depths"), "")


## P3-DG-APEX-FORGE-BG-001 — 星炉専用戦闘BG（Early/Late/Boss）・BrokenMarsh流用解除
func test_red_forge_dedicated_battle_bgs() -> void:
	const EARLY := "res://assets/dungeon/red_forge_depths/env/BG_Battle_RedForge_Early.png"
	const LATE := "res://assets/dungeon/red_forge_depths/env/BG_Battle_RedForge.png"
	const BOSS := "res://assets/dungeon/red_forge_depths/env/BG_Battle_RedForge_Boss.png"
	assert_true(FileAccess.file_exists(EARLY))
	assert_true(FileAccess.file_exists(LATE))
	assert_true(FileAccess.file_exists(BOSS))
	var sc: Script = load("res://scripts/dungeon/DungeonScene.gd")
	var consts: Dictionary = sc.get_script_constant_map()
	var late_map: Dictionary = consts["BATTLE_BG_MAP"]
	var early_map: Dictionary = consts["BATTLE_BG_EARLY_MAP"]
	var boss_map: Dictionary = consts["BATTLE_BG_BOSS_MAP"]
	assert_eq(str(late_map.get("red_forge_depths", "")), LATE)
	assert_eq(str(early_map.get("red_forge_depths", "")), EARLY)
	assert_eq(str(boss_map.get("red_forge_depths", "")), BOSS)
	assert_eq(int(consts.get("BATTLE_BG_APEX_EARLY_FLOOR_MAX", -1)), 14)
	assert_true(bool(consts["BATTLE_BG_FINAL_BOSS_BIOMES"].get("red_forge_depths", false)))
	## BrokenMarsh 流用を残さない
	assert_false(str(late_map["red_forge_depths"]).contains("BrokenMarsh"))
	assert_false(str(early_map["red_forge_depths"]).contains("BrokenMarsh"))
	assert_false(str(boss_map["red_forge_depths"]).contains("BrokenMarsh"))


func test_forgedormient_codex_art_dedicated() -> void:
	var path: String = str(IconPaths.ICON_MAP.get("enemy:forgedormient", ""))
	assert_eq(path, "res://assets/codex/enemies/ART_BOSS_Forgedormient.png")
	assert_true(FileAccess.file_exists(path))
	## エルディオン流用を残さない
	assert_false(path.contains("Eldion"))


## P3-DG-APEX-FORGE-ICO-002 — フォージ戦闘ICO（ターン＋スキル2）・エルディオン流用解除
func test_forgedormient_combat_icons_dedicated() -> void:
	const TURN := "res://assets/ui/combat/enemy_icons/ICO_ENM_Turn_Forgedormient.png"
	const SLAG := "res://assets/ui/skills/ICO_SKILL_EnemyForgedormientSlagBreath.png"
	const QUAKE := "res://assets/ui/skills/ICO_SKILL_EnemyForgedormientFurnaceQuake.png"
	assert_eq(str(IconPaths.ICON_MAP.get("enemy_turn:forgedormient", "")), TURN)
	assert_eq(str(IconPaths.ICON_MAP.get("skill:enemy_forgedormient_slag_breath", "")), SLAG)
	assert_eq(str(IconPaths.ICON_MAP.get("skill:enemy_forgedormient_furnace_quake", "")), QUAKE)
	assert_true(FileAccess.file_exists(TURN))
	assert_true(FileAccess.file_exists(SLAG))
	assert_true(FileAccess.file_exists(QUAKE))
	assert_false(TURN.contains("Eldion"))
	assert_false(SLAG.contains("Eldion"))
	assert_false(QUAKE.contains("Eldion"))


func test_north_reach_enemy_pool_ids() -> void:
	var data: Resource = DataRegistry.get_dungeon_data(Constants.NORTH_REACH_DUNGEON_ID)
	assert_true("rock_bison" in data.enemy_pool)
	assert_true("greios" in data.elite_pool)
	assert_false("sepia_hound" in data.enemy_pool)


## P3-DG-APEX-BOSS-001 — アルバークは降臨帯（ヴァル超え・クロノス未満）
func test_albark_descent_band_stats() -> void:
	var albark: Resource = DataRegistry.get_enemy_data("albark")
	var chronos: Resource = DataRegistry.get_enemy_data("chronos_wave")
	var valgard: Resource = DataRegistry.get_enemy_data("valgard")
	assert_not_null(albark)
	assert_eq(int(albark.max_hp), 3900)
	assert_eq(int(albark.attack), 248)
	assert_eq(int(albark.defense), 236)
	assert_almost_eq(float(albark.attack_speed), 1.45, 0.001)
	assert_almost_eq(float(albark.critical_rate), 0.11, 0.001)
	assert_eq(int(albark.exp_reward), 225)
	assert_eq(int(albark.gold_reward), 330)
	assert_gt(int(albark.max_hp), int(valgard.max_hp))
	assert_lt(int(albark.max_hp), int(chronos.max_hp))
	assert_lt(int(albark.attack), int(chronos.attack))
	var silence: Resource = DataRegistry.get_skill_data("enemy_albark_white_silence")
	assert_almost_eq(float(silence.power_multiplier), 0.6, 0.001)
	var charge: Resource = DataRegistry.get_skill_data("enemy_albark_mapless_charge")
	assert_almost_eq(float(charge.cooldown), 6.5, 0.001)


## P3-DG-APEX-FORGE-BOSS-001 — フォージはアルバーク同帯（降臨帯）
func test_forgedormient_descent_band_stats() -> void:
	var forge: Resource = DataRegistry.get_enemy_data("forgedormient")
	var albark: Resource = DataRegistry.get_enemy_data("albark")
	var chronos: Resource = DataRegistry.get_enemy_data("chronos_wave")
	var valgard: Resource = DataRegistry.get_enemy_data("valgard")
	assert_not_null(forge)
	assert_eq(int(forge.max_hp), 3900)
	assert_eq(int(forge.attack), 248)
	assert_eq(int(forge.defense), 236)
	assert_almost_eq(float(forge.attack_speed), 1.45, 0.001)
	assert_almost_eq(float(forge.critical_rate), 0.11, 0.001)
	assert_eq(int(forge.exp_reward), 225)
	assert_eq(int(forge.gold_reward), 330)
	assert_eq(int(forge.max_hp), int(albark.max_hp))
	assert_eq(int(forge.attack), int(albark.attack))
	assert_gt(int(forge.max_hp), int(valgard.max_hp))
	assert_lt(int(forge.max_hp), int(chronos.max_hp))
	assert_lt(int(forge.attack), int(chronos.attack))
	var slag: Resource = DataRegistry.get_skill_data("enemy_forgedormient_slag_breath")
	assert_almost_eq(float(slag.power_multiplier), 0.6, 0.001)
	var quake: Resource = DataRegistry.get_skill_data("enemy_forgedormient_furnace_quake")
	assert_almost_eq(float(quake.power_multiplier), 2.0, 0.001)
	assert_almost_eq(float(quake.cooldown), 9.0, 0.001)
	assert_gte(float(quake.cast_time), 1.0)


## P3-DG-APEX-ENV-001 — 天候 W-A（吹雪なし）＋雑魚階帯 Lv
func test_north_reach_weather_weights_no_snow() -> void:
	var w: Dictionary = CombatWeather.weights_for_dungeon("north_reach")
	assert_eq(int(w.get(CombatWeather.CLEAR, -1)), 55)
	assert_eq(int(w.get(CombatWeather.FOG, -1)), 25)
	assert_eq(int(w.get(CombatWeather.RAIN, -1)), 10)
	assert_eq(int(w.get(CombatWeather.NIGHT, -1)), 10)
	assert_eq(int(w.get(CombatWeather.HEAT, -1)), 0)
	assert_eq(int(w.get(CombatWeather.SNOW, -1)), 0)
	## フロスト alias ではない
	assert_eq(CombatWeather.weather_biome_key("north_reach"), "")
	var frost: Dictionary = CombatWeather.weights_for_dungeon("frostridge")
	assert_gt(int(frost.get(CombatWeather.SNOW, 0)), 0)


func test_north_reach_trash_enemy_level_bands() -> void:
	const _Apex := preload("res://scripts/dungeon/ApexConquestConfig.gd")
	const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
	assert_eq(_Apex.enemy_level_for_floor(1), 50)
	assert_eq(_Apex.enemy_level_for_floor(7), 50)
	assert_eq(_Apex.enemy_level_for_floor(8), 54)
	assert_eq(_Apex.enemy_level_for_floor(14), 54)
	assert_eq(_Apex.enemy_level_for_floor(15), 58)
	assert_eq(_Apex.enemy_level_for_floor(19), 58)
	GameState.debug_full_unlock = true
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.start_dungeon("north_reach")
	assert_eq(dc.get_display_floor_current(), 1)
	assert_eq(dc.get_enemy_level(), 50)
	dc.current_room_index = 7
	assert_eq(dc.get_display_floor_current(), 8)
	assert_eq(dc.get_enemy_level(), 54)
	dc.current_room_index = 14
	assert_eq(dc.get_display_floor_current(), 15)
	assert_eq(dc.get_enemy_level(), 58)
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_HARD
	var h_bonus: int = _DungeonTierConfig.enemy_level_bonus(_DungeonTierConfig.TIER_HARD)
	assert_eq(dc.get_enemy_level(), 58 + h_bonus)


func test_north_reach_dedicated_banner_and_icon() -> void:
	const _BiomeBannerHelper := preload("res://scripts/ui/BiomeBannerHelper.gd")
	var ban: String = _BiomeBannerHelper.resolve_path("north_reach")
	assert_eq(ban, "res://assets/ui/dungeon/BAN_DG_NorthReach.png")
	assert_true(FileAccess.file_exists(ban))
	var ico: String = str(IconPaths.ICON_MAP.get("dungeon:north_reach", ""))
	assert_eq(ico, "res://assets/dungeon/north_reach/ICO_DG_NorthReach.png")
	assert_true(FileAccess.file_exists(ico))
	## 境界廊流用を残さない
	assert_false(ban.contains("ValgardBoundary"))
	assert_false(ico.contains("ValgardBoundary"))


## P3-DG-APEX-FORGE-ICO-001 — 星炉 DG ICO／BAN 専用（フロストリッジ流用解除）
func test_red_forge_dedicated_banner_and_icon() -> void:
	const _BiomeBannerHelper := preload("res://scripts/ui/BiomeBannerHelper.gd")
	var ban: String = _BiomeBannerHelper.resolve_path("red_forge_depths")
	assert_eq(ban, "res://assets/ui/dungeon/BAN_DG_RedForge.png")
	assert_true(FileAccess.file_exists(ban))
	var ico: String = str(IconPaths.ICON_MAP.get("dungeon:red_forge_depths", ""))
	assert_eq(ico, "res://assets/dungeon/red_forge_depths/ICO_DG_RedForge.png")
	assert_true(FileAccess.file_exists(ico))
	assert_false(ban.contains("Frostridge"))
	assert_false(ico.contains("Frostridge"))
	assert_false(ban.contains("BrokenMarsh"))
	assert_false(ico.contains("BrokenMarsh"))


## P3-DG-APEX-TIER-001 — 征討も降臨同型で N/H/NM 自由選択
func test_north_reach_free_hard_nightmare_tiers() -> void:
	const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
	GameState.debug_full_unlock = true
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var packed: PackedScene = load("res://scenes/dungeon/DungeonSelectScene.tscn")
	assert_not_null(packed)
	var scene: Control = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	## 征討 Featured 相当へ寄せる（イベント枠・常設）
	scene.set("_featured_dungeon_id", "north_reach")
	scene.set("_expanded_biome_id", "north_reach")
	scene.call("_clamp_selected_tier")
	scene.call("_refresh_tier_tabs")
	var btn_hard: Button = scene.get_node("MainColumn/TabsRow/ButtonHard") as Button
	var btn_nm: Button = scene.get_node("MainColumn/TabsRow/ButtonNightmare") as Button
	assert_not_null(btn_hard)
	assert_not_null(btn_nm)
	assert_false(btn_hard.disabled, "征討 Hard はキャンペーン条件なしで選択可")
	assert_false(btn_nm.disabled, "征討 NM はキャンペーン条件なしで選択可")
	scene.call("_on_tier_pressed", _DungeonTierConfig.TIER_HARD)
	assert_eq(GameState.current_dungeon_tier, _DungeonTierConfig.TIER_HARD)
	scene.call("_on_tier_pressed", _DungeonTierConfig.TIER_NIGHTMARE)
	assert_eq(GameState.current_dungeon_tier, _DungeonTierConfig.TIER_NIGHTMARE)
	## 進入行ラベルは選択難度を反映
	var card: Control = scene.call("_make_event_free_tier_enter_card", "north_reach") as Control
	assert_not_null(card)
	var rich: RichTextLabel = _find_rich_label(card)
	assert_not_null(rich)
	assert_true(str(rich.text).contains("天望の塔"))
	assert_true(str(rich.text).contains("ナイトメア"))
	## 時王も同経路（回帰）
	assert_true(bool(scene.call("_is_event_free_tier_dungeon", "chronos_mausoleum")))
	assert_true(bool(scene.call("_is_event_free_tier_dungeon", "valgard_boundary")))
	assert_true(bool(scene.call("_is_event_free_tier_dungeon", "north_reach")))
	assert_false(bool(scene.call("_is_event_free_tier_dungeon", "golden_nest")))


func _find_rich_label(node: Node) -> RichTextLabel:
	if node is RichTextLabel:
		return node as RichTextLabel
	for child in node.get_children():
		var found: RichTextLabel = _find_rich_label(child)
		if found != null:
			return found
	return null
