class_name EventWeekRotation
extends RefCounted

## 6 週ローテ「野外の変化」（P3-EVT-WEEK-002）。端末週 = JST 月曜 5:00 起点（7日）。

const _Schedule := preload("res://scripts/event/EventScheduleHelper.gd")
const _EventData := preload("res://scripts/data/EventData.gd")

const ANCHOR_DATE_JST: String = "2026-07-01"
const WEEK_SECONDS: int = 7 * 86400

const MAIN_BIOME_IDS: Array[String] = [
	Constants.MOURNGATE_DUNGEON_ID,
	"whisperwood",
	"mistfen",
	"blackshore",
	"frostridge",
]

const WEEK_DEFINITIONS: Array[Dictionary] = [
	{
		"modifier_type": "exp",
		"modifier_mult": 1.5,
		"title": "経験記録増加週",
		"banner_desc": "戦闘経験値 ×1.5",
		"description": "ギルド報告：各地で戦闘データの取得効率が上昇している。今週の探索では経験値記録が増える。",
	},
	{
		"modifier_type": "gold",
		"modifier_mult": 1.5,
		"title": "調査報酬増加週",
		"banner_desc": "戦闘ゴールド ×1.5",
		"description": "ギルド報告：補給局が追加報酬を配分した。今週の探索ではゴールド入手が増える。",
	},
	{
		"modifier_type": "weapon_drop",
		"modifier_mult": 1.5,
		"title": "遺物回収週",
		"banner_desc": "武器ドロップ率 ×1.5",
		"description": "ギルド報告：遺物反応が活発化。今週は撃破時の武器直ドロップ率が上がる。",
	},
	{
		"modifier_type": "codex",
		"modifier_mult": 2.0,
		"title": "生態活発期",
		"banner_desc": "図鑑調査 ×2",
		"description": "ギルド報告：未確認個体の目撃が増加。今週は撃破時の図鑑記録が加速する。",
	},
	{
		"modifier_type": "featured_biome",
		"modifier_mult": 1.5,
		"title": "注目区域調査",
		"banner_desc": "注目区域 経験値/ゴールド ×1.5",
		"description": "ギルド指定の重点調査区域。今週は当該区域での報酬が増える。",
	},
	{
		"modifier_type": "elite_material",
		"modifier_mult": 1.5,
		"title": "高品質素材の澱",
		"banner_desc": "エリート素材 ×1.5",
		"description": "ギルド報告：エリート級個体からの素材採取が好調。今週は高品質欠片の入手量が増える。",
	},
]


static func absolute_week_index(now_unix: int) -> int:
	var anchor: int = _Schedule.jst_day_start_unix(ANCHOR_DATE_JST)
	if now_unix < anchor:
		return 0
	return int((now_unix - anchor) / WEEK_SECONDS)


static func week_in_cycle(now_unix: int) -> int:
	return absolute_week_index(now_unix) % WEEK_DEFINITIONS.size()


static func featured_biome_id(now_unix: int) -> String:
	var cycle: int = absolute_week_index(now_unix) / WEEK_DEFINITIONS.size()
	if MAIN_BIOME_IDS.is_empty():
		return ""
	return MAIN_BIOME_IDS[cycle % MAIN_BIOME_IDS.size()]


static func build_active_event(now_unix: int) -> Resource:
	var abs_week: int = absolute_week_index(now_unix)
	var cycle_week: int = week_in_cycle(now_unix)
	var def: Dictionary = WEEK_DEFINITIONS[cycle_week]
	var event: Resource = _EventData.new()
	event.id = "field_week_%d" % cycle_week
	event.title = str(def.get("title", ""))
	event.tag_text = "今週の野外"
	event.banner_desc = str(def.get("banner_desc", ""))
	event.description = str(def.get("description", ""))
	event.modifier_type = str(def.get("modifier_type", ""))
	event.modifier_mult = float(def.get("modifier_mult", 1.0))
	var start_unix: int = _Schedule.jst_day_start_unix(ANCHOR_DATE_JST) + abs_week * WEEK_SECONDS
	var end_unix: int = start_unix + WEEK_SECONDS
	event.start_date_jst = _unix_to_jst_date(start_unix)
	event.end_date_jst = _unix_to_jst_date(end_unix)
	if str(event.modifier_type) == "featured_biome":
		event.featured_biome_id = featured_biome_id(now_unix)
		var biome: Resource = DataRegistry.get_dungeon_data(event.featured_biome_id)
		if biome != null and not str(biome.display_name).is_empty():
			event.title = "注目区域 — %s" % str(biome.display_name)
			event.banner_desc = "%s で 経験値/ゴールド ×%.1f" % [
				str(biome.display_name),
				event.modifier_mult,
			]
	return event


static func seconds_until_week_end(now_unix: int) -> int:
	var abs_week: int = absolute_week_index(now_unix)
	var end_unix: int = _Schedule.jst_day_start_unix(ANCHOR_DATE_JST) + (abs_week + 1) * WEEK_SECONDS
	return maxi(0, end_unix - now_unix)


static func featured_biome_display_name(now_unix: int) -> String:
	var biome_id: String = featured_biome_id(now_unix)
	if biome_id.is_empty():
		return ""
	var data: Resource = DataRegistry.get_dungeon_data(biome_id)
	if data == null:
		return biome_id
	return str(data.display_name)


static func _unix_to_jst_date(unix: int) -> String:
	var dict: Dictionary = Time.get_datetime_dict_from_unix_time(unix + _Schedule.JST_OFFSET_SEC)
	return "%04d-%02d-%02d" % [int(dict.year), int(dict.month), int(dict.day)]
