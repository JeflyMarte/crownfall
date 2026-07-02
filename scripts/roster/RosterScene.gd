extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const EQUIPMENT_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const FORMATION_SLOT_COUNT: int = 4
const FORMATION_CELL_PX: int = 132
const ACTIVE_CARD_WIDTH: int = 158
const GRID_COLUMNS: int = 4

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_FRONT: Color = Color(0.55, 0.72, 0.95)
const COLOR_BACK: Color = Color(0.65, 0.85, 0.55)
const COLOR_EMPTY: Color = Color(0.35, 0.33, 0.30)
const COLOR_PICK: Color = Color(0.95, 0.78, 0.35)

const _FRONT_JOB_IDS: Array[String] = ["swordsman", "vanguard"]
const _RECOMMENDED_JOB_ORDER: Array[String] = [
	"vanguard", "swordsman", "ranger", "alchemist", "beast_tamer",
]
const _ROLE_FILTER_ORDER: Array[String] = ["all", "tank", "dps", "scout", "support"]

var _selected: Array = []
var _formation_slots: Array = [null, null, null, null]
var _formation_pick_slot: int = -1
var _active_pick_slot: int = -1
var _sort_by_rarity: bool = true
var _role_filter_index: int = 0
var _formation_cells: Array[PanelContainer] = []

@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _label_power: Label = $MainScroll/MainVBox/PowerRow/LabelPower
@onready var _active_party_row: HBoxContainer = $MainScroll/MainVBox/ActivePartyScroll/ActivePartyRow
@onready var _leader_strip: PanelContainer = $MainScroll/MainVBox/LeaderStrip
@onready var _roster_grid: GridContainer = $MainScroll/MainVBox/RosterGrid
@onready var _label_status: Label = $MainScroll/MainVBox/LabelStatus
@onready var _formation_overlay: CanvasLayer = $FormationOverlay
@onready var _formation_board: VBoxContainer = $FormationOverlay/FormationPanel/FormationVBox/FormationBoard
@onready var _button_save: Button = $FooterRow/ButtonSave

func _ready() -> void:
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.PARTY)
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	$MainScroll/MainVBox/PowerRow/ButtonRecommend.pressed.connect(_on_recommend_pressed)
	$MainScroll/MainVBox/PowerRow/ButtonFormation.pressed.connect(_open_formation_overlay)
	$MainScroll/MainVBox/ListHeader/ButtonSort.pressed.connect(_on_sort_pressed)
	$MainScroll/MainVBox/ListHeader/ButtonRoleFilter.pressed.connect(_on_role_filter_pressed)
	$FooterRow/ButtonReset.pressed.connect(_on_reset_pressed)
	$FooterRow/ButtonSave.pressed.connect(_on_save_pressed)
	$FormationOverlay/Dim.gui_input.connect(_on_formation_dim_input)
	$FormationOverlay/FormationPanel/FormationVBox/ButtonFormationClose.pressed.connect(_close_formation_overlay)
	$FormationOverlay/FormationPanel/FormationVBox/FormationPresetRow/ButtonPresetFront.pressed.connect(
		_on_formation_preset_pressed.bind("front")
	)
	$FormationOverlay/FormationPanel/FormationVBox/FormationPresetRow/ButtonPresetBalanced.pressed.connect(
		_on_formation_preset_pressed.bind("balanced")
	)
	$FormationOverlay/FormationPanel/FormationVBox/FormationPresetRow/ButtonPresetBack.pressed.connect(
		_on_formation_preset_pressed.bind("back")
	)
	_selected = GameState.party_members.duplicate()
	_init_formation_slots_from_party()
	_apply_panel_styles()
	_build_formation_grid()
	_refresh_all()

func _apply_panel_styles() -> void:
	_leader_strip.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	$FormationOverlay/FormationPanel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
	)

func _refresh_all() -> void:
	_update_currency()
	_refresh_power_label()
	_rebuild_active_party_row()
	_refresh_leader_strip()
	_rebuild_roster_grid()
	_refresh_formation_grid()
	_update_save_button()

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()

func _refresh_power_label() -> void:
	var members: Array = _active_members_in_slot_order()
	_label_power.text = "総合戦力 %s" % _format_number(RosterUiHelper.compute_combat_power(members))

func _format_number(value: int) -> String:
	var text: String = str(value)
	if text.length() <= 3:
		return text
	var out: String = ""
	while text.length() > 3:
		out = "," + text.substr(text.length() - 3, 3) + out
		text = text.substr(0, text.length() - 3)
	return text + out

func _init_formation_slots_from_party() -> void:
	for i in FORMATION_SLOT_COUNT:
		_formation_slots[i] = null
	for member in GameState.party_members:
		if member == null:
			continue
		var slot: int = GameState.get_member_formation_slot(member)
		if slot < 0 or slot >= FORMATION_SLOT_COUNT or _formation_slots[slot] != null:
			continue
		_formation_slots[slot] = member
	for i in mini(FORMATION_SLOT_COUNT, GameState.party_members.size()):
		if _formation_slots[i] == null:
			_formation_slots[i] = GameState.party_members[i]

func _sync_formation_slots_from_selection() -> void:
	var kept: Array = []
	for slot in _formation_slots:
		if slot != null and _selected.has(slot):
			kept.append(slot)
	for adv in _selected:
		if not kept.has(adv):
			kept.append(adv)
	while kept.size() < FORMATION_SLOT_COUNT:
		kept.append(null)
	for i in FORMATION_SLOT_COUNT:
		_formation_slots[i] = kept[i] if i < kept.size() else null
	_apply_formation_rows_from_slots()

func _active_members_in_slot_order() -> Array:
	var members: Array = []
	for i in FORMATION_SLOT_COUNT:
		var member: Resource = _formation_slots[i]
		if member != null and _selected.has(member):
			members.append(member)
	return members

func _party_index_for_member(member: Resource) -> int:
	for i in _selected.size():
		if _selected[i] == member:
			return i
	return -1

func _rebuild_active_party_row() -> void:
	for child in _active_party_row.get_children():
		child.queue_free()
	for slot_index in FORMATION_SLOT_COUNT:
		_active_party_row.add_child(_make_active_party_card(slot_index))

func _make_active_party_card(slot_index: int) -> Control:
	var member: Resource = _formation_slots[slot_index]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(ACTIVE_CARD_WIDTH, 0)
	panel.add_theme_stylebox_override(
		"panel",
		RosterUiHelper.card_panel_style(member != null, slot_index == 0)
	)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	if slot_index == 0:
		var leader := Label.new()
		leader.text = "リーダー"
		leader.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		leader.add_theme_font_size_override("font_size", 11)
		leader.add_theme_color_override("font_color", COLOR_GOLD)
		vbox.add_child(leader)
	if member == null:
		var empty := Label.new()
		empty.text = "空き"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(ACTIVE_CARD_WIDTH - 16, 160)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLOR_EMPTY)
		vbox.add_child(empty)
		panel.gui_input.connect(_on_active_card_input.bind(slot_index))
		return panel
	var portrait_tex: Texture2D = RosterUiHelper.get_member_portrait_texture(member)
	if portrait_tex != null:
		var portrait := TextureRect.new()
		portrait.texture = portrait_tex
		portrait.custom_minimum_size = Vector2(88, 88)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(portrait)
	var name_lbl := Label.new()
	name_lbl.text = RosterUiHelper.short_display_name(str(member.display_name))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_lbl)
	var stars := Label.new()
	stars.text = "%s  Lv%d" % [RosterUiHelper.stars_text(int(member.rarity)), int(member.level)]
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 12)
	stars.add_theme_color_override("font_color", COLOR_SUB)
	vbox.add_child(stars)
	var mods: Dictionary = JobStatCalculator.get_member_modifiers(member)
	var role: String = str(mods.get("role", ""))
	var role_lbl := Label.new()
	role_lbl.text = "%s %s" % [RosterUiHelper.role_glyph(role), RosterUiHelper.role_label(role)]
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(role_lbl)
	var stats: Dictionary = RosterUiHelper.compute_member_stats(member, _party_index_for_member(member))
	var stat_lbl := Label.new()
	stat_lbl.text = "%s\n%s\n%s" % [
		RosterUiHelper.stat_line("攻撃力", int(stats.get("attack", 0))),
		RosterUiHelper.stat_line("防御力", int(stats.get("defense", 0))),
		RosterUiHelper.stat_line("HP", int(stats.get("hp", 0))),
	]
	stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_lbl.add_theme_font_size_override("font_size", 11)
	stat_lbl.add_theme_color_override("font_color", COLOR_SUB)
	vbox.add_child(stat_lbl)
	var row_lbl := Label.new()
	var is_back: bool = GameState.get_member_formation_row(member) == GameState.FORMATION_BACK
	row_lbl.text = "後列" if is_back else "前列"
	row_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row_lbl.add_theme_font_size_override("font_size", 11)
	row_lbl.add_theme_color_override("font_color", COLOR_BACK if is_back else COLOR_FRONT)
	vbox.add_child(row_lbl)
	var detail := Button.new()
	detail.text = "詳細"
	detail.pressed.connect(_on_detail_pressed.bind(member))
	vbox.add_child(detail)
	panel.gui_input.connect(_on_active_card_input.bind(slot_index))
	if _active_pick_slot == slot_index:
		panel.add_theme_stylebox_override("panel", _pick_style())
	return panel

func _pick_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.05, 0.94)
	style.border_color = COLOR_PICK
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style

func _on_active_card_input(event: InputEvent, slot_index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _formation_slots[slot_index] == null:
		return
	if _active_pick_slot < 0:
		_active_pick_slot = slot_index
	else:
		if _active_pick_slot != slot_index:
			var tmp = _formation_slots[_active_pick_slot]
			_formation_slots[_active_pick_slot] = _formation_slots[slot_index]
			_formation_slots[slot_index] = tmp
			_apply_formation_rows_from_slots()
		_active_pick_slot = -1
	_rebuild_active_party_row()

func _on_detail_pressed(member: Resource) -> void:
	var party: Array = _ordered_party_from_formation()
	if not GameState.set_active_party(party):
		_label_status.text = "詳細を開くには有効な編成が必要です"
		return
	var roster: Array = GameState.get_roster()
	var roster_idx: int = roster.find(member)
	if roster_idx < 0:
		roster_idx = 0
	GameState.equipment_focus_member_index = roster_idx
	SceneRouter.change_scene(EQUIPMENT_SCENE)

func _refresh_leader_strip() -> void:
	for child in _leader_strip.get_children():
		child.queue_free()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_leader_strip.add_child(row)
	var crown := Label.new()
	crown.text = "♛"
	crown.add_theme_font_size_override("font_size", 28)
	crown.add_theme_color_override("font_color", COLOR_GOLD)
	crown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(crown)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var leader: Resource = _formation_slots[0]
	if leader == null:
		var empty_title := Label.new()
		empty_title.text = "リーダー未設定"
		empty_title.add_theme_font_size_override("font_size", 14)
		empty_title.add_theme_color_override("font_color", COLOR_GOLD)
		info.add_child(empty_title)
		var empty_desc := Label.new()
		empty_desc.text = "編成の先頭スロットにキャラを配置してください。"
		empty_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_desc.add_theme_font_size_override("font_size", 12)
		empty_desc.add_theme_color_override("font_color", COLOR_SUB)
		info.add_child(empty_desc)
		return
	var skill: Dictionary = RosterUiHelper.leader_skill_display(leader)
	var title := Label.new()
	title.text = "%s — %s" % [
		RosterUiHelper.short_display_name(str(leader.display_name)),
		str(skill.get("name", "—")),
	]
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	info.add_child(title)
	var desc := Label.new()
	desc.text = str(skill.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", COLOR_SUB)
	info.add_child(desc)
	var hint := Label.new()
	hint.text = "※戦闘効果はパッシブとして既存配線。先頭スロット入替でリーダー変更。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.5, 0.48, 0.42))
	info.add_child(hint)

func _rebuild_roster_grid() -> void:
	for child in _roster_grid.get_children():
		child.queue_free()
	var roster: Array = GameState.get_roster().duplicate()
	roster = roster.filter(func(adv: Resource) -> bool: return _passes_role_filter(adv))
	roster.sort_custom(func(a: Resource, b: Resource) -> bool: return _sort_roster_cmp(a, b))
	for adv in roster:
		_roster_grid.add_child(_make_roster_grid_card(adv))
	if roster.is_empty():
		var empty := Label.new()
		empty.text = "該当キャラがいません"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLOR_SUB)
		_roster_grid.add_child(empty)

func _passes_role_filter(adv: Resource) -> bool:
	var filter_id: String = _ROLE_FILTER_ORDER[_role_filter_index]
	if filter_id == "all":
		return true
	var mods: Dictionary = JobStatCalculator.get_member_modifiers(adv)
	return str(mods.get("role", "")) == filter_id

func _on_role_filter_pressed() -> void:
	_role_filter_index = (_role_filter_index + 1) % _ROLE_FILTER_ORDER.size()
	var filter_id: String = _ROLE_FILTER_ORDER[_role_filter_index]
	$MainScroll/MainVBox/ListHeader/ButtonRoleFilter.text = str(
		RosterUiHelper.ROLE_FILTER_LABELS.get(filter_id, filter_id)
	)
	_rebuild_roster_grid()

func _sort_roster_cmp(a: Resource, b: Resource) -> bool:
	if _sort_by_rarity:
		if int(a.rarity) != int(b.rarity):
			return int(a.rarity) > int(b.rarity)
		if int(a.level) != int(b.level):
			return int(a.level) > int(b.level)
	else:
		if int(a.level) != int(b.level):
			return int(a.level) > int(b.level)
		if int(a.rarity) != int(b.rarity):
			return int(a.rarity) > int(b.rarity)
	return str(a.display_name) < str(b.display_name)

func _make_roster_grid_card(adv: Resource) -> Control:
	var in_party: bool = _selected.has(adv)
	var wrapper := PanelContainer.new()
	wrapper.custom_minimum_size = Vector2(78, 118)
	wrapper.add_theme_stylebox_override("panel", RosterUiHelper.card_panel_style(in_party, false))
	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(_toggle_selection.bind(adv))
	wrapper.add_child(btn)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)
	var tex: Texture2D = RosterUiHelper.get_member_portrait_texture(adv)
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(52, 52)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if in_party:
			icon.modulate = Color(1, 1, 1, 0.78)
		vbox.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.text = RosterUiHelper.short_display_name(str(adv.display_name))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)
	var mods: Dictionary = JobStatCalculator.get_member_modifiers(adv)
	var role: String = str(mods.get("role", ""))
	var role_lbl := Label.new()
	role_lbl.text = "%s %s" % [RosterUiHelper.role_glyph(role), RosterUiHelper.role_label(role)]
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_lbl.add_theme_font_size_override("font_size", 10)
	role_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(role_lbl)
	var lv_lbl := Label.new()
	lv_lbl.text = "Lv%d" % int(adv.level)
	lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv_lbl.add_theme_font_size_override("font_size", 10)
	lv_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lv_lbl)
	var star_lbl := Label.new()
	star_lbl.text = RosterUiHelper.stars_text(int(adv.rarity))
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_lbl.add_theme_font_size_override("font_size", 9)
	star_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(star_lbl)
	if in_party:
		var badge := Label.new()
		badge.text = "編成中"
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 9)
		badge.add_theme_color_override("font_color", COLOR_GOLD)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(badge)
	return wrapper

func _toggle_selection(adv: Resource) -> void:
	if _selected.has(adv):
		if _selected.size() > 1:
			_selected.erase(adv)
	else:
		if _selected.size() < GameState.ACTIVE_PARTY_SIZE:
			_selected.append(adv)
	_sync_formation_slots_from_selection()
	_active_pick_slot = -1
	_refresh_all()

func _on_recommend_pressed() -> void:
	var roster: Array = GameState.get_roster()
	var picked: Array = []
	for job_id in _RECOMMENDED_JOB_ORDER:
		for adv in roster:
			if str(adv.job_id) == job_id and adv not in picked:
				picked.append(adv)
				break
	for adv in roster:
		if adv not in picked:
			picked.append(adv)
		if picked.size() >= GameState.ACTIVE_PARTY_SIZE:
			break
	_selected = picked.slice(0, mini(GameState.ACTIVE_PARTY_SIZE, picked.size()))
	_assign_formation_by_role(_selected, true)
	_active_pick_slot = -1
	_formation_pick_slot = -1
	_label_status.text = "おすすめ編成を適用しました"
	_refresh_all()

func _on_reset_pressed() -> void:
	var roster: Array = GameState.get_roster()
	_selected = []
	for i in mini(GameState.ACTIVE_PARTY_SIZE, roster.size()):
		_selected.append(roster[i])
	_place_members_in_slots(_selected, [0, 1, 2, 3])
	_apply_formation_rows_from_slots()
	_active_pick_slot = -1
	_formation_pick_slot = -1
	_label_status.text = "編成を初期状態に戻しました"
	_refresh_all()

func _on_sort_pressed() -> void:
	_sort_by_rarity = not _sort_by_rarity
	$MainScroll/MainVBox/ListHeader/ButtonSort.text = "レアリティ順" if _sort_by_rarity else "レベル順"
	_rebuild_roster_grid()

func _on_save_pressed() -> void:
	_sync_formation_slots_from_selection()
	_apply_formation_rows_from_slots()
	var party: Array = _ordered_party_from_formation()
	if not GameState.set_active_party(party):
		_label_status.text = "編成の変更に失敗しました（1〜%d名・重複不可）" % GameState.ACTIVE_PARTY_SIZE
		return
	SaveManager.save_game()
	_label_status.text = "編成を保存しました"

func _ordered_party_from_formation() -> Array:
	var ordered: Array = []
	for i in FORMATION_SLOT_COUNT:
		var member: Resource = _formation_slots[i]
		if member != null and _selected.has(member) and not ordered.has(member):
			ordered.append(member)
	for adv in _selected:
		if not ordered.has(adv):
			ordered.append(adv)
	return ordered

func _update_save_button() -> void:
	var count: int = _selected.size()
	_button_save.disabled = count < 1 or count > GameState.ACTIVE_PARTY_SIZE

func _open_formation_overlay() -> void:
	_sync_formation_slots_from_selection()
	_formation_pick_slot = -1
	_refresh_formation_grid()
	_formation_overlay.visible = true

func _close_formation_overlay() -> void:
	_formation_overlay.visible = false
	_formation_pick_slot = -1
	_refresh_formation_grid()
	_rebuild_active_party_row()
	_refresh_leader_strip()
	_refresh_power_label()

func _on_formation_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_formation_overlay()

func _build_formation_grid() -> void:
	for child in _formation_board.get_children():
		child.queue_free()
	_formation_cells.clear()
	_add_formation_row_label("— 前列 —", COLOR_FRONT)
	_formation_board.add_child(_make_formation_row(0, 1))
	_add_formation_row_label("— 後列 —", COLOR_BACK)
	_formation_board.add_child(_make_formation_row(2, 3))

func _add_formation_row_label(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	_formation_board.add_child(label)

func _make_formation_row(slot_a: int, slot_b: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(_make_formation_cell(slot_a))
	row.add_child(_make_formation_cell(slot_b))
	return row

func _make_formation_cell(slot_index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(FORMATION_CELL_PX, FORMATION_CELL_PX)
	panel.add_theme_stylebox_override("panel", _formation_cell_style(false, false))
	panel.gui_input.connect(_on_formation_cell_input.bind(slot_index))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_formation_cells.append(panel)
	return panel

func _formation_cell_style(active: bool, picked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.05, 0.94)
	if picked:
		style.border_color = COLOR_PICK
		style.set_border_width_all(3)
	elif active:
		style.border_color = COLOR_GOLD
		style.set_border_width_all(2)
	else:
		style.border_color = Color(0.45, 0.40, 0.32)
		style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	return style

func _on_formation_cell_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_formation_cell_pressed(slot_index)

func _on_formation_cell_pressed(slot_index: int) -> void:
	if _formation_pick_slot < 0:
		if _formation_slots[slot_index] == null:
			return
		_formation_pick_slot = slot_index
	else:
		if _formation_pick_slot != slot_index:
			var tmp = _formation_slots[_formation_pick_slot]
			_formation_slots[_formation_pick_slot] = _formation_slots[slot_index]
			_formation_slots[slot_index] = tmp
		_formation_pick_slot = -1
		_apply_formation_rows_from_slots()
	_refresh_formation_grid()

func _refresh_formation_grid() -> void:
	for i in _formation_cells.size():
		var panel: PanelContainer = _formation_cells[i]
		for child in panel.get_children():
			child.queue_free()
		panel.add_theme_stylebox_override(
			"panel", _formation_cell_style(i < 2, _formation_pick_slot == i)
		)
		var member: Resource = _formation_slots[i]
		if member == null:
			var empty := Label.new()
			empty.text = "空き"
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.set_anchors_preset(Control.PRESET_FULL_RECT)
			empty.add_theme_color_override("font_color", COLOR_EMPTY)
			panel.add_child(empty)
			continue
		var vbox := VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 3)
		var icon_tex: Texture2D = RosterUiHelper.get_member_portrait_texture(member)
		if icon_tex != null:
			var portrait := TextureRect.new()
			portrait.texture = icon_tex
			portrait.custom_minimum_size = Vector2(64, 64)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			vbox.add_child(portrait)
		var name_lbl := Label.new()
		name_lbl.text = RosterUiHelper.short_display_name(str(member.display_name))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(name_lbl)
		panel.add_child(vbox)

func _slot_row_for_index(slot_index: int) -> int:
	return GameState.FORMATION_FRONT if slot_index < 2 else GameState.FORMATION_BACK

func _apply_formation_rows_from_slots() -> void:
	for i in FORMATION_SLOT_COUNT:
		var member: Resource = _formation_slots[i]
		if member == null:
			continue
		GameState.set_member_formation_row(member, _slot_row_for_index(i))
		GameState.set_member_formation_slot(member, i)

func _on_formation_preset_pressed(preset: String) -> void:
	var members: Array = _collect_selected_members_for_formation()
	if members.is_empty():
		_label_status.text = "編成メンバーがいません"
		return
	match preset:
		"front":
			_assign_formation_by_role(members, true)
		"back":
			_assign_formation_by_role(members, false)
		_:
			_place_members_in_slots(members, [0, 1, 2, 3])
	_apply_formation_rows_from_slots()
	_formation_pick_slot = -1
	_refresh_formation_grid()
	_rebuild_active_party_row()

func _collect_selected_members_for_formation() -> Array:
	var members: Array = []
	for adv in _formation_slots:
		if adv != null:
			members.append(adv)
	if members.is_empty():
		members = _selected.duplicate()
	return members

func _assign_formation_by_role(members: Array, tanks_to_front_slots: bool) -> void:
	var tanks: Array = []
	var others: Array = []
	for m in members:
		if str(m.job_id) in _FRONT_JOB_IDS:
			tanks.append(m)
		else:
			others.append(m)
	var front_slots: Array = [0, 1]
	var back_slots: Array = [2, 3]
	var slots: Array = [null, null, null, null]
	if tanks_to_front_slots:
		_fill_slots_from_lists(slots, tanks, front_slots)
		_fill_slots_from_lists(slots, others, back_slots)
	else:
		_fill_slots_from_lists(slots, others, back_slots)
		_fill_slots_from_lists(slots, tanks, front_slots)
	_fill_slots_from_lists(slots, tanks + others, front_slots + back_slots)
	for i in FORMATION_SLOT_COUNT:
		_formation_slots[i] = slots[i]

func _fill_slots_from_lists(slots: Array, members: Array, open_slots: Array) -> void:
	for m in members:
		if slots.has(m):
			continue
		for slot_idx in open_slots:
			if slots[int(slot_idx)] == null:
				slots[int(slot_idx)] = m
				break

func _place_members_in_slots(members: Array, slot_order: Array) -> void:
	for i in FORMATION_SLOT_COUNT:
		_formation_slots[i] = null
	for i in mini(members.size(), slot_order.size()):
		_formation_slots[int(slot_order[i])] = members[i]

func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)

func _go_home() -> void:
	SceneRouter.change_scene(HOME_SCENE)

func _go_to(path: String) -> void:
	SceneRouter.change_scene(path)
