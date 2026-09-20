extends GutTest

## Decision 144 Phase 2 — 王痕育成専用UI

const _RoyalMarkConfig := preload("res://scripts/systems/RoyalMarkConfig.gd")
const _RoyalMarkSystem := preload("res://scripts/systems/RoyalMarkSystem.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _Adventurer := preload("res://scripts/domain/Adventurer.gd")
const _Stats := preload("res://scripts/domain/Stats.gd")
const ROYAL_MARK_SCENE: String = "res://scenes/royal_mark/RoyalMarkScene.tscn"
const EQUIPMENT_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"


func before_each() -> void:
	GameState.debug_full_unlock = false
	GameState.dungeon_progress.clear()
	GameState.stage_progress.clear()
	GameState.dungeon_tier_cleared.clear()
	GameState.royal_mark_shards = 0
	GameState.royal_mark_ranks = {}
	GameState.royal_mark_paths = {}
	GameState.gold = 0
	GameState.roster.clear()
	GameState.party_members.clear()
	GameState.active_pet = null
	GameState.current_dungeon_id = ""


func _clear_main_normal() -> void:
	for biome_id: String in _DungeonTierConfig.MAIN_BIOME_IDS:
		GameState.mark_dungeon_cleared(biome_id)
		GameState.mark_dungeon_tier_cleared(biome_id, _DungeonTierConfig.TIER_NORMAL)


func _make_human(id: String, level: int = 50) -> Resource:
	var adv: Resource = _Adventurer.new()
	adv.id = id
	adv.display_name = id
	adv.job_id = "swordsman"
	adv.level = level
	adv.rarity = 3
	var st: Resource = _Stats.new()
	st.hp = 800
	st.attack = 100
	st.defense = 50
	adv.base_stats = st
	return adv


func _make_pet() -> Resource:
	var adv: Resource = _Adventurer.new()
	adv.id = "pet_jack"
	adv.display_name = "ジャック"
	adv.job_id = ""
	adv.level = 99
	return adv


func test_scene_parses() -> void:
	assert_true(ResourceLoader.exists(ROYAL_MARK_SCENE), "RoyalMarkScene path exists")
	var packed: PackedScene = load(ROYAL_MARK_SCENE) as PackedScene
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	assert_not_null(scene)
	scene.free()


func test_list_owned_excludes_jack_and_pet() -> void:
	GameState.roster = [
		_make_human("adventurer_aldric"),
		_make_pet(),
		_make_human("gacha_helper_mirei"),
	]
	var list: Array = _RoyalMarkSystem.list_owned_eligible_members()
	assert_eq(list.size(), 2)
	for m: Variant in list:
		assert_false(PetSystem.is_pet_member(m as Resource))
		assert_true(_RoyalMarkSystem.is_eligible_member(m as Resource))


func test_ui_rank_zero_and_switch() -> void:
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 50)
	var b: Resource = _make_human("adventurer_serin", 50)
	GameState.roster = [a, b, _make_pet()]
	GameState.royal_mark_ranks = {}
	GameState.royal_mark_shards = 100
	GameState.gold = 5000
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_eq(scene.get_view_members_for_test().size(), 2)
	assert_eq(scene.get_rank_display_for_test(), "未覚醒")
	var next0: String = scene.get_next_reward_for_test()
	assert_true(next0.find("王痕 I") >= 0)
	assert_true(next0.find("HP +3%") >= 0)
	var special0: String = scene.get_special_preview_for_test()
	assert_true(special0.find("🔒") >= 0)
	assert_true(special0.find("Rank V") >= 0 or special0.find("覚醒") >= 0)
	scene.select_index_for_test(1)
	assert_eq(scene.get_selected_index_for_test(), 1)
	assert_eq(str((scene.get_view_members_for_test()[1] as Resource).id), "adventurer_serin")


func test_ui_rank_ii_and_effect_lines() -> void:
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 50)
	GameState.roster = [a]
	GameState.royal_mark_ranks = {"adventurer_aldric": 2}
	GameState.royal_mark_shards = 200
	GameState.gold = 15000
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_eq(scene.get_rank_display_for_test(), "王痕 II")
	var effect: String = scene.get_current_effect_for_test()
	assert_true(effect.find("HP +3%") >= 0)
	assert_true(effect.find("ATK +3%") >= 0)
	assert_true(effect.find("DEF —") >= 0)
	## II→III: 次の王痕が主情報
	var next_txt: String = scene.get_next_reward_for_test()
	assert_true(next_txt.find("王痕 III") >= 0)
	assert_true(next_txt.find("DEF +3%") >= 0)
	assert_false(scene.get_path_panel_visible_for_test())
	var special: String = scene.get_special_preview_for_test()
	assert_true(special.find("🔒") >= 0)
	assert_true(special.find("Rank V") >= 0 or special.find("覚醒") >= 0)
	assert_false(scene.get_upgrade_button_for_test().disabled)


func test_ui_current_status_reflects_royal_mark() -> void:
	## 現在のステータスは王痕倍率込みの実数値（キャラ画面と同式）。
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 50)
	GameState.roster = [a]
	GameState.royal_mark_ranks = {}
	GameState.royal_mark_shards = 100
	GameState.gold = 5000
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var base_txt: String = scene.get_current_status_for_test()
	assert_true(base_txt.find("HP ") >= 0)
	assert_true(base_txt.find("ATK ") >= 0)
	assert_true(base_txt.find("DEF ") >= 0)
	var base_hp: int = int(base_txt.split("\n")[0].replace("HP ", ""))
	GameState.royal_mark_ranks = {"adventurer_aldric": 5}
	scene.refresh_for_test()
	await get_tree().process_frame
	var boosted_txt: String = scene.get_current_status_for_test()
	var boosted_hp: int = int(boosted_txt.split("\n")[0].replace("HP ", ""))
	assert_gt(boosted_hp, base_hp)
	var expected: Dictionary = RosterUiHelper.compute_member_stats(a)
	assert_eq(boosted_hp, int(expected.get("hp", 0)))


func test_ui_rank_iv_to_v_preview() -> void:
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 50)
	GameState.roster = [a]
	GameState.royal_mark_ranks = {"adventurer_aldric": 4}
	GameState.royal_mark_shards = 300
	GameState.gold = 45000
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var next_txt: String = scene.get_next_reward_for_test()
	assert_true(next_txt.find("王痕 V") >= 0)
	assert_true(next_txt.find("必殺強化") >= 0)
	assert_true(scene.get_path_panel_visible_for_test())
	var special: String = scene.get_special_preview_for_test()
	assert_true(special.find("🔒") >= 0)
	assert_false(scene.get_upgrade_button_for_test().disabled)


func test_ui_rank_v_max() -> void:
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 50)
	GameState.roster = [a]
	GameState.royal_mark_ranks = {"adventurer_aldric": 5}
	GameState.royal_mark_shards = 99
	GameState.gold = 999999
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_eq(scene.get_rank_display_for_test(), "王痕 V")
	assert_eq(scene.get_status_text_for_test(), "王痕 MAX")
	assert_true(scene.get_upgrade_button_for_test().disabled)
	assert_false(scene.get_upgrade_button_for_test().visible)
	assert_true(scene.get_max_panel_visible_for_test())
	var max_txt: String = scene.get_max_state_text_for_test()
	assert_true(max_txt.find("王痕 V") >= 0)
	assert_true(max_txt.find("MAX") >= 0)


func test_ui_level_gate() -> void:
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 49)
	GameState.roster = [a]
	GameState.royal_mark_shards = 99
	GameState.gold = 999999
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_true(scene.get_status_text_for_test().find("Lv50") >= 0)
	assert_true(scene.get_upgrade_button_for_test().disabled)


func test_ui_shards_and_gold_shortage() -> void:
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 50)
	GameState.roster = [a]
	GameState.royal_mark_shards = 0
	GameState.gold = 999999
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_eq(scene.get_status_text_for_test(), "王痕片不足")
	GameState.royal_mark_shards = 999
	GameState.gold = 0
	scene.refresh_for_test()
	assert_eq(scene.get_status_text_for_test(), "Gold不足")


func test_ui_upgrade_success_refreshes() -> void:
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 50)
	GameState.roster = [a]
	GameState.royal_mark_shards = 100
	GameState.gold = 5000
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var result: Dictionary = _RoyalMarkSystem.apply_upgrade(a)
	assert_true(bool(result.get("ok", false)))
	scene.refresh_for_test()
	assert_eq(scene.get_rank_display_for_test(), "王痕 I")
	assert_eq(_RoyalMarkSystem.get_shards(), 0)


func test_equipment_has_no_upgrade_transaction_api() -> void:
	## EquipmentScene から強化メソッドが消えていること。導線は王痕育成ボタン。
	var src: String = FileAccess.get_file_as_string("res://scripts/equipment/EquipmentScene.gd")
	assert_true(src.find("apply_upgrade") < 0)
	assert_true(src.find("_on_royal_mark_confirmed") < 0)
	assert_true(src.find("_open_royal_mark_sheet") < 0)
	assert_true(src.find("_update_royal_mark_button") >= 0)
	assert_true(src.find("BtnRoyalMark") >= 0)
	assert_true(ResourceLoader.exists(EQUIPMENT_SCENE))
	var hub: String = FileAccess.get_file_as_string("res://scripts/ui/BottomNavHelper.gd")
	assert_true(hub.find('"id": "royal_mark"') < 0)

func test_effect_stat_lines_helper() -> void:
	var lines0: PackedStringArray = _RoyalMarkConfig.effect_stat_lines_for_rank(0)
	assert_eq(lines0[0], "HP —")
	var lines2: PackedStringArray = _RoyalMarkConfig.effect_stat_lines_for_rank(2)
	assert_eq(lines2[0], "HP +3%")
	assert_eq(lines2[1], "ATK +3%")
	assert_eq(lines2[2], "DEF —")
	var lines5: PackedStringArray = _RoyalMarkConfig.effect_stat_lines_for_rank(5)
	assert_eq(lines5[0], "HP +8%")
