class_name CommanderUiTokens
extends RefCounted

## 隊長台帳 UI chrome。

const ROOT: String = "res://assets/ui/commander_ui/"

const BG: String = ROOT + "UI_BG_Commander.png"
const ORNAMENT_DIAMOND: String = ROOT + "UI_Ornament_Diamond.png"
const ICO_BACK: String = ROOT + "UI_Ico_Back_Gold.png"
const SECTION_RULE: String = ROOT + "UI_CMD_SectionRule.png"

const BTN_RENAME: String = ROOT + "UI_CMD_Btn_Rename.png"
const BTN_RENAME_DISABLED: String = ROOT + "UI_CMD_Btn_Rename_Disabled.png"
const BTN_CLAIM_ALL: String = ROOT + "UI_CMD_Btn_ClaimAll.png"
const BTN_CLAIM: String = ROOT + "UI_CMD_Btn_Claim.png"
const BTN_FORGE: String = ROOT + "UI_CMD_Btn_Forge.png"
const BTN_CODEX: String = ROOT + "UI_CMD_Btn_Codex.png"
const BTN_CLEAR_TITLE: String = ROOT + "UI_CMD_Btn_ClearTitle.png"
const BTN_CLEAR_TITLE_DISABLED: String = ROOT + "UI_CMD_Btn_ClearTitle_Disabled.png"
const BTN_DAILY_CLAIM: String = ROOT + "UI_CMD_Btn_DailyClaim.png"
const BTN_DAILY_DONE: String = ROOT + "UI_CMD_Btn_DailyDone.png"
const BTN_DAILY_MOVE: String = ROOT + "UI_CMD_Btn_DailyMove.png"

const BTN_MARGINS: Vector4i = Vector4i(16, 10, 16, 10)
const BTN_MARGINS_COMPACT: Vector4i = Vector4i(12, 8, 12, 8)

const SCREEN_TITLE: String = "隊長台帳"

static func load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func back_icon() -> Texture2D:
	return load_tex(ICO_BACK)

static func ornament_diamond() -> Texture2D:
	return load_tex(ORNAMENT_DIAMOND)

static func texture_stylebox(
	path: String,
	margins: Vector4i = BTN_MARGINS,
	content_margin: float = 2.0
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

static func _labeled_styles(normal_path: String, disabled_path: String = "") -> Dictionary:
	var styles := {
		"normal": texture_stylebox(normal_path, BTN_MARGINS, 2.0),
	}
	if not disabled_path.is_empty():
		styles["disabled"] = texture_stylebox(disabled_path, BTN_MARGINS, 2.0)
	else:
		styles["disabled"] = styles["normal"]
	return styles

static func rename_button_styles() -> Dictionary:
	return _labeled_styles(BTN_RENAME, BTN_RENAME_DISABLED)

static func claim_all_button_styles() -> Dictionary:
	return _labeled_styles(BTN_CLAIM_ALL)

static func claim_button_styles() -> Dictionary:
	return _labeled_styles(BTN_CLAIM)

static func forge_shortcut_button_styles() -> Dictionary:
	return _labeled_styles(BTN_FORGE)

static func codex_shortcut_button_styles() -> Dictionary:
	return _labeled_styles(BTN_CODEX)

static func clear_title_button_styles() -> Dictionary:
	return _labeled_styles(BTN_CLEAR_TITLE, BTN_CLEAR_TITLE_DISABLED)

static func daily_button_styles(state: String) -> Dictionary:
	var path: String = BTN_DAILY_CLAIM
	match state:
		"done":
			path = BTN_DAILY_DONE
		"move":
			path = BTN_DAILY_MOVE
	var sb: StyleBoxTexture = texture_stylebox(path, BTN_MARGINS_COMPACT, 2.0)
	return {"normal": sb, "disabled": sb}
