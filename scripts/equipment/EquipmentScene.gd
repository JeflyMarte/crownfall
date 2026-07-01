extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const _AffixDisplayFormatter = preload("res://scripts/equipment/AffixDisplayFormatter.gd")
const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")
const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _ElementResolver = preload("res://scripts/combat/ElementResolver.gd")

# CombatController.BASE_MEMBER_HP と同値（表示用の素HP）。
const BASE_MEMBER_HP: int = 30
# クリティカルダメージ倍率（DungeonScene.CRITICAL_MULTIPLIER と同値）。
const CRIT_DAMAGE_MULT: float = 1.5
const GRID_COLUMNS: int = 6
const CELL_SIZE: Vector2 = Vector2(72, 72)
const SLOT_CELL_SIZE: Vector2 = Vector2(58, 58)

# レア度別の枠色（COMMON/RARE/EPIC/LEGENDARY）。
const RARITY_COLORS: Array[Color] = [
	Color(0.60, 0.60, 0.60),
	Color(0.30, 0.55, 0.95),
	Color(0.70, 0.45, 0.95),
	Color(0.95, 0.75, 0.25),
]
# レアリティ隅マーカー（COMMON/RARE/EPIC/LEGENDARY）。
const RARITY_GEMS: Array[String] = ["◇", "◆", "✦", "★"]

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_VALUE: Color = Color(0.94, 0.91, 0.83)
const COLOR_POS: Color = Color(0.55, 0.88, 0.5)
const COLOR_ACCENT: Color = Color(0.75, 0.82, 0.95, 1)

# ステータス／スロットのグリフ装飾。
const STAT_GLYPHS: Dictionary = {
	"hp": "❤", "attack": "⚔", "defense": "🛡",
	"speed": "💨", "crit_rate": "🎯", "crit_damage": "💥",
}
const EFFECT_GLYPHS: Dictionary = {
	"攻撃力": "⚔", "防御力": "🛡", "HP": "❤", "クリティカル率": "🎯",
}
const SLOT_GLYPHS: Dictionary = {"weapon": "⚔", "armor": "🛡", "accessory": "💍"}

@onready var _button_back: Button = $Header/HeaderRow/ButtonBack
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _btn_member_prev: Button = $VBoxContainer/CharacterCard/CardRow/PortraitBox/PortraitNavRow/BtnMemberPrev
@onready var _btn_member_next: Button = $VBoxContainer/CharacterCard/CardRow/PortraitBox/PortraitNavRow/BtnMemberNext
@onready var _member_row: HBoxContainer = $VBoxContainer/MemberSelectRow
@onready var _label_stars: Label = $VBoxContainer/CharacterCard/CardRow/PortraitBox/LabelStars
@onready var _portrait_art: TextureRect = $VBoxContainer/CharacterCard/CardRow/PortraitBox/PortraitNavRow/Portrait/PortraitArt
@onready var _portrait_glyph: Label = $VBoxContainer/CharacterCard/CardRow/PortraitBox/PortraitNavRow/Portrait/PortraitGlyph
@onready var _label_name: Label = $VBoxContainer/CharacterCard/CardRow/InfoBox/LabelName
@onready var _label_level: Label = $VBoxContainer/CharacterCard/CardRow/InfoBox/LabelLevel
@onready var _job_icon: TextureRect = $VBoxContainer/CharacterCard/CardRow/InfoBox/JobRow/JobIcon
@onready var _label_job: Label = $VBoxContainer/CharacterCard/CardRow/InfoBox/JobRow/LabelJob
@onready var _stats_grid: GridContainer = $VBoxContainer/CharacterCard/CardRow/InfoBox/StatsGrid
@onready var _button_unequip_all: Button = $VBoxContainer/CharacterCard/CardRow/SlotsPanel/ButtonUnequipAll
@onready var _slots_row: GridContainer = $VBoxContainer/CharacterCard/CardRow/SlotsPanel/EquipSlotsGrid
@onready var _btn_sort: Button = $VBoxContainer/TabContainer/TabEquip/EquipContent/InventoryHeaderRow/ButtonSort
@onready var _btn_filter: Button = $VBoxContainer/TabContainer/TabEquip/EquipContent/InventoryHeaderRow/ButtonFilter
@onready var _nav_forge: Button = $BottomNav/NavRow/NavForge
@onready var _character_card: PanelContainer = $VBoxContainer/CharacterCard
@onready var _tabs: TabContainer = $VBoxContainer/TabContainer
@onready var _effects_grid: GridContainer = $VBoxContainer/TabContainer/TabEquip/EquipContent/EffectsGrid
@onready var _category_row: HBoxContainer = $VBoxContainer/TabContainer/TabEquip/EquipContent/CategoryRow
@onready var _inventory_grid: GridContainer = $VBoxContainer/TabContainer/TabEquip/EquipContent/InventoryGrid
@onready var _skill_content: VBoxContainer = $VBoxContainer/TabContainer/TabSkill/SkillContent

var _combat_setup_panel: PanelContainer = null
var _combat_setup_content: VBoxContainer = null

var _selected_member_index: int = 0
var _inventory_filter: String = "all"
var _inventory_sort: String = "rarity"
var _inventory_equipped_filter: String = "all"
# 戦術セレクタ（P3-D086・スキルタブ上部に動的生成）
var _tactics_option: OptionButton = null
var _tactics_ids: Array[String] = []
var _gambit_custom_check: CheckBox = null
var _gambit_custom_box: VBoxContainer = null
var _gambit_target_option: OptionButton = null
var _gambit_target_ids: Array[String] = []
var _gambit_slot_opts: Array[OptionButton] = []
var _gambit_cond_opts: Array[OptionButton] = []
var _gambit_value_edits: Array[LineEdit] = []
var _gambit_range_opts: Array[OptionButton] = []
var _gambit_move_up_btns: Array[Button] = []
var _gambit_move_down_btns: Array[Button] = []
var _gambit_cond_hint_labels: Array[Label] = []
var _gambit_ui_syncing: bool = false
var _relic_option: OptionButton = null
var _relic_ids: Array[String] = []
var _preset_option: OptionButton = null
var _preset_name_edit: LineEdit = null
var _preset_rename_btn: Button = null
var _policy_option: OptionButton = null
var _policy_hint_label: Label = null
var _preset_feedback_panel: PanelContainer = null
var _preset_feedback_label: Label = null
var _preset_feedback_tween: Tween = null
const _POLICY_IDS: Array = ["", "safe", "material", "relic", "codex"]
var _tag_info_label: Label = null

func _ready() -> void:
	_tabs.set_tab_title(0, "装備")
	_tabs.set_tab_title(1, "スキル")
	_tabs.set_tab_title(2, "覚醒 🔒")
	_tabs.set_tab_title(3, "プロフィール 🔒")
	_tabs.get_tab_bar().set_tab_disabled(2, true)
	_tabs.get_tab_bar().set_tab_disabled(3, true)
	_member_row.visible = false
	_ensure_combat_setup_panel()
	_button_back.pressed.connect(_on_back_pressed)
	_btn_member_prev.pressed.connect(_on_member_prev_pressed)
	_btn_member_next.pressed.connect(_on_member_next_pressed)
	$BottomNav/NavRow/NavHome.pressed.connect(_go_to.bind(HOME_SCENE))
	$BottomNav/NavRow/NavParty.pressed.connect(_go_to.bind(ROSTER_SCENE))
	$BottomNav/NavRow/NavAdventure.pressed.connect(_go_to.bind(DUNGEON_SCENE))
	$BottomNav/NavRow/NavForge.pressed.connect(_go_to.bind(BLACKSMITH_SCENE))
	$BottomNav/NavRow/NavCodex.pressed.connect(_go_to.bind(CODEX_SCENE))
	$BottomNav/NavRow/NavShop.pressed.connect(_go_to.bind(GACHA_SCENE))
	_button_unequip_all.pressed.connect(_on_unequip_all_pressed)
	_btn_sort.pressed.connect(_on_sort_pressed)
	_btn_filter.pressed.connect(_on_filter_pressed)
	_connect_category_buttons()
	_inventory_grid.columns = GRID_COLUMNS
	_apply_panel_styles()
	_decorate_portrait()
	if GameState.equipment_focus_member_index >= 0:
		_selected_member_index = clampi(
			GameState.equipment_focus_member_index,
			0,
			maxi(0, GameState.party_members.size() - 1)
		)
		GameState.equipment_focus_member_index = -1
	_refresh_display()

func _on_sort_pressed() -> void:
	_inventory_sort = "name" if _inventory_sort == "rarity" else "rarity"
	_refresh_inventory_tools()
	_rebuild_inventory_grid()

func _on_filter_pressed() -> void:
	match _inventory_equipped_filter:
		"all":
			_inventory_equipped_filter = "equipped"
		"equipped":
			_inventory_equipped_filter = "unequipped"
		_:
			_inventory_equipped_filter = "all"
	_refresh_inventory_tools()
	_rebuild_inventory_grid()

func _refresh_inventory_tools() -> void:
	_btn_sort.text = str(EquipmentUiHelper.SORT_LABELS.get(_inventory_sort, _inventory_sort))
	_btn_filter.text = str(
		EquipmentUiHelper.EQUIPPED_FILTER_LABELS.get(_inventory_equipped_filter, _inventory_equipped_filter)
	)

func _apply_panel_styles() -> void:
	_character_card.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)

func _decorate_portrait() -> void:
	var p := $VBoxContainer/CharacterCard/CardRow/PortraitBox/PortraitNavRow/Portrait as PanelContainer
	if p != null:
		p.add_theme_stylebox_override("panel", _framed_box(COLOR_GOLD, 2, Color(0.06, 0.05, 0.04, 1.0)))
	_portrait_glyph.add_theme_font_size_override("font_size", 40)
	_portrait_glyph.add_theme_color_override("font_color", COLOR_GOLD)

func _connect_category_buttons() -> void:
	var defs: Array = [
		["ButtonCatAll", "all"],
		["ButtonCatWeapon", "weapon"],
		["ButtonCatArmor", "armor"],
		["ButtonCatAccessory", "accessory"],
	]
	for d in defs:
		var btn: Button = _category_row.get_node(d[0]) as Button
		btn.pressed.connect(_on_category_selected.bind(str(d[1])))

func _on_category_selected(filter_id: String) -> void:
	_inventory_filter = filter_id
	_refresh_category_buttons()
	_rebuild_inventory_grid()

func _refresh_category_buttons() -> void:
	var map: Dictionary = {
		"ButtonCatAll": "all",
		"ButtonCatWeapon": "weapon",
		"ButtonCatArmor": "armor",
		"ButtonCatAccessory": "accessory",
	}
	for node_name in map:
		var btn: Button = _category_row.get_node(node_name) as Button
		btn.button_pressed = (map[node_name] == _inventory_filter)

func _on_member_selected(member_index: int) -> void:
	_selected_member_index = member_index
	_refresh_display()

func _on_member_prev_pressed() -> void:
	_cycle_member(-1)

func _on_member_next_pressed() -> void:
	_cycle_member(1)

func _cycle_member(delta: int) -> void:
	var count: int = GameState.party_members.size()
	if count <= 0:
		return
	var next_index: int = (_selected_member_index + delta + count) % count
	_on_member_selected(next_index)

func _refresh_display() -> void:
	_update_header()
	_update_character_card()
	_rebuild_equip_slots()
	_rebuild_effects()
	_refresh_category_buttons()
	_refresh_inventory_tools()
	_rebuild_inventory_grid()
	_rebuild_skill_tab()
	_update_forge_nav_dot()

func _update_forge_nav_dot() -> void:
	_nav_forge.text = "鍛冶 ●" if BlacksmithUiHelper.has_craftable_recipes() else "鍛冶"

func _update_header() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()

# ---- キャラクターカード ----
func _update_character_card() -> void:
	var member: Resource = GameState.get_member(_selected_member_index)
	if member == null:
		_label_name.text = "—"
		_label_level.text = ""
		_label_job.text = ""
		_job_icon.texture = null
		_portrait_glyph.text = "?"
		return
	_label_name.text = member.display_name
	var job_mods: Dictionary = _JobStatCalculator.get_member_modifiers(member)
	var job_name: String = str(job_mods.get("display_name", member.job_id))
	_label_level.text = EquipmentUiHelper.level_line(int(member.level))
	_label_job.text = job_name
	_job_icon.texture = IconPaths.get_icon_texture(str(member.job_id), "chr")
	var chr_tex: Texture2D = RosterUiHelper.get_member_portrait_texture(member)
	_portrait_art.texture = chr_tex
	_portrait_glyph.text = "" if chr_tex != null else member.display_name.substr(0, 1)
	_label_stars.text = EquipmentUiHelper.stars_text(int(member.rarity))
	var stats: Dictionary = _compute_member_stats(_selected_member_index)
	_populate_stat_grid(stats)

func _populate_stat_grid(stats: Dictionary) -> void:
	for child in _stats_grid.get_children():
		child.queue_free()
	var rows: Array = [
		["hp", "HP", str(stats["hp"])],
		["attack", "攻撃力", str(stats["attack"])],
		["defense", "防御力", str(stats["defense"])],
		["speed", "速度", "%.1f" % stats["speed"]],
		["crit_rate", "会心率", "%.0f%%" % (stats["crit_rate"] * 100.0)],
		["crit_damage", "会心ダメ", "%.0f%%" % (stats["crit_damage"] * 100.0)],
	]
	for r in rows:
		_stats_grid.add_child(_make_dim_label(str(r[1])))
		_stats_grid.add_child(_make_value_label(str(r[2])))

func _make_dim_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", COLOR_SUB)
	return l

func _make_value_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", COLOR_VALUE)
	l.add_theme_font_size_override("font_size", 15)
	return l

func _make_pos_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", COLOR_POS)
	l.add_theme_font_size_override("font_size", 15)
	return l

# ---- 装備中の効果（装備品由来のボーナス集計） ----
func _rebuild_effects() -> void:
	for child in _effects_grid.get_children():
		child.queue_free()
	var idx: int = _selected_member_index
	var armor: Resource = GameState.get_member_equipped_armor(idx)
	var acc_data: Resource = _accessory_data(GameState.get_member_equipped_accessory(idx))
	var affix: Dictionary = _AffixStatCalculator.get_bonuses(idx)
	var atk_bonus: int = int(affix.get("attack_flat", 0)) + (acc_data.attack_bonus if acc_data != null else 0)
	var def_bonus: int = int(affix.get("defense_flat", 0)) + (acc_data.defense_bonus if acc_data != null else 0)
	if armor != null:
		def_bonus += armor.rolled_defense
	var hp_bonus: int = int(affix.get("hp_flat", 0)) + (acc_data.hp_bonus if acc_data != null else 0)
	if armor != null:
		hp_bonus += armor.hp_bonus
	var crit_bonus: float = float(affix.get("crit_rate_add", 0.0)) + (acc_data.crit_rate_bonus if acc_data != null else 0.0)
	var rows: Array = []
	if atk_bonus != 0:
		rows.append(["攻撃力", "+%d" % atk_bonus])
	if def_bonus != 0:
		rows.append(["防御力", "+%d" % def_bonus])
	if hp_bonus != 0:
		rows.append(["HP", "+%d" % hp_bonus])
	if not is_zero_approx(crit_bonus):
		rows.append(["クリティカル率", "+%.0f%%" % (crit_bonus * 100.0)])
	if rows.is_empty():
		_effects_grid.add_child(_make_dim_label("（装備ボーナスなし）"))
		return
	for r in rows:
		var glyph: String = str(EFFECT_GLYPHS.get(str(r[0]), "・"))
		_effects_grid.add_child(_make_dim_label("%s %s" % [glyph, r[0]]))
		_effects_grid.add_child(_make_pos_label(str(r[1])))

# ---- 装備スロット ----
func _rebuild_equip_slots() -> void:
	for child in _slots_row.get_children():
		child.queue_free()
	var idx: int = _selected_member_index
	_slots_row.add_child(_make_slot("武器", "weapon", GameState.get_member_equipped_weapon(idx)))
	_slots_row.add_child(_make_slot("防具", "armor", GameState.get_member_equipped_armor(idx)))
	_slots_row.add_child(_make_slot("装飾", "accessory", GameState.get_member_equipped_accessory(idx)))
	_slots_row.add_child(_make_locked_slot("足具"))

func _make_locked_slot(label: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var cap := Label.new()
	cap.text = label
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_color_override("font_color", COLOR_SUB)
	cap.add_theme_font_size_override("font_size", 11)
	box.add_child(cap)
	var btn := Button.new()
	btn.custom_minimum_size = SLOT_CELL_SIZE
	btn.disabled = true
	btn.text = "🔒"
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_stylebox_override(
		"disabled",
		_framed_box(Color(0.35, 0.33, 0.3, 0.55), 1, Color(0.08, 0.07, 0.05, 0.9))
	)
	box.add_child(btn)
	return box

func _make_slot(slot_label: String, category: String, item: Resource) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var cap := Label.new()
	cap.text = slot_label
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_color_override("font_color", COLOR_SUB)
	cap.add_theme_font_size_override("font_size", 11)
	box.add_child(cap)
	var btn := Button.new()
	btn.custom_minimum_size = SLOT_CELL_SIZE
	if item != null:
		var icon: Texture2D = _item_icon(item, category)
		if icon != null:
			btn.icon = icon
			btn.expand_icon = true
		btn.tooltip_text = _item_label(item, category)
		var rarity: int = _item_rarity(item, category)
		btn.add_theme_stylebox_override("normal", _rarity_box(rarity, false))
		btn.add_theme_stylebox_override("hover", _rarity_box(rarity, true))
		_apply_item_badges(btn, item, category, SLOT_CELL_SIZE, true)
	else:
		btn.text = str(SLOT_GLYPHS.get(category, "+"))
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35, 0.7))
		btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
		var empty_box: StyleBoxFlat = _framed_box(Color(0.45, 0.4, 0.3, 0.55), 1, Color(0.08, 0.07, 0.05, 0.9))
		btn.add_theme_stylebox_override("normal", empty_box)
		btn.add_theme_stylebox_override("hover", _framed_box(COLOR_GOLD, 2, Color(0.13, 0.11, 0.08, 1.0)))
	btn.pressed.connect(_on_slot_pressed.bind(category))
	box.add_child(btn)
	return box

func _on_slot_pressed(category: String) -> void:
	_inventory_filter = category
	_refresh_category_buttons()
	_rebuild_inventory_grid()
	_tabs.current_tab = 0

# ---- 所持一覧グリッド ----
func _rebuild_inventory_grid() -> void:
	for child in _inventory_grid.get_children():
		child.queue_free()
	var entries: Array = []
	if _inventory_filter == "all" or _inventory_filter == "weapon":
		for it in $EquipmentController.get_appraised_weapons():
			entries.append({"item": it, "category": "weapon"})
	if _inventory_filter == "all" or _inventory_filter == "armor":
		for it in $EquipmentController.get_appraised_armors():
			entries.append({"item": it, "category": "armor"})
	if _inventory_filter == "all" or _inventory_filter == "accessory":
		for it in $EquipmentController.get_appraised_accessories():
			entries.append({"item": it, "category": "accessory"})
	entries = EquipmentUiHelper.filter_by_equipped_state(
		entries, _inventory_equipped_filter, _selected_member_index
	)
	if entries.is_empty():
		_inventory_grid.add_child(_make_dim_label("該当する装備がありません"))
		return
	for e in EquipmentUiHelper.sort_inventory_entries(entries, _inventory_sort):
		_inventory_grid.add_child(_make_item_cell(e["item"], str(e["category"])))

func _make_item_cell(item: Resource, category: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = CELL_SIZE
	var icon: Texture2D = _item_icon(item, category)
	if icon != null:
		btn.icon = icon
		btn.expand_icon = true
	var rarity: int = _item_rarity(item, category)
	var owner_idx: int = EquipmentUiHelper.equipped_member_index(item)
	var is_on_self: bool = owner_idx == _selected_member_index
	btn.tooltip_text = "%s  %s" % [_item_label(item, category), _compare_text(item, category)]
	if owner_idx >= 0 and not is_on_self:
		var owner: Resource = GameState.get_member(owner_idx)
		if owner != null:
			btn.tooltip_text += "（%s装備中）" % str(owner.display_name)
	btn.pressed.connect(_on_cell_pressed.bind(item, category))
	if is_on_self:
		btn.disabled = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.modulate = Color(0.72, 0.72, 0.72, 0.85)
		btn.add_theme_stylebox_override("disabled", _rarity_box(rarity, true))
	else:
		btn.add_theme_stylebox_override("normal", _rarity_box(rarity, false))
		btn.add_theme_stylebox_override("hover", _rarity_box(rarity, true))
	_apply_item_badges(btn, item, category, CELL_SIZE, is_on_self)
	if owner_idx >= 0:
		_add_owner_portrait_badge(btn, owner_idx)
	return btn

func _add_owner_portrait_badge(btn: Button, owner_idx: int) -> void:
	var member: Resource = GameState.get_member(owner_idx)
	if member == null:
		return
	var tex: Texture2D = IconPaths.get_icon_texture(str(member.job_id), "chr")
	if tex == null:
		return
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = Vector2(16, 16)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(CELL_SIZE.x - 18.0, 2.0)
	btn.add_child(icon)

func _on_cell_pressed(item: Resource, category: String) -> void:
	match category:
		"weapon":
			$EquipmentController.equip_weapon(item, _selected_member_index)
		"armor":
			$EquipmentController.equip_armor(item, _selected_member_index)
		"accessory":
			$EquipmentController.equip_accessory(item, _selected_member_index)
	_refresh_display()

func _on_unequip_all_pressed() -> void:
	$EquipmentController.unequip_weapon(_selected_member_index)
	$EquipmentController.unequip_armor(_selected_member_index)
	$EquipmentController.unequip_accessory(_selected_member_index)
	_refresh_display()

# ---- レア度枠スタイル ----
func _rarity_box(rarity: int, highlight: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	var col: Color = RARITY_COLORS[clampi(rarity, 0, RARITY_COLORS.size() - 1)]
	sb.bg_color = Color(0.10, 0.09, 0.07, 0.95) if not highlight else Color(0.20, 0.18, 0.13, 1.0)
	sb.set_border_width_all(3 if highlight else 2)
	sb.border_color = col if not highlight else col.lerp(Color.WHITE, 0.25)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(4.0)
	if highlight:
		sb.shadow_color = Color(col.r, col.g, col.b, 0.5)
		sb.shadow_size = 4
	return sb

# 汎用の額縁スタイル（枠色・枠幅・地色を指定）。
func _framed_box(border: Color, width: int, bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(width)
	sb.border_color = border
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(4.0)
	return sb

# ボタン隅にバッジ（レアリティ / 装備中 / 炉研ぎ）を重ねる。
func _apply_item_badges(
	btn: Button,
	item: Resource,
	category: String,
	size: Vector2,
	is_equipped: bool
) -> void:
	var rarity: int = _item_rarity(item, category)
	var rarity_col: Color = RARITY_COLORS[clampi(rarity, 0, RARITY_COLORS.size() - 1)]
	_add_corner_badge(
		btn,
		EquipmentUiHelper.rarity_gem(rarity),
		rarity_col,
		Vector2(2.0, 1.0)
	)
	var enhance_text: String = EquipmentUiHelper.enhance_badge(item, category)
	if not enhance_text.is_empty():
		_add_corner_badge(btn, enhance_text, COLOR_GOLD, Vector2(size.x - 26.0, size.y - 18.0), 11)
	if is_equipped:
		_add_corner_badge(btn, "装", COLOR_ACCENT, Vector2(2.0, size.y - 18.0), 11)

# ボタン隅にバッジ（レアリティ宝石 / 装備中マーク）を重ねる。
func _add_corner_badge(
	btn: Button,
	text: String,
	color: Color,
	pos: Vector2,
	font_size: int = 13
) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = pos
	btn.add_child(lbl)

# ---- アイテム情報ヘルパー ----
func _equipped_for_category(category: String) -> Resource:
	match category:
		"weapon":
			return GameState.get_member_equipped_weapon(_selected_member_index)
		"armor":
			return GameState.get_member_equipped_armor(_selected_member_index)
		"accessory":
			return GameState.get_member_equipped_accessory(_selected_member_index)
	return null

func _item_data(item: Resource, category: String) -> Resource:
	if item == null:
		return null
	match category:
		"weapon":
			return load("res://resources/weapons/" + item.weapon_id + ".tres")
		"armor":
			return load("res://resources/armors/" + item.armor_id + ".tres")
		"accessory":
			return load("res://resources/accessories/" + item.accessory_id + ".tres")
	return null

func _accessory_data(item: Resource) -> Resource:
	if item == null:
		return null
	return load("res://resources/accessories/" + item.accessory_id + ".tres")

func _item_rarity(item: Resource, category: String) -> int:
	var data: Resource = _item_data(item, category)
	if data != null and "rarity" in data:
		return int(data.rarity)
	return 0

func _item_icon(item: Resource, category: String) -> Texture2D:
	match category:
		"weapon":
			return IconPaths.get_icon_texture(item.weapon_id, "weapon")
		"armor":
			return IconPaths.get_icon_texture(item.armor_id, "armor")
		"accessory":
			return IconPaths.get_icon_texture(item.accessory_id, "accessory")
	return null

func _item_label(item: Resource, category: String) -> String:
	match category:
		"weapon":
			var wt: String = "%s  ATK %d  SPD %.1f  CRT %.0f%%" % [
				_EquipmentEnhancer.get_display_name(item),
				_EquipmentEnhancer.get_effective_attack(item),
				item.attack_speed,
				item.critical_rate * 100.0,
			]
			return _AffixDisplayFormatter.append_to_text(wt, item)
		"armor":
			var at: String = "%s  DEF %d  HP+%d  WGT %.1f" % [
				DataRegistry.get_armor_name(item.armor_id), item.rolled_defense, item.hp_bonus, item.weight
			]
			at += _armor_resist_suffix(item)
			return _AffixDisplayFormatter.append_to_text(at, item)
		"accessory":
			var acc_data: Resource = _accessory_data(item)
			var act: String
			if acc_data != null:
				act = "%s  HP+%d  ATK+%d  DEF+%d  CRT+%.0f%%" % [
					DataRegistry.get_accessory_name(item.accessory_id),
					acc_data.hp_bonus, acc_data.attack_bonus, acc_data.defense_bonus,
					acc_data.crit_rate_bonus * 100.0,
				]
			else:
				act = DataRegistry.get_accessory_name(item.accessory_id)
			return _AffixDisplayFormatter.append_to_text(act, item)
	return ""

func _compare_text(candidate: Resource, category: String) -> String:
	var equipped: Resource = _equipped_for_category(category)
	if equipped == null:
		return "（未装備）"
	if candidate == equipped:
		return "（装備中）"
	match category:
		"weapon":
			return _weapon_compare(candidate, equipped)
		"armor":
			return _armor_compare(candidate, equipped)
		"accessory":
			return _accessory_compare(candidate, equipped)
	return ""

func _weapon_compare(candidate: Resource, equipped: Resource) -> String:
	var parts: PackedStringArray = []
	var atk_diff: int = _EquipmentEnhancer.get_effective_attack(candidate) - _EquipmentEnhancer.get_effective_attack(equipped)
	parts.append("ATK %s%d" % ["+" if atk_diff >= 0 else "", atk_diff])
	var spd_diff: float = candidate.attack_speed - equipped.attack_speed
	if not is_zero_approx(spd_diff):
		parts.append("SPD %s%.1f" % ["+" if spd_diff >= 0.0 else "", spd_diff])
	var crt_diff: float = candidate.critical_rate - equipped.critical_rate
	if not is_zero_approx(crt_diff):
		parts.append("CRT %s%.0f%%" % ["+" if crt_diff >= 0.0 else "", crt_diff * 100.0])
	return "[%s]" % " | ".join(parts)

# 防具の属性耐性表示（P3-D103）。例: "  耐性:闇"。
func _armor_resist_suffix(item: Resource) -> String:
	if item == null:
		return ""
	var armor_data: Resource = load("res://resources/armors/" + str(item.armor_id) + ".tres")
	if armor_data == null or not ("resist_elements" in armor_data):
		return ""
	var names: PackedStringArray = []
	for e in armor_data.resist_elements:
		var nm: String = _ElementResolver.get_display_name(str(e))
		if not nm.is_empty():
			names.append(nm)
	if names.is_empty():
		return ""
	return "  耐性:%s" % "/".join(names)

func _armor_compare(candidate: Resource, equipped: Resource) -> String:
	var parts: PackedStringArray = []
	var def_diff: int = candidate.rolled_defense - equipped.rolled_defense
	if def_diff != 0:
		parts.append("DEF %s%d" % ["+" if def_diff >= 0 else "", def_diff])
	var hp_diff: int = candidate.hp_bonus - equipped.hp_bonus
	if hp_diff != 0:
		parts.append("HP %s%d" % ["+" if hp_diff >= 0 else "", hp_diff])
	if parts.is_empty():
		return "[±0]"
	return "[%s]" % " | ".join(parts)

func _accessory_compare(candidate: Resource, equipped: Resource) -> String:
	var c_data: Resource = _accessory_data(candidate)
	var e_data: Resource = _accessory_data(equipped)
	if c_data == null or e_data == null:
		return ""
	var parts: PackedStringArray = []
	var hp_d: int = c_data.hp_bonus - e_data.hp_bonus
	if hp_d != 0:
		parts.append("HP %s%d" % ["+" if hp_d >= 0 else "", hp_d])
	var atk_d: int = c_data.attack_bonus - e_data.attack_bonus
	if atk_d != 0:
		parts.append("ATK %s%d" % ["+" if atk_d >= 0 else "", atk_d])
	var def_d: int = c_data.defense_bonus - e_data.defense_bonus
	if def_d != 0:
		parts.append("DEF %s%d" % ["+" if def_d >= 0 else "", def_d])
	var crt_d: float = c_data.crit_rate_bonus - e_data.crit_rate_bonus
	if not is_zero_approx(crt_d):
		parts.append("CRT %s%.0f%%" % ["+" if crt_d >= 0.0 else "", crt_d * 100.0])
	if parts.is_empty():
		return "[±0]"
	return "[%s]" % " | ".join(parts)

# ---- ステータス計算（戦闘式と整合する表示用集計） ----
func _compute_member_stats(idx: int) -> Dictionary:
	var member: Resource = GameState.get_member(idx)
	var weapon: Resource = GameState.get_member_equipped_weapon(idx)
	var armor: Resource = GameState.get_member_equipped_armor(idx)
	var acc_data: Resource = _accessory_data(GameState.get_member_equipped_accessory(idx))
	var affix: Dictionary = _AffixStatCalculator.get_bonuses(idx)
	var job: Dictionary = _JobStatCalculator.get_member_modifiers(member)
	var level: int = int(member.level) if member != null else 1
	var hp: int = BASE_MEMBER_HP
	if armor != null:
		hp += armor.hp_bonus
	if acc_data != null:
		hp += acc_data.hp_bonus
	hp += int(affix.get("hp_flat", 0))
	hp += LevelSystem.level_hp_bonus(level)
	hp = int(round(float(hp) * float(job.get("hp_multiplier", 1.0))))
	var attack: int = 0
	if weapon != null:
		attack = _EquipmentEnhancer.get_effective_attack(weapon)
	if acc_data != null:
		attack += acc_data.attack_bonus
	attack += int(affix.get("attack_flat", 0))
	attack += LevelSystem.level_attack_bonus(level)
	var atk_mult: float = float(job.get("attack_multiplier", 1.0))
	if weapon != null:
		atk_mult *= _JobStatCalculator.get_preferred_weapon_multiplier(member, DataRegistry.get_weapon_data(weapon.weapon_id))
	attack = int(round(float(attack) * atk_mult))
	var defense: int = 0
	if armor != null:
		defense = armor.rolled_defense
	if acc_data != null:
		defense += acc_data.defense_bonus
	defense += int(affix.get("defense_flat", 0))
	defense = int(round(float(defense) * float(job.get("defense_multiplier", 1.0))))
	var speed: float = weapon.attack_speed if weapon != null else 1.0
	var crit: float = (weapon.critical_rate if weapon != null else 0.0)
	if acc_data != null:
		crit += acc_data.crit_rate_bonus
	crit += float(affix.get("crit_rate_add", 0.0))
	return {
		"hp": hp,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"crit_rate": crit,
		"crit_damage": CRIT_DAMAGE_MULT,
	}

# ---- スキルタブ（P3-D077） ----
func _rebuild_skill_tab() -> void:
	var member: Resource = GameState.get_member(_selected_member_index)
	_ensure_tactics_ui()
	_refresh_tactics_ui(member)
	_ensure_relic_ui()
	_refresh_relic_ui(member)
	_ensure_preset_ui()
	_refresh_preset_ui()
	_ensure_tag_info_ui()
	_refresh_tag_info(member)
	var slots_label: Label = _skill_content.get_node("LabelSkillSlots") as Label
	var list: Node = _skill_content.get_node("SkillList")
	for child in list.get_children():
		child.queue_free()
	if member == null:
		slots_label.text = "装備中スキル: —"
		return
	var equipped: Array[String] = GameState.get_equipped_skill_ids(member)
	var equipped_names: PackedStringArray = []
	for sid in equipped:
		equipped_names.append(_skill_label_name(sid))
	var shown: String = " / ".join(equipped_names) if not equipped_names.is_empty() else "なし"
	slots_label.text = "装備中スキル (%d/%d): %s" % [equipped.size(), Constants.MAX_EQUIPPED_SKILLS, shown]
	var job: Resource = DataRegistry.get_job_data(member.job_id)
	if job == null:
		return
	for raw_sid in job.learnable_skill_ids:
		var sid: String = str(raw_sid)
		var skill_data: Resource = DataRegistry.get_skill_data(sid)
		if skill_data == null:
			continue
		var is_equipped: bool = equipped.has(sid)
		var row := HBoxContainer.new()
		var info := Label.new()
		info.text = _skill_info_text(skill_data)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.add_child(info)
		var btn := Button.new()
		btn.text = "解除" if is_equipped else "装備"
		btn.disabled = (not is_equipped) and equipped.size() >= Constants.MAX_EQUIPPED_SKILLS
		btn.pressed.connect(_on_skill_toggle_pressed.bind(sid))
		row.add_child(btn)
		list.add_child(row)

# 戦術・陣形はタブ外の常時表示パネル（P3-ALPHA-003 フィードバック）。
func _ensure_combat_setup_panel() -> void:
	if _combat_setup_panel != null and is_instance_valid(_combat_setup_panel):
		return
	var vbox: VBoxContainer = $VBoxContainer
	_combat_setup_panel = PanelContainer.new()
	_combat_setup_panel.name = "CombatSetupPanel"
	_combat_setup_panel.add_theme_stylebox_override(
		"panel", _framed_box(COLOR_GOLD, 2, Color(0.08, 0.07, 0.05, 0.92))
	)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "◆ 戦術 ◆"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.add_theme_font_size_override("font_size", 16)
	outer.add_child(title)
	var hint := Label.new()
	hint.text = "陣形は拠点 → 編成 → 陣形タブで設定"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", COLOR_SUB)
	hint.add_theme_font_size_override("font_size", 12)
	outer.add_child(hint)
	_combat_setup_content = VBoxContainer.new()
	_combat_setup_content.name = "CombatSetupContent"
	_combat_setup_content.add_theme_constant_override("separation", 6)
	outer.add_child(_combat_setup_content)
	_combat_setup_panel.add_child(outer)
	vbox.add_child(_combat_setup_panel)
	var tab_idx: int = vbox.get_node("TabContainer").get_index()
	vbox.move_child(_combat_setup_panel, tab_idx)

# 戦術セレクタ（P3-D086）。常時表示パネル最上部。
func _ensure_tactics_ui() -> void:
	if _tactics_option != null and is_instance_valid(_tactics_option):
		return
	_ensure_combat_setup_panel()
	var row := HBoxContainer.new()
	row.name = "TacticsRow"
	var label := Label.new()
	label.text = "戦術:"
	row.add_child(label)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tactics_ids.clear()
	for t: Dictionary in CombatTactics.tactics_list():
		opt.add_item(str(t["display_name"]))
		_tactics_ids.append(str(t["id"]))
	opt.item_selected.connect(_on_tactics_selected)
	row.add_child(opt)
	_combat_setup_content.add_child(row)
	_combat_setup_content.move_child(row, 0)
	_tactics_option = opt
	_ensure_gambit_ui()

func _ensure_gambit_ui() -> void:
	if _gambit_custom_check != null and is_instance_valid(_gambit_custom_check):
		return
	_ensure_combat_setup_panel()
	var check_row := HBoxContainer.new()
	check_row.name = "GambitCheckRow"
	_gambit_custom_check = CheckBox.new()
	_gambit_custom_check.text = "カスタム戦術（ガンビット）"
	_gambit_custom_check.toggled.connect(_on_gambit_custom_toggled)
	check_row.add_child(_gambit_custom_check)
	_combat_setup_content.add_child(check_row)
	_combat_setup_content.move_child(check_row, 1)
	_gambit_custom_box = VBoxContainer.new()
	_gambit_custom_box.name = "GambitCustomBox"
	_gambit_custom_box.add_theme_constant_override("separation", 4)
	_gambit_custom_box.visible = false
	var target_row := HBoxContainer.new()
	var target_label := Label.new()
	target_label.text = "標的:"
	target_row.add_child(target_label)
	_gambit_target_option = OptionButton.new()
	_gambit_target_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gambit_target_ids.clear()
	for target_id: String in CombatTactics.TARGET_RULES:
		_gambit_target_option.add_item(CombatGambit.target_label(target_id))
		_gambit_target_ids.append(target_id)
	_gambit_target_option.item_selected.connect(_on_gambit_target_selected)
	target_row.add_child(_gambit_target_option)
	_gambit_custom_box.add_child(target_row)
	var copy_btn := Button.new()
	copy_btn.text = "プリセットから複製"
	copy_btn.pressed.connect(_on_gambit_copy_preset_pressed)
	_gambit_custom_box.add_child(copy_btn)
	_gambit_slot_opts.clear()
	_gambit_cond_opts.clear()
	_gambit_value_edits.clear()
	_gambit_range_opts.clear()
	_gambit_move_up_btns.clear()
	_gambit_move_down_btns.clear()
	_gambit_cond_hint_labels.clear()
	for i in CombatGambit.plan_row_count():
		var row_wrap := VBoxContainer.new()
		row_wrap.name = "GambitPlanWrap%d" % i
		row_wrap.add_theme_constant_override("separation", 2)
		var plan_row := HBoxContainer.new()
		plan_row.name = "GambitPlanRow%d" % i
		var pri := Label.new()
		pri.text = "%d." % (i + 1)
		pri.custom_minimum_size.x = 18.0
		plan_row.add_child(pri)
		var slot_opt := OptionButton.new()
		slot_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for slot_id: String in CombatGambit.SLOT_IDS:
			slot_opt.add_item(CombatGambit.slot_label(slot_id))
		slot_opt.item_selected.connect(_on_gambit_row_changed)
		plan_row.add_child(slot_opt)
		var cond_opt := OptionButton.new()
		cond_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for cond_id: String in CombatGambit.CONDITION_IDS:
			cond_opt.add_item(CombatGambit.condition_label(cond_id))
		cond_opt.item_selected.connect(_on_gambit_row_changed)
		plan_row.add_child(cond_opt)
		var value_edit := LineEdit.new()
		value_edit.custom_minimum_size.x = 52.0
		value_edit.placeholder_text = "値"
		value_edit.text_changed.connect(_on_gambit_row_changed)
		plan_row.add_child(value_edit)
		var range_opt := OptionButton.new()
		range_opt.custom_minimum_size.x = 72.0
		for range_id: String in CombatGambit.RANGE_VALUE_IDS:
			range_opt.add_item(range_id)
		range_opt.item_selected.connect(_on_gambit_row_changed)
		range_opt.visible = false
		plan_row.add_child(range_opt)
		var move_col := VBoxContainer.new()
		move_col.add_theme_constant_override("separation", 0)
		var btn_up := Button.new()
		btn_up.text = "↑"
		btn_up.custom_minimum_size = Vector2(30, 22)
		btn_up.pressed.connect(_on_gambit_move_row.bind(i, -1))
		move_col.add_child(btn_up)
		var btn_down := Button.new()
		btn_down.text = "↓"
		btn_down.custom_minimum_size = Vector2(30, 22)
		btn_down.pressed.connect(_on_gambit_move_row.bind(i, 1))
		move_col.add_child(btn_down)
		plan_row.add_child(move_col)
		row_wrap.add_child(plan_row)
		var cond_hint := Label.new()
		cond_hint.text = ""
		cond_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cond_hint.add_theme_color_override("font_color", COLOR_SUB)
		cond_hint.add_theme_font_size_override("font_size", 11)
		row_wrap.add_child(cond_hint)
		_gambit_custom_box.add_child(row_wrap)
		_gambit_slot_opts.append(slot_opt)
		_gambit_cond_opts.append(cond_opt)
		_gambit_value_edits.append(value_edit)
		_gambit_range_opts.append(range_opt)
		_gambit_move_up_btns.append(btn_up)
		_gambit_move_down_btns.append(btn_down)
		_gambit_cond_hint_labels.append(cond_hint)
	var gambit_hint := Label.new()
	gambit_hint.text = "上から優先。↑↓で並替。条件成立かつ発動可の最初の行動を実行"
	gambit_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	gambit_hint.add_theme_color_override("font_color", COLOR_SUB)
	gambit_hint.add_theme_font_size_override("font_size", 12)
	_gambit_custom_box.add_child(gambit_hint)
	_combat_setup_content.add_child(_gambit_custom_box)
	_combat_setup_content.move_child(_gambit_custom_box, 2)

func _refresh_gambit_ui(member: Resource) -> void:
	if _gambit_custom_check == null:
		return
	_gambit_ui_syncing = true
	if member == null:
		_gambit_custom_check.disabled = true
		_gambit_custom_box.visible = false
		_gambit_ui_syncing = false
		return
	_gambit_custom_check.disabled = false
	var custom_on: bool = GameState.get_member_tactics_custom_enabled(member)
	_gambit_custom_check.button_pressed = custom_on
	_gambit_custom_box.visible = custom_on
	if _tactics_option != null:
		_tactics_option.disabled = custom_on
	var target: String = GameState.get_member_tactics_custom_target(member)
	var target_idx: int = _gambit_target_ids.find(target)
	if _gambit_target_option != null:
		_gambit_target_option.select(target_idx if target_idx >= 0 else 0)
	var plan: Array = GameState.get_member_tactics_custom_plan(member)
	for i in CombatGambit.plan_row_count():
		var rule: Dictionary = plan[i] if i < plan.size() else CombatGambit.default_plan_row(i)
		var slot_id: String = str(rule.get("slot", "attack"))
		var cond_id: String = str(rule.get("condition", "always"))
		var slot_idx: int = CombatGambit.SLOT_IDS.find(slot_id)
		var cond_idx: int = CombatGambit.CONDITION_IDS.find(cond_id)
		_gambit_slot_opts[i].select(slot_idx if slot_idx >= 0 else 0)
		_gambit_cond_opts[i].select(cond_idx if cond_idx >= 0 else 0)
		_update_gambit_row_value_widgets(i, cond_id, rule)
	_update_gambit_move_buttons()
	_update_gambit_condition_hints()
	_gambit_ui_syncing = false

func _update_gambit_condition_hints() -> void:
	for i in CombatGambit.plan_row_count():
		if i >= _gambit_cond_opts.size() or i >= _gambit_cond_hint_labels.size():
			continue
		var cond_idx: int = _gambit_cond_opts[i].selected
		var cond_id: String = "always"
		if cond_idx >= 0 and cond_idx < CombatGambit.CONDITION_IDS.size():
			cond_id = CombatGambit.CONDITION_IDS[cond_idx]
		var hint: String = CombatGambit.condition_hint(cond_id)
		_gambit_cond_hint_labels[i].text = hint
		_gambit_cond_hint_labels[i].visible = not hint.is_empty()

func _update_gambit_move_buttons() -> void:
	var row_count: int = CombatGambit.plan_row_count()
	for i in row_count:
		if i < _gambit_move_up_btns.size():
			_gambit_move_up_btns[i].disabled = i <= 0
		if i < _gambit_move_down_btns.size():
			_gambit_move_down_btns[i].disabled = i >= row_count - 1

func _update_gambit_row_value_widgets(row: int, cond_id: String, rule: Dictionary = {}) -> void:
	var needs_value: bool = CombatGambit.condition_needs_value(cond_id)
	var is_range: bool = cond_id == "self_range"
	_gambit_value_edits[row].visible = needs_value and not is_range
	_gambit_range_opts[row].visible = needs_value and is_range
	if not needs_value:
		return
	var raw_val: String = str(rule.get("value", CombatGambit.default_value_for(cond_id)))
	if is_range:
		var range_idx: int = CombatGambit.RANGE_VALUE_IDS.find(raw_val)
		_gambit_range_opts[row].select(range_idx if range_idx >= 0 else 0)
	else:
		_gambit_value_edits[row].text = raw_val

func _collect_gambit_plan_from_ui() -> Array:
	var out: Array = []
	for i in CombatGambit.plan_row_count():
		var slot_idx: int = _gambit_slot_opts[i].selected
		var cond_idx: int = _gambit_cond_opts[i].selected
		if slot_idx < 0 or slot_idx >= CombatGambit.SLOT_IDS.size():
			continue
		if cond_idx < 0 or cond_idx >= CombatGambit.CONDITION_IDS.size():
			continue
		var cond_id: String = CombatGambit.CONDITION_IDS[cond_idx]
		var rule: Dictionary = {
			"slot": CombatGambit.SLOT_IDS[slot_idx],
			"condition": cond_id,
		}
		if CombatGambit.condition_needs_value(cond_id):
			if cond_id == "self_range":
				var range_idx: int = _gambit_range_opts[i].selected
				if range_idx >= 0 and range_idx < CombatGambit.RANGE_VALUE_IDS.size():
					rule["value"] = CombatGambit.RANGE_VALUE_IDS[range_idx]
			else:
				rule["value"] = _gambit_value_edits[i].text
		out.append(rule)
	return out

func _persist_gambit_plan(member: Resource) -> void:
	if member == null or _gambit_ui_syncing:
		return
	GameState.set_member_tactics_custom_plan(member, _collect_gambit_plan_from_ui())

func _on_gambit_custom_toggled(enabled: bool) -> void:
	if _gambit_ui_syncing:
		return
	var member: Resource = GameState.get_member(_selected_member_index)
	if member == null:
		return
	if enabled and GameState.get_member_tactics_custom_plan(member).is_empty():
		GameState.copy_member_tactics_preset_to_custom(member)
	else:
		GameState.set_member_tactics_custom_enabled(member, enabled)
	_refresh_gambit_ui(member)

func _on_gambit_copy_preset_pressed() -> void:
	var member: Resource = GameState.get_member(_selected_member_index)
	if member == null:
		return
	GameState.copy_member_tactics_preset_to_custom(member)
	_refresh_gambit_ui(member)

func _on_gambit_target_selected(_index: int) -> void:
	if _gambit_ui_syncing:
		return
	var member: Resource = GameState.get_member(_selected_member_index)
	if member == null or _gambit_target_option == null:
		return
	var idx: int = _gambit_target_option.selected
	if idx < 0 or idx >= _gambit_target_ids.size():
		return
	GameState.set_member_tactics_custom_target(member, _gambit_target_ids[idx])

func _on_gambit_row_changed(_unused: Variant = null) -> void:
	if _gambit_ui_syncing:
		return
	var member: Resource = GameState.get_member(_selected_member_index)
	if member == null:
		return
	for i in CombatGambit.plan_row_count():
		var cond_idx: int = _gambit_cond_opts[i].selected
		var cond_id: String = CombatGambit.CONDITION_IDS[cond_idx] if cond_idx >= 0 else "always"
		_update_gambit_row_value_widgets(i, cond_id)
	_update_gambit_condition_hints()
	_persist_gambit_plan(member)

func _on_gambit_move_row(row: int, delta: int) -> void:
	if _gambit_ui_syncing:
		return
	var member: Resource = GameState.get_member(_selected_member_index)
	if member == null:
		return
	var other: int = row + delta
	if other < 0 or other >= CombatGambit.plan_row_count():
		return
	var plan: Array = _collect_gambit_plan_from_ui()
	if plan.size() < CombatGambit.plan_row_count():
		return
	var tmp: Dictionary = plan[row]
	plan[row] = plan[other]
	plan[other] = tmp
	GameState.set_member_tactics_custom_plan(member, plan)
	_refresh_gambit_ui(member)

func _refresh_tactics_ui(member: Resource) -> void:
	if _tactics_option == null:
		return
	if member == null:
		_tactics_option.disabled = true
		return
	_tactics_option.disabled = false
	var current: String = GameState.get_member_tactics_id(member)
	var idx: int = _tactics_ids.find(current)
	_tactics_option.select(idx if idx >= 0 else 0)
	_refresh_gambit_ui(member)

func _on_tactics_selected(index: int) -> void:
	if index < 0 or index >= _tactics_ids.size():
		return
	var member: Resource = GameState.get_member(_selected_member_index)
	if member == null:
		return
	GameState.set_member_tactics(member, _tactics_ids[index])

# 遺物セレクタ（P3-D090）。戦術行の直下に 1 度だけ生成する。
func _ensure_relic_ui() -> void:
	if _relic_option != null and is_instance_valid(_relic_option):
		return
	var row := HBoxContainer.new()
	row.name = "RelicRow"
	var label := Label.new()
	label.text = "遺物:"
	row.add_child(label)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.item_selected.connect(_on_relic_selected)
	row.add_child(opt)
	_skill_content.add_child(row)
	_skill_content.move_child(row, 1)
	_relic_option = opt

# 所持遺物のみ選択可（P3-D093）。先頭=なし＋所持済み。現在装備が未所持なら参考表示。
func _refresh_relic_ui(member: Resource) -> void:
	if _relic_option == null:
		return
	_relic_option.clear()
	_relic_ids.clear()
	_relic_option.add_item("なし")
	_relic_ids.append("")
	for rid: String in CombatRelics.all_ids():
		if GameState.has_relic(rid):
			_relic_option.add_item(CombatRelics.display_name(rid))
			_relic_ids.append(rid)
	if member == null:
		_relic_option.disabled = true
		_relic_option.select(0)
		return
	_relic_option.disabled = false
	var current: String = GameState.get_member_relic_id(member)
	if not current.is_empty() and current not in _relic_ids:
		_relic_option.add_item("%s (未所持)" % CombatRelics.display_name(current))
		_relic_ids.append(current)
	var idx: int = _relic_ids.find(current)
	_relic_option.select(idx if idx >= 0 else 0)

func _on_relic_selected(index: int) -> void:
	if index < 0 or index >= _relic_ids.size():
		return
	var member: Resource = GameState.get_member(_selected_member_index)
	if member == null:
		return
	GameState.set_member_relic(member, _relic_ids[index])

# 作戦プリセット（P3-D091 / P3-D121）。スキルタブ最上部に「作戦 [▼] [適用] [保存]」を 1 度だけ生成。
# プリセット＝party 全員の戦術＋遺物＋装備＋探索方針。適用で全員へ一括反映する。
func _ensure_preset_ui() -> void:
	if _preset_option != null and is_instance_valid(_preset_option):
		return
	var row := HBoxContainer.new()
	row.name = "PresetRow"
	var label := Label.new()
	label.text = "作戦:"
	row.add_child(label)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.item_selected.connect(_on_preset_slot_selected)
	row.add_child(opt)
	var apply_btn := Button.new()
	apply_btn.text = "適用"
	apply_btn.pressed.connect(_on_preset_apply_pressed)
	row.add_child(apply_btn)
	var save_btn := Button.new()
	save_btn.text = "保存"
	save_btn.pressed.connect(_on_preset_save_pressed)
	row.add_child(save_btn)
	_skill_content.add_child(row)
	_skill_content.move_child(row, 0)
	_preset_option = opt
	var name_row := HBoxContainer.new()
	name_row.name = "PresetNameRow"
	var name_label := Label.new()
	name_label.text = "名称:"
	_preset_name_edit = LineEdit.new()
	_preset_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preset_name_edit.placeholder_text = "作戦1"
	_preset_name_edit.max_length = 24
	_preset_name_edit.text_submitted.connect(_on_preset_rename_submitted)
	name_row.add_child(name_label)
	name_row.add_child(_preset_name_edit)
	_preset_rename_btn = Button.new()
	_preset_rename_btn.text = "名前変更"
	_preset_rename_btn.pressed.connect(_on_preset_rename_pressed)
	name_row.add_child(_preset_rename_btn)
	_skill_content.add_child(name_row)
	_skill_content.move_child(name_row, 1)
	# 探索方針セレクタ（P3-D098）。プリセットに内包され、保存時に一緒に記録される。
	var policy_row := HBoxContainer.new()
	policy_row.name = "PolicyRow"
	var policy_label := Label.new()
	policy_label.text = "探索方針:"
	policy_row.add_child(policy_label)
	var policy_opt := OptionButton.new()
	policy_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for pid: String in _POLICY_IDS:
		policy_opt.add_item(GameState.exploration_policy_label(pid))
	policy_opt.item_selected.connect(_on_policy_selected)
	policy_row.add_child(policy_opt)
	_skill_content.add_child(policy_row)
	_skill_content.move_child(policy_row, 2)
	_policy_option = policy_opt
	var policy_hint := Label.new()
	policy_hint.name = "PolicyHint"
	policy_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	policy_hint.add_theme_color_override("font_color", COLOR_SUB)
	policy_hint.add_theme_font_size_override("font_size", 12)
	_skill_content.add_child(policy_hint)
	_skill_content.move_child(policy_hint, 3)
	_policy_hint_label = policy_hint

func _refresh_preset_ui() -> void:
	if _preset_option == null:
		return
	var prev: int = _preset_option.selected
	_preset_option.clear()
	for slot: int in GameState.COMBAT_PRESET_SLOTS:
		var nm: String = GameState.get_combat_preset_name(slot)
		var summary: String = GameState.get_combat_preset_summary(slot)
		var text: String
		if nm.is_empty():
			text = "%d: (空)" % (slot + 1)
		elif summary.is_empty():
			text = "%d: %s" % [slot + 1, nm]
		else:
			text = "%d: %s (%s)" % [slot + 1, nm, summary]
		_preset_option.add_item(text)
	if _preset_option.item_count > 0:
		_preset_option.select(clampi(prev, 0, _preset_option.item_count - 1))
	_sync_preset_name_field(_preset_option.selected)
	_sync_policy_option()

func _sync_preset_name_field(slot: int) -> void:
	if _preset_name_edit == null:
		return
	var default_name: String = GameState.default_combat_preset_name(slot)
	if GameState.has_combat_preset(slot):
		_preset_name_edit.text = GameState.get_combat_preset_name(slot)
		if _preset_rename_btn != null:
			_preset_rename_btn.disabled = false
	else:
		_preset_name_edit.text = default_name
		if _preset_rename_btn != null:
			_preset_rename_btn.disabled = true
	_preset_name_edit.placeholder_text = default_name

func _on_preset_slot_selected(index: int) -> void:
	_sync_preset_name_field(index)

func _on_preset_rename_submitted(_text: String) -> void:
	_on_preset_rename_pressed()

func _on_preset_rename_pressed() -> void:
	if _preset_option == null or _preset_name_edit == null:
		return
	var slot: int = _preset_option.selected
	if slot < 0:
		return
	if not GameState.rename_combat_preset(slot, _preset_name_edit.text):
		return
	SaveManager.save_game()
	_refresh_preset_ui()
	_preset_option.select(slot)

func _sync_policy_option() -> void:
	if _policy_option == null:
		return
	var idx: int = _POLICY_IDS.find(GameState.get_exploration_policy())
	_policy_option.select(idx if idx >= 0 else 0)
	_sync_policy_hint()

func _sync_policy_hint() -> void:
	if _policy_hint_label == null:
		return
	var policy: String = GameState.get_exploration_policy()
	_policy_hint_label.text = GameState.exploration_policy_hint(policy)

func _on_policy_selected(index: int) -> void:
	if index < 0 or index >= _POLICY_IDS.size():
		return
	GameState.set_exploration_policy(str(_POLICY_IDS[index]))
	_sync_policy_hint()

func _on_preset_apply_pressed() -> void:
	if _preset_option == null:
		return
	var slot: int = _preset_option.selected
	var result: Dictionary = GameState.apply_combat_preset(slot)
	if not bool(result.get("ok", false)):
		return
	var skipped: Array = result.get("skipped", [])
	if not skipped.is_empty():
		_show_preset_apply_feedback(skipped)
	SaveManager.save_game()
	_refresh_display()
	var member: Resource = GameState.get_member(_selected_member_index)
	_refresh_tactics_ui(member)
	_refresh_gambit_ui(member)
	_refresh_relic_ui(member)
	_sync_policy_option()

func _ensure_preset_feedback_ui() -> void:
	if _preset_feedback_panel != null and is_instance_valid(_preset_feedback_panel):
		return
	var layer := CanvasLayer.new()
	layer.name = "PresetFeedbackLayer"
	layer.layer = 12
	add_child(layer)
	var panel := PanelContainer.new()
	panel.name = "PresetFeedback"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -96.0
	panel.offset_bottom = -16.0
	panel.offset_left = 16.0
	panel.offset_right = -16.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.92)
	style.border_color = COLOR_GOLD
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", COLOR_VALUE)
	panel.add_child(label)
	_preset_feedback_panel = panel
	_preset_feedback_label = label

func _show_preset_apply_feedback(skipped: Array) -> void:
	_ensure_preset_feedback_ui()
	var parts: PackedStringArray = PackedStringArray()
	for entry in skipped:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		var member_name: String = str(d.get("member_name", "?"))
		var kind: String = GameState.preset_equipment_kind_label(str(d.get("kind", "")))
		var reason: String = GameState.preset_equipment_skip_label(str(d.get("reason", "")))
		parts.append("%s・%s（%s）" % [member_name, kind, reason])
	if parts.is_empty():
		return
	_preset_feedback_label.text = "装備スキップ: " + " / ".join(parts)
	_preset_feedback_panel.visible = true
	_preset_feedback_panel.modulate.a = 0.0
	if _preset_feedback_tween != null and _preset_feedback_tween.is_valid():
		_preset_feedback_tween.kill()
	_preset_feedback_tween = create_tween()
	_preset_feedback_tween.tween_property(_preset_feedback_panel, "modulate:a", 1.0, 0.2)
	_preset_feedback_tween.tween_interval(3.0)
	_preset_feedback_tween.tween_property(_preset_feedback_panel, "modulate:a", 0.0, 0.3)
	_preset_feedback_tween.tween_callback(func() -> void:
		if is_instance_valid(_preset_feedback_panel):
			_preset_feedback_panel.visible = false
	)

func _on_preset_save_pressed() -> void:
	if _preset_option == null:
		return
	var slot: int = _preset_option.selected
	if slot < 0:
		return
	GameState.save_combat_preset(slot, _preset_name_edit.text if _preset_name_edit != null else "")
	SaveManager.save_game()
	_refresh_preset_ui()
	_preset_option.select(slot)

# タグ/シナジー可視化（P3-D095）。装備武器タグ＋パーティ属性シナジーを読み取り表示。
func _ensure_tag_info_ui() -> void:
	if _tag_info_label != null and is_instance_valid(_tag_info_label):
		return
	var row := HBoxContainer.new()
	row.name = "TagInfoRow"
	var lbl := Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(lbl)
	_skill_content.add_child(row)
	_skill_content.move_child(row, 3)
	_tag_info_label = lbl

func _refresh_tag_info(member: Resource) -> void:
	if _tag_info_label == null:
		return
	if member == null:
		_tag_info_label.text = ""
		return
	var wtags: PackedStringArray = []
	var winst: Resource = member.equipped_weapon
	if winst != null and not str(winst.weapon_id).is_empty():
		var wd: Resource = DataRegistry.get_weapon_data(winst.weapon_id)
		if wd != null and "tags" in wd:
			for t in wd.tags:
				wtags.append(CombatTags.display_name(str(t)))
	var tag_text: String = " / ".join(wtags) if not wtags.is_empty() else "なし"
	var syn: Dictionary = CombatSynergy.compute_element_bonuses(GameState.party_members)
	var syn_parts: PackedStringArray = []
	for e: String in syn:
		syn_parts.append("%s +%d%%" % [CombatTags.display_name(e), int(round(float(syn[e]) * 100.0))])
	var syn_text: String = " / ".join(syn_parts) if not syn_parts.is_empty() else "なし"
	# 物理タグシナジー＋ロール編成ボーナス（P3-D097）
	var bonus_parts: PackedStringArray = []
	var phys: float = CombatSynergy.compute_physical_bonus(GameState.party_members)
	if phys > 0.0:
		bonus_parts.append("物理連携 与ダメ+%d%%" % int(round(phys * 100.0)))
	for lbl in CombatSynergy.compute_role_bonuses(GameState.party_members).get("labels", []):
		bonus_parts.append(str(lbl))
	var bonus_text: String = " / ".join(bonus_parts) if not bonus_parts.is_empty() else "なし"
	var link_hints: PackedStringArray = CombatLinks.hint_lines()
	var link_text: String = " / ".join(link_hints)
	var explore_labels: PackedStringArray = ExplorationSkills.active_labels(GameState.party_members)
	var explore_text: String = " / ".join(explore_labels) if not explore_labels.is_empty() else "なし"
	_tag_info_label.text = "武器タグ: %s   ｜   属性シナジー: %s\n編成ボーナス: %s\n戦闘連携: %s\n探索スキル: %s" % [tag_text, syn_text, bonus_text, link_text, explore_text]

func _skill_label_name(skill_id: String) -> String:
	var sd: Resource = DataRegistry.get_skill_data(skill_id)
	if sd != null and not sd.display_name.is_empty():
		return sd.display_name
	return skill_id

func _skill_info_text(skill_data: Resource) -> String:
	match skill_data.effect_type:
		"heal":
			# HEAL_SKILL_BASE(=14) と同期。最も負傷した味方を回復。
			var amt: int = int(round(skill_data.power_multiplier * 14.0))
			return "%s  回復+%d  CD%.1fs" % [skill_data.display_name, amt, skill_data.cooldown]
		"buff":
			var parts_buff: PackedStringArray = [skill_data.display_name]
			var eff_b: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
			if eff_b != null:
				var up: int = int(round((eff_b.outgoing_damage_multiplier - 1.0) * 100.0))
				if up != 0:
					parts_buff.append("味方与ダメ+%d%%" % up)
				parts_buff.append("%dtick" % eff_b.duration_ticks)
			parts_buff.append("CD%.1fs" % skill_data.cooldown)
			return "  ".join(parts_buff)
	var parts: PackedStringArray = [
		skill_data.display_name,
		"威力x%.2f" % skill_data.power_multiplier,
		"CD%.1fs" % skill_data.cooldown,
	]
	if not str(skill_data.element).is_empty():
		parts.append("属性:%s" % skill_data.element)
	if not str(skill_data.apply_status_id).is_empty() and skill_data.apply_status_chance > 0.0:
		var eff: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
		var st_name: String = eff.display_name if eff != null else str(skill_data.apply_status_id)
		parts.append("%s%.0f%%" % [st_name, skill_data.apply_status_chance * 100.0])
	return "  ".join(parts)

func _on_skill_toggle_pressed(skill_id: String) -> void:
	var member: Resource = GameState.get_member(_selected_member_index)
	if member == null:
		return
	GameState.toggle_member_skill(member, skill_id)
	_rebuild_skill_tab()

func _on_back_pressed() -> void:
	SaveManager.save_game()
	_go_to(HOME_SCENE)

func _go_to(scene_path: String) -> void:
	SaveManager.save_game()
	SceneRouter.change_scene(scene_path)
