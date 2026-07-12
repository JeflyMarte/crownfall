extends Control

const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderTitles = preload("res://scripts/commander/CommanderTitles.gd")
const _CommanderLifetime = preload("res://scripts/commander/CommanderLifetime.gd")
const _CommanderSurveyPoints = preload("res://scripts/commander/CommanderSurveyPoints.gd")
const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)

enum Tab { OVERVIEW, ASSETS, MEMBERS, RECORDS, TITLES }

var _current_tab: Tab = Tab.OVERVIEW

@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _tab_row: HBoxContainer = $MainScroll/MainVBox/TabRow
@onready var _content_host: VBoxContainer = $MainScroll/MainVBox/ContentHost
@onready var _label_locked: Label = $MainScroll/MainVBox/LabelLocked


func _ready() -> void:
	UiTypography.apply_screen_title(_label_title)
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.HOME)
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	_label_locked.visible = false
	UiTypography.apply_caption(_label_locked)
	if not _CommanderProfile.is_profile_unlocked():
		_show_locked_state()
		return
	_build_tabs()
	_select_tab(Tab.OVERVIEW)


func _show_locked_state() -> void:
	_tab_row.visible = false
	_content_host.visible = false
	_label_locked.visible = true
	var progress: Dictionary = _CommanderProfile.progress_to_next_rank()
	_label_locked.text = (
		"隊長台帳は調査許可C級で解放されます。\n"
		+ "現在: %s（%s）"
	) % [_CommanderProfile.rank_display(false), str(progress.get("label", ""))]


func _build_tabs() -> void:
	for child in _tab_row.get_children():
		child.queue_free()
	var entries: Array = [
		[Tab.OVERVIEW, "概要"],
		[Tab.ASSETS, "資産"],
		[Tab.MEMBERS, "仲間"],
		[Tab.RECORDS, "記録"],
		[Tab.TITLES, "称号"],
	]
	for pair: Array in entries:
		var tab: Tab = pair[0]
		var label: String = str(pair[1])
		var btn := Button.new()
		btn.text = label
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(56, 34)
		UiTypography.apply_menu_button(btn, false)
		btn.pressed.connect(_select_tab.bind(tab))
		btn.set_meta("tab_id", int(tab))
		_tab_row.add_child(btn)


func _select_tab(tab: Tab) -> void:
	_current_tab = tab
	for child in _tab_row.get_children():
		if child is Button:
			(child as Button).button_pressed = int(child.get_meta("tab_id", -1)) == int(tab)
	for child in _content_host.get_children():
		child.queue_free()
	match tab:
		Tab.OVERVIEW:
			_build_overview()
		Tab.ASSETS:
			_build_assets()
		Tab.MEMBERS:
			_build_members()
		Tab.RECORDS:
			_build_records()
		Tab.TITLES:
			_build_titles()


func _build_overview() -> void:
	var panel := _make_card()
	var vbox := _card_vbox(panel)
	_add_heading(vbox, _CommanderProfile.get_name())
	var title_id: String = _CommanderProfile.get_equipped_title()
	if not title_id.is_empty():
		_add_caption(vbox, "称号: %s" % _CommanderTitles.get_label(title_id))
	_add_body(vbox, _CommanderProfile.rank_display())
	var progress: Dictionary = _CommanderProfile.progress_to_next_rank()
	var bar := ProgressBar.new()
	bar.max_value = 1.0
	bar.value = float(progress.get("progress", 0.0))
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(bar)
	_add_caption(vbox, str(progress.get("label", "")))
	if _CommanderProfile.can_edit_name():
		vbox.add_child(_make_name_editor())
	_add_heading(vbox, "最近のハイライト", false)
	var highlights: Array = _CommanderProfile.get_recent_highlights()
	if highlights.is_empty():
		_add_caption(vbox, "まだ記録がありません")
	else:
		for entry: Variant in highlights:
			if entry is Dictionary:
				_add_caption(vbox, "・%s" % str(entry.get("text", "")))
	_content_host.add_child(panel)


func _make_name_editor() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var field := LineEdit.new()
	field.placeholder_text = "隊長名（16文字まで）"
	field.text = _CommanderProfile.get_name()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(field)
	var btn := Button.new()
	btn.text = "変更"
	UiTypography.apply_menu_button(btn, false)
	btn.pressed.connect(func():
		if _CommanderProfile.set_name(field.text):
			SaveManager.save_game()
			_select_tab(Tab.OVERVIEW)
	)
	row.add_child(btn)
	return row


func _build_assets() -> void:
	var panel := _make_card()
	var vbox := _card_vbox(panel)
	_add_body(vbox, "ゴールド: %d" % GameState.gold, COLOR_GOLD)
	_add_body(vbox, "%s: %s" % [CurrencyHelper.DISPLAY_NAME, CurrencyHelper.format_amount()], COLOR_GOLD)
	_add_heading(vbox, "所持素材", false)
	var materials: Array = _CommanderProfile.top_materials(8)
	if materials.is_empty():
		_add_caption(vbox, "所持素材なし")
	else:
		for row_data: Dictionary in materials:
			_add_caption(vbox, "%s × %d" % [str(row_data.get("name", "")), int(row_data.get("qty", 0))])
	var shortcuts := HBoxContainer.new()
	shortcuts.add_theme_constant_override("separation", 8)
	var forge_btn := Button.new()
	forge_btn.text = "鍛冶屋へ"
	UiTypography.apply_menu_button(forge_btn, false)
	forge_btn.pressed.connect(func(): SceneRouter.change_scene(BLACKSMITH_SCENE))
	shortcuts.add_child(forge_btn)
	var codex_btn := Button.new()
	codex_btn.text = "図鑑へ"
	UiTypography.apply_menu_button(codex_btn, false)
	codex_btn.pressed.connect(func(): SceneRouter.change_scene(CODEX_SCENE))
	shortcuts.add_child(codex_btn)
	vbox.add_child(shortcuts)
	_content_host.add_child(panel)


func _build_members() -> void:
	var panel := _make_card()
	var vbox := _card_vbox(panel)
	_add_heading(vbox, "よく使う仲間")
	var rows: Array = _CommanderProfile.top_deployed_members(5)
	if rows.is_empty():
		_add_caption(vbox, "まだ出撃記録がありません")
	else:
		for row_data: Dictionary in rows:
			_add_body(
				vbox,
				"%s — 出撃%d / 最活躍%d" % [
					str(row_data.get("display_name", "")),
					int(row_data.get("count", 0)),
					int(row_data.get("mvp_count", 0)),
				]
			)
	_content_host.add_child(panel)


func _build_records() -> void:
	var panel := _make_card()
	var vbox := _card_vbox(panel)
	var lifetime: Dictionary = _CommanderProfile.get_lifetime()
	_add_heading(vbox, "戦闘記録")
	var max_hit: int = int(lifetime.get("damage_max_hit", 0))
	if max_hit <= 0:
		_add_caption(vbox, "最大一撃: 記録なし")
	else:
		var skill_name: String = str(lifetime.get("damage_max_hit_skill_name", ""))
		var context: String = str(lifetime.get("damage_max_hit_context", ""))
		var line: String = "最大一撃: %s" % _CommanderLifetime._format_int(max_hit)
		if not skill_name.is_empty():
			line += "（%s）" % skill_name
		if not context.is_empty():
			line += " @ %s" % context
		_add_body(vbox, line)
	_add_caption(vbox, "単ラン最多与ダメ: %s" % _fmt_or_dash(int(lifetime.get("damage_max_run_total", 0))))
	_add_caption(vbox, "単ラン最多回復: %s" % _fmt_or_dash(int(lifetime.get("heal_max_run_total", 0))))
	_add_heading(vbox, "調査記録", false)
	_add_caption(vbox, "完走 %d / 撤退 %d / 全滅 %d" % [
		int(lifetime.get("runs_cleared", 0)),
		int(lifetime.get("runs_retired", 0)),
		int(lifetime.get("runs_wiped", 0)),
	])
	var rates: Dictionary = _CommanderProfile.codex_rates()
	for key in ["enemy", "material", "weapon"]:
		var row: Dictionary = rates.get(key, {})
		var label: String = {"enemy": "敵", "material": "素材", "weapon": "武器"}.get(key, key)
		_add_caption(
			vbox,
			"%s図鑑: %d/%d（%d%%）" % [
				label,
				int(row.get("discovered", 0)),
				int(row.get("total", 0)),
				int(row.get("percent", 0)),
			]
		)
	if _CommanderProfile.is_rank_at_least(_CommanderProfile.EXTENDED_RECORDS_UNLOCK_RANK):
		_add_heading(vbox, "詳細（A級）", false)
		_add_caption(vbox, "調査点: %d SP" % _CommanderProfile.survey_points())
		_add_caption(vbox, "発見登録: %d 件" % _CommanderSurveyPoints.discovery_count())
	_content_host.add_child(panel)


func _build_titles() -> void:
	var panel := _make_card()
	var vbox := _card_vbox(panel)
	_add_heading(vbox, "称号（%d枠）" % _CommanderProfile.title_slot_limit())
	var equipped: String = _CommanderProfile.get_equipped_title()
	var clear_btn := Button.new()
	clear_btn.text = "称号を外す"
	clear_btn.disabled = equipped.is_empty()
	UiTypography.apply_menu_button(clear_btn, false)
	clear_btn.pressed.connect(func():
		_CommanderProfile.equip_title("")
		SaveManager.save_game()
		_select_tab(Tab.TITLES)
	)
	vbox.add_child(clear_btn)
	var unlocked: Array = _CommanderProfile.get_unlocked_titles()
	if unlocked.is_empty():
		_add_caption(vbox, "未獲得")
	else:
		for title_id: Variant in unlocked:
			var tid: String = str(title_id)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var lbl := Label.new()
			lbl.text = _CommanderTitles.get_label(tid)
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if tid == equipped:
				UiTypography.apply_body(lbl, UiTypography.SIZE_BODY_SMALL, COLOR_GOLD)
			else:
				UiTypography.apply_body(lbl)
			row.add_child(lbl)
			var btn := Button.new()
			btn.text = "装備" if tid != equipped else "装備中"
			btn.disabled = tid == equipped
			UiTypography.apply_menu_button(btn, false)
			btn.pressed.connect(_equip_title.bind(tid))
			row.add_child(btn)
			vbox.add_child(row)
	_content_host.add_child(panel)


func _equip_title(title_id: String) -> void:
	if _CommanderProfile.equip_title(title_id):
		SaveManager.save_game()
		_select_tab(Tab.TITLES)


func _make_card() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	return panel


func _card_vbox(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	return vbox


func _add_heading(vbox: VBoxContainer, text: String, primary: bool = true) -> void:
	var lbl := Label.new()
	lbl.text = text
	if primary:
		UiTypography.apply_display(lbl, UiTypography.SIZE_BODY_SMALL, COLOR_GOLD)
	else:
		UiTypography.apply_body(lbl, UiTypography.SIZE_BODY_SMALL, COLOR_GOLD)
	vbox.add_child(lbl)


func _add_body(vbox: VBoxContainer, text: String, color: Color = Color.WHITE) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(lbl, UiTypography.SIZE_BODY_SMALL, color)
	vbox.add_child(lbl)


func _add_caption(vbox: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(lbl)
	vbox.add_child(lbl)


func _fmt_or_dash(value: int) -> String:
	if value <= 0:
		return "—"
	return _CommanderLifetime._format_int(value)


func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
