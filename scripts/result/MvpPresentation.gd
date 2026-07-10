class_name MvpPresentation
extends RefCounted

## MVP 画面演出 SSOT（P3-UX-RESULT-005）。

const BG_PATH: String = "res://assets/ui/result/BG_Result_Mvp.png"
const DEFAULT_BG_PATH: String = "res://assets/ui/UI_BG_Result.png"
const FRAME_HERO_PATH: String = "res://assets/ui/result/FRAME_Mvp_Hero.png"
const CROWN_ICON_PATH: String = "res://assets/ui/result/ICO_Mvp_Crown.png"

const COLOR_GOLD: Color = Color(0.92, 0.78, 0.34)
const COLOR_STAT_DAMAGE: Color = Color(1.0, 0.55, 0.42)
const COLOR_STAT_HIT: Color = Color(1.0, 0.86, 0.38)
const COLOR_STAT_HEAL: Color = Color(0.45, 0.95, 0.58)
const COLOR_STAT_SCORE: Color = Color(0.78, 0.62, 1.0)

const HERO_PORTRAIT_PX: float = 128.0
const RUNNER_PORTRAIT_PX: float = 84.0
const PODIUM_MIN_HEIGHT: float = 220.0

const STAT_DAMAGE_ICON: String = "res://assets/ui/batch2/ICO_WPN_IronSword.png"
const STAT_HIT_ICON: String = "res://assets/ui/batch2/ICO_WPN_FrostBlade.png"
const STAT_HEAL_ICON: String = "res://assets/ui/batch2/ICO_HP.png"
const STAT_SCORE_ICON: String = "res://assets/ui/batch2/ICO_Gold.png"

const BACKDROP_HEADER_BG: Color = Color(0.04, 0.05, 0.1, 0.9)
const BACKDROP_BODY_BG: Color = Color(0.03, 0.04, 0.08, 0.86)
const BACKDROP_PODIUM_BG: Color = Color(0.02, 0.03, 0.07, 0.82)
const BACKDROP_STAT_BG: Color = Color(0.05, 0.06, 0.12, 0.94)
const BACKDROP_BORDER: Color = Color(0.78, 0.64, 0.28, 0.62)
const BACKDROP_BORDER_SOFT: Color = Color(0.55, 0.48, 0.32, 0.45)
const SCRIM_COLOR: Color = Color(0.02, 0.03, 0.06, 0.48)
const TEXT_ON_BACKDROP: Color = Color(0.96, 0.94, 0.9)
const TEXT_MUTED_ON_BACKDROP: Color = Color(0.78, 0.8, 0.86)


static func timings(fast: bool = false) -> Dictionary:
	if fast:
		return {
			"header": 0.18,
			"podium": 0.22,
			"stat_gap": 0.08,
			"skill": 0.16,
			"subtitle": 0.14,
			"sparkle_delay": 0.12,
		}
	return {
		"header": 0.28,
		"podium": 0.34,
		"stat_gap": 0.12,
		"skill": 0.22,
		"subtitle": 0.18,
		"sparkle_delay": 0.18,
	}


static func podium_layout(ranked: Array) -> Array:
	var out: Array = []
	if ranked.is_empty():
		return out
	out.append({"entry": ranked[0], "slot": "center", "scale": 1.0, "hero": true, "rank": 1})
	if ranked.size() > 1:
		out.append({"entry": ranked[1], "slot": "left", "scale": 0.78, "hero": false, "rank": 2})
	if ranked.size() > 2:
		out.append({"entry": ranked[2], "slot": "right", "scale": 0.78, "hero": false, "rank": 3})
	return out


static func pick_subtitle(entry: Dictionary) -> String:
	var damage: int = int(entry.get("damage_total", 0))
	var heal: int = int(entry.get("heal_total", 0))
	var max_hit: int = int(entry.get("damage_max_hit", 0))
	var skill_name: String = str(entry.get("damage_max_skill_name", ""))
	if heal > damage and heal >= max_hit:
		return "今回の守りの要 — 回復が隊を支えた"
	if max_hit >= damage and max_hit > 0 and not skill_name.is_empty():
		return "一撃の英雄 — %s が戦局を決した" % skill_name
	if damage > 0:
		return "攻撃の要 — 最多ダメージで隊を牽引した"
	return "今回の MVP — 探索を勝ち抜いた"


static func stat_cards(entry: Dictionary) -> Array:
	return [
		{
			"key": "与ダメージ",
			"value": str(int(entry.get("damage_total", 0))),
			"icon": STAT_DAMAGE_ICON,
			"color": COLOR_STAT_DAMAGE,
		},
		{
			"key": "最大ヒット",
			"value": str(int(entry.get("damage_max_hit", 0))),
			"icon": STAT_HIT_ICON,
			"color": COLOR_STAT_HIT,
		},
		{
			"key": "回復量",
			"value": str(int(entry.get("heal_total", 0))),
			"icon": STAT_HEAL_ICON,
			"color": COLOR_STAT_HEAL,
		},
		{
			"key": "MVPスコア",
			"value": str(int(entry.get("score", 0))),
			"icon": STAT_SCORE_ICON,
			"color": COLOR_STAT_SCORE,
		},
	]


static func backdrop_style(tier: String = "body") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(1)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	match tier:
		"header":
			style.bg_color = BACKDROP_HEADER_BG
			style.border_color = BACKDROP_BORDER
			style.set_corner_radius_all(10)
			style.content_margin_left = 16
			style.content_margin_right = 16
			style.content_margin_top = 10
			style.content_margin_bottom = 10
		"podium":
			style.bg_color = BACKDROP_PODIUM_BG
			style.border_color = BACKDROP_BORDER_SOFT
			style.set_corner_radius_all(6)
			style.content_margin_left = 10
			style.content_margin_right = 10
			style.content_margin_top = 6
			style.content_margin_bottom = 6
		"stat":
			style.bg_color = BACKDROP_STAT_BG
			style.border_color = BACKDROP_BORDER_SOFT
			style.set_corner_radius_all(8)
		"lower":
			style.bg_color = BACKDROP_BODY_BG
			style.border_color = BACKDROP_BORDER_SOFT
			style.set_corner_radius_all(12)
			style.content_margin_left = 14
			style.content_margin_right = 14
			style.content_margin_top = 12
			style.content_margin_bottom = 12
		_:
			style.bg_color = BACKDROP_BODY_BG
			style.border_color = BACKDROP_BORDER_SOFT
	return style
