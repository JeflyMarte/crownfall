extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const CATALOG_SCENE: String = "res://scenes/equipment/EquipmentCatalogScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const _AffixDisplayFormatter = preload("res://scripts/equipment/AffixDisplayFormatter.gd")
const _JobEvolution = preload("res://scripts/systems/JobEvolution.gd")
const _EvolutionVisual = preload("res://scripts/systems/EvolutionVisual.gd")
const _EvolutionTraits = preload("res://scripts/systems/EvolutionTraits.gd")
const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")
const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _WeaponFlavorHelper = preload("res://scripts/systems/WeaponFlavorHelper.gd")
const _ElementResolver = preload("res://scripts/combat/ElementResolver.gd")
const _SkillIconHelper = preload("res://scripts/ui/SkillIconHelper.gd")
const _ChrIdlePortrait = preload("res://scripts/ui/ChrIdlePortrait.gd")

# CombatController.BASE_MEMBER_HP と同値（表示用の素HP）。
const BASE_MEMBER_HP: int = 30
# クリティカルダメージ倍率（BalanceConfig 準拠）。
const CRIT_DAMAGE_MULT: float = BalanceConfig.CRITICAL_MULTIPLIER
const GRID_COLUMNS: int = 6
const SLOT_COLUMNS: int = 2
const INV_VISIBLE_ROWS: int = 3
const STAT_VALUE_FONT_SIZE: int = 24
const STAT_LABEL_FONT_SIZE: int = 20

const SKILL_COLOR_ATTACK: Color = Color(0.95, 0.45, 0.42)
const SKILL_COLOR_DEFENSE: Color = Color(0.55, 0.78, 0.98)
const SKILL_COLOR_SUPPORT: Color = Color(0.96, 0.82, 0.35)
const SKILL_NAME_FONT_SIZE: int = 22
const TAB_EQUIP: int = 0
const TAB_SKILL: int = 1
const TAB_ULTIMATE: int = 2
const TAB_PASSIVE: int = 3
const TAB_TACTICS: int = 4

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

# スロット空表示用グリフ（テクスチャ未取得時のフォールバック）。
const SLOT_GLYPHS: Dictionary = {"weapon": "⚔", "armor": "🛡", "accessory": "💍", "relic": "✦"}

@onready var _button_back: Button = $Header/HeaderRow/ButtonBack
@onready var _btn_catalog: Button = $Header/HeaderRow/BtnCatalog
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _btn_member_prev: Button = $VBoxContainer/CharacterCard/CardRow/PortraitBox/PortraitNavRow/BtnMemberPrev
@onready var _btn_member_next: Button = $VBoxContainer/CharacterCard/CardRow/PortraitBox/PortraitNavRow/BtnMemberNext
@onready var _portrait_box: VBoxContainer = $VBoxContainer/CharacterCard/CardRow/PortraitBox
@onready var _portrait_stack: Control = $VBoxContainer/CharacterCard/CardRow/PortraitBox/PortraitNavRow/PortraitStack
@onready var _pedestal_bg: TextureRect = $VBoxContainer/CharacterCard/CardRow/PortraitBox/PortraitNavRow/PortraitStack/PedestalBg
@onready var _portrait_panel: PanelContainer = $VBoxContainer/CharacterCard/CardRow/PortraitBox/PortraitNavRow/PortraitStack/Portrait
@onready var _member_row: HBoxContainer = $VBoxContainer/MemberSelectRow
@onready var _label_stars: Label = $VBoxContainer/CharacterCard/CardRow/PortraitBox/LabelStars
@onready var _portrait_art: TextureRect = $VBoxContainer/CharacterCard/CardRow/PortraitBox/PortraitNavRow/PortraitStack/Portrait/PortraitArt
@onready var _portrait_glyph: Label = $VBoxContainer/CharacterCard/CardRow/PortraitBox/PortraitNavRow/PortraitStack/Portrait/PortraitGlyph
@onready var _label_name: Label = $VBoxContainer/CharacterCard/CardRow/InfoBox/LabelName
@onready var _label_level: Label = $VBoxContainer/CharacterCard/CardRow/InfoBox/LabelLevel
@onready var _job_icon: TextureRect = $VBoxContainer/CharacterCard/CardRow/InfoBox/JobRow/JobIcon
@onready var _label_job: Label = $VBoxContainer/CharacterCard/CardRow/InfoBox/JobRow/LabelJob
@onready var _evolution_row: HBoxContainer = $VBoxContainer/CharacterCard/CardRow/InfoBox/EvolutionRow
@onready var _btn_promote: Button = $VBoxContainer/CharacterCard/CardRow/InfoBox/EvolutionRow/BtnPromote
@onready var _label_evolution: Label = $VBoxContainer/CharacterCard/CardRow/InfoBox/EvolutionRow/LabelEvolution
var _label_evolution_traits: Label = null
@onready var _stats_grid: GridContainer = $VBoxContainer/CharacterCard/CardRow/InfoBox/StatsGrid
@onready var _btn_stat_detail: Button = $VBoxContainer/CharacterCard/CardRow/InfoBox/BtnStatDetail
@onready var _slots_panel: VBoxContainer = $VBoxContainer/CharacterCard/CardRow/SlotsPanel
@onready var _slots_row: GridContainer = $VBoxContainer/CharacterCard/CardRow/SlotsPanel/EquipSlotsGrid
@onready var _equip_content: VBoxContainer = $VBoxContainer/TabContainer/TabEquip/EquipContent
@onready var _effects_panel: PanelContainer = $VBoxContainer/TabContainer/TabEquip/EquipContent/EffectsPanel
@onready var _effects_rule: TextureRect = $VBoxContainer/TabContainer/TabEquip/EquipContent/EffectsPanel/EffectsVBox/EffectsRule
@onready var _effects_grid: GridContainer = $VBoxContainer/TabContainer/TabEquip/EquipContent/EffectsPanel/EffectsVBox/EffectsGrid
@onready var _inventory_scroll: ScrollContainer = $VBoxContainer/TabContainer/TabEquip/EquipContent/InventoryScroll
@onready var _tab_row: HBoxContainer = $VBoxContainer/TabRow
@onready var _btn_sort: Button = $VBoxContainer/TabContainer/TabEquip/EquipContent/InventoryHeaderRow/ButtonSort
@onready var _btn_filter: Button = $VBoxContainer/TabContainer/TabEquip/EquipContent/InventoryHeaderRow/ButtonFilter
@onready var _nav_forge: Button = $BottomNav/NavRow/NavForge
@onready var _character_card: PanelContainer = $VBoxContainer/CharacterCard
@onready var _tabs: TabContainer = $VBoxContainer/TabContainer
@onready var _tactics_content: VBoxContainer = $VBoxContainer/TabContainer/TabTactics/TacticsContent
@onready var _category_row: HBoxContainer = $VBoxContainer/TabContainer/TabEquip/EquipContent/CategoryRow
@onready var _inventory_grid: GridContainer = (
	$VBoxContainer/TabContainer/TabEquip/EquipContent/InventoryScroll/InventoryGrid
)
@onready var _skill_content: VBoxContainer = $VBoxContainer/TabContainer/TabSkill/SkillContent
@onready var _ultimate_content: VBoxContainer = $VBoxContainer/TabContainer/TabUltimate/UltimateContent
@onready var _passive_content: VBoxContainer = $VBoxContainer/TabContainer/TabPassive/PassiveContent

var _combat_setup_panel: PanelContainer = null
var _combat_setup_content: VBoxContainer = null

var _selected_member_index: int = 0
var _inventory_filter: String = "all"
var _inventory_sort: String = "rarity"
var _inventory_equipped_filter: String = "all"
# 戦術セレクタ（P3-D086・スキルタブ上部に動的生成）
var _tactics_option: OptionButton = null
var _tactics_ids: Array[String] = []
var _tactics_summary_label: Label = null
var _gambit_accordion_btn: Button = null
var _gambit_accordion_expanded: bool = false
var _gambit_custom_check: CheckBox = null
var _gambit_custom_box: VBoxContainer = null
var _gambit_target_option: OptionButton = null
var _gambit_target_ids: Array[String] = []
var _gambit_action_opts: Array[OptionButton] = []
var _gambit_action_keys: Array = []
var _gambit_cond_opts: Array[OptionButton] = []
var _gambit_value_edits: Array[LineEdit] = []
var _gambit_range_opts: Array[OptionButton] = []
var _gambit_move_up_btns: Array[Button] = []
var _gambit_move_down_btns: Array[Button] = []
var _gambit_row_preview_labels: Array[Label] = []
var _gambit_ui_syncing: bool = false
var _policy_option: OptionButton = null
var _policy_hint_label: Label = null
const _POLICY_IDS: Array = ["", "safe", "material", "relic", "codex"]
var _tab_buttons: Array[Button] = []
var _category_panels: Dictionary = {}
var _active_tab: int = 0

const _TAB_LABELS: Array[String] = ["装備", "スキル", "必殺技", "パッシブ", "戦術"]
const _TAB_CONTAINER_INDICES: Array[int] = [0, 2, 3, 4, 5]
const _TAB_LOCKED: Array[bool] = [false, false, false, false, false]

var _inv_cell_size: Vector2 = Vector2(EquipmentUiTokens.INV_CELL_PX, EquipmentUiTokens.INV_CELL_PX)
var _slot_cell_size: Vector2 = Vector2(EquipmentUiTokens.SLOT_PX, EquipmentUiTokens.SLOT_PX)
var _detail_overlay: Control = null
var _detail_host: VBoxContainer = null
var _detail_title: Label = null
var _detail_equip_btn: Button = null
var _overlay_item: Resource = null
var _overlay_category: String = ""
var _overlay_relic_id: String = ""
var _overlay_skill_id: String = ""

const INVENTORY_LONG_PRESS_SEC: float = 0.45
var _inv_pointer_down: bool = false
var _inv_long_press_fired: bool = false
var _inv_press_timer: SceneTreeTimer = null
var _inv_press_action: Callable = Callable()
var _detail_pinned: bool = false
var _portrait_idle_textures: Array[Texture2D] = []
var _portrait_idle_frame: int = 0
var _portrait_idle_accum: float = 0.0

func _ready() -> void:
	$Header/HeaderRow/LabelTitle.text = ""
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.CHARACTER)
	_tabs.tabs_visible = false
	_build_tab_row()
	_member_row.visible = false
	_ensure_combat_setup_panel()
	_button_back.pressed.connect(_on_back_pressed)
	_btn_catalog.pressed.connect(_on_catalog_pressed)
	UiTypography.apply_menu_button(_btn_catalog)
	_ensure_item_detail_overlay()
	_btn_member_prev.pressed.connect(_on_member_prev_pressed)
	_btn_member_next.pressed.connect(_on_member_next_pressed)
	_btn_promote.pressed.connect(_on_promote_pressed)
	_btn_sort.pressed.connect(_on_sort_pressed)
	_btn_filter.pressed.connect(_on_filter_pressed)
	_inventory_grid.columns = GRID_COLUMNS
	_inventory_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_inventory_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_inventory_scroll.scroll_deadzone = 12
	_setup_equipment_chrome()
	_build_category_chips()
	_apply_panel_styles()
	_decorate_portrait()
	if GameState.equipment_focus_member_index >= 0:
		_selected_member_index = _clamp_roster_index(GameState.equipment_focus_member_index)
		GameState.equipment_focus_member_index = -1
	call_deferred("_handle_layout_resized")
	_refresh_display()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_handle_layout_resized")

func _handle_layout_resized() -> void:
	if not is_node_ready():
		return
	var old_inv: Vector2 = _inv_cell_size
	var old_slot: Vector2 = _slot_cell_size
	_sync_cell_sizes()
	if old_inv.is_equal_approx(_inv_cell_size) and old_slot.is_equal_approx(_slot_cell_size):
		return
	if not old_inv.is_equal_approx(_inv_cell_size):
		_rebuild_inventory_grid()
	if not old_slot.is_equal_approx(_slot_cell_size):
		_rebuild_equip_slots()

func _setup_equipment_chrome() -> void:
	EquipmentUiTokens.apply_tooltip_theme(self)
	var back_tex: Texture2D = EquipmentUiTokens.back_icon()
	if back_tex != null:
		_button_back.text = ""
		_button_back.icon = back_tex
		_button_back.expand_icon = true
		_button_back.custom_minimum_size = Vector2(40, 40)
	var pedestal_tex: Texture2D = EquipmentUiTokens.load_tex(EquipmentUiTokens.PORTRAIT_PEDESTAL)
	if pedestal_tex != null:
		_pedestal_bg.texture = pedestal_tex
	var rule_tex: Texture2D = EquipmentUiTokens.load_tex(EquipmentUiTokens.SECTION_RULE)
	if rule_tex != null:
		_effects_rule.texture = rule_tex
	var filter_tex: Texture2D = EquipmentUiTokens.filter_icon()
	if filter_tex != null:
		_btn_filter.icon = filter_tex
		_btn_filter.expand_icon = true
	_btn_stat_detail.custom_minimum_size = Vector2(0, 34)
	_btn_stat_detail.add_theme_stylebox_override("disabled", EquipmentUiTokens.stat_detail_button_style())
	_btn_stat_detail.add_theme_color_override("font_disabled_color", Color(0.62, 0.58, 0.52, 1.0))
	_evolution_row.add_theme_constant_override("separation", 4)
	UiTypography.apply_display(_label_name, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_level, UiTypography.SIZE_BODY, UiTypography.COLOR_BODY)
	UiTypography.apply_body(_label_job, UiTypography.SIZE_BODY, UiTypography.COLOR_BODY)
	UiTypography.apply_caption(
		$VBoxContainer/TabContainer/TabEquip/EquipContent/InventoryHeaderRow/LabelInventoryTitle,
		UiTypography.COLOR_BODY
	)
	UiTypography.apply_body(
		$VBoxContainer/TabContainer/TabEquip/EquipContent/EffectsPanel/EffectsVBox/LabelEffectsTitle,
		UiTypography.SIZE_BODY_SMALL,
		UiTypography.COLOR_GOLD
	)
	_effects_panel.add_theme_stylebox_override(
		"panel", _framed_box(COLOR_GOLD, 1, Color(0.08, 0.07, 0.05, 0.88))
	)
	_evolution_row.visible = false
	_btn_stat_detail.visible = false
	_slots_panel.custom_minimum_size.x = EquipmentUiTokens.SLOT_PANEL_MIN_W
	_slots_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equip_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _apply_button_style(btn: Button, style: StyleBox) -> void:
	if style is StyleBoxTexture and (style as StyleBoxTexture).texture != null:
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_color_override("font_color", Color(0.98, 0.92, 0.72, 1.0))

func _build_tab_row() -> void:
	for child in _tab_row.get_children():
		child.queue_free()
	_tab_buttons.clear()
	for i in _TAB_LABELS.size():
		var btn := Button.new()
		btn.text = _TAB_LABELS[i] + (" 🔒" if _TAB_LOCKED[i] else "")
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		btn.focus_mode = Control.FOCUS_NONE
		var tab_idx: int = i
		btn.pressed.connect(func(): _set_active_tab(tab_idx))
		_tab_row.add_child(btn)
		_tab_buttons.append(btn)
		UiTypography.apply_menu_button(btn)
	_set_active_tab(0)

func _set_active_tab(tab_idx: int) -> void:
	if tab_idx < 0 or tab_idx >= _TAB_LABELS.size():
		return
	if _TAB_LOCKED[tab_idx]:
		return
	_active_tab = tab_idx
	_tabs.current_tab = _TAB_CONTAINER_INDICES[tab_idx]
	_update_tab_styles()

func _update_tab_styles() -> void:
	for i in _tab_buttons.size():
		EquipmentUiTokens.apply_tab_button(_tab_buttons[i], i == _active_tab, _TAB_LOCKED[i])
		if not _TAB_LOCKED[i]:
			_tab_buttons[i].add_theme_font_size_override("font_size", 16 if i == _active_tab else 15)

func _build_category_chips() -> void:
	for child in _category_row.get_children():
		child.queue_free()
	_category_panels.clear()
	for cat in ["all", "weapon", "armor", "accessory", "relic"]:
		var wrap := PanelContainer.new()
		wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrap.custom_minimum_size = EquipmentUiTokens.CATEGORY_MIN_SIZE
		wrap.add_theme_stylebox_override(
			"panel", EquipmentUiTokens.category_tab_style(_inventory_filter == cat)
		)
		_category_row.add_child(wrap)
		_category_panels[cat] = wrap
		var col := VBoxContainer.new()
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.offset_left = 2
		col.offset_top = 2
		col.offset_right = -2
		col.offset_bottom = -2
		col.add_theme_constant_override("separation", 0)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(col)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(40, 40)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = EquipmentUiTokens.category_icon(cat)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(icon)
		var lbl := Label.new()
		lbl.text = EquipmentUiHelper.category_label(cat)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_caption(lbl)
		col.add_child(lbl)
		var btn := Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.pressed.connect(func(): _on_category_selected(cat))
		wrap.add_child(btn)

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
	_character_card.add_theme_stylebox_override("panel", EquipmentUiTokens.char_card_style())

func _decorate_portrait() -> void:
	# 台座の上に正面 Idle を大きく載せる（モック構図）。
	_portrait_stack.custom_minimum_size = EquipmentUiTokens.PORTRAIT_STACK_SIZE
	_pedestal_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_pedestal_bg.offset_left = 0.0
	_pedestal_bg.offset_right = 0.0
	_pedestal_bg.offset_top = -float(EquipmentUiTokens.PEDESTAL_HEIGHT_PX)
	_pedestal_bg.offset_bottom = 0.0
	_pedestal_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pedestal_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pedestal_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_pedestal_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pedestal_bg.z_index = 0

	var empty := StyleBoxEmpty.new()
	_portrait_panel.add_theme_stylebox_override("panel", empty)
	var char_px: float = float(EquipmentUiTokens.PORTRAIT_PX)
	var overlap: float = float(EquipmentUiTokens.PORTRAIT_PEDESTAL_OVERLAP_PX)
	var pedestal_h: float = float(EquipmentUiTokens.PEDESTAL_HEIGHT_PX)
	_portrait_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_portrait_panel.offset_left = -char_px * 0.5
	_portrait_panel.offset_right = char_px * 0.5
	_portrait_panel.offset_bottom = -(pedestal_h - overlap)
	_portrait_panel.offset_top = _portrait_panel.offset_bottom - char_px
	_portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_panel.z_index = 1

	_portrait_art.custom_minimum_size = Vector2(char_px, char_px)
	_portrait_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_glyph.add_theme_font_size_override("font_size", 36)
	_portrait_glyph.add_theme_color_override("font_color", COLOR_GOLD)

	# 星は台座の下（PortraitNavRow の後）へ。
	if _label_stars.get_parent() == _portrait_box:
		_portrait_box.move_child(_label_stars, _portrait_box.get_child_count() - 1)
	_label_stars.visible = true
	_label_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(_label_stars, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)

func _process(delta: float) -> void:
	if _portrait_idle_textures.size() <= 1:
		return
	_portrait_idle_accum += delta
	var frame_dur: float = 1.0 / _ChrIdlePortrait.IDLE_FPS
	if _portrait_idle_accum < frame_dur:
		return
	_portrait_idle_accum = 0.0
	_portrait_idle_frame = (_portrait_idle_frame + 1) % _portrait_idle_textures.size()
	_portrait_art.texture = _portrait_idle_textures[_portrait_idle_frame]

func _set_character_portrait(member: Resource) -> void:
	_portrait_idle_textures.clear()
	_portrait_idle_frame = 0
	_portrait_idle_accum = 0.0
	if member == null:
		_portrait_art.texture = null
		_portrait_glyph.text = "?"
		return
	var job_id: String = str(member.job_id)
	var idle_texs: Array[Texture2D] = _ChrIdlePortrait.load_idle_textures(job_id)
	if not idle_texs.is_empty():
		_portrait_idle_textures = idle_texs
		_portrait_art.texture = idle_texs[0]
		_portrait_glyph.text = ""
		return
	# Idle 未配置時は従来バスト／立ち絵へフォールバック
	var chr_tex: Texture2D = RosterUiHelper.get_member_portrait_texture(member)
	_portrait_art.texture = chr_tex
	_portrait_glyph.text = "" if chr_tex != null else member.display_name.substr(0, 1)

func _on_category_selected(filter_id: String) -> void:
	_inventory_filter = filter_id
	_refresh_category_buttons()
	_rebuild_inventory_grid()

func _refresh_category_buttons() -> void:
	for cat in _category_panels.keys():
		var panel: PanelContainer = _category_panels[cat]
		if panel != null:
			panel.add_theme_stylebox_override(
				"panel", EquipmentUiTokens.category_tab_style(_inventory_filter == str(cat))
			)

func _on_member_selected(member_index: int) -> void:
	_selected_member_index = member_index
	_refresh_display()

func _on_member_prev_pressed() -> void:
	_cycle_member(-1)

func _on_member_next_pressed() -> void:
	_cycle_member(1)

func _cycle_member(delta: int) -> void:
	var count: int = GameState.get_roster().size()
	if count <= 0:
		return
	var next_index: int = (_selected_member_index + delta + count) % count
	_on_member_selected(next_index)

func _clamp_roster_index(index: int) -> int:
	var roster: Array = GameState.get_roster()
	if roster.is_empty():
		return 0
	if index >= 0 and index < roster.size():
		return index
	var party_idx: int = clampi(index, 0, maxi(0, GameState.party_members.size() - 1))
	if party_idx < GameState.party_members.size():
		var adv: Resource = GameState.party_members[party_idx]
		var roster_idx: int = roster.find(adv)
		if roster_idx >= 0:
			return roster_idx
	return clampi(index, 0, roster.size() - 1)

func _get_view_adventurer() -> Resource:
	var roster: Array = GameState.get_roster()
	if _selected_member_index < 0 or _selected_member_index >= roster.size():
		return null
	return roster[_selected_member_index]

func _party_index_for(adv: Resource) -> int:
	if adv == null:
		return -1
	return GameState.party_members.find(adv)

func _party_index_for_view() -> int:
	return _party_index_for(_get_view_adventurer())

func _refresh_display() -> void:
	_update_header()
	_update_character_card()
	_rebuild_equip_slots()
	_rebuild_effects()
	_refresh_category_buttons()
	_refresh_inventory_tools()
	_rebuild_inventory_grid()
	_rebuild_skill_tab()
	_rebuild_ultimate_tab()
	_rebuild_passive_tab()
	_rebuild_tactics_tab()
	_update_forge_nav_dot()

func _update_forge_nav_dot() -> void:
	NavUiTokens.set_bottom_nav_text(
		_nav_forge,
		"鍛冶屋 ●" if BlacksmithUiHelper.has_craftable_recipes() else "鍛冶屋"
	)

func _update_header() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()

# ---- キャラクターカード ----
func _update_character_card() -> void:
	var member: Resource = _get_view_adventurer()
	if member == null:
		_label_name.text = "—"
		_label_level.text = ""
		_label_job.text = ""
		_job_icon.texture = null
		_set_character_portrait(null)
		_job_icon.modulate = Color.WHITE
		_portrait_art.modulate = Color.WHITE
		_label_stars.text = ""
		_evolution_row.visible = false
		return
	_label_name.text = member.display_name
	_label_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label_name.max_lines_visible = 1
	var job_mods: Dictionary = _JobStatCalculator.get_member_modifiers(member)
	var job_name: String = str(job_mods.get("display_name", member.job_id))
	_label_level.text = EquipmentUiHelper.level_line(int(member.level))
	_label_job.text = job_name
	_label_job.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label_job.max_lines_visible = 1
	_job_icon.texture = IconPaths.get_icon_texture(str(member.job_id), "chr")
	_set_character_portrait(member)
	_label_stars.text = EquipmentUiHelper.rarity_stars_text(int(member.rarity))
	_label_stars.visible = true
	var portrait_tint: Color = _EvolutionVisual.portrait_modulate(member)
	_job_icon.modulate = portrait_tint
	_portrait_art.modulate = portrait_tint
	var party_idx: int = _party_index_for(member)
	var stats: Dictionary = _compute_member_stats(party_idx if party_idx >= 0 else -1, member)
	_populate_stat_grid(stats)

func _update_evolution_row(member: Resource) -> void:
	var target_name: String = _JobEvolution.get_evolved_name(member)
	if target_name.is_empty():
		_evolution_row.visible = false
		return
	_evolution_row.visible = true
	var evolved: bool = bool(member.is_evolved)
	var can_promote: bool = _JobEvolution.can_evolve(member)
	if evolved:
		_label_evolution.text = "昇格済 — %s" % target_name
		_label_evolution.add_theme_color_override("font_color", COLOR_POS)
		_btn_promote.text = "昇格済"
		_btn_promote.disabled = true
	elif can_promote:
		_label_evolution.text = "→ %s" % target_name
		_label_evolution.add_theme_color_override("font_color", COLOR_SUB)
		_btn_promote.text = "昇格する"
		_btn_promote.disabled = false
	else:
		var req: int = _JobEvolution.required_level(member)
		_label_evolution.text = "→ %s" % target_name
		_label_evolution.add_theme_color_override("font_color", COLOR_SUB)
		_btn_promote.text = "Lv%d必要" % req if req > 0 else "対象外"
		_btn_promote.disabled = true
	_label_evolution.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label_evolution.max_lines_visible = 1
	_label_evolution.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_evolution.clip_text = true
	_update_evolution_traits_label(member)

func _ensure_evolution_traits_label() -> void:
	if _label_evolution_traits != null:
		return
	_label_evolution_traits = Label.new()
	_label_evolution_traits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_evolution_traits.max_lines_visible = 2
	_label_evolution_traits.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label_evolution_traits.add_theme_font_size_override("font_size", 11)
	var info_box: Node = _evolution_row.get_parent()
	info_box.add_child(_label_evolution_traits)
	info_box.move_child(_label_evolution_traits, _evolution_row.get_index() + 1)

func _update_evolution_traits_label(member: Resource) -> void:
	if member == null or _JobEvolution.get_evolved_name(member).is_empty():
		if _label_evolution_traits != null:
			_label_evolution_traits.visible = false
		return
	_ensure_evolution_traits_label()
	var lines: PackedStringArray = (
		_EvolutionTraits.trait_summary_lines(member)
		if bool(member.is_evolved)
		else _EvolutionTraits.preview_summary_lines(str(member.job_id))
	)
	if lines.is_empty():
		_label_evolution_traits.visible = false
		return
	var prefix: String = "昇格特質" if bool(member.is_evolved) else "昇格で解放"
	_label_evolution_traits.text = "%s:\n• %s" % [prefix, "\n• ".join(lines)]
	_label_evolution_traits.visible = true
	_label_evolution_traits.add_theme_color_override(
		"font_color", COLOR_POS if bool(member.is_evolved) else COLOR_SUB
	)

func _on_promote_pressed() -> void:
	var member: Resource = _get_view_adventurer()
	if member == null or not _JobEvolution.evolve(member):
		return
	SaveManager.save_game()
	_refresh_display()

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
	_stats_grid.add_theme_constant_override("v_separation", 4)
	_stats_grid.add_theme_constant_override("h_separation", 10)
	for r in rows:
		_stats_grid.add_child(_make_stat_label_row(str(r[0]), str(r[1])))
		_stats_grid.add_child(_make_value_label(str(r[2])))

func _make_stat_label_row(stat_key: String, label_text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stat_tex: Texture2D = EquipmentUiTokens.stat_icon(stat_key)
	if stat_tex != null:
		var icon := TextureRect.new()
		icon.texture = stat_tex
		icon.custom_minimum_size = Vector2(
			EquipmentUiTokens.STAT_ICON_PX, EquipmentUiTokens.STAT_ICON_PX
		)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	var lbl := _make_dim_label(label_text)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	return row

func _make_dim_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	UiTypography.apply_body(l, STAT_LABEL_FONT_SIZE, COLOR_SUB)
	return l

func _make_value_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	UiTypography.apply_body(l, STAT_VALUE_FONT_SIZE, COLOR_VALUE, UiTypography.OUTLINE_STRONG)
	return l

func _make_pos_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_body(l, STAT_VALUE_FONT_SIZE, COLOR_POS, UiTypography.OUTLINE_STRONG)
	return l

# ---- 装備中の効果（装備品由来のボーナス集計） ----
func _rebuild_effects() -> void:
	for child in _effects_grid.get_children():
		child.queue_free()
	var member: Resource = _get_view_adventurer()
	var bonuses: Dictionary = _compute_equipment_effect_bonuses(member)
	_add_effects_row(
		"攻撃力", "attack", _format_effect_int(int(bonuses.get("attack", 0))),
		"クリティカル率", "crit_rate", _format_effect_percent(float(bonuses.get("crit_rate", 0.0)))
	)
	_add_effects_row(
		"防御力", "defense", _format_effect_int(int(bonuses.get("defense", 0))),
		"クリティカルダメージ", "crit_damage", _format_effect_percent(float(bonuses.get("crit_damage", 0.0)))
	)
	_add_effects_row(
		"HP", "hp", _format_effect_int(int(bonuses.get("hp", 0))),
		"攻撃速度", "speed", _format_effect_speed(float(bonuses.get("attack_speed", 0.0)))
	)

func _compute_equipment_effect_bonuses(member: Resource) -> Dictionary:
	var result: Dictionary = {
		"attack": 0,
		"defense": 0,
		"hp": 0,
		"crit_rate": 0.0,
		"crit_damage": 0.0,
		"attack_speed": 0.0,
	}
	if member == null:
		return result
	var party_idx: int = _party_index_for(member)
	var armor: Resource = member.equipped_armor
	var weapon: Resource = member.equipped_weapon
	var acc_data: Resource = _accessory_data(member.equipped_accessory)
	var affix: Dictionary = _AffixStatCalculator.get_bonuses(party_idx) if party_idx >= 0 else {}
	result["attack"] = int(affix.get("attack_flat", 0))
	if acc_data != null and member.equipped_accessory != null:
		result["attack"] += EquipmentEnhancer.effective_accessory_int_bonus(
			member.equipped_accessory, "attack_bonus", acc_data
		)
	result["defense"] = int(affix.get("defense_flat", 0))
	if acc_data != null and member.equipped_accessory != null:
		result["defense"] += EquipmentEnhancer.effective_accessory_int_bonus(
			member.equipped_accessory, "defense_bonus", acc_data
		)
	if armor != null:
		result["defense"] += EquipmentEnhancer.effective_armor_defense(armor)
	result["hp"] = int(affix.get("hp_flat", 0))
	if acc_data != null and member.equipped_accessory != null:
		result["hp"] += EquipmentEnhancer.effective_accessory_int_bonus(
			member.equipped_accessory, "hp_bonus", acc_data
		)
	if armor != null:
		result["hp"] += EquipmentEnhancer.effective_armor_hp(armor)
	result["crit_rate"] = float(affix.get("crit_rate_add", 0.0))
	if acc_data != null and member.equipped_accessory != null:
		result["crit_rate"] += EquipmentEnhancer.effective_accessory_float_bonus(
			member.equipped_accessory, "crit_rate_bonus", acc_data
		)
	if weapon != null:
		result["crit_rate"] += float(weapon.critical_rate)
		result["attack_speed"] = maxf(0.0, float(weapon.attack_speed) - 1.0)
	result["attack_speed"] += float(affix.get("attack_speed_mult_add", 0.0))
	return result

func _add_effects_row(
	left_label: String,
	left_key: String,
	left_value: String,
	right_label: String,
	right_key: String,
	right_value: String
) -> void:
	_effects_grid.add_child(_make_stat_label_row(left_key, left_label))
	_effects_grid.add_child(_make_pos_label(left_value))
	_effects_grid.add_child(_make_stat_label_row(right_key, right_label))
	_effects_grid.add_child(_make_pos_label(right_value))

func _format_effect_int(value: int) -> String:
	return "+%d" % value

func _format_effect_percent(value: float) -> String:
	return "+%.0f%%" % (value * 100.0)

func _format_effect_speed(value: float) -> String:
	if is_zero_approx(value):
		return "+0"
	return "+%.1f" % value

# ---- 装備スロット ----
func _rebuild_equip_slots() -> void:
	_sync_slot_cell_size()
	for child in _slots_row.get_children():
		child.queue_free()
	var member: Resource = _get_view_adventurer()
	var can_equip: bool = _party_index_for(member) >= 0
	if member == null:
		return
	var cell_size: Vector2 = _slot_cell_size_vec()
	_slots_row.add_child(_make_slot("武器", "weapon", member.equipped_weapon, can_equip, cell_size))
	_slots_row.add_child(_make_slot("防具", "armor", member.equipped_armor, can_equip, cell_size))
	_slots_row.add_child(_make_slot("装飾", "accessory", member.equipped_accessory, can_equip, cell_size))
	_slots_row.add_child(_make_relic_slot(cell_size, member, can_equip))

func _make_relic_slot(cell_size: Vector2, member: Resource, can_equip: bool) -> Control:
	var cell_px: int = int(cell_size.x)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var cap := Label.new()
	cap.text = "レリック"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_color_override("font_color", COLOR_SUB)
	cap.add_theme_font_size_override("font_size", 11)
	box.add_child(cap)
	var btn := Button.new()
	btn.custom_minimum_size = cell_size
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	var relic_id: String = GameState.get_equipped_relic_passive_id(member) if member != null else ""
	var icon_key: String = CombatPassives.relic_icon_key(relic_id)
	var relic_tex: Texture2D = (
		IconPaths.get_icon_texture(icon_key, "relic") if not icon_key.is_empty() else null
	)
	if relic_tex != null:
		_attach_item_icon(btn, relic_tex, cell_px, EquipmentUiTokens.SLOT_DESIGN_PX)
		btn.tooltip_text = "%s\n%s" % [
			CombatPassives.relic_display_name(relic_id),
			CombatPassives.relic_description(relic_id),
		]
		_apply_item_cell_styles(btn, 0, cell_px)
	else:
		btn.text = str(SLOT_GLYPHS.get("relic", "✦"))
		btn.add_theme_font_size_override("font_size", maxi(18, int(float(cell_px) * 0.34)))
		btn.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35, 0.7))
		btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
		_apply_item_cell_styles(btn, 0, cell_px)
	btn.pressed.connect(_on_relic_slot_pressed)
	btn.disabled = not can_equip
	box.add_child(btn)
	return box

func _on_relic_slot_pressed() -> void:
	_inventory_filter = "relic"
	_refresh_category_buttons()
	_rebuild_inventory_grid()
	_set_active_tab(0)

func _make_locked_slot(label: String, cell_size: Vector2) -> Control:
	var cell_px: int = int(cell_size.x)
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
	btn.custom_minimum_size = cell_size
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	btn.disabled = true
	btn.text = ""
	btn.add_theme_stylebox_override("disabled", EquipmentUiTokens.slot_locked_style(cell_px))
	box.add_child(btn)
	return box

func _make_slot(
	slot_label: String,
	category: String,
	item: Resource,
	can_equip: bool = true,
	cell_size: Vector2 = _slot_cell_size_vec()
) -> Control:
	var cell_px: int = int(cell_size.x)
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
	btn.custom_minimum_size = cell_size
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	if item != null:
		var icon: Texture2D = _item_icon(item, category)
		_attach_item_icon(btn, icon, cell_px, EquipmentUiTokens.SLOT_DESIGN_PX)
		btn.tooltip_text = _item_label(item, category)
		var rarity: int = _item_rarity(item, category)
		_apply_item_cell_styles(btn, rarity, cell_px)
		_apply_item_badges(btn, item, category, cell_size, true)
	else:
		btn.text = str(SLOT_GLYPHS.get(category, "+"))
		btn.add_theme_font_size_override("font_size", maxi(18, int(float(cell_px) * 0.34)))
		btn.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35, 0.7))
		btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
		_apply_item_cell_styles(btn, 0, cell_px)
	btn.pressed.connect(_on_slot_pressed.bind(category))
	btn.disabled = not can_equip
	box.add_child(btn)
	return box

func _on_slot_pressed(category: String) -> void:
	_inventory_filter = category
	_refresh_category_buttons()
	_rebuild_inventory_grid()
	_set_active_tab(0)

func _sync_cell_sizes() -> void:
	_sync_inventory_cell_size()
	_sync_slot_cell_size()

func _inventory_grid_width() -> float:
	var scroll: ScrollContainer = $VBoxContainer/TabContainer/TabEquip as ScrollContainer
	if scroll != null and scroll.size.x >= 100.0:
		return scroll.size.x
	if _inventory_grid.size.x >= 100.0:
		return _inventory_grid.size.x
	if _equip_content.size.x >= 100.0:
		return _equip_content.size.x
	return maxf(100.0, size.x - 16.0)

func _sync_inventory_cell_size() -> void:
	var sep: int = _inventory_grid.get_theme_constant("h_separation", "GridContainer")
	var cell_px: int = EquipmentUiTokens.cell_px_for_grid_width(
		_inventory_grid_width(),
		GRID_COLUMNS,
		sep
	)
	_inv_cell_size = Vector2(cell_px, cell_px)
	_update_inventory_viewport_height()

func _update_inventory_viewport_height() -> void:
	var cell_size: Vector2 = _inv_cell_size_vec()
	var v_sep: int = _inventory_grid.get_theme_constant("v_separation", "GridContainer")
	var height: float = cell_size.y * float(INV_VISIBLE_ROWS) + float(v_sep * maxi(0, INV_VISIBLE_ROWS - 1))
	_inventory_scroll.custom_minimum_size.y = height
	_inventory_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func _slot_panel_width() -> float:
	var panel_w: float = maxf(_slots_panel.size.x, _slots_row.size.x)
	if panel_w >= 120.0:
		return panel_w
	return float(EquipmentUiTokens.SLOT_PANEL_MIN_W)

func _sync_slot_cell_size() -> void:
	var sep: int = _slots_row.get_theme_constant("h_separation", "GridContainer")
	var cell_px: int = EquipmentUiTokens.cell_px_for_slot_panel(
		_slot_panel_width(),
		SLOT_COLUMNS,
		sep
	)
	_slot_cell_size = Vector2(cell_px, cell_px)

func _inv_cell_size_vec() -> Vector2:
	return _inv_cell_size

func _slot_cell_size_vec() -> Vector2:
	return _slot_cell_size

func _attach_item_icon(btn: Button, icon: Texture2D, cell_px: int, design_px: int) -> void:
	if icon == null:
		return
	var inset: int = EquipmentUiTokens.icon_inset_px(cell_px, design_px)
	var tex_rect := TextureRect.new()
	tex_rect.name = "ItemIcon"
	tex_rect.texture = icon
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.offset_left = inset
	tex_rect.offset_top = inset
	tex_rect.offset_right = -inset
	tex_rect.offset_bottom = -inset
	btn.add_child(tex_rect)

# ---- 所持一覧グリッド ----
func _rebuild_inventory_grid() -> void:
	_sync_inventory_cell_size()
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
	if _inventory_filter == "relic":
		for rid in GameState.owned_relics:
			var relic_id: String = str(rid)
			if relic_id.is_empty():
				continue
			entries.append({"relic_id": relic_id, "category": "relic"})
	entries = EquipmentUiHelper.filter_by_equipped_state(
		entries, _inventory_equipped_filter, _party_index_for_view()
	)
	if entries.is_empty():
		var empty_msg: String = "該当する装備がありません"
		if _inventory_filter == "relic":
			empty_msg = "所持しているレリックがありません"
		_inventory_grid.add_child(_make_dim_label(empty_msg))
		return
	for e in EquipmentUiHelper.sort_inventory_entries(entries, _inventory_sort):
		if str(e.get("category", "")) == "relic":
			_inventory_grid.add_child(_make_relic_cell(str(e.get("relic_id", ""))))
		else:
			_inventory_grid.add_child(_make_item_cell(e["item"], str(e["category"])))

func _make_item_cell(item: Resource, category: String) -> Button:
	var cell_size: Vector2 = _inv_cell_size_vec()
	var cell_px: int = int(cell_size.x)
	var btn := Button.new()
	btn.custom_minimum_size = cell_size
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	var icon: Texture2D = _item_icon(item, category)
	_attach_item_icon(btn, icon, cell_px, EquipmentUiTokens.INV_CELL_DESIGN_PX)
	var rarity: int = _item_rarity(item, category)
	var owner_idx: int = EquipmentUiHelper.equipped_member_index(item)
	var party_idx: int = _party_index_for_view()
	var is_on_self: bool = party_idx >= 0 and owner_idx == party_idx
	var member: Resource = _get_view_adventurer()
	btn.tooltip_text = EquipmentItemDetailHelper.hover_summary(item, category, member)
	var captured_item: Resource = item
	var captured_category: String = category
	btn.pressed.connect(func() -> void:
		_tap_inventory_item(captured_item, captured_category)
	)
	btn.disabled = party_idx < 0
	if is_on_self:
		btn.modulate = Color(0.72, 0.72, 0.72, 0.85)
		_apply_item_cell_styles(btn, rarity, cell_px, true)
	else:
		_apply_item_cell_styles(btn, rarity, cell_px)
	_apply_item_badges(btn, item, category, cell_size, is_on_self)
	if owner_idx >= 0:
		_add_owner_portrait_badge(btn, owner_idx, cell_size)
	return btn

func _make_relic_cell(relic_id: String) -> Button:
	var cell_size: Vector2 = _inv_cell_size_vec()
	var cell_px: int = int(cell_size.x)
	var btn := Button.new()
	btn.custom_minimum_size = cell_size
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	var icon_key: String = CombatPassives.relic_icon_key(relic_id)
	var tex: Texture2D = IconPaths.get_icon_texture(icon_key, "relic")
	_attach_item_icon(btn, tex, cell_px, EquipmentUiTokens.INV_CELL_DESIGN_PX)
	var owner_idx: int = EquipmentUiHelper.relic_equipped_member_index(relic_id)
	var party_idx: int = _party_index_for_view()
	var is_on_self: bool = party_idx >= 0 and owner_idx == party_idx
	btn.tooltip_text = EquipmentItemDetailHelper.relic_hover_summary(relic_id)
	var captured_relic_id: String = relic_id
	btn.pressed.connect(func() -> void:
		_on_relic_equip_pressed(captured_relic_id)
	)
	btn.disabled = party_idx < 0
	if is_on_self:
		btn.modulate = Color(0.72, 0.72, 0.72, 0.85)
		_apply_item_cell_styles(btn, 2, cell_px, true)
	else:
		_apply_item_cell_styles(btn, 2, cell_px)
	if owner_idx >= 0:
		_add_owner_portrait_badge(btn, owner_idx, cell_size)
	return btn

func _bind_inventory_cell_interaction(btn: Button, action: Callable) -> void:
	btn.gui_input.connect(_on_inventory_cell_gui_input.bind(action))

func _on_inventory_cell_gui_input(event: InputEvent, action: Callable) -> void:
	if event is InputEventScreenDrag:
		_cancel_inventory_press()
		return
	if not _is_inventory_pointer_event(event):
		return
	if event.pressed:
		_begin_inventory_press(action)
	else:
		_end_inventory_press()
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		event.accept_event()

func _is_inventory_pointer_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return true
	return false

func _begin_inventory_press(action: Callable) -> void:
	_cancel_inventory_press()
	_inv_pointer_down = true
	_inv_long_press_fired = false
	_inv_press_action = action
	_inv_press_timer = get_tree().create_timer(INVENTORY_LONG_PRESS_SEC)
	_inv_press_timer.timeout.connect(_on_inventory_long_press_timeout)

func _on_inventory_long_press_timeout() -> void:
	if not _inv_pointer_down:
		return
	_inv_long_press_fired = true
	if _inv_press_action.is_valid():
		_inv_press_action.call(true)

func _end_inventory_press() -> void:
	if not _inv_pointer_down:
		return
	_inv_pointer_down = false
	_cancel_inventory_press_timer_only()
	if not _inv_long_press_fired and _inv_press_action.is_valid():
		_inv_press_action.call(false)
	_inv_press_action = Callable()

func _cancel_inventory_press_timer_only() -> void:
	if _inv_press_timer != null:
		if _inv_press_timer.timeout.is_connected(_on_inventory_long_press_timeout):
			_inv_press_timer.timeout.disconnect(_on_inventory_long_press_timeout)
		_inv_press_timer = null

func _cancel_inventory_press() -> void:
	_inv_pointer_down = false
	_inv_long_press_fired = false
	_cancel_inventory_press_timer_only()
	_inv_press_action = Callable()

func _tap_inventory_item(item: Resource, category: String) -> void:
	var party_idx: int = _party_index_for_view()
	if party_idx < 0:
		return
	var owner_idx: int = EquipmentUiHelper.equipped_member_index(item)
	if owner_idx == party_idx:
		match category:
			"weapon":
				$EquipmentController.unequip_weapon(party_idx)
			"armor":
				$EquipmentController.unequip_armor(party_idx)
			"accessory":
				$EquipmentController.unequip_accessory(party_idx)
		_refresh_display()
	else:
		_on_cell_pressed(item, category)

func _show_relic_stats_overlay(relic_id: String, pinned: bool = false) -> void:
	_ensure_item_detail_overlay()
	_detail_pinned = pinned
	_overlay_item = null
	_overlay_category = "relic"
	_overlay_relic_id = relic_id
	_overlay_skill_id = ""
	if _detail_title != null:
		_detail_title.text = "遺物詳細"
	for child in _detail_host.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = CombatPassives.relic_display_name(relic_id)
	UiTypography.apply_body(title, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	_detail_host.add_child(title)
	var desc := Label.new()
	desc.text = CombatPassives.relic_description(relic_id)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(desc, UiTypography.SIZE_CAPTION, UiTypography.COLOR_BODY)
	_detail_host.add_child(desc)
	var owner_idx: int = EquipmentUiHelper.relic_equipped_member_index(relic_id)
	var party_idx: int = _party_index_for_view()
	var is_on_self: bool = party_idx >= 0 and owner_idx == party_idx
	_detail_equip_btn.text = "外す" if is_on_self else "装備する"
	_detail_equip_btn.visible = party_idx >= 0
	_detail_equip_btn.disabled = party_idx < 0 or (owner_idx >= 0 and not is_on_self)
	_detail_overlay.visible = true

func _add_owner_portrait_badge(btn: Button, owner_idx: int, cell_size: Vector2) -> void:
	var member: Resource = GameState.get_member(owner_idx)
	if member == null:
		return
	var tex: Texture2D = IconPaths.get_icon_texture(str(member.job_id), "chr")
	if tex == null:
		return
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(cell_size.x - 18.0, 2.0)
	btn.add_child(icon)

func _ensure_item_detail_overlay() -> void:
	if _detail_overlay != null:
		return
	_detail_overlay = Control.new()
	_detail_overlay.name = "ItemDetailOverlay"
	_detail_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_overlay.visible = false
	_detail_overlay.z_index = 60
	_detail_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_detail_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.58)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_item_detail_dim_input)
	_detail_overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -360.0
	panel.add_theme_stylebox_override("panel", EquipmentUiTokens.tooltip_panel_style())
	_detail_overlay.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	margin.add_child(outer)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	outer.add_child(header)
	var title := Label.new()
	title.text = "装備性能"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_display(title, UiTypography.SIZE_BODY_SMALL)
	header.add_child(title)
	_detail_title = title
	var close_btn := Button.new()
	close_btn.text = "閉じる"
	UiTypography.apply_menu_button(close_btn)
	close_btn.pressed.connect(_hide_item_detail_overlay)
	header.add_child(close_btn)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_detail_host = VBoxContainer.new()
	_detail_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_detail_host)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	action_row.alignment = BoxContainer.ALIGNMENT_END
	outer.add_child(action_row)
	_detail_equip_btn = Button.new()
	_detail_equip_btn.text = "装備する"
	UiTypography.apply_menu_button(_detail_equip_btn)
	_detail_equip_btn.pressed.connect(_on_detail_equip_pressed)
	action_row.add_child(_detail_equip_btn)

func _show_item_stats_overlay(item: Resource, category: String, pinned: bool = false) -> void:
	_ensure_item_detail_overlay()
	_detail_pinned = pinned
	_overlay_item = item
	_overlay_category = category
	_overlay_skill_id = ""
	if _detail_title != null:
		_detail_title.text = "装備性能"
	EquipmentItemDetailHelper.populate_stats_panel(_detail_host, item, category)
	var party_idx: int = _party_index_for_view()
	var owner_idx: int = EquipmentUiHelper.equipped_member_index(item)
	var can_equip: bool = party_idx >= 0 and owner_idx != party_idx
	_detail_equip_btn.visible = can_equip
	_detail_equip_btn.disabled = not can_equip
	_detail_overlay.visible = true

func _on_detail_equip_pressed() -> void:
	if _overlay_category == "skill":
		if not _overlay_skill_id.is_empty():
			_on_skill_toggle_pressed(_overlay_skill_id)
		_hide_item_detail_overlay()
		return
	if _overlay_category == "relic":
		if not _overlay_relic_id.is_empty():
			_on_relic_equip_pressed(_overlay_relic_id)
		_hide_item_detail_overlay()
		return
	if _overlay_item == null or _overlay_category.is_empty():
		return
	_on_cell_pressed(_overlay_item, _overlay_category)
	_hide_item_detail_overlay()

func _on_relic_equip_pressed(relic_id: String) -> void:
	var party_idx: int = _party_index_for_view()
	if party_idx < 0:
		return
	var member: Resource = GameState.get_member(party_idx)
	if member == null:
		return
	var pid: String = CombatPassives.migrate_relic_passive_id(relic_id)
	if GameState.get_equipped_relic_passive_id(member) == pid:
		GameState.set_member_relic(member, "")
	else:
		GameState.set_member_relic(member, relic_id)
	_refresh_display()

func _hide_item_detail_overlay() -> void:
	if _detail_overlay != null:
		_detail_overlay.visible = false
	_detail_pinned = false
	_overlay_item = null
	_overlay_category = ""
	_overlay_relic_id = ""
	_overlay_skill_id = ""

func _on_item_detail_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_item_detail_overlay()

func _on_catalog_pressed() -> void:
	if ResourceLoader.exists(CATALOG_SCENE):
		SceneRouter.change_scene(CATALOG_SCENE)

func _on_cell_pressed(item: Resource, category: String) -> void:
	var party_idx: int = _party_index_for_view()
	if party_idx < 0:
		return
	match category:
		"weapon":
			$EquipmentController.equip_weapon(item, party_idx)
		"armor":
			$EquipmentController.equip_armor(item, party_idx)
		"accessory":
			$EquipmentController.equip_accessory(item, party_idx)
	_refresh_display()

# ---- レア度枠スタイル ----
func _rarity_box(rarity: int, highlight: bool, cell_px: int) -> StyleBox:
	return EquipmentUiTokens.rarity_slot_style(rarity, highlight, cell_px)

func _apply_item_cell_styles(btn: Button, rarity: int, cell_px: int, disabled_highlight: bool = false) -> void:
	var normal: StyleBox = _rarity_box(rarity, false, cell_px)
	var hover: StyleBox = _rarity_box(rarity, true, cell_px)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_stylebox_override("disabled", _rarity_box(rarity, disabled_highlight, cell_px))

# 汎用の額縁スタイル（枠色・枠幅・地色を指定）。
func _framed_box(border: Color, width: int, bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(width)
	sb.border_color = border
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(4.0)
	return sb

# ボタン隅にバッジ（レアリティ星 / 炉研ぎ / 装備中）を重ねる。
func _apply_item_badges(
	btn: Button,
	item: Resource,
	category: String,
	size: Vector2,
	is_equipped: bool
) -> void:
	var rarity: int = _item_rarity(item, category)
	var star_font: int = maxi(11, int(size.y * 0.17))
	_add_corner_badge(
		btn,
		EquipmentUiHelper.rarity_stars_text(rarity),
		Color(0.96, 0.82, 0.35, 1.0),
		Vector2(3.0, 2.0),
		star_font
	)
	if category == "weapon":
		EquipmentUiHelper.apply_enhance_badge(btn, item, category, size, COLOR_GOLD)
	if is_equipped:
		var eq_font: int = maxi(10, int(size.y * 0.14))
		_add_corner_badge(btn, "装", COLOR_ACCENT, Vector2(3.0, size.y - float(eq_font) - 4.0), eq_font)

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
	var member: Resource = _get_view_adventurer()
	if member == null:
		return null
	match category:
		"weapon":
			return member.equipped_weapon
		"armor":
			return member.equipped_armor
		"accessory":
			return member.equipped_accessory
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
			var wt: String = "%s  攻撃力 %d  攻撃速度 %.1f  会心率 %.0f%%" % [
				_EquipmentEnhancer.get_display_name(item),
				_EquipmentEnhancer.get_effective_attack(item),
				item.attack_speed,
				item.critical_rate * 100.0,
			]
			wt = _AffixDisplayFormatter.append_to_text(wt, item)
			var flavor: String = _WeaponFlavorHelper.get_flavor_text_for_item(item)
			if not flavor.is_empty():
				wt += "\n「%s」" % flavor
			return wt
		"armor":
			var at: String = "%s  防御力 %d  HP+%d  重量 %.1f" % [
				DataRegistry.get_armor_name(item.armor_id), item.rolled_defense, item.hp_bonus, item.weight
			]
			at += _armor_resist_suffix(item)
			return _AffixDisplayFormatter.append_to_text(at, item)
		"accessory":
			var acc_data: Resource = _accessory_data(item)
			var act: String
			if acc_data != null:
				act = "%s  HP+%d  攻撃力+%d  防御力+%d  会心率+%.0f%%" % [
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
	parts.append("攻撃力 %s%d" % ["+" if atk_diff >= 0 else "", atk_diff])
	var spd_diff: float = candidate.attack_speed - equipped.attack_speed
	if not is_zero_approx(spd_diff):
		parts.append("攻撃速度 %s%.1f" % ["+" if spd_diff >= 0.0 else "", spd_diff])
	var crt_diff: float = candidate.critical_rate - equipped.critical_rate
	if not is_zero_approx(crt_diff):
		parts.append("会心率 %s%.0f%%" % ["+" if crt_diff >= 0.0 else "", crt_diff * 100.0])
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
	var def_diff: int = (
		EquipmentEnhancer.effective_armor_defense(candidate)
		- EquipmentEnhancer.effective_armor_defense(equipped)
	)
	if def_diff != 0:
		parts.append("防御力 %s%d" % ["+" if def_diff >= 0 else "", def_diff])
	var hp_diff: int = (
		EquipmentEnhancer.effective_armor_hp(candidate) - EquipmentEnhancer.effective_armor_hp(equipped)
	)
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
		parts.append("攻撃力 %s%d" % ["+" if atk_d >= 0 else "", atk_d])
	var def_d: int = c_data.defense_bonus - e_data.defense_bonus
	if def_d != 0:
		parts.append("防御力 %s%d" % ["+" if def_d >= 0 else "", def_d])
	var crt_d: float = c_data.crit_rate_bonus - e_data.crit_rate_bonus
	if not is_zero_approx(crt_d):
		parts.append("会心率 %s%.0f%%" % ["+" if crt_d >= 0.0 else "", crt_d * 100.0])
	if parts.is_empty():
		return "[±0]"
	return "[%s]" % " | ".join(parts)

# ---- ステータス計算（戦闘式と整合する表示用集計） ----
func _compute_member_stats(idx: int, member_override: Resource = null) -> Dictionary:
	var member: Resource = member_override if member_override != null else GameState.get_member(idx)
	var weapon: Resource = member.equipped_weapon if member != null else null
	var armor: Resource = member.equipped_armor if member != null else null
	var accessory: Resource = member.equipped_accessory if member != null else null
	var acc_data: Resource = _accessory_data(accessory)
	var affix: Dictionary = _AffixStatCalculator.get_bonuses(idx) if idx >= 0 else {}
	var job: Dictionary = _JobStatCalculator.get_member_modifiers(member)
	var level: int = int(member.level) if member != null else 1
	var hp: int = BASE_MEMBER_HP
	if member != null and member.base_stats != null and int(member.base_stats.hp) > 0:
		hp = int(member.base_stats.hp)
	if armor != null:
		hp += EquipmentEnhancer.effective_armor_hp(armor)
	if acc_data != null and accessory != null:
		hp += EquipmentEnhancer.effective_accessory_int_bonus(accessory, "hp_bonus", acc_data)
	hp += int(affix.get("hp_flat", 0))
	hp += LevelSystem.level_hp_bonus(level)
	hp = int(round(float(hp) * float(job.get("hp_multiplier", 1.0))))
	var attack: int = 0
	if weapon != null:
		attack = _EquipmentEnhancer.get_effective_attack(weapon)
	if acc_data != null and accessory != null:
		attack += EquipmentEnhancer.effective_accessory_int_bonus(accessory, "attack_bonus", acc_data)
	attack += int(affix.get("attack_flat", 0))
	attack += LevelSystem.level_attack_bonus(level)
	if member != null and member.base_stats != null:
		attack += int(member.base_stats.attack)
	var atk_mult: float = float(job.get("attack_multiplier", 1.0))
	if weapon != null:
		atk_mult *= _JobStatCalculator.get_preferred_weapon_multiplier(member, DataRegistry.get_weapon_data(weapon.weapon_id))
	attack = int(round(float(attack) * atk_mult))
	var defense: int = 0
	if armor != null:
		defense = EquipmentEnhancer.effective_armor_defense(armor)
	if acc_data != null and accessory != null:
		defense += EquipmentEnhancer.effective_accessory_int_bonus(accessory, "defense_bonus", acc_data)
	defense += int(affix.get("defense_flat", 0))
	if member != null and member.base_stats != null:
		defense += int(member.base_stats.defense)
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
	var member: Resource = _get_view_adventurer()
	var slots_label: RichTextLabel = _skill_content.get_node("LabelSkillSlots") as RichTextLabel
	var hint_label: Label = _skill_content.get_node("LabelSkillHint") as Label
	var list: Node = _skill_content.get_node("SkillList")
	for child in list.get_children():
		child.queue_free()
	if member == null:
		slots_label.text = "装備中スキル: —"
		return
	var equipped: Array[String] = GameState.get_equipped_skill_ids(member)
	var equipped_names: PackedStringArray = []
	for sid in equipped:
		equipped_names.append(_skill_bbcode_name(sid))
	var shown: String = " / ".join(equipped_names) if not equipped_names.is_empty() else "なし"
	slots_label.text = "[center]装備中スキル (%d/%d): %s[/center]" % [
		equipped.size(), Constants.MAX_EQUIPPED_SKILLS, shown
	]
	hint_label.text = "習得スキル（タップで詳細 / 右ボタンで装備）"
	var job: Resource = DataRegistry.get_job_data(member.job_id)
	if job == null:
		return
	for entry in SkillProgression.get_unlock_entries(job):
		if not entry is Dictionary:
			continue
		var sid: String = str(entry.get("skill_id", ""))
		var skill_data: Resource = DataRegistry.get_skill_data(sid)
		if skill_data == null:
			continue
		var req_lv: int = maxi(1, int(entry.get("level", 1)))
		var unlocked: bool = SkillProgression.is_job_skill_unlocked(member, sid)
		var is_equipped: bool = equipped.has(sid)
		list.add_child(_make_skill_list_row(
			sid, skill_data, member, unlocked, req_lv, is_equipped, equipped.size()
		))
	var weapon_skill: Dictionary = WeaponSkillHelper.get_weapon_skill_display(member)
	if not str(weapon_skill.get("skill_id", "")).is_empty():
		list.add_child(_make_weapon_skill_list_row(member, weapon_skill))

func _make_skill_list_row(
	skill_id: String,
	skill_data: Resource,
	member: Resource,
	unlocked: bool,
	req_lv: int,
	is_equipped: bool,
	equipped_count: int
) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = float(PASSIVE_ROW_ICON_PX)
	row.add_child(_skill_row_icon(skill_id, member))
	row.add_child(_make_skill_row_body(skill_id, skill_data, unlocked, req_lv, is_equipped))
	var equip_btn := Button.new()
	equip_btn.text = "解除" if is_equipped else "装備"
	equip_btn.custom_minimum_size.x = PASSIVE_ROW_BTN_W
	equip_btn.disabled = (
		not unlocked or ((not is_equipped) and equipped_count >= Constants.MAX_EQUIPPED_SKILLS)
	)
	equip_btn.pressed.connect(_on_skill_toggle_pressed.bind(skill_id))
	row.add_child(equip_btn)
	if not unlocked:
		row.modulate = Color(0.78, 0.78, 0.78, 1.0)
	return row

func _make_weapon_skill_list_row(member: Resource, weapon_skill: Dictionary) -> HBoxContainer:
	var ws_sid: String = str(weapon_skill.get("skill_id", ""))
	var ws_skill_data: Resource = DataRegistry.get_skill_data(ws_sid)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = float(PASSIVE_ROW_ICON_PX)
	row.add_child(_skill_row_icon(ws_sid, member))
	var body := PanelContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	body.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	body.gui_input.connect(_on_weapon_skill_row_gui_input.bind(ws_sid))
	if ws_skill_data != null:
		body.tooltip_text = _skill_summary_text(ws_skill_data, true, 1)
	var body_row := HBoxContainer.new()
	body_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_row.add_theme_constant_override("separation", 0)
	body.add_child(body_row)
	if ws_skill_data != null:
		body_row.add_child(_make_skill_name_label(ws_skill_data))
	else:
		var ws_name := Label.new()
		ws_name.text = "『%s』" % str(weapon_skill.get("skill_name", ""))
		ws_name.custom_minimum_size.x = SKILL_ROW_NAME_MIN_W
		ws_name.clip_text = true
		ws_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		ws_name.add_theme_color_override("font_color", SKILL_COLOR_ATTACK)
		UiTypography.apply_body(ws_name, UiTypography.SIZE_CAPTION)
		body_row.add_child(ws_name)
	body_row.add_child(_passive_row_sep())
	var ws_desc := _make_skill_desc_label(
		_skill_summary_text(ws_skill_data, true, 1) if ws_skill_data != null else "武器スキルとして自動発動",
		true
	)
	body_row.add_child(ws_desc)
	row.add_child(body)
	var ws_tag := Label.new()
	ws_tag.text = "自動"
	ws_tag.custom_minimum_size.x = PASSIVE_ROW_BTN_W
	ws_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ws_tag.add_theme_color_override("font_color", COLOR_SUB)
	UiTypography.apply_caption(ws_tag)
	row.add_child(ws_tag)
	return row

const SKILL_ROW_NAME_MIN_W: float = 132.0

func _skill_row_icon(skill_id: String, member: Resource) -> Control:
	var icon: Control = _make_skill_icon(skill_id, member)
	if icon != null:
		icon.custom_minimum_size = Vector2(PASSIVE_ROW_ICON_PX, PASSIVE_ROW_ICON_PX)
		return icon
	return _passive_row_icon_placeholder()

func _make_skill_row_body(
	skill_id: String,
	skill_data: Resource,
	unlocked: bool,
	req_lv: int,
	is_equipped: bool
) -> PanelContainer:
	var body := PanelContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	body.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	body.gui_input.connect(_on_skill_row_gui_input.bind(skill_id, unlocked, req_lv, is_equipped))
	body.tooltip_text = _skill_summary_text(skill_data, unlocked, req_lv)
	var body_row := HBoxContainer.new()
	body_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_row.add_theme_constant_override("separation", 0)
	body.add_child(body_row)
	body_row.add_child(_make_skill_name_label(skill_data))
	body_row.add_child(_passive_row_sep())
	body_row.add_child(_make_skill_desc_label(_skill_summary_text(skill_data, unlocked, req_lv), unlocked))
	return body

func _make_skill_name_label(skill_data: Resource) -> Label:
	var name_lbl := Label.new()
	name_lbl.text = _skill_wrapped_name(skill_data)
	_apply_skill_name_style(name_lbl, skill_data)
	name_lbl.custom_minimum_size.x = SKILL_ROW_NAME_MIN_W
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return name_lbl

func _make_skill_desc_label(text: String, unlocked: bool) -> Label:
	var desc_lbl := Label.new()
	desc_lbl.text = text
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_lbl.clip_text = true
	desc_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_lbl.add_theme_color_override(
		"font_color", COLOR_VALUE if unlocked else Color(0.55, 0.55, 0.55)
	)
	UiTypography.apply_body(desc_lbl, UiTypography.SIZE_CAPTION)
	return desc_lbl

func _on_skill_row_gui_input(
	event: InputEvent,
	skill_id: String,
	unlocked: bool,
	req_lv: int,
	is_equipped: bool
) -> void:
	if not _is_inventory_pointer_event(event):
		return
	if event.pressed:
		_begin_inventory_press(_skill_row_action.bind(skill_id, unlocked, req_lv, is_equipped))
	else:
		_end_inventory_press()

func _on_weapon_skill_row_gui_input(event: InputEvent, skill_id: String) -> void:
	if not _is_inventory_pointer_event(event):
		return
	if event.pressed:
		_begin_inventory_press(_weapon_skill_row_action.bind(skill_id))
	else:
		_end_inventory_press()

func _skill_row_action(
	is_long_press: bool,
	skill_id: String,
	unlocked: bool,
	req_lv: int,
	is_equipped: bool
) -> void:
	if is_long_press:
		_show_skill_detail_overlay(skill_id, unlocked, req_lv, is_equipped)
	elif unlocked:
		_on_skill_toggle_pressed(skill_id)

func _weapon_skill_row_action(is_long_press: bool, skill_id: String) -> void:
	if is_long_press:
		_show_skill_detail_overlay(skill_id, true, 1, false)

# ---- 必殺技タブ ----
const ULTIMATE_ICON_PX: int = 96

func _rebuild_ultimate_tab() -> void:
	var host: VBoxContainer = _ultimate_content.get_node("UltimateHost") as VBoxContainer
	for child in host.get_children():
		child.queue_free()
	var member: Resource = _get_view_adventurer()
	if member == null:
		return
	var skill_data: Resource = _get_member_ultimate_skill_data(member)
	if skill_data == null:
		var empty := Label.new()
		empty.text = "必殺技がありません"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTypography.apply_body(empty, UiTypography.SIZE_BODY_SMALL, COLOR_SUB)
		host.add_child(empty)
		return
	var skill_id: String = str(skill_data.id)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel", _framed_box(COLOR_GOLD, 2, Color(0.08, 0.07, 0.05, 0.92))
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(outer)
	var icon_row := CenterContainer.new()
	icon_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon := _make_ultimate_skill_icon(skill_id, member, Vector2(ULTIMATE_ICON_PX, ULTIMATE_ICON_PX))
	if icon != null:
		icon_row.add_child(icon)
	else:
		var ph := Control.new()
		ph.custom_minimum_size = Vector2(ULTIMATE_ICON_PX, ULTIMATE_ICON_PX)
		icon_row.add_child(ph)
	outer.add_child(icon_row)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(title_row)
	var name_lbl := Label.new()
	name_lbl.text = _skill_wrapped_name(skill_data)
	var name_font: Font = UiTypography.display_font()
	if name_font != null:
		name_lbl.add_theme_font_override("font", name_font)
	name_lbl.add_theme_font_size_override("font_size", UiTypography.SIZE_DISPLAY_TITLE)
	name_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title_row.add_child(name_lbl)
	var ell := Label.new()
	ell.text = "…"
	ell.add_theme_color_override("font_color", COLOR_SUB)
	UiTypography.apply_body(ell, UiTypography.SIZE_BODY_SMALL)
	title_row.add_child(ell)
	var desc_lbl := Label.new()
	desc_lbl.text = _skill_summary_text(skill_data, true, 1)
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", COLOR_VALUE)
	UiTypography.apply_body(desc_lbl, UiTypography.SIZE_BODY_SMALL)
	title_row.add_child(desc_lbl)
	var fx_title := Label.new()
	fx_title.text = "効果"
	UiTypography.apply_body(fx_title, UiTypography.SIZE_BODY, COLOR_GOLD)
	outer.add_child(fx_title)
	for line in _skill_stats_detail_lines(skill_data, true, 1):
		var stat_lbl := Label.new()
		stat_lbl.text = "・%s" % line
		stat_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiTypography.apply_body(stat_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_VALUE)
		outer.add_child(stat_lbl)
	host.add_child(panel)

func _get_member_ultimate_skill_data(member: Resource) -> Resource:
	if member == null:
		return null
	var ult_id: String = Constants.DEFAULT_ULTIMATE_SKILL_ID
	if not str(member.job_id).is_empty():
		var job: Resource = DataRegistry.get_job_data(member.job_id)
		if job != null and not str(job.ultimate_skill_id).is_empty():
			ult_id = str(job.ultimate_skill_id)
	if ult_id.is_empty():
		return null
	return DataRegistry.get_skill_data(ult_id)

# ---- パッシブタブ ----
const PASSIVE_ROW_ICON_PX: int = 56
const PASSIVE_ROW_BTN_W: int = 64
const PASSIVE_ROW_NAME_MIN_W: int = 120

func _rebuild_passive_tab() -> void:
	_sync_slot_cell_size()
	var member: Resource = _get_view_adventurer()
	var list: Node = _passive_content.get_node("PassiveList")
	for child in list.get_children():
		child.queue_free()
	if member == null:
		return
	var char_ids: Array[String] = GameState.get_equipped_character_passive_ids(member)
	for pid in CombatPassives.selectable_passive_ids(member):
		var def: Dictionary = CombatPassives.get_def(pid)
		if def.is_empty():
			continue
		list.add_child(_make_passive_equip_row(def, char_ids.has(pid)))
	for eq_def: Dictionary in CombatPassives.equipment_passives_for_member(member):
		list.add_child(_make_passive_info_row(eq_def, "装備固定"))

func _make_passive_equip_row(def: Dictionary, is_equipped: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = float(PASSIVE_ROW_ICON_PX)
	var pid: String = str(def.get("id", ""))
	row.add_child(_passive_row_icon(pid))
	row.add_child(_passive_row_sep())
	var name_lbl := _passive_row_label(
		str(def.get("display_name", "—")), SKILL_COLOR_SUPPORT, PASSIVE_ROW_NAME_MIN_W, true
	)
	row.add_child(name_lbl)
	row.add_child(_passive_row_sep())
	var effect_lbl := _passive_row_label(_passive_effect_text(def), COLOR_VALUE, 0, false)
	effect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(effect_lbl)
	row.add_child(_passive_row_sep())
	var btn := Button.new()
	btn.custom_minimum_size.x = PASSIVE_ROW_BTN_W
	btn.text = "解除" if is_equipped else "装備"
	btn.pressed.connect(_on_passive_toggle_pressed.bind(pid))
	row.add_child(btn)
	return row

func _make_passive_info_row(def: Dictionary, tag_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = float(PASSIVE_ROW_ICON_PX)
	var pid: String = str(def.get("id", ""))
	row.add_child(_passive_row_icon(pid))
	row.add_child(_passive_row_sep())
	var name_lbl := _passive_row_label(
		str(def.get("display_name", "—")), SKILL_COLOR_SUPPORT, PASSIVE_ROW_NAME_MIN_W, true
	)
	row.add_child(name_lbl)
	row.add_child(_passive_row_sep())
	var effect_lbl := _passive_row_label(_passive_effect_text(def), COLOR_VALUE, 0, false)
	effect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(effect_lbl)
	row.add_child(_passive_row_sep())
	var tag_lbl := _passive_row_label(tag_text, COLOR_SUB, PASSIVE_ROW_BTN_W)
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(tag_lbl)
	return row

func _make_relic_passive_row(def: Dictionary, is_equipped: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = float(PASSIVE_ROW_ICON_PX)
	var pid: String = str(def.get("id", ""))
	var relic_icon := _make_relic_passive_icon(pid)
	if relic_icon != null:
		relic_icon.custom_minimum_size = Vector2(PASSIVE_ROW_ICON_PX, PASSIVE_ROW_ICON_PX)
		row.add_child(relic_icon)
	else:
		row.add_child(_passive_row_icon_placeholder())
	row.add_child(_passive_row_sep())
	var name_lbl := _passive_row_label(
		str(def.get("display_name", "—")), COLOR_ACCENT, PASSIVE_ROW_NAME_MIN_W, true
	)
	row.add_child(name_lbl)
	row.add_child(_passive_row_sep())
	var effect_lbl := _passive_row_label(CombatPassives.relic_description(pid), COLOR_VALUE, 0, false)
	effect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(effect_lbl)
	row.add_child(_passive_row_sep())
	var btn := Button.new()
	btn.custom_minimum_size.x = PASSIVE_ROW_BTN_W
	btn.text = "解除" if is_equipped else "装備"
	btn.pressed.connect(_on_relic_passive_toggle_pressed.bind(pid))
	row.add_child(btn)
	return row

func _passive_row_icon(passive_id: String) -> Control:
	var icon: Control = _make_passive_icon(passive_id)
	if icon != null:
		icon.custom_minimum_size = Vector2(PASSIVE_ROW_ICON_PX, PASSIVE_ROW_ICON_PX)
		return icon
	return _passive_row_icon_placeholder()

func _passive_row_icon_placeholder() -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(PASSIVE_ROW_ICON_PX, PASSIVE_ROW_ICON_PX)
	return box

func _passive_row_sep() -> Label:
	var sep := Label.new()
	sep.text = "："
	sep.add_theme_color_override("font_color", COLOR_SUB)
	UiTypography.apply_body(sep, UiTypography.SIZE_BODY_SMALL)
	return sep

func _passive_row_label(
	text: String, color: Color, min_width: int, is_name: bool = false
) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_name:
		lbl.clip_text = true
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	else:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if min_width > 0:
		lbl.custom_minimum_size.x = float(min_width)
	UiTypography.apply_body(lbl, UiTypography.SIZE_BODY_SMALL)
	return lbl

func _passive_effect_text(def: Dictionary) -> String:
	return RosterUiHelper.passive_description(def)

func _make_relic_passive_icon(passive_id: String) -> TextureRect:
	var icon_key: String = CombatPassives.relic_icon_key(passive_id)
	var tex: Texture2D = IconPaths.get_icon_texture(icon_key, "relic") if not icon_key.is_empty() else null
	if tex == null:
		return null
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = Vector2(PASSIVE_ROW_ICON_PX, PASSIVE_ROW_ICON_PX)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func _on_passive_toggle_pressed(passive_id: String) -> void:
	var member: Resource = _get_view_adventurer()
	if member == null:
		return
	GameState.toggle_member_passive(member, passive_id)
	_rebuild_passive_tab()
	_rebuild_equip_slots()

func _on_relic_passive_toggle_pressed(passive_id: String) -> void:
	var member: Resource = _get_view_adventurer()
	if member == null:
		return
	if GameState.get_equipped_relic_passive_id(member) == passive_id:
		GameState.toggle_member_relic_passive(member, "")
	else:
		GameState.toggle_member_relic_passive(member, passive_id)
	_rebuild_passive_tab()
	_rebuild_equip_slots()

# ---- 戦術タブ（P3-D086 戦術・ガンビット） ----
func _rebuild_tactics_tab() -> void:
	var member: Resource = _get_view_adventurer()
	_ensure_exploration_policy_ui()
	_sync_policy_option()
	_ensure_tactics_ui()
	_refresh_tactics_ui(member)

func _ensure_combat_setup_panel() -> void:
	if _combat_setup_panel != null and is_instance_valid(_combat_setup_panel):
		return
	_combat_setup_panel = PanelContainer.new()
	_combat_setup_panel.name = "CombatSetupPanel"
	_combat_setup_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_combat_setup_panel.add_theme_stylebox_override(
		"panel", _framed_box(COLOR_GOLD, 2, Color(0.08, 0.07, 0.05, 0.92))
	)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	var hint := Label.new()
	hint.text = "陣形は拠点 → 編成 → 陣形タブで設定"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(hint)
	outer.add_child(hint)
	_combat_setup_content = VBoxContainer.new()
	_combat_setup_content.name = "CombatSetupContent"
	_combat_setup_content.add_theme_constant_override("separation", 8)
	outer.add_child(_combat_setup_content)
	_combat_setup_panel.add_child(outer)
	_tactics_content.add_child(_combat_setup_panel)

# 戦術セレクタ（P3-D086）。常時表示パネル最上部。
func _ensure_tactics_ui() -> void:
	if _tactics_option != null and is_instance_valid(_tactics_option):
		return
	_ensure_combat_setup_panel()
	var row := HBoxContainer.new()
	row.name = "TacticsRow"
	var label := Label.new()
	label.text = "戦術:"
	UiTypography.apply_body(label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
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
	var summary := Label.new()
	summary.name = "TacticsSummaryLabel"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(summary, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	_combat_setup_content.add_child(summary)
	_combat_setup_content.move_child(summary, 1)
	_tactics_summary_label = summary
	_ensure_gambit_ui()

func _ensure_gambit_ui() -> void:
	if _gambit_accordion_btn != null and is_instance_valid(_gambit_accordion_btn):
		return
	_ensure_combat_setup_panel()
	var accordion_row := HBoxContainer.new()
	accordion_row.name = "GambitAccordionRow"
	_gambit_accordion_btn = Button.new()
	_gambit_accordion_btn.text = "▶ 行動ルールを編集"
	_gambit_accordion_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_menu_button(_gambit_accordion_btn)
	_gambit_accordion_btn.pressed.connect(_on_gambit_accordion_pressed)
	accordion_row.add_child(_gambit_accordion_btn)
	_combat_setup_content.add_child(accordion_row)
	_combat_setup_content.move_child(accordion_row, 2)
	_gambit_custom_box = VBoxContainer.new()
	_gambit_custom_box.name = "GambitCustomBox"
	_gambit_custom_box.add_theme_constant_override("separation", 6)
	_gambit_custom_box.visible = false
	var intro := Label.new()
	intro.text = "このキャラだけ、行動の優先順を上書きします。"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(intro, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	_gambit_custom_box.add_child(intro)
	var check_row := HBoxContainer.new()
	check_row.name = "GambitCheckRow"
	_gambit_custom_check = CheckBox.new()
	_gambit_custom_check.text = "行動ルールを自分で設定"
	UiTypography.apply_menu_button(_gambit_custom_check)
	_gambit_custom_check.toggled.connect(_on_gambit_custom_toggled)
	check_row.add_child(_gambit_custom_check)
	_gambit_custom_box.add_child(check_row)
	var target_row := HBoxContainer.new()
	var target_label := Label.new()
	target_label.text = "狙う敵:"
	UiTypography.apply_body(target_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
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
	copy_btn.text = "今の戦術をコピーして編集"
	UiTypography.apply_menu_button(copy_btn)
	copy_btn.pressed.connect(_on_gambit_copy_preset_pressed)
	_gambit_custom_box.add_child(copy_btn)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 4)
	var h_pri := Label.new()
	h_pri.text = "順"
	h_pri.custom_minimum_size.x = 18.0
	UiTypography.apply_body(h_pri, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	header_row.add_child(h_pri)
	var h_slot := Label.new()
	h_slot.text = "使う技"
	h_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(h_slot, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	header_row.add_child(h_slot)
	var h_cond := Label.new()
	h_cond.text = "いつ使うか"
	h_cond.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(h_cond, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	header_row.add_child(h_cond)
	var h_val := Label.new()
	h_val.text = "値"
	h_val.custom_minimum_size.x = 52.0
	UiTypography.apply_body(h_val, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	header_row.add_child(h_val)
	var h_move := Label.new()
	h_move.text = "並替"
	h_move.custom_minimum_size.x = 30.0
	UiTypography.apply_body(h_move, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	header_row.add_child(h_move)
	_gambit_custom_box.add_child(header_row)
	_gambit_action_opts.clear()
	_gambit_action_keys.clear()
	_gambit_cond_opts.clear()
	_gambit_value_edits.clear()
	_gambit_range_opts.clear()
	_gambit_move_up_btns.clear()
	_gambit_move_down_btns.clear()
	_gambit_row_preview_labels.clear()
	for i in CombatGambit.plan_row_count():
		var row_wrap := VBoxContainer.new()
		row_wrap.name = "GambitPlanWrap%d" % i
		row_wrap.add_theme_constant_override("separation", 2)
		var plan_row := HBoxContainer.new()
		plan_row.name = "GambitPlanRow%d" % i
		var pri := Label.new()
		pri.text = "%d" % (i + 1)
		pri.custom_minimum_size.x = 18.0
		UiTypography.apply_body(pri, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
		plan_row.add_child(pri)
		var action_opt := OptionButton.new()
		action_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_opt.item_selected.connect(_on_gambit_row_changed)
		plan_row.add_child(action_opt)
		var cond_opt := OptionButton.new()
		cond_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for cond_id: String in CombatGambit.CONDITION_IDS:
			cond_opt.add_item(CombatGambit.condition_label(cond_id))
		cond_opt.item_selected.connect(_on_gambit_row_changed)
		plan_row.add_child(cond_opt)
		var value_edit := LineEdit.new()
		value_edit.custom_minimum_size.x = 52.0
		value_edit.placeholder_text = "%"
		value_edit.text_changed.connect(_on_gambit_row_changed)
		plan_row.add_child(value_edit)
		var range_opt := OptionButton.new()
		range_opt.custom_minimum_size.x = 72.0
		for range_id: String in CombatGambit.RANGE_VALUE_IDS:
			range_opt.add_item(CombatGambit.range_label(range_id))
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
		var row_preview := Label.new()
		row_preview.text = ""
		row_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiTypography.apply_body(row_preview, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
		row_wrap.add_child(row_preview)
		_gambit_custom_box.add_child(row_wrap)
		_gambit_action_opts.append(action_opt)
		_gambit_action_keys.append([])
		_gambit_cond_opts.append(cond_opt)
		_gambit_value_edits.append(value_edit)
		_gambit_range_opts.append(range_opt)
		_gambit_move_up_btns.append(btn_up)
		_gambit_move_down_btns.append(btn_down)
		_gambit_row_preview_labels.append(row_preview)
	var gambit_hint := Label.new()
	gambit_hint.text = "上から優先。戦闘ログに [戦術] と表示されます。"
	gambit_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gambit_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(gambit_hint, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	_gambit_custom_box.add_child(gambit_hint)
	_combat_setup_content.add_child(_gambit_custom_box)
	_combat_setup_content.move_child(_gambit_custom_box, 3)

func _refresh_gambit_ui(member: Resource) -> void:
	if _gambit_custom_check == null:
		return
	_gambit_ui_syncing = true
	if member == null:
		_gambit_custom_check.disabled = true
		_gambit_custom_box.visible = false
		_sync_gambit_accordion_btn(false, false)
		_gambit_ui_syncing = false
		return
	_gambit_custom_check.disabled = false
	var custom_on: bool = GameState.get_member_tactics_custom_enabled(member)
	_gambit_custom_check.button_pressed = custom_on
	if custom_on:
		_gambit_accordion_expanded = true
	_sync_gambit_accordion_btn(_gambit_accordion_expanded, custom_on)
	_gambit_custom_box.visible = _gambit_accordion_expanded
	if _tactics_option != null:
		_tactics_option.disabled = custom_on
	var target: String = GameState.get_member_tactics_custom_target(member)
	var target_idx: int = _gambit_target_ids.find(target)
	if _gambit_target_option != null:
		_gambit_target_option.select(target_idx if target_idx >= 0 else 0)
	var plan: Array = GameState.get_member_tactics_custom_plan(member)
	for i in CombatGambit.plan_row_count():
		var rule: Dictionary = plan[i] if i < plan.size() else CombatGambit.default_plan_row(i)
		_sync_gambit_action_option(i, member, rule)
		var cond_id: String = str(rule.get("condition", "always"))
		var cond_idx: int = CombatGambit.CONDITION_IDS.find(cond_id)
		_gambit_cond_opts[i].select(cond_idx if cond_idx >= 0 else 0)
		_update_gambit_row_value_widgets(i, cond_id, rule)
	_update_gambit_move_buttons()
	_update_gambit_row_previews()
	_set_gambit_editor_interactive(custom_on)
	_gambit_ui_syncing = false

func _set_gambit_editor_interactive(enabled: bool) -> void:
	if _gambit_target_option != null:
		_gambit_target_option.disabled = not enabled
	for i in CombatGambit.plan_row_count():
		if i < _gambit_action_opts.size():
			_gambit_action_opts[i].disabled = not enabled
		if i < _gambit_cond_opts.size():
			_gambit_cond_opts[i].disabled = not enabled
		if i < _gambit_value_edits.size():
			_gambit_value_edits[i].editable = enabled
		if i < _gambit_range_opts.size():
			_gambit_range_opts[i].disabled = not enabled
	_update_gambit_move_buttons()
	if not enabled:
		for i in CombatGambit.plan_row_count():
			if i < _gambit_move_up_btns.size():
				_gambit_move_up_btns[i].disabled = true
			if i < _gambit_move_down_btns.size():
				_gambit_move_down_btns[i].disabled = true

func _sync_gambit_accordion_btn(expanded: bool, custom_on: bool) -> void:
	if _gambit_accordion_btn == null:
		return
	var prefix: String = "▼" if expanded else "▶"
	var suffix: String = "（適用中）" if custom_on else ""
	_gambit_accordion_btn.text = "%s 行動ルールを編集%s" % [prefix, suffix]

func _on_gambit_accordion_pressed() -> void:
	_gambit_accordion_expanded = not _gambit_accordion_expanded
	var custom_on: bool = false
	var member: Resource = _get_view_adventurer()
	if member != null:
		custom_on = GameState.get_member_tactics_custom_enabled(member)
	_sync_gambit_accordion_btn(_gambit_accordion_expanded, custom_on)
	if _gambit_custom_box != null:
		_gambit_custom_box.visible = _gambit_accordion_expanded

func _update_gambit_row_previews() -> void:
	var member: Resource = _get_view_adventurer()
	for i in CombatGambit.plan_row_count():
		if i >= _gambit_cond_opts.size() or i >= _gambit_row_preview_labels.size():
			continue
		var rule: Dictionary = _gambit_rule_from_row(i)
		_gambit_row_preview_labels[i].text = CombatGambit.rule_preview(rule, member)

func _sync_gambit_action_option(row: int, member: Resource, rule: Dictionary) -> void:
	if row < 0 or row >= _gambit_action_opts.size():
		return
	var opt: OptionButton = _gambit_action_opts[row]
	opt.clear()
	var keys: Array[String] = []
	for entry in CombatGambit.action_options_for_member(member):
		if not entry is Dictionary:
			continue
		var key: String = str(entry.get("key", ""))
		var label: String = str(entry.get("label", key))
		opt.add_item(label)
		keys.append(key)
	_gambit_action_keys[row] = keys
	var want_key: String = CombatGambit.action_key_from_rule(rule)
	var pick_idx: int = keys.find(want_key)
	if pick_idx < 0:
		pick_idx = keys.find("attack")
	opt.select(pick_idx if pick_idx >= 0 else 0)

func _gambit_rule_from_row(row: int) -> Dictionary:
	var cond_idx: int = _gambit_cond_opts[row].selected
	var cond_id: String = CombatGambit.CONDITION_IDS[cond_idx] if cond_idx >= 0 else "always"
	var keys: Array = _gambit_action_keys[row] if row < _gambit_action_keys.size() else []
	var action_idx: int = _gambit_action_opts[row].selected
	var action_key: String = "attack"
	if action_idx >= 0 and action_idx < keys.size():
		action_key = str(keys[action_idx])
	var rule: Dictionary = CombatGambit.rule_from_action_key(action_key)
	rule["condition"] = cond_id
	if CombatGambit.condition_needs_value(cond_id):
		if cond_id == "self_range":
			var range_idx: int = _gambit_range_opts[row].selected
			if range_idx >= 0 and range_idx < CombatGambit.RANGE_VALUE_IDS.size():
				rule["value"] = CombatGambit.RANGE_VALUE_IDS[range_idx]
		elif cond_id == "self_hp_below":
			rule["value"] = CombatGambit.hp_percent_storage(_gambit_value_edits[row].text)
		else:
			rule["value"] = _gambit_value_edits[row].text
	return rule

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
	elif cond_id == "self_hp_below":
		_gambit_value_edits[row].text = CombatGambit.hp_percent_display(raw_val)
		_gambit_value_edits[row].placeholder_text = "%"
	else:
		_gambit_value_edits[row].text = raw_val
		_gambit_value_edits[row].placeholder_text = "数"

func _collect_gambit_plan_from_ui() -> Array:
	var out: Array = []
	for i in CombatGambit.plan_row_count():
		var cond_idx: int = _gambit_cond_opts[i].selected
		if cond_idx < 0 or cond_idx >= CombatGambit.CONDITION_IDS.size():
			continue
		var rule: Dictionary = _gambit_rule_from_row(i)
		var cond_id: String = str(rule.get("condition", "always"))
		if CombatGambit.condition_needs_value(cond_id):
			if cond_id == "self_range":
				var range_idx: int = _gambit_range_opts[i].selected
				if range_idx >= 0 and range_idx < CombatGambit.RANGE_VALUE_IDS.size():
					rule["value"] = CombatGambit.RANGE_VALUE_IDS[range_idx]
			elif cond_id == "self_hp_below":
				rule["value"] = CombatGambit.hp_percent_storage(_gambit_value_edits[i].text)
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
	var member: Resource = _get_view_adventurer()
	if member == null:
		return
	if enabled and GameState.get_member_tactics_custom_plan(member).is_empty():
		GameState.copy_member_tactics_preset_to_custom(member)
	else:
		GameState.set_member_tactics_custom_enabled(member, enabled)
	if enabled:
		_gambit_accordion_expanded = true
	_refresh_gambit_ui(member)

func _on_gambit_copy_preset_pressed() -> void:
	var member: Resource = _get_view_adventurer()
	if member == null:
		return
	GameState.copy_member_tactics_preset_to_custom(member)
	_gambit_accordion_expanded = true
	_refresh_gambit_ui(member)

func _on_gambit_target_selected(_index: int) -> void:
	if _gambit_ui_syncing:
		return
	var member: Resource = _get_view_adventurer()
	if member == null or _gambit_target_option == null:
		return
	var idx: int = _gambit_target_option.selected
	if idx < 0 or idx >= _gambit_target_ids.size():
		return
	GameState.set_member_tactics_custom_target(member, _gambit_target_ids[idx])

func _on_gambit_row_changed(_unused: Variant = null) -> void:
	if _gambit_ui_syncing:
		return
	var member: Resource = _get_view_adventurer()
	if member == null:
		return
	for i in CombatGambit.plan_row_count():
		var cond_idx: int = _gambit_cond_opts[i].selected
		var cond_id: String = CombatGambit.CONDITION_IDS[cond_idx] if cond_idx >= 0 else "always"
		_update_gambit_row_value_widgets(i, cond_id)
	_update_gambit_row_previews()
	_persist_gambit_plan(member)

func _on_gambit_move_row(row: int, delta: int) -> void:
	if _gambit_ui_syncing:
		return
	var member: Resource = _get_view_adventurer()
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
		if _tactics_summary_label != null:
			_tactics_summary_label.text = ""
		return
	_tactics_option.disabled = false
	var current: String = GameState.get_member_tactics_id(member)
	var idx: int = _tactics_ids.find(current)
	_tactics_option.select(idx if idx >= 0 else 0)
	_refresh_tactics_summary_label(current, member)
	_refresh_gambit_ui(member)

func _refresh_tactics_summary_label(tactics_id: String, member: Resource = null) -> void:
	if _tactics_summary_label == null:
		return
	if member == null:
		member = _get_view_adventurer()
	if member != null and GameState.get_member_tactics_custom_enabled(member):
		_tactics_summary_label.text = "行動ルールを自分で設定中"
		return
	_tactics_summary_label.text = CombatTactics.summary_hint(tactics_id)

func _on_tactics_selected(index: int) -> void:
	if index < 0 or index >= _tactics_ids.size():
		return
	var member: Resource = _get_view_adventurer()
	if member == null:
		return
	GameState.set_member_tactics(member, _tactics_ids[index])
	_refresh_tactics_summary_label(_tactics_ids[index], member)

# 探索方針（P3-D098）。戦術タブで設定。
func _ensure_exploration_policy_ui() -> void:
	if _policy_option != null and is_instance_valid(_policy_option):
		return
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
	_policy_option = policy_opt
	_tactics_content.add_child(policy_row)
	_tactics_content.move_child(policy_row, 0)
	var policy_hint := Label.new()
	policy_hint.name = "PolicyHint"
	policy_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(policy_hint, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	_policy_hint_label = policy_hint
	_tactics_content.add_child(policy_hint)
	_tactics_content.move_child(policy_hint, 1)

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

func _skill_label_name(skill_id: String) -> String:
	var sd: Resource = DataRegistry.get_skill_data(skill_id)
	if sd != null and not sd.display_name.is_empty():
		return sd.display_name
	return skill_id

func _skill_wrapped_name(skill_data: Resource) -> String:
	if skill_data == null or skill_data.display_name.is_empty():
		return "『—』"
	return "『%s』" % skill_data.display_name

func _skill_name_color(skill_data: Resource) -> Color:
	if skill_data == null:
		return COLOR_VALUE
	if str(skill_data.effect_type) == "heal":
		return SKILL_COLOR_DEFENSE
	if str(skill_data.effect_type) == "buff" or _skill_applies_status(skill_data):
		return SKILL_COLOR_SUPPORT
	if str(skill_data.effect_type) == "damage":
		return SKILL_COLOR_ATTACK
	return COLOR_VALUE

func _skill_name_color_hex(skill_data: Resource) -> String:
	return _skill_name_color(skill_data).to_html(false)

func _skill_bbcode_name(skill_id: String) -> String:
	var sd: Resource = DataRegistry.get_skill_data(skill_id)
	if sd == null:
		return skill_id
	return "[font_size=%d][color=#%s]%s[/color][/font_size]" % [
		SKILL_NAME_FONT_SIZE, _skill_name_color_hex(sd), _skill_wrapped_name(sd)
	]

func _apply_skill_name_style(label: Label, skill_data: Resource) -> void:
	var font: Font = UiTypography.display_font()
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", _skill_name_color(skill_data))
	label.add_theme_font_size_override("font_size", SKILL_NAME_FONT_SIZE)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))

func _skill_applies_status(skill_data: Resource) -> bool:
	if skill_data == null:
		return false
	if not str(skill_data.apply_status_id).is_empty() and float(skill_data.apply_status_chance) > 0.0:
		return true
	return not str(skill_data.apply_status_id2).is_empty() and float(skill_data.apply_status_chance2) > 0.0

func _skill_summary_text(skill_data: Resource, unlocked: bool = true, req_lv: int = 1) -> String:
	if skill_data == null:
		return ""
	if not unlocked:
		return "🔒 Lv%d で習得" % req_lv
	var desc: String = str(skill_data.description)
	if not desc.is_empty():
		return desc
	return _skill_detail_text(skill_data, unlocked, req_lv)

func _skill_target_label(target_type: String) -> String:
	match target_type:
		"enemy":
			return "敵1体"
		"ally":
			return "味方1体"
		"party":
			return "味方1体"
		"all_party":
			return "味方全体"
		"party_front":
			return "味方前列"
		"party_back":
			return "味方後列"
		"self":
			return "自身"
		_:
			return target_type

func _skill_range_label(range_type: String) -> String:
	match range_type:
		"melee":
			return "近距離"
		"mid":
			return "中距離"
		"long":
			return "遠距離"
		"global":
			return "全体"
		_:
			return range_type

func _skill_slot_label(slot_type: String) -> String:
	match slot_type:
		"attack":
			return "通常攻撃枠"
		"defend":
			return "防御枠"
		"ultimate":
			return "必殺技枠"
		_:
			return "スキル枠"

func _skill_reserve_label(reserve_condition: String) -> String:
	match reserve_condition:
		"ally_injured":
			return "味方が負傷しているとき優先"
		"enemy_has_vulnerable":
			return "敵が脆弱状態のとき"
		"enemy_is_boss":
			return "ボス戦で使用"
		_:
			return ""

func _skill_status_line(status_id: String, chance: float) -> String:
	if status_id.is_empty() or chance <= 0.0:
		return ""
	var eff: Resource = DataRegistry.get_status_effect(status_id)
	var st_name: String = eff.display_name if eff != null else status_id
	var pct: int = int(round(chance * 100.0))
	if pct >= 100:
		return "%sを付与" % st_name
	return "%s %d%%" % [st_name, pct]

func _skill_stats_detail_lines(skill_data: Resource, unlocked: bool = true, req_lv: int = 1) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if skill_data == null:
		return lines
	if not unlocked:
		lines.append("🔒 Lv%d で習得" % req_lv)
		return lines
	lines.append("対象: %s" % _skill_target_label(str(skill_data.target_type)))
	var slot_type: String = str(skill_data.slot_type)
	if slot_type != "skill":
		lines.append("枠: %s" % _skill_slot_label(slot_type))
	var range_type: String = str(skill_data.range_type)
	if not range_type.is_empty() and range_type != "melee":
		lines.append("射程: %s" % _skill_range_label(range_type))
	match skill_data.effect_type:
		"heal":
			var heal_amt: int = int(round(skill_data.power_multiplier * 14.0))
			lines.append("回復量: +%d" % heal_amt)
		"buff":
			var eff_b: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
			if eff_b != null:
				var up: int = int(round((eff_b.outgoing_damage_multiplier - 1.0) * 100.0))
				if up != 0:
					lines.append("味方与ダメ: +%d%%" % up)
				lines.append("持続: %dtick" % eff_b.duration_ticks)
		_:
			lines.append("威力: x%.2f" % skill_data.power_multiplier)
			if not str(skill_data.element).is_empty():
				lines.append("属性: %s" % str(skill_data.element))
			for status_key: String in ["apply_status_id", "apply_status_id2"]:
				var chance_key: String = status_key.replace("id", "chance")
				var status_line: String = _skill_status_line(
					str(skill_data.get(status_key)),
					float(skill_data.get(chance_key))
				)
				if not status_line.is_empty():
					lines.append("付与: %s" % status_line)
	lines.append("再使用: %.1fs" % skill_data.cooldown)
	if float(skill_data.cast_time) >= 1.0:
		lines.append("詠唱: %dターン" % int(skill_data.cast_time))
	var reserve: String = _skill_reserve_label(str(skill_data.reserve_condition))
	if not reserve.is_empty():
		lines.append("温存: %s" % reserve)
	return lines

func _show_skill_detail_overlay(
	skill_id: String, unlocked: bool, req_lv: int, is_equipped: bool
) -> void:
	var member: Resource = _get_view_adventurer()
	var skill_data: Resource = DataRegistry.get_skill_data(skill_id)
	if skill_data == null:
		return
	_ensure_item_detail_overlay()
	_detail_pinned = true
	_overlay_item = null
	_overlay_category = "skill"
	_overlay_relic_id = ""
	_overlay_skill_id = skill_id
	if _detail_title != null:
		_detail_title.text = "スキル詳細"
	for child in _detail_host.get_children():
		child.queue_free()
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	var icon := _make_skill_icon(skill_id, member)
	if icon != null:
		header_row.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.text = _skill_wrapped_name(skill_data)
	_apply_skill_name_style(name_lbl, skill_data)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(name_lbl)
	_detail_host.add_child(header_row)
	var desc_lbl := Label.new()
	desc_lbl.text = _skill_summary_text(skill_data, unlocked, req_lv)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(desc_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_VALUE)
	_detail_host.add_child(desc_lbl)
	var stats_title := Label.new()
	stats_title.text = "効果"
	UiTypography.apply_body(stats_title, UiTypography.SIZE_CAPTION, COLOR_GOLD)
	_detail_host.add_child(stats_title)
	for line in _skill_stats_detail_lines(skill_data, unlocked, req_lv):
		var stat_lbl := Label.new()
		stat_lbl.text = "・%s" % line
		stat_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiTypography.apply_body(stat_lbl, UiTypography.SIZE_CAPTION, COLOR_SUB)
		_detail_host.add_child(stat_lbl)
	var equipped: Array[String] = (
		GameState.get_equipped_skill_ids(member) if member != null else []
	)
	var weapon_skill: Dictionary = WeaponSkillHelper.get_weapon_skill_display(member)
	var is_weapon_skill: bool = str(weapon_skill.get("skill_id", "")) == skill_id
	if is_weapon_skill:
		_detail_equip_btn.visible = false
	else:
		_detail_equip_btn.text = "解除" if is_equipped else "装備"
		_detail_equip_btn.visible = unlocked
		_detail_equip_btn.disabled = (
			not unlocked or ((not is_equipped) and equipped.size() >= Constants.MAX_EQUIPPED_SKILLS)
		)
	_detail_overlay.visible = true

func _skill_detail_text(skill_data: Resource, unlocked: bool = true, req_lv: int = 1) -> String:
	var body: String = ""
	match skill_data.effect_type:
		"heal":
			var amt: int = int(round(skill_data.power_multiplier * 14.0))
			body = "回復+%d  CD%.1fs" % [amt, skill_data.cooldown]
		"buff":
			var parts_buff: PackedStringArray = []
			var eff_b: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
			if eff_b != null:
				var up: int = int(round((eff_b.outgoing_damage_multiplier - 1.0) * 100.0))
				if up != 0:
					parts_buff.append("味方与ダメ+%d%%" % up)
				parts_buff.append("%dtick" % eff_b.duration_ticks)
			parts_buff.append("CD%.1fs" % skill_data.cooldown)
			body = "  ".join(parts_buff)
		_:
			var parts: PackedStringArray = [
				"威力x%.2f" % skill_data.power_multiplier,
				"CD%.1fs" % skill_data.cooldown,
			]
			if not str(skill_data.element).is_empty():
				parts.append("属性:%s" % skill_data.element)
			if not str(skill_data.apply_status_id).is_empty() and skill_data.apply_status_chance > 0.0:
				var eff: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
				var st_name: String = eff.display_name if eff != null else str(skill_data.apply_status_id)
				parts.append("%s%.0f%%" % [st_name, skill_data.apply_status_chance * 100.0])
			if not str(skill_data.apply_status_id2).is_empty() and skill_data.apply_status_chance2 > 0.0:
				var eff2: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id2)
				var st_name2: String = eff2.display_name if eff2 != null else str(skill_data.apply_status_id2)
				parts.append("%s%.0f%%" % [st_name2, skill_data.apply_status_chance2 * 100.0])
			body = "  ".join(parts)
	if not unlocked:
		return "🔒 Lv%d  %s" % [req_lv, body]
	return body

func _skill_info_text(skill_data: Resource) -> String:
	return "%s  %s" % [_skill_wrapped_name(skill_data), _skill_detail_text(skill_data)]

func _make_ultimate_skill_icon(skill_id: String, member: Resource, display_size: Vector2) -> Control:
	return SkillIconHelper.make_ultimate_icon(skill_id, member, display_size)

func _make_skill_icon(skill_id: String, member: Resource, display_size: Vector2 = Vector2.ZERO) -> Control:
	var px: Vector2 = display_size
	if px == Vector2.ZERO:
		px = Vector2(PASSIVE_ROW_ICON_PX, PASSIVE_ROW_ICON_PX)
	return SkillIconHelper.make_ally_equipped_icon(skill_id, member, px)

func _make_passive_icon(passive_id: String) -> Control:
	return PassiveIconHelper.make_icon(passive_id, Vector2(PASSIVE_ROW_ICON_PX, PASSIVE_ROW_ICON_PX))

func _on_skill_toggle_pressed(skill_id: String) -> void:
	var member: Resource = _get_view_adventurer()
	if member == null:
		return
	GameState.toggle_member_skill(member, skill_id)
	_rebuild_skill_tab()
	_refresh_tactics_ui(member)

func _on_back_pressed() -> void:
	SaveManager.save_game()
	_go_to(HOME_SCENE)

func _go_to(scene_path: String) -> void:
	SaveManager.save_game()
	SceneRouter.change_scene(scene_path)
