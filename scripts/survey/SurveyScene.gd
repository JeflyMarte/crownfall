extends Control

## 調査室（P3-HUB-SURVEY-001）。モック構成準拠・通常 BottomNav。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const BG_PATH: String = "res://assets/ui/UI_BG_Survey.png"
const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")
const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
const _CurrencyHelper := preload("res://scripts/ui/CurrencyHelper.gd")

@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _content: VBoxContainer = $MainScroll/MainVBox/ContentHost

var _label_lead: Label
var _label_target: Label
var _label_survey_pct: Label
var _progress_bar: ProgressBar
var _label_timer: Label
var _label_materials: Label
var _label_discovery: Label
var _label_bonus: Label
var _assignee_box: VBoxContainer
var _btn_claim: Button
var _btn_start_short: Button
var _btn_start_std: Button
var _btn_auto: Button
var _option_dungeon: OptionButton
var _pending_members: Array[String] = []
var _tick: float = 0.0


func _ready() -> void:
	UiTypography.apply_screen_title(_label_title)
	_label_title.text = "✦ 調査室 ✦"
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	_hide_legacy_event_nodes()
	_ensure_background()
	_build_ui()
	_pending_members = _SurveySystem.auto_assign_members()
	_refresh()


func _process(delta: float) -> void:
	_tick += delta
	if _tick < 0.5:
		return
	_tick = 0.0
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
	_label_lead = _make_body(
		"ダンジョンで入手した資料を調査し、失われた歴史や遺物の手がかりを解明します。"
	)
	_content.add_child(_label_lead)

	_content.add_child(_section_title("調査対象", "同時調査枠 1/1"))
	var target_panel := _card_panel()
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 6)
	_option_dungeon = OptionButton.new()
	_option_dungeon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fill_dungeon_options()
	tv.add_child(_option_dungeon)
	_label_target = _make_body("—")
	tv.add_child(_label_target)
	_label_survey_pct = _make_caption("調査進捗: 0%")
	tv.add_child(_label_survey_pct)
	target_panel.add_child(tv)
	_content.add_child(target_panel)

	_content.add_child(_section_title("調査員の配置", "合計ボーナス —"))
	_label_bonus = _make_caption("配置すると調査速度が上がります。")
	_content.add_child(_label_bonus)
	_btn_auto = Button.new()
	_btn_auto.text = "おまかせ配置"
	_btn_auto.pressed.connect(_on_auto_assign)
	_content.add_child(_btn_auto)
	_assignee_box = VBoxContainer.new()
	_assignee_box.add_theme_constant_override("separation", 6)
	_content.add_child(_assignee_box)

	_content.add_child(_section_title("調査の進行状況", ""))
	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.custom_minimum_size = Vector2(0, 22)
	_progress_bar.show_percentage = false
	_content.add_child(_progress_bar)
	_label_timer = _make_caption("調査完了まで: —")
	_content.add_child(_label_timer)
	_label_materials = _make_body("調査資料: —")
	_content.add_child(_label_materials)
	_label_discovery = _make_caption("発見: —")
	_content.add_child(_label_discovery)

	_content.add_child(_section_title("調査完了時の期待成果", ""))
	var reward_row := HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 8)
	for label_text: String in ["武器（低確率）", "魔晶石（高確率）", "資料素材", "手がかり（確定）"]:
		var chip := Label.new()
		chip.text = label_text
		UiTypography.apply_caption(chip)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_row.add_child(chip)
	_content.add_child(reward_row)

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


func _make_body(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(l)
	return l


func _make_caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(l)
	return l


func _fill_dungeon_options() -> void:
	_option_dungeon.clear()
	## Phase1: ①のみ調査対象として開始可能
	var data: Resource = DataRegistry.get_dungeon_data(Constants.MOURNGATE_DUNGEON_ID)
	var name_str: String = "モーンゲート" if data == null else str(data.display_name)
	_option_dungeon.add_item(name_str, 0)
	_option_dungeon.set_item_metadata(0, Constants.MOURNGATE_DUNGEON_ID)
	_option_dungeon.select(0)


func _selected_dungeon_id() -> String:
	var idx: int = _option_dungeon.selected
	if idx < 0:
		return Constants.MOURNGATE_DUNGEON_ID
	return str(_option_dungeon.get_item_metadata(idx))


func _refresh() -> void:
	_rebuild_assignees()
	_refresh_progress_only()
	var did: String = _selected_dungeon_id()
	var data: Resource = DataRegistry.get_dungeon_data(did)
	var desc: String = "—"
	if data != null:
		if "flavor_text" in data and str(data.flavor_text) != "":
			desc = str(data.flavor_text)
		elif "display_name" in data:
			desc = str(data.display_name)
	_label_target.text = desc
	var pct: float = _SurveySystem.get_survey_percent(did)
	_label_survey_pct.text = "調査進捗（永続）: %.0f%% ／ クリア %.0f%%" % [
		pct, _SurveyConfig.SURVEY_CLEAR_PERCENT
	]
	var bonus: float = _SurveySystem.total_speed_bonus(_pending_as_entries())
	_label_bonus.text = "合計ボーナス +%.0f%%" % (bonus * 100.0)
	_label_materials.text = "調査資料: 古地図の断片 ×%d" % maxi(1, int(pct / 10.0) + 1)
	if pct >= _SurveyConfig.SURVEY_CLEAR_PERCENT:
		_label_discovery.text = "発見: 次区域への手がかりが揃いつつある"
	else:
		_label_discovery.text = "発見: まだ断片的な記録のみ"


func _refresh_progress_only() -> void:
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
		_option_dungeon.disabled = false
		return
	var rem: float = _SurveySystem.cycle_remaining_sec()
	_label_timer.text = "調査完了まで: %s（%.0f%%）" % [_format_hms(rem), p01 * 100.0]
	_btn_start_short.disabled = true
	_btn_start_std.disabled = true
	_option_dungeon.disabled = true
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
	## 進行中はサイクルの assignees を表示
	var show_ids: Array[String] = _pending_members
	var roles: Array = []
	if _SurveySystem.has_active_cycle():
		show_ids = []
		for entry in GameState.hub_survey_cycle.get("assignees", []):
			if entry is Dictionary:
				show_ids.append(str(entry.get("member_id", "")))
				roles.append(str(entry.get("role_id", "")))
	for i in range(_SurveyConfig.INVESTIGATOR_SLOTS):
		var row := _card_panel()
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		var role_id: String = _SurveyConfig.ROLE_IDS[i]
		if i < roles.size() and str(roles[i]) != "":
			role_id = str(roles[i])
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path: String = "res://assets/ui/survey/ICO_Survey_Role_%s.png" % role_id.capitalize()
		## files are Archaeology/Geology/Documents
		match role_id:
			"archaeology":
				icon_path = "res://assets/ui/survey/ICO_Survey_Role_Archaeology.png"
			"geology":
				icon_path = "res://assets/ui/survey/ICO_Survey_Role_Geology.png"
			_:
				icon_path = "res://assets/ui/survey/ICO_Survey_Role_Documents.png"
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path) as Texture2D
		hb.add_child(icon)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_l := Label.new()
		var mid: String = show_ids[i] if i < show_ids.size() else ""
		var adv: Resource = GameState.find_roster_member_by_id(mid) if not mid.is_empty() else null
		name_l.text = "空きスロット" if adv == null else str(adv.display_name)
		UiTypography.apply_body(name_l)
		vb.add_child(name_l)
		var role_l := Label.new()
		var bonus: float = 0.0 if adv == null else _SurveySystem.investigator_speed_bonus(mid, role_id)
		role_l.text = "%s ／ 速度 +%.0f%%" % [
			str(_SurveyConfig.ROLE_DISPLAY.get(role_id, role_id)),
			bonus * 100.0,
		]
		UiTypography.apply_caption(role_l)
		vb.add_child(role_l)
		hb.add_child(vb)
		if not _SurveySystem.has_active_cycle():
			var btn := Button.new()
			btn.text = "変更"
			var slot_i: int = i
			btn.pressed.connect(func(): _cycle_member_at(slot_i))
			hb.add_child(btn)
		row.add_child(hb)
		_assignee_box.add_child(row)
	## ロック枠
	var lock := _card_panel()
	var lock_l := Label.new()
	lock_l.text = "🔒 調査室Lv.15で4枠目解放（後続）"
	UiTypography.apply_caption(lock_l)
	lock.add_child(lock_l)
	_assignee_box.add_child(lock)


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
		_label_discovery.text = "開始不可: %s" % str(result.get("reason", ""))
		return
	SaveManager.save_game()
	_refresh()


func _on_claim() -> void:
	var result: Dictionary = _SurveySystem.claim_cycle()
	if not bool(result.get("ok", false)):
		_label_discovery.text = "受取不可: %s" % str(result.get("reason", ""))
		return
	var parts: PackedStringArray = []
	parts.append("%s +%d" % [_CurrencyHelper.DISPLAY_NAME, int(result.get("token", 0))])
	parts.append("Gold +%d" % int(result.get("gold", 0)))
	parts.append("素材 ×%d" % int(result.get("material_qty", 0)))
	if not str(result.get("weapon_id", "")).is_empty():
		parts.append("武器入手")
	_label_discovery.text = "受取完了: %s ／ %s" % [
		" ・ ".join(parts),
		str(result.get("discovery", "")),
	]
	_pending_members = _SurveySystem.auto_assign_members()
	_refresh()


func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
