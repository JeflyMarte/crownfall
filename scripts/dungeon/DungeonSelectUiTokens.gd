class_name DungeonSelectUiTokens
extends RefCounted

## ダンジョン選択 UI chrome（入場ボタン等）。

const ROOT: String = "res://assets/ui/dungeon_select/"

const BTN_DEPART: String = ROOT + "UI_DG_Btn_Depart.png"
const BTN_DEPART_DISABLED: String = ROOT + "UI_DG_Btn_Depart_Disabled.png"
const BTN_CONFIRM_YES: String = ROOT + "UI_DG_Btn_ConfirmYes.png"
const BTN_CONFIRM_YES_DISABLED: String = ROOT + "UI_DG_Btn_ConfirmYes_Disabled.png"
const BTN_CONFIRM_NO: String = ROOT + "UI_DG_Btn_ConfirmNo.png"
const BTN_CONFIRM_NO_DISABLED: String = ROOT + "UI_DG_Btn_ConfirmNo_Disabled.png"
const BTN_SELECT: String = ROOT + "UI_DG_Btn_Select.png"
const BTN_SELECT_DISABLED: String = ROOT + "UI_DG_Btn_Select_Disabled.png"
const ICO_BACK: String = ROOT + "UI_Ico_Back_Gold.png"

const BTN_MARGINS: Vector4i = Vector4i(20, 16, 20, 16)
const CONFIRM_BTN_MARGINS: Vector4i = Vector4i(16, 12, 16, 12)
const SELECT_BTN_MARGINS: Vector4i = Vector4i(12, 8, 12, 8)

static func load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func texture_stylebox(
	path: String,
	margins: Vector4i = BTN_MARGINS,
	content_margin: float = 4.0
) -> StyleBoxTexture:
	var tex: Texture2D = load_tex(path)
	var sb := StyleBoxTexture.new()
	if tex == null:
		return sb
	sb.texture = tex
	sb.texture_margin_left = margins.x
	sb.texture_margin_top = margins.y
	sb.texture_margin_right = margins.z
	sb.texture_margin_bottom = margins.w
	sb.set_content_margin_all(content_margin)
	return sb

static func depart_button_styles() -> Dictionary:
	return {
		"normal": texture_stylebox(BTN_DEPART, BTN_MARGINS, 4.0),
		"disabled": texture_stylebox(BTN_DEPART_DISABLED, BTN_MARGINS, 4.0),
	}

static func confirm_yes_button_styles() -> Dictionary:
	return {
		"normal": texture_stylebox(BTN_CONFIRM_YES, CONFIRM_BTN_MARGINS, 4.0),
		"disabled": texture_stylebox(BTN_CONFIRM_YES_DISABLED, CONFIRM_BTN_MARGINS, 4.0),
	}

static func confirm_no_button_styles() -> Dictionary:
	return {
		"normal": texture_stylebox(BTN_CONFIRM_NO, CONFIRM_BTN_MARGINS, 4.0),
		"disabled": texture_stylebox(BTN_CONFIRM_NO_DISABLED, CONFIRM_BTN_MARGINS, 4.0),
	}

static func select_button_styles() -> Dictionary:
	return {
		"normal": texture_stylebox(BTN_SELECT, SELECT_BTN_MARGINS, 2.0),
		"disabled": texture_stylebox(BTN_SELECT_DISABLED, SELECT_BTN_MARGINS, 2.0),
	}

static func back_icon() -> Texture2D:
	return load_tex(ICO_BACK)
