extends GutTest

## P3-DG-NEREION-DESCENT-001 — 潮脈王　降臨／沈没旗艦下

const _Sched := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
const _Sets := preload("res://scripts/equipment/EquipmentSetBonuses.gd")
const DID := "nereion_flagship"


func before_each() -> void:
	_Sched.clear_debug_weekday_override()
	_Sched.clear_debug_unix_override()
	GameState.debug_full_unlock = false


func after_each() -> void:
	_Sched.clear_debug_weekday_override()
	_Sched.clear_debug_unix_override()
	GameState.debug_full_unlock = false


func test_tres_shape() -> void:
	var data: Resource = DataRegistry.get_dungeon_data(DID)
	assert_not_null(data, "nereion_flagship.tres")
	assert_eq(str(data.id), DID)
	assert_eq(str(data.route_type), "event")
	assert_eq(str(data.boss_id), "nereion_depths")
	assert_eq(str(data.display_name), "潮脈王　降臨")
	assert_eq(int(data.daily_attempt_limit), 0)
	assert_true(bool(data.disable_wandering))
	assert_eq(str(data.unlock_after_dungeon_id), "")
	assert_eq(int(data.floor_count), 7)


func test_boss_descent_band() -> void:
	var boss: Resource = DataRegistry.get_enemy_data("nereion_depths")
	assert_not_null(boss)
	assert_eq(int(boss.max_hp), 3800)
	assert_eq(int(boss.attack), 246)
	assert_eq(int(boss.defense), 228)
	assert_almost_eq(float(boss.attack_speed), 1.5, 0.001)


func test_unlocked_from_start() -> void:
	GameState.dungeon_progress = {}
	if Constants.NEREION_FLAGSHIP_PLAYABLE:
		assert_true(GameState.is_dungeon_unlocked(DID), "進行解放なし")
	else:
		assert_false(GameState.is_dungeon_unlocked(DID), "第3弾OFF時は未解放扱い")


func test_debug_full_unlock_lists_flagship() -> void:
	## PLAYABLE=false でもデバッグセーブならイベント一覧に載る。
	GameState.debug_full_unlock = true
	assert_true(GameState.is_dungeon_unlocked(DID))
	const _Sched := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
	assert_true(_Sched.is_open_now(DID), "デバッグ常時開放")


func test_hourly_windows_jst() -> void:
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 9, 6, 2, 30))
	assert_true(_Sched.is_open_now(DID), "2時台は開放")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 9, 6, 3, 0))
	assert_false(_Sched.is_open_now(DID), "3時は閉鎖（クロノス帯）")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 9, 6, 5, 0))
	assert_true(_Sched.is_open_now(DID), "5時台は開放")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 9, 6, 8, 59))
	assert_true(_Sched.is_open_now(DID), "8時台は開放")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 9, 6, 11, 0))
	assert_true(_Sched.is_open_now(DID), "11時台は開放")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 9, 6, 12, 0))
	assert_false(_Sched.is_open_now(DID), "12時は閉鎖")


func test_schedule_label() -> void:
	assert_eq(_Sched.open_schedule_label(DID), "毎日 2/5/8/11時〜各1時間")


func test_set_bonus_and_pieces() -> void:
	assert_eq(_Sets.set_id_for_dungeon(DID), _Sets.SET_NEREION_TIDEBOND)
	assert_eq(_Sets.all_piece_ids(_Sets.SET_NEREION_TIDEBOND).size(), 7)
	var bonus: Dictionary = _Sets.BONUS[_Sets.SET_NEREION_TIDEBOND]
	assert_almost_eq(float(bonus.get("incoming_mult", 1.0)), 0.90, 0.001)
	assert_almost_eq(float(bonus.get("heal_received_mult", 1.0)), 1.20, 0.001)


func test_field_and_banner_assets() -> void:
	assert_true(FileAccess.file_exists(
		"res://assets/dungeon/nereion_flagship/env/BG_Battle_NereionFlagship.png"
	))
	assert_true(FileAccess.file_exists(
		"res://assets/ui/dungeon/BAN_DG_NereionFlagship.png"
	))
	assert_true(FileAccess.file_exists(
		"res://assets/dungeon/nereion_flagship/ICO_DG_NereionFlagship.png"
	))
	assert_eq(
		BiomeBannerHelper.resolve_path(DID),
		"res://assets/ui/dungeon/BAN_DG_NereionFlagship.png"
	)
	assert_eq(
		str(IconPaths.ICON_MAP.get("dungeon:nereion_flagship", "")),
		"res://assets/dungeon/nereion_flagship/ICO_DG_NereionFlagship.png"
	)


func test_descent_swarm() -> void:
	var prev_tier: int = GameState.current_dungeon_tier
	GameState.current_dungeon_tier = 0
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data(DID)
	dc.current_room_type = Enums.RoomType.COMBAT
	assert_true(dc._is_descent_event_dungeon())
	GameState.current_dungeon_tier = prev_tier


func _unix_for_jst(year: int, month: int, day: int, hour: int, minute: int) -> int:
	var as_utc_like: int = int(
		Time.get_unix_time_from_datetime_dict({
			"year": year,
			"month": month,
			"day": day,
			"hour": hour,
			"minute": minute,
			"second": 0,
		})
	)
	return as_utc_like - (9 * 3600)
