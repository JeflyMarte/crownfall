class_name ResultUiHelper
extends RefCounted

const FOOTER_BTN_MIN_HEIGHT: float = 48.0
const NEXT_BTN_FONT_SIZE: int = 24


static func apply_next_button(btn: Button) -> void:
	_apply_image_button_styles(btn, ResultUiTokens.next_button_styles(), true)


static func apply_retry_button(btn: Button) -> void:
	_apply_image_button_styles(btn, ResultUiTokens.retry_button_styles(), false)


static func apply_home_button(btn: Button) -> void:
	_apply_image_button_styles(btn, ResultUiTokens.home_button_styles(), false)


static func _apply_image_button_styles(btn: Button, styles: Dictionary, with_overlay_text: bool) -> void:
	var normal: StyleBox = styles.get("normal", null)
	var disabled: StyleBox = styles.get("disabled", null)
	if _texture_style_ok(normal):
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", normal)
		btn.add_theme_stylebox_override("pressed", normal)
	if _texture_style_ok(disabled):
		btn.add_theme_stylebox_override("disabled", disabled)
	if with_overlay_text:
		btn.add_theme_color_override("font_color", Color(0.98, 0.92, 0.62, 1.0))
		btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.48, 1.0))
		btn.add_theme_font_size_override("font_size", NEXT_BTN_FONT_SIZE)
	else:
		btn.text = ""
		btn.add_theme_font_size_override("font_size", 1)
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 0))
		btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0))
	if btn.custom_minimum_size.y < FOOTER_BTN_MIN_HEIGHT:
		btn.custom_minimum_size = Vector2(btn.custom_minimum_size.x, FOOTER_BTN_MIN_HEIGHT)


static func _texture_style_ok(style: StyleBox) -> bool:
	return style is StyleBoxTexture and (style as StyleBoxTexture).texture != null
