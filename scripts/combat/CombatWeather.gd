class_name CombatWeather
extends RefCounted

## 天候（環境変化・P3-D101）。run 開始時に1つ抽選し DG 中は不変（敵Lv/地形と同じ扱い）。
## 効果は戦闘の中央フックに相乗りする:
##   属性補正（attack_element 別の与ダメ倍率）/ 全体の与ダメ・被ダメ倍率
## 数値・属性 id は ElementResolver(thunder/fire/dark/holy 等) に準拠する。

const CLEAR: String = ""
const RAIN: String = "rain"
const NIGHT: String = "night"
const FOG: String = "fog"

# 抽選重み（晴れ多め）。
const _WEIGHTS: Dictionary = {
	CLEAR: 55,
	RAIN: 15,
	NIGHT: 15,
	FOG: 15,
}

const _DEFS: Dictionary = {
	"rain": {
		"label": "雨",
		"element_mult": {"thunder": 1.15, "fire": 0.90},
		"outgoing_mult": 1.0,
		"incoming_mult": 1.0,
	},
	"night": {
		"label": "夜",
		"element_mult": {"dark": 1.15, "holy": 0.90},
		"outgoing_mult": 1.0,
		"incoming_mult": 1.0,
	},
	"fog": {
		"label": "霧",
		"element_mult": {},
		"outgoing_mult": 0.95,
		"incoming_mult": 0.95,
	},
}

static func normalize(weather: String) -> String:
	return weather if _DEFS.has(weather) else CLEAR

static func label(weather: String) -> String:
	if _DEFS.has(weather):
		return str(_DEFS[weather]["label"])
	return "晴れ"

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

# 重み付き抽選で天候 id を返す（""=晴れ含む）。
static func roll() -> String:
	var total: int = 0
	for w: String in _WEIGHTS:
		total += int(_WEIGHTS[w])
	var r: int = randi() % maxi(total, 1)
	for w: String in _WEIGHTS:
		r -= int(_WEIGHTS[w])
		if r < 0:
			return w
	return CLEAR
