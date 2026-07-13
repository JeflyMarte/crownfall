class_name CommanderUiHelper
extends RefCounted

const RENAME_BTN_MIN_SIZE: Vector2 = Vector2(88, 32)
const CLAIM_ALL_BTN_MIN_SIZE: Vector2 = Vector2(140, 36)
const CLAIM_BTN_MIN_SIZE: Vector2 = Vector2(96, 40)
const SHORTCUT_BTN_MIN_SIZE: Vector2 = Vector2(120, 40)
const CLEAR_TITLE_BTN_MIN_SIZE: Vector2 = Vector2(120, 36)
const DAILY_BTN_MIN_SIZE: Vector2 = Vector2(60, 32)

const DAILY_STATE_CLAIM: String = "claim"
const DAILY_STATE_DONE: String = "done"
const DAILY_STATE_MOVE: String = "move"


static func apply_rename_button(btn: Button, enabled: bool) -> void:
	_apply_labeled_button(btn, CommanderUiTokens.rename_button_styles(), RENAME_BTN_MIN_SIZE)
	btn.disabled = not enabled


static func apply_claim_all_button(btn: Button) -> void:
	_apply_labeled_button(btn, CommanderUiTokens.claim_all_button_styles(), CLAIM_ALL_BTN_MIN_SIZE)


static func apply_claim_button(btn: Button) -> void:
	_apply_labeled_button(btn, CommanderUiTokens.claim_button_styles(), CLAIM_BTN_MIN_SIZE)


static func apply_forge_shortcut_button(btn: Button) -> void:
	_apply_labeled_button(btn, CommanderUiTokens.forge_shortcut_button_styles(), SHORTCUT_BTN_MIN_SIZE)


static func apply_codex_shortcut_button(btn: Button) -> void:
	_apply_labeled_button(btn, CommanderUiTokens.codex_shortcut_button_styles(), SHORTCUT_BTN_MIN_SIZE)


static func apply_clear_title_button(btn: Button, enabled: bool) -> void:
	_apply_labeled_button(btn, CommanderUiTokens.clear_title_button_styles(), CLEAR_TITLE_BTN_MIN_SIZE)
	btn.disabled = not enabled


static func apply_daily_button(btn: Button, state: String) -> void:
	var styles: Dictionary = CommanderUiTokens.daily_button_styles(state)
	_apply_labeled_button(btn, styles, DAILY_BTN_MIN_SIZE)
	match state:
		DAILY_STATE_CLAIM:
			btn.disabled = false
		DAILY_STATE_DONE, DAILY_STATE_MOVE:
			btn.disabled = true


static func apply_back_button(btn: Button) -> void:
	var back_tex: Texture2D = CommanderUiTokens.back_icon()
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
