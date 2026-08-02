extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const FORGE_TITLE_FONT_SIZE: int = 34
const COLOR_TEXT_STRONG: Color = Color(0.98, 0.96, 0.92, 1.0)
const COLOR_SUB_STRONG: Color = Color(0.92, 0.88, 0.82, 1.0)
const COLOR_SHORT: Color = Color(0.82, 0.45, 0.42, 1)
const COLOR_OK: Color = Color(0.55, 0.88, 0.5)
const COLOR_SUB: Color = UiTypography.COLOR_SUB
const COLOR_TEXT: Color = UiTypography.COLOR_BODY
const COLOR_GOLD: Color = UiTypography.COLOR_GOLD
const _MaterialUiTokens = preload("res://scripts/equipment/MaterialUiTokens.gd")
const COLOR_ACCENT: Color = Color(0.82, 0.9, 1.0, 1)

const _AffixRoller = preload("res://scripts/equipment/AffixRoller.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _EquipmentReforgeHelper = preload("res://scripts/equipment/EquipmentReforgeHelper.gd")
const _EquipmentRandomMods = preload("res://scripts/equipment/EquipmentRandomMods.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _EquipmentUiTokens = preload("res://scripts/equipment/EquipmentUiTokens.gd")

## 装備画面と同じステアイコンを preload（class_name 経由の欠落を防ぐ）。
const _STAT_ICON_ATK: Texture2D = preload("res://assets/ui/equipment_ui/ICO_Equip_Stat_ATK.png")
const _STAT_ICON_DEF: Texture2D = preload("res://assets/ui/equipment_ui/ICO_Equip_Stat_DEF.png")
const _STAT_ICON_HP: Texture2D = preload("res://assets/ui/equipment_ui/ICO_Equip_Stat_HP.png")
const _STAT_ICON_CRIT: Texture2D = preload("res://assets/ui/equipment_ui/ICO_Equip_Stat_CRIT.png")
const _STAT_ICON_CRITDMG: Texture2D = preload("res://assets/ui/equipment_ui/ICO_Equip_Stat_CRITDMG.png")
const _STAT_ICON_SPD: Texture2D = preload("res://assets/ui/equipment_ui/ICO_Equip_Stat_SPD.png")
const _DETAIL_STAT_ICON_PX: float = 28.0
## ステ行のラベル列幅（「攻撃力」「クリティカル率」の左揃え用）。
const _DETAIL_STAT_KEY_W: float = 150.0
const _DETAIL_STAT_FONT_PX: int = 16
const _DETAIL_SUBTITLE_FONT_PX: int = 16

const _COST_MAT_ICON_PX: int = 48

const FORGE_FLASH_CRAFT: Color = Color(1.0, 0.78, 0.35)
const FORGE_FLASH_ENHANCE: Color = Color(0.72, 0.86, 1.0)
const FORGE_FLASH_ALCHEMY: Color = Color(0.55, 0.92, 0.78)
const FORGE_FLASH_DISMANTLE: Color = Color(0.86, 0.72, 1.0)
const FORGE_FLASH_PEAK_ALPHA: float = 0.32
## 下段ストリップ（作成可能／錬成素材）。BottomNav 上に専用帯を確保する。
## チップ高(112)＋ヘッダ分。外枠テクスチャ無しなので余白は控えめ。
const CRAFTABLE_STRIP_HEIGHT_PX: float = 148.0
const CRAFTABLE_SCROLL_MIN_H: float = 118.0
## カテゴリタブ下端〜 MainSplit 上端の隙間。
const MAIN_SPLIT_TOP_GAP_PX: float = 2.0
## MainSplit 下端〜素材帯の隙間。
const MAIN_TO_STRIP_GAP_PX: float = 14.0
## CategoryRow の設計高さ（アイコン横並び・縦に伸ばす）。
const CATEGORY_ROW_DESIGN_H_PX: float = 124.0
## モードタブ行の高さ。
const MODE_TABS_HEIGHT_PX: float = 72.0
## モードタブ下端〜カテゴリタブ上端。
const MODE_TO_CATEGORY_GAP_PX: float = 0.0
## ヘッダ下端〜モードタブ上端。
const HEADER_TO_MODE_GAP_PX: float = 2.0
## モードタブ同士の隙間（被らない最小）。
const MODE_TAB_SEPARATION_PX: int = 0
## モードタブ行を左右にはみ出させて各タブ幅を稼ぐ。
const MODE_TAB_SIDE_BLEED_PX: float = 14.0
## カテゴリタブ同士の隙間。
const CATEGORY_TAB_SEPARATION_PX: int = 2
const BOTTOM_NAV_FALLBACK_H_PX: float = 84.0
const LEFT_LIST_MIN_WIDTH_PX: float = 248.0
const LEFT_LIST_STRETCH_RATIO: float = 0.40
const DETAIL_STRETCH_RATIO: float = 0.60

@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _btn_produce: Button = $ModeTabs/BtnProduce
@onready var _btn_enhance: Button = $ModeTabs/BtnEnhance
@onready var _btn_alchemy: Button = $ModeTabs/BtnAlchemy
@onready var _btn_dismantle: Button = $ModeTabs/BtnDismantle
@onready var _produce_notify_dot: PanelContainer = $ModeTabs/BtnProduce/NotifyDot
@onready var _flash_overlay: ColorRect = $FxLayer/FlashOverlay
@onready var _category_row: HBoxContainer = $CategoryRow
@onready var _left_list: VBoxContainer = $MainSplit/LeftScroll/LeftList
@onready var _detail_panel: PanelContainer = $MainSplit/DetailPanel
@onready var _hero_panel: CenterContainer = $MainSplit/DetailPanel/DetailVBox/HeroPanel
@onready var _hero_stack: Control = $MainSplit/DetailPanel/DetailVBox/HeroPanel/HeroStack
@onready var _hero_pedestal: TextureRect = $MainSplit/DetailPanel/DetailVBox/HeroPanel/HeroStack/HeroPedestal
@onready var _hero_weapon_pivot: Control = $MainSplit/DetailPanel/DetailVBox/HeroPanel/HeroStack/HeroWeaponPivot
@onready var _hero_icon_slot: Control = $MainSplit/DetailPanel/DetailVBox/HeroPanel/HeroStack/HeroWeaponPivot/HeroIconSlot
@onready var _rarity_title_label: Label = $MainSplit/DetailPanel/DetailVBox/RarityTitleLabel
@onready var _title_label: Label = $MainSplit/DetailPanel/DetailVBox/TitleLabel
@onready var _subtitle_label: Label = $MainSplit/DetailPanel/DetailVBox/SubtitleLabel
@onready var _stats_grid: VBoxContainer = $MainSplit/DetailPanel/DetailVBox/StatsGrid
@onready var _unique_panel: PanelContainer = $MainSplit/DetailPanel/DetailVBox/UniquePanel
@onready var _unique_label: Label = $MainSplit/DetailPanel/DetailVBox/UniquePanel/UniqueLabel
@onready var _cost_panel: PanelContainer = $MainSplit/DetailPanel/DetailVBox/CostPanel
@onready var _materials_row: HBoxContainer = $MainSplit/DetailPanel/DetailVBox/CostPanel/CostVBox/MaterialsRow
@onready var _gold_cost_label: Label = $MainSplit/DetailPanel/DetailVBox/CostPanel/CostVBox/GoldRow/GoldCostLabel
@onready var _cost_header_label: Label = $MainSplit/DetailPanel/DetailVBox/CostPanel/CostVBox/CostHeaderLabel
@onready var _cost_button_gap: Control = $MainSplit/DetailPanel/DetailVBox/CostButtonGap
@onready var _craft_button: Button = $MainSplit/DetailPanel/DetailVBox/CraftButton
@onready var _craft_button_bottom_pad: Control = $MainSplit/DetailPanel/DetailVBox/CraftButtonBottomPad
@onready var _reason_label: Label = $MainSplit/DetailPanel/DetailVBox/ReasonLabel
@onready var _craftable_panel: PanelContainer = $CraftablePanel
@onready var _craftable_header: Label = $CraftablePanel/CraftableVBox/LabelCraftableHeader
@onready var _craftable_row: HBoxContainer = $CraftablePanel/CraftableVBox/CraftableScroll/CraftableRow
@onready var _craftable_scroll: ScrollContainer = $CraftablePanel/CraftableVBox/CraftableScroll
@onready var _label_status: Label = $LabelStatus

var _mode: String = "produce"
var _category: String = "weapon"
var _selected_craft: Resource = null
var _selected_enhance_item: Resource = null
var _selected_alchemy_base: Resource = null
var _selected_alchemy_fodder: Resource = null
var _selected_dismantle_item: Resource = null
var _mode_button_group: ButtonGroup
var _category_panels: Dictionary = {}
var _hero_pulse_base_scale: Vector2 = Vector2.ONE
var _bulk_dismantle_btn: Button
var _reforge_button: Button
var _dismantle_confirm: ConfirmationDialog
var _legendary_dismantle_confirm: ConfirmationDialog
var _legendary_dismantle_final_confirm: ConfirmationDialog
var _single_dismantle_confirm: ConfirmationDialog
var _alchemy_confirm: ConfirmationDialog
var _enhance_confirm: ConfirmationDialog
var _reforge_confirm: ConfirmationDialog
var _craft_confirm: ConfirmationDialog
var _pending_craft: Resource = null
var _selected_reforge_mod_index: int = -1
var _alchemy_fodder_overlay: Control = null
var _alchemy_fodder_list: VBoxContainer = null
var _pending_alchemy_fodder: Resource = null
var _result_overlay: Control = null
var _result_panel: PanelContainer = null
var _result_margin: MarginContainer = null
var _result_title_wrap: Control = null
var _result_title_tex: TextureRect = null
var _result_title_lbl: Label = null
var _result_detail_host: VBoxContainer = null
var _result_close_bottom_pad: Control = null
var _pending_dismantle_item: Resource = null
var _detail_scroll: ScrollContainer = null
## カテゴリ下〜下ナビ上の全体縦スクロール（MainSplit＋素材帯）。
var _body_scroll: ScrollContainer = null
var _body_vbox: VBoxContainer = null
var _main_split: HBoxContainer = null
## 錬成素材チップ／コスト素材チップの長押し（名前表示）。
const FODDER_LONG_PRESS_SEC: float = 0.45
const FODDER_PRESS_MOVE_CANCEL_PX: float = 20.0
var _fodder_pointer_down: bool = false
var _fodder_long_press_fired: bool = false
var _fodder_press_timer: SceneTreeTimer = null
var _fodder_press_item: Resource = null
var _fodder_press_origin: Vector2 = Vector2.ZERO
## 必要素材（遺跡の結晶など）長押し名表示。
const MAT_LONG_PRESS_SEC: float = 0.45
const MAT_PRESS_MOVE_CANCEL_PX: float = 20.0
var _mat_pointer_down: bool = false
var _mat_long_press_fired: bool = false
var _mat_press_timer: SceneTreeTimer = null
var _mat_press_name: String = ""
var _mat_press_origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	_label_title.text = ""
	AudioManager.play_bgm("forge")
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.FORGE)
	HeaderCurrencyHelper.apply_to_row($Header/HeaderRow)
	_ensure_body_scroll()
	_ensure_detail_scroll()
	_mode_button_group = ButtonGroup.new()
	_btn_produce.button_group = _mode_button_group
	_btn_enhance.button_group = _mode_button_group
	_btn_alchemy.button_group = _mode_button_group
	_btn_dismantle.button_group = _mode_button_group
	_btn_back.pressed.connect(_on_back_pressed)
	_btn_produce.pressed.connect(func(): _set_mode("produce"))
	_btn_enhance.pressed.connect(func(): _set_mode("enhance"))
	_btn_alchemy.pressed.connect(func(): _set_mode("alchemy"))
	_btn_dismantle.pressed.connect(func(): _set_mode("dismantle"))
	_btn_produce.set_meta("forge_mode", "produce")
	_btn_enhance.set_meta("forge_mode", "enhance")
	_btn_alchemy.set_meta("forge_mode", "alchemy")
	_btn_dismantle.set_meta("forge_mode", "dismantle")
	_btn_dismantle.disabled = false
	_btn_dismantle.text = "分解"
	_btn_alchemy.text = "錬成"
	_setup_dismantle_dialogs()
	_setup_alchemy_confirm()
	_setup_enhance_confirm()
	_setup_reforge_confirm()
	_setup_craft_confirm()
	_setup_result_dialog()
	_setup_bulk_dismantle_button()
	_setup_reforge_button()
	_detail_panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.detail_panel_style()
	)
	_cost_panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.cost_panel_style())
	_unique_panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.unique_panel_style())
	BlacksmithUiHelper.apply_bulk_dismantle_button(_bulk_dismantle_btn)
	_craft_button.pressed.connect(_on_craft_button_pressed)
	_produce_notify_dot.add_theme_stylebox_override("panel", BlacksmithUiHelper.notify_dot_style())
	_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	_hero_pulse_base_scale = _hero_weapon_pivot.scale
	_setup_hero_display_layout()
	_setup_forge_chrome()
	_apply_detail_typography()
	_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var detail_vbox: VBoxContainer = _detail_vbox()
	if detail_vbox != null:
		## Scroll 内では SHRINK。EXPAND だと中身が伸びてスクロール不能になる。
		detail_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		detail_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		## 生産詳細が下にはみ出さないよう行間を詰める。
		detail_vbox.add_theme_constant_override("separation", 5)
	_cost_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_craft_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_setup_craftable_header()
	_setup_tab_styles()
	_setup_left_list_layout()
	## 下帯はオミット。
	if _craftable_panel != null:
		_craftable_panel.visible = false
	_set_mode("produce")
	## カテゴリアイコン生成後の実寸で帯を再計算（生産／錬成の上下侵食防止）。
	call_deferred("_layout_craftable_strip")
	call_deferred("_enable_forge_scroll_touch")


## 一覧＋詳細＋素材帯をまとめて縦スクロール可能にする。
func _ensure_body_scroll() -> void:
	if _craftable_panel == null:
		return
	if get_node_or_null("BodyScroll") != null:
		_body_scroll = get_node("BodyScroll") as ScrollContainer
		_body_vbox = _body_scroll.get_node_or_null("BodyVBox") as VBoxContainer
		if _body_vbox != null:
			_main_split = _body_vbox.get_node_or_null("MainSplit") as HBoxContainer
		return
	_main_split = get_node_or_null("MainSplit") as HBoxContainer
	if _main_split == null:
		return
	_body_scroll = ScrollContainer.new()
	_body_scroll.name = "BodyScroll"
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_body_scroll.clip_contents = true
	_body_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_body_vbox = VBoxContainer.new()
	_body_vbox.name = "BodyVBox"
	_body_vbox.add_theme_constant_override("separation", int(MAIN_TO_STRIP_GAP_PX))
	_body_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	remove_child(_main_split)
	remove_child(_craftable_panel)
	_body_vbox.add_child(_main_split)
	_body_vbox.add_child(_craftable_panel)
	_body_scroll.add_child(_body_vbox)
	add_child(_body_scroll)
	## Header / ModeTabs / Category より手前、BottomNav / Fx より奥。
	var cat_i: int = _category_row.get_index() if _category_row != null else 0
	move_child(_body_scroll, cat_i + 1)
	_prepare_body_child_for_vbox(_main_split)
	_prepare_body_child_for_vbox(_craftable_panel)


func _prepare_body_child_for_vbox(ctrl: Control) -> void:
	if ctrl == null:
		return
	## 絶対配置から VBox 子へ切り替え。
	ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ctrl.anchor_right = 0.0
	ctrl.anchor_bottom = 0.0
	ctrl.offset_left = 0.0
	ctrl.offset_top = 0.0
	ctrl.offset_right = 0.0
	ctrl.offset_bottom = 0.0
	ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ctrl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ctrl.grow_vertical = Control.GROW_DIRECTION_END


## 詳細パネルを縦スクロール可能にする（錬成などで内容がはみ出す対策）。
func _ensure_detail_scroll() -> void:
	if _detail_panel == null:
		return
	if _detail_panel.get_node_or_null("DetailScroll") != null:
		_detail_scroll = _detail_panel.get_node("DetailScroll") as ScrollContainer
		return
	var detail_vbox: VBoxContainer = _detail_panel.get_node_or_null("DetailVBox") as VBoxContainer
	if detail_vbox == null:
		return
	_detail_scroll = ScrollContainer.new()
	_detail_scroll.name = "DetailScroll"
	_detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_detail_scroll.clip_contents = true
	_detail_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_panel.remove_child(detail_vbox)
	_detail_scroll.add_child(detail_vbox)
	_detail_panel.add_child(_detail_scroll)
	detail_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	detail_vbox.mouse_filter = Control.MOUSE_FILTER_PASS


func _detail_vbox() -> VBoxContainer:
	## DetailScroll 導入後はパスが変わるため、ノード参照経由で解決する。
	if _title_label != null:
		return _title_label.get_parent() as VBoxContainer
	if _detail_scroll != null:
		return _detail_scroll.get_node_or_null("DetailVBox") as VBoxContainer
	if _detail_panel != null:
		return _detail_panel.get_node_or_null("DetailVBox") as VBoxContainer
	return null


func _enable_forge_scroll_touch() -> void:
	## 全体 BodyScroll ＋ 左一覧・詳細・下帯。
	if _body_scroll != null:
		ScrollTouchHelper.enable(_body_scroll)
	var left_scroll: ScrollContainer = null
	if _main_split != null:
		left_scroll = _main_split.get_node_or_null("LeftScroll") as ScrollContainer
	if left_scroll != null:
		left_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		## 子が親幅に潰されると縦スクロール不能。
		if _left_list != null:
			_left_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_left_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		ScrollTouchHelper.enable(left_scroll)
	if _detail_scroll != null:
		_detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var detail_vbox: VBoxContainer = _detail_vbox()
		if detail_vbox != null:
			detail_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			detail_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		ScrollTouchHelper.enable(_detail_scroll)
	if _craftable_scroll != null:
		_craftable_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_craftable_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		if _craftable_row != null:
			_craftable_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			_craftable_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ScrollTouchHelper.enable(_craftable_scroll)
	## ScrollTouch の PASS 化で主ボタンの pressed が落ちるのを防ぐ。
	_restore_primary_button_input()


func _restore_primary_button_input() -> void:
	if _craft_button != null:
		_craft_button.set_meta(&"_cf_keep_mouse_stop", true)
		_craft_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if _reforge_button != null:
		_reforge_button.set_meta(&"_cf_keep_mouse_stop", true)
		_reforge_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if _bulk_dismantle_btn != null:
		_bulk_dismantle_btn.set_meta(&"_cf_keep_mouse_stop", true)
		_bulk_dismantle_btn.mouse_filter = Control.MOUSE_FILTER_STOP


## マウス左クリック／タッチ開始の共通判定（実機は ScreenTouch のみのことがある）。
func _is_primary_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false


func _setup_craftable_header() -> void:
	UiTypography.apply_body(_craftable_header, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	_layout_craftable_strip()


func _craftable_strip_natural_height() -> float:
	## ヘッダ＋チップ全体が見切れない高さ（下フレームの content_margin 込み）。
	var chip_h: float = float(BlacksmithUiHelper.CRAFTABLE_CHIP_HEIGHT)
	var header_h: float = 22.0
	if _craftable_header != null:
		header_h = maxf(header_h, _craftable_header.get_combined_minimum_size().y)
	var m: Vector4i = ForgeUiTokens.CRAFTABLE_PANEL_CONTENT_MARGINS
	var frame_pad: float = float(m.y + m.w)
	return header_h + 4.0 + chip_h + frame_pad + 8.0


func _layout_craftable_strip() -> void:
	## BodyScroll をカテゴリ下〜下ナビ上に置き、中で MainSplit＋素材帯を縦スクロール。
	_fit_mode_tabs_height()
	_fit_category_row_height()
	var nav: Control = $BottomNav
	var nav_h: float = BOTTOM_NAV_FALLBACK_H_PX
	if nav != null:
		nav_h = maxf(BOTTOM_NAV_FALLBACK_H_PX, absf(nav.offset_top))
		if nav.size.y > 1.0:
			nav_h = maxf(nav_h, nav.size.y)
	var category_bottom: float = _category_row_bottom_px()
	var body_top: float = category_bottom + MAIN_SPLIT_TOP_GAP_PX
	var body_bottom: float = -(nav_h + 4.0)
	var view_h: float = size.y
	if view_h < 1.0:
		view_h = 1280.0
	var body_view_h: float = maxf(320.0, view_h - body_top - absf(body_bottom))

	if _body_scroll != null:
		_body_scroll.anchor_left = 0.0
		_body_scroll.anchor_right = 1.0
		_body_scroll.anchor_top = 0.0
		_body_scroll.anchor_bottom = 1.0
		_body_scroll.offset_left = 8.0
		_body_scroll.offset_right = -8.0
		_body_scroll.offset_top = body_top
		_body_scroll.offset_bottom = body_bottom
		_body_scroll.grow_vertical = Control.GROW_DIRECTION_END
		_body_scroll.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_body_scroll.z_index = 0

	if _body_vbox != null:
		_body_vbox.custom_minimum_size = Vector2(maxf(0.0, size.x - 16.0), 0.0)
		_body_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_body_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var strip_h: float = 0.0
	if _craftable_panel != null and _craftable_panel.visible:
		strip_h = _craftable_strip_natural_height()

	if _main_split != null:
		## 素材帯は初画面下部に見える高さ。足りなければ BodyScroll で下へ。
		var main_min_h: float = body_view_h
		if strip_h > 0.0:
			main_min_h = maxf(
				360.0,
				body_view_h - strip_h - float(MAIN_TO_STRIP_GAP_PX)
			)
		_main_split.custom_minimum_size = Vector2(0, main_min_h)
		_main_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_main_split.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_main_split.clip_contents = true
		_main_split.z_index = 0

	if _craftable_panel != null:
		_craftable_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_craftable_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_craftable_panel.custom_minimum_size = Vector2(0, strip_h if _craftable_panel.visible else 0.0)
		## チップ見切れ防止（高さは natural で確保）。
		_craftable_panel.clip_contents = false
		_craftable_panel.z_index = 1
		_craftable_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_craftable_panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.craftable_panel_style())

	if _craftable_scroll != null:
		_craftable_scroll.custom_minimum_size = Vector2(0, float(BlacksmithUiHelper.CRAFTABLE_CHIP_HEIGHT))
		_craftable_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_craftable_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_craftable_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_craftable_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_craftable_scroll.clip_contents = true
	if _craftable_row != null:
		## EXPAND だと親幅に潰されて横スクロール不能になる。
		_craftable_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_craftable_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if _detail_panel != null:
		_detail_panel.clip_contents = true
	_category_row.z_index = 3
	var mode_tabs: Control = $ModeTabs
	if mode_tabs != null:
		mode_tabs.z_index = 3


func _fit_category_row_height() -> void:
	## タブ内容が行高を押し広げて MainSplit に食い込むのを防ぐ。
	var top: float = _category_row.offset_top
	var need_h: float = maxf(
		CATEGORY_ROW_DESIGN_H_PX,
		maxf(
			ForgeUiTokens.CATEGORY_MIN_SIZE.y,
			_category_row.get_combined_minimum_size().y
		)
	)
	_category_row.offset_bottom = top + need_h
	_category_row.clip_contents = true


func _category_row_bottom_px() -> float:
	var bottom: float = _category_row.offset_bottom
	if bottom < 120.0:
		return _category_row.offset_top + CATEGORY_ROW_DESIGN_H_PX
	## 実レイアウト後は size も見る（offset より下に描画されている場合）。
	if _category_row.size.y > 1.0:
		var by_size: float = _category_row.position.y + _category_row.size.y
		bottom = maxf(bottom, by_size)
	return bottom


func _setup_left_list_layout() -> void:
	## 長い装備名で行の最小幅が LeftScroll を超えると、左アイコンが欠けて見える。
	var left_scroll: ScrollContainer = null
	if _main_split != null:
		left_scroll = _main_split.get_node_or_null("LeftScroll") as ScrollContainer
	if left_scroll == null:
		return
	left_scroll.clip_contents = true
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	left_scroll.custom_minimum_size = Vector2(LEFT_LIST_MIN_WIDTH_PX, 0)
	left_scroll.size_flags_stretch_ratio = LEFT_LIST_STRETCH_RATIO
	_left_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_left_list.clip_contents = true
	if _detail_panel != null:
		_detail_panel.size_flags_stretch_ratio = DETAIL_STRETCH_RATIO
	_layout_craftable_strip()


func _fit_mode_tabs_height() -> void:
	## モードタブをヘッダ直下へ密着させ、カテゴリ／本文を続けて上へ積む。
	var mode_tabs: Control = $ModeTabs
	if mode_tabs == null:
		return
	var header: Control = get_node_or_null("Header") as Control
	var header_bottom: float = 46.0
	if header != null:
		header_bottom = maxf(header_bottom, header.offset_bottom)
		if header.size.y > 1.0:
			header_bottom = maxf(header_bottom, header.position.y + header.size.y)
	var top: float = header_bottom + HEADER_TO_MODE_GAP_PX
	mode_tabs.offset_top = top
	mode_tabs.offset_bottom = top + MODE_TABS_HEIGHT_PX
	## 左右へ少しはみ出して各タブの実効幅を広げる（カテゴリより広い帯）。
	mode_tabs.offset_left = -MODE_TAB_SIDE_BLEED_PX
	mode_tabs.offset_right = MODE_TAB_SIDE_BLEED_PX
	mode_tabs.add_theme_constant_override("separation", MODE_TAB_SEPARATION_PX)
	mode_tabs.clip_contents = false
	for child in mode_tabs.get_children():
		var tab := child as Control
		if tab == null:
			continue
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.size_flags_stretch_ratio = 1.0
		tab.clip_contents = false
		if tab is Button:
			var btn := tab as Button
			btn.custom_minimum_size = Vector2(0.0, maxf(btn.custom_minimum_size.y, MODE_TABS_HEIGHT_PX))
			btn.add_theme_constant_override("h_separation", 4)
	## カテゴリ行はモードタブ直下へ（隙間ゼロ）。
	var cat_top: float = mode_tabs.offset_bottom + MODE_TO_CATEGORY_GAP_PX
	_category_row.offset_top = cat_top
	_fit_category_row_height()

func _setup_hero_display_layout() -> void:
	## 詳細ペイン内に余裕を残す（右寄せ／はみ出し防止）。
	var stack_px: int = ForgeUiTokens.HERO_STACK_PX
	var pedestal_px: int = ForgeUiTokens.HERO_PEDESTAL_PX
	var display_px: int = ForgeUiTokens.HERO_DISPLAY_PX
	## 台座アートの視覚重心が右寄りなので、描画を少し左へ寄せる。
	var nudge_x: float = -14.0
	var nudge_y: float = ForgeUiTokens.HERO_NUDGE_Y_PX
	## 生産／錬成は下帯があるためヒーローを一段コンパクトに。
	if _craftable_panel != null and _craftable_panel.visible:
		stack_px = mini(stack_px, 176)
		display_px = mini(display_px, 140)
		pedestal_px = mini(pedestal_px, 160)
		nudge_y = 16.0
	## tscn の旧 260px 固定を上書き（これが高いと詳細が下帯へ食い込む）。
	## クレスト分＋下方向 nudge をスタック高に含める。
	var panel_h: float = float(stack_px) + nudge_y + 8.0
	## 縦並び: ヒーロー上 → レア／名前／ステ下（横並びは詳細枠内で重なるため撤回）。
	_hero_panel.custom_minimum_size = Vector2(0, panel_h)
	_hero_stack.custom_minimum_size = Vector2(stack_px, stack_px + int(nudge_y))
	_hero_stack.clip_contents = true
	_hero_panel.clip_contents = true
	var half_ped: float = float(pedestal_px) * 0.5
	_hero_pedestal.offset_left = -half_ped + nudge_x
	_hero_pedestal.offset_top = -half_ped + nudge_y
	_hero_pedestal.offset_right = half_ped + nudge_x
	_hero_pedestal.offset_bottom = half_ped + nudge_y
	_hero_pedestal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var half_weapon: float = float(display_px) * 0.5
	_hero_weapon_pivot.offset_left = -half_weapon + nudge_x
	_hero_weapon_pivot.offset_top = -half_weapon + nudge_y
	_hero_weapon_pivot.offset_right = half_weapon + nudge_x
	_hero_weapon_pivot.offset_bottom = half_weapon + nudge_y
	_hero_weapon_pivot.pivot_offset = Vector2(half_weapon, half_weapon)
	_hero_weapon_pivot.rotation_degrees = 0.0
	_hero_weapon_pivot.clip_contents = true
	_hero_icon_slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hero_icon_slot.custom_minimum_size = Vector2(display_px, display_px)
	_hero_icon_slot.clip_contents = true
	## visible は触らない（タブ切替後の _update_hero_icon 表示を消さない）。
	_ensure_hero_to_title_gap()


func _ensure_hero_to_title_gap() -> void:
	## 名前以降をまとめて下げる（ヒーロー直下の余白）。
	var detail_vbox: VBoxContainer = _detail_vbox()
	if detail_vbox == null:
		return
	var gap: Control = detail_vbox.get_node_or_null("HeroTitleGap") as Control
	if gap == null:
		gap = Control.new()
		gap.name = "HeroTitleGap"
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		detail_vbox.add_child(gap)
	detail_vbox.move_child(gap, _hero_panel.get_index() + 1)
	## 生産でボタンが下帯に沈まないよう、ヒーロー直下余白は詰める。
	gap.custom_minimum_size = Vector2(0, 8)


func _setup_alchemy_confirm() -> void:
	_alchemy_confirm = ConfirmationDialog.new()
	_alchemy_confirm.title = "錬成の確認"
	_alchemy_confirm.ok_button_text = "はい"
	_alchemy_confirm.cancel_button_text = "いいえ"
	_alchemy_confirm.confirmed.connect(_execute_alchemy)
	_alchemy_confirm.canceled.connect(_on_alchemy_confirm_canceled)
	add_child(_alchemy_confirm)
	_setup_alchemy_fodder_popup()


func _on_alchemy_confirm_canceled() -> void:
	_pending_alchemy_fodder = null
	_selected_alchemy_fodder = null
	_on_forge_confirm_canceled()


func _setup_alchemy_fodder_popup() -> void:
	## AcceptDialog（Window 排他）は実機で入力を食ってフリーズするため、
	## 結果ポップと同じ Control オーバーレイで素材一覧を出す。
	if _alchemy_fodder_overlay != null:
		return
	_alchemy_fodder_overlay = Control.new()
	_alchemy_fodder_overlay.name = "AlchemyFodderOverlay"
	_alchemy_fodder_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_alchemy_fodder_overlay.visible = false
	_alchemy_fodder_overlay.z_index = 90
	_alchemy_fodder_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_alchemy_fodder_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_alchemy_fodder_dim_input)
	_alchemy_fodder_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alchemy_fodder_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 780)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.07, 0.06, 0.05, 0.97)
	panel_sb.border_color = Color(0.55, 0.48, 0.32, 1.0)
	panel_sb.set_border_width_all(2)
	panel_sb.set_corner_radius_all(10)
	panel_sb.set_content_margin_all(18.0)
	panel.add_theme_stylebox_override("panel", panel_sb)
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(outer)
	var title := Label.new()
	title.text = "錬成素材を選ぶ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(title, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	outer.add_child(title)
	var hint := Label.new()
	hint.text = "素材にする装備を選んでください"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(hint, COLOR_SUB_STRONG)
	outer.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_alchemy_fodder_list = VBoxContainer.new()
	_alchemy_fodder_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_alchemy_fodder_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_alchemy_fodder_list)
	ScrollTouchHelper.enable(scroll)
	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.custom_minimum_size = Vector2(200, 48)
	close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	UiTypography.apply_menu_button(close_btn)
	close_btn.pressed.connect(_hide_alchemy_fodder_picker)
	outer.add_child(close_btn)


func _on_alchemy_fodder_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_alchemy_fodder_picker()


func _hide_alchemy_fodder_picker() -> void:
	if _alchemy_fodder_overlay != null:
		_alchemy_fodder_overlay.visible = false
	AudioManager.play_sfx("ui_cancel")


func _setup_craft_confirm() -> void:
	_craft_confirm = ConfirmationDialog.new()
	_craft_confirm.title = "装備生産"
	_craft_confirm.ok_button_text = "生産する"
	_craft_confirm.cancel_button_text = "やめる"
	_craft_confirm.confirmed.connect(_on_craft_confirmed)
	_craft_confirm.canceled.connect(_on_forge_confirm_canceled)
	add_child(_craft_confirm)


func _setup_enhance_confirm() -> void:
	_enhance_confirm = ConfirmationDialog.new()
	_enhance_confirm.title = "炉研ぎの確認"
	_enhance_confirm.ok_button_text = "はい"
	_enhance_confirm.cancel_button_text = "いいえ"
	_enhance_confirm.confirmed.connect(_on_enhance_confirmed)
	_enhance_confirm.canceled.connect(_on_forge_confirm_canceled)
	add_child(_enhance_confirm)


func _setup_reforge_confirm() -> void:
	_reforge_confirm = ConfirmationDialog.new()
	_reforge_confirm.title = "焼直しの確認"
	_reforge_confirm.ok_button_text = "はい"
	_reforge_confirm.cancel_button_text = "いいえ"
	_reforge_confirm.confirmed.connect(_on_reforge_confirmed)
	_reforge_confirm.canceled.connect(_on_forge_confirm_canceled)
	add_child(_reforge_confirm)


func _setup_reforge_button() -> void:
	_reforge_button = Button.new()
	_reforge_button.text = "焼直し"
	_reforge_button.visible = false
	_reforge_button.custom_minimum_size = Vector2(240, 64)
	_reforge_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reforge_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_reforge_button.set_meta(&"_cf_keep_mouse_stop", true)
	_reforge_button.mouse_filter = Control.MOUSE_FILTER_STOP
	BlacksmithUiHelper.apply_primary_button(
		_reforge_button, BlacksmithUiHelper.PRIMARY_KIND_ENHANCE
	)
	_reforge_button.pressed.connect(_on_reforge_pressed)
	var detail_vbox: VBoxContainer = _detail_vbox()
	if detail_vbox == null:
		return
	detail_vbox.add_child(_reforge_button)
	## 炉で研ぐ直下（CraftButton の次）。一括分解より前に置く。
	detail_vbox.move_child(_reforge_button, _craft_button.get_index() + 1)
	if _bulk_dismantle_btn != null and is_instance_valid(_bulk_dismantle_btn):
		detail_vbox.move_child(_bulk_dismantle_btn, _craft_button.get_index() + 2)
	_restore_primary_button_input()


func _setup_result_dialog() -> void:
	_ensure_result_overlay()


func _ensure_result_overlay() -> void:
	if _result_overlay != null:
		return
	_result_overlay = Control.new()
	_result_overlay.name = "ForgeResultOverlay"
	_result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_overlay.visible = false
	_result_overlay.z_index = 80
	_result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_result_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_result_overlay_dim_input)
	_result_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 900)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", ForgeUiTokens.result_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)
	_result_panel = panel
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 36)
	panel.add_child(margin)
	_result_margin = margin
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(outer)
	var title_wrap := Control.new()
	title_wrap.custom_minimum_size = Vector2(0, 120)
	title_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(title_wrap)
	_result_title_wrap = title_wrap
	_result_title_tex = TextureRect.new()
	_result_title_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_title_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_result_title_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_result_title_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_title_tex.visible = false
	title_wrap.add_child(_result_title_tex)
	_result_title_lbl = Label.new()
	_result_title_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_display(_result_title_lbl, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD)
	_result_title_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_result_title_lbl.add_theme_constant_override("shadow_outline_size", 4)
	title_wrap.add_child(_result_title_lbl)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 480)
	outer.add_child(scroll)
	_result_detail_host = VBoxContainer.new()
	_result_detail_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_detail_host.add_theme_constant_override("separation", 6)
	scroll.add_child(_result_detail_host)
	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.custom_minimum_size = Vector2(200, 48)
	UiTypography.apply_menu_button(close_btn)
	close_btn.pressed.connect(_hide_result_overlay)
	outer.add_child(close_btn)
	_result_close_bottom_pad = Control.new()
	_result_close_bottom_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_close_bottom_pad.custom_minimum_size = Vector2(0, 0)
	outer.add_child(_result_close_bottom_pad)


func _on_result_overlay_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_result_overlay()


func _hide_result_overlay() -> void:
	if _result_overlay != null:
		_result_overlay.visible = false
	_label_status.visible = false
	AudioManager.play_sfx("ui_cancel")


func _show_forge_result(title: String, body: String) -> void:
	## テキストのみのフォールバック（アイテム無し経路）。
	_ensure_result_overlay()
	_apply_result_chrome(title, "plain")
	for child in _result_detail_host.get_children():
		child.queue_free()
	var body_lbl := Label.new()
	body_lbl.text = body
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(body_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_TEXT_STRONG)
	_result_detail_host.add_child(body_lbl)
	_result_overlay.visible = true
	_log_craft(body)


func _framed_result_detail_opts() -> Dictionary:
	## 生産／強化／錬成の完了ポップ共通レイアウト（強化完了と同じ位置）。
	return {
		"show_owner": false,
		"header_icon_px": 96,
		## レアロゴは装備一覧セルと同寸（PanelContainer 直下配置は禁止）。
		"badge_ref_px": EquipmentUiTokens.INV_CELL_PX,
		"indent_left": 56,
		"indent_right": 24,
		"desc_wrap_width": 360,
		"desc_max_chars": 28,
		"effect_max_chars": 36,
		"value_color": UiTypography.COLOR_GOLD,
		"framed_icon": true,
		"show_enhance_badge": false,
		"content_pad_top": 18,
		"meta_host": self,
	}


func _show_forge_item_result(
	title: String,
	item: Resource,
	category: String,
	kind: String = "enhance",
	forge_before: Dictionary = {},
	extra_opts: Dictionary = {}
) -> void:
	_ensure_result_overlay()
	_apply_result_chrome(title, kind)
	var opts: Dictionary = _framed_result_detail_opts()
	if not forge_before.is_empty():
		opts["forge_before"] = forge_before
	for k: Variant in extra_opts.keys():
		opts[k] = extra_opts[k]
	EquipmentItemDetailHelper.populate_panel(
		_result_detail_host,
		item,
		category,
		opts
	)
	_result_overlay.visible = true
	_log_craft("%s: %s" % [title, EquipmentItemDetailHelper.short_name(item, category)])


func _show_forge_dismantle_result(materials: Dictionary, headline: String = "") -> void:
	_ensure_result_overlay()
	_apply_result_chrome("分解完了", "dismantle")
	for child in _result_detail_host.get_children():
		child.queue_free()
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 56)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_top", 18)
	_result_detail_host.add_child(pad)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	pad.add_child(col)
	if not headline.is_empty():
		var head := Label.new()
		head.text = headline
		head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiTypography.apply_body(head, UiTypography.SIZE_BODY_SMALL, COLOR_TEXT_STRONG)
		col.add_child(head)
	var gained := Label.new()
	gained.text = "獲得素材"
	UiTypography.apply_caption(gained, UiTypography.COLOR_GOLD)
	col.add_child(gained)
	var mat_ids: Array = materials.keys()
	mat_ids.sort()
	var any: bool = false
	for mat_id_v in mat_ids:
		var qty: int = int(materials[mat_id_v])
		if qty <= 0:
			continue
		any = true
		col.add_child(_make_dismantle_result_material_row(str(mat_id_v), qty))
	if not any:
		var empty := Label.new()
		empty.text = "（素材なし）"
		UiTypography.apply_caption(empty, COLOR_SUB_STRONG)
		col.add_child(empty)
	_result_overlay.visible = true
	_log_craft("分解完了: %s" % _format_material_summary(materials))


func _make_dismantle_result_material_row(mat_id: String, qty: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon_cell: Control = _MaterialUiTokens.make_icon_cell(mat_id, 72, true)
	icon_cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon_cell)
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	row.add_child(text_col)
	var name_lbl := Label.new()
	name_lbl.text = DataRegistry.get_material_name(mat_id)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_TEXT_STRONG)
	text_col.add_child(name_lbl)
	var qty_lbl := Label.new()
	qty_lbl.text = "×%d" % qty
	UiTypography.apply_body(qty_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	text_col.add_child(qty_lbl)
	return row


func _apply_result_chrome(title: String, kind: String) -> void:
	var use_ornate: bool = (
		kind == "produce" or kind == "enhance" or kind == "alchemy" or kind == "dismantle"
	)
	if _result_panel != null:
		if use_ornate:
			_result_panel.add_theme_stylebox_override(
				"panel", ForgeUiTokens.enhance_result_panel_style()
			)
			_result_panel.custom_minimum_size = Vector2(640, 920)
		else:
			_result_panel.add_theme_stylebox_override(
				"panel", ForgeUiTokens.result_panel_style()
			)
			_result_panel.custom_minimum_size = Vector2(620, 900)
	if _result_margin != null:
		if use_ornate:
			_result_margin.add_theme_constant_override("margin_left", 12)
			_result_margin.add_theme_constant_override("margin_top", 44)
			_result_margin.add_theme_constant_override("margin_right", 12)
			_result_margin.add_theme_constant_override("margin_bottom", 12)
		else:
			_result_margin.add_theme_constant_override("margin_left", 28)
			_result_margin.add_theme_constant_override("margin_top", 36)
			_result_margin.add_theme_constant_override("margin_right", 28)
			_result_margin.add_theme_constant_override("margin_bottom", 36)
	if _result_close_bottom_pad != null:
		_result_close_bottom_pad.custom_minimum_size = Vector2(0, 36 if use_ornate else 0)
	var title_tex: Texture2D = ForgeUiTokens.title_tex_for_result_kind(kind) if use_ornate else null
	var use_art: bool = use_ornate and title_tex != null
	if _result_title_wrap != null:
		_result_title_wrap.custom_minimum_size = Vector2(0, 100 if use_art else 120)
	if _result_title_tex != null:
		_result_title_tex.texture = title_tex
		_result_title_tex.visible = use_art
		if use_art:
			_result_title_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_result_title_tex.anchor_left = 0.18
			_result_title_tex.anchor_right = 0.82
			_result_title_tex.anchor_top = 0.12
			_result_title_tex.anchor_bottom = 0.88
			_result_title_tex.offset_left = 0.0
			_result_title_tex.offset_right = 0.0
			_result_title_tex.offset_top = 0.0
			_result_title_tex.offset_bottom = 0.0
		else:
			_result_title_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _result_title_lbl != null:
		_result_title_lbl.visible = not use_art
		_result_title_lbl.text = title


func _on_forge_confirm_canceled() -> void:
	_pending_craft = null
	AudioManager.play_sfx("ui_cancel")


func _setup_dismantle_dialogs() -> void:
	_single_dismantle_confirm = ConfirmationDialog.new()
	_single_dismantle_confirm.title = "分解の確認"
	_single_dismantle_confirm.ok_button_text = "はい"
	_single_dismantle_confirm.cancel_button_text = "いいえ"
	_single_dismantle_confirm.confirmed.connect(_on_single_dismantle_confirmed)
	_single_dismantle_confirm.canceled.connect(_on_single_dismantle_canceled)
	add_child(_single_dismantle_confirm)
	_dismantle_confirm = ConfirmationDialog.new()
	_dismantle_confirm.title = "N・R一括分解"
	_dismantle_confirm.ok_button_text = "はい"
	_dismantle_confirm.cancel_button_text = "いいえ"
	_dismantle_confirm.confirmed.connect(_on_bulk_dismantle_confirmed)
	_dismantle_confirm.canceled.connect(_on_forge_confirm_canceled)
	add_child(_dismantle_confirm)
	_legendary_dismantle_confirm = ConfirmationDialog.new()
	_legendary_dismantle_confirm.title = "L装備の分解（1/2）"
	_legendary_dismantle_confirm.ok_button_text = "はい"
	_legendary_dismantle_confirm.cancel_button_text = "いいえ"
	_legendary_dismantle_confirm.confirmed.connect(_on_legendary_dismantle_step1)
	_legendary_dismantle_confirm.canceled.connect(_on_forge_confirm_canceled)
	add_child(_legendary_dismantle_confirm)
	_legendary_dismantle_final_confirm = ConfirmationDialog.new()
	_legendary_dismantle_final_confirm.title = "L装備の分解（2/2）"
	_legendary_dismantle_final_confirm.ok_button_text = "はい"
	_legendary_dismantle_final_confirm.cancel_button_text = "いいえ"
	_legendary_dismantle_final_confirm.confirmed.connect(_on_legendary_dismantle_final)
	_legendary_dismantle_final_confirm.canceled.connect(_on_forge_confirm_canceled)
	add_child(_legendary_dismantle_final_confirm)

func _setup_bulk_dismantle_button() -> void:
	_bulk_dismantle_btn = Button.new()
	_bulk_dismantle_btn.text = "N・Rを一括分解"
	_bulk_dismantle_btn.visible = false
	_bulk_dismantle_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bulk_dismantle_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	BlacksmithUiHelper.apply_bulk_dismantle_button(_bulk_dismantle_btn)
	_bulk_dismantle_btn.pressed.connect(_on_bulk_dismantle_pressed)
	# MainSplit(HBox) の第3列にすると縦に肥大化し左一覧を圧迫するため、
	# 詳細パネル内・分解ボタン直下に置く。
	var detail_vbox: VBoxContainer = _detail_vbox()
	if detail_vbox == null:
		return
	detail_vbox.add_child(_bulk_dismantle_btn)
	detail_vbox.move_child(_bulk_dismantle_btn, _craft_button.get_index() + 1)

func _setup_forge_chrome() -> void:
	var back_tex: Texture2D = ForgeUiTokens.back_icon()
	if back_tex != null:
		_btn_back.text = ""
		_btn_back.icon = back_tex
		_btn_back.expand_icon = true
		_btn_back.custom_minimum_size = Vector2(40, 40)
	# 武器詳細ヒーロー: Desktop「武器背景」ペデスタル + 透過アイコン（Glow なし）。
	_hero_pedestal.texture = ForgeUiTokens.load_tex(ForgeUiTokens.HERO_ITEM_BG)
	_hero_pedestal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_pedestal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero_pedestal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero_pedestal.z_index = 0
	_hero_weapon_pivot.z_index = 1
	_hero_pedestal.visible = false
	_build_category_icons()

func _set_mode(mode: String) -> void:
	_mode = mode
	_btn_produce.button_pressed = mode == "produce"
	_btn_enhance.button_pressed = mode == "enhance"
	_btn_alchemy.button_pressed = mode == "alchemy"
	_btn_dismantle.button_pressed = mode == "dismantle"
	_category_row.visible = (
		mode == "produce" or mode == "enhance" or mode == "alchemy" or mode == "dismantle"
	)
	## 作成可能／錬成素材の下帯はオミット（錬成素材はポップアップへ）。
	if _craftable_panel != null:
		_craftable_panel.visible = false
	_bulk_dismantle_btn.visible = mode == "dismantle"
	if _reforge_button != null:
		_reforge_button.visible = false
	_selected_reforge_mod_index = -1
	if mode == "enhance":
		_selected_enhance_item = null
	elif mode == "alchemy":
		_selected_alchemy_base = null
		_selected_alchemy_fodder = null
	elif mode == "dismantle":
		_selected_dismantle_item = null
	_update_category_styles()
	_update_tab_styles()
	_apply_craft_button_style()
	## 先にサイズ調整→詳細再構築（逆だと装備アイコンが非表示のまま残る）。
	_setup_hero_display_layout()
	_refresh_all()
	_layout_craftable_strip()
	call_deferred("_layout_craftable_strip")
	call_deferred("_enable_forge_scroll_touch")


func _apply_craft_button_style() -> void:
	match _mode:
		"enhance", "alchemy":
			BlacksmithUiHelper.apply_primary_button(
				_craft_button, BlacksmithUiHelper.PRIMARY_KIND_ENHANCE
			)
			if _reforge_button != null:
				BlacksmithUiHelper.apply_primary_button(
					_reforge_button, BlacksmithUiHelper.PRIMARY_KIND_ENHANCE
				)
		"dismantle":
			BlacksmithUiHelper.apply_primary_button(
				_craft_button, BlacksmithUiHelper.PRIMARY_KIND_DISMANTLE
			)
		_:
			BlacksmithUiHelper.apply_primary_button(
				_craft_button, BlacksmithUiHelper.PRIMARY_KIND_PRODUCE
			)

func _set_category(category: String) -> void:
	if _mode == "produce":
		_category = category
		_selected_craft = null
	elif _mode == "enhance" or _mode == "alchemy" or _mode == "dismantle":
		_category = category
		if _mode == "enhance":
			_selected_enhance_item = null
			_selected_reforge_mod_index = -1
		elif _mode == "alchemy":
			_selected_alchemy_base = null
			_selected_alchemy_fodder = null
		else:
			_selected_dismantle_item = null
	else:
		return
	_update_category_styles()
	_refresh_all()

func _build_category_icons() -> void:
	for child in _category_row.get_children():
		child.queue_free()
	_category_panels.clear()
	## アイコンと文言を横並び（左アイコン・右ラベル）。縦は行高まで伸ばす。
	const CAT_ICON_PX: int = 40
	_category_row.offset_left = 0.0
	_category_row.offset_right = 0.0
	_category_row.add_theme_constant_override("separation", CATEGORY_TAB_SEPARATION_PX)
	for cat in ["weapon", "armor", "accessory"]:
		var wrap := PanelContainer.new()
		wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
		wrap.custom_minimum_size = ForgeUiTokens.CATEGORY_MIN_SIZE
		wrap.clip_contents = true
		wrap.add_theme_stylebox_override(
			"panel", BlacksmithUiHelper.category_tab_style(_category_tab_active(cat))
		)
		_category_row.add_child(wrap)
		_category_panels[cat] = wrap
		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 12
		row.offset_top = 10
		row.offset_right = -12
		row.offset_bottom = -10
		row.add_theme_constant_override("separation", 12)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(CAT_ICON_PX, CAT_ICON_PX)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = ForgeUiTokens.category_icon(cat)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var lbl := Label.new()
		lbl.text = BlacksmithUiHelper.category_label(cat)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_caption(lbl)
		row.add_child(lbl)
		var btn := Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.pressed.connect(func(): _set_category(cat))
		wrap.add_child(btn)

func _category_tab_active(cat: String) -> bool:
	return _category == cat and (
		_mode == "produce" or _mode == "enhance" or _mode == "alchemy" or _mode == "dismantle"
	)

func _update_category_styles() -> void:
	for cat in _category_panels.keys():
		var panel: PanelContainer = _category_panels[cat]
		if panel != null:
			panel.add_theme_stylebox_override(
				"panel", BlacksmithUiHelper.category_tab_style(_category_tab_active(str(cat)))
			)

func _apply_detail_typography() -> void:
	_rarity_title_label.visible = false
	UiTypography.apply_display(_title_label, UiTypography.SIZE_BODY, COLOR_TEXT_STRONG)
	UiTypography.apply_caption(_subtitle_label, COLOR_SUB_STRONG)
	_subtitle_label.add_theme_font_size_override("font_size", _DETAIL_SUBTITLE_FONT_PX)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(_unique_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_caption(_cost_header_label, UiTypography.COLOR_GOLD)
	UiTypography.apply_caption(_gold_cost_label, COLOR_TEXT_STRONG)
	# 統計・理由ラベルも暗背景で読めるよう強めの色を既定に
	_reason_label.add_theme_color_override("font_color", COLOR_SUB_STRONG)
	## ステ列は内容幅で中央配置しつつ、行内は左揃え。
	_stats_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stats_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_stats_grid.alignment = BoxContainer.ALIGNMENT_BEGIN

func _setup_tab_styles() -> void:
	_update_tab_styles()

func _update_tab_styles() -> void:
	BlacksmithUiHelper.apply_mode_tab(_btn_produce, _mode == "produce")
	BlacksmithUiHelper.apply_mode_tab(_btn_enhance, _mode == "enhance")
	BlacksmithUiHelper.apply_mode_tab(_btn_alchemy, _mode == "alchemy")
	BlacksmithUiHelper.apply_mode_tab(_btn_dismantle, _mode == "dismantle")

func _refresh_all() -> void:
	_update_currency()
	_update_mode_tab_dots()
	_rebuild_left_list()
	_rebuild_detail()
	## 下帯（作成可能／錬成素材）はオミット。
	if _craftable_panel != null:
		_craftable_panel.visible = false
	call_deferred("_layout_craftable_strip")
	## 一覧再生成後も全タブでタッチスクロールを維持。
	call_deferred("_enable_forge_scroll_touch")


## 一覧タップ時: 左一覧は作り直さずハイライト＋詳細のみ更新（体感のカクつき対策）。
func _refresh_selection() -> void:
	_sync_left_list_selection_styles()
	_rebuild_detail()


func _tag_list_card(
	panel: PanelContainer,
	kind: String,
	ref: Variant,
	rarity: int,
	craftable: bool = false
) -> void:
	panel.set_meta("forge_list_kind", kind)
	panel.set_meta("forge_list_ref", ref)
	panel.set_meta("forge_rarity", rarity)
	panel.set_meta("forge_craftable", craftable)


func _sync_left_list_selection_styles() -> void:
	for child in _left_list.get_children():
		if not (child is PanelContainer):
			continue
		var panel := child as PanelContainer
		if not panel.has_meta("forge_list_kind"):
			continue
		var kind: String = str(panel.get_meta("forge_list_kind"))
		var ref: Variant = panel.get_meta("forge_list_ref")
		var rarity: int = int(panel.get_meta("forge_rarity"))
		var craftable: bool = bool(panel.get_meta("forge_craftable"))
		var selected: bool = false
		match kind:
			"recipe":
				selected = ref == _selected_craft
			"enhance":
				selected = ref == _selected_enhance_item
			"dismantle":
				selected = ref == _selected_dismantle_item
			"alchemy":
				selected = ref == _selected_alchemy_base
			_:
				continue
		panel.add_theme_stylebox_override(
			"panel", BlacksmithUiHelper.list_card_style(selected, craftable, rarity)
		)
		if panel.get_child_count() < 1:
			continue
		var row := panel.get_child(0) as HBoxContainer
		if row == null or row.get_child_count() < 1:
			continue
		BlacksmithUiHelper.apply_list_icon_selection(
			row.get_child(0) as Control, rarity, selected
		)

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()

func _update_mode_tab_dots() -> void:
	_btn_produce.text = "生産"
	_btn_alchemy.text = "錬成"
	_produce_notify_dot.visible = BlacksmithUiHelper.has_craftable_recipes()

func _rebuild_left_list() -> void:
	for child in _left_list.get_children():
		child.queue_free()
	## カテゴリタブ直下に一覧を密着（余白パッド無し）。
	_left_list.add_child(_make_list_section_header())
	if _mode == "produce":
		_rebuild_produce_left_list()
	elif _mode == "enhance":
		_rebuild_enhance_left_list()
	elif _mode == "alchemy":
		_rebuild_alchemy_left_list()
	else:
		_rebuild_dismantle_left_list()
	_update_bulk_dismantle_button()


func _make_list_section_header() -> Control:
	var wrap := HBoxContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## 生産一覧ヘッダがカテゴリタブ／先頭カードに食われないよう高さを確保。
	wrap.custom_minimum_size = Vector2(0, 36)
	wrap.add_theme_constant_override("separation", 6)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rule_l := ColorRect.new()
	rule_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule_l.custom_minimum_size = Vector2(12, 2)
	rule_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rule_l.color = Color(0.72, 0.58, 0.28, 0.55)
	rule_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(rule_l)
	var lbl := Label.new()
	lbl.text = _list_section_title()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(lbl, UiTypography.COLOR_GOLD)
	wrap.add_child(lbl)
	var rule_r := ColorRect.new()
	rule_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule_r.custom_minimum_size = Vector2(12, 2)
	rule_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rule_r.color = Color(0.72, 0.58, 0.28, 0.55)
	rule_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(rule_r)
	return wrap


func _list_section_title() -> String:
	match _mode:
		"enhance":
			return "%s一覧" % BlacksmithUiHelper.category_label(_category)
		"alchemy":
			return "錬成・主材"
		"dismantle":
			return "分解・%s" % BlacksmithUiHelper.category_label(_category)
		_:
			return "%s一覧" % BlacksmithUiHelper.category_label(_category)


func _rebuild_produce_left_list() -> void:
	var recipes: Array = BlacksmithUiHelper.recipes_for_category(_category)
	if recipes.is_empty():
		_left_list.add_child(_make_empty_label("（レシピなし）"))
		_selected_craft = null
		return
	if _selected_craft == null or _selected_craft not in recipes:
		_selected_craft = recipes[0]
	for craft in recipes:
		_left_list.add_child(_make_recipe_list_card(craft))

func _rebuild_enhance_left_list() -> void:
	var items: Array = _sorted_enhance_candidates()
	if items.is_empty():
		_left_list.add_child(_make_empty_label(_empty_label_for_category(_category, "enhance")))
		_selected_enhance_item = null
		return
	if _selected_enhance_item == null or _selected_enhance_item not in items:
		_selected_enhance_item = items[0]
	for item in items:
		_left_list.add_child(_make_enhance_list_card(item))

func _rebuild_dismantle_left_list() -> void:
	var items: Array = _sorted_dismantle_candidates()
	if items.is_empty():
		_left_list.add_child(_make_empty_label(_empty_label_for_category(_category, "dismantle")))
		_selected_dismantle_item = null
		return
	if _selected_dismantle_item == null or _selected_dismantle_item not in items:
		_selected_dismantle_item = items[0]
	for item in items:
		_left_list.add_child(_make_dismantle_list_card(item))


func _rebuild_alchemy_left_list() -> void:
	var items: Array = _sorted_alchemy_base_candidates()
	if items.is_empty():
		_left_list.add_child(_make_empty_label(_empty_label_for_category(_category, "alchemy")))
		_selected_alchemy_base = null
		_selected_alchemy_fodder = null
		return
	if _selected_alchemy_base == null or _selected_alchemy_base not in items:
		_selected_alchemy_base = items[0]
		_selected_alchemy_fodder = null
	for item in items:
		_left_list.add_child(_make_alchemy_base_card(item))

func _empty_label_for_category(category: String, mode: String) -> String:
	var kind: String = BlacksmithUiHelper.category_label(category)
	if mode == "dismantle":
		return "（分解可能な%sがありません）" % kind
	if mode == "alchemy":
		return "（錬成できる%sがありません）" % kind
	return "（鑑定済みの%sがありません）" % kind

func _make_empty_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COLOR_SUB_STRONG)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _make_recipe_list_card(craft: Resource) -> PanelContainer:
	var can_craft: bool = CraftHelper.can_craft(craft)
	var selected: bool = craft == _selected_craft
	var rarity: int = BlacksmithUiHelper.output_rarity(craft)
	var panel := _make_owned_list_card_shell(selected, rarity)
	_tag_list_card(panel, "recipe", craft, rarity, can_craft)
	panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.list_card_style(selected, can_craft, rarity)
	)
	panel.gui_input.connect(_on_recipe_card_input.bind(craft))
	var row: HBoxContainer = panel.get_child(0) as HBoxContainer
	row.add_child(
		_make_selectable_list_icon(
			str(craft.output_id), str(craft.output_type), rarity, selected
		)
	)
	var name_lbl := Label.new()
	name_lbl.text = BlacksmithUiHelper.output_display_name(craft)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_list_name_label(name_lbl, BlacksmithUiHelper.rarity_name_color(rarity))
	row.add_child(name_lbl)
	return panel

func _on_recipe_card_input(event: InputEvent, craft: Resource) -> void:
	if _is_primary_press(event):
		if craft == _selected_craft:
			return
		_selected_craft = craft
		_refresh_selection()

func _make_enhance_list_card(item: Resource) -> PanelContainer:
	var selected: bool = item == _selected_enhance_item
	var level: int = _EquipmentEnhancer.get_enhance_level(item)
	var category: String = _category
	var item_id: String = _item_id_for_category(item, category)
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	var panel := _make_owned_list_card_shell(selected, rarity)
	_tag_list_card(panel, "enhance", item, rarity)
	panel.gui_input.connect(_on_enhance_card_input.bind(item))
	var row: HBoxContainer = panel.get_child(0) as HBoxContainer
	row.add_child(_make_selectable_list_icon(item_id, category, rarity, selected, item))
	var name_lbl := Label.new()
	name_lbl.text = _EquipmentEnhancer.get_display_name(item)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_color: Color = BlacksmithUiHelper.rarity_name_color(rarity)
	if level >= _EquipmentEnhancer.MAX_FORGE_LEVEL:
		name_color = UiTypography.COLOR_GOLD
	_apply_list_name_label(name_lbl, name_color)
	row.add_child(name_lbl)
	return panel

func _make_dismantle_list_card(item: Resource) -> PanelContainer:
	var selected: bool = item == _selected_dismantle_item
	var category: String = _category
	var item_id: String = _item_id_for_category(item, category)
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	var panel := _make_owned_list_card_shell(selected, rarity)
	_tag_list_card(panel, "dismantle", item, rarity)
	panel.gui_input.connect(_on_dismantle_card_input.bind(item))
	var row: HBoxContainer = panel.get_child(0) as HBoxContainer
	row.add_child(_make_selectable_list_icon(item_id, category, rarity, selected, item))
	var name_lbl := Label.new()
	name_lbl.text = _EquipmentEnhancer.get_display_name(item)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_list_name_label(name_lbl, BlacksmithUiHelper.rarity_name_color(rarity))
	row.add_child(name_lbl)
	return panel

func _item_id_for_category(item: Resource, category: String) -> String:
	match category:
		"armor":
			return str(item.armor_id)
		"accessory":
			return str(item.accessory_id)
		_:
			return str(item.weapon_id)

func _make_owned_list_card_shell(selected: bool, rarity: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, BlacksmithUiHelper.LIST_CARD_MIN_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.clip_contents = true
	## PASS: 左一覧の縦スクロールを奪わない。
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.list_card_style(selected, false, rarity)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	return panel


func _apply_list_name_label(lbl: Label, color: Color) -> void:
	## 1行。長い名前はフォント縮小のうえ、それでも溢れる場合のみ省略。
	## 省略禁止だと行最小幅が LeftScroll を超え、左アイコンが欠ける。
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.max_lines_visible = 1
	lbl.clip_text = true
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_size: int = UiTypography.SIZE_CAPTION
	var char_count: int = lbl.text.length()
	if char_count >= 10:
		font_size = 14
	elif char_count >= 7:
		font_size = 16
	UiTypography.apply_body(lbl, font_size, color)

func _on_enhance_card_input(event: InputEvent, item: Resource) -> void:
	if _is_primary_press(event):
		if item == _selected_enhance_item:
			return
		_selected_enhance_item = item
		_selected_reforge_mod_index = -1
		_refresh_selection()

func _on_dismantle_card_input(event: InputEvent, item: Resource) -> void:
	if _is_primary_press(event):
		if item == _selected_dismantle_item:
			return
		_selected_dismantle_item = item
		_refresh_selection()


func _make_alchemy_base_card(item: Resource) -> PanelContainer:
	var selected: bool = item == _selected_alchemy_base
	var category: String = _category
	var item_id: String = _item_id_for_category(item, category)
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	var panel := _make_owned_list_card_shell(selected, rarity)
	_tag_list_card(panel, "alchemy", item, rarity)
	panel.gui_input.connect(_on_alchemy_base_card_input.bind(item))
	var row: HBoxContainer = panel.get_child(0) as HBoxContainer
	row.add_child(_make_selectable_list_icon(item_id, category, rarity, selected, item))
	var name_lbl := Label.new()
	name_lbl.text = _EquipmentEnhancer.get_display_name(item)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_list_name_label(name_lbl, BlacksmithUiHelper.rarity_name_color(rarity))
	row.add_child(name_lbl)
	return panel


func _on_alchemy_base_card_input(event: InputEvent, item: Resource) -> void:
	if _is_primary_press(event):
		if item == _selected_alchemy_base:
			return
		if _selected_alchemy_base != item:
			_selected_alchemy_fodder = null
		_selected_alchemy_base = item
		_refresh_selection()


func _rebuild_detail() -> void:
	_clear_stats_grid()
	_clear_materials_row()
	_clear_hero_icon()
	_unique_panel.visible = false
	_reason_label.visible = false
	_cost_panel.visible = true
	_craft_button.visible = true
	if _reforge_button != null:
		_reforge_button.visible = false
	## 錬成以外は説明文の縮小設定を戻す。
	if _mode != "alchemy":
		_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		UiTypography.apply_caption(_subtitle_label, COLOR_SUB_STRONG)
		_subtitle_label.add_theme_font_size_override("font_size", _DETAIL_SUBTITLE_FONT_PX)
		_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _mode == "produce":
		_rebuild_produce_detail()
	elif _mode == "enhance":
		_rebuild_enhance_detail()
	elif _mode == "alchemy":
		_rebuild_alchemy_detail()
	else:
		_rebuild_dismantle_detail()
	if _mode != "alchemy":
		_layout_detail_action_anchor()

func _clear_stats_grid() -> void:
	## queue_free だと同フレームに新旧が混在しレイアウトが崩れることがあるため即 free。
	while _stats_grid.get_child_count() > 0:
		var child: Node = _stats_grid.get_child(0)
		_stats_grid.remove_child(child)
		child.free()

func _clear_materials_row() -> void:
	while _materials_row.get_child_count() > 0:
		var child: Node = _materials_row.get_child(0)
		_materials_row.remove_child(child)
		child.free()

func _clear_hero_icon() -> void:
	while _hero_icon_slot.get_child_count() > 0:
		var child: Node = _hero_icon_slot.get_child(0)
		_hero_icon_slot.remove_child(child)
		child.free()

func _set_detail_empty(message: String) -> void:
	_rarity_title_label.visible = false
	_rarity_title_label.text = ""
	_title_label.text = message
	_subtitle_label.text = ""
	_hero_weapon_pivot.visible = false
	_hero_pedestal.visible = false
	_cost_panel.visible = false
	_craft_button.visible = false
	if _reforge_button != null:
		_reforge_button.visible = false

func _add_stat_row(key: String, value: String, stat_key: String = "") -> void:
	## [アイコン][固定幅ラベル][数値]。ラベル列を左揃え（攻撃力／クリティカル率が縦に揃う）。
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## アイコン無し行でもラベル起点を揃えるため、常に同幅スロットを置く。
	var icon_host := Control.new()
	icon_host.custom_minimum_size = Vector2(_DETAIL_STAT_ICON_PX, _DETAIL_STAT_ICON_PX)
	icon_host.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stat_tex: Texture2D = _stat_icon_texture(stat_key, key)
	if stat_tex != null:
		var icon := TextureRect.new()
		icon.texture = stat_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.modulate = Color(1.28, 1.20, 1.08, 1.0)
		icon_host.add_child(icon)
	row.add_child(icon_host)
	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.custom_minimum_size = Vector2(_DETAIL_STAT_KEY_W, 0)
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	key_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	key_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_lbl.clip_text = false
	UiTypography.apply_caption(key_lbl, COLOR_SUB_STRONG)
	key_lbl.add_theme_font_size_override("font_size", _DETAIL_STAT_FONT_PX)
	row.add_child(key_lbl)
	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	val_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	val_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(val_lbl, COLOR_TEXT_STRONG)
	val_lbl.add_theme_font_size_override("font_size", _DETAIL_STAT_FONT_PX)
	row.add_child(val_lbl)
	_stats_grid.add_child(row)


func _stat_icon_texture(stat_key: String, label: String) -> Texture2D:
	## preload 済みテクスチャのみ返す（実行時 load 失敗を排除）。
	match _equip_stat_key(stat_key, label):
		"attack":
			return _STAT_ICON_ATK
		"defense":
			return _STAT_ICON_DEF
		"hp":
			return _STAT_ICON_HP
		"crit_rate":
			return _STAT_ICON_CRIT
		"crit_damage":
			return _STAT_ICON_CRITDMG
		"speed":
			return _STAT_ICON_SPD
		_:
			return null


func _equip_stat_key(stat_key: String, label: String) -> String:
	## 鍛冶側キー（atk/def/crit）を装備画面キーへ。
	match stat_key:
		"atk", "attack":
			return "attack"
		"def", "defense":
			return "defense"
		"hp":
			return "hp"
		"crit", "crit_rate":
			return "crit_rate"
		"crit_damage":
			return "crit_damage"
		"speed":
			return "speed"
		_:
			pass
	if label.find("防御") >= 0:
		return "defense"
	if label.find("攻撃") >= 0:
		return "attack"
	if label.find("クリティカル") >= 0 or label.find("会心") >= 0:
		return "crit_rate"
	if label == "HP" or label.begins_with("HP"):
		return "hp"
	return ""


func _update_hero_icon(item_id: String, category: String, _rarity: int) -> void:
	_clear_hero_icon()
	## 武器背景の上に透過で武器本体。
	_hero_pedestal.visible = BlacksmithUiHelper.HERO_USE_PEDESTAL and _hero_pedestal.texture != null
	_hero_weapon_pivot.visible = true
	_hero_weapon_pivot.rotation_degrees = 0.0
	var display_px: int = ForgeUiTokens.HERO_DISPLAY_PX
	BlacksmithUiHelper.attach_hero_icon(_hero_icon_slot, item_id, category, display_px)


func _add_stats_section_spacer(height: float = 24.0) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_grid.add_child(gap)

func _populate_stats_from_entries(entries: Array) -> void:
	for entry in entries:
		if entry is Dictionary:
			_add_stat_row(
				str(entry.get("label", "")),
				str(entry.get("value", "")),
				str(entry.get("key", ""))
			)

func _populate_unique_from_craft(craft: Resource) -> void:
	if craft == null or str(craft.output_type) != "weapon":
		return
	var wd: Resource = DataRegistry.get_weapon_data(str(craft.output_id))
	if wd == null:
		return
	var effect_text: String = EquipmentItemDetailHelper.weapon_legendary_effect_text_from_data(wd)
	if effect_text.is_empty():
		return
	_unique_label.text = "固有効果\n%s" % effect_text
	_unique_panel.visible = true

func _add_meta_stat_row(key: String, value: String) -> void:
	## 所持数などコスト寄りメタ行: 小さめ＋やや右寄せ。
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(36, 0)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pad)
	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	key_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(key_lbl, COLOR_SUB_STRONG)
	row.add_child(key_lbl)
	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	val_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	val_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(val_lbl, COLOR_TEXT_STRONG)
	row.add_child(val_lbl)
	_stats_grid.add_child(row)


func _update_cost_panel(gold_cost: int, materials: Dictionary) -> void:
	_cost_header_label.text = "必要コスト"
	UiTypography.apply_caption(_cost_header_label, UiTypography.COLOR_GOLD)
	_gold_cost_label.text = "必要ゴールド: %d" % gold_cost
	UiTypography.apply_caption(
		_gold_cost_label,
		COLOR_GOLD if GameState.gold >= gold_cost else COLOR_SHORT
	)
	for child in _materials_row.get_children():
		child.queue_free()
	for mat_id in materials:
		_materials_row.add_child(_make_material_req_cell(str(mat_id), int(materials[mat_id])))

func _rebuild_produce_detail() -> void:
	if _selected_craft == null:
		_set_detail_empty("レシピを選択してください")
		return
	var craft: Resource = _selected_craft
	var can_craft: bool = CraftHelper.can_craft(craft)
	var rarity: int = BlacksmithUiHelper.output_rarity(craft)
	_update_hero_icon(str(craft.output_id), str(craft.output_type), rarity)
	_rarity_title_label.visible = false
	_rarity_title_label.text = ""
	var rarity_col: Color = BlacksmithUiHelper.rarity_name_color(rarity)
	_title_label.text = BlacksmithUiHelper.output_display_name(craft)
	_title_label.add_theme_color_override("font_color", rarity_col)
	_subtitle_label.text = BlacksmithUiHelper.output_subtitle(craft)
	_populate_stats_from_entries(BlacksmithUiHelper.craft_stat_entries(craft))
	_populate_unique_from_craft(craft)
	_update_cost_panel(int(craft.gold_cost), craft.required_materials)
	_craft_button.text = "生産する"
	_craft_button.disabled = not can_craft
	if can_craft:
		_reason_label.visible = false
	else:
		_reason_label.text = _craft_button_label(craft, false)
		_reason_label.visible = not _reason_label.text.is_empty()
	_layout_detail_action_anchor()

func _rebuild_enhance_detail() -> void:
	if _selected_enhance_item == null:
		_set_detail_empty("%sを選択してください" % BlacksmithUiHelper.category_label(_category))
		return
	var item: Resource = _selected_enhance_item
	var level: int = _EquipmentEnhancer.get_enhance_level(item)
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	var item_id: String = _item_id_for_category(item, _category)
	_update_hero_icon(item_id, _category, rarity)
	_rarity_title_label.visible = false
	_title_label.text = _EquipmentEnhancer.get_display_name(item)
	_title_label.add_theme_color_override("font_color", BlacksmithUiHelper.rarity_name_color(rarity))
	_subtitle_label.text = "炉研ぎ +%d / +%d" % [level, _EquipmentEnhancer.MAX_FORGE_LEVEL]
	_populate_enhance_stats(item)
	if _is_item_equipped(item):
		_add_stat_row("状態", "装備中")
	_add_stats_section_spacer(12.0)
	_populate_reforge_mod_rows(item)
	_add_stats_section_spacer(24.0)
	var at_max: bool = level >= _EquipmentEnhancer.MAX_FORGE_LEVEL
	if at_max:
		_craft_button.visible = false
	else:
		var check: Dictionary = _EquipmentEnhancer.can_enhance_item(item)
		var next_level: int = int(check.get("next_level", level + 1))
		var gold_cost: int = int(check.get("gold_cost", _EquipmentEnhancer.get_gold_cost(next_level, rarity)))
		var materials: Dictionary = check.get(
			"materials", _EquipmentEnhancer.get_material_cost(next_level, rarity)
		)
		_update_cost_panel(gold_cost, materials)
		_craft_button.visible = true
		_craft_button.text = "炉で研ぐ（+%d）" % next_level
		_craft_button.disabled = not bool(check.get("ok", false))
		if not bool(check.get("ok", false)):
			_reason_label.text = str(check.get("reason", ""))
			_reason_label.visible = not _reason_label.text.is_empty()
		else:
			_reason_label.visible = false
	_update_reforge_action(item, at_max)
	## ScrollTouch が詳細 rebuild 後に主ボタンを PASS 化するため STOP を戻す。
	_restore_primary_button_input()
	call_deferred("_restore_primary_button_input")

func _populate_enhance_stats(item: Resource) -> void:
	match _category:
		"weapon":
			var current_atk: int = _EquipmentEnhancer.get_effective_attack(item)
			var level: int = _EquipmentEnhancer.get_enhance_level(item)
			var forge_flat: int = BalanceConfig.EQUIP_FORGE_FLAT_PER_LEVEL
			if level >= _EquipmentEnhancer.MAX_FORGE_LEVEL:
				_add_stat_row("攻撃力", "%d（上限）" % current_atk, "atk")
			else:
				_add_stat_row("攻撃力", "%d → %d" % [current_atk, current_atk + forge_flat], "atk")
		"armor":
			var def_now: int = _EquipmentEnhancer.effective_armor_defense(item)
			var hp_now: int = _EquipmentEnhancer.effective_armor_hp(item)
			var enh: int = _EquipmentEnhancer.get_enhance_level(item)
			var forge_flat: int = BalanceConfig.EQUIP_FORGE_FLAT_PER_LEVEL
			var forge_hp: int = BalanceConfig.EQUIP_FORGE_HP_PER_LEVEL
			if enh >= _EquipmentEnhancer.MAX_FORGE_LEVEL:
				_add_stat_row("防御力", "%d（上限）" % def_now, "def")
				_add_stat_row("HP", "%d（上限）" % hp_now, "hp")
			else:
				_add_stat_row("防御力", "%d → %d" % [def_now, def_now + forge_flat], "def")
				_add_stat_row("HP", "%d → %d" % [hp_now, hp_now + forge_hp], "hp")
		"accessory":
			var acc_data: Resource = DataRegistry.get_accessory_data(str(item.accessory_id))
			var forge_flat: int = BalanceConfig.EQUIP_FORGE_FLAT_PER_LEVEL
			for field_pair in [["hp_bonus", "HP", "hp"], ["attack_bonus", "攻撃力", "atk"], ["defense_bonus", "防御力", "def"]]:
				var raw: int = _AccessoryStatResolver.resolve_int_stat(item, field_pair[0], acc_data)
				if raw <= 0:
					continue
				var now: int = _EquipmentEnhancer.effective_accessory_int_bonus(item, field_pair[0], acc_data)
				var enh_lv: int = _EquipmentEnhancer.get_enhance_level(item)
				if enh_lv >= _EquipmentEnhancer.MAX_FORGE_LEVEL:
					_add_stat_row(field_pair[1], "%d（上限）" % now, field_pair[2])
				else:
					_add_stat_row(field_pair[1], "%d → %d" % [now, now + forge_flat], field_pair[2])


func _populate_reforge_mod_rows(item: Resource) -> void:
	if item == null:
		return
	if _category != "weapon" and _category != "armor" and _category != "accessory":
		return
	var mods: Array = _EquipmentRandomMods.get_mods(item)
	if mods.is_empty():
		_selected_reforge_mod_index = -1
		return
	## 未選択なら焼直し可能な先頭枠を自動選択（ボタンが常時グレーになるのを防ぐ）。
	if _selected_reforge_mod_index < 0 or _selected_reforge_mod_index >= mods.size():
		_selected_reforge_mod_index = _first_reforgeable_mod_index(mods)
	elif not (
		mods[_selected_reforge_mod_index] is Dictionary
		and _EquipmentReforgeHelper.is_mod_reforgeable(mods[_selected_reforge_mod_index] as Dictionary)
	):
		_selected_reforge_mod_index = _first_reforgeable_mod_index(mods)
	var header := Label.new()
	header.text = "ランダム効果（タップで焼直し対象を変更）"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_caption(header, COLOR_SUB_STRONG)
	header.add_theme_font_size_override("font_size", 14)
	_stats_grid.add_child(header)
	for i: int in mods.size():
		if not mods[i] is Dictionary:
			continue
		var mod: Dictionary = mods[i] as Dictionary
		_stats_grid.add_child(_make_reforge_mod_row(mod, i))


func _first_reforgeable_mod_index(mods: Array) -> int:
	for i: int in mods.size():
		if mods[i] is Dictionary and _EquipmentReforgeHelper.is_mod_reforgeable(mods[i] as Dictionary):
			return i
	return -1


func _make_reforge_mod_row(mod: Dictionary, mod_index: int) -> Control:
	var can_pick: bool = _EquipmentReforgeHelper.is_mod_reforgeable(mod)
	var selected: bool = can_pick and mod_index == _selected_reforge_mod_index
	var line: String = _EquipmentRandomMods.format_mod_line(mod)
	if not can_pick:
		line = "%s（固定）" % line
	## Button の pressed の方が ScrollTouch 下でも安定（gui_input だけだと選択できないことがある）。
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 44)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.text = ("▶ " if selected else "　") + line
	btn.clip_text = false
	btn.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_theme_font_size_override("font_size", _DETAIL_STAT_FONT_PX)
	btn.set_meta(&"_cf_keep_mouse_stop", true)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.disabled = not can_pick
	var sb_n := StyleBoxFlat.new()
	sb_n.set_content_margin_all(8.0)
	sb_n.set_corner_radius_all(6)
	var sb_h := sb_n.duplicate() as StyleBoxFlat
	var sb_p := sb_n.duplicate() as StyleBoxFlat
	var sb_d := sb_n.duplicate() as StyleBoxFlat
	if selected:
		sb_n.bg_color = Color(0.42, 0.32, 0.08, 0.55)
		sb_n.set_border_width_all(2)
		sb_n.border_color = Color(0.95, 0.82, 0.38, 1.0)
	elif can_pick:
		sb_n.bg_color = Color(0.12, 0.11, 0.09, 0.75)
		sb_n.set_border_width_all(1)
		sb_n.border_color = Color(0.55, 0.45, 0.18, 0.55)
	else:
		sb_n.bg_color = Color(0.08, 0.08, 0.1, 0.55)
		sb_n.set_border_width_all(1)
		sb_n.border_color = Color(0.35, 0.32, 0.28, 0.45)
	sb_h.bg_color = Color(0.32, 0.26, 0.12, 0.7)
	sb_h.set_border_width_all(1)
	sb_h.border_color = Color(0.85, 0.72, 0.28, 0.9)
	sb_p.bg_color = Color(0.42, 0.32, 0.08, 0.65)
	sb_p.set_border_width_all(2)
	sb_p.border_color = Color(0.95, 0.82, 0.38, 1.0)
	sb_d.bg_color = Color(0.08, 0.08, 0.1, 0.45)
	sb_d.set_border_width_all(1)
	sb_d.border_color = Color(0.3, 0.28, 0.26, 0.4)
	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", sb_h if can_pick else sb_d)
	btn.add_theme_stylebox_override("pressed", sb_p if can_pick else sb_d)
	btn.add_theme_stylebox_override("disabled", sb_d)
	btn.add_theme_color_override(
		"font_color", COLOR_TEXT_STRONG if can_pick else COLOR_SUB
	)
	btn.add_theme_color_override("font_disabled_color", COLOR_SUB)
	if can_pick:
		btn.pressed.connect(_on_reforge_mod_pressed.bind(mod_index))
	return btn


func _on_reforge_mod_pressed(mod_index: int) -> void:
	if _selected_reforge_mod_index == mod_index:
		return
	_selected_reforge_mod_index = mod_index
	## pressed 中に StatsGrid を free すると発信元 Button ごと破棄され Abort する。
	call_deferred("_refresh_selection")


func _update_reforge_action(item: Resource, forge_at_max: bool) -> void:
	if _reforge_button == null:
		return
	if _category != "weapon" and _category != "armor" and _category != "accessory":
		_reforge_button.visible = false
		if forge_at_max:
			_cost_panel.visible = false
		return
	if item == null:
		_reforge_button.visible = false
		if forge_at_max:
			_cost_panel.visible = false
		return
	_reforge_button.visible = true
	_reforge_button.text = "焼直し"
	var check: Dictionary = _EquipmentReforgeHelper.can_reforge(item, _selected_reforge_mod_index)
	var can_do: bool = bool(check.get("ok", false))
	_reforge_button.disabled = not can_do
	## 焼直し不可理由を明示（常時グレーで理由不明を防ぐ）。炉研ぎ失敗理由より優先。
	if not can_do:
		var reason: String = str(check.get("reason", ""))
		if reason.is_empty():
			reason = "焼直しできません"
		_reason_label.text = reason
		_reason_label.visible = true
	elif not forge_at_max:
		## 炉研ぎ側が理由を出していないときだけ消す（両方OKなら非表示）。
		pass
	else:
		_reason_label.visible = false
	if forge_at_max:
		## +5 時は焼直しコストを詳細に出す（炉研ぎコストは無し）。
		var rarity: int = _EquipmentEnhancer.item_rarity(item)
		var gold_cost: int = int(check.get("gold_cost", _EquipmentReforgeHelper.get_gold_cost(rarity)))
		var materials: Dictionary = check.get(
			"materials", _EquipmentReforgeHelper.get_material_cost(rarity)
		)
		if _selected_reforge_mod_index >= 0:
			_update_cost_panel(gold_cost, materials)
			_cost_panel.visible = true
		else:
			_cost_panel.visible = false
	## 詳細内に増やした効果 Button も STOP 維持。
	_restore_primary_button_input()


func _rebuild_dismantle_detail() -> void:
	if _selected_dismantle_item == null:
		_set_detail_empty("%sを選択してください" % BlacksmithUiHelper.category_label(_category))
		return
	var item: Resource = _selected_dismantle_item
	var preview: Dictionary = _EquipmentEnhancer.dismantle_preview(item)
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	_update_hero_icon(_item_id_for_category(item, _category), _category, rarity)
	_title_label.text = _EquipmentEnhancer.get_display_name(item)
	_title_label.add_theme_color_override("font_color", BlacksmithUiHelper.rarity_name_color(rarity))
	_subtitle_label.text = "分解すると以下の素材を獲得"
	_populate_dismantle_yield(preview.get("materials", {}))
	var can_do: bool = bool(preview.get("ok", false))
	_cost_panel.visible = false
	_craft_button.visible = true
	_craft_button.text = "分解する"
	_craft_button.disabled = not can_do
	if can_do:
		_reason_label.visible = false
	else:
		_reason_label.text = str(preview.get("reason", ""))
		_reason_label.visible = not _reason_label.text.is_empty()

func _populate_dismantle_yield(materials: Dictionary) -> void:
	if materials.is_empty():
		_add_stat_row("獲得素材", "なし")
		return
	for mat_id in materials:
		var qty: int = int(materials[mat_id])
		if qty <= 0:
			continue
		## 中央寄せ（「基礎鉱 × N」が左枠に貼り付かないように）。
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var key_lbl := Label.new()
		key_lbl.text = DataRegistry.get_material_name(str(mat_id))
		key_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_body(key_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_SUB_STRONG)
		row.add_child(key_lbl)
		var val_lbl := Label.new()
		val_lbl.text = "× %d" % qty
		val_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_body(val_lbl, UiTypography.SIZE_BODY, COLOR_TEXT_STRONG)
		row.add_child(val_lbl)
		_stats_grid.add_child(row)


func _rebuild_alchemy_detail() -> void:
	if _selected_alchemy_base == null:
		_set_detail_empty("主材にする%sを選んでください" % BlacksmithUiHelper.category_label(_category))
		_layout_detail_action_anchor()
		return
	var base: Resource = _selected_alchemy_base
	var rarity: int = _EquipmentEnhancer.item_rarity(base)
	_update_hero_icon(_item_id_for_category(base, _category), _category, rarity)
	_title_label.text = _EquipmentEnhancer.get_display_name(base)
	_title_label.add_theme_color_override("font_color", BlacksmithUiHelper.rarity_name_color(rarity))
	_subtitle_label.text = "「錬成する」で素材装備を選びます"
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_label.clip_text = false
	_subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(_subtitle_label, COLOR_SUB_STRONG)
	_subtitle_label.add_theme_font_size_override("font_size", 12)
	_add_stat_row("現在レベル", "Lv.%d" % _EquipmentEnhancer.get_equip_level(base))
	_cost_panel.visible = false
	_craft_button.visible = true
	_craft_button.text = "錬成する"
	var fodders: Array = _sorted_alchemy_fodder_candidates()
	_craft_button.disabled = fodders.is_empty()
	if fodders.is_empty():
		_reason_label.text = "消費できる同種装備がありません"
		_reason_label.visible = true
	else:
		_reason_label.text = "素材候補 %d 件" % _alchemy_fodder_grouped_rows().size()
		_reason_label.visible = true
	_layout_detail_action_anchor()


func _layout_detail_action_anchor() -> void:
	## 錬成でコスト帯が空のとき、ボタン／ヒントを詳細枠下寄りへ押し下げる。
	## 生産は下帯（作成可能）があるため、余白を詰めてボタンを枠内に残す。
	## DetailScroll 導入後は EXPAND で無限伸長しない（スクロールで足りる）。
	if _cost_button_gap == null:
		return
	var push_down: bool = _mode == "alchemy" and not _cost_panel.visible
	if push_down:
		_cost_button_gap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_cost_button_gap.custom_minimum_size = Vector2(0, 24)
		if _craft_button_bottom_pad != null:
			_craft_button_bottom_pad.custom_minimum_size = Vector2(0, 12)
	elif _mode == "produce":
		_cost_button_gap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_cost_button_gap.custom_minimum_size = Vector2(0, 6)
		if _craft_button_bottom_pad != null:
			_craft_button_bottom_pad.custom_minimum_size = Vector2(0, 4)
	else:
		_cost_button_gap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_cost_button_gap.custom_minimum_size = Vector2(0, 14)
		if _craft_button_bottom_pad != null:
			_craft_button_bottom_pad.custom_minimum_size = Vector2(0, 10)


func _format_material_summary(materials: Dictionary) -> String:
	var parts: PackedStringArray = []
	for mat_id in materials:
		var qty: int = int(materials[mat_id])
		if qty <= 0:
			continue
		parts.append("%s×%d" % [DataRegistry.get_material_name(str(mat_id)), qty])
	return " / ".join(parts) if not parts.is_empty() else "なし"

func _on_craft_button_pressed() -> void:
	if _craft_button != null and _craft_button.disabled:
		return
	if _mode == "produce" and _selected_craft != null:
		_on_craft_pressed(_selected_craft)
	elif _mode == "enhance" and _selected_enhance_item != null:
		_on_enhance_pressed()
	elif _mode == "alchemy" and _selected_alchemy_base != null:
		_open_alchemy_fodder_picker()
	elif _mode == "dismantle" and _selected_dismantle_item != null:
		_on_dismantle_pressed()


func _open_alchemy_fodder_picker() -> void:
	if _selected_alchemy_base == null:
		return
	_setup_alchemy_fodder_popup()
	if _alchemy_fodder_overlay == null or _alchemy_fodder_list == null:
		return
	for child in _alchemy_fodder_list.get_children():
		child.queue_free()
	var rows: Array = _alchemy_fodder_grouped_rows()
	if rows.is_empty():
		var empty := Label.new()
		empty.text = "（消費できる同種装備がありません）"
		UiTypography.apply_caption(empty, COLOR_SUB_STRONG)
		_alchemy_fodder_list.add_child(empty)
	else:
		var index: int = 1
		for row_data in rows:
			var sample: Resource = row_data.get("sample") as Resource
			var display_name: String = str(row_data.get("display_name", ""))
			var count: int = int(row_data.get("count", 0))
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 52)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.text = "%d  %s　　所持 %d" % [index, display_name, count]
			btn.clip_text = false
			btn.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			btn.add_theme_font_size_override("font_size", 18)
			## ScrollTouch の PASS 化後もタップ確定できるよう STOP を明示。
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			btn.pressed.connect(_on_alchemy_fodder_row_pressed.bind(sample))
			_alchemy_fodder_list.add_child(btn)
			index += 1
	_alchemy_fodder_overlay.visible = true
	## 一覧追加後に ScrollTouch が PASS に戻すので、次フレームで STOP を復元。
	call_deferred("_restore_alchemy_fodder_row_input")


func _restore_alchemy_fodder_row_input() -> void:
	if _alchemy_fodder_list == null:
		return
	for child in _alchemy_fodder_list.get_children():
		if child is BaseButton:
			(child as BaseButton).mouse_filter = Control.MOUSE_FILTER_STOP


func _alchemy_fodder_grouped_rows() -> Array:
	## 同一テンプレIDをまとめて所持数表示。サンプルはレベル高い個体。
	var groups: Dictionary = {}
	for item in _sorted_alchemy_fodder_candidates():
		if item == null:
			continue
		var item_id: String = _item_id_for_category(item, _category)
		if item_id.is_empty():
			continue
		if not groups.has(item_id):
			groups[item_id] = {
				"item_id": item_id,
				"display_name": _EquipmentEnhancer.get_display_name(item),
				"count": 1,
				"sample": item,
			}
		else:
			var row: Dictionary = groups[item_id]
			row["count"] = int(row.get("count", 0)) + 1
			var sample: Resource = row.get("sample") as Resource
			if _EquipmentEnhancer.get_equip_level(item) > _EquipmentEnhancer.get_equip_level(sample):
				row["sample"] = item
			groups[item_id] = row
	var out: Array = []
	for key in groups.keys():
		out.append(groups[key])
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", "")) < str(b.get("display_name", ""))
	)
	return out


func _on_alchemy_fodder_row_pressed(fodder: Resource) -> void:
	if fodder == null or _selected_alchemy_base == null:
		return
	if _alchemy_fodder_overlay != null and _alchemy_fodder_overlay.visible:
		_alchemy_fodder_overlay.visible = false
	_pending_alchemy_fodder = fodder
	_selected_alchemy_fodder = fodder
	_show_alchemy_fodder_confirm(fodder)


func _show_alchemy_fodder_confirm(fodder: Resource) -> void:
	if _selected_alchemy_base == null or fodder == null or _alchemy_confirm == null:
		return
	var preview: Dictionary = _EquipmentEnhancer.alchemy_preview(_selected_alchemy_base, fodder)
	if not bool(preview.get("ok", false)):
		_log_craft_error(str(preview.get("reason", "錬成できません")))
		_pending_alchemy_fodder = null
		_selected_alchemy_fodder = null
		return
	var lines: PackedStringArray = PackedStringArray()
	lines.append("素材にしてよろしいですか？")
	lines.append("")
	lines.append("【素材】%s" % _EquipmentEnhancer.get_display_name(fodder))
	for stat_line: String in _alchemy_item_stat_lines(fodder):
		lines.append(stat_line)
	lines.append("")
	lines.append("【主材】%s" % _EquipmentEnhancer.get_display_name(_selected_alchemy_base))
	lines.append(
		"結果 Lv.%d → Lv.%d（Gold %d）"
		% [
			int(preview.get("from_level", 1)),
			int(preview.get("to_level", 1)),
			int(preview.get("gold_cost", 0)),
		]
	)
	lines.append("素材は消滅します（分解報酬なし）。")
	_alchemy_confirm.dialog_text = "\n".join(lines)
	_alchemy_confirm.popup_centered()


func _alchemy_item_stat_lines(item: Resource) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if item == null:
		return lines
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	lines.append(
		"Lv.%d　%s"
		% [_EquipmentEnhancer.get_equip_level(item), BlacksmithUiHelper.rarity_short_label(rarity)]
	)
	match _EquipmentEnhancer.item_category(item):
		"weapon":
			lines.append("攻撃力 %d" % _EquipmentEnhancer.get_effective_attack(item))
			var wd: Resource = DataRegistry.get_weapon_data(str(item.weapon_id))
			if wd != null:
				lines.append("会心率 %.0f%%" % (float(wd.base_critical_rate) * 100.0))
		"armor":
			lines.append("防御力 %d" % _EquipmentEnhancer.effective_armor_defense(item))
			lines.append("HP +%d" % _EquipmentEnhancer.effective_armor_hp(item))
		"accessory":
			var ac: Resource = DataRegistry.get_accessory_data(str(item.accessory_id))
			var hp: int = _EquipmentEnhancer.effective_accessory_int_bonus(item, "hp_bonus", ac)
			var atk: int = _EquipmentEnhancer.effective_accessory_int_bonus(item, "attack_bonus", ac)
			if hp > 0:
				lines.append("HP +%d" % hp)
			if atk > 0:
				lines.append("攻撃力 +%d" % atk)
	var enhance_lv: int = _EquipmentEnhancer.get_enhance_level(item)
	if enhance_lv > 0:
		lines.append("炉研ぎ +%d" % enhance_lv)
	return lines


func _on_alchemy_pressed() -> void:
	## 旧フロー互換。主ボタンは素材ピッカーを開く。
	_open_alchemy_fodder_picker()


func _execute_alchemy() -> void:
	var fodder: Resource = _pending_alchemy_fodder
	if fodder == null:
		fodder = _selected_alchemy_fodder
	if _selected_alchemy_base == null or fodder == null:
		return
	var base: Resource = _selected_alchemy_base
	var forge_before: Dictionary = EquipmentItemDetailHelper.forge_stat_snapshot(base, _category)
	var result: Dictionary = _EquipmentEnhancer.perform_alchemy(base, fodder)
	_pending_alchemy_fodder = null
	if not bool(result.get("ok", false)):
		_log_craft_error(str(result.get("reason", "錬成に失敗しました")))
		return
	_log_craft(
		"錬成成功: Lv.%d → Lv.%d（Gold %d）"
		% [int(result.get("from_level", 1)), int(result.get("to_level", 1)), int(result.get("gold_cost", 0))]
	)
	DailyMissionSystem.report_progress("alchemy_item")
	_selected_alchemy_fodder = null
	SaveManager.save_game()
	_show_forge_item_result("錬成完了", base, _category, "alchemy", forge_before)
	_refresh_all()
	_play_forge_success_feedback(FORGE_FLASH_ALCHEMY)

func _rebuild_craftable_strip() -> void:
	_craftable_header.text = "作成可能"
	for child in _craftable_row.get_children():
		child.queue_free()
	var recipes: Array = CraftHelper.get_craftable_recipes()
	if recipes.is_empty():
		var empty := Label.new()
		empty.text = "（作成可能なレシピはありません）"
		empty.add_theme_color_override("font_color", COLOR_SUB_STRONG)
		_craftable_row.add_child(empty)
		call_deferred("_enable_forge_scroll_touch")
		return
	for craft in recipes:
		_craftable_row.add_child(_make_craftable_chip(craft))
	call_deferred("_enable_forge_scroll_touch")


func _rebuild_alchemy_fodder_strip() -> void:
	_craftable_header.text = "素材にする装備"
	for child in _craftable_row.get_children():
		child.queue_free()
	if _selected_alchemy_base == null:
		var empty := Label.new()
		empty.text = "（まず左側で主材を選んでください）"
		empty.add_theme_color_override("font_color", COLOR_SUB_STRONG)
		_craftable_row.add_child(empty)
		call_deferred("_enable_forge_scroll_touch")
		return
	var fodders: Array = _sorted_alchemy_fodder_candidates()
	if fodders.is_empty():
		var empty2 := Label.new()
		empty2.text = "（消費できる同種装備がありません）"
		empty2.add_theme_color_override("font_color", COLOR_SUB_STRONG)
		_craftable_row.add_child(empty2)
		_selected_alchemy_fodder = null
		call_deferred("_enable_forge_scroll_touch")
		return
	if _selected_alchemy_fodder != null and _selected_alchemy_fodder not in fodders:
		_selected_alchemy_fodder = null
	for item in fodders:
		_craftable_row.add_child(_make_alchemy_fodder_chip(item))
	call_deferred("_enable_forge_scroll_touch")


func _make_alchemy_fodder_chip(item: Resource) -> Control:
	var selected: bool = item == _selected_alchemy_fodder
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	var item_id: String = _item_id_for_category(item, _category)
	var display_name: String = _EquipmentEnhancer.get_display_name(item)
	## 外枠帯は無し。装備アイコン枠（レア枠）は残す。名前は長押し。
	var cell_px: int = BlacksmithUiHelper.list_cell_px()
	var host := Control.new()
	host.custom_minimum_size = Vector2(cell_px, cell_px)
	host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.mouse_filter = Control.MOUSE_FILTER_PASS
	host.clip_contents = true
	host.tooltip_text = display_name
	host.gui_input.connect(_on_alchemy_fodder_chip_input.bind(item))
	var cell: Control = BlacksmithUiHelper.make_item_icon_cell(
		item_id, _category, rarity, cell_px, selected, item
	)
	_set_mouse_filter_tree(cell, Control.MOUSE_FILTER_IGNORE)
	cell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(cell)
	return host


func _on_alchemy_fodder_chip_input(event: InputEvent, item: Resource) -> void:
	if _fodder_pointer_down and _should_cancel_fodder_press_for_move(event):
		_cancel_fodder_press()
		return
	if not _is_fodder_pointer_event(event):
		return
	if event.pressed:
		_fodder_press_origin = _fodder_event_position(event)
		_begin_fodder_press(item)
	else:
		_end_fodder_press()
	## accept_event しない（横スクロールを奪わない）。


func _is_fodder_pointer_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return true
	return false


func _fodder_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).position
	return Vector2.ZERO


func _should_cancel_fodder_press_for_move(event: InputEvent) -> bool:
	if event is InputEventScreenDrag:
		return (
			_fodder_press_origin.distance_to((event as InputEventScreenDrag).position)
			>= FODDER_PRESS_MOVE_CANCEL_PX
		)
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return false
		return _fodder_press_origin.distance_to(motion.position) >= FODDER_PRESS_MOVE_CANCEL_PX
	return false


func _begin_fodder_press(item: Resource) -> void:
	_cancel_fodder_press()
	_fodder_pointer_down = true
	_fodder_long_press_fired = false
	_fodder_press_item = item
	_fodder_press_timer = get_tree().create_timer(FODDER_LONG_PRESS_SEC)
	_fodder_press_timer.timeout.connect(_on_fodder_long_press_timeout)


func _on_fodder_long_press_timeout() -> void:
	if not _fodder_pointer_down or _fodder_press_item == null:
		return
	_fodder_long_press_fired = true
	_show_fodder_name(_fodder_press_item)


func _end_fodder_press() -> void:
	if not _fodder_pointer_down:
		return
	_fodder_pointer_down = false
	_cancel_fodder_press_timer_only()
	if not _fodder_long_press_fired and _fodder_press_item != null:
		_selected_alchemy_fodder = _fodder_press_item
		_refresh_all()
	_fodder_press_item = null


func _cancel_fodder_press_timer_only() -> void:
	if _fodder_press_timer != null:
		if _fodder_press_timer.timeout.is_connected(_on_fodder_long_press_timeout):
			_fodder_press_timer.timeout.disconnect(_on_fodder_long_press_timeout)
		_fodder_press_timer = null


func _cancel_fodder_press() -> void:
	_fodder_pointer_down = false
	_cancel_fodder_press_timer_only()
	_fodder_press_item = null
	_fodder_long_press_fired = false


func _show_fodder_name(item: Resource) -> void:
	if item == null:
		return
	_show_name_toast(_EquipmentEnhancer.get_display_name(item))


## 鍛冶画面下部に名前トースト（錬成素材・コスト素材の長押し共通）。
func _show_name_toast(name_text: String) -> void:
	if name_text.is_empty() or _label_status == null:
		return
	_label_status.text = name_text
	_label_status.visible = true
	_label_status.z_index = 40
	_label_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_label_status.offset_left = 16.0
	_label_status.offset_right = -16.0
	_label_status.offset_top = -210.0
	_label_status.offset_bottom = -168.0
	UiTypography.apply_body(_label_status, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	_label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tw: Tween = create_tween()
	tw.tween_interval(1.6)
	tw.tween_callback(func() -> void:
		if _label_status != null and _label_status.text == name_text:
			_label_status.visible = false
	)

func _make_selectable_list_icon(
	item_id: String,
	category: String,
	rarity: int = 0,
	highlight: bool = false,
	item: Resource = null
) -> Control:
	## 生産／強化／錬成／分解で共通。二重ホストは作らずセル自体を返す。
	var cell: Control = BlacksmithUiHelper.make_item_icon_cell(
		item_id, category, rarity, BlacksmithUiHelper.list_icon_px(), highlight, item
	)
	_set_mouse_filter_tree(cell, Control.MOUSE_FILTER_IGNORE)
	return cell

func _set_mouse_filter_tree(node: Node, filter: Control.MouseFilter) -> void:
	if node is Control:
		(node as Control).mouse_filter = filter
	for child in node.get_children():
		_set_mouse_filter_tree(child, filter)

func _make_craftable_chip(craft: Resource) -> PanelContainer:
	var selected: bool = craft == _selected_craft
	var panel := PanelContainer.new()
	## PASS にして横スクロールを親 ScrollContainer に渡す。
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.custom_minimum_size = Vector2(
		BlacksmithUiHelper.CRAFTABLE_CHIP_WIDTH,
		BlacksmithUiHelper.CRAFTABLE_CHIP_HEIGHT
	)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.craftable_strip_style(selected))
	panel.gui_input.connect(_on_craftable_chip_input.bind(craft))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(col)
	var icon_wrap := CenterContainer.new()
	var cell_px: int = BlacksmithUiHelper.list_cell_px()
	icon_wrap.custom_minimum_size = Vector2(cell_px, cell_px)
	icon_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(icon_wrap)
	var chip_rarity: int = BlacksmithUiHelper.output_rarity(craft)
	var cell: Control = BlacksmithUiHelper.make_item_icon_cell(
		str(craft.output_id), str(craft.output_type), chip_rarity, cell_px, selected
	)
	_set_mouse_filter_tree(cell, Control.MOUSE_FILTER_IGNORE)
	icon_wrap.add_child(cell)
	var can_make: bool = CraftHelper.can_craft(craft)
	var name_lbl := Label.new()
	name_lbl.text = BlacksmithUiHelper.output_display_name(craft)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_lbl.max_lines_visible = 1
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_col: Color = BlacksmithUiHelper.rarity_name_color(chip_rarity)
	if not can_make:
		name_col = name_col.darkened(0.25)
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY_SMALL, name_col)
	col.add_child(name_lbl)
	return panel

func _on_craftable_chip_input(event: InputEvent, craft: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cat: String = str(craft.output_type)
		if _category != cat:
			_category = cat
			_update_category_styles()
		_selected_craft = craft
		_refresh_all()

func _make_material_req_cell(mat_id: String, needed: int) -> Control:
	var owned: int = GameState.get_material_quantity(mat_id)
	var ok: bool = owned >= needed
	var mat_name: String = DataRegistry.get_material_name(mat_id)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	## 名前は常時出さず個数のみ。長押しでトースト（マイページ素材と同方針）。
	col.tooltip_text = "%s\n（長押しで名前）" % mat_name
	col.mouse_filter = Control.MOUSE_FILTER_STOP
	var icon_cell: Control = _MaterialUiTokens.make_icon_cell(mat_id, _COST_MAT_ICON_PX, ok)
	icon_cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	## 子が STOP だと親の長押し gui_input に届かない。
	_set_mouse_filter_tree(icon_cell, Control.MOUSE_FILTER_IGNORE)
	col.add_child(icon_cell)
	var qty := Label.new()
	qty.text = "%d/%d" % [owned, needed]
	qty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(qty, COLOR_OK if ok else COLOR_SHORT)
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(qty)
	col.gui_input.connect(_on_cost_material_gui_input.bind(mat_name))
	return col


func _on_cost_material_gui_input(event: InputEvent, mat_name: String) -> void:
	if _mat_pointer_down and _should_cancel_mat_press_for_move(event):
		_cancel_mat_press()
		return
	if not _is_mat_pointer_event(event):
		return
	if event.pressed:
		_mat_press_origin = _mat_event_position(event)
		_begin_mat_press(mat_name)
	else:
		_end_mat_press()
	## accept_event しない（BodyScroll を奪わない）。


func _is_mat_pointer_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return true
	return false


func _mat_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).position
	return Vector2.ZERO


func _should_cancel_mat_press_for_move(event: InputEvent) -> bool:
	if event is InputEventScreenDrag:
		return (
			_mat_press_origin.distance_to((event as InputEventScreenDrag).position)
			>= MAT_PRESS_MOVE_CANCEL_PX
		)
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return false
		return _mat_press_origin.distance_to(motion.position) >= MAT_PRESS_MOVE_CANCEL_PX
	return false


func _begin_mat_press(mat_name: String) -> void:
	_cancel_mat_press()
	_mat_pointer_down = true
	_mat_long_press_fired = false
	_mat_press_name = mat_name
	_mat_press_timer = get_tree().create_timer(MAT_LONG_PRESS_SEC)
	_mat_press_timer.timeout.connect(_on_mat_long_press_timeout)


func _on_mat_long_press_timeout() -> void:
	if not _mat_pointer_down or _mat_press_name.is_empty():
		return
	_mat_long_press_fired = true
	_show_name_toast(_mat_press_name)


func _end_mat_press() -> void:
	if not _mat_pointer_down:
		return
	_mat_pointer_down = false
	_cancel_mat_press_timer_only()
	_mat_press_name = ""


func _cancel_mat_press_timer_only() -> void:
	if _mat_press_timer != null:
		if _mat_press_timer.timeout.is_connected(_on_mat_long_press_timeout):
			_mat_press_timer.timeout.disconnect(_on_mat_long_press_timeout)
		_mat_press_timer = null


func _cancel_mat_press() -> void:
	_mat_pointer_down = false
	_mat_long_press_fired = false
	_cancel_mat_press_timer_only()
	_mat_press_name = ""

func _sorted_enhance_candidates() -> Array:
	var items: Array = []
	for item in _inventory_for_category(_category):
		if item == null or not bool(item.is_appraised):
			continue
		items.append(item)
	items.sort_custom(func(a: Resource, b: Resource) -> bool:
		return BlacksmithUiHelper.enhance_list_sort_before(
			a, b, _is_item_equipped(a), _is_item_equipped(b), _category
		)
	)
	return items


func _sorted_dismantle_candidates() -> Array:
	var items: Array = []
	for item in _inventory_for_category(_category):
		if bool(_EquipmentEnhancer.can_dismantle_item(item).get("ok", false)):
			items.append(item)
	items.sort_custom(func(a: Resource, b: Resource) -> bool:
		return _EquipmentEnhancer.get_display_name(a) < _EquipmentEnhancer.get_display_name(b)
	)
	return items


func _sorted_alchemy_base_candidates() -> Array:
	var items: Array = []
	for item in _inventory_for_category(_category):
		if item == null:
			continue
		if _is_item_equipped(item):
			continue
		if _EquipmentEnhancer.get_equip_level(item) >= _EquipmentEnhancer.EQUIP_MAX_LEVEL:
			continue
		items.append(item)
	items.sort_custom(func(a: Resource, b: Resource) -> bool:
		var la: int = _EquipmentEnhancer.get_equip_level(a)
		var lb: int = _EquipmentEnhancer.get_equip_level(b)
		if la != lb:
			return la > lb
		return _EquipmentEnhancer.get_display_name(a) < _EquipmentEnhancer.get_display_name(b)
	)
	return items


func _sorted_alchemy_fodder_candidates() -> Array:
	var items: Array = []
	if _selected_alchemy_base == null:
		return items
	for item in _inventory_for_category(_category):
		if item == null or item == _selected_alchemy_base:
			continue
		if _is_item_equipped(item):
			continue
		items.append(item)
	items.sort_custom(func(a: Resource, b: Resource) -> bool:
		var la: int = _EquipmentEnhancer.get_equip_level(a)
		var lb: int = _EquipmentEnhancer.get_equip_level(b)
		if la != lb:
			return la > lb
		return _EquipmentEnhancer.get_display_name(a) < _EquipmentEnhancer.get_display_name(b)
	)
	return items

func _inventory_for_category(category: String) -> Array:
	match category:
		"armor":
			return GameState.armor_inventory
		"accessory":
			return GameState.accessory_inventory
		_:
			return GameState.inventory

func _is_item_equipped(item: Resource) -> bool:
	## 編成外ロスターの装着も「装備中」として強化一覧の上に寄せる。
	if item == null:
		return false
	for member: Variant in GameState.roster:
		if member == null:
			continue
		if (
			member.equipped_weapon == item
			or member.equipped_armor == item
			or member.equipped_accessory == item
		):
			return true
	return false

func _update_bulk_dismantle_button() -> void:
	if _bulk_dismantle_btn == null:
		return
	var preview: Dictionary = _EquipmentEnhancer.dismantle_bulk_preview()
	var count: int = int(preview.get("count", 0))
	_bulk_dismantle_btn.disabled = count <= 0
	_bulk_dismantle_btn.text = (
		"N・Rを一括分解（%d件）" % count
		if count > 0
		else "N・Rを一括分解"
	)
	_bulk_dismantle_btn.tooltip_text = _bulk_dismantle_btn.text
	BlacksmithUiHelper.apply_bulk_dismantle_button(_bulk_dismantle_btn)

func _craft_button_label(craft: Resource, can_craft: bool) -> String:
	if can_craft:
		return "生産する"
	var lock_reason: String = CraftHelper.craft_lock_reason(craft)
	if not lock_reason.is_empty():
		return lock_reason
	if GameState.gold < craft.gold_cost:
		return "ゴールド不足"
	return "素材不足"

func _on_craft_pressed(craft: Resource) -> void:
	if craft.output_type != "armor" and craft.output_type != "accessory" and craft.output_type != "weapon":
		_log_craft_error("作成できません（出力不正）")
		return
	if craft.output_id.is_empty() or not CraftHelper.craft_output_exists(craft):
		_log_craft_error("作成できません（出力不正）")
		return
	var lock_reason: String = CraftHelper.craft_lock_reason(craft)
	if not lock_reason.is_empty():
		_log_craft_error(lock_reason)
		return
	if GameState.gold < craft.gold_cost:
		_log_craft_error("ゴールドが足りません")
		return
	if not CraftHelper.has_enough_materials(craft.required_materials):
		_log_craft_error("素材が足りません")
		return
	_pending_craft = craft
	var item_name: String = DataRegistry.get_item_name(craft.output_id, craft.output_type)
	_craft_confirm.dialog_text = (
		"%s を生産しますか？\n（Gold %d）"
		% [item_name, int(craft.gold_cost)]
	)
	_craft_confirm.popup_centered()


func _on_craft_confirmed() -> void:
	var craft: Resource = _pending_craft
	_pending_craft = null
	if craft == null:
		return
	if craft.output_type != "armor" and craft.output_type != "accessory" and craft.output_type != "weapon":
		_log_craft_error("作成できません（出力不正）")
		return
	if craft.output_id.is_empty() or not CraftHelper.craft_output_exists(craft):
		_log_craft_error("作成できません（出力不正）")
		return
	if GameState.gold < craft.gold_cost:
		_log_craft_error("ゴールドが足りません")
		return
	if not CraftHelper.has_enough_materials(craft.required_materials):
		_log_craft_error("素材が足りません")
		return
	GameState.gold -= craft.gold_cost
	GameState.consume_materials(craft.required_materials)
	var crafted: Resource = _generate_craft_output(craft)
	DailyMissionSystem.report_progress("craft_item")
	SaveManager.save_game()
	if crafted != null:
		_show_forge_item_result("生産完了", crafted, craft.output_type, "produce")
	else:
		var item_name: String = DataRegistry.get_item_name(craft.output_id, craft.output_type)
		_show_forge_result("生産完了", "生産しました。\n\n%s" % item_name)
	_refresh_all()
	_play_forge_success_feedback(FORGE_FLASH_CRAFT)

func _on_enhance_pressed() -> void:
	if _selected_enhance_item == null or _enhance_confirm == null:
		return
	var item: Resource = _selected_enhance_item
	var check: Dictionary = _EquipmentEnhancer.can_enhance_item(item)
	if not bool(check.get("ok", false)):
		_log_craft_error(str(check.get("reason", "炉研ぎできません")))
		return
	var level: int = _EquipmentEnhancer.get_enhance_level(item)
	var next_level: int = int(check.get("next_level", level + 1))
	var gold_cost: int = int(check.get("gold_cost", 0))
	var mat_summary: String = _format_material_summary(check.get("materials", {}))
	_enhance_confirm.dialog_text = (
		"「%s」を炉で研ぎますか？\n+%d → +%d\n必要ゴールド: %d\n素材: %s"
		% [
			_EquipmentEnhancer.get_display_name(item),
			level,
			next_level,
			gold_cost,
			mat_summary,
		]
	)
	_enhance_confirm.popup_centered()


func _on_enhance_confirmed() -> void:
	if _selected_enhance_item == null:
		return
	var forge_before: Dictionary = EquipmentItemDetailHelper.forge_stat_snapshot(
		_selected_enhance_item, _category
	)
	var result: Dictionary = _EquipmentEnhancer.enhance_item(_selected_enhance_item)
	if not bool(result.get("ok", false)):
		_log_craft_error(str(result.get("reason", "炉研ぎに失敗しました")))
		_refresh_all()
		return
	DailyMissionSystem.report_progress("enhance_item")
	SaveManager.save_game()
	_show_forge_item_result(
		"強化完了", _selected_enhance_item, _category, "enhance", forge_before
	)
	_refresh_all()
	_play_forge_success_feedback(FORGE_FLASH_ENHANCE)


func _on_reforge_pressed() -> void:
	if _selected_enhance_item == null or _reforge_confirm == null:
		return
	var item: Resource = _selected_enhance_item
	var check: Dictionary = _EquipmentReforgeHelper.can_reforge(item, _selected_reforge_mod_index)
	if not bool(check.get("ok", false)):
		_log_craft_error(str(check.get("reason", "焼直しできません")))
		return
	var mods: Array = _EquipmentRandomMods.get_mods(item)
	var mod_line: String = ""
	if _selected_reforge_mod_index >= 0 and _selected_reforge_mod_index < mods.size():
		if mods[_selected_reforge_mod_index] is Dictionary:
			mod_line = _EquipmentRandomMods.format_mod_line(
				mods[_selected_reforge_mod_index] as Dictionary
			)
	var gold_cost: int = int(check.get("gold_cost", 0))
	var mat_summary: String = _format_material_summary(check.get("materials", {}))
	_reforge_confirm.dialog_text = (
		"「%s」の効果を焼直しますか？\n%s\n必要ゴールド: %d\n素材: %s"
		% [
			_EquipmentEnhancer.get_display_name(item),
			mod_line,
			gold_cost,
			mat_summary,
		]
	)
	_reforge_confirm.popup_centered()


func _on_reforge_confirmed() -> void:
	if _selected_enhance_item == null:
		return
	var forge_before: Dictionary = EquipmentItemDetailHelper.forge_stat_snapshot(
		_selected_enhance_item, _category
	)
	var mod_index: int = _selected_reforge_mod_index
	var result: Dictionary = _EquipmentReforgeHelper.reforge_mod(
		_selected_enhance_item, mod_index
	)
	if not bool(result.get("ok", false)):
		_log_craft_error(str(result.get("reason", "焼直しに失敗しました")))
		_refresh_all()
		return
	var extra: Dictionary = {
		"reforge_mod_index": mod_index,
	}
	SaveManager.save_game()
	_show_forge_item_result(
		"焼直し完了", _selected_enhance_item, _category, "enhance", forge_before, extra
	)
	_refresh_all()
	_play_forge_success_feedback(FORGE_FLASH_ENHANCE)

func _on_dismantle_pressed() -> void:
	if _selected_dismantle_item == null:
		return
	var item: Resource = _selected_dismantle_item
	## 確認文の素材は dismantle_preview（can_dismantle には materials が無い）。
	var preview: Dictionary = _EquipmentEnhancer.dismantle_preview(item)
	if not bool(preview.get("ok", false)):
		_log_craft_error(str(preview.get("reason", "分解できません")))
		return
	var mat_summary: String = _format_material_summary(preview.get("materials", {}))
	if mat_summary.is_empty():
		mat_summary = "（素材なし）"
	if _EquipmentEnhancer.item_rarity(item) >= Enums.Rarity.LEGENDARY:
		_pending_dismantle_item = item
		_legendary_dismantle_confirm.dialog_text = (
			"L装備「%s」を分解します。\n獲得: %s\n本当によろしいですか？（1/2）"
			% [_EquipmentEnhancer.get_display_name(item), mat_summary]
		)
		_legendary_dismantle_confirm.popup_centered()
		return
	_pending_dismantle_item = item
	_single_dismantle_confirm.dialog_text = (
		"「%s」を分解しますか？\n獲得: %s\n分解すると元に戻せません。"
		% [_EquipmentEnhancer.get_display_name(item), mat_summary]
	)
	_single_dismantle_confirm.popup_centered()


func _on_single_dismantle_confirmed() -> void:
	if _pending_dismantle_item == null:
		return
	var item: Resource = _pending_dismantle_item
	_pending_dismantle_item = null
	_execute_dismantle(item)


func _on_single_dismantle_canceled() -> void:
	_pending_dismantle_item = null
	_on_forge_confirm_canceled()


func _on_legendary_dismantle_step1() -> void:
	if _pending_dismantle_item == null:
		return
	var preview: Dictionary = _EquipmentEnhancer.dismantle_preview(_pending_dismantle_item)
	var mat_summary: String = _format_material_summary(preview.get("materials", {}))
	if mat_summary.is_empty():
		mat_summary = "（素材なし）"
	_legendary_dismantle_final_confirm.dialog_text = (
		"「%s」を分解すると元に戻せません。\n獲得: %s\n最終確認です。（2/2）"
		% [_EquipmentEnhancer.get_display_name(_pending_dismantle_item), mat_summary]
	)
	_legendary_dismantle_final_confirm.popup_centered()

func _on_legendary_dismantle_final() -> void:
	if _pending_dismantle_item == null:
		return
	_execute_dismantle(_pending_dismantle_item)
	_pending_dismantle_item = null

func _execute_dismantle(item: Resource) -> void:
	var result: Dictionary = _EquipmentEnhancer.dismantle_item(item)
	if not bool(result.get("ok", false)):
		_log_craft_error(str(result.get("reason", "分解に失敗しました")))
		_refresh_all()
		return
	DailyMissionSystem.report_progress("dismantle_item")
	SaveManager.save_game()
	_selected_dismantle_item = null
	_selected_enhance_item = null
	var materials: Dictionary = result.get("materials", {})
	_show_forge_dismantle_result(materials)
	_refresh_all()
	_play_forge_success_feedback(FORGE_FLASH_DISMANTLE)

func _on_bulk_dismantle_pressed() -> void:
	var preview: Dictionary = _EquipmentEnhancer.dismantle_bulk_preview()
	var count: int = int(preview.get("count", 0))
	if count <= 0:
		_log_craft_error("分解対象がありません")
		return
	_dismantle_confirm.dialog_text = (
		"N・R装備 %d件を分解します。\n獲得: %s\nよろしいですか？"
		% [count, _format_material_summary(preview.get("materials", {}))]
	)
	_dismantle_confirm.popup_centered()

func _on_bulk_dismantle_confirmed() -> void:
	var result: Dictionary = _EquipmentEnhancer.dismantle_bulk_common_rare()
	if not bool(result.get("ok", false)):
		_log_craft_error(str(result.get("reason", "一括分解に失敗しました")))
		_refresh_all()
		return
	var dismantled: int = maxi(1, int(result.get("count", 0)))
	DailyMissionSystem.report_progress("dismantle_item", "", dismantled)
	SaveManager.save_game()
	_selected_dismantle_item = null
	var materials: Dictionary = result.get("materials", {})
	_show_forge_dismantle_result(
		materials,
		"N・R装備 %d件を分解しました。" % int(result.get("count", 0))
	)
	_refresh_all()
	_play_forge_success_feedback(FORGE_FLASH_DISMANTLE)

func _auto_appraise(instance: Resource, category: String, rarity: int) -> void:
	## P3-EQ-DIABLO-001: Affix 抽選は apply_drop_stats → EquipmentRandomMods に統合済。
	if instance != null:
		instance.is_appraised = true
	return

func _generate_craft_output(craft: Resource) -> Resource:
	if craft.output_type == "armor":
		return _spawn_armor(craft.output_id)
	if craft.output_type == "accessory":
		return _spawn_accessory(craft.output_id)
	if craft.output_type == "weapon":
		return _spawn_weapon(craft.output_id)
	return null

func _spawn_weapon(weapon_id: String) -> Resource:
	var weapon_data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if weapon_data == null:
		return null
	var instance := WeaponInstance.new()
	instance.instance_id = str(Time.get_ticks_msec()) + "_craft_" + str(randi() % 100000)
	instance.weapon_id = weapon_id
	_WeaponStatResolver.apply_drop_stats(instance, weapon_data)
	_auto_appraise(instance, _AffixRoller.CATEGORY_WEAPON, weapon_data.rarity)
	GameState.inventory.append(instance)
	GameState.note_equipment_obtained(instance)
	return instance

func _spawn_armor(armor_id: String) -> Resource:
	var armor_data: Resource = DataRegistry.get_armor_data(armor_id)
	if armor_data == null:
		return null
	var instance := ArmorInstance.new()
	instance.instance_id = str(Time.get_ticks_msec()) + "_craft_" + str(randi() % 100000)
	instance.armor_id = armor_id
	_ArmorStatResolver.apply_drop_stats(instance, armor_data)
	instance.rarity = armor_data.rarity
	_auto_appraise(instance, _AffixRoller.CATEGORY_ARMOR, armor_data.rarity)
	GameState.armor_inventory.append(instance)
	GameState.note_equipment_obtained(instance)
	return instance

func _spawn_accessory(accessory_id: String) -> Resource:
	var accessory_data: Resource = DataRegistry.get_accessory_data(accessory_id)
	if accessory_data == null:
		return null
	var instance := AccessoryInstance.new()
	instance.instance_id = str(Time.get_ticks_msec()) + "_craft_" + str(randi() % 100000)
	instance.accessory_id = accessory_id
	_AccessoryStatResolver.apply_drop_stats(instance, accessory_data)
	_auto_appraise(instance, _AffixRoller.CATEGORY_ACCESSORY, accessory_data.rarity)
	GameState.accessory_inventory.append(instance)
	GameState.note_equipment_obtained(instance)
	return instance

func _log_craft(msg: String) -> void:
	print("[Craft] ", msg)
	_label_status.text = msg
	_label_status.visible = not msg.is_empty()


func _log_craft_error(msg: String) -> void:
	AudioManager.play_sfx("ui_error")
	_log_craft(msg)

func _play_forge_success_feedback(flash_color: Color) -> void:
	AudioManager.play_sfx("forge_action")
	_flash_forge_screen(flash_color)
	_pulse_hero_icon()

func _flash_forge_screen(flash_color: Color) -> void:
	_flash_overlay.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
	var tw := create_tween()
	tw.tween_property(_flash_overlay, "color:a", FORGE_FLASH_PEAK_ALPHA, 0.08)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_flash_overlay, "color:a", 0.0, 0.34)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _pulse_hero_icon() -> void:
	if not _hero_weapon_pivot.visible:
		return
	_hero_weapon_pivot.scale = _hero_pulse_base_scale
	var tw := create_tween()
	tw.tween_property(_hero_weapon_pivot, "scale", _hero_pulse_base_scale * 1.08, 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_hero_weapon_pivot, "scale", _hero_pulse_base_scale, 0.22)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_back_pressed() -> void:
	_go_to(HOME_SCENE)

func _go_to(scene_path: String) -> void:
	SceneRouter.change_scene(scene_path)
