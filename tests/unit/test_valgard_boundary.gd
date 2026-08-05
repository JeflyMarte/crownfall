extends GutTest

## P3-DG-VALGARD-DESCENT-001 — ストームクラウン境界廊（時間帯イベント）

const _Sched := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
const DID := "valgard_boundary"


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
	assert_not_null(data, "valgard_boundary.tres")
	assert_eq(str(data.id), DID)
	assert_eq(str(data.route_type), "event")
	assert_eq(str(data.boss_id), "valgard")
	assert_eq(str(data.display_name), "境界の番　降臨")
	assert_eq(int(data.daily_attempt_limit), 0)
	assert_true(bool(data.disable_wandering))
	assert_eq(str(data.unlock_after_dungeon_id), "")
	var bison_n: int = 0
	var has_moss: bool = false
	for raw in data.enemy_pool:
		var eid: String = str(raw)
		if eid == "rock_bison":
			bison_n += 1
		if eid == "moss_boar":
			has_moss = true
	assert_gte(bison_n, 1, "ロックバイソン通常")
	assert_true(has_moss, "ウィスパーウッド寄り（モスボア）")
	bison_n = 0
	for raw in data.elite_pool:
		if str(raw) == "rock_bison":
			bison_n += 1
	assert_gte(bison_n, 1, "ロックバイソン elite")


func test_boss_stats() -> void:
	var boss: Resource = DataRegistry.get_enemy_data("valgard")
	assert_not_null(boss)
	assert_eq(int(boss.max_hp), 3600)
	## 全ボス案A横展開後の ATK（旧 210）。
	assert_eq(int(boss.attack), 254)
	assert_eq(int(boss.defense), 220)
	assert_eq(str(boss.attack_element), "holy")


func test_unlocked_from_start() -> void:
	GameState.dungeon_progress = {}
	assert_true(GameState.is_dungeon_unlocked(DID), "進行解放なし")


func test_hourly_windows_jst() -> void:
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 1, 30))
	assert_true(_Sched.is_open_now(DID), "1時台は開放")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 2, 0))
	assert_false(_Sched.is_open_now(DID), "2時は閉鎖")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 4, 0))
	assert_true(_Sched.is_open_now(DID), "4時台は開放")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 0, 30))
	assert_false(_Sched.is_open_now(DID), "0時台はクロノス枠で閉鎖")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 10, 59))
	assert_true(_Sched.is_open_now(DID), "10時台は開放")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 11, 0))
	assert_false(_Sched.is_open_now(DID), "11時は閉鎖")


func test_can_attempt_follows_window() -> void:
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 7, 15))
	assert_true(GameState.can_attempt_event_dungeon(DID))
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 3, 0))
	assert_false(GameState.can_attempt_event_dungeon(DID))


func test_next_open_label() -> void:
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 2, 0))
	assert_eq(_Sched.next_open_label(DID), "次の出現 4:00")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 1, 10))
	assert_eq(_Sched.next_open_label(DID), "")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 12, 0))
	assert_eq(_Sched.next_open_label(DID), "次の出現 1:00")


func test_debug_always_open() -> void:
	_Sched.set_debug_weekday_override(-2)
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 14, 0))
	assert_true(_Sched.is_open_now(DID))


func test_field_and_banner_assets() -> void:
	assert_true(FileAccess.file_exists(
		"res://assets/dungeon/valgard_boundary/env/BG_Battle_ValgardBoundary.png"
	))
	assert_true(FileAccess.file_exists(
		"res://assets/ui/dungeon/BAN_DG_ValgardBoundary.png"
	))
	assert_true(FileAccess.file_exists(
		"res://assets/dungeon/valgard_boundary/ICO_DG_ValgardBoundary.png"
	))
	var ban_path: String = BiomeBannerHelper.resolve_path(DID)
	assert_eq(ban_path, "res://assets/ui/dungeon/BAN_DG_ValgardBoundary.png")
	assert_eq(
		str(IconPaths.ICON_MAP.get("dungeon:valgard_boundary", "")),
		"res://assets/dungeon/valgard_boundary/ICO_DG_ValgardBoundary.png"
	)


func test_boss_art_assets() -> void:
	assert_true(FileAccess.file_exists("res://assets/battle/bosses/BOSS_Valgard_Sheet.png"))
	assert_true(FileAccess.file_exists("res://resources/animation/BOSS_Valgard.tres"))
	assert_true(FileAccess.file_exists("res://assets/codex/enemies/ART_BOSS_Valgard.png"))
	assert_true(FileAccess.file_exists("res://assets/ui/combat/enemy_icons/ICO_ENM_Turn_Valgard.png"))
	assert_eq(
		str(IconPaths.ICON_MAP.get("enemy:valgard", "")),
		"res://assets/codex/enemies/ART_BOSS_Valgard.png"
	)
	assert_eq(
		str(IconPaths.ICON_MAP.get("enemy_turn:valgard", "")),
		"res://assets/ui/combat/enemy_icons/ICO_ENM_Turn_Valgard.png"
	)


func test_bgm_mapping() -> void:
	const _BgmCatalog := preload("res://scripts/audio/BgmCatalog.gd")
	assert_true(FileAccess.file_exists("res://assets/audio/bgm/valgard_boundary.mp3"))
	assert_true(FileAccess.file_exists("res://assets/audio/bgm/valgard.mp3"))
	assert_eq(_BgmCatalog.explore_bgm_for_dungeon(DID), _BgmCatalog.ID_VALGARD_BOUNDARY)
	assert_eq(_BgmCatalog.battle_bgm_for_dungeon(DID), _BgmCatalog.ID_VALGARD_BOUNDARY)
	assert_eq(_BgmCatalog.boss_bgm_for_dungeon(DID), _BgmCatalog.ID_VALGARD)


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
