class_name CommanderUiTokens
extends RefCounted

## 隊長台帳 UI chrome（背景・装飾）。ボタン画像化は撤回済み。

const ROOT: String = "res://assets/ui/commander_ui/"

const BG: String = ROOT + "UI_BG_Commander.png"
const ORNAMENT_DIAMOND: String = ROOT + "UI_Ornament_Diamond.png"
const ICO_BACK: String = ROOT + "UI_Ico_Back_Gold.png"
const SECTION_RULE: String = ROOT + "UI_CMD_SectionRule.png"

const RANK_ICON_D: String = ROOT + "ICO_Rank_D.png"
const RANK_ICON_C: String = ROOT + "ICO_Rank_C.png"
const RANK_ICON_B: String = ROOT + "ICO_Rank_B.png"
const RANK_ICON_A: String = ROOT + "ICO_Rank_A.png"
const RANK_ICON_S: String = ROOT + "ICO_Rank_S.png"

const RANK_ICON_BY_CODE: Dictionary = {
	"D": RANK_ICON_D,
	"C": RANK_ICON_C,
	"B": RANK_ICON_B,
	"A": RANK_ICON_A,
	"S": RANK_ICON_S,
}

const SCREEN_TITLE: String = "マイページ"


static func load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func ornament_diamond() -> Texture2D:
	return load_tex(ORNAMENT_DIAMOND)


static func rank_icon_path(rank_code: String) -> String:
	return str(RANK_ICON_BY_CODE.get(rank_code, ""))


static func rank_icon(rank_code: String) -> Texture2D:
	return load_tex(rank_icon_path(rank_code))
