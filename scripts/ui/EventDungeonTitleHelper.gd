class_name EventDungeonTitleHelper
extends RefCounted

## イベント／降臨／征討タイトルの色分け（P3-UX-EVENT-TITLE-TWOTONE-001）。
## 形式: 【本体】降臨／【本体】征討。曜日イベント等は単色。

const DESCENT_SUFFIX: String = "降臨"
const CONQUEST_SUFFIX: String = "征討"
const TITLE_SUFFIXES: PackedStringArray = [DESCENT_SUFFIX, CONQUEST_SUFFIX]

## 接尾「降臨／征討」共通色（バッジ）。
const COLOR_ROUTE_MARK: Color = Color(1.0, 0.74, 0.56, 1.0)
const COLOR_ROUTE_MARK_OUTLINE: Color = Color(0.78, 0.36, 0.18, 1.0)
## 後方互換エイリアス。
const COLOR_DESCENT_MARK: Color = COLOR_ROUTE_MARK
const COLOR_DESCENT_MARK_OUTLINE: Color = COLOR_ROUTE_MARK_OUTLINE

## 曜日イベント等の単色（従来のイベント名色）。
const COLOR_EVENT_PLAIN: Color = COLOR_ROUTE_MARK
const COLOR_EVENT_PLAIN_OUTLINE: Color = COLOR_ROUTE_MARK_OUTLINE

## 本体のテーマ色（dungeon_id → {color, outline}）。
const _BODY_THEME: Dictionary = {
	"chronos_mausoleum": {
		"color": Color(0.58, 0.90, 1.0, 1.0),
		"outline": Color(0.08, 0.28, 0.42, 1.0),
	},
	"valgard_boundary": {
		"color": Color(0.98, 0.82, 0.45, 1.0),
		"outline": Color(0.42, 0.22, 0.06, 1.0),
	},
	"nereion_flagship": {
		"color": Color(0.45, 0.78, 0.92, 1.0),
		"outline": Color(0.06, 0.28, 0.42, 1.0),
	},
	"north_reach": {
		"color": Color(0.72, 0.86, 1.0, 1.0),
		"outline": Color(0.12, 0.22, 0.40, 1.0),
	},
	"red_forge_depths": {
		"color": Color(1.0, 0.62, 0.38, 1.0),
		"outline": Color(0.42, 0.12, 0.06, 1.0),
	},
}


## display_name を body / suffix に分割。suffix 空＝2色対象外。
## 期待形式: 【潮脈王ネレイオン・デプス】降臨／【地図なき主アルバーク】征討（】直後の空白は除去）。
static func split_title(display_name: String) -> Dictionary:
	var full: String = display_name.strip_edges()
	if full.is_empty():
		return {"body": "", "suffix": ""}
	for suffix: String in TITLE_SUFFIXES:
		if not full.ends_with(suffix):
			continue
		var body: String = full.substr(0, full.length() - suffix.length())
		## 】直後・旧形式の全角空白を除去（strip_edges は半角空白のみ）。
		body = body.replace("　", " ").strip_edges()
		## 旧形式「本体　降臨」も許容（移行・テスト互換）。
		return {"body": body, "suffix": suffix}
	return {"body": full, "suffix": ""}


static func is_descent_twotone(display_name: String) -> bool:
	return is_route_twotone(display_name)


static func is_route_twotone(display_name: String) -> bool:
	return not str(split_title(display_name).get("suffix", "")).is_empty()


static func body_color(dungeon_id: String, unlocked: bool = true) -> Color:
	if not unlocked:
		return UiTypography.COLOR_SUB
	var theme: Dictionary = _BODY_THEME.get(dungeon_id, {}) as Dictionary
	if theme.is_empty():
		return COLOR_EVENT_PLAIN
	return theme.get("color", COLOR_EVENT_PLAIN) as Color


static func body_outline_color(dungeon_id: String) -> Color:
	var theme: Dictionary = _BODY_THEME.get(dungeon_id, {}) as Dictionary
	if theme.is_empty():
		return COLOR_EVENT_PLAIN_OUTLINE
	return theme.get("outline", COLOR_EVENT_PLAIN_OUTLINE) as Color


static func suffix_color(unlocked: bool = true) -> Color:
	return COLOR_ROUTE_MARK if unlocked else UiTypography.COLOR_SUB


static func suffix_outline_color() -> Color:
	return COLOR_ROUTE_MARK_OUTLINE


static func plain_event_color(unlocked: bool = true) -> Color:
	return COLOR_EVENT_PLAIN if unlocked else UiTypography.COLOR_SUB


static func color_to_bb_hex(color: Color) -> String:
	return "%02x%02x%02x" % [
		clampi(int(round(color.r * 255.0)), 0, 255),
		clampi(int(round(color.g * 255.0)), 0, 255),
		clampi(int(round(color.b * 255.0)), 0, 255),
	]


## 一覧 RichText 用。2色対象なら本体＋接尾、否则単色名。
static func title_bbcode(dungeon_id: String, display_name: String, unlocked: bool) -> String:
	if not unlocked:
		return "[color=#c9c4b8][b]%s[/b][/color]" % display_name
	var parts: Dictionary = split_title(display_name)
	var suffix: String = str(parts.get("suffix", ""))
	if suffix.is_empty():
		return "[color=#%s][b]%s[/b][/color]" % [
			color_to_bb_hex(plain_event_color(true)),
			display_name,
		]
	var body: String = str(parts.get("body", ""))
	return "[color=#%s][b]%s[/b][/color][color=#%s][b]%s[/b][/color]" % [
		color_to_bb_hex(body_color(dungeon_id, true)),
		body,
		color_to_bb_hex(suffix_color(true)),
		suffix,
	]
