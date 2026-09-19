extends Control

## 王痕育成専用画面（Decision 144 Phase 2）。Presentation のみ。transaction は RoyalMarkSystem。
## UI: 次の王痕を主情報に。現在効果コンパクト／特殊王痕2行予告。

const _RoyalMarkConfig := preload("res://scripts/systems/RoyalMarkConfig.gd")
const _RoyalMarkSystem := preload("res://scripts/systems/RoyalMarkSystem.gd")
const _RoyalMarkSkillModifier := preload("res://scripts/systems/RoyalMarkSkillModifier.gd")
const _RoyalMarkUiTokens := preload("res://scripts/royal_mark/RoyalMarkUiTokens.gd")
const _UltimateSkillResolver := preload("res://scripts/combat/UltimateSkillResolver.gd")
const _GachaLimitBreak := preload("res://scripts/gacha/GachaLimitBreak.gd")
const _ChrIdlePortrait := preload("res://scripts/ui/ChrIdlePortrait.gd")
const _SafeAreaHelper := preload("res://scripts/ui/SafeAreaHelper.gd")
const HOME_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"

const SHARD_HELP_BODY: String = (
	"王痕片\n極限任務の攻略によって獲得できる。\n"
	+ "極限指令を達成し、高い★評価を得ることで追加獲得できる。"
)

@onready var _root: VBoxContainer = $Root

var _members: Array = []
var _index: int = 0
var _busy: bool = false

var _btn_back: Button
var _btn_help: Button
var _label_title: Label
var _btn_prev: Button
var _btn_next: Button
var _portrait: TextureRect
var _label_name: Label
var _label_level: Label
var _label_rank: Label
var _emblem_host: CenterContainer
var _emblem_stack: Control
var _emblem: TextureRect
var _emblem_glow: ColorRect
var _emblem_frame: PanelContainer
var _rank_nodes: Array[Control] = []
var _rank_labels: Array[Label] = []
var _rank_connectors: Array[Control] = []

var _label_stat_hp: Label
var _label_stat_atk: Label
var _label_stat_def: Label
var _label_current_stats: Label
var _label_special_iii: Label
var _label_special_v: Label

var _panel_next: PanelContainer
var _label_next_title: Label
var _label_next_rank: Label
var _label_next_effect: Label
var _label_next_block: Label
var _btn_shards: Button
var _label_gold_cost: Label
var _gold_row_panel: PanelContainer
var _panel_max: PanelContainer
var _label_max_title: Label
var _label_max_sub: Label
var _panel_status: PanelContainer
var _label_status: Label
var _btn_upgrade: Button
var _panel_special: PanelContainer
var _panel_path: PanelContainer
var _label_path_current: Label
var _label_path_hint: Label
var _label_path_excluded: Label
var _path_btn_row: HBoxContainer
var _btn_path_offense: Button
var _btn_path_defense: Button
var _btn_path_technique: Button

var _confirm_overlay: Control
var _confirm_title: Label
var _confirm_body: Label
var _confirm_on_ok: Callable = Callable()
var _help_overlay: Control


func _ready() -> void:
	_root.add_theme_constant_override("separation", 6)
	_apply_safe_area()
	_build_chrome()
	_build_confirm_overlay()
	_reload_members()
	_refresh_all()


func _apply_safe_area() -> void:
	var top: float = 12.0
	var bottom: float = 12.0
	if _SafeAreaHelper.should_apply_chrome():
		top += _SafeAreaHelper.top_inset()
		bottom += _SafeAreaHelper.bottom_inset()
	_root.offset_top = top
	_root.offset_bottom = -bottom


func _build_chrome() -> void:
	for c in _root.get_children():
		c.queue_free()

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_root.add_child(header)
	_btn_back = Button.new()
	_btn_back.text = "←"
	_btn_back.custom_minimum_size = Vector2(48, 48)
	_btn_back.focus_mode = Control.FOCUS_NONE
	_RoyalMarkUiTokens.apply_chrome_button(_btn_back, true)
	_btn_back.pressed.connect(_on_back_pressed)
	header.add_child(_btn_back)
	_label_title = Label.new()
	_label_title.text = "✦ 王痕育成 ✦"
	_label_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_screen_title(_label_title)
	_label_title.add_theme_color_override("font_color", _RoyalMarkUiTokens.COLOR_GOLD)
	header.add_child(_label_title)
	_btn_help = Button.new()
	_btn_help.text = "?"
	_btn_help.custom_minimum_size = Vector2(48, 48)
	_btn_help.focus_mode = Control.FOCUS_NONE
	_RoyalMarkUiTokens.apply_chrome_button(_btn_help, true)
	_btn_help.pressed.connect(_on_shards_help_pressed)
	header.add_child(_btn_help)

	var char_row := HBoxContainer.new()
	char_row.add_theme_constant_override("separation", 8)
	char_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(char_row)
	_btn_prev = Button.new()
	_btn_prev.text = "◀"
	_btn_prev.custom_minimum_size = Vector2(44, int(_RoyalMarkUiTokens.PORTRAIT_SIZE))
	_btn_prev.focus_mode = Control.FOCUS_NONE
	_RoyalMarkUiTokens.apply_chrome_button(_btn_prev, true)
	_btn_prev.pressed.connect(_on_prev_pressed)
	char_row.add_child(_btn_prev)
	var char_col := VBoxContainer.new()
	char_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	char_col.add_theme_constant_override("separation", 4)
	char_row.add_child(char_col)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(
		_RoyalMarkUiTokens.PORTRAIT_SIZE, _RoyalMarkUiTokens.PORTRAIT_SIZE
	)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	char_col.add_child(_portrait)
	_label_name = Label.new()
	_label_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(_label_name, UiTypography.SIZE_BODY, _RoyalMarkUiTokens.COLOR_BODY)
	char_col.add_child(_label_name)
	_label_level = Label.new()
	_label_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(_label_level, _RoyalMarkUiTokens.COLOR_BODY)
	char_col.add_child(_label_level)
	_label_rank = Label.new()
	_label_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(_label_rank, UiTypography.SIZE_BODY_SMALL, _RoyalMarkUiTokens.COLOR_GOLD_LIT)
	char_col.add_child(_label_rank)
	_btn_next = Button.new()
	_btn_next.text = "▶"
	_btn_next.custom_minimum_size = Vector2(44, int(_RoyalMarkUiTokens.PORTRAIT_SIZE))
	_btn_next.focus_mode = Control.FOCUS_NONE
	_RoyalMarkUiTokens.apply_chrome_button(_btn_next, true)
	_btn_next.pressed.connect(_on_next_pressed)
	char_row.add_child(_btn_next)

	_emblem_host = CenterContainer.new()
	_emblem_host.custom_minimum_size = Vector2(0, _RoyalMarkUiTokens.EMBLEM_HOST_BASE)
	_root.add_child(_emblem_host)
	_emblem_stack = Control.new()
	_emblem_stack.custom_minimum_size = Vector2(
		_RoyalMarkUiTokens.EMBLEM_HOST_BASE, _RoyalMarkUiTokens.EMBLEM_HOST_BASE
	)
	_emblem_host.add_child(_emblem_stack)
	_emblem_glow = ColorRect.new()
	_emblem_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_emblem_glow.color = Color(0.86, 0.74, 0.45, 0.0)
	_emblem_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_emblem_stack.add_child(_emblem_glow)
	_emblem_frame = PanelContainer.new()
	_emblem_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_emblem_frame.add_theme_stylebox_override("panel", _RoyalMarkUiTokens.info_panel_style())
	_emblem_stack.add_child(_emblem_frame)
	_emblem = TextureRect.new()
	_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_emblem.custom_minimum_size = Vector2(
		_RoyalMarkUiTokens.EMBLEM_SIZE_BASE, _RoyalMarkUiTokens.EMBLEM_SIZE_BASE
	)
	_emblem_frame.add_child(_emblem)

	var track := VBoxContainer.new()
	track.add_theme_constant_override("separation", 2)
	_root.add_child(track)
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 4)
	track.add_child(dots)
	var romans := HBoxContainer.new()
	romans.alignment = BoxContainer.ALIGNMENT_CENTER
	romans.add_theme_constant_override("separation", 4)
	track.add_child(romans)
	_rank_nodes.clear()
	_rank_labels.clear()
	_rank_connectors.clear()
	for i in range(1, 6):
		if i > 1:
			var bar := Label.new()
			bar.text = "—"
			bar.custom_minimum_size = Vector2(28, 24)
			bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UiTypography.apply_caption(bar, _RoyalMarkUiTokens.COLOR_MUTED)
			dots.add_child(bar)
			_rank_connectors.append(bar)
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(28, 1)
			romans.add_child(gap)
		var node := Label.new()
		node.text = "○"
		node.custom_minimum_size = Vector2(40, 24)
		node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTypography.apply_body(node, UiTypography.SIZE_BODY_SMALL, _RoyalMarkUiTokens.COLOR_MUTED)
		dots.add_child(node)
		_rank_nodes.append(node)
		var rl := Label.new()
		rl.text = _RoyalMarkConfig.roman_for_rank(i)
		rl.custom_minimum_size = Vector2(40, 20)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTypography.apply_caption(rl, _RoyalMarkUiTokens.COLOR_SUB)
		romans.add_child(rl)
		_rank_labels.append(rl)

	## --- 4. 現在の効果（1行コンパクト） ---
	var cur_panel := PanelContainer.new()
	cur_panel.add_theme_stylebox_override("panel", _RoyalMarkUiTokens.info_panel_style())
	cur_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(cur_panel)
	var cur_v := VBoxContainer.new()
	cur_v.add_theme_constant_override("separation", 4)
	cur_panel.add_child(cur_v)
	var cur_title := Label.new()
	cur_title.text = "現在の効果"
	UiTypography.apply_caption(cur_title, _RoyalMarkUiTokens.COLOR_GOLD)
	cur_v.add_child(cur_title)
	var stats_row := HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override("separation", 12)
	stats_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cur_v.add_child(stats_row)
	_label_stat_hp = _make_stat_inline(stats_row, "HP")
	_label_stat_atk = _make_stat_inline(stats_row, "ATK")
	_label_stat_def = _make_stat_inline(stats_row, "DEF")
	_label_current_stats = Label.new()
	_label_current_stats.visible = false
	cur_v.add_child(_label_current_stats)

	## --- 方針（Decision 146・Rank III+） ---
	_panel_path = PanelContainer.new()
	_panel_path.visible = false
	_panel_path.add_theme_stylebox_override("panel", _RoyalMarkUiTokens.enhance_card_style(false))
	_panel_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(_panel_path)
	var path_v := VBoxContainer.new()
	path_v.add_theme_constant_override("separation", 6)
	_panel_path.add_child(path_v)
	var path_title := Label.new()
	path_title.text = "王痕方針"
	UiTypography.apply_caption(path_title, _RoyalMarkUiTokens.COLOR_GOLD)
	path_v.add_child(path_title)
	_label_path_current = Label.new()
	_label_path_current.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(_label_path_current, UiTypography.SIZE_BODY_SMALL, _RoyalMarkUiTokens.COLOR_BODY)
	path_v.add_child(_label_path_current)
	_label_path_hint = Label.new()
	_label_path_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(_label_path_hint, _RoyalMarkUiTokens.COLOR_SUB)
	path_v.add_child(_label_path_hint)
	_path_btn_row = HBoxContainer.new()
	_path_btn_row.add_theme_constant_override("separation", 6)
	path_v.add_child(_path_btn_row)
	_btn_path_offense = _make_path_button("攻勢", _RoyalMarkConfig.PATH_OFFENSE)
	_btn_path_defense = _make_path_button("守勢", _RoyalMarkConfig.PATH_DEFENSE)
	_btn_path_technique = _make_path_button("技巧", _RoyalMarkConfig.PATH_TECHNIQUE)
	_label_path_excluded = Label.new()
	_label_path_excluded.visible = false
	_label_path_excluded.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(_label_path_excluded, _RoyalMarkUiTokens.COLOR_SHORTAGE)
	path_v.add_child(_label_path_excluded)

	## --- 5〜7. 次の王痕 → コスト → CTA（Reward→Cost→Action）／MAX 同スロット ---
	_panel_next = PanelContainer.new()
	_panel_next.add_theme_stylebox_override("panel", _RoyalMarkUiTokens.info_panel_style())
	_panel_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(_panel_next)
	var next_v := VBoxContainer.new()
	next_v.add_theme_constant_override("separation", 8)
	_panel_next.add_child(next_v)
	_label_next_title = Label.new()
	_label_next_title.text = "次の王痕"
	UiTypography.apply_caption(_label_next_title, _RoyalMarkUiTokens.COLOR_GOLD)
	next_v.add_child(_label_next_title)
	_label_next_rank = Label.new()
	_label_next_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(_label_next_rank, UiTypography.SIZE_DISPLAY_TITLE, _RoyalMarkUiTokens.COLOR_GOLD_LIT)
	next_v.add_child(_label_next_rank)
	_label_next_effect = Label.new()
	_label_next_effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_next_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_display(_label_next_effect, UiTypography.SIZE_DISPLAY, _RoyalMarkUiTokens.COLOR_BODY)
	next_v.add_child(_label_next_effect)
	## テスト互換: 結合文言
	_label_next_block = Label.new()
	_label_next_block.visible = false
	next_v.add_child(_label_next_block)
	_btn_shards = Button.new()
	_btn_shards.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_btn_shards.focus_mode = Control.FOCUS_NONE
	_btn_shards.add_theme_stylebox_override("normal", _RoyalMarkUiTokens.material_row_style(false))
	_btn_shards.add_theme_stylebox_override("hover", _RoyalMarkUiTokens.material_row_style(false))
	_btn_shards.add_theme_stylebox_override("pressed", _RoyalMarkUiTokens.material_row_style(false))
	_btn_shards.add_theme_font_size_override("font_size", UiTypography.SIZE_CAPTION)
	_btn_shards.add_theme_color_override("font_color", _RoyalMarkUiTokens.COLOR_BODY)
	_btn_shards.pressed.connect(_on_shards_help_pressed)
	next_v.add_child(_btn_shards)
	_gold_row_panel = PanelContainer.new()
	_gold_row_panel.add_theme_stylebox_override("panel", _RoyalMarkUiTokens.material_row_style(false))
	next_v.add_child(_gold_row_panel)
	_label_gold_cost = Label.new()
	UiTypography.apply_caption(_label_gold_cost, _RoyalMarkUiTokens.COLOR_SUB)
	_gold_row_panel.add_child(_label_gold_cost)
	_panel_status = PanelContainer.new()
	_panel_status.add_theme_stylebox_override("panel", _RoyalMarkUiTokens.status_pill_style())
	_panel_status.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_v.add_child(_panel_status)
	_label_status = Label.new()
	_label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiTypography.apply_caption(_label_status, _RoyalMarkUiTokens.COLOR_SUB)
	_panel_status.add_child(_label_status)
	_btn_upgrade = Button.new()
	_btn_upgrade.text = "王痕を刻む"
	_btn_upgrade.custom_minimum_size = Vector2(0, 52)
	_btn_upgrade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_upgrade.focus_mode = Control.FOCUS_NONE
	_RoyalMarkUiTokens.apply_upgrade_button(_btn_upgrade, false)
	_btn_upgrade.pressed.connect(_on_upgrade_pressed)
	next_v.add_child(_btn_upgrade)

	_panel_max = PanelContainer.new()
	_panel_max.visible = false
	_panel_max.add_theme_stylebox_override("panel", _RoyalMarkUiTokens.enhance_card_style(true))
	_panel_max.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(_panel_max)
	var max_v := VBoxContainer.new()
	max_v.add_theme_constant_override("separation", 4)
	_panel_max.add_child(max_v)
	_label_max_title = Label.new()
	_label_max_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(_label_max_title, UiTypography.SIZE_DISPLAY_TITLE, _RoyalMarkUiTokens.COLOR_GOLD_LIT)
	max_v.add_child(_label_max_title)
	_label_max_sub = Label.new()
	_label_max_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(_label_max_sub, _RoyalMarkUiTokens.COLOR_GOLD)
	max_v.add_child(_label_max_sub)

	## --- 8. 特殊王痕 III / V（2行コンパクト） ---
	_panel_special = PanelContainer.new()
	_panel_special.add_theme_stylebox_override("panel", _RoyalMarkUiTokens.info_panel_style())
	_panel_special.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(_panel_special)
	var sp_v := VBoxContainer.new()
	sp_v.add_theme_constant_override("separation", 4)
	_panel_special.add_child(sp_v)
	var sp_title := Label.new()
	sp_title.text = "特殊王痕"
	UiTypography.apply_caption(sp_title, _RoyalMarkUiTokens.COLOR_GOLD)
	sp_v.add_child(sp_title)
	_label_special_iii = Label.new()
	_label_special_iii.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(_label_special_iii, _RoyalMarkUiTokens.COLOR_MUTED)
	sp_v.add_child(_label_special_iii)
	_label_special_v = Label.new()
	_label_special_v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(_label_special_v, _RoyalMarkUiTokens.COLOR_MUTED)
	sp_v.add_child(_label_special_v)


func _make_path_button(label: String, path_id: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 40)
	_RoyalMarkUiTokens.apply_chrome_button(btn, true)
	btn.pressed.connect(_on_path_pressed.bind(path_id))
	_path_btn_row.add_child(btn)
	return btn


func _make_stat_inline(parent: HBoxContainer, key: String) -> Label:
	var col := HBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(col)
	var k := Label.new()
	k.text = key
	UiTypography.apply_caption(k, _RoyalMarkUiTokens.COLOR_SUB)
	col.add_child(k)
	var v := Label.new()
	v.text = "—"
	UiTypography.apply_body(v, UiTypography.SIZE_BODY_SMALL, _RoyalMarkUiTokens.COLOR_BODY)
	col.add_child(v)
	return v


func _reload_members() -> void:
	_members = _RoyalMarkSystem.list_owned_eligible_members()
	if _members.is_empty():
		_index = 0
		return
	_index = clampi(_index, 0, _members.size() - 1)
	var focus_id: String = str(GameState.equipment_focus_member_id).strip_edges()
	if not focus_id.is_empty():
		for i in _members.size():
			var fm: Resource = _members[i]
			if fm != null and str(fm.id) == focus_id:
				_index = i
				return
	for i in _members.size():
		var m: Resource = _members[i]
		for p: Variant in GameState.party_members:
			if p != null and str(p.id) == str(m.id):
				_index = i
				return


func _current_member() -> Resource:
	if _index < 0 or _index >= _members.size():
		return null
	return _members[_index] as Resource


func _refresh_all() -> void:
	var member: Resource = _current_member()
	var can_nav: bool = _members.size() > 1
	_btn_prev.disabled = not can_nav
	_btn_next.disabled = not can_nav
	_RoyalMarkUiTokens.apply_chrome_button(_btn_prev, can_nav)
	_RoyalMarkUiTokens.apply_chrome_button(_btn_next, can_nav)
	if member == null:
		_portrait.texture = null
		_label_name.text = "対象キャラなし"
		_label_level.text = ""
		_label_rank.text = ""
		_set_emblem_for_rank(0)
		_set_stat_bonuses(0)
		_refresh_enhance_labels(null, 0)
		_refresh_path_panel(null, 0)
		_show_non_max_footer()
		_label_next_rank.text = "—"
		_label_next_effect.text = "—"
		_label_next_block.text = "—"
		_btn_shards.text = "王痕片 0 / —"
		_label_gold_cost.text = "Gold 0 / —"
		_set_status("roster に人間キャラがいません", true)
		_btn_upgrade.disabled = true
		_btn_upgrade.text = "王痕を刻む"
		_RoyalMarkUiTokens.apply_upgrade_button(_btn_upgrade, false)
		_apply_rank_track(0)
		return
	_set_portrait(member)
	_label_name.text = _GachaLimitBreak.format_member_name_plus(member)
	_label_level.text = "Lv.%d" % int(member.level)
	var rank: int = _RoyalMarkSystem.rank_of_member(member)
	_label_rank.text = _RoyalMarkConfig.rank_display(rank)
	_label_rank.add_theme_color_override("font_color", _RoyalMarkUiTokens.COLOR_GOLD_LIT)
	_set_emblem_for_rank(rank)
	_apply_rank_track(rank)
	_set_stat_bonuses(rank)
	_refresh_enhance_labels(member, rank)
	_refresh_path_panel(member, rank)
	var shards: int = _RoyalMarkSystem.get_shards()
	var gold: int = int(GameState.gold)
	if rank >= _RoyalMarkConfig.MAX_RANK:
		_show_max_footer(rank)
		return
	_show_non_max_footer()
	var next_rank: int = rank + 1
	var step: String = _RoyalMarkConfig.step_effect_label(next_rank)
	_label_next_rank.text = _RoyalMarkConfig.rank_display(next_rank)
	_label_next_effect.text = step
	_label_next_block.text = "%s\n%s" % [_label_next_rank.text, step]
	_label_next_rank.add_theme_color_override("font_color", _RoyalMarkUiTokens.COLOR_GOLD_LIT)
	_label_next_effect.add_theme_color_override("font_color", _RoyalMarkUiTokens.COLOR_BODY)
	var need_s: int = _RoyalMarkConfig.upgrade_shard_cost(rank)
	var need_g: int = _RoyalMarkConfig.upgrade_gold_cost(rank)
	var short_s: bool = shards < need_s
	var short_g: bool = gold < need_g
	_btn_shards.text = "王痕片 %d / %d" % [shards, need_s]
	_btn_shards.add_theme_stylebox_override(
		"normal", _RoyalMarkUiTokens.material_row_style(short_s)
	)
	_btn_shards.add_theme_color_override(
		"font_color",
		_RoyalMarkUiTokens.COLOR_SHORTAGE if short_s else _RoyalMarkUiTokens.COLOR_BODY
	)
	_label_gold_cost.text = "Gold %d / %d" % [gold, need_g]
	_label_gold_cost.add_theme_color_override(
		"font_color",
		_RoyalMarkUiTokens.COLOR_SHORTAGE if short_g else _RoyalMarkUiTokens.COLOR_SUB
	)
	if _gold_row_panel != null:
		_gold_row_panel.add_theme_stylebox_override(
			"panel", _RoyalMarkUiTokens.material_row_style(short_g)
		)
	var check: Dictionary = _RoyalMarkSystem.can_upgrade(member)
	if bool(check.get("ok", false)):
		_set_status("", false)
		_btn_upgrade.text = "王痕を刻む"
		_btn_upgrade.disabled = false
		_RoyalMarkUiTokens.apply_upgrade_button(_btn_upgrade, true)
		return
	_btn_upgrade.disabled = true
	_btn_upgrade.text = "王痕を刻む"
	_RoyalMarkUiTokens.apply_upgrade_button(_btn_upgrade, false)
	match str(check.get("reason", "")):
		"locked":
			_set_status("未解放（メイン1〜5 Normal CLEAR）", true)
			_btn_upgrade.text = "LOCKED"
		"level_gate":
			_set_status("Lv%d未満" % _RoyalMarkConfig.MIN_LEVEL, true)
		"need_shards":
			_set_status("王痕片不足", true)
		"need_gold":
			_set_status("Gold不足", true)
		"max_rank":
			_show_max_footer(rank)
		"not_owned":
			_set_status("未所持", true)
		_:
			_set_status("強化不可", true)


func _show_max_footer(rank: int) -> void:
	_panel_next.visible = false
	_btn_upgrade.visible = false
	_btn_upgrade.disabled = true
	_btn_upgrade.text = "王痕を刻む"
	_RoyalMarkUiTokens.apply_upgrade_button(_btn_upgrade, false)
	_panel_status.visible = false
	_label_status.text = "王痕 MAX"
	_panel_max.visible = true
	_label_max_title.text = _RoyalMarkConfig.rank_display(rank)
	_label_max_sub.text = _RoyalMarkConfig.next_rank_effect_label(rank)


func _show_non_max_footer() -> void:
	_panel_next.visible = true
	_btn_upgrade.visible = true
	_panel_max.visible = false


func _set_stat_bonuses(rank: int) -> void:
	_label_stat_hp.text = _RoyalMarkUiTokens.format_stat_bonus(_RoyalMarkConfig.hp_mult_for_rank(rank))
	_label_stat_atk.text = _RoyalMarkUiTokens.format_stat_bonus(_RoyalMarkConfig.atk_mult_for_rank(rank))
	_label_stat_def.text = _RoyalMarkUiTokens.format_stat_bonus(_RoyalMarkConfig.def_mult_for_rank(rank))
	var body: Color = _RoyalMarkUiTokens.COLOR_BODY
	_label_stat_hp.add_theme_color_override("font_color", body)
	_label_stat_atk.add_theme_color_override("font_color", body)
	_label_stat_def.add_theme_color_override("font_color", body)


func _set_status(text: String, shortage: bool) -> void:
	_label_status.text = text
	_panel_status.visible = not text.is_empty()
	_label_status.add_theme_color_override(
		"font_color",
		_RoyalMarkUiTokens.COLOR_SHORTAGE if shortage else _RoyalMarkUiTokens.COLOR_SUB
	)


func _set_emblem_for_rank(rank: int) -> void:
	if _emblem == null:
		return
	var path: String = _RoyalMarkUiTokens.emblem_path_for_rank(rank)
	if ResourceLoader.exists(path):
		_emblem.texture = load(path) as Texture2D
	var is_max: bool = rank >= _RoyalMarkConfig.MAX_RANK
	var host: float = (
		_RoyalMarkUiTokens.EMBLEM_HOST_RANK5 if is_max else _RoyalMarkUiTokens.EMBLEM_HOST_BASE
	)
	var icon: float = (
		_RoyalMarkUiTokens.EMBLEM_SIZE_RANK5 if is_max else _RoyalMarkUiTokens.EMBLEM_SIZE_BASE
	)
	if _emblem_host != null:
		_emblem_host.custom_minimum_size = Vector2(0, host)
	if _emblem_stack != null:
		_emblem_stack.custom_minimum_size = Vector2(host, host)
	_emblem.custom_minimum_size = Vector2(icon, icon)
	_emblem.modulate = Color(1.12, 1.08, 0.92, 1.0) if is_max else Color.WHITE
	if _emblem_glow != null and is_max:
		_emblem_glow.color = Color(0.95, 0.82, 0.35, 0.18)
	elif _emblem_glow != null:
		_emblem_glow.color = Color(0.86, 0.74, 0.45, 0.0)
	if _emblem_frame != null:
		var sb: StyleBoxFlat = _RoyalMarkUiTokens.info_panel_style()
		if is_max:
			sb.border_color = _RoyalMarkUiTokens.COLOR_GOLD_LIT
			sb.set_border_width_all(3)
		elif rank >= _RoyalMarkConfig.SKILL_ENHANCE_MIN_RANK:
			sb.border_color = _RoyalMarkUiTokens.COLOR_GOLD
			sb.set_border_width_all(2)
		_emblem_frame.add_theme_stylebox_override("panel", sb)


func _refresh_enhance_labels(member: Resource, rank: int) -> void:
	if _label_special_iii == null or _label_special_v == null:
		return
	## III
	if rank < _RoyalMarkConfig.SKILL_ENHANCE_MIN_RANK:
		_label_special_iii.text = "III　装備スキル強化　🔒"
		_label_special_iii.add_theme_color_override("font_color", _RoyalMarkUiTokens.COLOR_MUTED)
	else:
		var skill_ids: Array[String] = []
		if member != null:
			skill_ids = GameState.get_equipped_skill_ids(member)
		var skill_id: String = skill_ids[0] if not skill_ids.is_empty() else ""
		var skill_data: Resource = (
			DataRegistry.get_skill_data(skill_id) if not skill_id.is_empty() else null
		)
		var skill_name: String = str(skill_data.display_name) if skill_data != null else "—"
		var skill_lines: PackedStringArray = _RoyalMarkSkillModifier.describe_job_skill_enhance(
			skill_data, member
		)
		var boost: String = _format_boost_lines(skill_lines)
		var path: String = _RoyalMarkSystem.path_of_member(member) if member != null else ""
		var iii_prefix: String = "III　装備スキル強化"
		if path == _RoyalMarkConfig.PATH_TECHNIQUE:
			iii_prefix = "III　技巧"
		elif path == _RoyalMarkConfig.PATH_OFFENSE or path == _RoyalMarkConfig.PATH_DEFENSE:
			iii_prefix = "III　方針（装備強化なし）"
		if boost.is_empty() or boost == "—":
			_label_special_iii.text = "%s　%s" % [iii_prefix, skill_name]
		else:
			_label_special_iii.text = "%s　%s\n%s" % [iii_prefix, skill_name, boost]
		_label_special_iii.add_theme_color_override("font_color", _RoyalMarkUiTokens.COLOR_BODY)
	## V
	if rank < _RoyalMarkConfig.ULTIMATE_ENHANCE_MIN_RANK:
		_label_special_v.text = "V　必殺技強化　🔒"
		_label_special_v.add_theme_color_override("font_color", _RoyalMarkUiTokens.COLOR_MUTED)
	else:
		var ult: Resource = null
		if member != null:
			ult = _UltimateSkillResolver.resolve_ultimate_skill(member)
		var ult_name: String = str(ult.display_name) if ult != null else "—"
		var ult_lines: PackedStringArray = _RoyalMarkSkillModifier.describe_ultimate_enhance(ult)
		var ult_boost: String = _format_boost_lines(ult_lines)
		if ult_boost.is_empty() or ult_boost == "—":
			_label_special_v.text = "V　必殺技強化　%s" % ult_name
		else:
			_label_special_v.text = "V　必殺技強化　%s\n%s" % [ult_name, ult_boost]
		_label_special_v.add_theme_color_override("font_color", _RoyalMarkUiTokens.COLOR_BODY)


func _refresh_path_panel(member: Resource, rank: int) -> void:
	if _panel_path == null:
		return
	if member == null or rank < _RoyalMarkConfig.PATH_MIN_RANK:
		_panel_path.visible = false
		return
	_panel_path.visible = true
	var path: String = _RoyalMarkSystem.path_of_member(member)
	var path_name: String = _RoyalMarkConfig.path_display_name(path)
	var summary: String = _RoyalMarkConfig.path_effect_summary(path, rank)
	if path == _RoyalMarkConfig.PATH_UNSELECTED:
		_label_path_current.text = "現在: 未選択"
		_label_path_hint.text = "方針を選んでください（無料・何度でも変更可）"
		_label_path_current.add_theme_color_override("font_color", _RoyalMarkUiTokens.COLOR_GOLD_LIT)
	else:
		_label_path_current.text = "現在: %s　%s" % [path_name, summary]
		_label_path_hint.text = "攻勢: 与ダメ／守勢: 被ダメ減／技巧: Job強化"
		_label_path_current.add_theme_color_override("font_color", _RoyalMarkUiTokens.COLOR_BODY)
	var allowed: bool = _RoyalMarkSystem.is_path_change_allowed()
	_btn_path_offense.disabled = not allowed
	_btn_path_defense.disabled = not allowed
	_btn_path_technique.disabled = not allowed
	_RoyalMarkUiTokens.apply_chrome_button(_btn_path_offense, allowed)
	_RoyalMarkUiTokens.apply_chrome_button(_btn_path_defense, allowed)
	_RoyalMarkUiTokens.apply_chrome_button(_btn_path_technique, allowed)
	if not allowed:
		_label_path_hint.text = "ダンジョン中は方針変更不可"
	## 技巧＋excluded 警告
	var show_ex: bool = false
	if path == _RoyalMarkConfig.PATH_TECHNIQUE or path == _RoyalMarkConfig.PATH_UNSELECTED:
		var skill_ids: Array[String] = GameState.get_equipped_skill_ids(member)
		var skill_id: String = skill_ids[0] if not skill_ids.is_empty() else ""
		var skill_data: Resource = (
			DataRegistry.get_skill_data(skill_id) if not skill_id.is_empty() else null
		)
		if path == _RoyalMarkConfig.PATH_TECHNIQUE and _RoyalMarkSkillModifier.is_excluded_skill(skill_data):
			show_ex = true
	_label_path_excluded.visible = show_ex
	if show_ex:
		_label_path_excluded.text = "現在の装備スキルは技巧強化の対象外です"


func _on_path_pressed(path_id: String) -> void:
	if _busy:
		return
	var member: Resource = _current_member()
	if member == null:
		return
	var check: Dictionary = _RoyalMarkSystem.can_set_path(member, path_id)
	if not bool(check.get("ok", false)):
		_refresh_all()
		return
	var pname: String = _RoyalMarkConfig.path_display_name(path_id)
	_show_confirm(
		"方針を変更",
		"%s を「%s」にしますか？\n（無料・いつでも変更可／未選択には戻せません）" % [
			str(member.display_name),
			pname,
		],
		_on_path_confirmed.bind(path_id)
	)


func _on_path_confirmed(path_id: String) -> void:
	if _busy:
		return
	_busy = true
	var member: Resource = _current_member()
	var result: Dictionary = _RoyalMarkSystem.apply_path(member, path_id)
	_busy = false
	if not bool(result.get("ok", false)):
		_refresh_all()
		return
	SaveManager.save_game()
	_refresh_all()


func _format_boost_lines(lines: PackedStringArray) -> String:
	if lines.is_empty():
		return "—"
	return "\n".join(lines)


func _apply_rank_track(rank: int) -> void:
	var next_r: int = rank + 1 if rank < _RoyalMarkConfig.MAX_RANK else -1
	for i in _rank_nodes.size():
		var r: int = i + 1
		var lit: bool = r <= rank
		var is_next: bool = r == next_r
		var is_skill: bool = r == _RoyalMarkConfig.SKILL_ENHANCE_MIN_RANK
		var is_ult: bool = r == _RoyalMarkConfig.ULTIMATE_ENHANCE_MIN_RANK
		var node: Label = _rank_nodes[i]
		if is_ult:
			node.text = "★" if lit else "☆"
		elif is_skill:
			node.text = "◆" if lit else "◇"
		elif is_next:
			node.text = "◎"
		else:
			node.text = "●" if lit else "○"
		var col: Color = _RoyalMarkUiTokens.COLOR_MUTED
		if lit:
			col = (
				_RoyalMarkUiTokens.COLOR_GOLD_LIT
				if (is_skill or is_ult)
				else _RoyalMarkUiTokens.COLOR_GOLD
			)
		elif is_next:
			col = _RoyalMarkUiTokens.COLOR_GOLD_LIT
		elif is_skill or is_ult:
			col = _RoyalMarkUiTokens.COLOR_GOLD_DIM
		node.add_theme_color_override("font_color", col)
		if i < _rank_labels.size():
			var lc: Color = _RoyalMarkUiTokens.COLOR_MUTED
			if lit:
				lc = (
					_RoyalMarkUiTokens.COLOR_GOLD_LIT
					if (is_skill or is_ult)
					else _RoyalMarkUiTokens.COLOR_GOLD
				)
			elif is_next:
				lc = _RoyalMarkUiTokens.COLOR_GOLD_LIT
			elif is_skill or is_ult:
				lc = _RoyalMarkUiTokens.COLOR_GOLD
			_rank_labels[i].add_theme_color_override("font_color", lc)
	for i in _rank_connectors.size():
		var lit_c: bool = (i + 1) < rank
		var next_c: bool = (i + 1) == rank and next_r > 0
		(_rank_connectors[i] as Label).add_theme_color_override(
			"font_color",
			(
				_RoyalMarkUiTokens.COLOR_GOLD
				if lit_c
				else (_RoyalMarkUiTokens.COLOR_GOLD_DIM if next_c else _RoyalMarkUiTokens.COLOR_MUTED)
			)
		)


func _set_portrait(member: Resource) -> void:
	var idle: Array[Texture2D] = _ChrIdlePortrait.load_idle_textures_for_member(member)
	if not idle.is_empty():
		_portrait.texture = idle[0]
		return
	_portrait.texture = RosterUiHelper.get_member_portrait_texture(member)


func _on_prev_pressed() -> void:
	if _members.size() <= 1:
		return
	_index = (_index - 1 + _members.size()) % _members.size()
	_refresh_all()


func _on_next_pressed() -> void:
	if _members.size() <= 1:
		return
	_index = (_index + 1) % _members.size()
	_refresh_all()


func _on_back_pressed() -> void:
	var member: Resource = _current_member()
	if member != null:
		GameState.equipment_focus_member_id = str(member.id)
	SceneRouter.change_scene(HOME_SCENE)


func _on_shards_help_pressed() -> void:
	_show_help_overlay()


func _on_upgrade_pressed() -> void:
	if _busy:
		return
	var member: Resource = _current_member()
	var check: Dictionary = _RoyalMarkSystem.can_upgrade(member)
	if not bool(check.get("ok", false)):
		_refresh_all()
		return
	_show_confirm(
		"王痕を刻む",
		"%s を %s へ強化しますか？\n片%d／Gold %d" % [
			str(member.display_name),
			_RoyalMarkConfig.rank_display(int(check.get("next_rank", 0))),
			int(check.get("need_shards", 0)),
			int(check.get("need_gold", 0)),
		],
		_on_upgrade_confirmed
	)


func _on_upgrade_confirmed() -> void:
	if _busy:
		return
	_busy = true
	var member: Resource = _current_member()
	var result: Dictionary = _RoyalMarkSystem.apply_upgrade(member)
	if not bool(result.get("ok", false)):
		_busy = false
		_refresh_all()
		return
	SaveManager.save_game()
	_refresh_all()
	_play_success_fx(int(result.get("rank", _RoyalMarkSystem.rank_of_member(member))))
	_busy = false


func _play_success_fx(rank: int) -> void:
	_apply_rank_track(rank)
	_set_emblem_for_rank(rank)
	if _emblem_glow == null:
		return
	var tw := create_tween()
	_emblem_glow.color = Color(0.95, 0.82, 0.35, 0.55)
	tw.tween_property(_emblem_glow, "color:a", 0.0 if rank < _RoyalMarkConfig.MAX_RANK else 0.18, 0.35)
	if _emblem != null:
		var tw2 := create_tween()
		_emblem.modulate = Color(1.35, 1.2, 0.85, 1.0)
		var end_m: Color = Color(1.12, 1.08, 0.92, 1.0) if rank >= _RoyalMarkConfig.MAX_RANK else Color.WHITE
		tw2.tween_property(_emblem, "modulate", end_m, 0.4)


func _build_confirm_overlay() -> void:
	_confirm_overlay = Control.new()
	_confirm_overlay.visible = false
	_confirm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_overlay.z_index = 80
	add_child(_confirm_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.62)
	dim.gui_input.connect(_on_confirm_dim)
	_confirm_overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(480, 280)
	panel.offset_left = -240
	panel.offset_right = 240
	panel.offset_top = -140
	panel.offset_bottom = 140
	panel.add_theme_stylebox_override("panel", _RoyalMarkUiTokens.info_panel_style())
	_confirm_overlay.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	_confirm_title = Label.new()
	_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(_confirm_title, UiTypography.SIZE_BODY, _RoyalMarkUiTokens.COLOR_GOLD)
	v.add_child(_confirm_title)
	_confirm_body = Label.new()
	_confirm_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(
		_confirm_body, UiTypography.SIZE_BODY_SMALL, _RoyalMarkUiTokens.COLOR_BODY
	)
	v.add_child(_confirm_body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var btn_ok := Button.new()
	btn_ok.text = "刻む"
	btn_ok.custom_minimum_size = Vector2(140, 44)
	btn_ok.focus_mode = Control.FOCUS_NONE
	_RoyalMarkUiTokens.apply_upgrade_button(btn_ok, true)
	btn_ok.pressed.connect(_on_confirm_ok)
	row.add_child(btn_ok)
	var btn_cancel := Button.new()
	btn_cancel.text = "やめる"
	btn_cancel.custom_minimum_size = Vector2(140, 44)
	btn_cancel.focus_mode = Control.FOCUS_NONE
	_RoyalMarkUiTokens.apply_chrome_button(btn_cancel, true)
	btn_cancel.pressed.connect(_on_confirm_cancel)
	row.add_child(btn_cancel)


func _show_confirm(title: String, body: String, on_ok: Callable) -> void:
	_confirm_title.text = title
	_confirm_body.text = body
	_confirm_on_ok = on_ok
	_confirm_overlay.visible = true
	_confirm_overlay.move_to_front()


func _on_confirm_ok() -> void:
	var cb: Callable = _confirm_on_ok
	_confirm_overlay.visible = false
	_confirm_on_ok = Callable()
	if cb.is_valid():
		cb.call()


func _on_confirm_cancel() -> void:
	_confirm_overlay.visible = false
	_confirm_on_ok = Callable()


func _on_confirm_dim(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_confirm_cancel()


func _show_help_overlay() -> void:
	if _help_overlay != null and is_instance_valid(_help_overlay):
		_help_overlay.queue_free()
	_help_overlay = Control.new()
	_help_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_help_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_help_overlay.z_index = 70
	add_child(_help_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.62)
	dim.gui_input.connect(_on_help_dim_input)
	_help_overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 260)
	panel.offset_left = -250
	panel.offset_right = 250
	panel.offset_top = -130
	panel.offset_bottom = 130
	panel.add_theme_stylebox_override("panel", _RoyalMarkUiTokens.info_panel_style())
	_help_overlay.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var body := Label.new()
	body.text = SHARD_HELP_BODY
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(body, UiTypography.SIZE_BODY_SMALL, _RoyalMarkUiTokens.COLOR_BODY)
	v.add_child(body)
	var close := Button.new()
	close.text = "閉じる"
	close.custom_minimum_size = Vector2(0, 44)
	close.focus_mode = Control.FOCUS_NONE
	_RoyalMarkUiTokens.apply_chrome_button(close, true)
	close.pressed.connect(_close_help_overlay)
	v.add_child(close)


func _on_help_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_help_overlay()


func _close_help_overlay() -> void:
	if _help_overlay != null and is_instance_valid(_help_overlay):
		_help_overlay.queue_free()
	_help_overlay = null


func get_view_members_for_test() -> Array:
	return _members.duplicate()


func get_selected_index_for_test() -> int:
	return _index


func select_index_for_test(i: int) -> void:
	if _members.is_empty():
		return
	_index = clampi(i, 0, _members.size() - 1)
	_refresh_all()


func get_upgrade_button_for_test() -> Button:
	return _btn_upgrade


func get_status_text_for_test() -> String:
	## MAX 時は専用パネルへ移したため、互換で「王痕 MAX」を返す。
	if _panel_max != null and _panel_max.visible:
		return "王痕 MAX"
	return _label_status.text if _label_status != null else ""


func get_rank_display_for_test() -> String:
	return _label_rank.text if _label_rank != null else ""


func get_current_effect_for_test() -> String:
	var parts: PackedStringArray = PackedStringArray()
	if _label_stat_hp != null:
		parts.append("HP %s" % _label_stat_hp.text)
	if _label_stat_atk != null:
		parts.append("ATK %s" % _label_stat_atk.text)
	if _label_stat_def != null:
		parts.append("DEF %s" % _label_stat_def.text)
	return "\n".join(parts)


func get_next_reward_for_test() -> String:
	if _label_next_rank == null:
		return ""
	return "%s\n%s" % [_label_next_rank.text, _label_next_effect.text]


func get_special_preview_for_test() -> String:
	var a: String = _label_special_iii.text if _label_special_iii != null else ""
	var b: String = _label_special_v.text if _label_special_v != null else ""
	return "%s\n%s" % [a, b]


func get_path_panel_visible_for_test() -> bool:
	return _panel_path != null and _panel_path.visible


func get_path_current_text_for_test() -> String:
	return _label_path_current.text if _label_path_current != null else ""


func get_path_excluded_text_for_test() -> String:
	if _label_path_excluded == null or not _label_path_excluded.visible:
		return ""
	return _label_path_excluded.text


func get_path_buttons_disabled_for_test() -> bool:
	if _btn_path_offense == null:
		return true
	return _btn_path_offense.disabled


func get_max_panel_visible_for_test() -> bool:
	return _panel_max != null and _panel_max.visible


func get_max_state_text_for_test() -> String:
	if _label_max_title == null:
		return ""
	return "%s\n%s" % [_label_max_title.text, _label_max_sub.text]


func refresh_for_test() -> void:
	_reload_members()
	_refresh_all()
