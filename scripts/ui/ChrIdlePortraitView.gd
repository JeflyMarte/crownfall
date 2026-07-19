class_name ChrIdlePortraitView
extends Control

## 装備画面と同系統のジョブ別 Idle ドット表示（`ChrIdlePortrait` アニメ）。
## NOTE: MVP 表彰台など、ツリー投入前に `set_from_entry` が呼ばれる経路がある。
## `_ready` 前でも安全なよう `_ensure_nodes()` で子を遅延生成する。

@export var portrait_size: Vector2 = Vector2(128, 128)

var _art: TextureRect
var _glyph: Label
var _idle_textures: Array[Texture2D] = []
var _idle_frame: int = 0
var _idle_accum: float = 0.0


func _ready() -> void:
	_ensure_nodes()
	custom_minimum_size = portrait_size
	size = portrait_size


func _ensure_nodes() -> void:
	if _art != null:
		return
	_build_nodes()


func _build_nodes() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art = TextureRect.new()
	_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_glyph = Label.new()
	_glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph.add_theme_font_size_override("font_size", int(portrait_size.y * 0.28))
	_glyph.add_theme_color_override("font_color", Color(0.85, 0.74, 0.45, 1))
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glyph)


func set_portrait_size(px: float) -> void:
	portrait_size = Vector2(px, px)
	custom_minimum_size = portrait_size
	size = portrait_size
	_ensure_nodes()
	if _glyph != null:
		_glyph.add_theme_font_size_override("font_size", int(px * 0.28))


func set_from_entry(entry: Dictionary) -> void:
	var member_id: String = str(entry.get("member_id", ""))
	var job_id: String = str(entry.get("job_id", ""))
	var member: Resource = _find_member(member_id)
	if member != null and not str(member.job_id).is_empty():
		job_id = str(member.job_id)
	_apply_portrait(member, job_id)


func set_from_member(member: Resource) -> void:
	if member == null:
		_clear_portrait("?")
		return
	_apply_portrait(member, str(member.job_id))


func _find_member(member_id: String) -> Resource:
	if member_id.is_empty():
		return null
	for member in GameState.party_members:
		if member != null and str(member.id) == member_id:
			return member
	return null


func _apply_portrait(member: Resource, job_id: String) -> void:
	_ensure_nodes()
	_idle_textures.clear()
	_idle_frame = 0
	_idle_accum = 0.0
	var idle_texs: Array[Texture2D] = []
	if member != null:
		idle_texs = ChrIdlePortrait.load_idle_textures_for_member(member)
	if idle_texs.is_empty() and not job_id.is_empty():
		idle_texs = ChrIdlePortrait.load_idle_textures(job_id)
	if not idle_texs.is_empty():
		_idle_textures = idle_texs
		_art.texture = idle_texs[0]
		_glyph.text = ""
		return
	var chr_tex: Texture2D = null
	if member != null:
		chr_tex = RosterUiHelper.get_member_portrait_texture(member)
	if chr_tex == null and not job_id.is_empty():
		chr_tex = IconPaths.get_icon_texture(job_id, "chr")
	if chr_tex != null:
		_art.texture = chr_tex
		_glyph.text = ""
		return
	var glyph: String = "?"
	if member != null and not str(member.display_name).is_empty():
		glyph = str(member.display_name).substr(0, 1)
	_clear_portrait(glyph)


func _clear_portrait(glyph: String) -> void:
	_ensure_nodes()
	_art.texture = null
	_glyph.text = glyph


func _process(delta: float) -> void:
	if _art == null or _idle_textures.size() <= 1:
		return
	_idle_accum += delta
	var frame_dur: float = 1.0 / ChrIdlePortrait.IDLE_FPS
	if _idle_accum < frame_dur:
		return
	_idle_accum = 0.0
	_idle_frame = (_idle_frame + 1) % _idle_textures.size()
	_art.texture = _idle_textures[_idle_frame]
