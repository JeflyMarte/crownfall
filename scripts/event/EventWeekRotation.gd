class_name EventWeekRotation
extends RefCounted

## 野外速報（P3-EVT-FIELD-001）。30分スロット＋重み付きプール。
## 旧名 EventWeekRotation を維持（呼び出し互換）。週次ローテは廃止。

const _Schedule := preload("res://scripts/event/EventScheduleHelper.gd")
const _EventData := preload("res://scripts/data/EventData.gd")

const ANCHOR_DATE_JST: String = "2026-07-01"
## 30分スロット（全端末同時）。
const SLOT_SECONDS: int = 30 * 60
## 旧テスト互換エイリアス（週秒数は使わない）。
const WEEK_SECONDS: int = SLOT_SECONDS

const MAIN_BIOME_IDS: Array[String] = [
	Constants.MOURNGATE_DUNGEON_ID,
	"whisperwood",
	"mistfen",
	"blackshore",
	"frostridge",
]

## id / weight / modifier_type / modifier_mult / title / banner_desc / description
## ＋任意: weather_id
const SLOT_DEFINITIONS: Array[Dictionary] = [
	{
		"id": "none",
		"weight": 40,
		"modifier_type": "none",
		"modifier_mult": 1.0,
		"title": "穏やかな野外",
		"banner_desc": "特記なし",
		"description": "ギルド報告：いまのところ大きな変化は観測されていない。いつもの調子で調査してよい。",
	},
	{
		"id": "weather_rain",
		"weight": 7,
		"modifier_type": "weather",
		"modifier_mult": 1.0,
		"weather_id": "rain",
		"title": "雨の気配",
		"banner_desc": "天候：雨が続きやすい",
		"description": "ギルド報告：広域で降雨が優勢。探索中の天候は雨に固定されやすい。",
	},
	{
		"id": "weather_night",
		"weight": 7,
		"modifier_type": "weather",
		"modifier_mult": 1.0,
		"weather_id": "night",
		"title": "夜の帳",
		"banner_desc": "天候：夜が続きやすい",
		"description": "ギルド報告：日照が弱く、夜寄りの気象が優勢。探索中の天候は夜に固定されやすい。",
	},
	{
		"id": "weather_fog",
		"weight": 7,
		"modifier_type": "weather",
		"modifier_mult": 1.0,
		"weather_id": "fog",
		"title": "霧の蔓延",
		"banner_desc": "天候：霧が続きやすい",
		"description": "ギルド報告：視程不良の霧が広がっている。探索中の天候は霧に固定されやすい。",
	},
	{
		"id": "wander_duck",
		"weight": 6,
		"modifier_type": "wander_duck",
		"modifier_mult": 4.0,
		"title": "コズミックダック目撃増",
		"banner_desc": "放浪ダック出現率↑",
		"description": "ギルド報告：通常探索でもコズミックダックの目撃が増えている（日次裂け目とは別枠）。",
	},
	{
		"id": "wander_raven",
		"weight": 6,
		"modifier_type": "wander_raven",
		"modifier_mult": 4.0,
		"title": "宝冠レイヴン目撃増",
		"banner_desc": "放浪レイヴン出現率↑",
		"description": "ギルド報告：通常探索でも宝冠レイヴンの目撃が増えている（日次の巣とは別枠）。",
	},
	{
		"id": "enemy_level",
		"weight": 5,
		"modifier_type": "enemy_level",
		"modifier_mult": 2.0,
		"title": "強敵の波",
		"banner_desc": "敵レベル +2",
		"description": "ギルド報告：危険度の高い個体の比率が上がっている。敵レベルが一時的に上昇する。",
	},
	{
		"id": "swarm",
		"weight": 5,
		"modifier_type": "swarm",
		"modifier_mult": 2.5,
		"title": "群れの季節",
		"banner_desc": "敵の群れ出現率↑",
		"description": "ギルド報告：群れ行動が増えている。戦闘で複数体遭遇しやすくなる。",
	},
	{
		"id": "elite_rooms",
		"weight": 4,
		"modifier_type": "elite_rooms",
		"modifier_mult": 2.0,
		"title": "エリート目撃増",
		"banner_desc": "エリート部屋出現↑",
		"description": "ギルド報告：精鋭級の反応が強い。探索ルートでエリート遭遇が増えやすい。",
	},
	{
		"id": "exp",
		"weight": 3,
		"modifier_type": "exp",
		"modifier_mult": 1.2,
		"title": "経験記録の微増",
		"banner_desc": "戦闘経験値 ×1.2",
		"description": "ギルド報告：戦闘データの取得効率がわずかに上がっている。",
	},
	{
		"id": "gold",
		"weight": 3,
		"modifier_type": "gold",
		"modifier_mult": 1.2,
		"title": "調査報酬の微増",
		"banner_desc": "戦闘ゴールド ×1.2",
		"description": "ギルド報告：補給局が小規模な追加報酬を配分した。",
	},
	{
		"id": "weapon_drop",
		"weight": 3,
		"modifier_type": "weapon_drop",
		"modifier_mult": 1.2,
		"title": "遺物反応の微増",
		"banner_desc": "武器ドロップ率 ×1.2",
		"description": "ギルド報告：遺物反応がやや活発。武器直ドロップ率がわずかに上がる。",
	},
	{
		"id": "codex",
		"weight": 3,
		"modifier_type": "codex",
		"modifier_mult": 1.5,
		"title": "生態活発のひととき",
		"banner_desc": "図鑑調査 ×1.5",
		"description": "ギルド報告：未確認個体の目撃が一時的に増えている。",
	},
	{
		"id": "featured_biome",
		"weight": 3,
		"modifier_type": "featured_biome",
		"modifier_mult": 1.2,
		"title": "注目区域調査",
		"banner_desc": "注目区域 経験値/ゴールド ×1.2",
		"description": "ギルド指定の重点調査区域。当該区域での報酬がわずかに増える。",
	},
	{
		"id": "elite_material",
		"weight": 3,
		"modifier_type": "elite_material",
		"modifier_mult": 1.2,
		"title": "高品質素材のひととき",
		"banner_desc": "エリート素材 ×1.2",
		"description": "ギルド報告：エリート級からの素材採取が一時的に好調。",
	},
]


static func absolute_slot_index(now_unix: int) -> int:
	var anchor: int = _Schedule.jst_day_start_unix(ANCHOR_DATE_JST)
	if now_unix < anchor:
		return 0
	return int((now_unix - anchor) / SLOT_SECONDS)


## 旧 API 互換。
static func absolute_week_index(now_unix: int) -> int:
	return absolute_slot_index(now_unix)


static func total_weight() -> int:
	var total: int = 0
	for def: Dictionary in SLOT_DEFINITIONS:
		total += maxi(0, int(def.get("weight", 0)))
	return maxi(1, total)


static func definition_index_for_slot(slot_index: int) -> int:
	var total: int = total_weight()
	var roll: int = _stable_roll(slot_index, total)
	var acc: int = 0
	for i: int in SLOT_DEFINITIONS.size():
		acc += maxi(0, int(SLOT_DEFINITIONS[i].get("weight", 0)))
		if roll < acc:
			return i
	return SLOT_DEFINITIONS.size() - 1


static func week_in_cycle(now_unix: int) -> int:
	## 旧テスト互換: スロット種別インデックス。
	return definition_index_for_slot(absolute_slot_index(now_unix))


static func featured_biome_id(now_unix: int) -> String:
	if MAIN_BIOME_IDS.is_empty():
		return ""
	var slot: int = absolute_slot_index(now_unix)
	return MAIN_BIOME_IDS[slot % MAIN_BIOME_IDS.size()]


static func build_active_event(now_unix: int) -> Resource:
	var slot: int = absolute_slot_index(now_unix)
	var def_idx: int = definition_index_for_slot(slot)
	var def: Dictionary = SLOT_DEFINITIONS[def_idx]
	var event: Resource = _EventData.new()
	event.id = "field_slot_%s_%d" % [str(def.get("id", def_idx)), slot]
	event.title = str(def.get("title", ""))
	event.tag_text = "今日のダンジョン状態"
	event.banner_desc = str(def.get("banner_desc", ""))
	event.description = str(def.get("description", ""))
	event.modifier_type = str(def.get("modifier_type", ""))
	event.modifier_mult = float(def.get("modifier_mult", 1.0))
	var weather_id: String = str(def.get("weather_id", ""))
	if "weather_id" in event:
		event.weather_id = weather_id
	var start_unix: int = _Schedule.jst_day_start_unix(ANCHOR_DATE_JST) + slot * SLOT_SECONDS
	var end_unix: int = start_unix + SLOT_SECONDS
	event.start_date_jst = _unix_to_jst_datetime(start_unix)
	event.end_date_jst = _unix_to_jst_datetime(end_unix)
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


static func seconds_until_slot_end(now_unix: int) -> int:
	var slot: int = absolute_slot_index(now_unix)
	var end_unix: int = _Schedule.jst_day_start_unix(ANCHOR_DATE_JST) + (slot + 1) * SLOT_SECONDS
	return maxi(0, end_unix - now_unix)


static func seconds_until_week_end(now_unix: int) -> int:
	return seconds_until_slot_end(now_unix)


static func featured_biome_display_name(now_unix: int) -> String:
	var biome_id: String = featured_biome_id(now_unix)
	if biome_id.is_empty():
		return ""
	var data: Resource = DataRegistry.get_dungeon_data(biome_id)
	if data == null:
		return biome_id
	return str(data.display_name)


static func _stable_roll(slot_index: int, modulo: int) -> int:
	if modulo <= 0:
		return 0
	## 決定的・端末間一致（hash はセッション非依存の文字列ハッシュ）。
	var h: int = int(hash("crownfall_field_slot_%d" % slot_index))
	return absi(h) % modulo


static func _unix_to_jst_datetime(unix: int) -> String:
	var dict: Dictionary = Time.get_datetime_dict_from_unix_time(unix + _Schedule.JST_OFFSET_SEC)
	return "%04d-%02d-%02d %02d:%02d" % [
		int(dict.year),
		int(dict.month),
		int(dict.day),
		int(dict.hour),
		int(dict.minute),
	]


static func _unix_to_jst_date(unix: int) -> String:
	var dict: Dictionary = Time.get_datetime_dict_from_unix_time(unix + _Schedule.JST_OFFSET_SEC)
	return "%04d-%02d-%02d" % [int(dict.year), int(dict.month), int(dict.day)]
