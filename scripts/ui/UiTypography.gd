class_name UiTypography
extends RefCounted

## 三層フォント（P3-UI-TYPE-001 / P3-UI3-001）
## — 本文 Noto Sans JP（wght 800） / 見出し・タイトル Shippori Mincho B1（金セリフ・モック準拠）
## / 戦闘・数字インパクト DelaGothicOne。

const BODY_FONT_PATH: String = "res://assets/fonts/NotoSansJP-VariableFont_wght.ttf"
const DISPLAY_FONT_PATH: String = "res://assets/fonts/ShipporiMinchoB1-Bold.ttf"
const IMPACT_FONT_PATH: String = "res://assets/fonts/DelaGothicOne-Regular.ttf"
## Noto Sans JP Variable の本文ウェイト。
## 600/700 では Mobile レンダラ＋小サイズ UI で薄く見えるため ExtraBold 相当。
const BODY_FONT_WEIGHT: float = 800.0
## OpenType 'wght' タグ（整数）。文字列キーだけに頼ると環境で効かないことがある。
const BODY_WGHT_TAG: int = 0x77676874
## 可変フォントでも足りないときの合成太字（0=なし）。可読性優先で軽く掛ける。
const BODY_EMBOLDEN: float = 0.35

## 画面タイトルの飾り（モックの「✦〜✦」金飾 / P3-UI3-001）。
const TITLE_ORNAMENT_LEFT: String = "✦ "
const TITLE_ORNAMENT_RIGHT: String = " ✦"

const SIZE_BODY: int = 26
const SIZE_BODY_SMALL: int = 22
const SIZE_CAPTION: int = 18
const SIZE_DISPLAY: int = 24
const SIZE_DISPLAY_TITLE: int = 28
const SIZE_BUTTON: int = 24
const SIZE_NAV: int = 13
const SIZE_LOG: int = 22

const COLOR_BODY: Color = Color(0.95, 0.92, 0.86, 1.0)
const COLOR_SUB: Color = Color(0.88, 0.84, 0.76, 1.0)
const COLOR_GOLD: Color = Color(0.98, 0.88, 0.48, 1.0)
const COLOR_MUTED: Color = Color(0.82, 0.80, 0.76, 1.0)
const COLOR_LOG: Color = Color(0.90, 0.88, 0.94, 1.0)
const COLOR_LOCKED: Color = Color(0.58, 0.56, 0.52, 1.0)

const OUTLINE_BODY: int = 4
const OUTLINE_DISPLAY: int = 4
const OUTLINE_MENU: int = 3
const OUTLINE_STRONG: int = 5

static var _body_font: Font
static var _display_font: Font
static var _impact_font: Font

static func body_font() -> Font:
	if _body_font == null and ResourceLoader.exists(BODY_FONT_PATH):
		var base: FontFile = load(BODY_FONT_PATH) as FontFile
		if base != null:
			var variation := FontVariation.new()
			variation.base_font = base
			# 文字列キーと整数タグの両方を入れ、テーマ／ランタイムで確実に wght を効かせる。
			variation.variation_opentype = {
				"wght": BODY_FONT_WEIGHT,
				BODY_WGHT_TAG: BODY_FONT_WEIGHT,
			}
			variation.variation_embolden = BODY_EMBOLDEN
			_body_font = variation
	return _body_font

static func display_font() -> Font:
	if _display_font == null and ResourceLoader.exists(DISPLAY_FONT_PATH):
		_display_font = load(DISPLAY_FONT_PATH) as Font
	if _display_font == null:
		return impact_font()
	return _display_font

## 戦闘ダメージ数字・強調用（旧 display）。
static func impact_font() -> Font:
	if _impact_font == null and ResourceLoader.exists(IMPACT_FONT_PATH):
		_impact_font = load(IMPACT_FONT_PATH) as Font
	return _impact_font

static func menu_font() -> Font:
	return display_font()

## 画面タイトル用の「✦ 〜 ✦」金飾（多重適用は防止）。
static func decorate_title_text(text: String) -> String:
	if text.begins_with(TITLE_ORNAMENT_LEFT):
		return text
	return TITLE_ORNAMENT_LEFT + text + TITLE_ORNAMENT_RIGHT

## 画面ヘッダーのタイトルへ 金セリフ＋✦飾り を一括適用（P3-UI3-001）。
static func apply_screen_title(label: Label, size: int = SIZE_DISPLAY) -> void:
	label.text = decorate_title_text(label.text)
	apply_display(label, size, COLOR_GOLD)

static func _apply_outline(node: Control, outline_size: int) -> void:
	if outline_size <= 0:
		return
	node.add_theme_constant_override("outline_size", outline_size)
	node.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))

static func apply_body(
	label: Label,
	size: int = SIZE_BODY,
	color: Color = COLOR_BODY,
	outline_size: int = OUTLINE_BODY
) -> void:
	var font: Font = body_font()
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	_apply_outline(label, outline_size)

static func apply_display(
	label: Label,
	size: int = SIZE_DISPLAY,
	color: Color = COLOR_GOLD,
	outline_size: int = OUTLINE_DISPLAY
) -> void:
	var font: Font = display_font()
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	_apply_outline(label, outline_size)

static func apply_caption(label: Label, color: Color = COLOR_SUB) -> void:
	apply_body(label, SIZE_CAPTION, color, OUTLINE_BODY)

static func apply_menu_label(
	label: Label,
	size: int,
	color: Color = COLOR_BODY,
	outline_size: int = OUTLINE_MENU
) -> void:
	var font: Font = menu_font()
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	_apply_outline(label, outline_size)

static func apply_button(button: BaseButton, locked: bool = false) -> void:
	apply_menu_button(button, locked)

static func apply_menu_button(button: BaseButton, locked: bool = false) -> void:
	var font: Font = body_font()
	if font != null:
		button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", SIZE_BODY_SMALL)
	var color: Color = COLOR_LOCKED if locked else COLOR_BODY
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_disabled_color", COLOR_LOCKED)
	_apply_outline(button, OUTLINE_BODY)

static func apply_nav_button(button: BaseButton, size: int = SIZE_NAV) -> void:
	var font: Font = menu_font()
	if font != null:
		button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", COLOR_BODY)
	button.add_theme_color_override("font_disabled_color", COLOR_LOCKED)
	_apply_outline(button, OUTLINE_MENU)

static func apply_log_rich(entry: RichTextLabel, size: int = SIZE_LOG, color: Color = COLOR_LOG) -> void:
	var font: Font = body_font()
	if font != null:
		entry.add_theme_font_override("normal_font", font)
	entry.add_theme_font_size_override("normal_font_size", size)
	entry.add_theme_color_override("default_color", color)
