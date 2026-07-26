extends GutTest

## 初回レリック／レジェンド／ミシックのニーナ案内。

const _Guide = preload("res://scripts/ui/NinaRareAcquireGuide.gd")
const _Helper = preload("res://scripts/ui/HubNinaNavHelper.gd")
const _EventDungeonSchedule = preload("res://scripts/dungeon/EventDungeonSchedule.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	EventSystem.set_debug_unix_for_tests(-1)
	_EventDungeonSchedule.set_debug_unix_override(_unix_jst(2026, 7, 26, 14, 0))
	_EventDungeonSchedule.clear_debug_weekday_override()
	GameState.debug_full_unlock = false


func after_each() -> void:
	EventSystem.set_debug_unix_for_tests(-1)
	_EventDungeonSchedule.clear_debug_unix_override()
	_EventDungeonSchedule.clear_debug_weekday_override()
	GameState.debug_full_unlock = false


func _unix_jst(year: int, month: int, day: int, hour: int, minute: int) -> int:
	var dt := {
		"year": year, "month": month, "day": day,
		"hour": hour, "minute": minute, "second": 0,
	}
	return int(Time.get_unix_time_from_datetime_dict(dt)) - 9 * 3600


func test_first_relic_queues_guide() -> void:
	assert_true(GameState.unlock_relic("relic_war_banner"))
	assert_true(_Guide.has_pending_guide())
	assert_eq(_Guide.peek_pending_guide_kind(), _Guide.KIND_RELIC)
	assert_false(_Guide.is_guide_done(_Guide.KIND_RELIC))
	assert_eq(GameState.pending_nina_nav_notices.size(), 0)


func test_second_relic_queues_nav_notice() -> void:
	_Guide.mark_guide_done(_Guide.KIND_RELIC)
	assert_true(GameState.unlock_relic("relic_war_banner"))
	assert_true(GameState.unlock_relic("relic_aegis_shard"))
	assert_false(_Guide.has_pending_guide())
	assert_gte(GameState.pending_nina_nav_notices.size(), 1)


func test_guide_lines_nonempty() -> void:
	for kind in [_Guide.KIND_RELIC, _Guide.KIND_LEGENDARY, _Guide.KIND_MYTHIC]:
		var lines: Array[String] = _Guide.guide_lines_for(kind)
		assert_gte(lines.size(), 2, kind)
		assert_true(lines[0].contains("祝福") or lines[0].contains("神話"), kind)


func test_nav_notices_consumed_into_rotation() -> void:
	_Guide.mark_guide_done(_Guide.KIND_LEGENDARY)
	_Guide.on_equipment_obtained(_make_legendary_weapon())
	assert_gte(GameState.pending_nina_nav_notices.size(), 1)
	var rot: Array[Dictionary] = _Helper.build_rotation()
	assert_eq(GameState.pending_nina_nav_notices.size(), 0)
	assert_true(str(rot[0].get("text", "")).contains("レジェンド") or str(rot[0].get("text", "")).contains("祝福"))


func test_heal_marks_done_when_already_owned() -> void:
	GameState.owned_relics.append("relic_war_banner")
	assert_false(_Guide.is_guide_done(_Guide.KIND_RELIC))
	_Guide.heal_flags_from_progress()
	assert_true(_Guide.is_guide_done(_Guide.KIND_RELIC))


func test_first_legendary_queues_guide() -> void:
	_Guide.on_equipment_obtained(_make_legendary_weapon())
	assert_true(_Guide.has_pending_guide())
	assert_eq(_Guide.peek_pending_guide_kind(), _Guide.KIND_LEGENDARY)


func _make_legendary_weapon() -> Resource:
	var inst: Resource = WeaponInstance.new()
	inst.instance_id = "test_leg_1"
	inst.weapon_id = "pharos_flare"
	inst.is_appraised = true
	return inst
