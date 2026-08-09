extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const DUNGEON_SELECT_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _AbyssDungeonConfig = preload("res://scripts/dungeon/AbyssDungeonConfig.gd")
const _EventDungeonTitleHelper = preload("res://scripts/ui/EventDungeonTitleHelper.gd")

const THUMB_SIZE: Vector2 = Vector2(72, 72)
const ENEMY_ICON_PX: int = 26
const DROP_ICON_SIZE: Vector2 = Vector2(24, 24)
const MAX_STARS: int = 3
const DROP_CAPTION: String = "主なドロップ報酬"

const DUNGEON_ICON_PATHS: Dictionary = {
	"mourngate": "res://assets/dungeon/mourngate/ICO_DG_Mourngate.png",
	"astoria_ruins": "res://assets/dungeon/astoria_ruins/ICO_DG_AstoriaRuins.png",
	"whisperwood": "res://assets/dungeon/whisperwood/ICO_DG_Whisperwood.png",
	"green_hollow": "res://assets/dungeon/green_hollow/ICO_DG_GreenHollow.png",
	"mistfen": "res://assets/dungeon/mistfen/ICO_DG_Mistfen.png",
	"broken_marsh": "res://assets/dungeon/broken_marsh/ICO_DG_BrokenMarsh.png",
	"blackshore": "res://assets/dungeon/blackshore/ICO_DG_Blackshore.png",
	"westbay_flats": "res://assets/dungeon/westbay_flats/ICO_DG_WestbayFlats.png",
	"frostridge": "res://assets/dungeon/frostridge/ICO_DG_Frostridge.png",
	"frostwall_path": "res://assets/dungeon/frostwall_path/ICO_DG_FrostwallPath.png",
	"chronos_mausoleum": "res://assets/dungeon/chronos_mausoleum/ICO_DG_ChronosMausoleum.png",
	"valgard_boundary": "res://assets/dungeon/valgard_boundary/ICO_DG_ValgardBoundary.png",
}

const COLOR_GOLD: Color = Color(0.95, 0.84, 0.4, 1)
const COLOR_SUB: Color = Color(0.78, 0.74, 0.6, 1)
const COLOR_CLEAR: Color = Color(0.45, 0.92, 0.55, 1)
## クリア済み／日次挑戦済みバッジ用。ダンジョン名の金と分ける（緑）。
const COLOR_CLEAR_BADGE: Color = COLOR_CLEAR
const COLOR_CLEAR_BADGE_HEX: String = "73eb8c"
const BADGE_CLEAR: String = "CLEAR"
const BADGE_ATTEMPTED: String = "挑戦済み"
## 無限ダンジョンの「最高到達フロア」表示用（赤字）。
const COLOR_ABYSS_BEST_HEX: String = "e0574a"
const COLOR_ABYSS_BEST: Color = Color(0.88, 0.34, 0.29, 1)
const COLOR_TEAL: Color = Color(0.6, 0.82, 0.78, 1)
## イベント名の共通薔薇金（曜日イベント単色・互換エイリアス）。
## 降臨の2色分けは EventDungeonTitleHelper（案B）。
const COLOR_EVENT_TITLE: Color = Color(1.0, 0.74, 0.56, 1.0)
const COLOR_EVENT_TITLE_OUTLINE: Color = Color(0.78, 0.36, 0.18, 1.0)
const EVENT_TITLE_OUTLINE_SIZE: int = 7
const EVENT_TITLE_SHADOW_OUTLINE: int = 8

const ROUTE_TAB_MAIN: String = "main"
const ROUTE_TAB_SUB: String = "sub"
const ROUTE_TAB_EVENT: String = "event"
const ROUTE_TAB_ABYSS: String = "abyss"

const DROP_PREVIEW: Dictionary = {
	"cosmic_rift": [
		["material", "relic_shard"],
	],
	"crown_rookery": [
		["weapon", "stormveil_needle"],
		["weapon", "noctumbra_fang"],
		["weapon", "mistpierce_halberd"],
		["weapon", "shadowcord"],
	],
	"golden_nest": [
		["material", "relic_shard"],
	],
	"rock_stampede": [
		["material", "relic_shard"],
	],
	"shadow_hunt": [
		["weapon", "stormveil_needle"],
		["weapon", "noctumbra_fang"],
		["weapon", "mistpierce_halberd"],
		["weapon", "shadowcord"],
	],
	"mourngate": [
		["weapon", "iron_sword"],
		["armor", "leather_armor"],
		["accessory", "silver_ring"],
		["material", "relic_shard"],
	],
	"astoria_ruins": [
		["weapon", "heater_blade"],
		["armor", "bone_armor"],
		["accessory", "mourngate_sigil"],
		["material", "relic_shard"],
	],
	"whisperwood": [
		["weapon", "pyre_greatsword"],
		["armor", "moss_weave_garb"],
		["accessory", "verdant_ring"],
	],
	"green_hollow": [
		["weapon", "venom_fang_blades"],
		["armor", "mycel_cloak"],
		["accessory", "spore_charm"],
	],
	"mistfen": [
		["weapon", "storm_carver"],
		["armor", "mire_hide_garb"],
		["accessory", "marsh_pearl_ring"],
	],
	"broken_marsh": [
		["weapon", "galvanic_bow"],
		["armor", "bog_strider_cloak"],
		["accessory", "leech_oil_charm"],
	],
	"blackshore": [
		["weapon", "lighthouse_greatsword"],
		["armor", "tidecloth_garb"],
		["accessory", "black_pearl_ring"],
	],
	"westbay_flats": [
		["weapon", "pharos_bow"],
		["armor", "kelp_weave_cloak"],
		["accessory", "barnacle_charm"],
	],
	"frostridge": [
		["weapon", "glacier_greatsword"],
		["armor", "furline_garb"],
		["accessory", "ice_crystal_ring"],
	],
	"frostwall_path": [
		["weapon", "rime_bow"],
		["armor", "snowdrift_cloak"],
		["accessory", "frost_fang_charm"],
	],
	"chronos_mausoleum": [
		["weapon", "chronos_toki_sword"],
		["armor", "chronos_toki_armor"],
		["accessory", "chronos_toki_orb"],
	],
	"valgard_boundary": [
		["weapon", "valgard_antique_blade"],
		["armor", "valgard_antique_armor"],
		["accessory", "valgard_antique_amulet"],
	],
	"red_ridge_mine": [
		["weapon", "symbiont_edge"],
		["armor", "mycel_cloak"],
		["accessory", "granvel_fang_talisman"],
	],
	"mistfen_depths": [
		["weapon", "volgrave_thunderblade"],
		["armor", "chitin_plate"],
		["accessory", "moldgar_eye_talisman"],
	],
	"thunder_peak": [
		["weapon", "thunderfen_edge"],
		["armor", "bog_strider_cloak"],
		["accessory", "leech_oil_charm"],
	],
	"blackshore_abyss": [
		["weapon", "nereidas_tideblade"],
		["armor", "tidecloth_garb"],
		["accessory", "nereion_song_talisman"],
	],
	"red_forge_depths": [
		["weapon", "eldion_frostbrand"],
		["armor", "dragon_scale_aegis"],
		["accessory", "eldion_heart_talisman"],
	],
	"north_reach": [
		["weapon", "umbra_terminus_staff"],
		["armor", "aurora_vestment"],
		["accessory", "eldion_heart_talisman"],
	],
}

@onready var _btn_back: Button = $MainColumn/Header/HeaderRow/ButtonBack
@onready var _btn_tier_normal: Button = $MainColumn/TabsRow/ButtonNormal
@onready var _btn_tier_hard: Button = $MainColumn/TabsRow/ButtonHard
@onready var _btn_tier_nightmare: Button = $MainColumn/TabsRow/ButtonNightmare
@onready var _label_gold: Label = $MainColumn/Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $MainColumn/Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _featured_panel: PanelContainer = $MainColumn/FeaturedPanel
@onready var _featured_vbox: VBoxContainer = $MainColumn/FeaturedPanel/FeaturedVBox
@onready var _featured_banner_host: Control = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedBannerHost
@onready var _label_featured_name: Label = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedInfo/LabelFeaturedName
@onready var _label_featured_flavor: Label = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedInfo/LabelFeaturedFlavor
@onready var _label_featured_meta: Label = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedInfo/LabelFeaturedMeta
@onready var _label_featured_discovery: Label = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedInfo/LabelFeaturedDiscovery
@onready var _featured_drop_row: HBoxContainer = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedDropRow
@onready var _btn_featured_select: Button = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedActionRow/BtnFeaturedSelect
@onready var _label_featured_abyss_best: Label = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedActionRow/LabelFeaturedAbyssBest
@onready var _btn_route_main: Button = $MainColumn/RouteTabsRow/ButtonMainRoute
@onready var _btn_route_sub: Button = $MainColumn/RouteTabsRow/ButtonSubDungeon
@onready var _btn_route_event: Button = $MainColumn/RouteTabsRow/ButtonEventDungeon
@onready var _btn_route_abyss: Button = $MainColumn/RouteTabsRow/ButtonAbyssDungeon
@onready var _scroll_list: ScrollContainer = $MainColumn/ScrollList
@onready var _list: VBoxContainer = $MainColumn/ScrollList/ListVBox
@onready var _footer_panel: PanelContainer = $FooterPanel
@onready var _bonus_col: VBoxContainer = $FooterPanel/FooterRow/BonusCol
@onready var _label_bonus_value: Label = $FooterPanel/FooterRow/BonusCol/LabelBonusValue
@onready var _label_bonus_timer: Label = $FooterPanel/FooterRow/BonusCol/LabelBonusTimer

var _featured_dungeon_id: String = ""
var _selected_stage_id: String = ""
var _expanded_biome_id: String = ""
var _route_tab: String = ROUTE_TAB_MAIN
var _pending_enter_dungeon_id: String = ""
var _enter_confirm_overlay: Control
var _enter_confirm_yes: Button
var _enter_confirm_no: Button
var _party_empty_dialog: AcceptDialog
## Featured 名の2色行（LabelFeaturedName の代替表示）。
var _featured_name_twotone: HBoxContainer = null

const STAGE_CARD_MIN_SIZE: Vector2 = Vector2(136, 78)
const STAGE_THUMB_SIZE: Vector2 = Vector2(44, 44)
const BIOME_HEADER_MIN_SIZE: Vector2 = Vector2(0, 112)
## 一覧アコーディオン上の Biome バナー想定幅（高さはテクスチャ縦横比から算出）
const BIOME_BANNER_LIST_WIDTH: float = 680.0
const BIOME_BANNER_HEIGHT_MIN: float = 112.0
const BIOME_BANNER_HEIGHT_MAX: float = 240.0
const BIOME_BANNER_HEIGHT: float = 112.0
## 空 = バナー画像を使わずテキスト見出し（▶ ダンジョン名）に戻す。
## 雰囲気BGのみ（文字は UI ラベル重ね）。本番バナーは 1408×232（--strip-height 232）。
## パス／フォールバック SSOT: BiomeBannerHelper
const _BiomeBannerHelper = preload("res://scripts/ui/BiomeBannerHelper.gd")
## バナー画像にダンジョン名が焼き込まれている Biome（UI タイトルラベルを非表示）
const BIOME_BANNER_TITLE_BAKED: Dictionary = {}
const _DungeonRouteGuide := preload("res://scripts/ui/DungeonRouteGuideOverlay.gd")

var _guide_help_row: HBoxContainer
var _btn_guide_event: Button
var _btn_guide_descent: Button
var _btn_guide_abyss: Button

func _ready() -> void:
	$MainColumn/Header/HeaderRow/LabelTitle.text = ""
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.ADVENTURE)
	var bg: TextureRect = $BgTexture as TextureRect
	if bg != null:
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_back.pressed.connect(_go_home)
	_btn_featured_select.pressed.connect(_on_featured_select_pressed)
	_btn_tier_normal.pressed.connect(_on_tier_pressed.bind(_DungeonTierConfig.TIER_NORMAL))
	_btn_tier_hard.pressed.connect(_on_tier_pressed.bind(_DungeonTierConfig.TIER_HARD))
	_btn_tier_nightmare.pressed.connect(_on_tier_pressed.bind(_DungeonTierConfig.TIER_NIGHTMARE))
	_btn_route_main.pressed.connect(_on_route_tab_pressed.bind(ROUTE_TAB_MAIN))
	_btn_route_sub.pressed.connect(_on_route_tab_pressed.bind(ROUTE_TAB_SUB))
	_btn_route_event.pressed.connect(_on_route_tab_pressed.bind(ROUTE_TAB_EVENT))
	_btn_route_abyss.pressed.connect(_on_route_tab_pressed.bind(ROUTE_TAB_ABYSS))
	## 寄り道・征討はデータ残置のまま UI から外す（P3-DG-OMIT-001）。
	_btn_route_sub.visible = Constants.SUB_DUNGEONS_PLAYABLE
	_btn_route_abyss.visible = Constants.ABYSS_DUNGEONS_PLAYABLE
	if not Constants.SUB_DUNGEONS_PLAYABLE and _route_tab == ROUTE_TAB_SUB:
		_route_tab = ROUTE_TAB_MAIN
	if EventSystem.PERIODIC_EVENTS_ENABLED and EventSystem.has_signal("event_updated"):
		EventSystem.event_updated.connect(_refresh_event_footer)
	_featured_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	## 横はみ出し防止: 子 Label の自然幅で Featured／画面全体が広がらないよう clip。
	_featured_panel.clip_contents = true
	_featured_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## DISABLED(0) だと子の最小幅に Scroll が追従して画面全体が横に広がる。
	_scroll_list.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll_list.clip_contents = true
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var main_col: Control = $MainColumn as Control
	if main_col != null:
		main_col.clip_contents = true
	_footer_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	_apply_typography()
	_constrain_featured_text_labels()
	_setup_enter_confirm()
	_setup_party_empty_dialog()
	_setup_route_guide_help()
	_refresh_all()
	call_deferred("_maybe_show_content_unlock")


func _maybe_show_content_unlock() -> void:
	const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")
	## 章クリア加入ストーリー中は拠点で功績→解放の順に出す。
	## 完全調査達成も拠点（メインメニュー）まで残す。
	if not GameState.pending_clear_nina_merit:
		_ContentUnlockNotice.show_pending_on_except_hub_deferred(
			self, Callable(self, "_after_unlock_notices_for_guides")
		)
	else:
		call_deferred("_maybe_show_descent_route_guide")


func _after_unlock_notices_for_guides() -> void:
	_maybe_show_descent_route_guide()


func _setup_route_guide_help() -> void:
	var main_col: Node = $MainColumn
	var tabs: Node = $MainColumn/RouteTabsRow
	if main_col == null or tabs == null:
		return
	_guide_help_row = HBoxContainer.new()
	_guide_help_row.name = "RouteGuideHelpRow"
	_guide_help_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_guide_help_row.add_theme_constant_override("separation", 8)
	_guide_help_row.visible = false
	var insert_at: int = tabs.get_index() + 1
	main_col.add_child(_guide_help_row)
	main_col.move_child(_guide_help_row, insert_at)

	_btn_guide_event = _make_route_guide_help_button("イベントとは？")
	_btn_guide_event.pressed.connect(_on_route_guide_help_pressed.bind(_DungeonRouteGuide.GUIDE_EVENT))
	_guide_help_row.add_child(_btn_guide_event)

	_btn_guide_descent = _make_route_guide_help_button("降臨とは？")
	_btn_guide_descent.pressed.connect(
		_on_route_guide_help_pressed.bind(_DungeonRouteGuide.GUIDE_DESCENT)
	)
	_guide_help_row.add_child(_btn_guide_descent)

	_btn_guide_abyss = _make_route_guide_help_button("無限とは？")
	_btn_guide_abyss.pressed.connect(_on_route_guide_help_pressed.bind(_DungeonRouteGuide.GUIDE_ABYSS))
	_guide_help_row.add_child(_btn_guide_abyss)


func _make_route_guide_help_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 40)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_button(btn, false)
	return btn


func _refresh_route_guide_help() -> void:
	if _guide_help_row == null:
		return
	var on_event: bool = _route_tab == ROUTE_TAB_EVENT
	var on_abyss: bool = _route_tab == ROUTE_TAB_ABYSS and Constants.ABYSS_DUNGEONS_PLAYABLE
	_guide_help_row.visible = on_event or on_abyss
	if _btn_guide_event != null:
		_btn_guide_event.visible = on_event
	if _btn_guide_descent != null:
		_btn_guide_descent.visible = on_event
	if _btn_guide_abyss != null:
		_btn_guide_abyss.visible = on_abyss


func _on_route_guide_help_pressed(guide_id: String) -> void:
	## 再表示は preview（自動初回フラグを触らない）。
	_DungeonRouteGuide.show_on(self, guide_id, true)


func _maybe_show_descent_route_guide() -> void:
	if _DungeonRouteGuide.is_seen(_DungeonRouteGuide.GUIDE_DESCENT):
		return
	if get_node_or_null("DungeonRouteGuideOverlay") != null:
		return
	if get_node_or_null("DungeonUnlockOverlay") != null:
		return
	const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
	if _EventDungeonSchedule.open_hourly_event_ids().is_empty():
		return
	_DungeonRouteGuide.show_on(self, _DungeonRouteGuide.GUIDE_DESCENT, false)

func _setup_party_empty_dialog() -> void:
	_party_empty_dialog = AcceptDialog.new()
	_party_empty_dialog.title = "編成が空です"
	_party_empty_dialog.dialog_text = (
		"パーティに冒険者がいません。\n"
		+ "調査室から戻すか、編成画面で仲間を入れてから潜ってください。"
	)
	_party_empty_dialog.ok_button_text = "閉じる"
	add_child(_party_empty_dialog)


func _party_has_adventurer() -> bool:
	for adv in GameState.party_members:
		if adv != null:
			return true
	return false


func _show_party_empty_notice() -> void:
	if _party_empty_dialog == null:
		return
	AudioManager.play_sfx("ui_error")
	_party_empty_dialog.popup_centered()


func _setup_enter_confirm() -> void:
	_enter_confirm_overlay = Control.new()
	_enter_confirm_overlay.name = "EnterConfirmOverlay"
	_enter_confirm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_enter_confirm_overlay.visible = false
	_enter_confirm_overlay.z_index = 80
	_enter_confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_enter_confirm_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_enter_confirm_dim_input)
	_enter_confirm_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enter_confirm_overlay.add_child(center)

	var panel_host := Control.new()
	var panel_tex: Texture2D = DungeonSelectUiTokens.load_tex(DungeonSelectUiTokens.ENTER_CONFIRM_PANEL)
	var panel_w: float = DungeonSelectUiTokens.ENTER_CONFIRM_PANEL_WIDTH
	var panel_h: float = panel_w * 0.57
	if panel_tex != null:
		panel_h = panel_w * float(panel_tex.get_height()) / float(maxi(1, panel_tex.get_width()))
	panel_host.custom_minimum_size = Vector2(panel_w, panel_h)
	panel_host.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel_host)

	var panel := TextureRect.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.texture = panel_tex
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_host.add_child(panel)

	_enter_confirm_yes = _make_enter_confirm_hit_button(true)
	_enter_confirm_yes.pressed.connect(_on_enter_confirmed)
	panel_host.add_child(_enter_confirm_yes)
	_place_enter_confirm_button(_enter_confirm_yes, DungeonSelectUiTokens.ENTER_CONFIRM_YES_RECT, panel_w, panel_h)

	_enter_confirm_no = _make_enter_confirm_hit_button(false)
	_enter_confirm_no.pressed.connect(_hide_enter_confirm)
	panel_host.add_child(_enter_confirm_no)
	_place_enter_confirm_button(_enter_confirm_no, DungeonSelectUiTokens.ENTER_CONFIRM_NO_RECT, panel_w, panel_h)


func _make_enter_confirm_hit_button(yes: bool) -> Button:
	var btn := Button.new()
	# パネル画像に「はい／いいえ」が焼込済み。見た目は画像、操作は Button ヒット領域。
	btn.flat = true
	btn.text = "はい" if yes else "いいえ"
	btn.focus_mode = Control.FOCUS_ALL
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0))
	btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 0))
	btn.add_theme_font_size_override("font_size", 1)
	return btn


func _place_enter_confirm_button(btn: Button, frac: Rect2, panel_w: float, panel_h: float) -> void:
	btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn.anchor_right = 0.0
	btn.anchor_bottom = 0.0
	btn.position = Vector2(panel_w * frac.position.x, panel_h * frac.position.y)
	btn.size = Vector2(panel_w * frac.size.x, panel_h * frac.size.y)
	btn.custom_minimum_size = btn.size


func _on_enter_confirm_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_enter_confirm()


func _show_enter_confirm() -> void:
	if _enter_confirm_overlay == null:
		return
	_enter_confirm_overlay.visible = true
	if _enter_confirm_yes != null:
		_enter_confirm_yes.grab_focus()


func _hide_enter_confirm() -> void:
	if _enter_confirm_overlay != null:
		_enter_confirm_overlay.visible = false


func _apply_typography() -> void:
	UiTypography.apply_button(_btn_back, false)
	UiTypography.apply_button(_btn_featured_select)
	UiTypography.apply_button(_btn_route_main, _route_tab == ROUTE_TAB_MAIN)
	UiTypography.apply_button(_btn_route_sub, _route_tab == ROUTE_TAB_SUB)
	UiTypography.apply_button(_btn_route_event, _route_tab == ROUTE_TAB_EVENT)
	UiTypography.apply_button(_btn_route_abyss, _route_tab == ROUTE_TAB_ABYSS)
	HeaderCurrencyHelper.apply_to_row($MainColumn/Header/HeaderRow)
	UiTypography.apply_display(_label_featured_name, UiTypography.SIZE_BODY_SMALL)
	_label_featured_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(_label_featured_flavor, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	UiTypography.apply_body(_label_featured_meta, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	UiTypography.apply_body(_label_featured_abyss_best, UiTypography.SIZE_CAPTION, COLOR_ABYSS_BEST)
	UiTypography.apply_body(_label_featured_discovery, UiTypography.SIZE_BODY_SMALL, COLOR_CLEAR)
	UiTypography.apply_body(_label_bonus_value, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_caption(_label_bonus_timer)


## Featured 文言は親幅に追従させる（日本語 WORD_SMART は空白無し1語扱いで最小幅＝全文幅になり画面を横に押し広げる）。
## clip_text は付けない（幅未確定フレームで全文が消えることがある。折り返し＋min.x=0 で横伸びだけ抑止）。
func _constrain_featured_text_labels() -> void:
	var labels: Array[Label] = [
		_label_featured_name,
		_label_featured_flavor,
		_label_featured_meta,
		_label_featured_discovery,
	]
	for label in labels:
		if label == null:
			continue
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		label.clip_text = false
		label.custom_minimum_size.x = 0.0
		label.visible = true

func _refresh_all() -> void:
	_featured_dungeon_id = _resolve_featured_dungeon_id()
	if _expanded_biome_id.is_empty() and (
		_uses_stage_cards(_featured_dungeon_id)
		or _is_hourly_tier_event_dungeon(_featured_dungeon_id)
	):
		_expanded_biome_id = _featured_dungeon_id
	_sync_route_tab_to_featured()
	_clamp_selected_tier()
	_update_currency()
	_refresh_tier_tabs()
	_refresh_route_tabs()
	_refresh_route_guide_help()
	_refresh_featured()
	_refresh_event_footer()
	_build_list()
	call_deferred("_reset_scroll_list_top")


func _refresh_route_tabs() -> void:
	var buttons: Array[Button] = [_btn_route_main, _btn_route_sub, _btn_route_event, _btn_route_abyss]
	var tabs: Array[String] = [ROUTE_TAB_MAIN, ROUTE_TAB_SUB, ROUTE_TAB_EVENT, ROUTE_TAB_ABYSS]
	for i in tabs.size():
		var selected: bool = _route_tab == tabs[i]
		buttons[i].button_pressed = selected
		UiTypography.apply_button(buttons[i], selected)
	_refresh_route_guide_help()


func _on_route_tab_pressed(tab: String) -> void:
	if (
		tab != ROUTE_TAB_MAIN
		and tab != ROUTE_TAB_SUB
		and tab != ROUTE_TAB_EVENT
		and tab != ROUTE_TAB_ABYSS
	):
		return
	if tab == ROUTE_TAB_SUB and not Constants.SUB_DUNGEONS_PLAYABLE:
		return
	if tab == ROUTE_TAB_ABYSS and not Constants.ABYSS_DUNGEONS_PLAYABLE:
		return
	if _route_tab == tab:
		_refresh_route_tabs()
		return
	_route_tab = tab
	if tab != ROUTE_TAB_EVENT:
		_ensure_featured_matches_route_tab()
		_expanded_biome_id = ""
		if _uses_stage_cards(_featured_dungeon_id):
			_expanded_biome_id = _featured_dungeon_id
		_clamp_selected_tier()
		_refresh_tier_tabs()
		_refresh_featured()
	_refresh_route_tabs()
	_build_list()
	if tab == ROUTE_TAB_EVENT:
		call_deferred("_maybe_show_descent_route_guide")
	call_deferred("_reset_scroll_list_top")


func _sync_route_tab_to_featured() -> void:
	var data: Resource = DataRegistry.get_dungeon_data(_featured_dungeon_id)
	if data == null:
		return
	var route: String = str(data.route_type)
	if route == "main":
		_route_tab = ROUTE_TAB_MAIN
	elif route == "side" or route == "apex":
		if Constants.SUB_DUNGEONS_PLAYABLE:
			_route_tab = ROUTE_TAB_SUB
		else:
			_route_tab = ROUTE_TAB_MAIN
	elif route == "event":
		_route_tab = ROUTE_TAB_EVENT
	elif route == "abyss":
		if Constants.ABYSS_DUNGEONS_PLAYABLE:
			_route_tab = ROUTE_TAB_ABYSS
		else:
			_route_tab = ROUTE_TAB_MAIN


func _ensure_featured_matches_route_tab() -> void:
	var data: Resource = DataRegistry.get_dungeon_data(_featured_dungeon_id)
	if data != null and _route_matches_tab(str(data.route_type)) and GameState.is_dungeon_unlocked(_featured_dungeon_id):
		return
	var next_id: String = _first_unlocked_for_route_tab()
	if next_id.is_empty():
		next_id = _first_any_for_route_tab()
	if not next_id.is_empty():
		_featured_dungeon_id = next_id
		GameState.current_dungeon_id = next_id
		_sync_selected_stage_for_biome(next_id)
		GameState.current_stage_id = _selected_stage_id


func _route_matches_tab(route_type: String) -> bool:
	if _route_tab == ROUTE_TAB_MAIN:
		return route_type == "main"
	if _route_tab == ROUTE_TAB_SUB:
		return route_type == "side" or route_type == "apex"
	if _route_tab == ROUTE_TAB_EVENT:
		return route_type == "event"
	if _route_tab == ROUTE_TAB_ABYSS:
		return route_type == "abyss"
	return false


func _first_unlocked_for_route_tab() -> String:
	for data in _dungeons_for_route_tab():
		if data != null and GameState.is_dungeon_unlocked(str(data.id)):
			return str(data.id)
	return ""


func _first_any_for_route_tab() -> String:
	var list: Array = _dungeons_for_route_tab()
	if list.is_empty():
		return ""
	return str(list[0].id)


func _dungeons_for_route_tab() -> Array:
	if _route_tab == ROUTE_TAB_SUB:
		var out: Array = []
		out.append_array(_sorted_dungeons("side"))
		out.append_array(_sorted_dungeons("apex"))
		return out
	if _route_tab == ROUTE_TAB_EVENT:
		return _sorted_open_event_dungeons()
	if _route_tab == ROUTE_TAB_ABYSS:
		return _sorted_dungeons("abyss")
	return _sorted_dungeons("main")


## 開催中のみ。時間帯降臨を最上、続けて難易度昇順。
func _sorted_open_event_dungeons() -> Array:
	const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
	var out: Array = []
	for data in DataRegistry.get_all_dungeon_data():
		if data == null or str(data.route_type) != "event":
			continue
		var dungeon_id: String = str(data.id)
		if not _EventDungeonSchedule.is_open_now(dungeon_id):
			continue
		out.append(data)
	out.sort_custom(_compare_open_event_dungeons)
	return out


func _compare_open_event_dungeons(a: Variant, b: Variant) -> bool:
	const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
	var ka: int = _EventDungeonSchedule.list_sort_key(str(a.id), int(a.difficulty))
	var kb: int = _EventDungeonSchedule.list_sort_key(str(b.id), int(b.difficulty))
	return ka < kb


func _clamp_selected_tier() -> void:
	if _featured_dungeon_id.is_empty():
		_featured_dungeon_id = _resolve_featured_dungeon_id()
	var dungeon_id: String = _featured_dungeon_id
	if dungeon_id.is_empty():
		return
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	## 降臨イベント（時王の霊廟／境界廊）は N/H/NM すべて選択可。
	if data != null and _is_hourly_tier_event_dungeon(str(data.id)):
		GameState.current_dungeon_tier = _DungeonTierConfig.clamp_tier(GameState.current_dungeon_tier)
		return
	if data != null and (str(data.route_type) == "event" or str(data.route_type) == "abyss"):
		GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
		return
	var tier: int = _DungeonTierConfig.clamp_tier(GameState.current_dungeon_tier)
	while tier > _DungeonTierConfig.TIER_NORMAL and not GameState.is_dungeon_tier_unlocked(dungeon_id, tier):
		tier -= 1
	GameState.current_dungeon_tier = tier

func _refresh_tier_tabs() -> void:
	var dungeon_id: String = _featured_dungeon_id
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	var hourly_tiers: bool = data != null and _is_hourly_tier_event_dungeon(str(data.id))
	var event_only_normal: bool = (
		data != null
		and not hourly_tiers
		and (str(data.route_type) == "event" or str(data.route_type) == "abyss")
	)
	var buttons: Array[Button] = [_btn_tier_normal, _btn_tier_hard, _btn_tier_nightmare]
	for tier in _DungeonTierConfig.TIER_COUNT:
		var btn: Button = buttons[tier]
		var unlocked: bool = true if hourly_tiers else (
			tier == _DungeonTierConfig.TIER_NORMAL
			if event_only_normal
			else GameState.is_dungeon_tier_unlocked(dungeon_id, tier)
		)
		var selected: bool = GameState.current_dungeon_tier == tier
		btn.disabled = not unlocked
		btn.button_pressed = selected
		var label: String = _DungeonTierConfig.display_name(tier)
		if not unlocked:
			btn.text = "%s 🔒" % label
		elif GameState.is_dungeon_tier_cleared(dungeon_id, tier):
			btn.text = "%s ✓" % label
		else:
			btn.text = label
		_apply_tier_tab(btn, selected, unlocked)


## 難度タブ（鍛冶カテゴリタブ同型）。選択＝金枠＋明るい地＋金文字。
func _tier_tab_style(active: bool, locked: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if locked:
		sb.bg_color = Color(0.07, 0.06, 0.05, 0.72)
		sb.border_color = Color(0.28, 0.26, 0.22, 0.55)
	elif active:
		sb.bg_color = Color(0.16, 0.13, 0.09, 0.94)
		sb.border_color = Color(0.95, 0.82, 0.38, 1.0)
		sb.shadow_color = Color(0.85, 0.65, 0.2, 0.25)
		sb.shadow_size = 1
	else:
		sb.bg_color = Color(0.09, 0.08, 0.07, 0.82)
		sb.border_color = Color(0.40, 0.36, 0.30, 0.72)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10.0
	sb.content_margin_top = 6.0
	sb.content_margin_right = 10.0
	sb.content_margin_bottom = 6.0
	sb.set_border_width_all(1 if not active or locked else 2)
	return sb


func _apply_tier_tab(btn: Button, selected: bool, unlocked: bool) -> void:
	var active: bool = selected and unlocked
	var style: StyleBoxFlat = _tier_tab_style(active, not unlocked)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", _tier_tab_style(false, true))
	if btn.custom_minimum_size.y < 44.0:
		btn.custom_minimum_size = Vector2(btn.custom_minimum_size.x, 44.0)
	var tab_font: Font = UiTypography.display_font()
	if tab_font != null:
		btn.add_theme_font_override("font", tab_font)
	btn.add_theme_font_size_override("font_size", 18 if active else 16)
	btn.add_theme_constant_override("outline_size", UiTypography.OUTLINE_BODY)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	var font_color: Color = UiTypography.COLOR_LOCKED
	if unlocked:
		font_color = UiTypography.COLOR_GOLD if active else UiTypography.COLOR_SUB
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_pressed_color", font_color)
	btn.add_theme_color_override("font_hover_color", font_color)
	btn.add_theme_color_override("font_disabled_color", UiTypography.COLOR_LOCKED)

func _on_tier_pressed(tier: int) -> void:
	var dungeon_id: String = _featured_dungeon_id
	var hourly_tiers: bool = _is_hourly_tier_event_dungeon(dungeon_id)
	if not hourly_tiers and not GameState.is_dungeon_tier_unlocked(dungeon_id, tier):
		return
	GameState.current_dungeon_tier = _DungeonTierConfig.clamp_tier(tier)
	_refresh_tier_tabs()
	_refresh_featured()
	_build_list()

func _uses_stage_cards(dungeon_id: String) -> bool:
	## ダンジョン共通: 章データがあればバナー展開でサブダンジョン一覧（main/event/abyss 共通）。
	if not Constants.SUB_STAGES_PLAYABLE or dungeon_id.is_empty():
		return false
	if DataRegistry.get_dungeon_data(dungeon_id) == null:
		return false
	return not DataRegistry.get_stages_for_biome(dungeon_id).is_empty()

func _sync_selected_stage_for_biome(biome_id: String) -> void:
	if not _uses_stage_cards(biome_id):
		_selected_stage_id = ""
		return
	if not _selected_stage_id.is_empty():
		var current: Resource = DataRegistry.get_stage_data(_selected_stage_id)
		if current != null and str(current.biome_id) == biome_id and GameState.is_stage_unlocked(_selected_stage_id):
			return
	if not GameState.current_stage_id.is_empty():
		var saved: Resource = DataRegistry.get_stage_data(GameState.current_stage_id)
		if saved != null and str(saved.biome_id) == biome_id and GameState.is_stage_unlocked(GameState.current_stage_id):
			_selected_stage_id = GameState.current_stage_id
			return
	_selected_stage_id = GameState.resolve_stage_for_run(biome_id)

func _format_stage_label(stage: Resource) -> String:
	return "%d-%d %s" % [int(stage.biome_index), int(stage.chapter_index), str(stage.display_name)]

func _format_stage_meta_text(stage: Resource) -> String:
	## 無限（深層）は固定チャンク長／推奨Lvを出さない（無限階の性質）。
	## 例: 虚脈の深廊　？？F  推奨レベル？？  最高到達 66F
	if stage != null and _AbyssDungeonConfig.is_abyss_dungeon_id(str(stage.biome_id)):
		return "？？F  推奨レベル？？  最高到達 %s" % _abyss_best_floor_value(
			str(stage.biome_id)
		)
	var parts: Array[String] = ["%dF" % int(stage.floor_count)]
	var rec_lv: int = _DungeonTierConfig.apply_tier_level(
		int(stage.recommended_level), GameState.current_dungeon_tier
	)
	if rec_lv > 0:
		parts.append("推奨Lv%d" % rec_lv)
	return "  ".join(parts)

func _apply_stage_list_rich_text(line: RichTextLabel, unlocked: bool) -> void:
	var body_font: Font = UiTypography.body_font()
	if body_font != null:
		line.add_theme_font_override("normal_font", body_font)
	var display_font: Font = UiTypography.display_font()
	if display_font != null:
		line.add_theme_font_override("bold_font", display_font)
	line.add_theme_font_size_override("normal_font_size", UiTypography.SIZE_BODY_SMALL)
	line.add_theme_font_size_override("bold_font_size", UiTypography.SIZE_BODY_SMALL)

func _stage_list_line_bbcode(stage: Resource, unlocked: bool) -> String:
	var name: String = str(stage.display_name) if unlocked else "？"
	var name_color: String = "f5e07a" if unlocked else "c9c4b8"
	if not unlocked:
		return "[color=#%s][b]%s[/b][/color]  [color=#e0dcd0]未開[/color]" % [name_color, name]
	if _AbyssDungeonConfig.is_abyss_dungeon_id(str(stage.biome_id)):
		var best_bb: String = (
			"[color=#%s][b]最高到達 %s[/b][/color]"
			% [COLOR_ABYSS_BEST_HEX, _abyss_best_floor_value(str(stage.biome_id))]
		)
		return (
			"[color=#%s][b]%s[/b][/color]  [color=#e0dcd0]？？F  推奨レベル？？[/color]  %s"
			% [name_color, name, best_bb]
		)
	var meta: String = _format_stage_meta_text(stage)
	return "[color=#%s][b]%s[/b][/color]  [color=#e0dcd0]%s[/color]" % [name_color, name, meta]

func _dungeon_list_line_bbcode(data: Resource, unlocked: bool) -> String:
	var name: String = _dungeon_display_name(data, unlocked)
	if not unlocked:
		return "[color=#c9c4b8][b]%s[/b][/color]  [color=#e0dcd0]未開[/color]" % name
	var clear_bb: String = ""
	if str(data.route_type) != "abyss":
		var badge: String = _dungeon_name_badge_text(str(data.id))
		if not badge.is_empty():
			clear_bb = " [color=#%s][b]%s[/b][/color]" % [COLOR_CLEAR_BADGE_HEX, badge]
	var name_bb: String = name
	if _is_event_dungeon(data):
		name_bb = _EventDungeonTitleHelper.title_bbcode(str(data.id), name, true)
	else:
		name_bb = "[color=#f5e07a][b]%s[/b][/color]" % name
	if str(data.route_type) == "abyss":
		## 例: ？？F  推奨レベル？？  最高到達 66F（最高到達は赤字）
		var best_bb: String = (
			"[color=#%s][b]最高到達 %s[/b][/color]"
			% [COLOR_ABYSS_BEST_HEX, _abyss_best_floor_value(str(data.id))]
		)
		return (
			"%s%s  [color=#e0dcd0]？？F  推奨レベル？？[/color]  %s"
			% [name_bb, clear_bb, best_bb]
		)
	var parts: Array[String] = []
	if int(data.floor_count) > 0:
		parts.append("%dF" % int(data.floor_count))
	var rec_lv: int = _DungeonTierConfig.apply_tier_level(
		int(data.recommended_level), GameState.current_dungeon_tier
	)
	if rec_lv > 0:
		parts.append("推奨Lv%d〜" % rec_lv)
	var meta: String = "  ".join(parts)
	if meta.is_empty():
		return "%s%s" % [name_bb, clear_bb]
	return "%s%s  [color=#e0dcd0]%s[/color]" % [name_bb, clear_bb, meta]

func _is_stage_cleared_for_ui(stage_id: String) -> bool:
	if stage_id.is_empty():
		return false
	if GameState.is_stage_cleared(stage_id, GameState.current_dungeon_tier):
		return true
	return (
		GameState.current_dungeon_tier == _DungeonTierConfig.TIER_NORMAL
		and GameState.is_stage_cleared(stage_id)
	)

func _make_stage_card(stage: Resource) -> Control:
	var stage_id: String = str(stage.id)
	var unlocked: bool = GameState.is_stage_unlocked(stage_id)
	var selected: bool = stage_id == _selected_stage_id
	var cleared: bool = _is_stage_cleared_for_ui(stage_id)
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, STAGE_CARD_MIN_SIZE.y)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_theme_stylebox_override(
		"panel",
		CombatUiFrames.panel_style(
			CombatUiFrames.TIER_CARD_ACTIVE if selected else CombatUiFrames.TIER_CARD
		)
	)
	if not unlocked:
		wrap.modulate = Color(0.72, 0.72, 0.76, 1.0)
	var btn := Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.disabled = not unlocked
	btn.toggle_mode = true
	btn.button_pressed = selected
	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 4
	content.offset_top = 4
	content.offset_right = -4
	content.offset_bottom = -4
	content.add_theme_constant_override("separation", 6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(content)
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = STAGE_THUMB_SIZE
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unlocked:
		var stage_tex: Texture2D = IconPaths.get_stage_icon_texture(stage_id)
		if stage_tex != null:
			thumb.texture = stage_tex
		else:
			thumb.texture = _get_dungeon_thumb_texture(str(stage.biome_id))
	content.add_child(thumb)
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 1)
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(text_col)
	var line := RichTextLabel.new()
	line.bbcode_enabled = true
	line.fit_content = true
	line.scroll_active = false
	## OFF＋fit_content だと最小幅＝全文幅で一覧が横に広がる。任意折り返し＋min.x=0。
	line.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.custom_minimum_size = Vector2(0, UiTypography.SIZE_BODY_SMALL + 6)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_stage_list_rich_text(line, unlocked)
	line.text = _stage_list_line_bbcode(stage, unlocked)
	text_col.add_child(line)
	var biome_id: String = str(stage.biome_id) if stage != null else ""
	var status_text: String = ""
	var status_is_badge: bool = false
	if not unlocked:
		status_text = "？"
	elif _is_daily_attempt_exhausted(biome_id):
		status_text = BADGE_ATTEMPTED
		status_is_badge = true
	elif cleared and not _is_daily_attempt_event(biome_id):
		status_text = BADGE_CLEAR
		status_is_badge = true
	elif bool(stage.has_boss_floor()):
		status_text = "ボス"
	if not status_text.is_empty():
		var status_col := VBoxContainer.new()
		status_col.size_flags_horizontal = Control.SIZE_SHRINK_END
		status_col.alignment = BoxContainer.ALIGNMENT_CENTER
		status_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var status := Label.new()
		status.text = status_text
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_caption(status, COLOR_CLEAR_BADGE if status_is_badge else UiTypography.COLOR_SUB)
		status_col.add_child(status)
		content.add_child(status_col)
	btn.pressed.connect(_on_stage_card_pressed.bind(stage_id))
	UiTypography.apply_button(btn, selected)
	wrap.add_child(btn)
	return wrap

func _on_stage_card_pressed(stage_id: String) -> void:
	if not GameState.is_stage_unlocked(stage_id):
		return
	_selected_stage_id = stage_id
	GameState.current_stage_id = stage_id
	_refresh_featured()
	_build_list()
	var stage_data: Resource = DataRegistry.get_stage_data(stage_id)
	var biome_id: String = str(stage_data.biome_id) if stage_data != null else _featured_dungeon_id
	_prompt_enter_dungeon(biome_id)

func _refresh_event_footer() -> void:
	if not EventSystem.PERIODIC_EVENTS_ENABLED:
		_footer_panel.visible = false
		_bonus_col.visible = false
		_sync_list_footer_stack()
		return
	var event_data: Resource = EventSystem.get_active_event()
	if event_data == null:
		_footer_panel.visible = false
		_bonus_col.visible = false
		_sync_list_footer_stack()
		return
	_footer_panel.visible = true
	_bonus_col.visible = true
	var summary: String = EventSystem.active_modifier_summary()
	if EventSystem.is_featured_biome_week():
		var biome_id: String = EventSystem.get_featured_biome_id()
		if not biome_id.is_empty():
			var biome: Resource = DataRegistry.get_dungeon_data(biome_id)
			if biome != null:
				summary = "%s ｜ 注目: %s" % [summary, str(biome.display_name)]
	_label_bonus_value.text = summary if not summary.is_empty() else str(event_data.title)
	var countdown: String = EventSystem.countdown_text()
	if not countdown.is_empty() and countdown != "—":
		_label_bonus_value.text = "%s（%s）" % [_label_bonus_value.text, countdown]
	_label_bonus_timer.visible = false
	_constrain_footer_labels()
	_sync_list_footer_stack()
	call_deferred("_sync_list_footer_stack")


## イベント情報欄の長い日本語で Footer が横拡大／リストに重ならないようにする。
func _constrain_footer_labels() -> void:
	if _footer_panel == null:
		return
	_footer_panel.clip_contents = true
	_footer_panel.offset_left = 8.0
	_footer_panel.offset_right = -8.0
	var title: Label = _footer_panel.get_node_or_null("FooterRow/BonusCol/LabelBonusTitle") as Label
	if title != null:
		## 1行に要約＋残り時間だけ出す（タイトルは冗長で高さを食う）。
		title.visible = false
	if _bonus_col != null:
		_bonus_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _label_bonus_value != null:
		_label_bonus_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_label_bonus_value.custom_minimum_size.x = 0.0
		_label_bonus_value.autowrap_mode = TextServer.AUTOWRAP_OFF
		_label_bonus_value.clip_text = true
		_label_bonus_value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if _label_bonus_timer != null:
		_label_bonus_timer.size_flags_horizontal = Control.SIZE_SHRINK_END
		_label_bonus_timer.custom_minimum_size.x = 0.0
		_label_bonus_timer.clip_text = true


## Footer（イベント情報）の実高に合わせて MainColumn 下端を空け、リスト見切れを防ぐ。
func _sync_list_footer_stack() -> void:
	var main: Control = $MainColumn as Control
	var nav: Control = $BottomNav as Control
	if main == null or _footer_panel == null or nav == null:
		return
	var nav_h: float = HubLayoutHelper.bottom_nav_total_height()
	## Mac は chrome OFF のため、シーン上の BottomNav 高を優先（Tokens 68 より実パネルが厚い）。
	if not SafeAreaHelper.should_apply_chrome():
		var design_nav: float = absf(nav.offset_bottom - nav.offset_top)
		if design_nav < 1.0:
			design_nav = nav.size.y
		if design_nav > 1.0:
			nav_h = design_nav
	if not _footer_panel.visible:
		main.offset_bottom = -nav_h
		return
	_footer_panel.offset_left = 8.0
	_footer_panel.offset_right = -8.0
	_footer_panel.clip_contents = true
	var footer_h: float = _footer_panel.get_combined_minimum_size().y
	if footer_h < 40.0:
		footer_h = absf(_footer_panel.offset_bottom - _footer_panel.offset_top)
	if footer_h < 40.0:
		footer_h = 56.0
	## 情報欄はコンパクトに保ち、リスト領域を優先。
	footer_h = minf(footer_h, 72.0)
	_footer_panel.offset_bottom = -nav_h
	_footer_panel.offset_top = -(nav_h + footer_h)
	main.offset_bottom = -(nav_h + footer_h)

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()

func _refresh_featured() -> void:
	var data: Resource = DataRegistry.get_dungeon_data(_featured_dungeon_id)
	if data == null:
		_featured_panel.visible = false
		_btn_featured_select.disabled = true
		return
	_sync_selected_stage_for_biome(_featured_dungeon_id)
	_featured_panel.visible = true
	_sync_featured_banner(_featured_dungeon_id)
	var stage: Resource = DataRegistry.get_stage_data(_selected_stage_id)
	var title_baked: bool = _banner_hides_title(_featured_dungeon_id)
	var unlocked_featured: bool = GameState.is_dungeon_unlocked(_featured_dungeon_id)
	if not unlocked_featured:
		_hide_featured_name_twotone()
		_label_featured_name.visible = true
		_label_featured_name.text = "？"
		_label_featured_flavor.text = "未開のダンジョン"
		_label_featured_flavor.visible = true
		UiTypography.apply_display(
			_label_featured_name, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB
		)
	elif title_baked:
		_hide_featured_name_twotone()
		_label_featured_name.visible = stage != null and _uses_stage_cards(_featured_dungeon_id)
		_label_featured_name.text = str(stage.display_name) if stage != null else ""
		if _label_featured_name.visible:
			UiTypography.apply_display(
				_label_featured_name, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD
			)
	elif stage != null and _uses_stage_cards(_featured_dungeon_id):
		_hide_featured_name_twotone()
		_label_featured_name.visible = true
		_label_featured_name.text = "%s — %s" % [
			_dungeon_display_name(data, true),
			str(stage.display_name),
		]
		if _is_event_dungeon(data):
			_apply_event_dungeon_title_style(_label_featured_name, UiTypography.SIZE_BODY_SMALL, true)
		else:
			UiTypography.apply_display(
				_label_featured_name, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD
			)
	else:
		## 名横バッジ（CLEAR／挑戦済み）は一覧バナー側で緑表示。降臨は本体／「降臨」の2色。
		_set_featured_dungeon_title(data, true)
	if unlocked_featured:
		_label_featured_flavor.text = str(data.flavor_text)
		_label_featured_flavor.visible = not str(data.flavor_text).is_empty()

	var meta_parts: Array[String] = []
	if unlocked_featured:
		if stage != null and _uses_stage_cards(_featured_dungeon_id):
			if not title_baked:
				meta_parts.append(str(stage.display_name))
			## 深層は固定チャンクの 10F／推奨Lv を出さず、？？＋最高到達を示す。
			if str(data.route_type) == "abyss":
				meta_parts.append("？？F")
				meta_parts.append("推奨レベル？？")
				meta_parts.append(
					"最高到達 %s" % _abyss_best_floor_value(_featured_dungeon_id)
				)
			else:
				meta_parts.append("%dF" % int(stage.floor_count))
				var stage_rec: int = _DungeonTierConfig.apply_tier_level(
					int(stage.recommended_level), GameState.current_dungeon_tier
				)
				if stage_rec > 0:
					meta_parts.append("推奨Lv%d" % stage_rec)
			if bool(stage.has_boss_floor()):
				meta_parts.append("ボス")
			elif bool(stage.requires_elite):
				meta_parts.append("エリート")
		meta_parts.append(_DungeonTierConfig.display_name(GameState.current_dungeon_tier))
		var tier_summary: String = _DungeonTierConfig.summary_text(GameState.current_dungeon_tier)
		if not tier_summary.is_empty():
			meta_parts.append(tier_summary)
		var dungeon_rec: int = _DungeonTierConfig.apply_tier_level(
			int(data.recommended_level), GameState.current_dungeon_tier
		)
		if (
			dungeon_rec > 0
			and str(data.route_type) != "abyss"
			and (stage == null or not _uses_stage_cards(_featured_dungeon_id))
		):
			meta_parts.append("推奨Lv%d〜" % dungeon_rec)
		if str(data.route_type) == "event":
			const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
			meta_parts.append(_EventDungeonSchedule.open_schedule_label(_featured_dungeon_id))
		if str(data.route_type) == "abyss":
			meta_parts.append("無限階")
		elif not _uses_stage_cards(_featured_dungeon_id) and int(data.floor_count) > 0:
			meta_parts.append("%dF" % int(data.floor_count))
		if _uses_stage_cards(_featured_dungeon_id):
			var stage_label: String = GameState.get_stage_progress_label(_featured_dungeon_id)
			if not stage_label.is_empty():
				meta_parts.append(stage_label)
		meta_parts.append(_make_stars_text(int(data.difficulty)))
	else:
		meta_parts.append("？")
	_label_featured_meta.text = " · ".join(meta_parts)

	var abyss_best_f: int = (
		GameState.get_abyss_highest_floor(_featured_dungeon_id)
		if unlocked_featured and str(data.route_type) == "abyss"
		else 0
	)
	_label_featured_abyss_best.visible = abyss_best_f > 0
	if abyss_best_f > 0:
		_label_featured_abyss_best.text = "最高到達 F%d" % abyss_best_f

	if unlocked_featured:
		var discovery_pct: int = _discovery_percent(_featured_dungeon_id)
		_label_featured_discovery.text = "発見率 %d%%" % discovery_pct
		if GameState.is_dungeon_tier_cleared(_featured_dungeon_id, GameState.current_dungeon_tier):
			_label_featured_discovery.text += " · %s クリア済" % _DungeonTierConfig.display_name(
				GameState.current_dungeon_tier
			)
		elif GameState.is_dungeon_cleared(_featured_dungeon_id):
			_label_featured_discovery.text += " · ノーマル クリア済"
		_populate_drop_row(_featured_drop_row, _featured_dungeon_id, 4)
	else:
		_label_featured_discovery.text = "未開"
		for child in _featured_drop_row.get_children():
			child.queue_free()
	var unlocked: bool = unlocked_featured
	var stage_ready: bool = (
		not _uses_stage_cards(_featured_dungeon_id)
		or (
			not _selected_stage_id.is_empty()
			and GameState.is_stage_unlocked(_selected_stage_id)
		)
	)
	var attempt_ok: bool = true
	if unlocked and data != null and str(data.route_type) == "event":
		const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
		if not _EventDungeonSchedule.is_open_now(_featured_dungeon_id):
			var next_lbl: String = _EventDungeonSchedule.next_open_label(_featured_dungeon_id)
			var sched: String = _EventDungeonSchedule.open_schedule_label(_featured_dungeon_id)
			_label_featured_discovery.text += " · 開放: %s" % sched
			if not next_lbl.is_empty():
				_label_featured_discovery.text += " · %s" % next_lbl
				_btn_featured_select.text = next_lbl
			else:
				_btn_featured_select.text = "出現時間外（%s）" % sched
			_btn_featured_select.disabled = true
			return
		_label_featured_discovery.text += " · %s" % _EventDungeonSchedule.open_schedule_label(
			_featured_dungeon_id
		)
		if _is_hourly_tier_event_dungeon(str(data.id)):
			_btn_featured_select.text = "選択して出発"
			_btn_featured_select.disabled = false
			## 難度は上部 TabsRow（N/H/NM）。進入行／Featured とも同じ tier を使う。
			return
	if unlocked and data != null and int(data.daily_attempt_limit) > 0:
		var remaining: int = GameState.event_dungeon_attempts_remaining(_featured_dungeon_id)
		_label_featured_discovery.text += " · 本日残り %d/%d（リセット %s）" % [
			remaining,
			int(data.daily_attempt_limit),
			DailyMissionSystem.reset_countdown_text(),
		]
		attempt_ok = remaining > 0
		if not attempt_ok:
			_btn_featured_select.text = BADGE_ATTEMPTED
			_btn_featured_select.disabled = true
			return
	_btn_featured_select.text = "選択して出発" if unlocked else "未開"
	_btn_featured_select.disabled = not unlocked or not stage_ready or not attempt_ok


func _resolve_featured_dungeon_id() -> String:
	if not _featured_dungeon_id.is_empty():
		var current: Resource = DataRegistry.get_dungeon_data(_featured_dungeon_id)
		if current != null and GameState.is_dungeon_unlocked(_featured_dungeon_id):
			return _featured_dungeon_id
	var active_id: String = GameState.get_active_dungeon_id()
	if DataRegistry.get_dungeon_data(active_id) != null and GameState.is_dungeon_unlocked(active_id):
		return active_id
	for data in DataRegistry.get_all_dungeon_data():
		if data != null and str(data.route_type) == "main" and GameState.is_dungeon_unlocked(str(data.id)):
			return str(data.id)
	for data in DataRegistry.get_all_dungeon_data():
		if data != null and GameState.is_dungeon_unlocked(str(data.id)):
			return str(data.id)
	for data in DataRegistry.get_all_dungeon_data():
		if data != null:
			return str(data.id)
	return ""

func _set_featured_dungeon(dungeon_id: String) -> void:
	if dungeon_id.is_empty() or DataRegistry.get_dungeon_data(dungeon_id) == null:
		return
	_featured_dungeon_id = dungeon_id
	GameState.current_dungeon_id = dungeon_id
	_sync_route_tab_to_featured()
	_sync_selected_stage_for_biome(dungeon_id)
	GameState.current_stage_id = _selected_stage_id
	_clamp_selected_tier()
	_refresh_tier_tabs()
	_refresh_route_tabs()
	_refresh_featured()
	_build_list()

func _on_biome_accordion_pressed(dungeon_id: String) -> void:
	if not GameState.is_dungeon_unlocked(dungeon_id):
		return
	if _expanded_biome_id == dungeon_id:
		_expanded_biome_id = ""
	else:
		_expanded_biome_id = dungeon_id
	_set_featured_dungeon(dungeon_id)

func _discovery_percent(dungeon_id: String) -> int:
	var prog: Dictionary = GameState.dungeon_progress.get(dungeon_id, {})
	return int(round(float(prog.get("discovery", 0.0)) * 100.0))

func _populate_drop_row(row: HBoxContainer, dungeon_id: String, max_icons: int = 3) -> void:
	for child in row.get_children():
		child.queue_free()
	var caption := Label.new()
	caption.text = DROP_CAPTION
	UiTypography.apply_caption(caption)
	row.add_child(caption)
	var preview: Array = DROP_PREVIEW.get(dungeon_id, [])
	var shown: int = 0
	for pair in preview:
		if shown >= max_icons:
			break
		var tex: Texture2D = IconPaths.get_icon_texture(str(pair[1]), str(pair[0]))
		if tex == null:
			continue
		row.add_child(_make_drop_icon(tex))
		shown += 1

func _build_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	var entries: Array = _dungeons_for_route_tab()
	if entries.is_empty() and _route_tab == ROUTE_TAB_EVENT:
		_list.add_child(_make_event_tab_placeholder())
	else:
		for data in entries:
			if data == null:
				continue
			# メイン／サブともバナー＋アコーディオン（章が無ければバナー選択のみ）
			_list.add_child(_make_biome_accordion(data))
	# 末尾バナーがフッター／下ナビで見切れないようスクロール余白を確保
	_list.add_child(_make_list_bottom_spacer())
	## 動的生成した Button がタッチドラッグを奪うため、列挙後に PASS 化。
	call_deferred("_enable_list_touch_scroll")


func _enable_list_touch_scroll() -> void:
	ScrollTouchHelper.enable(_scroll_list)


func _make_event_tab_placeholder() -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = "開催中のイベントダンジョンはありません"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 0.0
	UiTypography.apply_body(label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB)
	margin.add_child(label)
	return margin

func _make_list_bottom_spacer() -> Control:
	var spacer := Control.new()
	spacer.name = "ListBottomSpacer"
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.custom_minimum_size = Vector2(0, BIOME_BANNER_HEIGHT + 16)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer

func _sorted_dungeons(route_type: String) -> Array:
	var out: Array = []
	for data in DataRegistry.get_all_dungeon_data():
		if data == null or str(data.route_type) != route_type:
			continue
		out.append(data)
	out.sort_custom(func(a, b): return int(a.difficulty) < int(b.difficulty))
	return out

func _make_section_header(title: String) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var header := Label.new()
	header.text = title
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(header, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	header.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	header.add_theme_constant_override("shadow_offset_x", 1)
	header.add_theme_constant_override("shadow_offset_y", 1)
	header.add_theme_constant_override("shadow_outline_size", 3)
	margin.add_child(header)
	return margin

func _make_biome_accordion(data: Resource) -> Control:
	var dungeon_id: String = str(data.id)
	var unlocked: bool = GameState.is_dungeon_unlocked(dungeon_id)
	var is_expanded: bool = unlocked and dungeon_id == _expanded_biome_id
	var is_featured: bool = dungeon_id == _featured_dungeon_id
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 2)

	var banner_tex: Texture2D = _get_biome_banner_texture(dungeon_id)
	## 未開はバナー実写を出さず「？」ヘッダに統一（ネタバレ防止）。
	if banner_tex != null and unlocked:
		outer.add_child(_make_biome_banner_header(data, banner_tex, unlocked, is_expanded, is_featured))
	else:
		outer.add_child(_make_biome_text_header(data, unlocked, is_expanded, is_featured))

	if is_expanded:
		var stages_box := VBoxContainer.new()
		stages_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stages_box.add_theme_constant_override("separation", 4)
		if _is_hourly_tier_event_dungeon(dungeon_id):
			stages_box.add_child(_make_hourly_tier_enter_card(dungeon_id))
		else:
			for stage in DataRegistry.get_stages_for_biome(dungeon_id):
				if stage != null:
					stages_box.add_child(_make_stage_card(stage))
		outer.add_child(stages_box)
	return outer


## 時間帯降臨イベント — TabsRow の難度に連動する進入行（縦3行は廃止）。
func _is_hourly_tier_event_dungeon(dungeon_id: String) -> bool:
	return (
		dungeon_id == Constants.CHRONOS_MAUSOLEUM_DUNGEON_ID
		or dungeon_id == Constants.VALGARD_BOUNDARY_DUNGEON_ID
	)


func _hourly_tier_enter_label(dungeon_id: String) -> String:
	if dungeon_id == Constants.VALGARD_BOUNDARY_DUNGEON_ID:
		return "ストームクラウン境界廊"
	return "時王の霊廟"


func _make_hourly_tier_enter_card(dungeon_id: String) -> Control:
	const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
	var open_now: bool = _EventDungeonSchedule.is_open_now(dungeon_id)
	var next_label: String = _EventDungeonSchedule.next_open_label(dungeon_id)
	var enter_name: String = _hourly_tier_enter_label(dungeon_id)
	var tier: int = _DungeonTierConfig.clamp_tier(GameState.current_dungeon_tier)
	var cleared: bool = GameState.is_dungeon_tier_cleared(dungeon_id, tier)
	var selected: bool = _featured_dungeon_id == dungeon_id
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(0, STAGE_CARD_MIN_SIZE.y)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_theme_stylebox_override(
		"panel",
		CombatUiFrames.panel_style(
			CombatUiFrames.TIER_CARD_ACTIVE if selected and open_now else CombatUiFrames.TIER_CARD
		)
	)
	if not open_now:
		wrap.modulate = Color(0.72, 0.72, 0.76, 1.0)
	var btn := Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.disabled = not open_now
	btn.toggle_mode = true
	btn.button_pressed = selected and open_now
	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 4
	content.offset_top = 4
	content.offset_right = -4
	content.offset_bottom = -4
	content.add_theme_constant_override("separation", 6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(content)
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = STAGE_THUMB_SIZE
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if open_now:
		thumb.texture = _get_dungeon_thumb_texture(dungeon_id)
	content.add_child(thumb)
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 1)
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(text_col)
	var line := RichTextLabel.new()
	line.bbcode_enabled = true
	line.fit_content = true
	line.scroll_active = false
	line.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.custom_minimum_size = Vector2(0, UiTypography.SIZE_BODY_SMALL + 6)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_stage_list_rich_text(line, open_now)
	var title_text: String = "%s　%s" % [enter_name, _DungeonTierConfig.display_name(tier)]
	if not open_now and not next_label.is_empty():
		title_text += "（%s）" % next_label
	var name_color: String = "f5e07a" if open_now else "c9c4b8"
	line.text = "[color=#%s][b]%s[/b][/color]" % [name_color, title_text]
	text_col.add_child(line)
	var status_text: String = ""
	if not open_now:
		status_text = "？"
	elif cleared:
		status_text = "CLEAR"
	if not status_text.is_empty():
		var status_col := VBoxContainer.new()
		status_col.size_flags_horizontal = Control.SIZE_SHRINK_END
		status_col.alignment = BoxContainer.ALIGNMENT_CENTER
		status_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var status := Label.new()
		status.text = status_text
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_caption(status, COLOR_CLEAR_BADGE if cleared else UiTypography.COLOR_SUB)
		status_col.add_child(status)
		content.add_child(status_col)
	if open_now:
		btn.pressed.connect(_on_hourly_tier_enter_pressed.bind(dungeon_id))
	UiTypography.apply_button(btn, selected and open_now)
	wrap.add_child(btn)
	return wrap


func _on_hourly_tier_enter_pressed(dungeon_id: String) -> void:
	const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
	if not _EventDungeonSchedule.is_open_now(dungeon_id):
		return
	_featured_dungeon_id = dungeon_id
	_expanded_biome_id = dungeon_id
	_selected_stage_id = ""
	GameState.current_stage_id = ""
	_refresh_tier_tabs()
	_refresh_featured()
	_build_list()
	_prompt_enter_dungeon(dungeon_id)


func _get_biome_banner_texture(dungeon_id: String) -> Texture2D:
	var path: String = _BiomeBannerHelper.resolve_path(dungeon_id)
	if path.is_empty():
		return null
	return _load_texture_flexible(path)

## 一覧・Featured ともデザイン幅基準の高さのみ（実幅追従禁止）。
## host.size.x 連動＋resized 再計算は押下のたびにバナーが伸びる原因になる。
func _biome_banner_header_size(banner_tex: Texture2D) -> Vector2:
	if banner_tex == null:
		return BIOME_HEADER_MIN_SIZE
	var tw: int = banner_tex.get_width()
	var th: int = banner_tex.get_height()
	if tw <= 0 or th <= 0:
		return BIOME_HEADER_MIN_SIZE
	var height: float = BIOME_BANNER_LIST_WIDTH * float(th) / float(tw)
	height = clampf(height, BIOME_BANNER_HEIGHT_MIN, BIOME_BANNER_HEIGHT_MAX)
	## x は必ず 0。テクスチャ実寸や実幅を min に入れると Scroll／画面が横に広がる。
	return Vector2(0.0, height)

func _banner_hides_title(dungeon_id: String) -> bool:
	return bool(BIOME_BANNER_TITLE_BAKED.get(dungeon_id, false))

func _uses_list_biome_banner(dungeon_id: String) -> bool:
	return _get_biome_banner_texture(dungeon_id) != null

func _make_biome_title_label(data: Resource, unlocked: bool) -> Control:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_dungeon_title_labels(row, data, unlocked, UiTypography.SIZE_BODY_SMALL, false)
	if unlocked and data != null:
		var badge: String = _dungeon_name_badge_text(str(data.id))
		if not badge.is_empty():
			var clear_lbl := Label.new()
			clear_lbl.text = badge
			UiTypography.apply_display(clear_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_CLEAR_BADGE)
			row.add_child(clear_lbl)
	margin.add_child(row)
	return margin

## バナー名は FULL_RECT 埋め込み禁止（実機でグリフが横方向に潰れて見える）。
## 中央寄せ＋自然サイズ。clip_text / 親 clip_contents と併用するとサイズ0で文字が消える（再発防止）。
func _make_banner_overlay_title(data: Resource, unlocked: bool, dungeon_id: String) -> Control:
	var host := HBoxContainer.new()
	host.alignment = BoxContainer.ALIGNMENT_CENTER
	host.add_theme_constant_override("separation", 8)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title_text: String = _dungeon_display_name(data, unlocked)
	var is_abyss: bool = data != null and str(data.route_type) == "abyss"
	var name_badge: String = ""
	if unlocked and data != null and not is_abyss:
		name_badge = _dungeon_name_badge_text(str(data.id))
	var show_abyss_best: bool = unlocked and is_abyss
	var title_size: int = _banner_title_font_size(
		dungeon_id, title_text, not name_badge.is_empty() or show_abyss_best
	)
	_add_dungeon_title_labels(host, data, unlocked, title_size, true)
	if not name_badge.is_empty():
		var clear_lbl := Label.new()
		clear_lbl.text = name_badge
		clear_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_display(clear_lbl, title_size, COLOR_CLEAR_BADGE)
		_apply_banner_title_shadow(clear_lbl)
		host.add_child(clear_lbl)
	elif show_abyss_best:
		var best_lbl := Label.new()
		best_lbl.text = _abyss_best_floor_text(dungeon_id)
		best_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_display(best_lbl, title_size, COLOR_ABYSS_BEST)
		_apply_banner_title_shadow(best_lbl)
		host.add_child(best_lbl)
	host.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	host.offset_top -= 2.0
	host.offset_bottom -= 6.0
	host.grow_horizontal = Control.GROW_DIRECTION_BOTH
	host.grow_vertical = Control.GROW_DIRECTION_BOTH
	return host


func _is_event_dungeon(data: Resource) -> bool:
	return data != null and str(data.route_type) == "event"


## タイトル Label 群を host に追加（降臨は本体＋「降臨」の2色）。
func _add_dungeon_title_labels(
	host: Control,
	data: Resource,
	unlocked: bool,
	size: int,
	banner_shadow: bool
) -> void:
	var title_text: String = _dungeon_display_name(data, unlocked)
	var dungeon_id: String = str(data.id) if data != null else ""
	if unlocked and _is_event_dungeon(data):
		var parts: Dictionary = _EventDungeonTitleHelper.split_title(title_text)
		var suffix: String = str(parts.get("suffix", ""))
		if not suffix.is_empty():
			var body_lbl := _make_title_piece_label(
				str(parts.get("body", "")),
				size,
				_EventDungeonTitleHelper.body_color(dungeon_id, true),
				_EventDungeonTitleHelper.body_outline_color(dungeon_id),
				banner_shadow
			)
			var mark_lbl := _make_title_piece_label(
				suffix,
				size,
				_EventDungeonTitleHelper.suffix_color(true),
				_EventDungeonTitleHelper.suffix_outline_color(),
				banner_shadow
			)
			host.add_child(body_lbl)
			host.add_child(mark_lbl)
			return
		var plain := _make_title_piece_label(
			title_text,
			size,
			_EventDungeonTitleHelper.plain_event_color(true),
			_EventDungeonTitleHelper.COLOR_EVENT_PLAIN_OUTLINE,
			banner_shadow
		)
		host.add_child(plain)
		return
	var label := _make_title_piece_label(
		title_text,
		size,
		UiTypography.COLOR_GOLD if unlocked else UiTypography.COLOR_SUB,
		Color(0, 0, 0, 0.9),
		banner_shadow and not unlocked
	)
	if not unlocked:
		label.modulate = Color(0.72, 0.72, 0.76, 1.0)
	if banner_shadow and unlocked and not _is_event_dungeon(data):
		_apply_banner_title_shadow(label, false)
	host.add_child(label)


func _make_title_piece_label(
	text: String,
	size: int,
	color: Color,
	outline: Color,
	strong_shadow: bool
) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.max_lines_visible = 1
	label.clip_text = false
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outline_size: int = EVENT_TITLE_OUTLINE_SIZE if strong_shadow else UiTypography.OUTLINE_BODY
	UiTypography.apply_display(label, size, color, outline_size)
	label.add_theme_color_override("font_outline_color", outline)
	if strong_shadow:
		_apply_banner_title_shadow(label, true)
	return label


## 曜日イベント等の単色スタイル（Featured の非2色時）。
func _apply_event_dungeon_title_style(label: Label, size: int, unlocked: bool) -> void:
	var color: Color = _EventDungeonTitleHelper.plain_event_color(unlocked)
	UiTypography.apply_display(label, size, color, EVENT_TITLE_OUTLINE_SIZE)
	if unlocked:
		label.add_theme_color_override(
			"font_outline_color", _EventDungeonTitleHelper.COLOR_EVENT_PLAIN_OUTLINE
		)
	_apply_banner_title_shadow(label, true)


func _ensure_featured_name_twotone() -> HBoxContainer:
	if _featured_name_twotone != null and is_instance_valid(_featured_name_twotone):
		return _featured_name_twotone
	var parent: Node = _label_featured_name.get_parent()
	_featured_name_twotone = HBoxContainer.new()
	_featured_name_twotone.name = "FeaturedNameTwotone"
	_featured_name_twotone.add_theme_constant_override("separation", 0)
	_featured_name_twotone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_featured_name_twotone)
	parent.move_child(_featured_name_twotone, _label_featured_name.get_index() + 1)
	return _featured_name_twotone


func _hide_featured_name_twotone() -> void:
	if _featured_name_twotone != null and is_instance_valid(_featured_name_twotone):
		_featured_name_twotone.visible = false
		for child in _featured_name_twotone.get_children():
			child.queue_free()


func _set_featured_dungeon_title(data: Resource, unlocked: bool) -> void:
	var title_text: String = _dungeon_display_name(data, unlocked)
	var dungeon_id: String = str(data.id) if data != null else ""
	if (
		unlocked
		and _is_event_dungeon(data)
		and _EventDungeonTitleHelper.is_descent_twotone(title_text)
	):
		var host: HBoxContainer = _ensure_featured_name_twotone()
		for child in host.get_children():
			child.queue_free()
		_label_featured_name.visible = false
		host.visible = true
		_add_dungeon_title_labels(host, data, unlocked, UiTypography.SIZE_BODY_SMALL, true)
		return
	_hide_featured_name_twotone()
	_label_featured_name.visible = true
	_label_featured_name.text = title_text
	if unlocked and _is_event_dungeon(data):
		_apply_event_dungeon_title_style(_label_featured_name, UiTypography.SIZE_BODY_SMALL, true)
	elif unlocked:
		UiTypography.apply_display(
			_label_featured_name, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD
		)
	else:
		UiTypography.apply_display(
			_label_featured_name, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB
		)


func _apply_banner_title_shadow(label: Label, strong: bool = false) -> void:
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 2 if strong else 1)
	label.add_theme_constant_override("shadow_offset_y", 2 if strong else 1)
	label.add_theme_constant_override(
		"shadow_outline_size", EVENT_TITLE_SHADOW_OUTLINE if strong else 5
	)

func _sync_featured_banner(dungeon_id: String) -> void:
	for child in _featured_banner_host.get_children():
		child.queue_free()
	var banner_tex: Texture2D = _get_biome_banner_texture(dungeon_id)
	if banner_tex == null:
		_featured_banner_host.visible = false
		_featured_banner_host.custom_minimum_size = Vector2.ZERO
		return
	_featured_banner_host.visible = true
	_featured_banner_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_featured_banner_host.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	## オーバーレイタイトルを切らない（バナー本体の TextureRect は FULL_RECT で収まる）。
	_featured_banner_host.clip_contents = false
	_featured_banner_host.custom_minimum_size = _biome_banner_header_size(banner_tex)
	var banner := TextureRect.new()
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.texture = banner_tex
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_featured_banner_host.add_child(banner)
	## 一覧バナーと同様、画像上にダンジョン名を重ねる（焼き込み無しの雰囲気BG向け）。
	if _banner_hides_title(dungeon_id):
		return
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	if data == null:
		return
	var unlocked: bool = GameState.is_dungeon_unlocked(dungeon_id)
	var title: Control = _make_banner_overlay_title(data, unlocked, dungeon_id)
	_featured_banner_host.add_child(title)

func _banner_title_font_size(
	dungeon_id: String,
	title_text: String = "",
	with_clear: bool = false
) -> int:
	return _BiomeBannerHelper.title_font_size(dungeon_id, title_text, with_clear)

func _make_biome_banner_header(
	data: Resource,
	banner_tex: Texture2D,
	unlocked: bool,
	is_expanded: bool,
	is_featured: bool
) -> Control:
	var dungeon_id: String = str(data.id)
	var root := Control.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	## オーバーレイタイトル（中央・自然サイズ）を切らない。横はみ出しは Scroll SHOW_NEVER 側で抑止。
	root.clip_contents = false
	root.custom_minimum_size = _biome_banner_header_size(banner_tex)
	if not unlocked:
		root.modulate = Color(0.72, 0.72, 0.76, 1.0)

	var banner := TextureRect.new()
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.texture = banner_tex
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner)

	## タイトルは Featured と同様・自然サイズ中央。シェブロンは左オーバーレイ（HBox だと右寄りになる）。
	if not _banner_hides_title(dungeon_id):
		root.add_child(_make_banner_overlay_title(data, unlocked, dungeon_id))

	var chevron := Label.new()
	chevron.text = "▼" if is_expanded else "▶"
	if not unlocked:
		chevron.text = "？"
	chevron.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	chevron.offset_left = 8.0
	chevron.offset_right = 32.0
	chevron.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# バナー上でも視認できるよう金＋影を強める
	UiTypography.apply_body(chevron, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	chevron.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
	chevron.add_theme_constant_override("shadow_offset_x", 1)
	chevron.add_theme_constant_override("shadow_offset_y", 1)
	chevron.add_theme_constant_override("shadow_outline_size", 4)
	root.add_child(chevron)

	var header_btn := Button.new()
	header_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_btn.flat = true
	header_btn.disabled = not unlocked
	header_btn.pressed.connect(_on_biome_accordion_pressed.bind(dungeon_id))
	UiTypography.apply_button(header_btn, is_featured or is_expanded)
	root.add_child(header_btn)
	return root

func _make_biome_text_header(
	data: Resource,
	unlocked: bool,
	is_expanded: bool,
	is_featured: bool
) -> PanelContainer:
	var dungeon_id: String = str(data.id)
	var header_wrap := PanelContainer.new()
	header_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_wrap.custom_minimum_size = BIOME_HEADER_MIN_SIZE
	header_wrap.add_theme_stylebox_override(
		"panel",
		CombatUiFrames.panel_style(
			CombatUiFrames.TIER_CARD_ACTIVE if is_featured or is_expanded else CombatUiFrames.TIER_CARD
		)
	)
	if not unlocked:
		header_wrap.modulate = Color(0.72, 0.72, 0.76, 1.0)

	var root := Control.new()
	root.custom_minimum_size = BIOME_HEADER_MIN_SIZE
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_wrap.add_child(root)

	var title_row := HBoxContainer.new()
	title_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	title_row.add_theme_constant_override("separation", 8)
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chevron_lbl := Label.new()
	chevron_lbl.text = "▼" if is_expanded else "▶"
	if not unlocked:
		chevron_lbl.text = "？"
	chevron_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chevron_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_body(chevron_lbl, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	title_row.add_child(chevron_lbl)
	var name_host := HBoxContainer.new()
	name_host.add_theme_constant_override("separation", 0)
	name_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_dungeon_title_labels(
		name_host, data, unlocked, UiTypography.SIZE_BODY_SMALL, false
	)
	title_row.add_child(name_host)
	if unlocked and str(data.route_type) == "abyss":
		var best_lbl := Label.new()
		best_lbl.text = _abyss_best_floor_text(dungeon_id)
		best_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		best_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_display(best_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_ABYSS_BEST)
		title_row.add_child(best_lbl)
	elif unlocked:
		var badge: String = _dungeon_name_badge_text(dungeon_id)
		if not badge.is_empty():
			var clear_lbl := Label.new()
			clear_lbl.text = badge
			clear_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			clear_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			UiTypography.apply_display(clear_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_CLEAR_BADGE)
			title_row.add_child(clear_lbl)
	root.add_child(title_row)

	var header_btn := Button.new()
	header_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_btn.flat = true
	header_btn.disabled = not unlocked
	header_btn.pressed.connect(_on_biome_accordion_pressed.bind(dungeon_id))
	UiTypography.apply_button(header_btn, is_featured or is_expanded)
	root.add_child(header_btn)
	return header_wrap

func _make_biome_card(data: Resource) -> PanelContainer:
	var dungeon_id: String = str(data.id)
	var unlocked: bool = GameState.is_dungeon_unlocked(dungeon_id)
	var is_featured: bool = dungeon_id == _featured_dungeon_id
	var cleared: bool = unlocked and (
		GameState.is_dungeon_tier_cleared(dungeon_id, GameState.current_dungeon_tier)
		or (
			GameState.current_dungeon_tier == _DungeonTierConfig.TIER_NORMAL
			and GameState.is_dungeon_cleared(dungeon_id)
		)
	)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.add_theme_stylebox_override(
		"panel",
		CombatUiFrames.panel_style(
			CombatUiFrames.TIER_CARD_ACTIVE if is_featured else CombatUiFrames.TIER_CARD
		)
	)
	if not unlocked:
		card.modulate = Color(0.72, 0.72, 0.76, 1.0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var thumb_tex: Texture2D = _get_dungeon_thumb_texture(dungeon_id) if unlocked else null
	var thumb_badge: String = _dungeon_name_badge_text(dungeon_id) if unlocked else ""
	## 旧カード経路: バッジ無し時は生涯クリアをリボン表示（日次枠付きは挑戦済みのみ）。
	if thumb_badge.is_empty() and cleared and not _is_daily_attempt_event(dungeon_id):
		thumb_badge = BADGE_CLEAR
	var thumb_wrap := _make_thumb_with_ribbon(thumb_tex, thumb_badge, not unlocked)
	thumb_wrap.gui_input.connect(_on_card_preview_input.bind(dungeon_id, unlocked))
	row.add_child(thumb_wrap)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	info.gui_input.connect(_on_card_preview_input.bind(dungeon_id, unlocked))
	row.add_child(info)

	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.scroll_active = false
	title.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.custom_minimum_size = Vector2(0, UiTypography.SIZE_BODY_SMALL + 6)
	_apply_stage_list_rich_text(title, unlocked)
	title.text = _dungeon_list_line_bbcode(data, unlocked)
	info.add_child(title)

	if unlocked and Constants.SUB_STAGES_PLAYABLE and _uses_stage_cards(dungeon_id):
		var stage_label: String = GameState.get_stage_progress_label(dungeon_id)
		if not stage_label.is_empty():
			var progress := Label.new()
			progress.text = stage_label
			UiTypography.apply_caption(progress)
			info.add_child(progress)

	if unlocked and not str(data.flavor_text).is_empty():
		var flavor := Label.new()
		flavor.text = str(data.flavor_text)
		flavor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flavor.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		flavor.max_lines_visible = 2
		flavor.clip_text = true
		flavor.custom_minimum_size.x = 0.0
		flavor.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		UiTypography.apply_caption(flavor, UiTypography.COLOR_MUTED)
		info.add_child(flavor)

	if unlocked:
		info.add_child(_make_enemy_icon_row(data, 1))

		var drop_row := HBoxContainer.new()
		drop_row.add_theme_constant_override("separation", 4)
		info.add_child(drop_row)
		var preview: Array = DROP_PREVIEW.get(dungeon_id, [])
		for i in mini(3, preview.size()):
			var pair: Array = preview[i]
			var tex: Texture2D = IconPaths.get_icon_texture(str(pair[1]), str(pair[0]))
			if tex != null:
				drop_row.add_child(_make_drop_icon(tex))

	var action := VBoxContainer.new()
	action.alignment = BoxContainer.ALIGNMENT_CENTER
	action.add_theme_constant_override("separation", 4)
	row.add_child(action)

	var power := Label.new()
	if unlocked:
		power.text = "推奨戦力\n%d" % _recommended_combat_power(data, 1)
	else:
		power.text = "？\n？"
	power.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(power, UiTypography.SIZE_CAPTION, COLOR_TEAL)
	action.add_child(power)
	if unlocked:
		action.add_child(_make_stars_label(int(data.difficulty)))

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(88, 40)
	if unlocked:
		if int(data.daily_attempt_limit) > 0 and not GameState.can_attempt_event_dungeon(dungeon_id):
			btn.text = BADGE_ATTEMPTED
			btn.disabled = true
			UiTypography.apply_button(btn, false)
		else:
			btn.text = "選択"
			UiTypography.apply_button(btn, is_featured)
			btn.pressed.connect(_on_select_pressed.bind(dungeon_id))
	else:
		btn.text = "？"
		btn.disabled = true
		if Constants.BETA_MOURNGATE_ONLY and str(data.route_type) == "main":
			btn.tooltip_text = "今後のアップデートで解放予定"
	action.add_child(btn)
	return card

func _dungeon_display_name(data: Resource, unlocked: bool = true) -> String:
	if data == null or not unlocked:
		return "？"
	return str(data.display_name)


## 最高到達の階表記（未到達は —）。
func _abyss_best_floor_value(dungeon_id: String) -> String:
	var best_f: int = GameState.get_abyss_highest_floor(dungeon_id)
	return ("%dF" % best_f) if best_f > 0 else "—"


## 無限ダンジョン名／章メタ横の「最高到達 XF」テキスト。
func _abyss_best_floor_text(dungeon_id: String) -> String:
	return "最高到達 %s" % _abyss_best_floor_value(dungeon_id)


func _dungeon_card_title(data: Resource, unlocked: bool = true) -> String:
	## 名前のみ。CLEAR／挑戦済みは別ラベル／BBCode で緑表示（同色連結禁止）。
	return _dungeon_display_name(data, unlocked)

## 親 Biome の配下章がすべてクリア済みか（イベント／メイン共通。章無しは Biome クリア）。
func _is_biome_fully_cleared_for_ui(dungeon_id: String) -> bool:
	if dungeon_id.is_empty() or not GameState.is_dungeon_unlocked(dungeon_id):
		return false
	if _uses_stage_cards(dungeon_id):
		var stages: Array = DataRegistry.get_stages_for_biome(dungeon_id)
		if stages.is_empty():
			return false
		for stage in stages:
			if stage == null:
				continue
			if not _is_stage_cleared_for_ui(str(stage.id)):
				return false
		return true
	if GameState.is_dungeon_tier_cleared(dungeon_id, GameState.current_dungeon_tier):
		return true
	return (
		GameState.current_dungeon_tier == _DungeonTierConfig.TIER_NORMAL
		and GameState.is_dungeon_cleared(dungeon_id)
	)

## 曜日短編など日次挑戦枠付きイベントDGか。
func _is_daily_attempt_event(dungeon_id: String) -> bool:
	if dungeon_id.is_empty():
		return false
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	return data != null and int(data.daily_attempt_limit) > 0

func _is_daily_attempt_exhausted(dungeon_id: String) -> bool:
	return (
		_is_daily_attempt_event(dungeon_id)
		and GameState.event_dungeon_attempts_remaining(dungeon_id) <= 0
	)

## ダンジョン名横バッジ。日次枠付きは枠消費後のみ「挑戦済み」（生涯 CLEAR は出さない）。
func _dungeon_name_badge_text(dungeon_id: String) -> String:
	if dungeon_id.is_empty() or not GameState.is_dungeon_unlocked(dungeon_id):
		return ""
	if _is_daily_attempt_event(dungeon_id):
		if _is_daily_attempt_exhausted(dungeon_id):
			return BADGE_ATTEMPTED
		return ""
	if _is_biome_fully_cleared_for_ui(dungeon_id):
		return BADGE_CLEAR
	return ""

func _on_card_preview_input(event: InputEvent, dungeon_id: String, unlocked: bool) -> void:
	if not unlocked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_featured_dungeon(dungeon_id)

func _recommended_combat_power(data: Resource, floor: int) -> int:
	var base_lv: int = _DungeonTierConfig.apply_tier_level(
		maxi(1, int(data.recommended_level)), GameState.current_dungeon_tier
	)
	base_lv = maxi(1, base_lv)
	return (base_lv + floor - 1) * 130 + int(data.difficulty) * 45

func _enemy_preview_ids(data: Resource, floor: int) -> Array[String]:
	var floors: int = maxi(1, int(data.floor_count))
	var ids: Array[String] = []
	if floor >= floors and not str(data.boss_id).is_empty():
		ids.append(str(data.boss_id))
	for eid in data.enemy_pool:
		if ids.size() >= 3:
			break
		var enemy_id: String = str(eid)
		if enemy_id not in ids:
			ids.append(enemy_id)
	while ids.size() < 3:
		ids.append("")
	return ids

func _make_enemy_icon_row(data: Resource, floor: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for enemy_id in _enemy_preview_ids(data, floor):
		row.add_child(_make_enemy_icon_cell(enemy_id))
	return row

func _make_enemy_icon_cell(enemy_id: String) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(ENEMY_ICON_PX, ENEMY_ICON_PX)
	frame.add_theme_stylebox_override("panel", _enemy_icon_frame_style())
	if enemy_id.is_empty():
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_size_override("font_size", 12)
		glyph.add_theme_color_override("font_color", COLOR_SUB)
		frame.add_child(glyph)
		return frame
	var tex: Texture2D = IconPaths.get_icon_texture(enemy_id, "enemy")
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_size_override("font_size", 12)
		frame.add_child(glyph)
	return frame

func _enemy_icon_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.09, 0.14, 0.95)
	style.set_border_width_all(1)
	style.border_color = Color(0.45, 0.38, 0.22, 0.65)
	style.set_corner_radius_all(ENEMY_ICON_PX / 2)
	return style

func _reset_scroll_list_top() -> void:
	if _scroll_list != null:
		_scroll_list.scroll_vertical = 0

func _get_dungeon_thumb_texture(dungeon_id: String) -> Texture2D:
	var tex: Texture2D = IconPaths.get_icon_texture(dungeon_id, "dungeon")
	if tex != null:
		return tex
	var path: String = str(DUNGEON_ICON_PATHS.get(dungeon_id, ""))
	if path.is_empty():
		path = IconPaths.ICON_MAP.get("dungeon:%s" % dungeon_id, "")
	return _load_texture_flexible(path)

func _load_texture_flexible(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var loaded: Texture2D = load(path) as Texture2D
		if loaded != null:
			return loaded
	var image := Image.new()
	if image.load(path) != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _make_thumb_with_ribbon(tex: Texture2D, badge_text: String, locked: bool) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = THUMB_SIZE
	var thumb := _make_thumb(tex, "？" if locked else "♛", THUMB_SIZE)
	thumb.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(thumb)
	if not badge_text.is_empty():
		var ribbon := _make_status_ribbon(badge_text)
		ribbon.position = Vector2(2, 2)
		wrap.add_child(ribbon)
	if locked:
		var lock := Label.new()
		lock.text = "？"
		lock.set_anchors_preset(Control.PRESET_CENTER)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock.add_theme_font_size_override("font_size", 22)
		wrap.add_child(lock)
	return wrap

func _make_status_ribbon(text: String) -> PanelContainer:
	var ribbon := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.42, 0.32, 0.05, 0.92)
	style.set_corner_radius_all(3)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	ribbon.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	UiTypography.apply_caption(label, COLOR_CLEAR_BADGE)
	ribbon.add_child(label)
	return ribbon

func _make_thumb(tex: Texture2D, fallback_glyph: String, size: Vector2 = THUMB_SIZE) -> PanelContainer:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _thumb_frame_style())
	box.custom_minimum_size = size
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = size
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = fallback_glyph
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_size_override("font_size", 24)
		box.add_child(glyph)
	return box

func _thumb_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.13, 0.9)
	style.set_border_width_all(1)
	style.border_color = Color(0.45, 0.38, 0.2, 0.7)
	style.set_corner_radius_all(6)
	return style

func _make_drop_icon(tex: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = DROP_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

func _make_stars_text(difficulty: int) -> String:
	var filled: int = clampi(difficulty, 1, MAX_STARS)
	var text: String = ""
	for i in MAX_STARS:
		text += "★" if i < filled else "☆"
	return text

func _make_stars_label(difficulty: int) -> Label:
	var label := Label.new()
	label.text = _make_stars_text(difficulty)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(label, UiTypography.SIZE_CAPTION, Color(0.95, 0.78, 0.3))
	return label

func _on_featured_select_pressed() -> void:
	_prompt_enter_dungeon(_featured_dungeon_id)

func _prompt_enter_dungeon(dungeon_id: String) -> void:
	if dungeon_id.is_empty() or DataRegistry.get_dungeon_data(dungeon_id) == null:
		return
	if not GameState.is_dungeon_unlocked(dungeon_id):
		return
	if not GameState.can_attempt_event_dungeon(dungeon_id):
		return
	if not _party_has_adventurer():
		_show_party_empty_notice()
		return
	if _uses_stage_cards(dungeon_id):
		if _selected_stage_id.is_empty() or not GameState.is_stage_unlocked(_selected_stage_id):
			return
	_pending_enter_dungeon_id = dungeon_id
	_show_enter_confirm()

func _on_enter_confirmed() -> void:
	_hide_enter_confirm()
	_do_enter_dungeon(_pending_enter_dungeon_id)

func _on_select_pressed(dungeon_id: String) -> void:
	_prompt_enter_dungeon(dungeon_id)

func _do_enter_dungeon(dungeon_id: String) -> void:
	if DataRegistry.get_dungeon_data(dungeon_id) == null:
		return
	if not GameState.is_dungeon_unlocked(dungeon_id):
		return
	if not _party_has_adventurer():
		_show_party_empty_notice()
		return
	if not GameState.consume_event_dungeon_attempt(dungeon_id):
		return
	GameState.current_dungeon_id = dungeon_id
	_featured_dungeon_id = dungeon_id
	_clamp_selected_tier()
	_sync_selected_stage_for_biome(dungeon_id)
	if _uses_stage_cards(dungeon_id):
		GameState.current_stage_id = _selected_stage_id
	else:
		GameState.current_stage_id = ""
	SaveManager.save_game()
	SceneRouter.change_scene(DUNGEON_SCENE)

func _go_home() -> void:
	SceneRouter.change_scene(HOME_SCENE)
