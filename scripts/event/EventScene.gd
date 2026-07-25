extends Control

## ギルド情報誌（P3-EVT-FIELD-001）。いまの野外＋発行日。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const BG_PATH: String = "res://assets/ui/UI_BG_GuildBulletin.png"

## 羊皮紙上のインク色（明るい UI 金ではなく濃色）。
const INK: Color = Color(0.22, 0.14, 0.08, 1.0)
const INK_GOLD: Color = Color(0.42, 0.28, 0.10, 1.0)
const INK_MUTED: Color = Color(0.35, 0.28, 0.20, 1.0)
## 背景アートを見せるため、いまの野外枠は塗りなし。
const FIELD_OUTLINE: int = 5
const FIELD_OUTLINE_COLOR: Color = Color(0.96, 0.90, 0.78, 0.92)
## 羊皮紙上の文字を太く見せる（FontVariation 合成太字）。
const FIELD_EMBOLDEN: float = 1.15
const FIELD_SIZE_SECTION: int = 22
const FIELD_SIZE_HEADLINE: int = 32
const FIELD_SIZE_BODY: int = 24
const FIELD_SIZE_CAPTION: int = 20


## 720×1280・COVERED 時の調査部メモ本文枠（背景アート基準）。
const MEMO_LEFT: float = 128.0
const MEMO_TOP: float = 925.0
const MEMO_WIDTH: float = 310.0
const MEMO_HEIGHT: float = 130.0

@onready var _header: PanelContainer = $Header
@onready var _main_scroll: ScrollContainer = $MainScroll
@onready var _label_issue_date: Label = $MainScroll/MainVBox/SidePad/InnerVBox/IssueDateRow/LabelIssueDate
@onready var _label_section: Label = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelSection
@onready var _label_headline: Label = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelHeadline
@onready var _label_timer: Label = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelTimer
@onready var _label_schedule: Label = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelSchedule
@onready var _label_featured: Label = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox/LabelFeatured
@onready var _label_desc: Label = $LabelGuildReport

var _countdown_timer: Timer

func _ready() -> void:
	_ensure_background()
	_apply_field_panel_style()
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
	_label_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_label_desc.clip_text = false

func _apply_field_panel_style() -> void:
	var panel: PanelContainer = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel as PanelContainer
	if panel == null:
		return
	## 半透明パネルをやめ、ギルド情報誌の背景をそのまま見せる。
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = 12.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", sb)

func _apply_typography() -> void:
	var bold_body: Font = _make_bold_font(UiTypography.body_font())
	var bold_display: Font = _make_bold_font(UiTypography.display_font())
	_apply_field_label(_label_issue_date, bold_body, FIELD_SIZE_CAPTION, INK_MUTED)
	_apply_field_label(_label_section, bold_display, FIELD_SIZE_SECTION, INK_GOLD)
	_apply_field_label(_label_headline, bold_display, FIELD_SIZE_HEADLINE, INK)
	_apply_field_label(_label_timer, bold_body, FIELD_SIZE_BODY, INK_GOLD)
	_apply_field_label(_label_schedule, bold_body, FIELD_SIZE_CAPTION, INK_MUTED)
	_apply_field_label(_label_desc, bold_body, FIELD_SIZE_CAPTION, INK)
	_apply_field_label(_label_featured, bold_body, FIELD_SIZE_CAPTION, INK_GOLD)

func _make_bold_font(base: Font) -> Font:
	if base == null:
		return null
	var variation := FontVariation.new()
	variation.base_font = base
	variation.variation_embolden = FIELD_EMBOLDEN
	return variation

func _apply_field_label(lab: Label, font: Font, size: int, color: Color) -> void:
	if lab == null:
		return
	if font != null:
		lab.add_theme_font_override("font", font)
	lab.add_theme_font_size_override("font_size", size)
	lab.add_theme_color_override("font_color", color)
	lab.add_theme_constant_override("outline_size", FIELD_OUTLINE)
	lab.add_theme_color_override("font_outline_color", FIELD_OUTLINE_COLOR)

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
	_label_desc.text = _guild_report_body(event_data)
	if EventSystem.is_featured_biome_week():
		var biome_id: String = EventSystem.get_featured_biome_id()
		var biome_name: String = ""
		if not biome_id.is_empty():
			var biome: Resource = DataRegistry.get_dungeon_data(biome_id)
			if biome != null:
				biome_name = str(biome.display_name)
		_label_featured.visible = not biome_name.is_empty()
		_label_featured.text = "注目区域: %s" % biome_name
	else:
		_label_featured.visible = false
		_label_featured.text = ""

func _guild_report_body(event_data: Resource) -> String:
	var text: String = str(event_data.description).strip_edges()
	for prefix: String in ["ギルド報告：", "ギルド報告:"]:
		if text.begins_with(prefix):
			return text.substr(prefix.length()).strip_edges()
	return text

func _refresh_countdown() -> void:
	if _label_timer == null:
		return
	_label_timer.text = EventSystem.countdown_text()

func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
