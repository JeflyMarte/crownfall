class_name UiTypography
extends RefCounted

## 二層フォント（P3-UI-TYPE-001）— 本文 Noto Sans JP / 見出し・戦闘 DelaGothicOne。

const BODY_FONT_PATH: String = "res://assets/fonts/NotoSansJP-VariableFont_wght.ttf"
const DISPLAY_FONT_PATH: String = "res://assets/fonts/DelaGothicOne-Regular.ttf"

const SIZE_BODY: int = 26
const SIZE_BODY_SMALL: int = 20
const SIZE_CAPTION: int = 16
const SIZE_DISPLAY: int = 24
const SIZE_DISPLAY_TITLE: int = 28
const SIZE_BUTTON: int = 24
const SIZE_LOG: int = 22

const COLOR_BODY: Color = Color(0.95, 0.92, 0.86, 1.0)
const COLOR_SUB: Color = Color(0.88, 0.84, 0.76, 1.0)
const COLOR_GOLD: Color = Color(0.98, 0.88, 0.48, 1.0)
const COLOR_MUTED: Color = Color(0.82, 0.80, 0.76, 1.0)
const COLOR_LOG: Color = Color(0.90, 0.88, 0.94, 1.0)
const COLOR_LOCKED: Color = Color(0.58, 0.56, 0.52, 1.0)

const OUTLINE_BODY: int = 2
const OUTLINE_DISPLAY: int = 4
const OUTLINE_STRONG: int = 5

static var _body_font: Font
static var _display_font: Font

static func body_font() -> Font:
	if _body_font == null and ResourceLoader.exists(BODY_FONT_PATH):
		var base: FontFile = load(BODY_FONT_PATH) as FontFile
		if base != null:
			var variation := FontVariation.new()
			variation.base_font = base
			variation.variation_opentype = {"wght": 600.0}
			_body_font = variation
	return _body_font

static func display_font() -> Font:
	if _display_font == null and ResourceLoader.exists(DISPLAY_FONT_PATH):
		_display_font = load(DISPLAY_FONT_PATH) as Font
	return _display_font

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

static func apply_button(button: BaseButton, display: bool = true) -> void:
	var font: Font = display_font() if display else body_font()
	if font != null:
		button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", SIZE_BUTTON)
	_apply_outline(button, OUTLINE_BODY if display else 0)

static func apply_log_rich(entry: RichTextLabel, size: int = SIZE_LOG, color: Color = COLOR_LOG) -> void:
	var font: Font = body_font()
	if font != null:
		entry.add_theme_font_override("normal_font", font)
	entry.add_theme_font_size_override("normal_font_size", size)
	entry.add_theme_color_override("default_color", color)
