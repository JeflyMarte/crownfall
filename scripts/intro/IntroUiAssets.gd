extends RefCounted
## Intro 画面共有アセット（P3-INTRO-002）。

const BG_LORE: String = "res://assets/ui/intro/BG_Intro_Lore.png"
const BG_NAME: String = "res://assets/ui/intro/BG_Intro_Name.png"
const BG_STARTER: String = "res://assets/ui/intro/BG_Intro_Starter.png"
const NINA_PORTRAIT: String = "res://assets/npc/ART_NPC_Nina.png"
## 調査室／セリフ用の顔アイコン（Downloads ニーナアイコン）。
const NINA_ICON: String = "res://assets/npc/ICO_NPC_Nina.png"
## 手引き書籍UI用の顔アイコン（Downloads ニーナの手引きアイコン・枠付き）。
const NINA_ICON_GUIDE: String = "res://assets/npc/ICO_NPC_Nina_Guide.png"
## 拠点ナビ用の顔ドット（PixelLab 128px）。
const NINA_ICON_DOT: String = "res://assets/npc/ICO_NPC_Nina_Dot.png"
## 簡易ガイド等のドット立ち（SPR）。
const NINA_DOT: String = "res://assets/npc/SPR_NPC_Nina.png"
## セリフ／手引き用の立ち絵。
const NINA_DIALOGUE: String = "res://assets/npc/ART_NPC_Nina_Stand.png"
## 旧・対話バストアップ（フォールバック用）。
const NINA_DIALOGUE_BUST: String = "res://assets/npc/ICO_NPC_Nina_Dialogue.png"
const STARTER_CARD_FRAME: String = "res://assets/ui/intro/UI_Card_Starter_Frame.png"


static func add_full_bg(parent: Control, path: String, fallback: Color) -> void:
	var color_bg := ColorRect.new()
	color_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_bg.color = fallback
	color_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(color_bg)

	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = load_tex(path)
	if tex != null:
		bg.texture = tex
	parent.add_child(bg)


static func load_tex(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return load(path) as Texture2D
	return null
