class_name StarterJoinUiTokens
extends RefCounted

## 章クリア後の加入ショーケース UI（モック準拠）。

const ROOT: String = "res://assets/ui/join/"
const TITLE_BANNER: String = ROOT + "UI_Join_TitleBanner.png"
const NAMEPLATE: String = ROOT + "UI_Join_Nameplate.png"
const QUOTE_PANEL: String = ROOT + "UI_Join_QuotePanel.png"
const PORTRAIT_GLOW: String = ROOT + "UI_Join_PortraitGlow.png"

const TITLE_WIDTH: float = 640.0
const PORTRAIT_PX: float = 280.0
const NAMEPLATE_WIDTH: float = 600.0
const NAMEPLATE_HEIGHT: float = 72.0
## セリフ枠は縦を抑えめ（短いセリフ＋タップ誘導向け）。
const QUOTE_WIDTH: float = 560.0
const QUOTE_HEIGHT: float = 168.0
const JOB_ICON_PX: float = 40.0


static func load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func title_banner() -> Texture2D:
	return load_tex(TITLE_BANNER)


static func nameplate() -> Texture2D:
	return load_tex(NAMEPLATE)


static func quote_panel() -> Texture2D:
	return load_tex(QUOTE_PANEL)


static func portrait_glow() -> Texture2D:
	return load_tex(PORTRAIT_GLOW)
