class_name ResultUiTokens
extends RefCounted

## リザルト画面フッターボタン chrome。

const ROOT: String = "res://assets/ui/result/"

const BTN_NEXT: String = ROOT + "UI_Result_Btn_Next.png"
const BTN_NEXT_DISABLED: String = ROOT + "UI_Result_Btn_Next_Disabled.png"
const BTN_RETRY: String = ROOT + "UI_Result_Btn_Retry.png"
const BTN_RETRY_DISABLED: String = ROOT + "UI_Result_Btn_Retry_Disabled.png"
const BTN_HOME: String = ROOT + "UI_Result_Btn_Home.png"
const BTN_HOME_DISABLED: String = ROOT + "UI_Result_Btn_Home_Disabled.png"

const BTN_MARGINS: Vector4i = Vector4i(20, 14, 20, 14)

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

static func next_button_styles() -> Dictionary:
	return {
		"normal": texture_stylebox(BTN_NEXT, BTN_MARGINS, 4.0),
		"disabled": texture_stylebox(BTN_NEXT_DISABLED, BTN_MARGINS, 4.0),
	}

static func retry_button_styles() -> Dictionary:
	return {
		"normal": texture_stylebox(BTN_RETRY, BTN_MARGINS, 4.0),
		"disabled": texture_stylebox(BTN_RETRY_DISABLED, BTN_MARGINS, 4.0),
	}

static func home_button_styles() -> Dictionary:
	return {
		"normal": texture_stylebox(BTN_HOME, BTN_MARGINS, 4.0),
		"disabled": texture_stylebox(BTN_HOME_DISABLED, BTN_MARGINS, 4.0),
	}
