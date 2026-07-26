class_name HubSimpleGuideOverlay
extends CanvasLayer

## はじめから初回のみ — 拠点上にニーナの簡易ガイド（P3-UI-HUB-GUIDE-001）。

signal dismissed

const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")

const FLAG_KEY: String = "hub_simple_guide_done"
const PANEL_MIN: Vector2 = Vector2(560, 480)
const NINA_PX: float = 168.0

## 各1ページ。操作講習ではなく「何からやるか」。
const PAGES: Array[Dictionary] = [
	{
		"title": "1. 仲間を集めよう",
		"body": "まずは招待状（ガチャ）を引いて、仲間を集めましょう！\n助っ人がいると調査がぐっと楽になりますよ！",
	},
	{
		"title": "2. ダンジョンへ潜ろう",
		"body": "ダンジョンへ潜って、レアな装備品を手に入れてレベルアップ！\nモーンゲートから、一歩ずつ進みましょう！",
	},
	{
		"title": "3. 調査室で研究",
		"body": "調査室でダンジョンを研究しましょう！\n進めるほど報酬ももらえますよ！",
	},
	{
		"title": "4. 鍛冶屋で強化",
		"body": "鍛冶屋で武器をさらに強くしましょう！\n素材が揃ったら、ぜひ立ち寄ってくださいね！",
	},
	{
		"title": "5. 展示室で自慢",
		"body": "展示室でお気に入りのキャラを自慢しましょう！\n拠点の顔として飾れますよ！",
	},
]

var _page_index: int = 0
var _dim: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _body_label: Label
var _page_label: Label
var _next_btn: Button
var _skip_btn: Button
var _nina: TextureRect
var _tween: Tween


func _ready() -> void:
	layer = 88
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func present() -> void:
	_page_index = 0
	_refresh_page()
	visible = true
	_play_intro()
	call_deferred("_play_sfx")


func _play_sfx() -> void:
	AudioManager.play_sfx("ui_confirm")


static func is_done() -> bool:
	return bool(GameState.tutorial_flags.get(FLAG_KEY, false))


static func mark_done() -> void:
	GameState.tutorial_flags[FLAG_KEY] = true
	SaveManager.save_game()


static func should_show() -> bool:
	return not is_done()


func _build() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.02, 0.03, 0.06, 0.72)
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
	_panel.custom_minimum_size = PANEL_MIN
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_dim_gui_input)
	_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 16)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(inner)

	var eyebrow := Label.new()
	eyebrow.text = "記録官ニーナの手引き"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(eyebrow, UiTypography.COLOR_GOLD)
	inner.add_child(eyebrow)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_title_label)

	_body_label = Label.new()
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_label.clip_text = false
	_body_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_body_label)

	_page_label = Label.new()
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(_page_label, UiTypography.COLOR_SUB)
	inner.add_child(_page_label)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	btn_row.mouse_filter = Control.MOUSE_FILTER_STOP
	inner.add_child(btn_row)

	_skip_btn = Button.new()
	_skip_btn.text = "スキップ"
	_skip_btn.custom_minimum_size = Vector2(140, 48)
	_skip_btn.pressed.connect(_on_skip_pressed)
	btn_row.add_child(_skip_btn)

	_next_btn = Button.new()
	_next_btn.text = "次へ"
	_next_btn.custom_minimum_size = Vector2(160, 48)
	_next_btn.pressed.connect(_on_next_pressed)
	btn_row.add_child(_next_btn)

	## 画面右下にニーナのドット絵（パネル外）。
	_nina = TextureRect.new()
	_nina.name = "NinaDot"
	_nina.custom_minimum_size = Vector2(NINA_PX, NINA_PX)
	_nina.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_nina.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_nina.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_nina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nina.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_nina.offset_left = - NINA_PX - 28.0
	_nina.offset_top = - NINA_PX - 36.0
	_nina.offset_right = - 28.0
	_nina.offset_bottom = - 36.0
	var nina_tex: Texture2D = _IntroUiAssets.load_tex(_IntroUiAssets.NINA_DOT)
	if nina_tex == null:
		nina_tex = _IntroUiAssets.load_tex(_IntroUiAssets.NINA_ICON)
	_nina.texture = nina_tex
	add_child(_nina)

	visible = false


func _refresh_page() -> void:
	var page: Dictionary = PAGES[_page_index]
	_title_label.text = str(page.get("title", ""))
	UiTypography.apply_display(
		_title_label, 30, Color(1.0, 0.94, 0.72), UiTypography.OUTLINE_STRONG
	)
	_body_label.text = str(page.get("body", ""))
	UiTypography.apply_body(_body_label, 20, UiTypography.COLOR_BODY)
	_page_label.text = "%d / %d" % [_page_index + 1, PAGES.size()]
	var last: bool = _page_index >= PAGES.size() - 1
	_next_btn.text = "はじめる" if last else "次へ"
	_skip_btn.visible = not last


func _play_intro() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.86, 0.86)
	_panel.pivot_offset = PANEL_MIN * 0.5
	_nina.modulate.a = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.16)
	_tween.parallel().tween_property(_panel, "scale", Vector2(1.04, 1.04), 0.24).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_nina, "modulate:a", 1.0, 0.22)
	_tween.chain().tween_property(_panel, "scale", Vector2.ONE, 0.1)


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_advance_or_close()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_advance_or_close()


func _on_next_pressed() -> void:
	_advance_or_close()


func _on_skip_pressed() -> void:
	_finish()


func _advance_or_close() -> void:
	if _page_index < PAGES.size() - 1:
		_page_index += 1
		_refresh_page()
		AudioManager.play_sfx("ui_confirm", 0.9, 0.0)
		return
	_finish()


func _finish() -> void:
	mark_done()
	AudioManager.play_sfx("ui_confirm")
	dismissed.emit()
	queue_free()


static func show_on(parent: Node) -> CanvasLayer:
	if parent == null:
		return null
	if parent.get_node_or_null("HubSimpleGuideOverlay") != null:
		return null
	var overlay := new()
	overlay.name = "HubSimpleGuideOverlay"
	parent.add_child(overlay)
	overlay.present()
	return overlay
