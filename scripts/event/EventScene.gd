extends Control

## ギルド情報誌（P3-EVT-FIELD-001）。いまの野外＋発行日。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const BG_PATH: String = "res://assets/ui/UI_BG_GuildBulletin.png"

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


## 720×1280・COVERED 時のメモ本文枠（背景アート基準）。
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
	"氷属性",
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
var _label_weather_guide: RichTextLabel = null

func _ready() -> void:
	_field_panel = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel as PanelContainer
	_field_vbox = $MainScroll/MainVBox/SidePad/InnerVBox/FieldPanel/FieldVBox as VBoxContainer
	_ensure_background()
	_apply_field_panel_style()
	_ensure_field_spacing()
	_ensure_weather_guide()
	_strip_nonoka_mascot()
	_layout_guild_report()
	_apply_typography()
	_layout_chrome()
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	EventSystem.event_updated.connect(_refresh)
	ScrollTouchHelper.enable(_main_scroll)
	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 1.0
	_countdown_timer.timeout.connect(_refresh_countdown)
	add_child(_countdown_timer)
	_countdown_timer.start()
	_refresh()


## 旧マスコット／FieldHost ラップがあれば除去して FieldPanel を InnerVBox へ戻す。
func _strip_nonoka_mascot() -> void:
	var overlay: Node = get_node_or_null("NonokaOverlayLayer")
	if overlay != null:
		overlay.queue_free()
	if _field_panel == null:
		return
	var old_on_panel: Node = _field_panel.get_node_or_null("NonokaMascot")
	if old_on_panel != null:
		old_on_panel.queue_free()
	var inner: VBoxContainer = (
		$MainScroll/MainVBox/SidePad/InnerVBox as VBoxContainer
	)
	if inner == null:
		return
	var host: Node = inner.get_node_or_null("FieldHost")
	if host == null:
		return
	var old_in_host: Node = host.get_node_or_null("NonokaMascot")
	if old_in_host != null:
		old_in_host.queue_free()
	if _field_panel.get_parent() != host:
		host.queue_free()
		return
	var host_index: int = host.get_index()
	host.remove_child(_field_panel)
	inner.add_child(_field_panel)
	inner.move_child(_field_panel, host_index)
	## Container 直下へ戻す（絶対アンカーは親が上書きする）。
	_field_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	host.queue_free()


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
	## 現場班コメント（field_notes）は非表示。下部メモと表記がぶれるため。
	## 記事・効果は開催期間の直後へ寄せる（メモ枠位置は固定のまま）。
	if _label_field_notes != null:
		_label_field_notes.visible = false
		_label_field_notes.text = ""
		_label_field_notes.custom_minimum_size = Vector2.ZERO
		_label_field_notes.fit_content = false
	var mid_after: Node = _label_schedule if _label_schedule != null else _label_field_notes
	_ensure_gap_after(_field_vbox, "MidPad", mid_after, FIELD_MID_GAP_PX)
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
	_label_weather_guide.visible = false
	_label_weather_guide.text = ""


func _refresh_weather_guide() -> void:
	if _label_weather_guide == null:
		return
	var wid: String = EventSystem.forced_weather_id()
	if wid.is_empty():
		_label_weather_guide.visible = false
		_label_weather_guide.text = ""
		return
	var body: String = CombatWeather.bulletin_active_weather_text(wid)
	if body.is_empty():
		_label_weather_guide.visible = false
		_label_weather_guide.text = ""
		return
	_label_weather_guide.visible = true
	_label_weather_guide.text = _emphasize_bbcode(body)


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
	## 見出しは title（例: 穏やかな野外）。banner_desc はホーム帯用。
	_label_headline.text = str(event_data.title).strip_edges()
	if _label_headline.text.is_empty():
		_label_headline.text = EventSystem.active_modifier_summary()
	_refresh_countdown()
	_label_schedule.text = "開催期間: %s" % EventSystem.schedule_text(event_data)
	## field_notes（第○班／鍛冶など）は非表示。記事・効果・天候のみ。
	if _label_field_notes != null:
		_label_field_notes.visible = false
		_label_field_notes.text = ""
	_label_article.text = _emphasize_bbcode(_event_article(event_data))
	_label_effect.text = _emphasize_bbcode(_event_effect_summary(event_data))
	_refresh_weather_guide()
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
