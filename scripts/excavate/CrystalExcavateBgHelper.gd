class_name CrystalExcavateBgHelper
extends RefCounted

## 魔晶石発掘画面の背景 TextureRect を最背面に載せる（EventScene と同型）。

const BG_SELECT: String = "res://assets/ui/excavate/UI_CrystalExcavate_Select_Frame.png"
const BG_SELECT_FALLBACK: String = "res://assets/ui/UI_BG_CrystalExcavate.png"
const BG_COMBAT: String = "res://assets/ui/UI_BG_CrystalExcavate_Combat.png"
const BG_RESULT: String = "res://assets/ui/UI_BG_CrystalExcavate_Result.png"
const ROCK_TEX: String = "res://assets/ui/UI_CrystalExcavate_Rock.png"


static func ensure_background(root: Control, bg_path: String) -> void:
	if root == null:
		return
	if root.has_node("BgTexture"):
		return
	var resolved: String = bg_path
	if bg_path == BG_SELECT and not ResourceLoader.exists(bg_path):
		resolved = BG_SELECT_FALLBACK
	var bg := TextureRect.new()
	bg.name = "BgTexture"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 0.0
	bg.offset_top = 0.0
	bg.offset_right = 0.0
	bg.offset_bottom = 0.0
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -10
	if ResourceLoader.exists(resolved):
		bg.texture = load(resolved) as Texture2D
	root.add_child(bg)
	root.move_child(bg, 0)


static func load_rock_texture() -> Texture2D:
	if ResourceLoader.exists(ROCK_TEX):
		return load(ROCK_TEX) as Texture2D
	return null
