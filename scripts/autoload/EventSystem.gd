extends Node

## 拠点「今週の野外の変化」（P3-EVT-WEEK-002）。6 週ローテ + 経済3週。DailyMission とは独立。

const PERIODIC_EVENTS_ENABLED: bool = true

signal event_updated

const _Schedule = preload("res://scripts/event/EventScheduleHelper.gd")
const _WeekRotation = preload("res://scripts/event/EventWeekRotation.gd")

const MOD_EXP: String = "exp"
const MOD_GOLD: String = "gold"
const MOD_WEAPON_DROP: String = "weapon_drop"
const MOD_CODEX: String = "codex"
const MOD_FEATURED_BIOME: String = "featured_biome"
const MOD_ELITE_MATERIAL: String = "elite_material"

var _cached_active_id: String = ""
var _debug_unix_override: int = -1

func ensure_active() -> void:
	var active: Resource = _resolve_active_event()
	var active_id: String = str(active.id) if active != null else ""
	if active_id != _cached_active_id:
		_cached_active_id = active_id
		event_updated.emit()

func is_event_running() -> bool:
	return get_active_event() != null

func get_active_event() -> Resource:
	ensure_active()
	return _resolve_active_event()

func get_featured_biome_id() -> String:
	var event_data: Resource = get_active_event()
	if event_data == null:
		return ""
	return str(event_data.featured_biome_id) if "featured_biome_id" in event_data else ""

func is_featured_biome_week() -> bool:
	var event_data: Resource = get_active_event()
	if event_data == null:
		return false
	return str(event_data.modifier_type) == MOD_FEATURED_BIOME

func get_modifier_mult(modifier_type: String) -> float:
	var event_data: Resource = get_active_event()
	if event_data == null:
		return 1.0
	var active_type: String = str(event_data.modifier_type)
	var mult: float = maxf(1.0, float(event_data.modifier_mult))
	if active_type == modifier_type:
		return _scope_mult(event_data, mult)
	if active_type == MOD_FEATURED_BIOME and modifier_type in [MOD_EXP, MOD_GOLD]:
		return _scope_mult(event_data, mult)
	return 1.0

func get_codex_kill_extra_count() -> int:
	var mult: float = get_modifier_mult(MOD_CODEX)
	if mult <= 1.0:
		return 0
	return maxi(0, int(round(mult - 1.0)))

func get_elite_material_amount(base_amount: int) -> int:
	var mult: float = get_modifier_mult(MOD_ELITE_MATERIAL)
	if mult <= 1.0 or base_amount <= 0:
		return base_amount
	return maxi(base_amount, int(round(float(base_amount) * mult)))

func modifier_label(modifier_type: String) -> String:
	match modifier_type:
		MOD_EXP:
			return "経験値"
		MOD_GOLD:
			return "ゴールド"
		MOD_WEAPON_DROP:
			return "武器ドロップ率"
		MOD_CODEX:
			return "図鑑調査"
		MOD_FEATURED_BIOME:
			return "注目区域報酬"
		MOD_ELITE_MATERIAL:
			return "ELITE素材"
		_:
			return modifier_type

func active_modifier_summary() -> String:
	var event_data: Resource = get_active_event()
	if event_data == null:
		return ""
	return str(event_data.banner_desc)

func run_intro_line() -> String:
	var event_data: Resource = get_active_event()
	if event_data == null:
		return ""
	var biome_line: String = ""
	if is_featured_biome_week():
		var biome_name: String = _featured_biome_display_name(event_data)
		if not biome_name.is_empty():
			biome_line = "（注目: %s）" % biome_name
	return "【今週の野外】%s%s" % [str(event_data.title), biome_line]

func countdown_text() -> String:
	if not PERIODIC_EVENTS_ENABLED:
		return "—"
	var remain: int = _WeekRotation.seconds_until_week_end(_current_unix())
	return _Schedule.format_countdown(remain)

func schedule_text(event_data: Resource) -> String:
	if event_data == null:
		return ""
	return "%s 〜 %s（週次・JST 5:00 切替）" % [
		str(event_data.start_date_jst),
		str(event_data.end_date_jst),
	]

func set_debug_unix_for_tests(unix: int) -> void:
	_debug_unix_override = unix
	_cached_active_id = ""
	ensure_active()

func clear_debug_unix_for_tests() -> void:
	_debug_unix_override = -1
	_cached_active_id = ""
	ensure_active()

func _current_unix() -> int:
	if _debug_unix_override >= 0:
		return _debug_unix_override
	return int(Time.get_unix_time_from_system())

func _resolve_active_event() -> Resource:
	if not PERIODIC_EVENTS_ENABLED:
		return null
	return _WeekRotation.build_active_event(_current_unix())

func _scope_mult(event_data: Resource, mult: float) -> float:
	var biome_id: String = ""
	if "featured_biome_id" in event_data:
		biome_id = str(event_data.featured_biome_id)
	if biome_id.is_empty():
		return mult
	var active: String = GameState.get_active_dungeon_id()
	return mult if active == biome_id else 1.0

func _featured_biome_display_name(event_data: Resource) -> String:
	var biome_id: String = str(event_data.featured_biome_id) if "featured_biome_id" in event_data else ""
	if biome_id.is_empty():
		return ""
	var data: Resource = DataRegistry.get_dungeon_data(biome_id)
	if data == null:
		return biome_id
	return str(data.display_name)
