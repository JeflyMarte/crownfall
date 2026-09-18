extends Control

## 王痕育成専用画面（Decision 144 Phase 2）。表示・入力のみ。transaction は RoyalMarkSystem。

const _RoyalMarkConfig := preload("res://scripts/systems/RoyalMarkConfig.gd")
const _RoyalMarkSystem := preload("res://scripts/systems/RoyalMarkSystem.gd")
const _RoyalMarkSkillModifier := preload("res://scripts/systems/RoyalMarkSkillModifier.gd")
const _UltimateSkillResolver := preload("res://scripts/combat/UltimateSkillResolver.gd")
const _GachaLimitBreak := preload("res://scripts/gacha/GachaLimitBreak.gd")
const _ChrIdlePortrait := preload("res://scripts/ui/ChrIdlePortrait.gd")
const _SafeAreaHelper := preload("res://scripts/ui/SafeAreaHelper.gd")
const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const EMBLEM_TEX: String = "res://assets/ui/passives/ICO_PASSIVE_RoyalSwordDoctrine.png"
const GOLD_ICON: String = "res://assets/ui/batch2/ICO_Gold.png"

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_MUTED: Color = Color(0.45, 0.42, 0.38)
const COLOR_LIT: Color = Color(0.95, 0.82, 0.35)
const SHARD_HELP_BODY: String = (
	"王痕片\n極限任務の攻略によって獲得できる。\n"
	+ "極限指令を達成し、高い★評価を得ることで追加獲得できる。"
)

@onready var _root: VBoxContainer = $Root

var _members: Array = []
var _index: int = 0
var _busy: bool = false

var _btn_back: Button
var _label_title: Label
var _btn_prev: Button
var _btn_next: Button
var _portrait: TextureRect
var _label_name: Label
var _label_level: Label
var _label_rank: Label
var _emblem: TextureRect
var _emblem_glow: ColorRect
var _rank_nodes: Array[Control] = []
var _rank_labels: Array[Label] = []
var _label_current_effect: Label
var _label_skill_enhance: Label
var _label_ult_enhance: Label
var _label_next_block: Label
var _btn_shards: Button
var _label_gold_cost: Label
var _label_status: Label
var _btn_upgrade: Button

var _confirm_overlay: Control
var _confirm_title: Label
var _confirm_body: Label
var _confirm_on_ok: Callable = Callable()
var _help_overlay: Control


func _ready() -> void:
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
	_btn_back.custom_minimum_size = Vector2(44, 44)
	UiTypography.apply_menu_button(_btn_back, false)
	_btn_back.pressed.connect(_on_back_pressed)
	header.add_child(_btn_back)
	_label_title = Label.new()
	_label_title.text = "王痕育成"
	_label_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_screen_title(_label_title)
	header.add_child(_label_title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(44, 44)
	header.add_child(spacer)

	var char_row := HBoxContainer.new()
	char_row.add_theme_constant_override("separation", 8)
	char_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(char_row)
	_btn_prev = Button.new()
	_btn_prev.text = "◀"
	_btn_prev.custom_minimum_size = Vector2(48, 120)
	UiTypography.apply_menu_button(_btn_prev, false)
	_btn_prev.pressed.connect(_on_prev_pressed)
	char_row.add_child(_btn_prev)
	var char_col := VBoxContainer.new()
	char_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	char_col.add_theme_constant_override("separation", 4)
	char_row.add_child(char_col)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(140, 140)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	char_col.add_child(_portrait)
	_label_name = Label.new()
	_label_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(_label_name, UiTypography.SIZE_BODY, COLOR_GOLD)
	char_col.add_child(_label_name)
	_label_level = Label.new()
	_label_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(_label_level, COLOR_SUB)
	char_col.add_child(_label_level)
	_label_rank = Label.new()
	_label_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(_label_rank, UiTypography.SIZE_BODY_SMALL, COLOR_GOLD)
	char_col.add_child(_label_rank)
	_btn_next = Button.new()
	_btn_next.text = "▶"
	_btn_next.custom_minimum_size = Vector2(48, 120)
	UiTypography.apply_menu_button(_btn_next, false)
	_btn_next.pressed.connect(_on_next_pressed)
	char_row.add_child(_btn_next)

	var emblem_host := CenterContainer.new()
	emblem_host.custom_minimum_size = Vector2(0, 168)
	_root.add_child(emblem_host)
	var emblem_stack := Control.new()
	emblem_stack.custom_minimum_size = Vector2(160, 160)
	emblem_host.add_child(emblem_stack)
	_emblem_glow = ColorRect.new()
	_emblem_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_emblem_glow.color = Color(0.86, 0.74, 0.45, 0.0)
	_emblem_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblem_stack.add_child(_emblem_glow)
	var emblem_panel := PanelContainer.new()
	emblem_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	emblem_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	emblem_stack.add_child(emblem_panel)
	_emblem = TextureRect.new()
	_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_emblem.custom_minimum_size = Vector2(120, 120)
	if ResourceLoader.exists(EMBLEM_TEX):
		_emblem.texture = load(EMBLEM_TEX) as Texture2D
	emblem_panel.add_child(_emblem)

	var track := VBoxContainer.new()
	track.add_theme_constant_override("separation", 4)
	_root.add_child(track)
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 6)
	track.add_child(dots)
	var romans := HBoxContainer.new()
	romans.alignment = BoxContainer.ALIGNMENT_CENTER
	romans.add_theme_constant_override("separation", 6)
	track.add_child(romans)
	_rank_nodes.clear()
	_rank_labels.clear()
	for i in range(1, 6):
		if i > 1:
			var bar := Label.new()
			bar.text = "━"
			bar.custom_minimum_size = Vector2(28, 28)
			bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UiTypography.apply_caption(bar, COLOR_MUTED)
			dots.add_child(bar)
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(28, 1)
			romans.add_child(gap)
		var node := Label.new()
		node.text = "○"
		node.custom_minimum_size = Vector2(36, 28)
		node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTypography.apply_body(node, UiTypography.SIZE_BODY, COLOR_MUTED)
		dots.add_child(node)
		_rank_nodes.append(node)
		var rl := Label.new()
		rl.text = _RoyalMarkConfig.roman_for_rank(i)
		rl.custom_minimum_size = Vector2(36, 22)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTypography.apply_caption(rl, COLOR_SUB)
		romans.add_child(rl)
		_rank_labels.append(rl)

	var cur_panel := PanelContainer.new()
	cur_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	_root.add_child(cur_panel)
	var cur_v := VBoxContainer.new()
	cur_v.add_theme_constant_override("separation", 4)
	cur_panel.add_child(cur_v)
	var cur_title := Label.new()
	cur_title.text = "現在の効果"
	UiTypography.apply_caption(cur_title, COLOR_GOLD)
	cur_v.add_child(cur_title)
	_label_current_effect = Label.new()
	_label_current_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(_label_current_effect, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	cur_v.add_child(_label_current_effect)
	_label_skill_enhance = Label.new()
	_label_skill_enhance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(_label_skill_enhance, COLOR_SUB)
	cur_v.add_child(_label_skill_enhance)
	_label_ult_enhance = Label.new()
	_label_ult_enhance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(_label_ult_enhance, COLOR_SUB)
	cur_v.add_child(_label_ult_enhance)

	var next_panel := PanelContainer.new()
	next_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	_root.add_child(next_panel)
	var next_v := VBoxContainer.new()
	next_v.add_theme_constant_override("separation", 6)
	next_panel.add_child(next_v)
	var next_title := Label.new()
	next_title.text = "次の王痕"
	UiTypography.apply_caption(next_title, COLOR_GOLD)
	next_v.add_child(next_title)
	_label_next_block = Label.new()
	_label_next_block.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(_label_next_block, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	next_v.add_child(_label_next_block)
	_btn_shards = Button.new()
	_btn_shards.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_btn_shards.focus_mode = Control.FOCUS_NONE
	UiTypography.apply_menu_button(_btn_shards, false)
	_btn_shards.add_theme_font_size_override("font_size", UiTypography.SIZE_CAPTION)
	_btn_shards.pressed.connect(_on_shards_help_pressed)
	next_v.add_child(_btn_shards)
	_label_gold_cost = Label.new()
	UiTypography.apply_caption(_label_gold_cost, COLOR_SUB)
	next_v.add_child(_label_gold_cost)

	_label_status = Label.new()
	_label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(_label_status, COLOR_SUB)
	_root.add_child(_label_status)

	_btn_upgrade = Button.new()
	_btn_upgrade.text = "王痕を刻む"
	_btn_upgrade.custom_minimum_size = Vector2(0, 52)
	UiTypography.apply_menu_button(_btn_upgrade, true)
	_btn_upgrade.pressed.connect(_on_upgrade_pressed)
	_root.add_child(_btn_upgrade)


func _reload_members() -> void:
	_members = _RoyalMarkSystem.list_owned_eligible_members()
	if _members.is_empty():
		_index = 0
		return
	_index = clampi(_index, 0, _members.size() - 1)
	## パーティ先頭の人間がいれば優先。
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
	if member == null:
		_portrait.texture = null
		_label_name.text = "対象キャラなし"
		_label_level.text = ""
		_label_rank.text = ""
		_label_current_effect.text = "—"
		if _label_skill_enhance != null:
			_label_skill_enhance.text = ""
		if _label_ult_enhance != null:
			_label_ult_enhance.text = ""
		_label_next_block.text = "—"
		_btn_shards.text = "王痕片 0 / —"
		_label_gold_cost.text = "Gold 0 / —"
		_label_status.text = "roster に人間キャラがいません"
		_btn_upgrade.disabled = true
		_btn_upgrade.text = "王痕を刻む"
		_apply_rank_track(0)
		return
	_set_portrait(member)
	_label_name.text = _GachaLimitBreak.format_member_name_plus(member)
	_label_level.text = "Lv.%d" % int(member.level)
	var rank: int = _RoyalMarkSystem.rank_of_member(member)
	_label_rank.text = _RoyalMarkConfig.rank_display(rank)
	_apply_rank_track(rank)
	var lines: PackedStringArray = _RoyalMarkConfig.effect_stat_lines_for_rank(rank)
	_label_current_effect.text = "\n".join(lines)
	_refresh_enhance_labels(member, rank)
	var shards: int = _RoyalMarkSystem.get_shards()
	var gold: int = int(GameState.gold)
	if rank >= _RoyalMarkConfig.MAX_RANK:
		_label_next_block.text = "王痕 MAX"
		_btn_shards.text = "王痕片 %d / —" % shards
		_label_gold_cost.text = "Gold %d / —" % gold
		_label_status.text = "王痕 MAX"
		_btn_upgrade.text = "王痕 MAX"
		_btn_upgrade.disabled = true
		return
	var next_rank: int = rank + 1
	var step: String = _RoyalMarkConfig.step_effect_label(next_rank)
	_label_next_block.text = "%s\n%s" % [_RoyalMarkConfig.rank_display(next_rank), step]
	var need_s: int = _RoyalMarkConfig.upgrade_shard_cost(rank)
	var need_g: int = _RoyalMarkConfig.upgrade_gold_cost(rank)
	_btn_shards.text = "王痕片 %d / %d" % [shards, need_s]
	_label_gold_cost.text = "Gold %d / %d" % [gold, need_g]
	var check: Dictionary = _RoyalMarkSystem.can_upgrade(member)
	if bool(check.get("ok", false)):
		_label_status.text = ""
		_btn_upgrade.text = "王痕を刻む"
		_btn_upgrade.disabled = false
		return
	_btn_upgrade.disabled = true
	_btn_upgrade.text = "王痕を刻む"
	match str(check.get("reason", "")):
		"locked":
			_label_status.text = "未解放（メイン1〜5 Normal CLEAR）"
			_btn_upgrade.text = "LOCKED"
		"level_gate":
			_label_status.text = "Lv%d未満" % _RoyalMarkConfig.MIN_LEVEL
		"need_shards":
			_label_status.text = "王痕片不足"
		"need_gold":
			_label_status.text = "Gold不足"
		"max_rank":
			_label_status.text = "王痕 MAX"
			_btn_upgrade.text = "王痕 MAX"
		"not_owned":
			_label_status.text = "未所持"
		_:
			_label_status.text = "強化不可"


func _refresh_enhance_labels(member: Resource, rank: int) -> void:
	if _label_skill_enhance == null or _label_ult_enhance == null:
		return
	if rank < _RoyalMarkConfig.SKILL_ENHANCE_MIN_RANK:
		_label_skill_enhance.text = "装備スキル強化: 王痕 III で解放"
		_label_ult_enhance.text = "必殺技強化: 王痕 V で解放"
		return
	var skill_ids: Array[String] = GameState.get_equipped_skill_ids(member)
	var skill_id: String = skill_ids[0] if not skill_ids.is_empty() else ""
	var skill_data: Resource = (
		DataRegistry.get_skill_data(skill_id) if not skill_id.is_empty() else null
	)
	var skill_name: String = str(skill_data.display_name) if skill_data != null else "—"
	var skill_lines: PackedStringArray = _RoyalMarkSkillModifier.describe_job_skill_enhance(skill_data)
	_label_skill_enhance.text = "王痕 III\n装備スキル強化\n%s\n%s" % [
		skill_name,
		"\n".join(skill_lines),
	]
	if rank < _RoyalMarkConfig.ULTIMATE_ENHANCE_MIN_RANK:
		_label_ult_enhance.text = "必殺技強化: 王痕 V で解放"
		return
	var ult: Resource = _UltimateSkillResolver.resolve_ultimate_skill(member)
	var ult_name: String = str(ult.display_name) if ult != null else "—"
	var ult_lines: PackedStringArray = _RoyalMarkSkillModifier.describe_ultimate_enhance(ult)
	_label_ult_enhance.text = "王痕 V\n必殺技強化\n%s\n%s" % [
		ult_name,
		"\n".join(ult_lines),
	]


func _apply_rank_track(rank: int) -> void:
	for i in _rank_nodes.size():
		var lit: bool = (i + 1) <= rank
		var node: Label = _rank_nodes[i]
		node.text = "●" if lit else "○"
		var col: Color = COLOR_LIT if lit else COLOR_MUTED
		node.add_theme_color_override("font_color", col)
		if i < _rank_labels.size():
			_rank_labels[i].add_theme_color_override(
				"font_color", COLOR_GOLD if lit else COLOR_SUB
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
	if _emblem_glow == null:
		return
	var tw := create_tween()
	_emblem_glow.color = Color(0.95, 0.82, 0.35, 0.55)
	tw.tween_property(_emblem_glow, "color:a", 0.0, 0.35)
	if _emblem != null:
		var tw2 := create_tween()
		_emblem.modulate = Color(1.35, 1.2, 0.85, 1.0)
		tw2.tween_property(_emblem, "modulate", Color.WHITE, 0.4)


func _build_confirm_overlay() -> void:
	_confirm_overlay = Control.new()
	_confirm_overlay.visible = false
	_confirm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_overlay.z_index = 80
	add_child(_confirm_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.gui_input.connect(_on_confirm_dim)
	_confirm_overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(480, 280)
	panel.offset_left = -240
	panel.offset_right = 240
	panel.offset_top = -140
	panel.offset_bottom = 140
	panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	_confirm_overlay.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	_confirm_title = Label.new()
	_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(_confirm_title, UiTypography.SIZE_BODY, COLOR_GOLD)
	v.add_child(_confirm_title)
	_confirm_body = Label.new()
	_confirm_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(_confirm_body, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	v.add_child(_confirm_body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var btn_ok := Button.new()
	btn_ok.text = "刻む"
	btn_ok.custom_minimum_size = Vector2(140, 44)
	UiTypography.apply_menu_button(btn_ok, true)
	btn_ok.pressed.connect(_on_confirm_ok)
	row.add_child(btn_ok)
	var btn_cancel := Button.new()
	btn_cancel.text = "やめる"
	btn_cancel.custom_minimum_size = Vector2(140, 44)
	UiTypography.apply_menu_button(btn_cancel, false)
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
	dim.color = Color(0, 0, 0, 0.55)
	dim.gui_input.connect(_on_help_dim_input)
	_help_overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 260)
	panel.offset_left = -250
	panel.offset_right = 250
	panel.offset_top = -130
	panel.offset_bottom = 130
	panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	_help_overlay.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var body := Label.new()
	body.text = SHARD_HELP_BODY
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(body, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	v.add_child(body)
	var close := Button.new()
	close.text = "閉じる"
	close.custom_minimum_size = Vector2(0, 44)
	UiTypography.apply_menu_button(close, false)
	close.pressed.connect(_close_help_overlay)
	v.add_child(close)


func _on_help_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_help_overlay()


func _close_help_overlay() -> void:
	if _help_overlay != null and is_instance_valid(_help_overlay):
		_help_overlay.queue_free()
	_help_overlay = null


## テスト用: 表示中メンバー／切替対象一覧。
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
	return _label_status.text if _label_status != null else ""


func get_rank_display_for_test() -> String:
	return _label_rank.text if _label_rank != null else ""


func get_current_effect_for_test() -> String:
	return _label_current_effect.text if _label_current_effect != null else ""


func refresh_for_test() -> void:
	_reload_members()
	_refresh_all()
