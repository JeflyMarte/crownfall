class_name DungeonSelectUiTokens
extends RefCounted

## ダンジョン選択 UI chrome（入場確認など）。

const ROOT: String = "res://assets/ui/dungeon_select/"

const ENTER_CONFIRM_PANEL: String = ROOT + "UI_DG_EnterConfirm.png"
const BTN_CONFIRM_YES: String = ROOT + "UI_DG_Btn_ConfirmYes.png"
const BTN_CONFIRM_YES_DISABLED: String = ROOT + "UI_DG_Btn_ConfirmYes_Disabled.png"
const BTN_CONFIRM_NO: String = ROOT + "UI_DG_Btn_ConfirmNo.png"
const BTN_CONFIRM_NO_DISABLED: String = ROOT + "UI_DG_Btn_ConfirmNo_Disabled.png"

const ENTER_CONFIRM_PANEL_WIDTH: float = 640.0
## パネル内のはい／いいえ枠（正規化座標: x, y, w, h）
const ENTER_CONFIRM_YES_RECT: Rect2 = Rect2(0.125, 0.70, 0.312, 0.20)
const ENTER_CONFIRM_NO_RECT: Rect2 = Rect2(0.563, 0.70, 0.312, 0.20)
const ENTER_CONFIRM_BTN_SIZE: Vector2 = Vector2(220, 62)
const ENTER_CONFIRM_BTN_SEPARATION: int = 28


static func load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func texture_stylebox(path: String, margins: Vector4i = Vector4i(24, 16, 24, 16)) -> StyleBoxTexture:
	var tex: Texture2D = load_tex(path)
	var sb := StyleBoxTexture.new()
	if tex == null:
		return sb
	sb.texture = tex
	sb.texture_margin_left = float(margins.x)
	sb.texture_margin_top = float(margins.y)
	sb.texture_margin_right = float(margins.z)
	sb.texture_margin_bottom = float(margins.w)
	return sb


static func confirm_yes_styles() -> Dictionary:
	return {
		"normal": texture_stylebox(BTN_CONFIRM_YES),
		"disabled": texture_stylebox(BTN_CONFIRM_YES_DISABLED),
	}


static func confirm_no_styles() -> Dictionary:
	return {
		"normal": texture_stylebox(BTN_CONFIRM_NO),
		"disabled": texture_stylebox(BTN_CONFIRM_NO_DISABLED),
	}


static func apply_confirm_button(btn: Button, yes: bool) -> void:
	var styles: Dictionary = confirm_yes_styles() if yes else confirm_no_styles()
	var normal: StyleBox = styles.get("normal", null)
	var disabled: StyleBox = styles.get("disabled", null)
	if normal != null and (normal as StyleBoxTexture).texture != null:
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", normal)
		btn.add_theme_stylebox_override("pressed", normal)
	if disabled != null and (disabled as StyleBoxTexture).texture != null:
		btn.add_theme_stylebox_override("disabled", disabled)
	# ラベルはボタン画像に焼込済み。
	btn.text = ""
	btn.add_theme_font_size_override("font_size", 1)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	btn.custom_minimum_size = ENTER_CONFIRM_BTN_SIZE
	btn.focus_mode = Control.FOCUS_ALL
