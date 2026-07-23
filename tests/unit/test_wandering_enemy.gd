extends GutTest

## P3-WANDER-001〜004 — 遍在希少種（ダック／レイヴン／スカラベ／影狩り）。

const _WanderingEnemyConfig = preload("res://scripts/dungeon/WanderingEnemyConfig.gd")
const _WeekRotation = preload("res://scripts/event/EventWeekRotation.gd")
const _Schedule = preload("res://scripts/event/EventScheduleHelper.gd")
func _unix_for_none_field_slot() -> int:
	var anchor: int = _Schedule.jst_day_start_unix(_WeekRotation.ANCHOR_DATE_JST)
	for slot: int in range(0, 800):
		var idx: int = _WeekRotation.definition_index_for_slot(slot)
		if str(_WeekRotation.SLOT_DEFINITIONS[idx].get("id", "")) == "none":
			return anchor + slot * _WeekRotation.SLOT_SECONDS + 60
	return anchor + 60


var _saved_party: Array = []


func before_each() -> void:
	EventSystem.set_debug_unix_for_tests(_unix_for_none_field_slot())
	_saved_party = GameState.party_members.duplicate()


func after_each() -> void:
	EventSystem.clear_debug_unix_for_tests()
	GameState.party_members = _saved_party
	_saved_party = []


func test_roll_cosmic_duck_at_low_roll() -> void:
	assert_eq(_WanderingEnemyConfig.wandering_id_for_roll(0.01), _WanderingEnemyConfig.ID_COSMIC_DUCK)


func test_roll_crown_raven_in_mid_band() -> void:
	assert_eq(_WanderingEnemyConfig.wandering_id_for_roll(0.03), _WanderingEnemyConfig.ID_CROWN_RAVEN)


func test_roll_golden_scarab_band() -> void:
	## N: duck 0.025 + raven 0.015 = 0.040 → scarab until 0.055
	assert_eq(_WanderingEnemyConfig.wandering_id_for_roll(0.045), _WanderingEnemyConfig.ID_GOLDEN_SCARAB)


func test_roll_shadow_stalker_band() -> void:
	## N: …scarab ends 0.055 → stalker until 0.063
	assert_eq(_WanderingEnemyConfig.wandering_id_for_roll(0.058), _WanderingEnemyConfig.ID_SHADOW_STALKER)
	## 1-1〜1-3 相当: 影狩り帯の roll でも空
	assert_eq(
		_WanderingEnemyConfig.wandering_id_for_roll(0.058, 0, false),
		""
	)


func test_shadow_stalker_blocked_on_early_mourngate_chapters() -> void:
	assert_false(_WanderingEnemyConfig.is_shadow_stalker_allowed_on_stage(1, 1))
	assert_false(_WanderingEnemyConfig.is_shadow_stalker_allowed_on_stage(1, 2))
	assert_false(_WanderingEnemyConfig.is_shadow_stalker_allowed_on_stage(1, 3))
	assert_true(_WanderingEnemyConfig.is_shadow_stalker_allowed_on_stage(1, 4))
	assert_true(_WanderingEnemyConfig.is_shadow_stalker_allowed_on_stage(1, 5))
	assert_true(_WanderingEnemyConfig.is_shadow_stalker_allowed_on_stage(2, 1))
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	dc.current_room_type = Enums.RoomType.COMBAT
	dc.current_stage_data = DataRegistry.get_stage_data("mourngate_1_1")
	var saw_stalker: bool = false
	for seed_val: int in range(400):
		seed(seed_val)
		var picked: Resource = dc.try_pick_wandering_enemy()
		if picked != null and str(picked.id) == "shadow_stalker":
			saw_stalker = true
			break
	assert_false(saw_stalker, "1-1 では影狩り放浪が出ない")
	dc.current_stage_data = DataRegistry.get_stage_data("mourngate_1_4")
	var saw_any_wander: bool = false
	for seed_val: int in range(400):
		seed(seed_val)
		var picked2: Resource = dc.try_pick_wandering_enemy()
		if picked2 != null:
			saw_any_wander = true
			if str(picked2.id) == "shadow_stalker":
				saw_stalker = true
				break
	assert_true(saw_any_wander or saw_stalker, "1-4 では放浪抽選が動く")


func test_roll_empty_above_threshold() -> void:
	assert_eq(_WanderingEnemyConfig.wandering_id_for_roll(0.99), "")


func test_spawn_chance_scales_with_dungeon_tier() -> void:
	var n_duck: float = _WanderingEnemyConfig.spawn_chance_cosmic_duck(0)
	var h_duck: float = _WanderingEnemyConfig.spawn_chance_cosmic_duck(1)
	var nm_duck: float = _WanderingEnemyConfig.spawn_chance_cosmic_duck(2)
	assert_almost_eq(n_duck, 0.025, 0.0001)
	assert_almost_eq(h_duck, 0.025 * 1.3, 0.0001)
	assert_almost_eq(nm_duck, 0.025 * 1.6, 0.0001)
	assert_almost_eq(_WanderingEnemyConfig.spawn_chance_crown_raven(2), 0.015 * 1.6, 0.0001)
	assert_almost_eq(_WanderingEnemyConfig.spawn_chance_golden_scarab(0), 0.015, 0.0001)
	assert_almost_eq(_WanderingEnemyConfig.spawn_chance_shadow_stalker(0), 0.008, 0.0001)
	assert_almost_eq(_WanderingEnemyConfig.spawn_chance_shadow_stalker(2), 0.008 * 1.6, 0.0001)
	## ノーマル帯では外れる roll が、ナイトメアでは影狩り帯に入る
	## N total=0.063 / NM: duck0.04+raven0.024+scarab0.024=0.088 → stalker to ~0.1008
	assert_eq(_WanderingEnemyConfig.wandering_id_for_roll(0.07, 0), "")
	assert_eq(
		_WanderingEnemyConfig.wandering_id_for_roll(0.09, 2),
		_WanderingEnemyConfig.ID_SHADOW_STALKER
	)

func test_legacy_ids_alias_to_new() -> void:
	assert_eq(
		_WanderingEnemyConfig.canonical_enemy_id("wayfarer_sparrow"),
		_WanderingEnemyConfig.ID_COSMIC_DUCK
	)
	assert_eq(
		_WanderingEnemyConfig.canonical_enemy_id("reliquary_beetle"),
		_WanderingEnemyConfig.ID_CROWN_RAVEN
	)
	var duck_via_alias: Resource = DataRegistry.get_enemy_data("wayfarer_sparrow")
	assert_not_null(duck_via_alias)
	assert_eq(str(duck_via_alias.id), _WanderingEnemyConfig.ID_COSMIC_DUCK)


func test_cosmic_duck_has_flee_and_no_weapon() -> void:
	var data: Resource = DataRegistry.get_enemy_data("cosmic_duck")
	assert_not_null(data)
	assert_true(data.is_wandering)
	assert_eq(data.wander_flee_after_turns, 3)
	assert_eq(data.weapon_drop_chance, 0.0)
	assert_true(data.equip_category_weights.is_empty())
	assert_eq(int(data.exp_reward), 100)


func test_golden_scarab_gold_flee_no_weapon() -> void:
	var data: Resource = DataRegistry.get_enemy_data("golden_scarab")
	assert_not_null(data)
	assert_true(data.is_wandering)
	assert_eq(data.wander_flee_after_turns, 3)
	assert_eq(data.weapon_drop_chance, 0.0)
	assert_true(data.equip_category_weights.is_empty())
	assert_eq(int(data.gold_reward), 220)
	assert_eq(int(data.exp_reward), 15)


func test_crown_raven_multi_category_drop() -> void:
	var data: Resource = DataRegistry.get_enemy_data("crown_raven")
	assert_not_null(data)
	assert_true(data.is_wandering)
	assert_eq(data.wander_flee_after_turns, 0)
	assert_eq(data.weapon_drop_chance, 0.85)
	assert_false(data.weapon_rarity_weights.is_empty())
	assert_eq(int(data.equip_category_weights.get("weapon", 0)), 40)
	assert_eq(int(data.equip_category_weights.get("armor", 0)), 35)
	assert_eq(int(data.equip_category_weights.get("accessory", 0)), 25)


func test_shadow_stalker_high_risk_loot() -> void:
	var data: Resource = DataRegistry.get_enemy_data("shadow_stalker")
	assert_not_null(data)
	assert_true(data.is_wandering)
	assert_eq(data.wander_flee_after_turns, 0)
	assert_eq(data.weapon_drop_chance, 0.88)
	assert_eq(int(data.exp_reward), 140)
	assert_eq(int(data.gold_reward), 150)
	assert_eq(int(data.max_hp), 2270)
	assert_eq(int(data.attack), 330)
	assert_eq(str(data.skill_ids[0]), "enemy_shadow_reap")
	assert_almost_eq(float(data.skill_use_chance), 0.5, 0.0001)
	assert_almost_eq(float(data.on_hit_status_chance), 0.4, 0.0001)
	assert_eq(int(data.weapon_rarity_weights.get(Enums.Rarity.LEGENDARY, 0)), 55)
	assert_eq(int(data.equip_category_weights.get("weapon", 0)), 40)
	assert_true(_WanderingEnemyConfig.grants_legendary_equip_pool(data))
	assert_almost_eq(_WanderingEnemyConfig.mythic_chance_for(data), 0.035, 0.0001)
	var skill: Resource = DataRegistry.get_skill_data("enemy_shadow_reap")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "party_back")
	assert_almost_eq(float(skill.power_multiplier), 1.85, 0.001)
	assert_eq(str(skill.apply_status_id), "bleed")
	assert_eq(str(skill.apply_status_id2), "armor_break")


func test_pick_wandering_replaces_combat_pool() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	dc.current_room_type = Enums.RoomType.COMBAT
	var saw_wander: bool = false
	var wander_ids: Array[String] = [
		"cosmic_duck", "crown_raven", "golden_scarab", "shadow_stalker"
	]
	for seed_val: int in range(200):
		seed(seed_val)
		var group: Array = dc.pick_combat_enemy_group()
		if group.size() != 1:
			continue
		var eid: String = str(group[0].id)
		if eid in wander_ids:
			saw_wander = true
			break
	assert_true(saw_wander, "200 trials should hit wandering spawn")


func test_weapon_drop_chance_override() -> void:
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_WEAPON_DROP), 1.0)
	GameState.party_members = []
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	var duck: Resource = DataRegistry.get_enemy_data("cosmic_duck")
	assert_eq(dc._resolve_weapon_drop_chance(Enums.RoomType.COMBAT, duck), 0.0)
	var raven: Resource = DataRegistry.get_enemy_data("crown_raven")
	assert_eq(dc._resolve_weapon_drop_chance(Enums.RoomType.COMBAT, raven), 0.85)
	var scarab: Resource = DataRegistry.get_enemy_data("golden_scarab")
	assert_eq(dc._resolve_weapon_drop_chance(Enums.RoomType.COMBAT, scarab), 0.0)
	var stalker: Resource = DataRegistry.get_enemy_data("shadow_stalker")
	assert_eq(dc._resolve_weapon_drop_chance(Enums.RoomType.COMBAT, stalker), 0.88)


func test_rarity_weight_override_for_raven() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	var raven: Resource = DataRegistry.get_enemy_data("crown_raven")
	assert_eq(dc._rarity_drop_weight_for(Enums.Rarity.EPIC, raven), 40)
	assert_eq(dc._rarity_drop_weight_for(Enums.Rarity.LEGENDARY, raven), 30)
	var stalker: Resource = DataRegistry.get_enemy_data("shadow_stalker")
	assert_eq(dc._rarity_drop_weight_for(Enums.Rarity.LEGENDARY, stalker), 55)


func test_multi_category_equip_drop_can_yield_armor() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	var raven: Resource = DataRegistry.get_enemy_data("crown_raven")
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.inventory.clear()
	var saw_non_weapon: bool = false
	for seed_val: int in range(80):
		seed(seed_val)
		GameState.armor_inventory.clear()
		GameState.accessory_inventory.clear()
		GameState.inventory.clear()
		## ドロップ判定を通すため chance 内に入るよう強制再試行
		var drop: Dictionary = dc._roll_multi_category_equip_drop(raven)
		if drop.is_empty():
			continue
		var cat: String = str(drop.get("category", ""))
		if cat == "armor" or cat == "accessory":
			saw_non_weapon = true
			break
	assert_true(saw_non_weapon, "レイヴンは防具/装飾も落とせる")


func test_crown_raven_pool_includes_legendary_weapons() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("astoria_ruins")
	var raven: Resource = DataRegistry.get_enemy_data("crown_raven")
	var pool: Array = dc._augment_pool_with_legendaries(
		dc._active_weapon_pool(), "weapon", raven
	)
	assert_true("consecrated_maul" in pool or "sanctified_dagger" in pool, "伝説武器が候補に入る")
	assert_false(MythicLoot.WEAPON_ID in pool, "神話はレア度プール外")
	var stalker: Resource = DataRegistry.get_enemy_data("shadow_stalker")
	var stalker_pool: Array = dc._augment_pool_with_legendaries(
		dc._active_weapon_pool(), "weapon", stalker
	)
	assert_true(
		"consecrated_maul" in stalker_pool or "sanctified_dagger" in stalker_pool,
		"影狩りも伝説武器候補"
	)


func test_crown_raven_mythic_drop_can_succeed() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	var saw: bool = false
	for seed_val: int in range(400):
		seed(seed_val)
		GameState.inventory.clear()
		GameState.armor_inventory.clear()
		GameState.accessory_inventory.clear()
		var drop: Dictionary = dc._try_crown_raven_mythic_drop()
		if drop.is_empty():
			continue
		assert_true(bool(drop.get("mythic", false)))
		assert_true(MythicLoot.is_mythic_id(str(drop.get("id", ""))))
		saw = true
		break
	assert_true(saw, "神話ドロップが成立しうる")


func test_shadow_stalker_mythic_drop_can_succeed() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	var stalker: Resource = DataRegistry.get_enemy_data("shadow_stalker")
	var saw: bool = false
	for seed_val: int in range(250):
		seed(seed_val)
		GameState.inventory.clear()
		GameState.armor_inventory.clear()
		GameState.accessory_inventory.clear()
		var drop: Dictionary = dc._try_wander_mythic_drop(stalker)
		if drop.is_empty():
			continue
		assert_true(bool(drop.get("mythic", false)))
		assert_true(MythicLoot.is_mythic_id(str(drop.get("id", ""))))
		saw = true
		break
	assert_true(saw, "影狩りの神話ドロップが成立しうる")


func test_shadow_stalker_omen_on_previous_floor() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	var seq: Array[int] = [
		Enums.RoomType.START,
		Enums.RoomType.ELITE,
		Enums.RoomType.COMBAT,
		Enums.RoomType.EXIT,
	]
	dc.room_sequence = seq
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	dc._wander_plan_ready = true
	dc._planned_wander_by_room = {2: _WanderingEnemyConfig.ID_SHADOW_STALKER}
	dc.current_room_index = 1
	dc.current_room_type = Enums.RoomType.ELITE
	assert_true(dc.should_show_shadow_stalker_omen())
	assert_eq(
		_WanderingEnemyConfig.SHADOW_STALKER_OMEN_LINE,
		"──死を告げる羽音が近づく。この気配…影狩だ。"
	)
	dc.current_room_index = 2
	dc.current_room_type = Enums.RoomType.COMBAT
	assert_false(dc.should_show_shadow_stalker_omen())
	dc.current_room_index = 0
	assert_false(dc.should_show_shadow_stalker_omen())


func test_planned_wander_used_on_combat_pick() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	dc.current_room_type = Enums.RoomType.COMBAT
	dc.current_room_index = 3
	dc._wander_plan_ready = true
	dc._planned_wander_by_room = {3: _WanderingEnemyConfig.ID_SHADOW_STALKER}
	var group: Array = dc.pick_combat_enemy_group()
	assert_eq(group.size(), 1)
	assert_eq(str(group[0].id), "shadow_stalker")


func test_save_v6_to_v7_merges_legacy_wander_codex() -> void:
	var raw: Dictionary = {
		"save_version": 6,
		"enemy_codex": {
			"wayfarer_sparrow": {"seen": true, "kills": 3},
			"reliquary_beetle": {"seen": true, "kills": 1},
		},
	}
	var migrated: Dictionary = SaveManager._migrate_save_v6_to_v7(raw.duplicate(true))
	var codex: Dictionary = migrated["enemy_codex"]
	assert_false(codex.has("wayfarer_sparrow"))
	assert_false(codex.has("reliquary_beetle"))
	assert_eq(int(codex["cosmic_duck"]["kills"]), 3)
	assert_eq(int(codex["crown_raven"]["kills"]), 1)
