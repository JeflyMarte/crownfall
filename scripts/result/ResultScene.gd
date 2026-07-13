extends Control

const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"
const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const PartyLogColorsScript: Script = preload("res://scripts/ui/PartyLogColors.gd")
const ResultFlowScript: Script = preload("res://scripts/result/ResultFlowController.gd")
const ExpRunSnapshotScript: Script = preload("res://scripts/result/ExpRunSnapshot.gd")
const ExpBarPresenterScript: Script = preload("res://scripts/result/ExpBarPresenter.gd")
const MvpScoreScript: Script = preload("res://scripts/result/MvpScore.gd")
const MvpPresentationScript: Script = preload("res://scripts/result/MvpPresentation.gd")
const SkillIconHelperScript: Script = preload("res://scripts/ui/SkillIconHelper.gd")
const _MaterialUiTokens = preload("res://scripts/equipment/MaterialUiTokens.gd")
const _ChrIdlePortraitView = preload("res://scripts/ui/ChrIdlePortraitView.gd")
const _ResultUiHelper = preload("res://scripts/result/ResultUiHelper.gd")
const CLEAR_BANNER_TEX: Texture2D = preload("res://assets/ui/result/UI_Result_Clear.png")

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
const REWARD_CELL_WIDTH: int = 88
const REWARD_ICON_PX: int = 64
const RARE_ICON_PX: int = 48

@onready var _scroll_rewards: ScrollContainer = $Scroll
@onready var _label_title: Label = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/LabelTitle
@onready var _label_dungeon: Label = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/LabelDungeon
@onready var _clear_banner: TextureRect = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/ClearBanner
@onready var _label_outcome: Label = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/LabelClear
@onready var _stars_row: HBoxContainer = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/StarsRow
@onready var _reward_row: HFlowContainer = $Scroll/Margin/Main/RewardPanel/RewardVBox/RewardRow
@onready var _material_panel: PanelContainer = $Scroll/Margin/Main/MaterialPanel
@onready var _material_row: HFlowContainer = $Scroll/Margin/Main/MaterialPanel/MaterialVBox/MaterialRow
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
@onready var _bg_texture: TextureRect = $BgTexture

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
var _mvp_context_row: HBoxContainer
var _mvp_context_backdrop: PanelContainer
var _mvp_context_dungeon: Label
var _mvp_context_stars: HBoxContainer
var _mvp_podium_host: CenterContainer
var _mvp_stats_grid: GridContainer
var _mvp_skill_row: HBoxContainer
var _mvp_skill_backdrop: PanelContainer
var _mvp_subtitle_label: Label
var _mvp_subtitle_backdrop: PanelContainer
var _mvp_lower_backdrop: PanelContainer
var _mvp_header_backdrop: PanelContainer
var _mvp_scrim: ColorRect
var _mvp_fx_host: Control
var _mvp_intro_active: bool = false
var _mvp_anim_nodes: Array = []
var _levelup_rows: Array = []
var _levelup_pending_count: int = 0

func _ready() -> void:
	_levelup_panel_legacy.visible = false
	_apply_typography()
	_apply_panel_styles()
	_setup_footer_chrome()
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

func _setup_footer_chrome() -> void:
	_ResultUiHelper.apply_retry_button(_button_retry)
	_ResultUiHelper.apply_home_button(_button_home)

func _setup_wizard_roots() -> void:
	_button_next = Button.new()
	_button_next.name = "ButtonNext"
	_button_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button_next.custom_minimum_size = Vector2(0, _ResultUiHelper.FOOTER_BTN_MIN_HEIGHT)
	_button_next.pressed.connect(_on_next_pressed)
	_ResultUiHelper.apply_next_button(_button_next)
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
	_mvp_scrim = ColorRect.new()
	_mvp_scrim.name = "MvpScrim"
	_mvp_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mvp_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mvp_scrim.color = MvpPresentationScript.SCRIM_COLOR
	_step_mvp_root.add_child(_mvp_scrim)
	var mvp_vbox := VBoxContainer.new()
	mvp_vbox.add_theme_constant_override("separation", 14)
	_step_mvp_root.add_child(mvp_vbox)
	_mvp_fx_host = Control.new()
	_mvp_fx_host.name = "MvpFxHost"
	_mvp_fx_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mvp_fx_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mvp_fx_host.z_index = 40
	add_child(_mvp_fx_host)
	_mvp_context_row = HBoxContainer.new()
	_mvp_context_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_mvp_context_row.add_theme_constant_override("separation", 8)
	var crown_icon := TextureRect.new()
	crown_icon.custom_minimum_size = Vector2(28, 28)
	crown_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(MvpPresentationScript.CROWN_ICON_PATH):
		crown_icon.texture = load(MvpPresentationScript.CROWN_ICON_PATH) as Texture2D
	_mvp_context_row.add_child(crown_icon)
	_mvp_context_dungeon = Label.new()
	_mvp_context_dungeon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(
		_mvp_context_dungeon, UiTypography.SIZE_BODY, MvpPresentationScript.TEXT_ON_BACKDROP, UiTypography.OUTLINE_BODY
	)
	_mvp_context_row.add_child(_mvp_context_dungeon)
	_mvp_context_stars = HBoxContainer.new()
	_mvp_context_stars.add_theme_constant_override("separation", 2)
	_mvp_context_row.add_child(_mvp_context_stars)
	_mvp_context_backdrop = _make_mvp_backdrop(_mvp_context_row, "header")
	mvp_vbox.add_child(_mvp_context_backdrop)
	_mvp_header = Label.new()
	_mvp_header.text = "★ 最活躍 ★"
	_mvp_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(_mvp_header, 40, COLOR_GOLD, UiTypography.OUTLINE_STRONG)
	_mvp_header_backdrop = _make_mvp_backdrop(_mvp_header, "header")
	mvp_vbox.add_child(_mvp_header_backdrop)
	_mvp_podium_host = CenterContainer.new()
	_mvp_podium_host.custom_minimum_size = Vector2(0, MvpPresentationScript.PODIUM_MIN_HEIGHT)
	_mvp_podium_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mvp_vbox.add_child(_mvp_podium_host)
	_mvp_lower_backdrop = PanelContainer.new()
	_mvp_lower_backdrop.add_theme_stylebox_override("panel", MvpPresentationScript.backdrop_style("lower"))
	_mvp_lower_backdrop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lower_margin := MarginContainer.new()
	lower_margin.add_theme_constant_override("margin_left", 4)
	lower_margin.add_theme_constant_override("margin_right", 4)
	lower_margin.add_theme_constant_override("margin_top", 4)
	lower_margin.add_theme_constant_override("margin_bottom", 4)
	var lower_vbox := VBoxContainer.new()
	lower_vbox.add_theme_constant_override("separation", 12)
	_mvp_stats_grid = GridContainer.new()
	_mvp_stats_grid.columns = 2
	_mvp_stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mvp_stats_grid.add_theme_constant_override("h_separation", 10)
	_mvp_stats_grid.add_theme_constant_override("v_separation", 10)
	lower_vbox.add_child(_mvp_stats_grid)
	_mvp_skill_row = HBoxContainer.new()
	_mvp_skill_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_mvp_skill_row.add_theme_constant_override("separation", 10)
	_mvp_skill_backdrop = _make_mvp_backdrop(_mvp_skill_row, "body")
	lower_vbox.add_child(_mvp_skill_backdrop)
	_mvp_subtitle_label = Label.new()
	_mvp_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mvp_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(
		_mvp_subtitle_label, UiTypography.SIZE_BODY, COLOR_GOLD, UiTypography.OUTLINE_BODY
	)
	_mvp_subtitle_backdrop = _make_mvp_backdrop(_mvp_subtitle_label, "body", true)
	lower_vbox.add_child(_mvp_subtitle_backdrop)
	lower_margin.add_child(lower_vbox)
	_mvp_lower_backdrop.add_child(lower_margin)
	mvp_vbox.add_child(_mvp_lower_backdrop)
	_mvp_body = VBoxContainer.new()
	_mvp_body.visible = false
	mvp_vbox.add_child(_mvp_body)

func _enter_step(step: int) -> void:
	_current_step = step
	_scroll_rewards.visible = step == ResultFlowScript.Step.REWARDS
	_step_levelup_root.visible = step == ResultFlowScript.Step.LEVELUP
	_step_mvp_root.visible = step == ResultFlowScript.Step.MVP
	if step == ResultFlowScript.Step.MVP:
		_apply_mvp_background(true)
		_build_mvp_step()
		_button_next.visible = false
		_button_retry.visible = false
		_button_home.visible = false
		_step_timer_sec = 0.0
		_play_mvp_intro()
	elif step == ResultFlowScript.Step.LEVELUP:
		_button_next.visible = true
		_button_retry.visible = false
		_button_home.visible = false
		_button_next.disabled = true
		_step_timer_sec = 0.0
		_start_levelup_step()
	else:
		_apply_mvp_background(false)
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
		exp_label.text = "%d / %d 経験値" % [int(snap.get("exp_before", 0)), cap]
		UiTypography.apply_body(exp_label, UiTypography.SIZE_CAPTION, COLOR_SUB)
		col.add_child(exp_label)
		var levelup_flash := Label.new()
		levelup_flash.text = "レベルアップ！"
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
				exp_label.text = "%d / %d 経験値" % [shown_exp, cap],
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
			exp_label.text = "0 / %d 経験値" % cap

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
			exp_label.text = "%d / %d 経験値" % [exp_after, LevelSystem.exp_to_next(lv_after)]
		if flash != null:
			flash.visible = false

func _apply_pending_exp() -> void:
	if _exp_applied:
		return
	_exp_applied = true
	GameState.last_run_level_ups = LevelSystem.grant_exp_to_party(GameState.last_run_exp_reward)

func _apply_mvp_background(use_mvp: bool) -> void:
	if _bg_texture == null:
		return
	var path: String = MvpPresentationScript.BG_PATH if use_mvp else MvpPresentationScript.DEFAULT_BG_PATH
	if path.is_empty() or not ResourceLoader.exists(path):
		path = MvpPresentationScript.DEFAULT_BG_PATH
	_bg_texture.texture = load(path) as Texture2D

func _result_dungeon_label() -> String:
	var dungeon_id: String = GameState.get_active_dungeon_id()
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	var name_text: String = "ダンジョン"
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
	return name_text

func _result_star_count() -> int:
	var dungeon_id: String = GameState.get_active_dungeon_id()
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	var difficulty: int = 1
	if data != null:
		var df: Variant = data.get("difficulty")
		if df is int or df is float:
			difficulty = int(df)
	return clampi(difficulty, 0, 3)

func _populate_mvp_context_header() -> void:
	_mvp_context_dungeon.text = _result_dungeon_label()
	for child in _mvp_context_stars.get_children():
		child.queue_free()
	var total: int = 3
	var filled: int = _result_star_count()
	for i in range(total):
		var star := Label.new()
		star.text = "★" if i < filled else "☆"
		star.add_theme_font_size_override("font_size", FS_STAR - 8)
		star.add_theme_color_override("font_color", COLOR_GOLD if i < filled else COLOR_SUB)
		_mvp_context_stars.add_child(star)

func _build_mvp_step() -> void:
	_mvp_anim_nodes.clear()
	for child in _mvp_podium_host.get_children():
		child.queue_free()
	for child in _mvp_stats_grid.get_children():
		child.queue_free()
	for child in _mvp_skill_row.get_children():
		child.queue_free()
	_populate_mvp_context_header()
	_mvp_subtitle_label.text = ""
	_reset_mvp_intro_visibility()
	var stats: Dictionary = GameState.last_run_combat_stats
	var ranked: Array = MvpScoreScript.rank_members(stats, GameState.party_members)
	if ranked.is_empty():
		_mvp_subtitle_label.text = "活躍データなし"
		_mvp_anim_nodes = [
			_mvp_scrim,
			_mvp_context_backdrop,
			_mvp_header_backdrop,
			_mvp_lower_backdrop,
		]
		return
	var mvp: Dictionary = ranked[0]
	_mvp_podium_host.add_child(_build_mvp_podium(ranked))
	for card: Dictionary in MvpPresentationScript.stat_cards(mvp):
		_mvp_stats_grid.add_child(_make_mvp_stat_card(card))
	_fill_mvp_skill_row(mvp)
	_mvp_subtitle_label.text = MvpPresentationScript.pick_subtitle(mvp)
	_mvp_anim_nodes = [
		_mvp_scrim,
		_mvp_context_backdrop,
		_mvp_header_backdrop,
		_mvp_podium_host,
		_mvp_lower_backdrop,
	]

func _make_mvp_backdrop(content: Control, tier: String, expand_horizontal: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MvpPresentationScript.backdrop_style(tier))
	if expand_horizontal:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_right", 2)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.add_child(content)
	panel.add_child(margin)
	return panel

func _reset_mvp_intro_visibility() -> void:
	for node: Variant in [
		_mvp_scrim,
		_mvp_context_backdrop,
		_mvp_header_backdrop,
		_mvp_podium_host,
		_mvp_lower_backdrop,
	]:
		if node is CanvasItem:
			(node as CanvasItem).modulate.a = 0.0
	if _mvp_podium_host is CanvasItem:
		_mvp_podium_host.scale = Vector2(0.92, 0.92)

func _build_mvp_podium(ranked: Array) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(MvpPresentationScript.PODIUM_WIDTH, MvpPresentationScript.PODIUM_MIN_HEIGHT)
	var slots: Array = MvpPresentationScript.podium_layout(ranked)
	for slot_data: Dictionary in slots:
		var slot_name: String = str(slot_data.get("slot", "center"))
		var slot: Control = _make_mvp_podium_slot(
			slot_data.get("entry", {}),
			bool(slot_data.get("hero", false)),
			float(slot_data.get("scale", 1.0)),
			int(slot_data.get("rank", 1)),
		)
		root.add_child(slot)
		slot.position = MvpPresentationScript.podium_slot_position(slot_name)
	return root

func _make_mvp_podium_slot(entry: Dictionary, is_hero: bool, scale: float, rank: int) -> Control:
	var slot := VBoxContainer.new()
	slot.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_theme_constant_override("separation", 6)
	slot.scale = Vector2(scale, scale)
	var portrait_px: float = (
		MvpPresentationScript.HERO_PORTRAIT_PX if is_hero else MvpPresentationScript.RUNNER_PORTRAIT_PX
	)
	var frame_pad: float = MvpPresentationScript.PORTRAIT_FRAME_PAD
	var frame_host := Control.new()
	frame_host.custom_minimum_size = Vector2(portrait_px + frame_pad * 2, portrait_px + frame_pad * 2)
	if is_hero and ResourceLoader.exists(MvpPresentationScript.FRAME_HERO_PATH):
		var frame := TextureRect.new()
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.texture = load(MvpPresentationScript.FRAME_HERO_PATH) as Texture2D
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame_host.add_child(frame)
	var portrait: Control = _ChrIdlePortraitView.new()
	portrait.set_portrait_size(portrait_px)
	portrait.position = Vector2(frame_pad, frame_pad)
	frame_host.add_child(portrait)
	portrait.set_from_entry(entry)
	slot.pivot_offset = Vector2(frame_host.custom_minimum_size.x * 0.5, portrait_px * 0.5 + frame_pad)
	slot.add_child(frame_host)
	var text_block := VBoxContainer.new()
	text_block.alignment = BoxContainer.ALIGNMENT_CENTER
	text_block.add_theme_constant_override("separation", 4)
	var rank_lbl := Label.new()
	rank_lbl.text = "%d位" % rank
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(
		rank_lbl,
		UiTypography.SIZE_CAPTION,
		COLOR_GOLD if is_hero else MvpPresentationScript.TEXT_MUTED_ON_BACKDROP,
		UiTypography.OUTLINE_BODY if is_hero else 0,
	)
	text_block.add_child(rank_lbl)
	var name := Label.new()
	name.text = str(entry.get("display_name", ""))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for member: Resource in GameState.party_members:
		if member != null and str(member.id) == str(entry.get("member_id", "")):
			UiTypography.apply_display(
				name,
				UiTypography.SIZE_BODY if is_hero else UiTypography.SIZE_BODY_SMALL,
				PartyLogColorsScript.party_color(member),
				UiTypography.OUTLINE_STRONG if is_hero else UiTypography.OUTLINE_BODY,
			)
			break
	text_block.add_child(name)
	var dmg := Label.new()
	dmg.text = "%d ダメージ" % int(entry.get("damage_total", 0))
	dmg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(
		dmg, UiTypography.SIZE_CAPTION, MvpPresentationScript.TEXT_MUTED_ON_BACKDROP, UiTypography.OUTLINE_BODY
	)
	text_block.add_child(dmg)
	slot.add_child(_make_mvp_backdrop(text_block, "podium"))
	return slot

func _make_mvp_stat_card(card: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MvpPresentationScript.backdrop_style("stat"))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon_path: String = str(card.get("icon", ""))
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28, 28)
		icon.texture = load(icon_path) as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var key_lbl := Label.new()
	key_lbl.text = str(card.get("key", ""))
	UiTypography.apply_body(key_lbl, UiTypography.SIZE_CAPTION, MvpPresentationScript.TEXT_MUTED_ON_BACKDROP)
	col.add_child(key_lbl)
	var val_lbl := Label.new()
	val_lbl.text = str(card.get("value", ""))
	UiTypography.apply_display(
		val_lbl, UiTypography.SIZE_BODY, card.get("color", COLOR_TEXT), UiTypography.OUTLINE_STRONG
	)
	col.add_child(val_lbl)
	row.add_child(col)
	margin.add_child(row)
	panel.add_child(margin)
	return panel

func _fill_mvp_skill_row(mvp: Dictionary) -> void:
	for child in _mvp_skill_row.get_children():
		child.queue_free()
	_mvp_skill_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = "決め手"
	UiTypography.apply_body(title, UiTypography.SIZE_BODY, MvpPresentationScript.TEXT_MUTED_ON_BACKDROP, UiTypography.OUTLINE_BODY)
	_mvp_skill_row.add_child(title)
	var skill_id: String = str(mvp.get("damage_max_skill_id", ""))
	var skill_name: String = str(mvp.get("damage_max_skill_name", ""))
	if skill_name.is_empty():
		skill_name = "—"
	var member: Resource = null
	for m: Resource in GameState.party_members:
		if m != null and str(m.id) == str(mvp.get("member_id", "")):
			member = m
			break
	var icon: Control = null
	if not skill_id.is_empty() and member != null:
		icon = SkillIconHelperScript.make_ally_equipped_icon(skill_id, member, Vector2(40, 40))
	if icon == null and not skill_id.is_empty():
		icon = SkillIconHelperScript.make_unique_icon(skill_id, Vector2(40, 40))
	if icon != null:
		_mvp_skill_row.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.text = skill_name
	UiTypography.apply_display(
		name_lbl, UiTypography.SIZE_BODY, MvpPresentationScript.TEXT_ON_BACKDROP, UiTypography.OUTLINE_STRONG
	)
	_mvp_skill_row.add_child(name_lbl)

func _play_mvp_intro() -> void:
	_play_mvp_intro_async()

func _play_mvp_intro_async() -> void:
	_mvp_intro_active = true
	_reset_mvp_intro_visibility()
	var timings: Dictionary = MvpPresentationScript.timings(false)
	await get_tree().process_frame
	var scrim_tw: Tween = create_tween()
	scrim_tw.tween_property(_mvp_scrim, "modulate:a", 1.0, float(timings["header"]) * 0.35)
	var header_tw: Tween = create_tween().set_parallel(true)
	header_tw.tween_property(_mvp_context_backdrop, "modulate:a", 1.0, float(timings["header"]) * 0.55)
	header_tw.tween_property(_mvp_header_backdrop, "modulate:a", 1.0, float(timings["header"]) * 0.55)
	await header_tw.finished
	var podium_tw: Tween = create_tween().set_parallel(true)
	podium_tw.tween_property(_mvp_podium_host, "modulate:a", 1.0, float(timings["podium"]) * 0.45)
	podium_tw.tween_property(_mvp_podium_host, "scale", Vector2.ONE, float(timings["podium"])).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	await podium_tw.finished
	_spawn_mvp_sparkles(_mvp_podium_center_global())
	await get_tree().create_timer(float(timings["sparkle_delay"])).timeout
	var lower_tw: Tween = create_tween()
	lower_tw.tween_property(_mvp_lower_backdrop, "modulate:a", 1.0, float(timings["stat_gap"]) * 4.0)
	await lower_tw.finished
	_flash_mvp_screen()
	_mvp_intro_active = false
	_button_retry.visible = true
	_button_home.visible = true

func _mvp_podium_center_global() -> Vector2:
	if _mvp_podium_host == null:
		return get_viewport_rect().size * Vector2(0.5, 0.42)
	return _mvp_podium_host.get_global_rect().get_center()

func _spawn_mvp_sparkles(at_global: Vector2) -> void:
	if _mvp_fx_host == null:
		return
	var parts := CPUParticles2D.new()
	parts.amount = 42
	parts.lifetime = 0.7
	parts.one_shot = true
	parts.explosiveness = 0.9
	parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	parts.emission_sphere_radius = 24.0
	parts.global_position = at_global
	parts.direction = Vector2(0, -1)
	parts.spread = 180.0
	parts.gravity = Vector2(0, 90.0)
	parts.initial_velocity_min = 70.0
	parts.initial_velocity_max = 160.0
	parts.modulate = MvpPresentationScript.COLOR_GOLD
	_mvp_fx_host.add_child(parts)
	parts.emitting = true
	parts.finished.connect(parts.queue_free)

func _flash_mvp_screen() -> void:
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(MvpPresentationScript.COLOR_GOLD.r, MvpPresentationScript.COLOR_GOLD.g, MvpPresentationScript.COLOR_GOLD.b, 0.0)
	if _mvp_fx_host != null:
		_mvp_fx_host.add_child(flash)
	var tw: Tween = create_tween()
	tw.tween_property(flash, "color:a", 0.18, 0.08)
	tw.tween_property(flash, "color:a", 0.0, 0.16)
	tw.tween_callback(flash.queue_free)

func _apply_typography() -> void:
	UiTypography.apply_display(_label_title, FS_TITLE, COLOR_GOLD)
	UiTypography.apply_body(_label_dungeon, FS_DUNGEON, COLOR_TEXT)
	if _clear_banner.texture == null:
		_clear_banner.texture = CLEAR_BANNER_TEX
	_clear_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_clear_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UiTypography.apply_display(_label_outcome, FS_OUTCOME_CLEAR, COLOR_GOLD)
	for title in [_label_reward_title, _label_material_title, _label_rare_title, _label_info_title]:
		UiTypography.apply_display(title, FS_SECTION, COLOR_GOLD)
	UiTypography.apply_body(_label_craftable, FS_CRAFTABLE, Color(0.7, 0.92, 0.6))
	_label_craftable.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_craftable.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_dungeon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_dungeon.clip_text = true
	_label_dungeon.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

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
			_clear_banner.visible = false
			_label_outcome.visible = true
			_label_outcome.text = "リタイア帰還"
			UiTypography.apply_display(_label_outcome, FS_OUTCOME_ALT, COLOR_RETIRE)
		GameState.RUN_OUTCOME_WIPE:
			_clear_banner.visible = false
			_label_outcome.visible = true
			_label_outcome.text = "探索失敗"
			UiTypography.apply_display(_label_outcome, FS_OUTCOME_ALT, COLOR_FAIL)
		_:
			_clear_banner.visible = true
			_label_outcome.visible = false
			_label_outcome.text = "クリア"

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
	_reward_row.add_child(_make_reward_cell(null, "経験値", "経験値", str(GameState.last_run_exp_reward)))
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
			null, "", DataRegistry.get_weapon_name(weapon), "1", weapon, "weapon"))
	var armor: String = GameState.last_run_armor_dropped
	if not armor.is_empty():
		_reward_row.add_child(_make_reward_cell(
			null, "", DataRegistry.get_armor_name(armor), "1", armor, "armor"))
	var accessory: String = GameState.last_run_accessory_dropped
	if not accessory.is_empty():
		_reward_row.add_child(_make_reward_cell(
			null, "", DataRegistry.get_accessory_name(accessory), "1", accessory, "accessory"))
	var relic: String = GameState.last_run_relic_dropped
	if not relic.is_empty():
		var relic_icon: String = CombatPassives.relic_icon_key(relic)
		_reward_row.add_child(_make_reward_cell(
			IconPaths.get_icon_texture(relic_icon, "relic"), "", CombatRelics.display_name(relic), "1"))

func _make_reward_cell(
	texture: Texture2D,
	glyph: String,
	name_text: String,
	value_text: String,
	item_id: String = "",
	category: String = ""
) -> Control:
	var cell: VBoxContainer = VBoxContainer.new()
	cell.custom_minimum_size = Vector2(REWARD_CELL_WIDTH, 0)
	cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.alignment = BoxContainer.ALIGNMENT_BEGIN
	var icon_host: Control
	if _is_equipment_category(category) and not item_id.is_empty():
		var rarity: int = _equipment_rarity(item_id, category)
		icon_host = BlacksmithUiHelper.make_item_icon_cell(item_id, category, rarity, REWARD_ICON_PX, false)
		icon_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	else:
		var frame: PanelContainer = PanelContainer.new()
		frame.custom_minimum_size = Vector2(REWARD_ICON_PX, REWARD_ICON_PX)
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
		icon_host = frame
	cell.add_child(icon_host)
	var name_label: Label = Label.new()
	name_label.text = name_text
	name_label.custom_minimum_size = Vector2(REWARD_CELL_WIDTH, 0)
	name_label.add_theme_font_size_override("font_size", FS_REWARD_NAME)
	name_label.add_theme_color_override("font_color", COLOR_SUB)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cell.add_child(name_label)
	var value_label: Label = Label.new()
	value_label.text = value_text
	value_label.custom_minimum_size = Vector2(REWARD_CELL_WIDTH, 0)
	value_label.add_theme_font_size_override("font_size", FS_REWARD_VALUE)
	value_label.add_theme_color_override("font_color", COLOR_TEXT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.clip_text = true
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cell.add_child(value_label)
	return cell

func _make_material_reward_cell(material_id: String, value_text: String) -> Control:
	var cell: VBoxContainer = VBoxContainer.new()
	cell.custom_minimum_size = Vector2(REWARD_CELL_WIDTH, 0)
	cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.alignment = BoxContainer.ALIGNMENT_BEGIN
	var frame: PanelContainer = _MaterialUiTokens.make_icon_cell(material_id, 64, true)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.add_child(frame)
	var name_label: Label = Label.new()
	name_label.text = DataRegistry.get_material_name(material_id)
	name_label.custom_minimum_size = Vector2(REWARD_CELL_WIDTH, 0)
	name_label.add_theme_font_size_override("font_size", FS_REWARD_NAME)
	var rarity: int = EquipmentEnhancer.material_rarity(material_id)
	name_label.add_theme_color_override("font_color", BlacksmithUiHelper.rarity_name_color(rarity))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cell.add_child(name_label)
	var value_label: Label = Label.new()
	value_label.text = value_text
	value_label.custom_minimum_size = Vector2(REWARD_CELL_WIDTH, 0)
	value_label.add_theme_font_size_override("font_size", FS_REWARD_VALUE)
	value_label.add_theme_color_override("font_color", COLOR_TEXT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.clip_text = true
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
		_material_row.add_child(_make_material_reward_cell(mat_key, str(qty)))
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
	var rarity: int = _equipment_rarity(item_id, category)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(BlacksmithUiHelper.make_item_icon_cell(item_id, category, rarity, RARE_ICON_PX, false))
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label: Label = Label.new()
	name_label.text = item_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", FS_RARE_NAME)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(name_label)
	if not desc.is_empty():
		var desc_label: Label = Label.new()
		desc_label.text = desc
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.add_theme_font_size_override("font_size", FS_RARE_DESC)
		desc_label.add_theme_color_override("font_color", COLOR_SUB)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(desc_label)
	row.add_child(col)
	var star: Label = Label.new()
	star.text = EquipmentUiHelper.rarity_stars_text(rarity)
	star.add_theme_font_size_override("font_size", FS_RARE_STAR)
	star.add_theme_color_override("font_color", BlacksmithUiHelper.rarity_name_color(rarity))
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(star)
	_rare_list.add_child(row)
	return 1

func _is_equipment_category(category: String) -> bool:
	return category in ["weapon", "armor", "accessory"]

func _equipment_rarity(item_id: String, category: String) -> int:
	var data: Resource = null
	match category:
		"weapon":
			data = DataRegistry.get_weapon_data(item_id)
		"armor":
			data = DataRegistry.get_armor_data(item_id)
		"accessory":
			data = DataRegistry.get_accessory_data(item_id)
	if data != null and "rarity" in data:
		return int(data.rarity)
	return 0

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
	_add_info_pair("入手経験値", "%d" % GameState.last_run_exp_reward)
	_add_info_pair("入手ゴールド", "%d G" % GameState.last_run_gold_reward)
	if GameState.last_run_token_reward > 0:
		_add_info_pair("入手%s" % CurrencyHelper.DISPLAY_NAME, "%d" % GameState.last_run_token_reward)

func _add_info_pair(key: String, value: String) -> void:
	var key_label: Label = Label.new()
	key_label.text = key
	key_label.add_theme_font_size_override("font_size", FS_INFO)
	key_label.add_theme_color_override("font_color", COLOR_SUB)
	key_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_info_grid.add_child(key_label)
	var value_label: Label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", FS_INFO)
	value_label.add_theme_color_override("font_color", COLOR_TEXT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
