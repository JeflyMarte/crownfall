class_name CombatWeather
extends RefCounted

## 天候（環境変化・P3-D101 / P3-WEATHER-W1-A-001 / P3-WEATHER-BIOME-BIAS-001）。
## run 開始時に1つ抽選し DG 中は不変（敵Lv/地形と同じ扱い）。
## 効果は戦闘の中央フックに相乗りする:
##   属性補正（attack_element 別の与ダメ倍率）/ 全体の与ダメ・被ダメ倍率
## 数値・属性 id は ElementResolver(thunder/fire/ice/dark/holy 等) に準拠する。

const CLEAR: String = ""
const RAIN: String = "rain"
const NIGHT: String = "night"
const FOG: String = "fog"
const HEAT: String = "heat"
const SNOW: String = "snow"

const _AbyssDungeonConfig := preload("res://scripts/dungeon/AbyssDungeonConfig.gd")

# 共通抽選重み（晴れ多め・約45%。他は各約11%）。Biome 未定義／イベントDG用。
const _WEIGHTS: Dictionary = {
	CLEAR: 45,
	RAIN: 11,
	NIGHT: 11,
	FOG: 11,
	HEAT: 11,
	SNOW: 11,
}

## メイン5 Biome の天候重み（案A・合計100想定）。全天候は出るが偏らせる。
const _BIOME_WEIGHTS: Dictionary = {
	"mourngate": {
		CLEAR: 40,
		RAIN: 10,
		NIGHT: 22,
		FOG: 18,
		HEAT: 5,
		SNOW: 5,
	},
	"whisperwood": {
		CLEAR: 40,
		RAIN: 22,
		NIGHT: 10,
		FOG: 18,
		HEAT: 6,
		SNOW: 4,
	},
	"mistfen": {
		CLEAR: 35,
		RAIN: 18,
		NIGHT: 8,
		FOG: 30,
		HEAT: 5,
		SNOW: 4,
	},
	"blackshore": {
		CLEAR: 38,
		RAIN: 20,
		NIGHT: 18,
		FOG: 16,
		HEAT: 5,
		SNOW: 3,
	},
	"frostridge": {
		CLEAR: 40,
		RAIN: 6,
		NIGHT: 10,
		FOG: 12,
		HEAT: 4,
		SNOW: 28,
	},
}

## メイン以外で親 Biome に寄せる id（深層・同系統寄り道）。イベント専用は載せない。
const _BIOME_ALIAS: Dictionary = {
	"mistfen_depths": "mistfen",
	"frostwall_path": "frostridge",
	"north_reach": "frostridge",
	"red_forge_depths": "frostridge",
	"westbay_flats": "blackshore",
	"broken_marsh": "mistfen",
	"green_hollow": "mistfen",
	"blackshore_abyss": "blackshore",
}

const _DEFS: Dictionary = {
	"rain": {
		"label": "雨",
		"element_mult": {"thunder": 1.10, "fire": 0.95},
		"outgoing_mult": 1.0,
		"incoming_mult": 1.0,
	},
	"night": {
		"label": "夜",
		"element_mult": {"dark": 1.10, "holy": 0.95},
		"outgoing_mult": 1.0,
		"incoming_mult": 1.0,
	},
	"fog": {
		"label": "霧",
		"element_mult": {},
		"outgoing_mult": 0.97,
		"incoming_mult": 0.97,
	},
	"heat": {
		"label": "炎天",
		"element_mult": {"fire": 1.10, "ice": 0.95},
		"outgoing_mult": 1.0,
		"incoming_mult": 1.0,
	},
	"snow": {
		"label": "吹雪",
		"element_mult": {"ice": 1.10, "fire": 0.95},
		"outgoing_mult": 1.0,
		"incoming_mult": 1.0,
	},
}

static func normalize(weather: String) -> String:
	return weather if _DEFS.has(weather) else CLEAR


static func label(weather: String) -> String:
	if _DEFS.has(weather):
		return str(_DEFS[weather]["label"])
	return "晴れ"


## プレイヤー向け効果行（ギルド情報誌・図鑑と共有）。先頭に「・」は付けない。
static func effect_bullet_lines(weather: String) -> PackedStringArray:
	match normalize(weather):
		RAIN:
			return PackedStringArray([
				"雷属性の与ダメ +10%",
				"炎属性の与ダメ −5%",
			])
		NIGHT:
			return PackedStringArray([
				"闇属性の与ダメ +10%",
				"聖属性の与ダメ −5%",
			])
		FOG:
			return PackedStringArray([
				"味方の与ダメ ×0.97",
				"味方の被ダメ ×0.97（視界不良で双方手探り）",
			])
		HEAT:
			return PackedStringArray([
				"炎属性の与ダメ +10%",
				"氷属性の与ダメ −5%",
			])
		SNOW:
			return PackedStringArray([
				"氷属性の与ダメ +10%",
				"炎属性の与ダメ −5%",
			])
		_:
			return PackedStringArray(["戦闘補正なし"])


## 野外速報の「効果」欄用（固定されやすい＋戦闘効果）。
static func field_event_effect_summary(weather: String) -> String:
	var wid: String = normalize(weather)
	var lines: PackedStringArray = PackedStringArray()
	if wid == CLEAR:
		lines.append("・特記事項なし")
		return "\n".join(lines)
	lines.append("・探索中の天候が%sに固定されやすい" % label(wid))
	for line: String in effect_bullet_lines(wid):
		lines.append("・%s" % line)
	return "\n".join(lines)


## 情報誌：いま出ている天候だけの効果（非天候スロットでは出さない）。
static func bulletin_active_weather_text(weather: String) -> String:
	var wid: String = normalize(weather)
	if wid == CLEAR:
		return ""
	var lines: PackedStringArray = PackedStringArray([
		"【天候の効果】",
		"・%s" % label(wid),
	])
	for line: String in effect_bullet_lines(wid):
		lines.append("・%s" % line)
	return "\n".join(lines)


## 旧・全天候早見（情報誌では使わない。テスト／参照用）。
static func bulletin_reference_text() -> String:
	var lines: PackedStringArray = PackedStringArray([
		"【天候の効果】",
		"探索開始時に1つ抽選され、その探索中は変わりません。",
		"ダンジョンによって出やすい天候が変わります（例: フロストリッジは吹雪多め）。",
		"・晴れ：戦闘補正なし（いちばん出やすい）",
		"・雨：雷与ダメ+10%／炎与ダメ−5%",
		"・夜：闇与ダメ+10%／聖与ダメ−5%",
		"・霧：与ダメ・被ダメとも×0.97",
		"・炎天：炎与ダメ+10%／氷与ダメ−5%",
		"・吹雪：氷与ダメ+10%／炎与ダメ−5%",
	])
	return "\n".join(lines)


# attack_element に対する天候の与ダメ倍率（既定 1.0）。
static func element_multiplier(weather: String, attack_element: String) -> float:
	if attack_element.is_empty() or not _DEFS.has(weather):
		return 1.0
	var em: Dictionary = _DEFS[weather].get("element_mult", {})
	return float(em.get(attack_element, 1.0))


static func outgoing_multiplier(weather: String) -> float:
	if not _DEFS.has(weather):
		return 1.0
	return float(_DEFS[weather].get("outgoing_mult", 1.0))


static func incoming_multiplier(weather: String) -> float:
	if not _DEFS.has(weather):
		return 1.0
	return float(_DEFS[weather].get("incoming_mult", 1.0))


## dungeon_id → 天候テーブルの Biome キー（空＝共通テーブル）。
static func weather_biome_key(dungeon_id: String) -> String:
	if dungeon_id.is_empty():
		return ""
	if _BIOME_WEIGHTS.has(dungeon_id):
		return dungeon_id
	var abyss_parent: String = _AbyssDungeonConfig.parent_biome_id(dungeon_id)
	if not abyss_parent.is_empty() and _BIOME_WEIGHTS.has(abyss_parent):
		return abyss_parent
	var alias: String = str(_BIOME_ALIAS.get(dungeon_id, ""))
	if not alias.is_empty() and _BIOME_WEIGHTS.has(alias):
		return alias
	return ""


static func weights_for_dungeon(dungeon_id: String) -> Dictionary:
	var key: String = weather_biome_key(dungeon_id)
	if key.is_empty():
		return _WEIGHTS.duplicate()
	return (_BIOME_WEIGHTS[key] as Dictionary).duplicate()


# 重み付き抽選で天候 id を返す（""=晴れ含む）。Biome 無しは共通テーブル。
static func roll(dungeon_id: String = "") -> String:
	return _roll_with_weights(weights_for_dungeon(dungeon_id))


static func _roll_with_weights(weights: Dictionary) -> String:
	var total: int = 0
	for w: String in weights:
		total += maxi(0, int(weights[w]))
	if total <= 0:
		return CLEAR
	var r: int = randi() % total
	for w: String in weights:
		r -= maxi(0, int(weights[w]))
		if r < 0:
			return w
	return CLEAR
