class_name EventDungeonTitleHelper
extends RefCounted

## イベント／降臨タイトルの色分け（P3-UX-EVENT-TITLE-TWOTONE-001 案B）。
## 「本体　降臨」形式のみ2色。曜日イベント等は単色（既存薔薇金）。

const DESCENT_SUFFIX: String = "降臨"

## 接尾「降臨」共通色（バッジ）。
const COLOR_DESCENT_MARK: Color = Color(1.0, 0.74, 0.56, 1.0)
const COLOR_DESCENT_MARK_OUTLINE: Color = Color(0.78, 0.36, 0.18, 1.0)

## 曜日イベント等の単色（従来のイベント名色）。
const COLOR_EVENT_PLAIN: Color = COLOR_DESCENT_MARK
const COLOR_EVENT_PLAIN_OUTLINE: Color = COLOR_DESCENT_MARK_OUTLINE

## 降臨本体のテーマ色（dungeon_id → {color, outline}）。
const _BODY_THEME: Dictionary = {
	"chronos_mausoleum": {
		"color": Color(0.58, 0.90, 1.0, 1.0),
		"outline": Color(0.08, 0.28, 0.42, 1.0),
	},
	"valgard_boundary": {
		"color": Color(0.98, 0.82, 0.45, 1.0),
		"outline": Color(0.42, 0.22, 0.06, 1.0),
	},
}


## display_name を body / suffix に分割。suffix 空＝2色対象外。
static func split_title(display_name: String) -> Dictionary:
	var full: String = display_name.strip_edges()
	if full.is_empty() or not full.ends_with(DESCENT_SUFFIX):
		return {"body": full, "suffix": ""}
	var body: String = full.substr(0, full.length() - DESCENT_SUFFIX.length())
	## 直前の全角／半角スペースは本体側に残す（見た目の間隔）。
	return {"body": body, "suffix": DESCENT_SUFFIX}


static func is_descent_twotone(display_name: String) -> bool:
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
	return COLOR_DESCENT_MARK if unlocked else UiTypography.COLOR_SUB


static func suffix_outline_color() -> Color:
	return COLOR_DESCENT_MARK_OUTLINE


static func plain_event_color(unlocked: bool = true) -> Color:
	return COLOR_EVENT_PLAIN if unlocked else UiTypography.COLOR_SUB


static func color_to_bb_hex(color: Color) -> String:
	return "%02x%02x%02x" % [
		clampi(int(round(color.r * 255.0)), 0, 255),
		clampi(int(round(color.g * 255.0)), 0, 255),
		clampi(int(round(color.b * 255.0)), 0, 255),
	]


## 一覧 RichText 用。2色対象なら本体＋降臨、否则単色名。
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
