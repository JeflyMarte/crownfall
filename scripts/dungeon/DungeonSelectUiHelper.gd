class_name DungeonSelectUiHelper
extends RefCounted

const DEPART_BTN_MIN_SIZE: Vector2 = Vector2(300, 56)
const CONFIRM_BTN_MIN_SIZE: Vector2 = Vector2(120, 48)
const SELECT_BTN_MIN_SIZE: Vector2 = Vector2(88, 40)


static func apply_depart_button(btn: Button) -> void:
	_apply_labeled_button(btn, DungeonSelectUiTokens.depart_button_styles(), DEPART_BTN_MIN_SIZE)


static func apply_confirm_button(btn: Button, is_yes: bool) -> void:
	var styles: Dictionary = (
		DungeonSelectUiTokens.confirm_yes_button_styles()
		if is_yes
		else DungeonSelectUiTokens.confirm_no_button_styles()
	)
	_apply_labeled_button(btn, styles, CONFIRM_BTN_MIN_SIZE)


static func apply_select_button(btn: Button, unlocked: bool) -> void:
	_apply_labeled_button(btn, DungeonSelectUiTokens.select_button_styles(), SELECT_BTN_MIN_SIZE)
	btn.disabled = not unlocked


static func apply_back_button(btn: Button) -> void:
	var back_tex: Texture2D = DungeonSelectUiTokens.back_icon()
	if back_tex == null:
		return
	btn.text = ""
	btn.icon = back_tex
	btn.expand_icon = true
	btn.custom_minimum_size = Vector2(40, 40)


static func _apply_labeled_button(btn: Button, styles: Dictionary, min_size: Vector2) -> void:
	var normal: StyleBox = styles.get("normal", null)
	var disabled: StyleBox = styles.get("disabled", null)
	if _texture_style_ok(normal):
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", normal)
		btn.add_theme_stylebox_override("pressed", normal)
	if _texture_style_ok(disabled):
		btn.add_theme_stylebox_override("disabled", disabled)
	btn.text = ""
	btn.add_theme_font_size_override("font_size", 1)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0))
	if btn.custom_minimum_size.x < min_size.x or btn.custom_minimum_size.y < min_size.y:
		btn.custom_minimum_size = Vector2(
			maxf(btn.custom_minimum_size.x, min_size.x),
			maxf(btn.custom_minimum_size.y, min_size.y),
		)


static func _texture_style_ok(style: StyleBox) -> bool:
	return style is StyleBoxTexture and (style as StyleBoxTexture).texture != null
