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
var _btn_start_short: Button
var _btn_start_std: Button
var _btn_auto: Button
var _btn_change_dungeon: Button
var _pending_members: Array[String] = []
var _target_dungeon_id: String = Constants.MOURNGATE_DUNGEON_ID
var _tick: float = 0.0
var _claim_fx_busy: bool = false


func _ready() -> void:
	_label_title.text = ""
	_label_title.visible = false
	AudioManager.play_bgm("survey")
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	_hide_legacy_event_nodes()
	_ensure_background()
	_build_ui()
	_pending_members = _SurveySystem.auto_assign_members()
	_update_currency()
	_refresh()
<<<<<<< HEAD
	call_deferred("_try_auto_claim_on_enter")
=======
	call_deferred("_maybe_show_content_unlock")


func _maybe_show_content_unlock() -> void:
	const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")
	_ContentUnlockNotice.show_pending_on(self)
>>>>>>> origin/cursor/dungeon-unlock-popup-b062


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
	_content.add_child(_build_hero_lead())
	_content.add_child(_build_target_card())

	_content.add_child(_build_assignee_section())
	_assignee_box = HBoxContainer.new()
	_assignee_box.add_theme_constant_override("separation", 8)
	_assignee_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_assignee_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_child(_assignee_box)

	_content.add_child(_build_cycle_progress_card())
	_content.add_child(_build_expected_rewards_card())

	var start_row := HBoxContainer.new()
	start_row.add_theme_constant_override("separation", 8)
	_btn_start_short = Button.new()
	_btn_start_short.text = "短調査（20分）"
	_btn_start_short.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_start_short.pressed.connect(func(): _on_start(_SurveyConfig.PRESET_SHORT))
	start_row.add_child(_btn_start_short)
	_btn_start_std = Button.new()
	_btn_start_std.text = "標準調査（3時間）"
	_btn_start_std.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_start_std.pressed.connect(func(): _on_start(_SurveyConfig.PRESET_STANDARD))
	start_row.add_child(_btn_start_std)
	_content.add_child(start_row)

	_btn_claim = Button.new()
	_btn_claim.text = "調査中..."
	_btn_claim.pressed.connect(_on_claim)
	_content.add_child(_btn_claim)


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
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lead.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	var title := Label.new()
	title.text = "調査員の配置"
	UiTypography.apply_display(title, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_label_bonus = Label.new()
	_label_bonus.text = "合計ボーナス +0%"
	_label_bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_caption(_label_bonus, UiTypography.COLOR_GOLD)
	header.add_child(_label_bonus)
	_btn_auto = Button.new()
	_btn_auto.text = "おまかせ配置"
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
	var title := Label.new()
	title.text = "調査完了時の期待成果"
	UiTypography.apply_display(title, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	vb.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	## 装備 → 魔晶石 → ゴールド → 素材
	var weapon_pct: int = int(round(_SurveyConfig.weapon_drop_chance() * 100.0))
	row.add_child(_make_reward_chance_cell(
		IconPaths.get_icon_texture("iron_sword", "weapon"),
		"装備",
		weapon_pct
	))
	row.add_child(_make_reward_chance_cell(
		_CurrencyHelper.get_icon_texture(),
		"魔晶石",
		100
	))
	const GOLD_COIN_PATH: String = "res://assets/ui/batch2/ICO_Gold.png"
	var gold_tex: Texture2D = null
	if ResourceLoader.exists(GOLD_COIN_PATH):
		gold_tex = load(GOLD_COIN_PATH) as Texture2D
	row.add_child(_make_reward_chance_cell(gold_tex, "ゴールド", 100))
	row.add_child(_make_reward_chance_cell(
		IconPaths.get_icon_texture("base_ore", "material"),
		"素材",
		100
	))
	vb.add_child(row)
	card.add_child(vb)
	return card


func _make_reward_chance_cell(tex: Texture2D, label_text: String, chance_pct: int) -> Control:
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
	var pct_l := Label.new()
	pct_l.text = "%d%%" % chance_pct
	pct_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(pct_l, UiTypography.COLOR_GOLD)
	cell.add_child(pct_l)
	return cell


func _build_target_card() -> PanelContainer:
	var target_panel := _card_panel()
	target_panel.clip_contents = true
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

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
	mid.add_theme_constant_override("separation", 4)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_target_name = Label.new()
	_label_target_name.text = "—"
	_label_target_name.clip_text = false
	_label_target_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label_target_name.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_label_target_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	_label_target_desc.autowrap_mode = TextServer.AUTOWRAP_OFF
	mid.add_child(_label_target_desc)
	var drops := HBoxContainer.new()
	drops.add_theme_constant_override("separation", 6)
	drops.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for tex: Texture2D in _target_reward_textures():
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(REWARD_ICON_PX, REWARD_ICON_PX)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = tex
		drops.add_child(icon)
	mid.add_child(drops)
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


func _target_reward_textures() -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	## 拠点 TopBar と同じコイン（batch2/ICO_Gold）。
	const GOLD_COIN_PATH: String = "res://assets/ui/batch2/ICO_Gold.png"
	if ResourceLoader.exists(GOLD_COIN_PATH):
		var gold: Texture2D = load(GOLD_COIN_PATH) as Texture2D
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
	var idx: int = ids.find(_target_dungeon_id)
	_target_dungeon_id = ids[(idx + 1) % ids.size()]
	_refresh()


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
	var bonus: float = _SurveySystem.total_speed_bonus(_pending_as_entries())
	_label_bonus.text = "合計ボーナス +%.0f%%" % (bonus * 100.0)
	var unlocked_n: int = _unlocked_main_dungeon_ids().size()
	_btn_change_dungeon.disabled = _SurveySystem.has_active_cycle() or unlocked_n <= 1


func _refresh_progress_only() -> void:
	if _claim_fx_busy:
		return
	var active: bool = _SurveySystem.has_active_cycle()
	var complete: bool = _SurveySystem.is_cycle_complete()
	var p01: float = _SurveySystem.cycle_progress_01()
	_progress_bar.value = p01 * 100.0
	if not active:
		_progress_bar.value = 0.0
		_label_timer.text = "調査完了まで: —（未開始）"
		_btn_claim.text = "調査を開始してください"
		_btn_claim.disabled = true
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
	else:
		_btn_claim.text = "調査中..."
		_btn_claim.disabled = true


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
		var role: String = _SurveyConfig.ROLE_IDS[mini(i, _SurveyConfig.ROLE_IDS.size() - 1)]
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
		var locked: bool = i >= _SurveyConfig.INVESTIGATOR_SLOTS
		var mid: String = ""
		if not locked and i < show_ids.size():
			mid = show_ids[i]
		_assignee_box.add_child(_build_assignee_card(i, mid, locked, cycle_active))


func _build_assignee_card(slot: int, member_id: String, locked: bool, cycle_active: bool) -> PanelContainer:
	var card := _card_panel()
	card.clip_contents = true
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.custom_minimum_size = Vector2(0, 0)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	name_l.clip_text = false
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_l.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
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
		speed_l.text = "Lv.15"
		card.add_child(vb)
		return card

	var adv: Resource = null
	if not member_id.is_empty():
		adv = GameState.find_roster_member_by_id(member_id)
	if adv == null:
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
		var role: String = _SurveyConfig.ROLE_IDS[mini(slot, _SurveyConfig.ROLE_IDS.size() - 1)]
		var bonus: float = _SurveySystem.investigator_speed_bonus(member_id, role)
		speed_l.text = "+%.0f%%" % (bonus * 100.0)

	var btn := Button.new()
	btn.text = "変更"
	btn.disabled = cycle_active
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var slot_i: int = slot
	btn.pressed.connect(func(): _cycle_member_at(slot_i))
	vb.add_child(btn)
	card.add_child(vb)
	return card


func _cycle_member_at(slot: int) -> void:
	var roster_ids: Array[String] = []
	for adv in GameState.roster:
		if adv != null and not str(adv.id).is_empty():
			roster_ids.append(str(adv.id))
	if roster_ids.is_empty():
		return
	while _pending_members.size() <= slot:
		_pending_members.append("")
	var cur: String = _pending_members[slot]
	var idx: int = roster_ids.find(cur)
	var next_i: int = (idx + 1) % roster_ids.size()
	## 重複回避
	for _k in range(roster_ids.size()):
		var cand: String = roster_ids[next_i]
		var used: bool = false
		for j in range(_pending_members.size()):
			if j != slot and _pending_members[j] == cand:
				used = true
				break
		if not used:
			_pending_members[slot] = cand
			break
		next_i = (next_i + 1) % roster_ids.size()
	_refresh()


func _on_auto_assign() -> void:
	if _SurveySystem.has_active_cycle():
		return
	_pending_members = _SurveySystem.auto_assign_members()
	_refresh()


func _on_start(preset: String) -> void:
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
	_label_status.text = "成果を懐へ…"
	_play_claim_fx(from_global, result)


func _claim_fx_origin_global() -> Vector2:
	if _progress_bar != null and is_instance_valid(_progress_bar):
		return _progress_bar.get_global_rect().get_center()
	if _btn_claim != null and is_instance_valid(_btn_claim):
		return _btn_claim.get_global_rect().get_center()
	return get_global_rect().get_center()


func _play_claim_fx(from_global: Vector2, result: Dictionary) -> void:
	var rewards: Array = []
	var gold: int = int(result.get("gold", 0))
	if gold > 0:
		var gold_tex: Texture2D = null
		if ResourceLoader.exists(GOLD_ICON_PATH):
			gold_tex = load(GOLD_ICON_PATH) as Texture2D
		if gold_tex != null and _gold_chip != null:
			rewards.append({"texture": gold_tex, "target": _gold_chip, "amount": gold})
	var tokens: int = int(result.get("token", 0))
	if tokens > 0:
		var token_tex: Texture2D = _CurrencyHelper.get_icon_texture()
		if token_tex != null and _token_chip != null:
			rewards.append({"texture": token_tex, "target": _token_chip, "amount": tokens})
	var mat_id: String = str(result.get("material_id", ""))
	var mat_qty: int = int(result.get("material_qty", 0))
	var pocket: Control = _pocket_nav_target()
	if not mat_id.is_empty() and mat_qty > 0:
		var mat_tex: Texture2D = IconPaths.get_icon_texture(mat_id, "material")
		var mat_target: Control = pocket if pocket != null else _gold_chip
		if mat_tex != null and mat_target != null:
			rewards.append({"texture": mat_tex, "target": mat_target, "amount": mat_qty})
	var weapon_id: String = str(result.get("weapon_id", ""))
	if not weapon_id.is_empty():
		var wpn_tex: Texture2D = IconPaths.get_icon_texture(weapon_id, "weapon")
		var equip_nav: Control = get_node_or_null("BottomNav/NavRow/NavEquipmentCatalog") as Control
		var wpn_target: Control = equip_nav if equip_nav != null else pocket
		if wpn_target == null:
			wpn_target = _gold_chip
		if wpn_tex != null and wpn_target != null:
			rewards.append({"texture": wpn_tex, "target": wpn_target, "amount": 1})
	if rewards.is_empty():
		_finish_claim(result)
		return
	CurrencyGainFx.play(self, from_global, rewards, func() -> void: _finish_claim(result))


func _pocket_nav_target() -> Control:
	## 素材はキャラ（所持）側のナビへ「懐」として飛ばす。
	var nav: Control = get_node_or_null("BottomNav/NavRow/NavCharacter") as Control
	if nav != null:
		return nav
	return get_node_or_null("BottomNav/NavRow/NavForge") as Control


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
	_pending_members = _SurveySystem.auto_assign_members()
	_refresh()
	call_deferred("_maybe_show_content_unlock")


func _update_currency() -> void:
	if _label_gold != null:
		_label_gold.text = "%d" % GameState.gold
	if _label_token != null:
		_label_token.text = _CurrencyHelper.format_amount()


func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
