extends RefCounted
## Intro 画面共有アセット（P3-INTRO-002）。

const BG_LORE: String = "res://assets/ui/intro/BG_Intro_Lore.png"
const BG_NAME: String = "res://assets/ui/intro/BG_Intro_Name.png"
const BG_STARTER: String = "res://assets/ui/intro/BG_Intro_Starter.png"
const NINA_PORTRAIT: String = "res://assets/npc/ART_NPC_Nina.png"
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
