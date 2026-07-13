extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const DUNGEON_SELECT_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"

const _ElementResolver: Script = preload("res://scripts/combat/ElementResolver.gd")
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")

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
	"mourngate_deep": "res://assets/dungeon/mourngate/ICO_DG_Mourngate.png",
}

const COLOR_GOLD: Color = Color(0.95, 0.84, 0.4, 1)
const COLOR_SUB: Color = Color(0.78, 0.74, 0.6, 1)
const COLOR_CLEAR: Color = Color(0.45, 0.92, 0.55, 1)
const COLOR_TEAL: Color = Color(0.6, 0.82, 0.78, 1)

const DROP_PREVIEW: Dictionary = {
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
	"mourngate_deep": [
		["weapon", "storm_edge"],
		["armor", "mourngate_plate"],
		["accessory", "clockwing_brooch"],
	],
	"storm_crown_ruins": [
		["weapon", "consecrated_maul"],
		["armor", "lament_guard_mail"],
		["accessory", "pilgrim_lantern_charm"],
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
@onready var _scroll_list: ScrollContainer = $MainColumn/ScrollList
@onready var _list: VBoxContainer = $MainColumn/ScrollList/ListVBox
@onready var _footer_panel: PanelContainer = $FooterPanel
@onready var _bonus_col: VBoxContainer = $FooterPanel/FooterRow/BonusCol
@onready var _label_bonus_value: Label = $FooterPanel/FooterRow/BonusCol/LabelBonusValue
@onready var _label_bonus_timer: Label = $FooterPanel/FooterRow/BonusCol/LabelBonusTimer

var _featured_dungeon_id: String = ""
var _selected_stage_id: String = ""
var _expanded_biome_id: String = ""
var _pending_enter_dungeon_id: String = ""
var _enter_confirm_overlay: Control
var _enter_confirm_yes: Button
var _enter_confirm_no: Button

const STAGE_CARD_MIN_SIZE: Vector2 = Vector2(136, 78)
const STAGE_THUMB_SIZE: Vector2 = Vector2(44, 44)
const BIOME_HEADER_MIN_SIZE: Vector2 = Vector2(0, 112)
## 一覧アコーディオン上の Biome バナー想定幅（高さはテクスチャ縦横比から算出）
const BIOME_BANNER_LIST_WIDTH: float = 680.0
const BIOME_BANNER_HEIGHT_MIN: float = 112.0
const BIOME_BANNER_HEIGHT_MAX: float = 240.0
const BIOME_BANNER_HEIGHT: float = 112.0
## 空 = バナー画像を使わずテキスト見出し（▶ ダンジョン名）に戻す。
## 雰囲気BGのみ（文字は UI ラベル重ね）。表示高さはテクスチャ比で ~112px（680幅時）。
const BIOME_BANNER_PATHS: Dictionary = {
	"mourngate": "res://assets/ui/dungeon/BAN_DG_Mourngate.png",
	"whisperwood": "res://assets/ui/dungeon/BAN_DG_Whisperwood.png",
	"mistfen": "res://assets/ui/dungeon/BAN_DG_Mistfen.png",
	"blackshore": "res://assets/ui/dungeon/BAN_DG_Blackshore.png",
	"frostridge": "res://assets/ui/dungeon/BAN_DG_Frostridge.png",
}
## バナー画像にダンジョン名が焼き込まれている Biome（UI タイトルラベルを非表示）
const BIOME_BANNER_TITLE_BAKED: Dictionary = {}
func _ready() -> void:
	$MainColumn/Header/HeaderRow/LabelTitle.text = ""
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.ADVENTURE)
	_btn_back.pressed.connect(_go_home)
	_btn_featured_select.pressed.connect(_on_featured_select_pressed)
	_btn_tier_normal.pressed.connect(_on_tier_pressed.bind(_DungeonTierConfig.TIER_NORMAL))
	_btn_tier_hard.pressed.connect(_on_tier_pressed.bind(_DungeonTierConfig.TIER_HARD))
	_btn_tier_nightmare.pressed.connect(_on_tier_pressed.bind(_DungeonTierConfig.TIER_NIGHTMARE))
	if EventSystem.PERIODIC_EVENTS_ENABLED and EventSystem.has_signal("event_updated"):
		EventSystem.event_updated.connect(_refresh_event_footer)
	_featured_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	_featured_panel.clip_contents = false
	_footer_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	_apply_typography()
	_setup_enter_confirm()
	_refresh_all()

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
	UiTypography.apply_body(_label_gold, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_token, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_display(_label_featured_name, UiTypography.SIZE_BODY_SMALL)
	UiTypography.apply_body(_label_featured_flavor, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	UiTypography.apply_body(_label_featured_meta, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	UiTypography.apply_body(_label_featured_discovery, UiTypography.SIZE_BODY_SMALL, COLOR_CLEAR)
	UiTypography.apply_body(_label_bonus_value, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_caption(_label_bonus_timer)

func _refresh_all() -> void:
	_featured_dungeon_id = _resolve_featured_dungeon_id()
	if _expanded_biome_id.is_empty() and _uses_stage_cards(_featured_dungeon_id):
		_expanded_biome_id = _featured_dungeon_id
	_clamp_selected_tier()
	_update_currency()
	_refresh_tier_tabs()
	_refresh_featured()
	_refresh_event_footer()
	_build_list()
	call_deferred("_reset_scroll_list_top")

func _clamp_selected_tier() -> void:
	if _featured_dungeon_id.is_empty():
		_featured_dungeon_id = _resolve_featured_dungeon_id()
	var dungeon_id: String = _featured_dungeon_id
	if dungeon_id.is_empty():
		return
	var tier: int = _DungeonTierConfig.clamp_tier(GameState.current_dungeon_tier)
	while tier > _DungeonTierConfig.TIER_NORMAL and not GameState.is_dungeon_tier_unlocked(dungeon_id, tier):
		tier -= 1
	GameState.current_dungeon_tier = tier

func _refresh_tier_tabs() -> void:
	var dungeon_id: String = _featured_dungeon_id
	var buttons: Array[Button] = [_btn_tier_normal, _btn_tier_hard, _btn_tier_nightmare]
	for tier in _DungeonTierConfig.TIER_COUNT:
		var btn: Button = buttons[tier]
		var unlocked: bool = GameState.is_dungeon_tier_unlocked(dungeon_id, tier)
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
		UiTypography.apply_button(btn, selected)

func _on_tier_pressed(tier: int) -> void:
	var dungeon_id: String = _featured_dungeon_id
	if not GameState.is_dungeon_tier_unlocked(dungeon_id, tier):
		return
	GameState.current_dungeon_tier = _DungeonTierConfig.clamp_tier(tier)
	_refresh_tier_tabs()
	_refresh_featured()
	_build_list()

func _uses_stage_cards(dungeon_id: String) -> bool:
	if not Constants.SUB_STAGES_PLAYABLE or dungeon_id.is_empty():
		return false
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	if data == null or str(data.route_type) != "main":
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
	var parts: Array[String] = ["%dF" % int(stage.floor_count)]
	if int(stage.recommended_level) > 0:
		parts.append("推奨Lv%d" % int(stage.recommended_level))
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
	var name: String = str(stage.display_name)
	var meta: String = _format_stage_meta_text(stage)
	var name_color: String = "f5e07a" if unlocked else "c9c4b8"
	return "[color=#%s][b]%s[/b][/color]  [color=#e0dcd0]%s[/color]" % [name_color, name, meta]

func _dungeon_list_line_bbcode(data: Resource, unlocked: bool) -> String:
	var name: String = _dungeon_card_title(data)
	var parts: Array[String] = []
	if int(data.floor_count) > 0:
		parts.append("%dF" % int(data.floor_count))
	if int(data.recommended_level) > 0:
		parts.append("推奨Lv%d〜" % int(data.recommended_level))
	var meta: String = "  ".join(parts)
	var name_color: String = "f5e07a" if unlocked else "c9c4b8"
	if meta.is_empty():
		return "[color=#%s][b]%s[/b][/color]" % [name_color, name]
	return "[color=#%s][b]%s[/b][/color]  [color=#e0dcd0]%s[/color]" % [name_color, name, meta]

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
	line.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.custom_minimum_size.y = UiTypography.SIZE_BODY_SMALL + 6
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_stage_list_rich_text(line, unlocked)
	line.text = _stage_list_line_bbcode(stage, unlocked)
	text_col.add_child(line)
	var status_text: String = ""
	if not unlocked:
		status_text = "🔒 未解放"
	elif cleared:
		status_text = "✓ クリア"
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
		UiTypography.apply_caption(status, COLOR_CLEAR if cleared else UiTypography.COLOR_SUB)
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
		return
	var event_data: Resource = EventSystem.get_active_event()
	if event_data == null:
		_footer_panel.visible = false
		_bonus_col.visible = false
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
	_label_bonus_timer.text = "残り %s" % EventSystem.countdown_text()

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
	if title_baked:
		_label_featured_name.visible = stage != null and _uses_stage_cards(_featured_dungeon_id)
		_label_featured_name.text = str(stage.display_name) if stage != null else ""
	elif stage != null and _uses_stage_cards(_featured_dungeon_id):
		_label_featured_name.visible = true
		_label_featured_name.text = "%s — %s" % [str(data.display_name), str(stage.display_name)]
	else:
		_label_featured_name.visible = true
		_label_featured_name.text = str(data.display_name)
	_label_featured_flavor.text = str(data.flavor_text)
	_label_featured_flavor.visible = not str(data.flavor_text).is_empty()

	var meta_parts: Array[String] = []
	if stage != null and _uses_stage_cards(_featured_dungeon_id):
		if not title_baked:
			meta_parts.append(str(stage.display_name))
		meta_parts.append("%dF" % int(stage.floor_count))
		if int(stage.recommended_level) > 0:
			meta_parts.append("推奨Lv%d" % int(stage.recommended_level))
		if bool(stage.has_boss_floor()):
			meta_parts.append("ボス")
		elif bool(stage.requires_elite):
			meta_parts.append("エリート")
	meta_parts.append(_DungeonTierConfig.display_name(GameState.current_dungeon_tier))
	var tier_summary: String = _DungeonTierConfig.summary_text(GameState.current_dungeon_tier)
	if not tier_summary.is_empty():
		meta_parts.append(tier_summary)
	if int(data.recommended_level) > 0 and (stage == null or not _uses_stage_cards(_featured_dungeon_id)):
		meta_parts.append("推奨Lv%d〜" % int(data.recommended_level))
	if _uses_stage_cards(_featured_dungeon_id):
		var stage_label: String = GameState.get_stage_progress_label(_featured_dungeon_id)
		if not stage_label.is_empty():
			meta_parts.append(stage_label)
	meta_parts.append(_make_stars_text(int(data.difficulty)))
	if not str(data.favored_element).is_empty():
		meta_parts.append("%s 有利" % _ElementResolver.get_display_name(str(data.favored_element)))
	var policy: String = GameState.get_exploration_policy()
	if not policy.is_empty():
		meta_parts.append("方針:%s" % GameState.exploration_policy_label(policy))
	_label_featured_meta.text = " · ".join(meta_parts)

	var discovery_pct: int = _discovery_percent(_featured_dungeon_id)
	_label_featured_discovery.text = "発見率 %d%%" % discovery_pct
	if GameState.is_dungeon_tier_cleared(_featured_dungeon_id, GameState.current_dungeon_tier):
		_label_featured_discovery.text += " · %s クリア済" % _DungeonTierConfig.display_name(
			GameState.current_dungeon_tier
		)
	elif GameState.is_dungeon_cleared(_featured_dungeon_id):
		_label_featured_discovery.text += " · ノーマル クリア済"

	_populate_drop_row(_featured_drop_row, _featured_dungeon_id, 4)
	var unlocked: bool = GameState.is_dungeon_unlocked(_featured_dungeon_id)
	var stage_ready: bool = (
		not _uses_stage_cards(_featured_dungeon_id)
		or (
			not _selected_stage_id.is_empty()
			and GameState.is_stage_unlocked(_selected_stage_id)
		)
	)
	_btn_featured_select.text = "選択して出発"
	_btn_featured_select.disabled = not unlocked or not stage_ready

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
	_sync_selected_stage_for_biome(dungeon_id)
	GameState.current_stage_id = _selected_stage_id
	_clamp_selected_tier()
	_refresh_tier_tabs()
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
	var mains: Array = _sorted_dungeons("main")
	var sides: Array = _sorted_dungeons("side")
	var apexes: Array = _sorted_dungeons("apex")
	if mains.is_empty() and sides.is_empty() and apexes.is_empty():
		return
	if not mains.is_empty():
		_list.add_child(_make_section_header("メインルート"))
		for data in mains:
			if _uses_stage_cards(str(data.id)):
				_list.add_child(_make_biome_accordion(data))
			else:
				_list.add_child(_make_biome_card(data))
	if not sides.is_empty():
		_list.add_child(_make_section_header("寄り道"))
		for data in sides:
			_list.add_child(_make_biome_card(data))
	if not apexes.is_empty():
		_list.add_child(_make_section_header("最果て"))
		for data in apexes:
			_list.add_child(_make_biome_card(data))
	# 末尾バナーがフッター／下ナビで見切れないようスクロール余白を確保
	_list.add_child(_make_list_bottom_spacer())

func _make_list_bottom_spacer() -> Control:
	var spacer := Control.new()
	spacer.name = "ListBottomSpacer"
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.custom_minimum_size = Vector2(0, BIOME_BANNER_HEIGHT + 16)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer

func _sorted_dungeons(route_type: String) -> Array:
	if not Constants.is_playable_dungeon_route(route_type):
		return []
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
	if banner_tex != null:
		outer.add_child(_make_biome_banner_header(data, banner_tex, unlocked, is_expanded, is_featured))
	else:
		outer.add_child(_make_biome_text_header(data, unlocked, is_expanded, is_featured))

	if is_expanded:
		var stages_box := VBoxContainer.new()
		stages_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stages_box.add_theme_constant_override("separation", 4)
		for stage in DataRegistry.get_stages_for_biome(dungeon_id):
			if stage != null:
				stages_box.add_child(_make_stage_card(stage))
		outer.add_child(stages_box)
	return outer

func _get_biome_banner_texture(dungeon_id: String) -> Texture2D:
	var path: String = str(BIOME_BANNER_PATHS.get(dungeon_id, ""))
	if path.is_empty():
		return null
	return _load_texture_flexible(path)

func _biome_banner_header_size(banner_tex: Texture2D) -> Vector2:
	if banner_tex == null:
		return BIOME_HEADER_MIN_SIZE
	var tw: int = banner_tex.get_width()
	var th: int = banner_tex.get_height()
	if tw <= 0 or th <= 0:
		return BIOME_HEADER_MIN_SIZE
	var height: float = BIOME_BANNER_LIST_WIDTH * float(th) / float(tw)
	height = clampf(height, BIOME_BANNER_HEIGHT_MIN, BIOME_BANNER_HEIGHT_MAX)
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
	var label := Label.new()
	label.text = str(data.display_name)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not unlocked:
		label.modulate = Color(0.72, 0.72, 0.76, 1.0)
	UiTypography.apply_display(
		label,
		UiTypography.SIZE_BODY_SMALL,
		UiTypography.COLOR_GOLD if unlocked else UiTypography.COLOR_SUB
	)
	margin.add_child(label)
	return margin

func _sync_featured_banner(dungeon_id: String) -> void:
	for child in _featured_banner_host.get_children():
		child.queue_free()
	# 一覧側に Biome バナーがある場合は Featured 上段の重複バナーを出さない。
	if _uses_list_biome_banner(dungeon_id):
		_featured_banner_host.visible = false
		_featured_banner_host.custom_minimum_size = Vector2.ZERO
		return
	var banner_tex: Texture2D = _get_biome_banner_texture(dungeon_id)
	if banner_tex == null:
		_featured_banner_host.visible = false
		_featured_banner_host.custom_minimum_size = Vector2.ZERO
		return
	_featured_banner_host.visible = true
	_featured_banner_host.custom_minimum_size = Vector2(0, BIOME_BANNER_HEIGHT)
	var banner := TextureRect.new()
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.texture = banner_tex
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_featured_banner_host.add_child(banner)

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
	root.custom_minimum_size = _biome_banner_header_size(banner_tex)
	if not unlocked:
		root.modulate = Color(0.72, 0.72, 0.76, 1.0)

	var banner := TextureRect.new()
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.texture = banner_tex
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner)

	var header_btn := Button.new()
	header_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_btn.flat = true
	header_btn.disabled = not unlocked
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_top = 4
	row.offset_right = -8
	row.offset_bottom = -4
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_btn.add_child(row)

	var chevron := Label.new()
	chevron.text = "▼" if is_expanded else "▶"
	if not unlocked:
		chevron.text = "🔒"
	chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# バナー上でも視認できるよう金＋影を強める
	UiTypography.apply_body(chevron, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	chevron.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
	chevron.add_theme_constant_override("shadow_offset_x", 1)
	chevron.add_theme_constant_override("shadow_offset_y", 1)
	chevron.add_theme_constant_override("shadow_outline_size", 4)
	row.add_child(chevron)

	if not _banner_hides_title(dungeon_id):
		var title := Label.new()
		title.text = _dungeon_card_title(data)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.max_lines_visible = 1
		title.clip_text = true
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_display(
			title,
			UiTypography.SIZE_BODY,
			UiTypography.COLOR_GOLD if unlocked else UiTypography.COLOR_SUB
		)
		title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
		title.add_theme_constant_override("shadow_offset_x", 1)
		title.add_theme_constant_override("shadow_offset_y", 1)
		title.add_theme_constant_override("shadow_outline_size", 5)
		row.add_child(title)

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

	var header_btn := Button.new()
	header_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_btn.flat = true
	header_btn.disabled = not unlocked
	header_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var chevron: String = "▼" if is_expanded else "▶"
	if not unlocked:
		chevron = "🔒"
	header_btn.text = "%s  %s" % [chevron, _dungeon_card_title(data)]
	header_btn.pressed.connect(_on_biome_accordion_pressed.bind(dungeon_id))
	UiTypography.apply_button(header_btn, is_featured or is_expanded)
	header_wrap.add_child(header_btn)
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

	var thumb_tex: Texture2D = _get_dungeon_thumb_texture(dungeon_id)
	var thumb_wrap := _make_thumb_with_ribbon(thumb_tex, cleared, not unlocked)
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
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.custom_minimum_size.y = UiTypography.SIZE_BODY_SMALL + 6
	_apply_stage_list_rich_text(title, unlocked)
	title.text = _dungeon_list_line_bbcode(data, unlocked)
	info.add_child(title)

	if Constants.SUB_STAGES_PLAYABLE and str(data.route_type) == "main":
		var stage_label: String = GameState.get_stage_progress_label(dungeon_id)
		if not stage_label.is_empty():
			var progress := Label.new()
			progress.text = stage_label
			UiTypography.apply_caption(progress)
			info.add_child(progress)

	if not str(data.flavor_text).is_empty():
		var flavor := Label.new()
		flavor.text = str(data.flavor_text)
		flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		flavor.max_lines_visible = 2
		flavor.clip_text = true
		flavor.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		UiTypography.apply_caption(flavor, UiTypography.COLOR_MUTED)
		info.add_child(flavor)

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
	power.text = "推奨戦力\n%d" % _recommended_combat_power(data, 1)
	power.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(power, UiTypography.SIZE_CAPTION, COLOR_TEAL)
	action.add_child(power)
	action.add_child(_make_stars_label(int(data.difficulty)))

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(88, 40)
	if unlocked:
		btn.text = "選択"
		UiTypography.apply_button(btn, is_featured)
		btn.pressed.connect(_on_select_pressed.bind(dungeon_id))
	else:
		btn.text = "ロック中"
		btn.disabled = true
	action.add_child(btn)
	return card

func _dungeon_card_title(data: Resource) -> String:
	var route: String = str(data.route_type)
	if route == "side":
		return "寄 %s" % str(data.display_name)
	if route == "apex":
		return "征 %s" % str(data.display_name)
	return str(data.display_name)

func _on_card_preview_input(event: InputEvent, dungeon_id: String, unlocked: bool) -> void:
	if not unlocked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_featured_dungeon(dungeon_id)

func _recommended_combat_power(data: Resource, floor: int) -> int:
	var base_lv: int = maxi(1, int(data.recommended_level))
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

func _make_thumb_with_ribbon(tex: Texture2D, show_clear: bool, locked: bool) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = THUMB_SIZE
	var thumb := _make_thumb(tex, "🔒" if locked else "♛", THUMB_SIZE)
	thumb.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(thumb)
	if show_clear:
		var ribbon := _make_clear_ribbon()
		ribbon.position = Vector2(2, 2)
		wrap.add_child(ribbon)
	if locked:
		var lock := Label.new()
		lock.text = "🔒"
		lock.set_anchors_preset(Control.PRESET_CENTER)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock.add_theme_font_size_override("font_size", 22)
		wrap.add_child(lock)
	return wrap

func _make_clear_ribbon() -> PanelContainer:
	var ribbon := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.45, 0.22, 0.92)
	style.set_corner_radius_all(3)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	ribbon.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "クリア"
	UiTypography.apply_caption(label, COLOR_CLEAR)
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
	GameState.current_dungeon_id = dungeon_id
	_featured_dungeon_id = dungeon_id
	_clamp_selected_tier()
	_sync_selected_stage_for_biome(dungeon_id)
	if _uses_stage_cards(dungeon_id):
		GameState.current_stage_id = _selected_stage_id
	else:
		GameState.current_stage_id = ""
	SceneRouter.change_scene(DUNGEON_SCENE)

func _go_home() -> void:
	SceneRouter.change_scene(HOME_SCENE)
