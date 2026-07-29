extends Control

## ギルド情報誌（P3-EVT-FIELD-001）。いまの野外＋発行日。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const BG_PATH: String = "res://assets/ui/UI_BG_GuildBulletin.png"
## 羊皮紙左上マスコット（テキスト中央レイアウトは維持。重ね表示）。
const NONOKA_PATH: String = "res://assets/ui/UI_GuildBulletin_Nonoka.png"
## 本文と被らないよう小さめ＋左寄せ（旧 210×250 / offset.x=12）。
const NONOKA_W: float = 138.0
const NONOKA_H: float = 164.0
## FieldHost 左上からのオフセット（左へ・やや上）。
const NONOKA_OFFSET: Vector2 = Vector2(-22.0, -52.0)
const NONOKA_LAYER: int = 12
## 少し明るく・薄く（羊皮紙に馴染ませる）。
const NONOKA_MODULATE: Color = Color(1.12, 1.1, 1.08, 0.78)

## 羊皮紙上のインク色（明るい UI 金ではなく濃色）。
const INK: Color = Color(0.22, 0.14, 0.08, 1.0)
const INK_GOLD: Color = Color(0.42, 0.28, 0.10, 1.0)
const INK_TIMER: Color = Color(0.55, 0.34, 0.08, 1.0)
const INK_MUTED: Color = Color(0.35, 0.28, 0.20, 1.0)
## 固有名詞・強調語（羊皮紙上の赤茶インク）。
const INK_EMPHASIS: Color = Color(0.58, 0.24, 0.08, 1.0)
## 背景アートを見せるため、いまの野外枠は塗りなし。
const FIELD_SIZE_SECTION: int = 22
const FIELD_SIZE_HEADLINE: int = 32
const FIELD_SIZE_BODY: int = 24
const FIELD_SIZE_TIMER: int = 30
const FIELD_SIZE_CAPTION: int = 20
const FIELD_SIZE_ARTICLE: int = 20
const FIELD_SIZE_EFFECT: int = 19
const FIELD_SIZE_FIELD_NOTES: int = 17
## 開催期間〜記事のあいだ。本文ブロックを羊皮紙中央へ寄せる。
const FIELD_MID_GAP_PX: float = 12.0
const FIELD_TOP_PAD_PX: float = 255.0


## 720×1280・COVERED 時の調査部ノノカのメモ本文枠（背景アート基準）。
const MEMO_LEFT: float = 108.0
const MEMO_TOP: float = 940.0
const MEMO_WIDTH: float = 560.0
const MEMO_HEIGHT: float = 230.0

## 長い語から置換（部分一致の取り違え防止）。
const EMPHASIS_TERMS: Array[String] = [
	"コズミックダック",
	"宝冠レイヴン",
	"日次裂け目",
	"日次の巣",
	"注目区域",
	"通常探索",
	"遺物反応",
	"補給局",
	"図鑑係",
	"放浪ダック",
	"放浪レイヴン",
	"見張り台",
	"測量係",
	"経験値",
	"ゴールド",
	"エリート",
	"裂け目",
	"鍛冶",
	"図鑑",
	"ギルド",
	"雷属性",
	"炎属性",
	"闇属性",
	"聖属性",
	"天候",
]

@onready var _header: PanelContainer = $Header
@onready var _main_scroll: ScrollContainer = $MainScroll
@onready var _label_issue_date: Label = $MainScroll/MainVBox/SidePad/InnerVBox/IssueDateRow/LabelIssueDate
@onready var _label_section: Label = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelSection
@onready var _label_headline: Label = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelHeadline
@onready var _label_timer: Label = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelTimer
@onready var _label_schedule: Label = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelSchedule
@onready var _label_field_notes: RichTextLabel = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelFieldNotes
@onready var _label_article: RichTextLabel = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelArticle
@onready var _label_effect: RichTextLabel = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelEffect
@onready var _label_featured: Label = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelFeatured
@onready var _label_desc: RichTextLabel = $LabelGuildReport

var _countdown_timer: Timer
var _field_panel: PanelContainer
var _field_vbox: VBoxContainer
var _field_host: Control
var _nonoka_layer: CanvasLayer
var _nonoka_rect: TextureRect
var _nonoka_texture: Texture2D
var _label_weather_guide: RichTextLabel = null

func _ready() -> void:
	_field_panel = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel as PanelContainer
	_field_vbox = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox as VBoxContainer
	_ensure_background()
	_apply_field_panel_style()
	_ensure_field_spacing()
	_ensure_weather_guide()
	_ensure_nonoka_mascot()
	_layout_guild_report()
	_apply_typography()
	_layout_chrome()
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.HOME)
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	EventSystem.event_updated.connect(_refresh)
	ScrollTouchHelper.enable(_main_scroll)
	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 1.0
	_countdown_timer.timeout.connect(_refresh_countdown)
	add_child(_countdown_timer)
	_countdown_timer.start()
	_refresh()


## ノノカは CanvasLayer で最前面。テクスチャはディスク直読み（import キャッシュ回避）。
func _ensure_nonoka_mascot() -> void:
	var inner: VBoxContainer = (
		$MainScroll/MainVBox/SidePad/InnerVBox as VBoxContainer
	)
	if inner == null or _field_panel == null or _field_vbox == null:
		return
	_restore_field_labels_from_nonoka_row(_field_vbox)
	var old_on_panel: Node = _field_panel.get_node_or_null("NonokaMascot")
	if old_on_panel != null:
		old_on_panel.queue_free()
	## 旧 FieldHost 内マスコットがあれば除去し、ホスト構造は維持。
	if inner.get_node_or_null("FieldHost") != null:
		_field_host = inner.get_node("FieldHost") as Control
		var old_in_host: Node = _field_host.get_node_or_null("NonokaMascot")
		if old_in_host != null:
			old_in_host.queue_free()
	else:
		var host := Control.new()
		host.name = "FieldHost"
		host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.clip_contents = false
		_field_host = host
		var panel_index: int = _field_panel.get_index()
		inner.remove_child(_field_panel)
		host.add_child(_field_panel)
		_field_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_field_panel.offset_left = 0.0
		_field_panel.offset_top = 0.0
		_field_panel.offset_right = 0.0
		_field_panel.offset_bottom = 0.0
		inner.add_child(host)
		inner.move_child(host, panel_index)
		if not _field_panel.resized.is_connected(_on_field_panel_resized):
			_field_panel.resized.connect(_on_field_panel_resized)

	_nonoka_texture = _load_nonoka_texture()
	_ensure_nonoka_layer()
	_sync_field_host_min_size(_field_host, _field_panel)
	call_deferred("_sync_field_host_min_size", _field_host, _field_panel)
	call_deferred("_sync_nonoka_screen_pos")


func _load_nonoka_texture() -> Texture2D:
	## ResourceLoader キャッシュを避け、PNG を直読みする。
	var abs_path: String = ProjectSettings.globalize_path(NONOKA_PATH)
	if abs_path.is_empty() or not FileAccess.file_exists(abs_path):
		if ResourceLoader.exists(NONOKA_PATH):
			return load(NONOKA_PATH) as Texture2D
		return null
	var img := Image.new()
	var err: Error = img.load(abs_path)
	if err != OK:
		push_warning("Nonoka image load failed: %s (%s)" % [abs_path, error_string(err)])
		if ResourceLoader.exists(NONOKA_PATH):
			return load(NONOKA_PATH) as Texture2D
		return null
	return ImageTexture.create_from_image(img)


func _ensure_nonoka_layer() -> void:
	if _nonoka_layer != null and is_instance_valid(_nonoka_layer):
		if _nonoka_rect != null and _nonoka_texture != null:
			_nonoka_rect.texture = _nonoka_texture
		return
	_nonoka_layer = CanvasLayer.new()
	_nonoka_layer.name = "NonokaOverlayLayer"
	_nonoka_layer.layer = NONOKA_LAYER
	add_child(_nonoka_layer)
	_nonoka_rect = TextureRect.new()
	_nonoka_rect.name = "NonokaMascot"
	_nonoka_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nonoka_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_nonoka_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_nonoka_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_nonoka_rect.modulate = NONOKA_MODULATE
	_nonoka_rect.custom_minimum_size = Vector2(NONOKA_W, NONOKA_H)
	_nonoka_rect.size = Vector2(NONOKA_W, NONOKA_H)
	if _nonoka_texture != null:
		_nonoka_rect.texture = _nonoka_texture
	_nonoka_layer.add_child(_nonoka_rect)


func _sync_nonoka_screen_pos() -> void:
	if _nonoka_rect == null or not is_instance_valid(_nonoka_rect):
		return
	if _field_host == null or not is_instance_valid(_field_host):
		return
	## FieldHost の画面座標へ追従（スクロール込み）。
	var origin: Vector2 = _field_host.get_global_transform_with_canvas().origin
	_nonoka_rect.global_position = origin + NONOKA_OFFSET
	_nonoka_rect.size = Vector2(NONOKA_W, NONOKA_H)


func _process(_delta: float) -> void:
	if _nonoka_rect != null and is_instance_valid(_nonoka_rect):
		_sync_nonoka_screen_pos()


func _on_field_panel_resized() -> void:
	if _field_host != null and _field_panel != null:
		_sync_field_host_min_size(_field_host, _field_panel)
	_sync_nonoka_screen_pos()


func _sync_field_host_min_size(host: Control, panel: PanelContainer) -> void:
	if host == null or panel == null or not is_instance_valid(host) or not is_instance_valid(panel):
		return
	var min_sz: Vector2 = panel.get_combined_minimum_size()
	var top_extra: float = maxf(0.0, -NONOKA_OFFSET.y)
	host.custom_minimum_size = Vector2(0.0, maxf(min_sz.y, NONOKA_H) + top_extra)


func _apply_nonoka_rect(nonoka: TextureRect) -> void:
	nonoka.offset_left = NONOKA_OFFSET.x
	nonoka.offset_top = NONOKA_OFFSET.y
	nonoka.offset_right = NONOKA_OFFSET.x + NONOKA_W
	nonoka.offset_bottom = NONOKA_OFFSET.y + NONOKA_H
	nonoka.custom_minimum_size = Vector2(NONOKA_W, NONOKA_H)


## 旧 HBox 配置があればラベルを FieldVBox 中央並びに戻す。
func _restore_field_labels_from_nonoka_row(field_vbox: VBoxContainer) -> void:
	var row: Node = field_vbox.get_node_or_null("NonokaRow")
	if row == null:
		return
	var head: Node = row.get_node_or_null("HeadCol")
	var restored: Array[Label] = []
	if head != null:
		for child in head.get_children():
			if child is Label:
				restored.append(child as Label)
	for lab in restored:
		head.remove_child(lab)
		field_vbox.add_child(lab)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	## 先頭順: Section → Headline → Timer →（以降は既存ノード）
	var order: Array[Label] = []
	for lab in restored:
		order.append(lab)
	for i in order.size():
		field_vbox.move_child(order[i], i)
	row.queue_free()


func _ensure_background() -> void:
	if has_node("BgTexture"):
		return
	var bg := TextureRect.new()
	bg.name = "BgTexture"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -10
	if ResourceLoader.exists(BG_PATH):
		bg.texture = load(BG_PATH) as Texture2D
	add_child(bg)
	move_child(bg, 0)

func _ensure_field_spacing() -> void:
	var top_pad: Control = $MainScroll/MainVBox/TopPad as Control
	if top_pad != null:
		top_pad.custom_minimum_size = Vector2(0, FIELD_TOP_PAD_PX)
	if _field_vbox == null:
		return
	_field_vbox.add_theme_constant_override("separation", 10)
	_ensure_gap_after(_field_vbox, "MidPad", _label_field_notes, FIELD_MID_GAP_PX)
	## 旧 TailPad があれば除去（空白を増やすだけだった）。
	var old_tail: Node = _field_vbox.get_node_or_null("TailPad")
	if old_tail != null:
		old_tail.queue_free()


func _ensure_gap_after(parent: VBoxContainer, node_name: String, after: Node, height_px: float) -> void:
	if parent == null or after == null:
		return
	var gap: Control = parent.get_node_or_null(node_name) as Control
	if gap == null:
		gap = Control.new()
		gap.name = node_name
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var after_i: int = after.get_index()
		parent.add_child(gap)
		parent.move_child(gap, after_i + 1)
	gap.custom_minimum_size = Vector2(0, height_px)


func _layout_guild_report() -> void:
	if _label_desc == null:
		return
	_label_desc.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label_desc.offset_left = MEMO_LEFT
	_label_desc.offset_top = MEMO_TOP
	_label_desc.offset_right = MEMO_LEFT + MEMO_WIDTH
	_label_desc.offset_bottom = MEMO_TOP + MEMO_HEIGHT
	_label_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_desc.z_index = 5
	_prepare_rich_label(_label_desc, FIELD_SIZE_CAPTION, INK, false)


func _ensure_weather_guide() -> void:
	if _field_vbox == null:
		return
	if _label_weather_guide != null and is_instance_valid(_label_weather_guide):
		return
	var existing: Node = _field_vbox.get_node_or_null("LabelWeatherGuide")
	if existing is RichTextLabel:
		_label_weather_guide = existing as RichTextLabel
	else:
		_label_weather_guide = RichTextLabel.new()
		_label_weather_guide.name = "LabelWeatherGuide"
		_field_vbox.add_child(_label_weather_guide)
	## 効果欄の直後（注目区域の前）へ。
	if _label_effect != null:
		var effect_i: int = _label_effect.get_index()
		_field_vbox.move_child(_label_weather_guide, effect_i + 1)
	_prepare_rich_label(_label_weather_guide, FIELD_SIZE_FIELD_NOTES, INK_MUTED, true)
	_label_weather_guide.text = _emphasize_bbcode(CombatWeather.bulletin_reference_text())


func _apply_typography() -> void:
	## はじめガイドと同じ：Shippori（display）で統一。アウトライン無し。
	_apply_guide_label(_label_issue_date, FIELD_SIZE_CAPTION, INK_MUTED)
	_apply_guide_label(_label_section, FIELD_SIZE_SECTION, INK_GOLD)
	_apply_guide_label(_label_headline, FIELD_SIZE_HEADLINE, INK)
	_apply_guide_label(_label_timer, FIELD_SIZE_TIMER, INK_TIMER)
	_apply_guide_label(_label_schedule, FIELD_SIZE_CAPTION, INK_MUTED)
	_apply_guide_label(_label_featured, FIELD_SIZE_CAPTION, INK_GOLD)
	if _label_timer != null:
		_label_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prepare_rich_label(_label_field_notes, FIELD_SIZE_FIELD_NOTES, INK_MUTED, true)
	_prepare_rich_label(_label_article, FIELD_SIZE_ARTICLE, INK, true)
	_prepare_rich_label(_label_effect, FIELD_SIZE_EFFECT, INK_GOLD, true)
	if _label_weather_guide != null:
		_prepare_rich_label(_label_weather_guide, FIELD_SIZE_FIELD_NOTES, INK_MUTED, true)
	_prepare_rich_label(_label_desc, FIELD_SIZE_CAPTION, INK, false)


func _prepare_rich_label(rtl: RichTextLabel, size: int, color: Color, fit_content: bool = true) -> void:
	if rtl == null:
		return
	var display: Font = UiTypography.display_font()
	rtl.bbcode_enabled = true
	rtl.fit_content = fit_content
	rtl.scroll_active = false
	rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if display != null:
		rtl.add_theme_font_override("normal_font", display)
		rtl.add_theme_font_override("bold_font", display)
	rtl.add_theme_font_size_override("normal_font_size", size)
	rtl.add_theme_font_size_override("bold_font_size", size)
	rtl.add_theme_color_override("default_color", color)
	## はじめガイド同様、アウトライン無し。
	rtl.add_theme_constant_override("outline_size", 0)


func _apply_field_panel_style() -> void:
	if _field_panel == null:
		return
	## 半透明パネルをやめ、ギルド情報誌の背景をそのまま見せる。
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = 12.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 10.0
	_field_panel.add_theme_stylebox_override("panel", sb)


func _apply_guide_label(lab: Label, size: int, color: Color) -> void:
	if lab == null:
		return
	UiTypography.apply_display(lab, size, color, 0)

func _layout_chrome() -> void:
	var top_inset: float = 0.0
	if SafeAreaHelper.should_apply_chrome():
		top_inset = SafeAreaHelper.top_inset()
	_header.offset_top = top_inset
	_header.offset_bottom = top_inset + 46.0
	_main_scroll.offset_top = _header.offset_bottom
	_main_scroll.visible = true
	var title: Label = $Header/HeaderRow/LabelTitle as Label
	if title != null:
		title.visible = false
		title.text = ""

func _refresh() -> void:
	var event_data: Resource = EventSystem.get_active_event()
	if event_data == null:
		SceneRouter.change_scene(HOME_SCENE)
		return
	_label_issue_date.text = EventSystem.issue_date_text()
	_label_section.text = "いまの野外"
	_label_headline.text = EventSystem.active_modifier_summary()
	if _label_headline.text.is_empty():
		_label_headline.text = str(event_data.title)
	_refresh_countdown()
	_label_schedule.text = "開催期間: %s" % EventSystem.schedule_text(event_data)
	_label_field_notes.text = _emphasize_bbcode(_event_field_notes(event_data))
	_label_article.text = _emphasize_bbcode(_event_article(event_data))
	_label_effect.text = _emphasize_bbcode(_event_effect_summary(event_data))
	if _label_weather_guide != null:
		_label_weather_guide.text = _emphasize_bbcode(CombatWeather.bulletin_reference_text())
	_label_desc.text = _emphasize_bbcode(_guild_report_body(event_data))
	if EventSystem.is_featured_biome_week():
		var biome_id: String = EventSystem.get_featured_biome_id()
		var biome_name: String = ""
		if not biome_id.is_empty():
			var biome: Resource = DataRegistry.get_dungeon_data(biome_id)
			if biome != null:
				biome_name = str(biome.display_name)
		_label_featured.visible = not biome_name.is_empty()
		_label_featured.text = "注目区域: %s" % biome_name
		if not biome_name.is_empty():
			var extras: Array = [biome_name]
			_label_field_notes.text = _emphasize_bbcode(_event_field_notes(event_data), extras)
			_label_article.text = _emphasize_bbcode(_event_article(event_data), extras)
			_label_effect.text = _emphasize_bbcode(_event_effect_summary(event_data), extras)
			_label_desc.text = _emphasize_bbcode(_guild_report_body(event_data), extras)
	else:
		_label_featured.visible = false
		_label_featured.text = ""


func _emphasize_bbcode(plain: String, extra_terms: Array = []) -> String:
	var text: String = plain
	if text.is_empty():
		return text
	var terms: Array[String] = []
	for t: Variant in extra_terms:
		var s: String = str(t).strip_edges()
		if not s.is_empty():
			terms.append(s)
	for t2: String in EMPHASIS_TERMS:
		terms.append(t2)
	## 長い語優先＋プレースホルダで入れ子破壊を防ぐ。
	terms.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	var hex: String = INK_EMPHASIS.to_html(false)
	var seen: Dictionary = {}
	var placeholders: Array[Dictionary] = []
	var idx: int = 0
	for term: String in terms:
		if term.is_empty() or seen.has(term):
			continue
		seen[term] = true
		if text.find(term) < 0:
			continue
		var token: String = "⟦E%d⟧" % idx
		text = text.replace(term, token)
		placeholders.append({"token": token, "term": term})
		idx += 1
	for entry: Dictionary in placeholders:
		var term2: String = str(entry["term"])
		var token2: String = str(entry["token"])
		text = text.replace(token2, "[color=#%s]%s[/color]" % [hex, term2])
	return text


func _event_field_notes(event_data: Resource) -> String:
	if event_data != null and "field_notes" in event_data:
		var notes: String = str(event_data.field_notes).strip_edges()
		if not notes.is_empty():
			return notes
	return ""


func _event_article(event_data: Resource) -> String:
	if event_data != null and "article" in event_data:
		var article: String = str(event_data.article).strip_edges()
		if not article.is_empty():
			return article
	## 旧データ互換: description を本文に流用。
	return _guild_report_body(event_data)


func _event_effect_summary(event_data: Resource) -> String:
	if event_data != null and "effect_summary" in event_data:
		var effect: String = str(event_data.effect_summary).strip_edges()
		if not effect.is_empty():
			return effect
	var banner: String = str(event_data.banner_desc).strip_edges() if event_data != null else ""
	if banner.is_empty() or banner == "特記なし":
		return "・特記事項なし"
	return "・%s" % banner


func _guild_report_body(event_data: Resource) -> String:
	var text: String = str(event_data.description).strip_edges()
	for prefix: String in ["ギルド報告：", "ギルド報告:"]:
		if text.begins_with(prefix):
			return text.substr(prefix.length()).strip_edges()
	return text

func _refresh_countdown() -> void:
	if _label_timer == null:
		return
	var raw: String = EventSystem.countdown_text()
	## 「残り」を目立たせる（例: 残り 16分）。
	if raw.begins_with("残り"):
		_label_timer.text = raw
	else:
		_label_timer.text = "残り %s" % raw

func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
