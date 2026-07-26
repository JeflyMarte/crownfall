class_name HubSimpleGuideOverlay
extends CanvasLayer

## はじめから初回のみ — 拠点上の簡易ガイド（P3-UI-HUB-GUIDE-001）。
## 案内役＝記録官ニーナ。

signal dismissed

const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")

const FLAG_KEY: String = "hub_simple_guide_done"
const BG_PATH: String = "res://assets/ui/UI_BG_HubSimpleGuide.png"
## 背景アート（約 4:3）に合わせて横長寄り。720幅画面で余白を残しつつ本文を収める。
const PANEL_MIN: Vector2 = Vector2(700, 560)
## 手引きヘッダの顔アイコン（正方形 ICO）。
const FACE_ICON_PX: float = 88.0
## 背景フレームの内側余白（書籍イラスト直置き・9-slice しない）。
const BG_CONTENT_MARGIN: int = 96
## 羊皮紙背景向けのインク色（通常UIの明るい本文色はコントラスト不足）。
const INK_TITLE: Color = Color(0.22, 0.12, 0.05, 1.0)
const INK_BODY: Color = Color(0.18, 0.11, 0.06, 1.0)
const INK_META: Color = Color(0.38, 0.26, 0.14, 1.0)
const INK_GOLD: Color = Color(0.36, 0.20, 0.05, 1.0)
## 最終ページだけヘッダ（アイコン＋手引き）を少し下げる。
const HEADER_TOP_GAP_LAST_PAGE: float = 28.0

## 手引きアイコン（アイコン画像。欠落時は「？」）。
const GUIDE_FACES: Array[Dictionary] = [
	{
		"id": "nina",
		"icon_path": "res://assets/npc/ICO_NPC_Nina.png",
	},
]

## 各1ページ。操作講習ではなく「何からやるか」（文量多め）。
const PAGES: Array[Dictionary] = [
	{
		"title": "1. 仲間を集めよう",
		"body": (
			"隊長、まずは招待状（ガチャ）を引いて、仲間を集めましょう。\n\n"
			+ "一人きりだと調査はすぐ行き詰まります。"
			+ "助っ人がいるだけで、戦闘も探索もぐっと楽になりますよ。\n\n"
			+ "拠点の「招待状」から、気になる探索者を迎えてみてください。"
			+ "最初の一枚が、この隊の顔になります！"
		),
	},
	{
		"title": "2. ダンジョンへ潜ろう",
		"body": (
			"仲間が揃ったら、ダンジョンへ潜りましょう。\n\n"
			+ "レアな装備品を手に入れたり、レベルを上げたりするのは、"
			+ "現場に出てこそです。まずは王都地下モーンゲートから、一歩ずつ。\n\n"
			+ "無理に深く潜らなくて大丈夫。"
			+ "戻って報告してくれれば、記録部でちゃんと残しておきますね。"
		),
	},
	{
		"title": "3. 調査室で研究",
		"body": (
			"拠点に戻ったら、調査室にも立ち寄ってください。\n\n"
			+ "記録官のわたしが調査の手伝いをします。"
			+ "ダンジョンの研究を進めると、図鑑が厚くなり、"
			+ "調査の進捗に応じた報酬も受け取れます。\n\n"
			+ "現場の体験と机の記録——両方あって、はじめて「調査」です。"
			+ "抜けのある報告書は、文句を言いますからね。"
		),
	},
	{
		"title": "4. 鍛冶屋で強化",
		"body": (
			"手に入れた武器や防具は、鍛冶屋でさらに強くできます。\n\n"
			+ "素材が揃ったら、ぜひ赤鉄の工房へ。"
			+ "生産・炉研ぎ・錬成で、隊の装備を伸ばしていきましょう。\n\n"
			+ "強い装備は、次のダンジョンへの自信にもなります。"
			+ "無理のない範囲で、少しずつ整えていってくださいね。"
		),
	},
	{
		"title": "5. 展示室で自慢",
		"body": (
			"お気に入りのキャラは、展示室で拠点の顔として飾れます。\n\n"
			+ "調査の合間に、隊の自慢を並べてみてください。"
			+ "記録に残るのは成果だけじゃありません。"
			+ "隊長の好みも、ちゃんと残しておきますからね。"
		),
	},
	{
		"title": "6. 頼れる相棒",
		"body": (
			"最後に——ギルドからの新人調査隊サポートです。\n\n"
			+ "頼りになるペット「ジャック」が支給されます。"
			+ "現場では人間の隊員と一緒に戦ってくれる、心強い相棒です。\n\n"
			+ "手引きは以上！困ったらまた声をかけてください。"
			+ "詳細は図鑑と現地で——いきましょう！"
		),
	},
]

var _page_index: int = 0
var _dim: ColorRect
var _panel: PanelContainer
var _header_top_spacer: Control
var _title_label: Label
var _body_label: Label
var _page_label: Label
var _next_btn: Button
var _skip_btn: Button
var _tween: Tween
## デバッグ再演時は閉じてもフラグを立てない。
var _preview_only: bool = false


func _ready() -> void:
	layer = 88
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func present(preview_only: bool = false) -> void:
	_preview_only = preview_only
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
	## 書籍イラストは 9-slice しない（縁の黒マットが四角く伸びる）。
	_panel.add_theme_stylebox_override("panel", _panel_empty_style())
	center.add_child(_panel)

	var bg := TextureRect.new()
	bg.name = "BookBg"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.texture = _IntroUiAssets.load_tex(BG_PATH)
	_panel.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", BG_CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_right", BG_CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_top", BG_CONTENT_MARGIN - 4)
	margin.add_theme_constant_override("margin_bottom", BG_CONTENT_MARGIN - 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 14)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(inner)

	_header_top_spacer = Control.new()
	_header_top_spacer.name = "HeaderTopSpacer"
	_header_top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_top_spacer.custom_minimum_size = Vector2(0, 0)
	inner.add_child(_header_top_spacer)

	## ヘッダ: ニーナのアイコン＋肩書き。
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(header)

	var faces := HBoxContainer.new()
	faces.add_theme_constant_override("separation", 10)
	faces.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	faces.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	faces.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(faces)
	for face: Dictionary in GUIDE_FACES:
		faces.add_child(_make_guide_face_icon(face))

	var header_col := VBoxContainer.new()
	header_col.add_theme_constant_override("separation", 4)
	header_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_col.alignment = BoxContainer.ALIGNMENT_CENTER
	header_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(header_col)

	var eyebrow := Label.new()
	eyebrow.text = "記録官ニーナの手引き"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_OFF
	eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_display(eyebrow, UiTypography.SIZE_CAPTION, INK_GOLD, 0)
	header_col.add_child(eyebrow)

	var name_line := Label.new()
	name_line.text = "記録官 ニーナ"
	name_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_display(name_line, UiTypography.SIZE_BODY_SMALL, INK_GOLD, 0)
	header_col.add_child(name_line)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_title_label)

	_body_label = Label.new()
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_label.clip_text = false
	_body_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_body_label)

	_page_label = Label.new()
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_display(_page_label, UiTypography.SIZE_CAPTION, INK_META, 0)
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

	visible = false


func _make_guide_face_icon(face: Dictionary) -> Control:
	var host := Control.new()
	host.custom_minimum_size = Vector2(FACE_ICON_PX, FACE_ICON_PX)
	host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.clip_contents = true
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tex: Texture2D = _load_icon_or_null(str(face.get("icon_path", "")))
	if tex != null:
		var icon := TextureRect.new()
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = tex
		host.add_child(icon)
	else:
		host.add_child(_make_missing_icon_badge())
	return host


func _make_missing_icon_badge() -> Control:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.78, 0.70, 0.55, 0.92)
	sb.border_color = Color(0.42, 0.30, 0.16, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	var q := Label.new()
	q.text = "？"
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	q.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_display(q, int(FACE_ICON_PX * 0.55), INK_TITLE, 0)
	panel.add_child(q)
	return panel


func _load_icon_or_null(path: String) -> Texture2D:
	if path.is_empty():
		return null
	return _IntroUiAssets.load_tex(path)


func _panel_empty_style() -> StyleBoxEmpty:
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = 0
	sb.content_margin_top = 0
	sb.content_margin_right = 0
	sb.content_margin_bottom = 0
	return sb


func _panel_bg_style() -> StyleBox:
	## 互換用。書籍BGは TextureRect 直置き（9-slice禁止）。
	return _panel_empty_style()


func _refresh_page() -> void:
	var page: Dictionary = PAGES[_page_index]
	_title_label.text = str(page.get("title", ""))
	UiTypography.apply_display(
		_title_label, 28, INK_TITLE, 0
	)
	_body_label.text = str(page.get("body", ""))
	## タイトルと同じ Shippori（筆記・見出し系）で統一。
	UiTypography.apply_display(_body_label, 18, INK_BODY, 0)
	_page_label.text = "%d / %d" % [_page_index + 1, PAGES.size()]
	var last: bool = _page_index >= PAGES.size() - 1
	_next_btn.text = "はじめる" if last else "次へ"
	_skip_btn.visible = not last
	if _header_top_spacer != null:
		_header_top_spacer.custom_minimum_size = Vector2(
			0.0, HEADER_TOP_GAP_LAST_PAGE if last else 0.0
		)


func _play_intro() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.86, 0.86)
	_panel.pivot_offset = PANEL_MIN * 0.5
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.16)
	_tween.parallel().tween_property(_panel, "scale", Vector2(1.04, 1.04), 0.24).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
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
	if not _preview_only:
		mark_done()
	AudioManager.play_sfx("ui_confirm")
	## 先に外してから通知（親が即ジャック支給できるようにする）。
	var p: Node = get_parent()
	if p != null:
		p.remove_child(self)
	dismissed.emit()
	queue_free()


static func show_on(parent: Node, preview_only: bool = false) -> CanvasLayer:
	if parent == null:
		return null
	var existing: Node = parent.get_node_or_null("HubSimpleGuideOverlay")
	if existing != null:
		existing.queue_free()
	var overlay := new()
	overlay.name = "HubSimpleGuideOverlay"
	parent.add_child(overlay)
	overlay.present(preview_only)
	return overlay
