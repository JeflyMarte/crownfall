class_name DungeonUnlockOverlay
extends CanvasLayer

## 「○○が解放された！」ポップアップ（バナー主役）。
## ダンジョン名はバナー内ネームプレート位置に重ねる（選択画面と同ポリシー）。

const _BiomeBannerHelper := preload("res://scripts/ui/BiomeBannerHelper.gd")

signal dismissed(display_name: String)

const PANEL_WIDTH: float = 640.0
const BANNER_WIDTH: float = 584.0
const BANNER_HEIGHT_MIN: float = 96.0
const BANNER_HEIGHT_MAX: float = 160.0
const NAME_FONT_MAX: int = 28
const NAME_FONT_MIN: int = 16
## ネームプレート内の想定最大幅（枠左右余白）。
const NAME_MAX_WIDTH_PAD: float = 72.0

var _display_name: String = ""
var _banner_id: String = ""
var _kind: String = "dungeon"
var _dim: ColorRect
var _panel: PanelContainer
var _eyebrow: Label
var _banner_host: Control
var _banner_rect: TextureRect
var _name_label: Label
var _suffix_label: Label
var _hint_label: Label
var _tween: Tween


func _ready() -> void:
	layer = 85
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


## banner_id: BiomeBannerHelper に渡すダンジョン／Biome id（空ならバナー無し）。
func present(display_name: String, banner_id: String = "", kind: String = "dungeon") -> void:
	_display_name = display_name.strip_edges()
	_banner_id = banner_id.strip_edges()
	_kind = kind.strip_edges()
	if _kind.is_empty():
		_kind = "dungeon"
	_eyebrow.text = _eyebrow_for_kind(_kind)
	_name_label.text = _display_name
	_suffix_label.text = "が解放された！"
	_apply_banner()
	UiTypography.apply_caption(_eyebrow, UiTypography.COLOR_GOLD)
	UiTypography.apply_display(
		_name_label, NAME_FONT_MAX, Color(1.0, 0.92, 0.38), UiTypography.OUTLINE_STRONG
	)
	UiTypography.apply_display(
		_suffix_label, 24, Color(1.0, 0.94, 0.72), UiTypography.OUTLINE_STRONG
	)
	UiTypography.apply_caption(_hint_label, UiTypography.COLOR_SUB)
	_fit_name_font()
	call_deferred("_fit_name_font")
	visible = true
	_play_intro()
	call_deferred("_play_sfx")


func _eyebrow_for_kind(kind: String) -> String:
	match kind:
		"stage":
			return "章解放"
		"pet":
			return "仲間解放"
		"dungeon_tier":
			return "危険度解放"
		_:
			return "ダンジョン解放"


func _apply_banner() -> void:
	var tex: Texture2D = _BiomeBannerHelper.load_texture(_banner_id)
	if tex == null:
		_banner_rect.texture = null
		## バナー無しでもネームプレート相当の中央表示を残す。
		_banner_host.custom_minimum_size = Vector2(BANNER_WIDTH, 56.0)
		_banner_host.visible = true
		_name_label.visible = true
		return
	_banner_rect.texture = tex
	var tw: int = tex.get_width()
	var th: int = tex.get_height()
	var height: float = BANNER_WIDTH * 0.5
	if tw > 0 and th > 0:
		height = BANNER_WIDTH * float(th) / float(tw)
	height = clampf(height, BANNER_HEIGHT_MIN, BANNER_HEIGHT_MAX)
	_banner_host.custom_minimum_size = Vector2(BANNER_WIDTH, height)
	_banner_host.visible = true
	_name_label.visible = true


func _fit_name_font() -> void:
	if _name_label == null or not is_instance_valid(_name_label):
		return
	var max_w: float = BANNER_WIDTH - NAME_MAX_WIDTH_PAD
	if not _banner_host.visible:
		max_w = PANEL_WIDTH - 64.0
	var font: Font = UiTypography.display_font()
	if font == null:
		font = _name_label.get_theme_font("font")
	if font == null:
		return
	var size_px: int = NAME_FONT_MAX
	while size_px > NAME_FONT_MIN:
		var text_w: float = font.get_string_size(
			_name_label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			size_px
		).x
		if text_w <= max_w:
			break
		size_px -= 1
	UiTypography.apply_display(
		_name_label, size_px, Color(1.0, 0.92, 0.38), UiTypography.OUTLINE_STRONG
	)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.clip_text = false
	_name_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_name_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_outline_size", 5)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)


func _play_sfx() -> void:
	AudioManager.play_sfx("ui_confirm")


func _build() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.02, 0.03, 0.06, 0.78)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 12)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(inner)

	_eyebrow = Label.new()
	_eyebrow.text = "ダンジョン解放"
	_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_eyebrow)

	_banner_host = Control.new()
	_banner_host.name = "BannerHost"
	_banner_host.custom_minimum_size = Vector2(BANNER_WIDTH, 112.0)
	_banner_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_banner_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_host.clip_contents = true
	inner.add_child(_banner_host)

	_banner_rect = TextureRect.new()
	_banner_rect.name = "Banner"
	_banner_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_banner_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_banner_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_host.add_child(_banner_rect)

	## 一覧バナーと同ポリシー: 自然サイズ＋中央寄せ（FULL_RECT 埋め込み禁止）。
	_name_label = Label.new()
	_name_label.name = "BannerTitle"
	_name_label.set_anchors_preset(Control.PRESET_CENTER)
	_name_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_name_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_name_label.offset_top = -2.0
	_name_label.offset_bottom = -6.0
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.max_lines_visible = 1
	_name_label.clip_text = false
	_name_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_host.add_child(_name_label)

	_suffix_label = Label.new()
	_suffix_label.text = "が解放された！"
	_suffix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_suffix_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_suffix_label.clip_text = false
	_suffix_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_suffix_label)

	_hint_label = Label.new()
	_hint_label.text = "タップして閉じる"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_hint_label)

	visible = false


func _play_intro() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.82, 0.82)
	call_deferred("_sync_panel_pivot")
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.16)
	_tween.parallel().tween_property(_panel, "scale", Vector2(1.04, 1.04), 0.28).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_property(_panel, "scale", Vector2.ONE, 0.1)


func _sync_panel_pivot() -> void:
	if _panel == null or not is_instance_valid(_panel):
		return
	_panel.pivot_offset = _panel.size * 0.5


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_close()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_close()


func _close() -> void:
	AudioManager.play_sfx("ui_confirm")
	var name_str: String = _display_name
	dismissed.emit(name_str)
	queue_free()


static func show_on(
	parent: Node,
	display_name: String,
	banner_id: String = "",
	kind: String = "dungeon"
) -> CanvasLayer:
	var overlay := new()
	overlay.name = "DungeonUnlockOverlay"
	parent.add_child(overlay)
	overlay.present(display_name, banner_id, kind)
	return overlay
