extends Control

## 調査室（P3-HUB-SURVEY-001）。モック構成準拠・通常 BottomNav。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const BG_PATH: String = "res://assets/ui/UI_BG_Survey.png"
## 上部キーアート（横長）。フル画面 BG とは別。
const HERO_BG_PATH: String = "res://assets/ui/UI_BG_Survey_Hero.png"
const TARGET_ICON_PX: float = 88.0
const REWARD_ICON_PX: float = 28.0
const ASSIGNEE_ICON_PX: float = 64.0
## ヒーロー高さ算出の参照幅（アスペクト維持の基準 → 半分に縮小）。
const HERO_REF_WIDTH_PX: float = 680.0
const HERO_HEIGHT_SCALE: float = 0.5
const HERO_HEIGHT_FALLBACK_PX: float = 180.0
const HERO_TITLE: String = "調査室"
const HERO_LEAD: String = "ダンジョンで入手した資料を調査し、\n失われた歴史や遺跡の手がかりを解明します。"
const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")
const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
const _CurrencyHelper := preload("res://scripts/ui/CurrencyHelper.gd")
const _RosterUiHelper := preload("res://scripts/roster/RosterUiHelper.gd")
const _RoomGuide := preload("res://scripts/ui/DungeonRouteGuideOverlay.gd")
const GOLD_ICON_PATH: String = "res://assets/ui/batch2/ICO_Gold.png"

@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _content: VBoxContainer = $MainScroll/MainVBox/ContentHost
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _gold_chip: Control = $Header/HeaderRow/GoldChip
@onready var _token_chip: Control = $Header/HeaderRow/TokenChip

var _label_target_name: Label
var _label_target_desc: Label
var _label_survey_pct: Label
var _target_pct_bar: ProgressBar
var _target_icon: TextureRect
var _progress_bar: ProgressBar
var _label_timer: Label
var _label_status: Label
var _label_bonus: Label
var _assignee_box: HBoxContainer
var _btn_claim: Button
var _btn_cancel: Button
var _btn_start_short: Button
var _btn_start_std: Button
var _btn_auto: Button
var _btn_change_dungeon: Button
var _target_drops: HBoxContainer
var _pending_members: Array[String] = []
var _target_dungeon_id: String = Constants.MOURNGATE_DUNGEON_ID
var _tick: float = 0.0
var _claim_fx_busy: bool = false
var _start_confirm: ConfirmationDialog
var _cancel_confirm: ConfirmationDialog
var _pending_start_preset: String = ""
var _pick_overlay: Control = null
var _claim_result_overlay: SurveyClaimResultOverlay = null


func _ready() -> void:
	_label_title.text = ""
	_label_title.visible = false
	AudioManager.play_bgm("survey")
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	_hide_legacy_event_nodes()
	_ensure_background()
	_raise_header_chrome()
	_constrain_main_scroll()
	HeaderCurrencyHelper.apply_to_row($Header/HeaderRow)
	_setup_start_confirm()
	_setup_cancel_confirm()
	_build_ui()
	## 前回配置を維持（未記録の初回のみおまかせ相当）。
	_SurveySystem.ensure_party_restored_if_awaiting_claim()
	_pending_members = _SurveySystem.pending_members_for_ui()
	_update_currency()
	_refresh()
	_setup_room_guide_help()
	call_deferred("_try_auto_claim_on_enter")


func _setup_room_guide_help() -> void:
	var row: Control = $Header/HeaderRow as Control
	if row == null or row.get_node_or_null("HubRoomGuideHelpBtn") != null:
		return
	_RoomGuide.attach_help_button(row, self, _RoomGuide.GUIDE_SURVEY, "？")


func _try_show_room_guide() -> void:
	if _claim_fx_busy:
		return
	if get_node_or_null("DungeonRouteGuideOverlay") != null:
		return
	_RoomGuide.try_auto_show(self, _RoomGuide.GUIDE_SURVEY)


## 長い日本語行で親まで横拡大し、一覧が右に見切れないようにする。
func _constrain_main_scroll() -> void:
	var scroll: ScrollContainer = $MainScroll as ScrollContainer
	if scroll != null:
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		scroll.clip_contents = true
	var main_vb: VBoxContainer = $MainScroll/MainVBox as VBoxContainer
	if main_vb != null:
		main_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_vb.custom_minimum_size.x = 0.0
		main_vb.grow_horizontal = Control.GROW_DIRECTION_END
	if _content != null:
		_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_content.custom_minimum_size.x = 0.0


## 戻る／通貨を BG・ヒーローより前面へ（実機で背景に沈むのを防ぐ）。
func _raise_header_chrome() -> void:
	var header: Control = $Header as Control
	if header == null:
		return
	header.z_as_relative = false
	header.z_index = 40
	## BottomNav(z=20) より手前、オーバーレイより下。
	move_child(header, get_child_count() - 1)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.1, 0.96)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.55, 0.45, 0.18, 0.6)
	sb.content_margin_left = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 8.0
	header.add_theme_stylebox_override("panel", sb)


func _maybe_show_content_unlock() -> void:
	if GameState.pending_clear_nina_merit:
		return
	const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")
	_ContentUnlockNotice.show_pending_on(self)


func _process(delta: float) -> void:
	_tick += delta
	if _tick < 0.5:
		return
	_tick = 0.0
	if _claim_fx_busy:
		return
	if _SurveySystem.has_active_cycle():
		_refresh_progress_only()


func _hide_legacy_event_nodes() -> void:
	for path: String in [
		"MainScroll/MainVBox/ModifierPanel",
		"MainScroll/MainVBox/LabelTimer",
		"MainScroll/MainVBox/LabelSchedule",
		"MainScroll/MainVBox/LabelDesc",
	]:
		var n: Node = get_node_or_null(path)
		if n is CanvasItem:
			(n as CanvasItem).visible = false


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
	var dim := ColorRect.new()
	dim.name = "BgDim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.05, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.z_index = -9
	add_child(dim)
	move_child(dim, 1)


func _build_ui() -> void:
	for c in _content.get_children():
		c.queue_free()
	## 左右余白。長い行の最小幅が親を押し広げないよう外側でクリップ。
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.clip_contents = true
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size.x = 0.0
	body.add_theme_constant_override("separation", 14)
	pad.add_child(body)
	_content.add_child(pad)

	body.add_child(_build_hero_lead())
	body.add_child(_build_target_card())

	body.add_child(_build_assignee_section())
	_assignee_box = HBoxContainer.new()
	_assignee_box.add_theme_constant_override("separation", 8)
	_assignee_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_assignee_box.custom_minimum_size.x = 0.0
	_assignee_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_assignee_box.clip_contents = true
	body.add_child(_assignee_box)

	body.add_child(_build_cycle_progress_card())
	body.add_child(_build_expected_rewards_card())

	var start_row := HBoxContainer.new()
	start_row.add_theme_constant_override("separation", 8)
	start_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_row.custom_minimum_size.x = 0.0
	_btn_start_short = Button.new()
	_btn_start_short.text = _SurveyConfig.display_name_with_duration(_SurveyConfig.PRESET_SHORT)
	_btn_start_short.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_start_short.pressed.connect(func(): _on_start(_SurveyConfig.PRESET_SHORT))
	start_row.add_child(_btn_start_short)
	_btn_start_std = Button.new()
	_btn_start_std.text = _SurveyConfig.display_name_with_duration(_SurveyConfig.PRESET_STANDARD)
	_btn_start_std.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_start_std.pressed.connect(func(): _on_start(_SurveyConfig.PRESET_STANDARD))
	start_row.add_child(_btn_start_std)
	body.add_child(start_row)

	_btn_claim = Button.new()
	_btn_claim.text = "調査中..."
	_btn_claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_claim.custom_minimum_size = Vector2(0, 48)
	_btn_claim.pressed.connect(_on_claim)
	body.add_child(_btn_claim)
	_btn_cancel = Button.new()
	_btn_cancel.text = "調査を中止"
	_btn_cancel.visible = false
	_btn_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_cancel.pressed.connect(_on_cancel_pressed)
	body.add_child(_btn_cancel)


func _build_hero_lead() -> Control:
	var host := Control.new()
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.custom_minimum_size = Vector2(0, _hero_banner_height())
	host.clip_contents = true
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := TextureRect.new()
	bg.name = "HeroBg"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	## 半高さ帯でも幅いっぱいに見せる（上下クロップ）。
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(HERO_BG_PATH):
		bg.texture = load(HERO_BG_PATH) as Texture2D
	host.add_child(bg)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.06, 0.42)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(dim)

	var text_col := VBoxContainer.new()
	text_col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_col.add_theme_constant_override("separation", 10)
	text_col.alignment = BoxContainer.ALIGNMENT_CENTER
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(text_col)

	var title := Label.new()
	title.text = HERO_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_display(title, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD)
	text_col.add_child(title)

	var lead := Label.new()
	lead.text = HERO_LEAD
	lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lead.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	lead.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lead.custom_minimum_size.x = 0.0
	UiTypography.apply_body(lead, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB)
	text_col.add_child(lead)
	return host


func _hero_banner_height() -> float:
	if not ResourceLoader.exists(HERO_BG_PATH):
		return HERO_HEIGHT_FALLBACK_PX
	var tex: Texture2D = load(HERO_BG_PATH) as Texture2D
	if tex == null or tex.get_width() <= 0:
		return HERO_HEIGHT_FALLBACK_PX
	var full: float = HERO_REF_WIDTH_PX * float(tex.get_height()) / float(tex.get_width())
	return full * HERO_HEIGHT_SCALE


func _build_assignee_section() -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.custom_minimum_size.x = 0.0
	header.clip_contents = true
	var title := Label.new()
	title.text = "調査員の配置"
	UiTypography.apply_display(title, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(title)
	_label_bonus = Label.new()
	_label_bonus.text = "合計ボーナス +0%"
	_label_bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label_bonus.size_flags_horizontal = Control.SIZE_SHRINK_END
	UiTypography.apply_caption(_label_bonus, UiTypography.COLOR_GOLD)
	header.add_child(_label_bonus)
	_btn_auto = Button.new()
	_btn_auto.text = "おまかせ"
	_btn_auto.tooltip_text = "おまかせ配置"
	_btn_auto.size_flags_horizontal = Control.SIZE_SHRINK_END
	_btn_auto.pressed.connect(_on_auto_assign)
	header.add_child(_btn_auto)
	return header


func _build_cycle_progress_card() -> PanelContainer:
	var card := _card_panel()
	card.clip_contents = true
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "調査の進行状況"
	UiTypography.apply_display(title, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	vb.add_child(title)
	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.custom_minimum_size = Vector2(0, 28)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_bar.show_percentage = false
	_style_survey_progress_bar(_progress_bar)
	vb.add_child(_progress_bar)
	_label_timer = _make_caption("調査完了まで: —")
	vb.add_child(_label_timer)
	_label_status = _make_caption("")
	vb.add_child(_label_status)
	card.add_child(vb)
	return card


## モック寄り: 達成＝不透明アンバー、未達成＝暗い窪み（インセット枠）。
func _style_survey_progress_bar(bar: ProgressBar) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.08, 0.06, 1.0)
	bg.set_corner_radius_all(6)
	bg.set_border_width_all(2)
	bg.border_color = Color(0.04, 0.03, 0.02, 1.0)
	## 上辺をさらに暗く見せて窪み感（内側の影代わり）。
	bg.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	bg.shadow_size = 3
	bg.shadow_offset = Vector2(0, 1)
	bg.content_margin_left = 2
	bg.content_margin_top = 2
	bg.content_margin_right = 2
	bg.content_margin_bottom = 2
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.92, 0.70, 0.22, 1.0)
	fill.set_corner_radius_all(4)
	fill.set_border_width_all(1)
	fill.border_color = Color(1.0, 0.88, 0.45, 1.0)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


func _build_expected_rewards_card() -> PanelContainer:
	var card := _card_panel()
	card.clip_contents = true
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "調査完了時の期待成果"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_display(title, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	head.add_child(title)
	var list_btn := Button.new()
	list_btn.text = "報酬一覧"
	list_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	list_btn.pressed.connect(_on_reward_catalog_pressed)
	UiTypography.apply_menu_button(list_btn, false)
	head.add_child(list_btn)
	vb.add_child(head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	## アイコンのみ（確率％は報酬一覧ポップアップへ）
	row.add_child(_make_reward_chance_cell(
		IconPaths.get_icon_texture("iron_sword", "weapon"),
		"装備"
	))
	row.add_child(_make_reward_chance_cell(
		_CurrencyHelper.get_icon_texture(),
		"魔晶石"
	))
	var gold_tex: Texture2D = null
	if ResourceLoader.exists(GOLD_ICON_PATH):
		gold_tex = load(GOLD_ICON_PATH) as Texture2D
	## ゴールドは魔晶石ヒット時のみ（×5）。常時確定に見せない。
	row.add_child(_make_reward_chance_cell(gold_tex, "ゴールド（石連動）"))
	row.add_child(_make_reward_chance_cell(
		IconPaths.get_icon_texture("base_ore", "material"),
		"素材"
	))
	vb.add_child(row)
	card.add_child(vb)
	return card


func _make_reward_chance_cell(tex: Texture2D, label_text: String) -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 4)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(REWARD_ICON_PX + 8.0, REWARD_ICON_PX + 8.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if tex != null:
		icon.texture = tex
	cell.add_child(icon)
	var name_l := Label.new()
	name_l.text = label_text
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(name_l)
	cell.add_child(name_l)
	return cell


func _build_target_card() -> PanelContainer:
	var target_panel := _card_panel()
	target_panel.clip_contents = true
	target_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_panel.custom_minimum_size.x = 0.0
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.x = 0.0
	row.clip_contents = true

	_target_icon = TextureRect.new()
	_target_icon.custom_minimum_size = Vector2(TARGET_ICON_PX, TARGET_ICON_PX)
	_target_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_target_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_target_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_target_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_target_icon.texture = IconPaths.get_icon_texture("dungeon_mourngate", "survey")
	row.add_child(_target_icon)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.custom_minimum_size.x = 0.0
	mid.add_theme_constant_override("separation", 4)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_target_name = Label.new()
	_label_target_name.text = "—"
	_label_target_name.clip_text = true
	_label_target_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label_target_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label_target_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_target_name.custom_minimum_size.x = 0.0
	UiTypography.apply_display(_label_target_name, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	name_row.add_child(_label_target_name)
	_btn_change_dungeon = Button.new()
	_btn_change_dungeon.text = "変更"
	_btn_change_dungeon.size_flags_horizontal = Control.SIZE_SHRINK_END
	_btn_change_dungeon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_btn_change_dungeon.pressed.connect(_on_change_dungeon)
	name_row.add_child(_btn_change_dungeon)
	mid.add_child(name_row)
	_label_target_desc = _make_caption("—")
	_label_target_desc.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_label_target_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_target_desc.custom_minimum_size.x = 0.0
	mid.add_child(_label_target_desc)
	var drops_row := HBoxContainer.new()
	drops_row.add_theme_constant_override("separation", 8)
	drops_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_drops = HBoxContainer.new()
	_target_drops.add_theme_constant_override("separation", 6)
	_target_drops.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rebuild_target_drops()
	drops_row.add_child(_target_drops)
	var drops_list_btn := Button.new()
	drops_list_btn.text = "報酬一覧"
	drops_list_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	drops_list_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	drops_list_btn.pressed.connect(_on_reward_catalog_pressed)
	UiTypography.apply_menu_button(drops_list_btn, false)
	drops_row.add_child(drops_list_btn)
	mid.add_child(drops_row)
	row.add_child(mid)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_theme_constant_override("separation", 4)
	var pct_title := Label.new()
	pct_title.text = "調査進捗"
	pct_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_caption(pct_title, UiTypography.COLOR_GOLD)
	right.add_child(pct_title)
	_label_survey_pct = Label.new()
	_label_survey_pct.text = "0%"
	_label_survey_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_display(_label_survey_pct, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD)
	right.add_child(_label_survey_pct)
	_target_pct_bar = ProgressBar.new()
	_target_pct_bar.min_value = 0.0
	_target_pct_bar.max_value = 100.0
	_target_pct_bar.custom_minimum_size = Vector2(88, 12)
	_target_pct_bar.show_percentage = false
	_target_pct_bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	_style_survey_progress_bar(_target_pct_bar)
	right.add_child(_target_pct_bar)
	row.add_child(right)

	target_panel.add_child(row)
	return target_panel


func _rebuild_target_drops() -> void:
	if _target_drops == null:
		return
	for c in _target_drops.get_children():
		c.queue_free()
	var seen: Dictionary = {}
	## サイクル基本報酬（重複キーで後続を抑止）
	for pair in [
		["gold", _gold_icon_texture()],
		["material:base_ore", IconPaths.get_icon_texture("base_ore", "material")],
		["token", _CurrencyHelper.get_icon_texture()],
		["weapon", IconPaths.get_icon_texture("iron_sword", "weapon")],
	]:
		var key: String = str(pair[0])
		var tex: Texture2D = pair[1] as Texture2D
		if tex == null or seen.has(key):
			continue
		seen[key] = true
		_target_drops.add_child(_make_reward_texture_icon(tex))
	## 完全調査景品（同種アイコンは重ねない。％バッジは出さない）
	const _SurveyCompleteRewards := preload("res://scripts/survey/SurveyCompleteRewards.gd")
	var did: String = _selected_dungeon_id()
	for entry in _SurveyCompleteRewards.preview_entries(did):
		var dkey: String = _SurveyCompleteRewards.preview_dedupe_key(entry)
		if dkey.is_empty() or seen.has(dkey):
			continue
		seen[dkey] = true
		_target_drops.add_child(_make_complete_reward_icon(entry))


func _gold_icon_texture() -> Texture2D:
	if ResourceLoader.exists(GOLD_ICON_PATH):
		return load(GOLD_ICON_PATH) as Texture2D
	return null


func _make_complete_reward_icon(entry: Dictionary) -> Control:
	var kind: String = str(entry.get("kind", ""))
	var host := Control.new()
	host.custom_minimum_size = Vector2(REWARD_ICON_PX, REWARD_ICON_PX)
	host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match kind:
		"pet":
			var pet_id: String = str(entry.get("id", ""))
			var idle_tex: Texture2D = ChrIdlePortrait.get_idle_texture(pet_id)
			if idle_tex == null:
				idle_tex = IconPaths.get_icon_texture(pet_id, "chr")
			if idle_tex != null:
				var portrait := ChrIdlePortraitView.new()
				portrait.set_portrait_size(REWARD_ICON_PX)
				portrait.set_static_texture(idle_tex)
				portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
				host.add_child(portrait)
			else:
				host.add_child(_make_reward_texture_icon(null))
		"ticket":
			var tid: String = str(entry.get("id", ""))
			var ttex: Texture2D = IconPaths.get_icon_texture(tid, "ticket")
			host.add_child(_make_reward_texture_icon(ttex))
		"material":
			var mid: String = str(entry.get("id", ""))
			var mtex: Texture2D = IconPaths.get_icon_texture(mid, "material")
			host.add_child(_make_reward_texture_icon(mtex))
		"gold":
			host.add_child(_make_reward_texture_icon(_gold_icon_texture()))
		"token":
			host.add_child(_make_reward_texture_icon(_CurrencyHelper.get_icon_texture()))
		_:
			pass
	## ％バッジは報酬一覧ポップアップ側のみ（アイコン行は重複・％なし）
	return host


func _make_reward_texture_icon(tex: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(REWARD_ICON_PX, REWARD_ICON_PX)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = tex
	return icon


func _target_reward_textures() -> Array[Texture2D]:
	## 互換のため残置（一覧構築は _rebuild_target_drops 側）。
	var out: Array[Texture2D] = []
	var gold: Texture2D = _gold_icon_texture()
	if gold != null:
		out.append(gold)
	var mat: Texture2D = IconPaths.get_icon_texture("base_ore", "material")
	if mat != null:
		out.append(mat)
	var token: Texture2D = _CurrencyHelper.get_icon_texture()
	if token != null:
		out.append(token)
	var sword: Texture2D = IconPaths.get_icon_texture("iron_sword", "weapon")
	if sword != null:
		out.append(sword)
	return out


func _section_title(title: String, right: String) -> Control:
	var row := HBoxContainer.new()
	var left := Label.new()
	left.text = title
	UiTypography.apply_display(left, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	if not right.is_empty():
		var r := Label.new()
		r.text = right
		UiTypography.apply_caption(r)
		row.add_child(r)
	return row


func _card_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	return p


func _make_caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(l)
	return l


func _selected_dungeon_id() -> String:
	if _SurveySystem.has_active_cycle():
		var cycle_id: String = str(GameState.hub_survey_cycle.get("dungeon_id", ""))
		if not cycle_id.is_empty():
			return cycle_id
	var ids: Array[String] = _unlocked_main_dungeon_ids()
	if ids.is_empty():
		return Constants.MOURNGATE_DUNGEON_ID
	if not ids.has(_target_dungeon_id):
		_target_dungeon_id = ids[0]
	return _target_dungeon_id


func _unlocked_main_dungeon_ids() -> Array[String]:
	var mains: Array = []
	for data in DataRegistry.get_all_dungeon_data():
		if data == null:
			continue
		if str(data.route_type) != "main":
			continue
		var did: String = str(data.id)
		if did.is_empty():
			continue
		if not GameState.is_dungeon_unlocked(did):
			continue
		mains.append(data)
	mains.sort_custom(func(a, b): return int(a.difficulty) < int(b.difficulty))
	var out: Array[String] = []
	for data in mains:
		out.append(str(data.id))
	return out


func _survey_short_desc(dungeon_id: String) -> String:
	match dungeon_id:
		"mourngate":
			return "王都地下の古い遺構を調べる。"
		"whisperwood":
			return "霧深い森の痕跡を調べる。"
		"mistfen":
			return "沼地に眠る記録を調べる。"
		"blackshore":
			return "黒き海岸の痕跡を調べる。"
		"frostridge":
			return "霜の稜線の記録を調べる。"
		_:
			return "この区域の記録を調べる。"


func _dungeon_icon_texture(dungeon_id: String) -> Texture2D:
	if dungeon_id == Constants.MOURNGATE_DUNGEON_ID:
		var survey_tex: Texture2D = IconPaths.get_icon_texture("dungeon_mourngate", "survey")
		if survey_tex != null:
			return survey_tex
	var path_map: Dictionary = {
		"mourngate": "res://assets/dungeon/mourngate/ICO_DG_Mourngate.png",
		"whisperwood": "res://assets/dungeon/whisperwood/ICO_DG_Whisperwood.png",
		"mistfen": "res://assets/dungeon/mistfen/ICO_DG_Mistfen.png",
		"blackshore": "res://assets/dungeon/blackshore/ICO_DG_Blackshore.png",
		"frostridge": "res://assets/dungeon/frostridge/ICO_DG_Frostridge.png",
	}
	var path: String = str(path_map.get(dungeon_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		path = "res://assets/dungeon/mourngate/ICO_DG_Mourngate.png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _on_change_dungeon() -> void:
	if _SurveySystem.has_active_cycle():
		return
	var ids: Array[String] = _unlocked_main_dungeon_ids()
	if ids.size() <= 1:
		return
	var rows: Array[Dictionary] = []
	var cur: String = _selected_dungeon_id()
	for did in ids:
		var data: Resource = DataRegistry.get_dungeon_data(did)
		var name_str: String = did
		if data != null and "display_name" in data and str(data.display_name) != "":
			name_str = str(data.display_name)
		var pct: float = _SurveySystem.get_survey_percent(did)
		rows.append({
			"id": did,
			"title": name_str,
			"subtitle": "調査進捗 %.0f%%" % pct,
			"texture": _dungeon_icon_texture(did),
			"selected": did == cur,
			"disabled": false,
		})
	_open_pick_list("調査対象を選択", rows, func(picked_id: String) -> void:
		if picked_id.is_empty() or picked_id == _target_dungeon_id:
			return
		_target_dungeon_id = picked_id
		_refresh()
	)


func _refresh() -> void:
	_rebuild_assignees()
	_refresh_progress_only()
	var did: String = _selected_dungeon_id()
	var data: Resource = DataRegistry.get_dungeon_data(did)
	var name_str: String = did
	if data != null and "display_name" in data and str(data.display_name) != "":
		name_str = str(data.display_name)
	_label_target_name.text = name_str
	_label_target_desc.text = _survey_short_desc(did)
	_target_icon.texture = _dungeon_icon_texture(did)
	var pct: float = _SurveySystem.get_survey_percent(did)
	_label_survey_pct.text = "%.0f%%" % pct
	_target_pct_bar.value = pct
	_rebuild_target_drops()
	var bonus: float = _SurveySystem.total_speed_bonus(_pending_as_entries())
	_label_bonus.text = "合計ボーナス +%.0f%%" % (bonus * 100.0)
	var unlocked_n: int = _unlocked_main_dungeon_ids().size()
	_btn_change_dungeon.disabled = _SurveySystem.has_active_cycle() or unlocked_n <= 1


func _refresh_progress_only() -> void:
	if _claim_fx_busy:
		return
	var active: bool = _SurveySystem.has_active_cycle()
	var complete: bool = _SurveySystem.is_cycle_complete()
	## 調査室に居たまま完了した場合も編成を戻す（入室時 ensure だけでは漏れる）。
	if active and complete:
		_SurveySystem.ensure_party_restored_if_awaiting_claim()
	var p01: float = _SurveySystem.cycle_progress_01()
	_progress_bar.value = p01 * 100.0
	if not active:
		_progress_bar.value = 0.0
		_label_timer.text = "調査完了まで: —（未開始）"
		_btn_claim.text = "調査を開始してください"
		_btn_claim.disabled = true
		if _btn_cancel != null:
			_btn_cancel.visible = false
			_btn_cancel.disabled = true
		_btn_start_short.disabled = false
		_btn_start_std.disabled = false
		if _btn_change_dungeon != null:
			_btn_change_dungeon.disabled = _unlocked_main_dungeon_ids().size() <= 1
		return
	var rem: float = _SurveySystem.cycle_remaining_sec()
	_label_timer.text = "調査完了まで: %s（%.0f%%）" % [_format_hms(rem), p01 * 100.0]
	_btn_start_short.disabled = true
	_btn_start_std.disabled = true
	if _btn_change_dungeon != null:
		_btn_change_dungeon.disabled = true
	if complete:
		_btn_claim.text = "調査完了 — 受け取る"
		_btn_claim.disabled = false
		if _btn_cancel != null:
			_btn_cancel.visible = false
			_btn_cancel.disabled = true
	else:
		_btn_claim.text = "調査中..."
		_btn_claim.disabled = true
		if _btn_cancel != null:
			_btn_cancel.visible = true
			_btn_cancel.disabled = false
			_btn_cancel.text = "調査を中止"


func _format_hms(sec: float) -> String:
	var s: int = maxi(0, int(ceil(sec)))
	var h: int = s / 3600
	var m: int = (s % 3600) / 60
	var r: int = s % 60
	return "%02d:%02d:%02d" % [h, m, r]


func _pending_as_entries() -> Array:
	var out: Array = []
	var i: int = 0
	for mid in _pending_members:
		var role: String = _SurveySystem.role_for_assignee(mid, i)
		out.append({"member_id": mid, "role_id": role})
		i += 1
	return out


func _rebuild_assignees() -> void:
	for c in _assignee_box.get_children():
		c.queue_free()
	var show_ids: Array[String] = _pending_members.duplicate()
	if _SurveySystem.has_active_cycle():
		show_ids = []
		for entry in GameState.hub_survey_cycle.get("assignees", []):
			if entry is Dictionary:
				show_ids.append(str(entry.get("member_id", "")))
			elif entry is String:
				show_ids.append(str(entry))
	var cycle_active: bool = _SurveySystem.has_active_cycle()
	_btn_auto.disabled = cycle_active
	for i in range(_SurveyConfig.INVESTIGATOR_UI_SLOTS):
		var mid: String = ""
		if i < show_ids.size():
			mid = show_ids[i]
		_assignee_box.add_child(_build_assignee_card(i, mid, false, cycle_active))


func _build_assignee_card(slot: int, member_id: String, locked: bool, cycle_active: bool) -> PanelContainer:
	var card := _card_panel()
	card.clip_contents = true
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## HBox 内で他カード高さに揃える（ロック枠が短い問題の防止）。
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 0)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon_host := Control.new()
	icon_host.custom_minimum_size = Vector2(ASSIGNEE_ICON_PX, ASSIGNEE_ICON_PX)
	icon_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.add_child(icon_host)

	var icon := TextureRect.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	icon_host.add_child(icon)

	var name_l := Label.new()
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.clip_text = true
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.custom_minimum_size.x = 0.0
	UiTypography.apply_body(name_l, UiTypography.SIZE_CAPTION)
	vb.add_child(name_l)

	var stars_l := Label.new()
	stars_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(stars_l, UiTypography.COLOR_GOLD)
	vb.add_child(stars_l)

	var speed_l := Label.new()
	speed_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiTypography.apply_caption(speed_l)
	vb.add_child(speed_l)

	if locked:
		var lock_path: String = "res://assets/ui/equipment_ui/UI_Equip_Slot_Locked.png"
		if ResourceLoader.exists(lock_path):
			icon.texture = load(lock_path) as Texture2D
			icon.modulate = Color(0.85, 0.78, 0.55, 1.0)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		else:
			icon.visible = false
			var lock_l := Label.new()
			lock_l.text = "🔒"
			lock_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lock_l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			UiTypography.apply_body(lock_l, int(ASSIGNEE_ICON_PX * 0.72), UiTypography.COLOR_GOLD)
			icon_host.add_child(lock_l)
		name_l.text = "ロック"
		stars_l.text = "—"
		speed_l.text = "—"
		speed_l.visible = false
		## 「変更」ボタン分の高さを確保して他カードと揃える。
		var lock_pad := Control.new()
		lock_pad.custom_minimum_size = Vector2(0, 36.0)
		lock_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lock_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(lock_pad)
		card.add_child(vb)
		return card

	var adv: Resource = null
	if not member_id.is_empty():
		adv = GameState.find_roster_member_by_id(member_id)
	if member_id.is_empty():
		name_l.text = "空き"
		stars_l.text = "—"
		speed_l.text = "速度 —"
	elif _SurveySystem.is_survey_staff(member_id):
		var tex: Texture2D = _SurveySystem.investigator_portrait_texture(member_id)
		if tex != null:
			icon.texture = tex
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		name_l.text = _SurveySystem.investigator_display_name(member_id)
		stars_l.text = "調査室"
		var role: String = _SurveySystem.role_for_assignee(member_id, slot)
		var bonus: float = _SurveySystem.investigator_speed_bonus(member_id, role)
		speed_l.text = "+%.0f%%" % (bonus * 100.0)
	elif adv == null:
		name_l.text = "空き"
		stars_l.text = "—"
		speed_l.text = "速度 —"
	else:
		var tex: Texture2D = _RosterUiHelper.get_member_portrait_texture(adv)
		if tex != null:
			icon.texture = tex
		name_l.text = str(adv.display_name)
		var rarity: int = int(adv.rarity) if "rarity" in adv else 1
		stars_l.text = _RosterUiHelper.stars_text(rarity)
		var role: String = _SurveySystem.role_for_assignee(member_id, slot)
		var bonus: float = _SurveySystem.investigator_speed_bonus(member_id, role)
		speed_l.text = "+%.0f%%" % (bonus * 100.0)

	var btn := Button.new()
	btn.text = "変更"
	btn.disabled = cycle_active
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.custom_minimum_size = Vector2(0, 36.0)
	var slot_i: int = slot
	btn.pressed.connect(func(): _open_member_pick_list(slot_i))
	vb.add_child(btn)
	card.add_child(vb)
	return card


func _open_member_pick_list(slot: int) -> void:
	if _SurveySystem.has_active_cycle():
		return
	var roster_ids: Array[String] = _SurveySystem.investigator_candidate_ids()
	if roster_ids.is_empty():
		return
	while _pending_members.size() <= slot:
		_pending_members.append("")
	var cur: String = _pending_members[slot]
	var used_elsewhere: Dictionary = {}
	for j in range(_pending_members.size()):
		if j == slot:
			continue
		var mid: String = str(_pending_members[j])
		if not mid.is_empty():
			used_elsewhere[mid] = true
	var rows: Array[Dictionary] = []
	for cand in roster_ids:
		var used: bool = used_elsewhere.has(cand)
		var title: String = _SurveySystem.investigator_display_name(cand)
		var role: String = _SurveySystem.role_for_assignee(cand, slot)
		var bonus: float = _SurveySystem.investigator_speed_bonus(cand, role)
		var subtitle: String = "+%.0f%%" % (bonus * 100.0)
		var selected: bool = cand == cur and not cur.is_empty()
		var disabled: bool = used
		if _SurveySystem.is_survey_staff(cand):
			subtitle = "調査室  " + subtitle
		elif used:
			subtitle = "他スロット配置中"
		elif selected:
			subtitle = "タップで外す"
		elif not _SurveySystem.can_place_without_emptying_party(_pending_members, slot, cand):
			disabled = true
			subtitle = "編成用に残す"
		rows.append({
			"id": cand,
			"title": title,
			"subtitle": subtitle,
			"texture": _SurveySystem.investigator_portrait_texture(cand),
			"selected": selected,
			"disabled": disabled,
		})
	_open_pick_list("調査員を選択", rows, func(picked_id: String) -> void:
		if picked_id.is_empty():
			return
		if used_elsewhere.has(picked_id):
			return
		## 選択中の同じキャラを再タップ → 枠から外す。
		if picked_id == cur and not cur.is_empty():
			_pending_members[slot] = ""
			_SurveySystem.remember_last_member_ids(_pending_members)
			_refresh()
			return
		if not _SurveySystem.can_place_without_emptying_party(_pending_members, slot, picked_id):
			return
		_pending_members[slot] = picked_id
		_SurveySystem.remember_last_member_ids(_pending_members)
		_refresh()
	)


func _on_auto_assign() -> void:
	if _SurveySystem.has_active_cycle():
		return
	_pending_members = _SurveySystem.auto_assign_members()
	_SurveySystem.remember_last_member_ids(_pending_members)
	_refresh()


## 報酬一覧（アイコン＋確率）。
func _on_reward_catalog_pressed() -> void:
	_open_reward_catalog()


func _open_reward_catalog() -> void:
	_close_pick_list()
	var overlay := Control.new()
	overlay.name = "SurveyRewardCatalogOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_as_relative = false
	overlay.z_index = 80
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.06, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_close_pick_list()
	)
	overlay.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 120)
	margin.add_theme_constant_override("margin_bottom", 140)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(margin)

	var panel := _card_panel()
	panel.clip_contents = true
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_child(panel)

	var root_vb := VBoxContainer.new()
	root_vb.add_theme_constant_override("separation", 12)
	root_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(root_vb)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var title_l := Label.new()
	title_l.text = "報酬一覧"
	title_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_display(title_l, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	head.add_child(title_l)
	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.pressed.connect(_close_pick_list)
	head.add_child(close_btn)
	root_vb.add_child(head)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.clip_contents = true
	root_vb.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size.x = 0.0
	scroll.add_child(list)

	for row in _reward_catalog_rows():
		if bool(row.get("is_section", false)):
			list.add_child(_make_reward_catalog_section(str(row.get("title", ""))))
		else:
			list.add_child(_make_reward_catalog_row(row))

	add_child(overlay)
	move_child(overlay, get_child_count() - 1)
	_pick_overlay = overlay
	ScrollTouchHelper.enable(scroll)


func _make_reward_catalog_section(title: String) -> Label:
	var l := Label.new()
	l.text = title
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 0.0
	l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	UiTypography.apply_display(l, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	return l


func _make_reward_catalog_row(row: Dictionary) -> Control:
	var wrap := PanelContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.custom_minimum_size.x = 0.0
	wrap.clip_contents = true
	wrap.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.custom_minimum_size.x = 0.0
	wrap.add_child(h)
	var icon_host := Control.new()
	icon_host.custom_minimum_size = Vector2(48, 48)
	icon_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(icon_host)
	var tex: Texture2D = row.get("texture", null) as Texture2D
	if tex != null:
		var icon := TextureRect.new()
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon.texture = tex
		icon_host.add_child(icon)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.custom_minimum_size.x = 0.0
	texts.add_theme_constant_override("separation", 2)
	var name_l := Label.new()
	name_l.text = str(row.get("title", ""))
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.custom_minimum_size.x = 0.0
	name_l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	UiTypography.apply_body(name_l, UiTypography.SIZE_BODY_SMALL)
	texts.add_child(name_l)
	var chance_l := Label.new()
	chance_l.text = str(row.get("chance", ""))
	chance_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chance_l.custom_minimum_size.x = 0.0
	chance_l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	UiTypography.apply_caption(chance_l, UiTypography.COLOR_GOLD)
	texts.add_child(chance_l)
	h.add_child(texts)
	return wrap


func _reward_catalog_rows() -> Array[Dictionary]:
	const _SurveyCompleteRewards := preload("res://scripts/survey/SurveyCompleteRewards.gd")
	var out: Array[Dictionary] = []
	out.append({"is_section": true, "title": "毎回の調査サイクル"})
	var token_pct: int = int(round(_SurveyConfig.TOKEN_GRANT_CHANCE * 100.0))
	out.append({
		"texture": _CurrencyHelper.get_icon_texture(),
		"title": "魔晶石",
		"chance": "%d%%（簡易 %d〜%d／本格 %d〜%d）" % [
			token_pct,
			_SurveyConfig.TOKEN_SHORT_MIN,
			_SurveyConfig.TOKEN_SHORT_MAX,
			_SurveyConfig.TOKEN_STANDARD_MIN,
			_SurveyConfig.TOKEN_STANDARD_MAX,
		],
	})
	out.append({
		"texture": _gold_icon_texture(),
		"title": "ゴールド",
		"chance": "魔晶石と同タイミング（×5）",
	})
	out.append({
		"texture": IconPaths.get_icon_texture("base_ore", "material"),
		"title": "鍛冶素材（派遣先帯）",
		"chance": "確定（簡易 2〜4／本格 5〜9）。帯で基礎鉱／遺跡結晶／蒼古／深層／王墓を重み抽選",
	})
	var p1: int = int(round(_SurveyConfig.WEAPON_P_STAR1 * 100.0))
	var p2: int = int(round(_SurveyConfig.WEAPON_P_STAR2 * 100.0))
	var p3: float = _SurveyConfig.WEAPON_P_STAR3 * 100.0
	out.append({
		"texture": IconPaths.get_icon_texture("iron_sword", "weapon"),
		"title": "装備（武器・派遣先プール）",
		"chance": "N %d%%／R %d%%／E %.1f%%（いずれか、または無し）。対象DGの武器プールから" % [p1, p2, p3],
	})
	var did: String = _selected_dungeon_id()
	var dg: Resource = DataRegistry.get_dungeon_data(did)
	var dg_name: String = str(dg.display_name) if dg != null else did
	out.append({"is_section": true, "title": "完全調査（100%%）— %s" % dg_name})
	var entries: Array[Dictionary] = _SurveyCompleteRewards.preview_entries(did)
	if entries.is_empty():
		out.append({
			"texture": null,
			"title": "（このダンジョンの景品定義なし）",
			"chance": "—",
		})
	else:
		for entry in entries:
			out.append({
				"texture": _texture_for_complete_entry(entry),
				"title": _SurveyCompleteRewards.preview_display_name(entry),
				"chance": _SurveyCompleteRewards.preview_chance_label(entry),
			})
	return out


func _texture_for_complete_entry(entry: Dictionary) -> Texture2D:
	var kind: String = str(entry.get("kind", ""))
	match kind:
		"gold":
			return _gold_icon_texture()
		"token":
			return _CurrencyHelper.get_icon_texture()
		"material":
			return IconPaths.get_icon_texture(str(entry.get("id", "")), "material")
		"ticket":
			return IconPaths.get_icon_texture(str(entry.get("id", "")), "ticket")
		"pet":
			var pet_id: String = str(entry.get("id", ""))
			var idle: Texture2D = ChrIdlePortrait.get_idle_texture(pet_id)
			if idle != null:
				return idle
			return IconPaths.get_icon_texture(pet_id, "chr")
		_:
			return null


## 一覧選択オーバーレイ（ダンジョン／調査員共通）。
func _open_pick_list(title: String, rows: Array[Dictionary], on_pick: Callable) -> void:
	_close_pick_list()
	var overlay := Control.new()
	overlay.name = "SurveyPickOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_as_relative = false
	overlay.z_index = 80
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.06, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_close_pick_list()
	)
	overlay.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 120)
	margin.add_theme_constant_override("margin_bottom", 140)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(margin)

	var panel := _card_panel()
	panel.clip_contents = true
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_child(panel)

	var root_vb := VBoxContainer.new()
	root_vb.add_theme_constant_override("separation", 12)
	root_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(root_vb)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var title_l := Label.new()
	title_l.text = title
	title_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_display(title_l, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	head.add_child(title_l)
	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.pressed.connect(_close_pick_list)
	head.add_child(close_btn)
	root_vb.add_child(head)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.clip_contents = true
	root_vb.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size.x = 0.0
	scroll.add_child(list)

	for row in rows:
		list.add_child(_build_pick_row(row, on_pick))

	add_child(overlay)
	move_child(overlay, get_child_count() - 1)
	_pick_overlay = overlay
	ScrollTouchHelper.enable(scroll)


func _build_pick_row(row: Dictionary, on_pick: Callable) -> Button:
	var btn := Button.new()
	btn.disabled = bool(row.get("disabled", false))
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 72)
	btn.clip_contents = true
	btn.clip_text = true
	btn.text = ""
	var selected: bool = bool(row.get("selected", false))
	var content := HBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10.0
	content.offset_top = 8.0
	content.offset_right = -10.0
	content.offset_bottom = -8.0
	content.add_theme_constant_override("separation", 10)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(content)
	var tex: Variant = row.get("texture", null)
	if tex is Texture2D:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		icon.texture = tex as Texture2D
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.custom_minimum_size.x = 0.0
	texts.add_theme_constant_override("separation", 2)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(texts)
	var title: String = str(row.get("title", ""))
	var mark: String = " 〔選択中〕" if selected else ""
	var title_l := Label.new()
	title_l.text = "%s%s" % [title, mark]
	title_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_l.custom_minimum_size.x = 0.0
	title_l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	title_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if selected:
		UiTypography.apply_display(title_l, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	else:
		UiTypography.apply_body(title_l, UiTypography.SIZE_BODY_SMALL)
	texts.add_child(title_l)
	var subtitle: String = str(row.get("subtitle", ""))
	if not subtitle.is_empty():
		var sub_l := Label.new()
		sub_l.text = subtitle
		sub_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sub_l.custom_minimum_size.x = 0.0
		sub_l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		sub_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_caption(sub_l, UiTypography.COLOR_SUB if not selected else UiTypography.COLOR_GOLD)
		texts.add_child(sub_l)
	var picked_id: String = str(row.get("id", ""))
	btn.pressed.connect(func() -> void:
		_close_pick_list()
		if on_pick.is_valid():
			on_pick.call(picked_id)
	)
	return btn


func _close_pick_list() -> void:
	if _pick_overlay != null and is_instance_valid(_pick_overlay):
		_pick_overlay.queue_free()
	_pick_overlay = null


func _setup_start_confirm() -> void:
	_start_confirm = ConfirmationDialog.new()
	## タイトルバーは実機で見出しが上端見切れしやすい → 本文先頭に見出しを置く。
	_start_confirm.title = ""
	_start_confirm.ok_button_text = "開始する"
	_start_confirm.cancel_button_text = "やめる"
	_start_confirm.confirmed.connect(_execute_start)
	_start_confirm.canceled.connect(_on_start_confirm_canceled)
	_style_survey_confirm(_start_confirm)
	add_child(_start_confirm)


func _setup_cancel_confirm() -> void:
	_cancel_confirm = ConfirmationDialog.new()
	_cancel_confirm.title = ""
	_cancel_confirm.ok_button_text = "中止する"
	_cancel_confirm.cancel_button_text = "続ける"
	_cancel_confirm.dialog_text = (
		"調査中止\n\n進行中の調査を中止しますか？\n\n報酬は得られません。\n配置した隊員は調査から戻ります。"
	)
	_cancel_confirm.confirmed.connect(_execute_cancel)
	_style_survey_confirm(_cancel_confirm)
	add_child(_cancel_confirm)


func _style_survey_confirm(dlg: ConfirmationDialog) -> void:
	if dlg == null:
		return
	dlg.unresizable = true
	dlg.dialog_autowrap = true
	dlg.min_size = Vector2i(440, 280)
	## タイトルバー高を確保（空タイトルでも余白が潰れる端末向け）。
	dlg.add_theme_constant_override("title_height", 36)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.10, 0.10, 0.12, 0.97)
	panel.set_border_width_all(2)
	panel.border_color = Color(0.78, 0.68, 0.38, 0.9)
	panel.set_corner_radius_all(8)
	panel.content_margin_left = 22.0
	panel.content_margin_right = 22.0
	panel.content_margin_top = 22.0
	panel.content_margin_bottom = 14.0
	dlg.add_theme_stylebox_override("panel", panel)
	var font: Font = UiTypography.body_font()
	if font != null:
		dlg.add_theme_font_override("font", font)
	dlg.add_theme_font_size_override("font_size", UiTypography.SIZE_BODY_SMALL)
	var msg: Label = dlg.get_label()
	if msg != null:
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		msg.add_theme_constant_override("line_spacing", 4)
		UiTypography.apply_body(msg, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)


func _on_cancel_pressed() -> void:
	if _claim_fx_busy:
		return
	if not _SurveySystem.has_active_cycle() or _SurveySystem.is_cycle_complete():
		_label_status.text = "中止不可: 進行中の調査がありません"
		_refresh_progress_only()
		return
	_cancel_confirm.popup_centered(Vector2i(460, 300))


func _execute_cancel() -> void:
	if _claim_fx_busy:
		return
	var result: Dictionary = _SurveySystem.cancel_cycle()
	if not bool(result.get("ok", false)):
		_label_status.text = "中止不可: %s" % str(result.get("reason", ""))
		_refresh()
		return
	AudioManager.play_sfx("ui_cancel")
	_label_status.text = "調査を中止しました"
	_pending_members = _SurveySystem.pending_members_for_ui()
	_refresh()


func _on_start(preset: String) -> void:
	if _SurveySystem.has_active_cycle():
		_label_status.text = "開始不可: 調査中の案件があります"
		return
	_pending_start_preset = preset
	var did: String = _selected_dungeon_id()
	var data: Resource = DataRegistry.get_dungeon_data(did)
	var dg_name: String = str(data.display_name) if data != null else did
	var kind: String = (
		_SurveyConfig.display_name_with_duration(preset)
	)
	_start_confirm.dialog_text = (
		"調査開始\n\n調査を開始しますか？\n\n対象: %s\n種別: %s\n※配置した隊員は編成から外れます（完了後に自動で戻ります）"
		% [dg_name, kind]
	)
	_start_confirm.popup_centered(Vector2i(460, 320))


func _on_start_confirm_canceled() -> void:
	_pending_start_preset = ""


func _execute_start() -> void:
	var preset: String = _pending_start_preset
	_pending_start_preset = ""
	if preset.is_empty():
		return
	var result: Dictionary = _SurveySystem.start_cycle(
		_selected_dungeon_id(), preset, _pending_members
	)
	if not bool(result.get("ok", false)):
		_label_status.text = "開始不可: %s" % str(result.get("reason", ""))
		return
	_label_status.text = ""
	SaveManager.save_game()
	_refresh()


func _on_claim() -> void:
	_perform_claim()


## 入室時点でサイクル完了済みなら、ボタンを押さずに受取＋懐へ飛ぶ演出。
func _try_auto_claim_on_enter() -> void:
	## レイアウト確定後に起点／着地の global_rect を取る。
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if _claim_fx_busy:
		return
	if not _SurveySystem.has_active_cycle() or not _SurveySystem.is_cycle_complete():
		_maybe_show_content_unlock()
		_try_show_room_guide()
		return
	_perform_claim()


func _perform_claim() -> void:
	if _claim_fx_busy:
		return
	var from_global: Vector2 = _claim_fx_origin_global()
	var result: Dictionary = _SurveySystem.claim_cycle()
	if not bool(result.get("ok", false)):
		_label_status.text = "受取不可: %s" % str(result.get("reason", ""))
		return
	_claim_fx_busy = true
	if _btn_claim != null:
		_btn_claim.disabled = true
		_btn_claim.text = "受取中..."
	if _btn_cancel != null:
		_btn_cancel.visible = false
		_btn_cancel.disabled = true
	_label_status.text = "調査完了…"
	_play_claim_fx(from_global, result)


func _claim_fx_origin_global() -> Vector2:
	if _progress_bar != null and is_instance_valid(_progress_bar):
		return _progress_bar.get_global_rect().get_center()
	if _btn_claim != null and is_instance_valid(_btn_claim):
		return _btn_claim.get_global_rect().get_center()
	return get_global_rect().get_center()


func _play_claim_fx(_from_global: Vector2, result: Dictionary) -> void:
	## 分解完了と同型の結果ポップ（枠＋調査完了ロゴ＋獲得一覧）。
	_update_currency()
	if _claim_result_overlay != null and is_instance_valid(_claim_result_overlay):
		_claim_result_overlay.queue_free()
		_claim_result_overlay = null
	var overlay := SurveyClaimResultOverlay.new()
	_claim_result_overlay = overlay
	add_child(overlay)
	overlay.dismissed.connect(_on_claim_result_dismissed.bind(result))
	overlay.present(result)


func _on_claim_result_dismissed(result: Dictionary) -> void:
	_claim_result_overlay = null
	_finish_claim(result)


func _finish_claim(result: Dictionary) -> void:
	_claim_fx_busy = false
	_update_currency()
	var parts: PackedStringArray = []
	parts.append("Gold +%d" % int(result.get("gold", 0)))
	parts.append("素材 ×%d" % int(result.get("material_qty", 0)))
	parts.append("%s +%d" % [_CurrencyHelper.DISPLAY_NAME, int(result.get("token", 0))])
	if not str(result.get("weapon_id", "")).is_empty():
		parts.append("装備入手")
	_label_status.text = "受取完了: %s" % " ・ ".join(parts)
	_pending_members = _SurveySystem.pending_members_for_ui()
	_refresh()
	call_deferred("_maybe_show_content_unlock")
	call_deferred("_try_show_room_guide")


func _update_currency() -> void:
	if _label_gold != null:
		_label_gold.text = "%d" % GameState.gold
	if _label_token != null:
		_label_token.text = _CurrencyHelper.format_amount()


func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
