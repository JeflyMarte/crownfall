class_name DungeonUnlockOverlay
extends CanvasLayer

## 「○○が解放された！」／完全調査報酬などのポップアップ（バナー主役）。
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
const REWARD_ICON_PX: float = 48.0
const GOLD_ICON_PATH: String = "res://assets/ui/batch2/ICO_Gold.png"

var _display_name: String = ""
var _banner_id: String = ""
var _kind: String = "dungeon"
var _detail: String = ""
var _rewards: Array = []
var _dim: ColorRect
var _panel: PanelContainer
var _eyebrow: Label
var _banner_host: Control
var _banner_rect: TextureRect
var _name_label: Label
var _suffix_label: Label
var _reward_row: HBoxContainer
var _detail_label: Label
var _hint_label: Label
var _tween: Tween


func _ready() -> void:
	layer = 85
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


## banner_id: BiomeBannerHelper に渡すダンジョン／Biome id（空ならバナー無し）。
## detail: テキスト内訳（rewards が空のときのフォールバック）。
## rewards: [{kind,id?,qty,label}] — アイコン＋個数表示。
func present(
	display_name: String,
	banner_id: String = "",
	kind: String = "dungeon",
	detail: String = "",
	rewards: Array = []
) -> void:
	_display_name = display_name.strip_edges()
	_banner_id = banner_id.strip_edges()
	_kind = kind.strip_edges()
	_detail = detail.strip_edges()
	_rewards = rewards.duplicate(true)
	if _kind.is_empty():
		_kind = "dungeon"
	_eyebrow.text = _eyebrow_for_kind(_kind)
	_name_label.text = _display_name
	_suffix_label.text = _suffix_for_kind(_kind)
	_rebuild_rewards()
	_apply_banner()
	UiTypography.apply_caption(_eyebrow, UiTypography.COLOR_GOLD)
	UiTypography.apply_display(
		_name_label, NAME_FONT_MAX, Color(1.0, 0.92, 0.38), UiTypography.OUTLINE_STRONG
	)
	UiTypography.apply_display(
		_suffix_label, 24, Color(1.0, 0.94, 0.72), UiTypography.OUTLINE_STRONG
	)
	UiTypography.apply_body(_detail_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
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
		"survey_complete":
			return "完全調査報酬"
		"dungeon_tier":
			return "危険度解放"
		_:
			return "ダンジョン解放"


func _suffix_for_kind(kind: String) -> String:
	match kind:
		"survey_complete":
			return "の完全調査を達成！"
		_:
			return "が解放された！"


func _rebuild_rewards() -> void:
	for child in _reward_row.get_children():
		child.queue_free()
	if not _rewards.is_empty():
		_reward_row.visible = true
		_detail_label.visible = false
		_detail_label.text = ""
		for entry_v in _rewards:
			if not (entry_v is Dictionary):
				continue
			_reward_row.add_child(_make_reward_chip(entry_v as Dictionary))
		return
	_reward_row.visible = false
	if _detail.is_empty():
		_detail_label.visible = false
		_detail_label.text = ""
	else:
		_detail_label.visible = true
		_detail_label.text = _detail


func _make_reward_chip(entry: Dictionary) -> Control:
	var cell := VBoxContainer.new()
	cell.alignment = BoxContainer.ALIGNMENT_CENTER
	cell.add_theme_constant_override("separation", 4)
	cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_host := Control.new()
	icon_host.custom_minimum_size = Vector2(REWARD_ICON_PX, REWARD_ICON_PX)
	icon_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(icon_host)

	var kind: String = str(entry.get("kind", ""))
	var tex: Texture2D = _reward_texture(entry)
	if kind == "pet" and tex != null:
		var portrait := ChrIdlePortraitView.new()
		portrait.set_portrait_size(REWARD_ICON_PX)
		portrait.set_static_texture(tex)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_host.add_child(portrait)
	else:
		var icon := TextureRect.new()
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = tex
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_host.add_child(icon)

	var qty: int = int(entry.get("qty", 0))
	var qty_label := Label.new()
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	qty_label.clip_text = false
	qty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "pet":
		qty_label.text = str(entry.get("label", ""))
	else:
		qty_label.text = "×%d" % maxi(qty, 1)
	UiTypography.apply_caption(qty_label, UiTypography.COLOR_GOLD)
	cell.add_child(qty_label)
	return cell


func _reward_texture(entry: Dictionary) -> Texture2D:
	var kind: String = str(entry.get("kind", ""))
	match kind:
		"gold":
			if ResourceLoader.exists(GOLD_ICON_PATH):
				return load(GOLD_ICON_PATH) as Texture2D
			return IconPaths.get_icon_texture("gold", "ui")
		"token":
			return CurrencyHelper.get_icon_texture()
		"material":
			return IconPaths.get_icon_texture(str(entry.get("id", "")), "material")
		"ticket":
			return IconPaths.get_icon_texture(str(entry.get("id", "")), "ticket")
		"pet":
			var pet_id: String = str(entry.get("id", ""))
			var idle_tex: Texture2D = ChrIdlePortrait.get_idle_texture(pet_id)
			if idle_tex != null:
				return idle_tex
			return IconPaths.get_icon_texture(pet_id, "chr")
		_:
			return null


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

	_reward_row = HBoxContainer.new()
	_reward_row.name = "RewardRow"
	_reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_reward_row.add_theme_constant_override("separation", 14)
	_reward_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reward_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reward_row.visible = false
	inner.add_child(_reward_row)

	_detail_label = Label.new()
	_detail_label.name = "Detail"
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_detail_label.clip_text = false
	_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_label.visible = false
	inner.add_child(_detail_label)

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
	kind: String = "dungeon",
	detail: String = "",
	rewards: Array = []
) -> CanvasLayer:
	var overlay := new()
	overlay.name = "DungeonUnlockOverlay"
	parent.add_child(overlay)
	overlay.present(display_name, banner_id, kind, detail, rewards)
	return overlay
