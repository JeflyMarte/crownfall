class_name CrystalExcavateBgHelper
extends RefCounted

## 魔晶石発掘画面の背景 TextureRect を最背面に載せる（EventScene と同型）。

const BG_SELECT: String = "res://assets/ui/excavate/UI_CrystalExcavate_Select_Frame.png"
const BG_SELECT_FALLBACK: String = "res://assets/ui/UI_BG_CrystalExcavate.png"
const BG_COMBAT: String = "res://assets/ui/UI_BG_CrystalExcavate_Combat.png"
const BG_RESULT: String = "res://assets/ui/UI_BG_CrystalExcavate_Result.png"
const ROCK_TEX: String = "res://assets/ui/UI_CrystalExcavate_Rock.png"

const GLOW_DIM := Color(0.62, 0.38, 1.05, 0.42)
const GLOW_BRIGHT := Color(0.95, 0.62, 1.35, 0.92)
const GLOW_PULSE_SEC: float = 0.85
const ROCK_GLOW_DIM := Color(1.0, 1.0, 1.0, 1.0)
const ROCK_GLOW_BRIGHT := Color(1.35, 1.1, 1.7, 1.0)


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


static func make_crystal_glow_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.22, 0.55, 1.0])
	grad.colors = PackedColorArray([
		Color(0.95, 0.75, 1.0, 1.0),
		Color(0.72, 0.35, 1.0, 0.65),
		Color(0.45, 0.15, 0.85, 0.18),
		Color(0.2, 0.05, 0.4, 0.0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


static func create_crystal_glow(node_name: String = "CrystalGlow") -> TextureRect:
	var glow := TextureRect.new()
	glow.name = node_name
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.texture = make_crystal_glow_texture()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.modulate = GLOW_DIM
	return glow


static func start_glow_pulse(
	owner: Node,
	target: CanvasItem,
	dim: Color = GLOW_DIM,
	bright: Color = GLOW_BRIGHT,
	sec: float = GLOW_PULSE_SEC
) -> Tween:
	if owner == null or target == null or not is_instance_valid(target):
		return null
	target.modulate = dim
	var tw: Tween = owner.create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(target, "modulate", bright, sec)
	tw.tween_property(target, "modulate", dim, sec)
	return tw
