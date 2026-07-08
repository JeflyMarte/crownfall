extends Control

const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"
const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const PartyLogColorsScript: Script = preload("res://scripts/ui/PartyLogColors.gd")
const ResultFlowScript: Script = preload("res://scripts/result/ResultFlowController.gd")
const ExpRunSnapshotScript: Script = preload("res://scripts/result/ExpRunSnapshot.gd")
const ExpBarPresenterScript: Script = preload("res://scripts/result/ExpBarPresenter.gd")
const MvpScoreScript: Script = preload("res://scripts/result/MvpScore.gd")

const COLOR_GOLD: Color = Color(0.85, 0.74, 0.45, 1)
const COLOR_TEXT: Color = Color(0.82, 0.84, 0.9, 1)
const COLOR_SUB: Color = Color(0.6, 0.62, 0.7, 1)
const COLOR_FAIL: Color = Color(0.82, 0.45, 0.42, 1)
const COLOR_RETIRE: Color = Color(0.72, 0.8, 0.95, 1)
const COLOR_LEVELUP: Color = Color("#FFD700")

const FS_TITLE: int = 30
const FS_SECTION: int = 24
const FS_DUNGEON: int = 22
const FS_OUTCOME_CLEAR: int = 68
const FS_OUTCOME_ALT: int = 52
const FS_STAR: int = 36
const FS_REWARD_NAME: int = 18
const FS_REWARD_VALUE: int = 22
const FS_REWARD_GLYPH: int = 28
const FS_INFO: int = 20
const FS_RARE_NAME: int = 21
const FS_RARE_DESC: int = 17
const FS_RARE_STAR: int = 26
const FS_CRAFTABLE: int = 19
const FS_BUTTON: int = 24

@onready var _scroll_rewards: ScrollContainer = $Scroll
@onready var _label_title: Label = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/LabelTitle
@onready var _label_dungeon: Label = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/LabelDungeon
@onready var _label_outcome: Label = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/LabelClear
@onready var _stars_row: HBoxContainer = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/StarsRow
@onready var _reward_row: HBoxContainer = $Scroll/Margin/Main/RewardPanel/RewardVBox/RewardRow
@onready var _material_panel: PanelContainer = $Scroll/Margin/Main/MaterialPanel
@onready var _material_row: HBoxContainer = $Scroll/Margin/Main/MaterialPanel/MaterialVBox/MaterialRow
@onready var _label_craftable: Label = $Scroll/Margin/Main/MaterialPanel/MaterialVBox/LabelCraftable
@onready var _rare_panel: PanelContainer = $Scroll/Margin/Main/RarePanel
@onready var _rare_list: VBoxContainer = $Scroll/Margin/Main/RarePanel/RareVBox/RareList
@onready var _info_grid: GridContainer = $Scroll/Margin/Main/InfoPanel/InfoVBox/InfoGrid
@onready var _levelup_panel_legacy: PanelContainer = $Scroll/Margin/Main/LevelUpPanel
@onready var _button_retry: Button = $FooterRow/Footer/ButtonRetry
@onready var _button_home: Button = $FooterRow/Footer/ButtonHome
@onready var _header_panel: PanelContainer = $Scroll/Margin/Main/HeaderPanel
@onready var _reward_panel: PanelContainer = $Scroll/Margin/Main/RewardPanel
@onready var _info_panel: PanelContainer = $Scroll/Margin/Main/InfoPanel
@onready var _label_reward_title: Label = $Scroll/Margin/Main/RewardPanel/RewardVBox/LabelRewardTitle
@onready var _label_material_title: Label = $Scroll/Margin/Main/MaterialPanel/MaterialVBox/LabelMaterialTitle
@onready var _label_rare_title: Label = $Scroll/Margin/Main/RarePanel/RareVBox/LabelRareTitle
@onready var _label_info_title: Label = $Scroll/Margin/Main/InfoPanel/InfoVBox/LabelInfoTitle
@onready var _footer_row: PanelContainer = $FooterRow
@onready var _footer: HBoxContainer = $FooterRow/Footer

var _rewards_banked: bool = false
var _current_step: int = ResultFlowScript.Step.REWARDS
var _step_timer_sec: float = 0.0
var _exp_applied: bool = false
var _levelup_animating: bool = false
var _levelup_skip_requested: bool = false
var _button_next: Button
var _step_levelup_root: MarginContainer
var _step_mvp_root: MarginContainer
var _levelup_header: Label
var _levelup_member_list: VBoxContainer
var _mvp_header: Label
var _mvp_body: VBoxContainer
var _levelup_rows: Array = []
var _levelup_pending_count: int = 0

func _ready() -> void:
	_levelup_panel_legacy.visible = false
	_apply_typography()
	_apply_panel_styles()
	_setup_wizard_roots()
	_bank_rewards()
	_build_header()
	_build_rewards()
	_build_materials()
	_build_rare_items()
	_build_info()
	_button_retry.pressed.connect(_on_retry_pressed)
	_button_home.pressed.connect(_on_home_pressed)
	_enter_step(ResultFlowScript.Step.REWARDS)

func _process(delta: float) -> void:
	if _step_timer_sec <= 0.0:
		return
	if _current_step == ResultFlowScript.Step.MVP:
		return
	if _levelup_animating:
		return
	_step_timer_sec = maxf(0.0, _step_timer_sec - delta)
	_refresh_next_button_text()
	if _step_timer_sec <= 0.0:
		_advance_step()

func _setup_wizard_roots() -> void:
	_button_next = Button.new()
	_button_next.name = "ButtonNext"
	_button_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button_next.custom_minimum_size = Vector2(0, 48)
	_button_next.pressed.connect(_on_next_pressed)
	UiTypography.apply_button(_button_next)
	_button_next.add_theme_font_size_override("font_size", FS_BUTTON)
	_footer.add_child(_button_next)
	_footer.move_child(_button_next, 0)
	_button_retry.visible = false
	_button_home.visible = false
	_step_levelup_root = MarginContainer.new()
	_step_levelup_root.name = "StepLevelUp"
	_step_levelup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_step_levelup_root.offset_bottom = -72.0
	_step_levelup_root.visible = false
	_step_levelup_root.add_theme_constant_override("margin_left", 16)
	_step_levelup_root.add_theme_constant_override("margin_right", 16)
	_step_levelup_root.add_theme_constant_override("margin_top", 12)
	_step_levelup_root.add_theme_constant_override("margin_bottom", 12)
	add_child(_step_levelup_root)
	var levelup_vbox := VBoxContainer.new()
	levelup_vbox.add_theme_constant_override("separation", 16)
	_step_levelup_root.add_child(levelup_vbox)
	_levelup_header = Label.new()
	_levelup_header.text = "レベルアップ！！"
	_levelup_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(_levelup_header, 42, COLOR_LEVELUP, UiTypography.OUTLINE_STRONG)
	levelup_vbox.add_child(_levelup_header)
	_levelup_member_list = VBoxContainer.new()
	_levelup_member_list.add_theme_constant_override("separation", 14)
	_levelup_member_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	levelup_vbox.add_child(_levelup_member_list)
	_step_mvp_root = MarginContainer.new()
	_step_mvp_root.name = "StepMvp"
	_step_mvp_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_step_mvp_root.offset_bottom = -72.0
	_step_mvp_root.visible = false
	_step_mvp_root.add_theme_constant_override("margin_left", 16)
	_step_mvp_root.add_theme_constant_override("margin_right", 16)
	_step_mvp_root.add_theme_constant_override("margin_top", 12)
	_step_mvp_root.add_theme_constant_override("margin_bottom", 12)
	add_child(_step_mvp_root)
	var mvp_vbox := VBoxContainer.new()
	mvp_vbox.add_theme_constant_override("separation", 14)
	_step_mvp_root.add_child(mvp_vbox)
	_mvp_header = Label.new()
	_mvp_header.text = "★ MVP ★"
	_mvp_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(_mvp_header, 40, COLOR_GOLD, UiTypography.OUTLINE_STRONG)
	mvp_vbox.add_child(_mvp_header)
	_mvp_body = VBoxContainer.new()
	_mvp_body.add_theme_constant_override("separation", 10)
	_mvp_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mvp_vbox.add_child(_mvp_body)

func _enter_step(step: int) -> void:
	_current_step = step
	_scroll_rewards.visible = step == ResultFlowScript.Step.REWARDS
	_step_levelup_root.visible = step == ResultFlowScript.Step.LEVELUP
	_step_mvp_root.visible = step == ResultFlowScript.Step.MVP
	if step == ResultFlowScript.Step.MVP:
		_build_mvp_step()
		_button_next.visible = false
		_button_retry.visible = true
		_button_home.visible = true
		_step_timer_sec = 0.0
	elif step == ResultFlowScript.Step.LEVELUP:
		_button_next.visible = true
		_button_retry.visible = false
		_button_home.visible = false
		_button_next.disabled = true
		_step_timer_sec = 0.0
		_start_levelup_step()
	else:
		_button_next.visible = true
		_button_retry.visible = false
		_button_home.visible = false
		_button_next.disabled = false
		_start_step_timer()

func _start_step_timer() -> void:
	_step_timer_sec = ResultFlowScript.STEP_AUTO_SEC
	_refresh_next_button_text()

func _refresh_next_button_text() -> void:
	if _button_next == null:
		return
	if _step_timer_sec > 0.0:
		_button_next.text = "次へ (%d)" % int(ceilf(_step_timer_sec))
	else:
		_button_next.text = "次へ"

func _on_next_pressed() -> void:
	if _current_step == ResultFlowScript.Step.LEVELUP and _levelup_animating:
		_levelup_skip_requested = true
		return
	_advance_step()

func _advance_step() -> void:
	_step_timer_sec = 0.0
	var next_step: int = ResultFlowScript.next_step(
		_current_step,
		GameState.last_run_outcome,
		GameState.last_run_exp_reward
	)
	if next_step == _current_step:
		return
	_enter_step(next_step)

func _start_levelup_step() -> void:
	_build_levelup_rows()
	if _levelup_rows.is_empty():
		_apply_pending_exp()
		_levelup_animating = false
		_button_next.disabled = false
		_advance_step()
		return
	_levelup_skip_requested = false
	_levelup_animating = true
	_play_levelup_sequence()

func _build_levelup_rows() -> void:
	for child in _levelup_member_list.get_children():
		child.queue_free()
	_levelup_rows.clear()
	var snapshots: Dictionary = GameState.last_run_exp_snapshots
	for member: Resource in GameState.party_members:
		if member == null:
			continue
		var member_id: String = str(member.id)
		if not snapshots.has(member_id):
			continue
		var snap: Dictionary = snapshots[member_id]
		var row_panel := PanelContainer.new()
		row_panel.add_theme_stylebox_override(
			"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
		)
		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 10)
		row_margin.add_theme_constant_override("margin_right", 10)
		row_margin.add_theme_constant_override("margin_top", 8)
		row_margin.add_theme_constant_override("margin_bottom", 8)
		var row_h := HBoxContainer.new()
		row_h.add_theme_constant_override("separation", 10)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(52, 52)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var job_id: String = str(snap.get("job_id", member.job_id))
		icon.texture = IconPaths.get_icon_texture(job_id, "chr")
		row_h.add_child(icon)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		var name_label := Label.new()
		var lv_before: int = int(snap.get("level_before", member.level))
		name_label.text = "%s  Lv%d" % [str(snap.get("display_name", member.display_name)), lv_before]
		UiTypography.apply_body(
			name_label,
			UiTypography.SIZE_BODY,
			PartyLogColorsScript.party_color(member),
			UiTypography.OUTLINE_BODY
		)
		col.add_child(name_label)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 16)
		bar.show_percentage = false
		bar.max_value = 1.0
		bar.value = ExpRunSnapshotScript.exp_ratio(lv_before, int(snap.get("exp_before", 0)))
		_style_exp_bar(bar, ExpBarPresenterScript.COLOR_BAR)
		col.add_child(bar)
		var exp_label := Label.new()
		var cap: int = LevelSystem.exp_to_next(lv_before)
		exp_label.text = "%d / %d EXP" % [int(snap.get("exp_before", 0)), cap]
		UiTypography.apply_body(exp_label, UiTypography.SIZE_CAPTION, COLOR_SUB)
		col.add_child(exp_label)
		var levelup_flash := Label.new()
		levelup_flash.text = "Lv UP!"
		levelup_flash.visible = false
		levelup_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTypography.apply_display(levelup_flash, UiTypography.SIZE_DISPLAY, COLOR_LEVELUP, UiTypography.OUTLINE_STRONG)
		col.add_child(levelup_flash)
		row_h.add_child(col)
		row_margin.add_child(row_h)
		row_panel.add_child(row_margin)
		_levelup_member_list.add_child(row_panel)
		_levelup_rows.append({
			"snap": snap,
			"name_label": name_label,
			"bar": bar,
			"exp_label": exp_label,
			"levelup_flash": levelup_flash,
		})

func _style_exp_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.1, 0.14, 0.95)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)

func _play_levelup_sequence() -> void:
	_play_levelup_sequence_async()

func _play_levelup_sequence_async() -> void:
	var timings: Dictionary = ExpBarPresenterScript.timings(false)
	_levelup_pending_count = _levelup_rows.size()
	if _levelup_pending_count <= 0:
		if not _exp_applied:
			_apply_pending_exp()
		_finalize_levelup_rows_from_party()
		_levelup_animating = false
		_button_next.disabled = false
		_start_step_timer()
		return
	for row: Dictionary in _levelup_rows:
		_run_parallel_exp_row(row, timings)
	while _levelup_pending_count > 0 and not _levelup_skip_requested:
		await get_tree().process_frame
	if not _exp_applied:
		_apply_pending_exp()
	_finalize_levelup_rows_from_party()
	_levelup_animating = false
	_button_next.disabled = false
	_start_step_timer()

func _run_parallel_exp_row(row: Dictionary, timings: Dictionary) -> void:
	await _animate_member_exp_row(row, timings)
	_levelup_pending_count = maxi(0, _levelup_pending_count - 1)

func _animate_member_exp_row(row: Dictionary, timings: Dictionary) -> void:
	var snap: Dictionary = row.get("snap", {})
	var bar: ProgressBar = row.get("bar")
	var name_label: Label = row.get("name_label")
	var exp_label: Label = row.get("exp_label")
	var flash: Label = row.get("levelup_flash")
	if bar == null:
		return
	var lv: int = int(snap.get("level_before", 1))
	var exp: int = int(snap.get("exp_before", 0))
	var remaining: int = int(snap.get("exp_gained", 0))
	var display_name: String = str(snap.get("display_name", ""))
	while remaining > 0 and lv < LevelSystem.MAX_LEVEL:
		if _levelup_skip_requested:
			break
		var cap: int = LevelSystem.exp_to_next(lv)
		var need: int = cap - exp
		var chunk: int = mini(remaining, need)
		var start_ratio: float = ExpRunSnapshotScript.exp_ratio(lv, exp)
		var end_ratio: float = ExpRunSnapshotScript.exp_ratio(lv, exp + chunk)
		var tw: Tween = create_tween()
		tw.tween_method(
			func(v: float) -> void:
				bar.value = v
				var shown_exp: int = int(round(v * float(cap)))
				exp_label.text = "%d / %d EXP" % [shown_exp, cap],
			start_ratio,
			end_ratio,
			float(timings.get("fill", 0.9))
		)
		await tw.finished
		remaining -= chunk
		exp += chunk
		if exp >= cap and lv < LevelSystem.MAX_LEVEL:
			flash.visible = true
			_style_exp_bar(bar, ExpBarPresenterScript.COLOR_BAR_LEVELUP)
			await get_tree().create_timer(float(timings.get("level_up", 0.35))).timeout
			flash.visible = false
			_style_exp_bar(bar, ExpBarPresenterScript.COLOR_BAR)
			lv += 1
			exp = 0
			cap = LevelSystem.exp_to_next(lv)
			bar.value = 0.0
			name_label.text = "%s  Lv%d" % [display_name, lv]
			exp_label.text = "0 / %d EXP" % cap

func _finalize_levelup_rows_from_party() -> void:
	for row: Dictionary in _levelup_rows:
		var snap: Dictionary = row.get("snap", {})
		var member_id: String = str(snap.get("member_id", ""))
		var member: Resource = null
		for m: Resource in GameState.party_members:
			if m != null and str(m.id) == member_id:
				member = m
				break
		if member == null:
			continue
		var lv_after: int = int(member.level)
		var exp_after: int = int(member.exp)
		var bar: ProgressBar = row.get("bar")
		var name_label: Label = row.get("name_label")
		var exp_label: Label = row.get("exp_label")
		var flash: Label = row.get("levelup_flash")
		if name_label != null:
			name_label.text = "%s  Lv%d" % [str(snap.get("display_name", member.display_name)), lv_after]
		if bar != null:
			bar.value = ExpRunSnapshotScript.exp_ratio(lv_after, exp_after)
			_style_exp_bar(bar, ExpBarPresenterScript.COLOR_BAR)
		if exp_label != null:
			exp_label.text = "%d / %d EXP" % [exp_after, LevelSystem.exp_to_next(lv_after)]
		if flash != null:
			flash.visible = false

func _apply_pending_exp() -> void:
	if _exp_applied:
		return
	_exp_applied = true
	GameState.last_run_level_ups = LevelSystem.grant_exp_to_party(GameState.last_run_exp_reward)

func _build_mvp_step() -> void:
	for child in _mvp_body.get_children():
		child.queue_free()
	var stats: Dictionary = GameState.last_run_combat_stats
	var ranked: Array = MvpScoreScript.rank_members(stats, GameState.party_members)
	if ranked.is_empty():
		var empty := Label.new()
		empty.text = "活躍データなし"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTypography.apply_body(empty, UiTypography.SIZE_BODY, COLOR_SUB)
		_mvp_body.add_child(empty)
		return
	var mvp: Dictionary = ranked[0]
	var hero_panel := PanelContainer.new()
	hero_panel.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	var hero_margin := MarginContainer.new()
	hero_margin.add_theme_constant_override("margin_left", 12)
	hero_margin.add_theme_constant_override("margin_right", 12)
	hero_margin.add_theme_constant_override("margin_top", 12)
	hero_margin.add_theme_constant_override("margin_bottom", 12)
	var hero_col := VBoxContainer.new()
	hero_col.add_theme_constant_override("separation", 8)
	hero_col.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconPaths.get_icon_texture(str(mvp.get("job_id", "")), "chr")
	hero_col.add_child(icon)
	var name := Label.new()
	name.text = str(mvp.get("display_name", ""))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for member: Resource in GameState.party_members:
		if member != null and str(member.id) == str(mvp.get("member_id", "")):
			UiTypography.apply_display(
				name, UiTypography.SIZE_DISPLAY, PartyLogColorsScript.party_color(member), UiTypography.OUTLINE_STRONG
			)
			break
	hero_col.add_child(name)
	hero_margin.add_child(hero_col)
	hero_panel.add_child(hero_margin)
	_mvp_body.add_child(hero_panel)
	_add_mvp_stat_line("与ダメージ", "%d" % int(mvp.get("damage_total", 0)))
	_add_mvp_stat_line("最大ヒット", "%d" % int(mvp.get("damage_max_hit", 0)))
	var skill_name: String = str(mvp.get("damage_max_skill_name", ""))
	if skill_name.is_empty():
		skill_name = "—"
	_add_mvp_stat_line("決め手スキル", skill_name)
	_add_mvp_stat_line("回復量", "%d" % int(mvp.get("heal_total", 0)))
	if ranked.size() > 1:
		var sub := Label.new()
		sub.text = "— その他 —"
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTypography.apply_body(sub, UiTypography.SIZE_CAPTION, COLOR_SUB)
		_mvp_body.add_child(sub)
		for i in range(1, mini(ranked.size(), 4)):
			var entry: Dictionary = ranked[i]
			var line := Label.new()
			line.text = "%d位 %s  %d dmg" % [
				i + 1,
				str(entry.get("display_name", "")),
				int(entry.get("damage_total", 0)),
			]
			line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UiTypography.apply_body(line, UiTypography.SIZE_BODY_SMALL, COLOR_TEXT)
			_mvp_body.add_child(line)

func _add_mvp_stat_line(key: String, value: String) -> void:
	var row := HBoxContainer.new()
	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(key_lbl, UiTypography.SIZE_BODY, COLOR_SUB)
	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_body(val_lbl, UiTypography.SIZE_BODY, COLOR_TEXT)
	row.add_child(key_lbl)
	row.add_child(val_lbl)
	_mvp_body.add_child(row)

func _apply_typography() -> void:
	UiTypography.apply_display(_label_title, FS_TITLE, COLOR_GOLD)
	UiTypography.apply_body(_label_dungeon, FS_DUNGEON, COLOR_TEXT)
	UiTypography.apply_display(_label_outcome, FS_OUTCOME_CLEAR, COLOR_GOLD)
	for title in [_label_reward_title, _label_material_title, _label_rare_title, _label_info_title]:
		UiTypography.apply_display(title, FS_SECTION, COLOR_GOLD)
	UiTypography.apply_body(_label_craftable, FS_CRAFTABLE, Color(0.7, 0.92, 0.6))
	for btn in [_button_retry, _button_home]:
		UiTypography.apply_button(btn)
		btn.add_theme_font_size_override("font_size", FS_BUTTON)

func _apply_panel_styles() -> void:
	_header_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	for panel in [_reward_panel, _material_panel, _rare_panel, _info_panel]:
		panel.add_theme_stylebox_override(
			"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
		)

func _bank_rewards() -> void:
	if _rewards_banked:
		return
	_rewards_banked = true
	GameState.gold += GameState.last_run_gold_reward
	if GameState.last_run_token_reward > 0:
		GameState.gacha_token += GameState.last_run_token_reward

func _build_header() -> void:
	var dungeon_id: String = GameState.get_active_dungeon_id()
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	var name_text: String = "ダンジョン"
	var difficulty: int = 1
	var stage_id: String = GameState.last_run_stage_id
	if stage_id.is_empty():
		stage_id = GameState.get_active_stage_id()
	var stage: Resource = DataRegistry.get_stage_data(stage_id)
	if stage != null and Constants.SUB_STAGES_PLAYABLE:
		name_text = "%d-%d %s" % [int(stage.biome_index), int(stage.chapter_index), str(stage.display_name)]
	elif data != null:
		var dn: Variant = data.get("display_name")
		if dn is String and not (dn as String).is_empty():
			name_text = dn
	if data != null:
		var df: Variant = data.get("difficulty")
		if df is int or df is float:
			difficulty = int(df)
	_label_dungeon.text = name_text
	_apply_outcome_banner()
	_build_stars(difficulty)

func _apply_outcome_banner() -> void:
	var outcome: String = GameState.last_run_outcome
	if outcome.is_empty():
		outcome = GameState.RUN_OUTCOME_CLEAR
	_label_title.text = UiTypography.decorate_title_text("探索結果")
	match outcome:
		GameState.RUN_OUTCOME_RETIRE:
			_label_outcome.text = "リタイア帰還"
			UiTypography.apply_display(_label_outcome, FS_OUTCOME_ALT, COLOR_RETIRE)
		GameState.RUN_OUTCOME_WIPE:
			_label_outcome.text = "探索失敗"
			UiTypography.apply_display(_label_outcome, FS_OUTCOME_ALT, COLOR_FAIL)
		_:
			_label_outcome.text = "CLEAR"
			UiTypography.apply_display(_label_outcome, FS_OUTCOME_CLEAR, COLOR_GOLD)

func _build_stars(filled: int) -> void:
	for child in _stars_row.get_children():
		child.queue_free()
	var total: int = 3
	var n: int = clampi(filled, 0, total)
	for i in range(total):
		var star: Label = Label.new()
		star.text = "★" if i < n else "☆"
		star.add_theme_font_size_override("font_size", FS_STAR)
		star.add_theme_color_override("font_color", COLOR_GOLD if i < n else COLOR_SUB)
		_stars_row.add_child(star)

func _build_rewards() -> void:
	for child in _reward_row.get_children():
		child.queue_free()
	_reward_row.add_child(_make_reward_cell(null, "EXP", "EXP", str(GameState.last_run_exp_reward)))
	var gold_icon: Texture2D = load("res://assets/ui/batch2/ICO_Gold.png") as Texture2D
	_reward_row.add_child(_make_reward_cell(gold_icon, "G", "ゴールド", str(GameState.last_run_gold_reward)))
	if GameState.last_run_token_reward > 0:
		_reward_row.add_child(_make_reward_cell(
			CurrencyHelper.get_icon_texture(), "", CurrencyHelper.DISPLAY_NAME,
			str(GameState.last_run_token_reward)
		))
	var weapon: String = GameState.last_run_weapon_dropped
	if not weapon.is_empty():
		_reward_row.add_child(_make_reward_cell(
			IconPaths.get_icon_texture(weapon, "weapon"), "", DataRegistry.get_weapon_name(weapon), "1"))
	var armor: String = GameState.last_run_armor_dropped
	if not armor.is_empty():
		_reward_row.add_child(_make_reward_cell(
			IconPaths.get_icon_texture(armor, "armor"), "", DataRegistry.get_armor_name(armor), "1"))
	var accessory: String = GameState.last_run_accessory_dropped
	if not accessory.is_empty():
		_reward_row.add_child(_make_reward_cell(
			IconPaths.get_icon_texture(accessory, "accessory"), "", DataRegistry.get_accessory_name(accessory), "1"))
	var relic: String = GameState.last_run_relic_dropped
	if not relic.is_empty():
		var relic_icon: String = CombatPassives.relic_icon_key(relic)
		_reward_row.add_child(_make_reward_cell(
			IconPaths.get_icon_texture(relic_icon, "relic"), "", CombatRelics.display_name(relic), "1"))

func _make_reward_cell(texture: Texture2D, glyph: String, name_text: String, value_text: String) -> Control:
	var cell: VBoxContainer = VBoxContainer.new()
	cell.custom_minimum_size = Vector2(96, 0)
	cell.alignment = BoxContainer.ALIGNMENT_BEGIN
	var frame: PanelContainer = PanelContainer.new()
	frame.custom_minimum_size = Vector2(64, 64)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	if texture != null:
		var icon: TextureRect = TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		frame.add_child(icon)
	else:
		var glyph_label: Label = Label.new()
		glyph_label.text = glyph
		glyph_label.add_theme_font_size_override("font_size", FS_REWARD_GLYPH)
		glyph_label.add_theme_color_override("font_color", COLOR_GOLD)
		glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		frame.add_child(glyph_label)
	cell.add_child(frame)
	var name_label: Label = Label.new()
	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", FS_REWARD_NAME)
	name_label.add_theme_color_override("font_color", COLOR_SUB)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cell.add_child(name_label)
	var value_label: Label = Label.new()
	value_label.text = value_text
	value_label.add_theme_font_size_override("font_size", FS_REWARD_VALUE)
	value_label.add_theme_color_override("font_color", COLOR_TEXT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(value_label)
	return cell

func _build_materials() -> void:
	for child in _material_row.get_children():
		child.queue_free()
	var mat_ids: Array = GameState.last_run_material_gains.keys()
	mat_ids.sort()
	var count: int = 0
	for mat_id in mat_ids:
		var qty: int = int(GameState.last_run_material_gains[mat_id])
		if qty <= 0:
			continue
		var mat_key: String = str(mat_id)
		var icon: Texture2D = IconPaths.get_icon_texture(mat_key, "material")
		var glyph: String = "材"
		if icon == null and not mat_key.is_empty():
			glyph = mat_key.substr(0, 1)
		_material_row.add_child(_make_reward_cell(
			icon,
			glyph,
			DataRegistry.get_material_name(mat_key),
			str(qty),
		))
		count += 1
	_material_panel.visible = count > 0
	_build_craftable_hint(count > 0)

func _build_craftable_hint(had_material_gains: bool) -> void:
	if not had_material_gains:
		_label_craftable.visible = false
		_label_craftable.text = ""
		return
	var recipes: Array = CraftHelper.get_craftable_recipes()
	if recipes.is_empty():
		_label_craftable.visible = false
		_label_craftable.text = ""
		return
	var names: PackedStringArray = []
	for craft in recipes:
		names.append(str(craft.display_name))
	_label_craftable.text = "赤鉄の工房で作成可能: " + " / ".join(names)
	_label_craftable.visible = true

func _build_rare_items() -> void:
	for child in _rare_list.get_children():
		child.queue_free()
	var rows: int = 0
	rows += _add_rare_row(GameState.last_run_weapon_dropped, "weapon")
	rows += _add_rare_row(GameState.last_run_armor_dropped, "armor")
	rows += _add_rare_row(GameState.last_run_accessory_dropped, "accessory")
	_rare_panel.visible = rows > 0

func _add_rare_row(item_id: String, category: String) -> int:
	if item_id.is_empty():
		return 0
	var item_name: String = ""
	var desc: String = ""
	var data: Resource = null
	match category:
		"weapon":
			item_name = DataRegistry.get_weapon_name(item_id)
			data = DataRegistry.get_weapon_data(item_id)
		"armor":
			item_name = DataRegistry.get_armor_name(item_id)
			data = DataRegistry.get_armor_data(item_id)
		"accessory":
			item_name = DataRegistry.get_accessory_name(item_id)
			data = DataRegistry.get_accessory_data(item_id)
	if data != null:
		var d: Variant = data.get("description")
		if d is String:
			desc = d
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var icon: TextureRect = TextureRect.new()
	icon.texture = IconPaths.get_icon_texture(item_id, category)
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label: Label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", FS_RARE_NAME)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	col.add_child(name_label)
	if not desc.is_empty():
		var desc_label: Label = Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", FS_RARE_DESC)
		desc_label.add_theme_color_override("font_color", COLOR_SUB)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(desc_label)
	row.add_child(col)
	var star: Label = Label.new()
	star.text = "★"
	star.add_theme_font_size_override("font_size", FS_RARE_STAR)
	star.add_theme_color_override("font_color", COLOR_GOLD)
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(star)
	_rare_list.add_child(row)
	return 1

func _build_info() -> void:
	for child in _info_grid.get_children():
		child.queue_free()
	var outcome: String = GameState.last_run_outcome
	if not outcome.is_empty():
		_add_info_pair("帰還", GameState.run_outcome_label(outcome))
	var run_policy: String = GameState.last_run_exploration_policy
	if not run_policy.is_empty():
		_add_info_pair("探索方針", GameState.exploration_policy_label(run_policy))
	var run_weather: String = GameState.last_run_weather
	if not run_weather.is_empty():
		_add_info_pair("天候", CombatWeather.label(run_weather))
	var top_mods: Array = GameState.top_run_modifiers(3)
	if not top_mods.is_empty():
		var parts: PackedStringArray = []
		for m in top_mods:
			parts.append("%s×%d" % [str(m["label"]), int(m["count"])])
		_add_info_pair("効いた戦闘要素", " / ".join(parts))
	var dungeon_id: String = GameState.get_active_dungeon_id()
	var prog: Dictionary = GameState.dungeon_progress.get(dungeon_id, {})
	var discovery_pct: int = int(round(float(prog.get("discovery", 0.0)) * 100.0))
	_add_info_pair("発見率", "%d%%" % discovery_pct)
	_add_info_pair("入手経験値", "%d EXP" % GameState.last_run_exp_reward)
	_add_info_pair("入手ゴールド", "%d G" % GameState.last_run_gold_reward)
	if GameState.last_run_token_reward > 0:
		_add_info_pair("入手%s" % CurrencyHelper.DISPLAY_NAME, "%d" % GameState.last_run_token_reward)

func _add_info_pair(key: String, value: String) -> void:
	var key_label: Label = Label.new()
	key_label.text = key
	key_label.add_theme_font_size_override("font_size", FS_INFO)
	key_label.add_theme_color_override("font_color", COLOR_SUB)
	_info_grid.add_child(key_label)
	var value_label: Label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", FS_INFO)
	value_label.add_theme_color_override("font_color", COLOR_TEXT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_grid.add_child(value_label)

func _on_retry_pressed() -> void:
	if not _exp_applied and ResultFlowScript.show_levelup_step(
		GameState.last_run_outcome, GameState.last_run_exp_reward
	):
		_apply_pending_exp()
	_set_buttons_disabled(true)
	SaveManager.save_game()
	SceneRouter.change_scene(DUNGEON_SCENE)

func _on_home_pressed() -> void:
	if not _exp_applied and ResultFlowScript.show_levelup_step(
		GameState.last_run_outcome, GameState.last_run_exp_reward
	):
		_apply_pending_exp()
	_set_buttons_disabled(true)
	SaveManager.save_game()
	SceneRouter.change_scene(HOME_SCENE)

func _set_buttons_disabled(value: bool) -> void:
	_button_retry.disabled = value
	_button_home.disabled = value
	if _button_next != null:
		_button_next.disabled = value
