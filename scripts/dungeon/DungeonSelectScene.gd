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
@onready var _label_featured_name: Label = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedInfo/LabelFeaturedName
@onready var _label_featured_flavor: Label = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedInfo/LabelFeaturedFlavor
@onready var _label_featured_meta: Label = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedInfo/LabelFeaturedMeta
@onready var _label_featured_discovery: Label = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedInfo/LabelFeaturedDiscovery
@onready var _featured_drop_row: HBoxContainer = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedDropRow
@onready var _btn_featured_select: Button = $MainColumn/FeaturedPanel/FeaturedVBox/FeaturedActionRow/BtnFeaturedSelect
@onready var _scroll_list: ScrollContainer = $MainColumn/ScrollList
@onready var _list: VBoxContainer = $MainColumn/ScrollList/ListVBox
@onready var _footer_panel: PanelContainer = $FooterPanel
@onready var _label_bonus_value: Label = $FooterPanel/FooterRow/BonusCol/LabelBonusValue
@onready var _label_bonus_timer: Label = $FooterPanel/FooterRow/BonusCol/LabelBonusTimer

var _featured_dungeon_id: String = ""

func _ready() -> void:
	UiTypography.apply_screen_title($MainColumn/Header/HeaderRow/LabelTitle)
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.ADVENTURE)
	_btn_back.pressed.connect(_go_home)
	_btn_featured_select.pressed.connect(_on_featured_select_pressed)
	_btn_tier_normal.pressed.connect(_on_tier_pressed.bind(_DungeonTierConfig.TIER_NORMAL))
	_btn_tier_hard.pressed.connect(_on_tier_pressed.bind(_DungeonTierConfig.TIER_HARD))
	_btn_tier_nightmare.pressed.connect(_on_tier_pressed.bind(_DungeonTierConfig.TIER_NIGHTMARE))
	if EventSystem.has_signal("event_updated"):
		EventSystem.event_updated.connect(_refresh_event_footer)
	_featured_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	_featured_panel.clip_contents = true
	_footer_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	_apply_typography()
	_refresh_all()

func _apply_typography() -> void:
	UiTypography.apply_button(_btn_back, false)
	UiTypography.apply_button(_btn_featured_select)
	UiTypography.apply_body(_label_gold, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_token, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_display(_label_featured_name, UiTypography.SIZE_BODY_SMALL)
	UiTypography.apply_body(_label_featured_flavor, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB)
	UiTypography.apply_body(_label_featured_meta, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	UiTypography.apply_body(_label_featured_discovery, UiTypography.SIZE_BODY_SMALL, COLOR_CLEAR)
	UiTypography.apply_body(_label_bonus_value, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_caption(_label_bonus_timer)

func _refresh_all() -> void:
	_featured_dungeon_id = _resolve_featured_dungeon_id()
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

func _refresh_event_footer() -> void:
	var event_data: Resource = EventSystem.get_active_event()
	if event_data == null:
		_footer_panel.visible = false
		return
	_footer_panel.visible = true
	var summary: String = EventSystem.active_modifier_summary()
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
	_featured_panel.visible = true
	_label_featured_name.text = str(data.display_name)
	_label_featured_flavor.text = str(data.flavor_text)
	_label_featured_flavor.visible = not str(data.flavor_text).is_empty()

	var meta_parts: Array[String] = []
	meta_parts.append(_DungeonTierConfig.display_name(GameState.current_dungeon_tier))
	var tier_summary: String = _DungeonTierConfig.summary_text(GameState.current_dungeon_tier)
	if not tier_summary.is_empty():
		meta_parts.append(tier_summary)
	if int(data.recommended_level) > 0:
		meta_parts.append("推奨Lv.%d〜" % int(data.recommended_level))
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
		_label_featured_discovery.text += " · %s CLEAR済" % _DungeonTierConfig.display_name(
			GameState.current_dungeon_tier
		)
	elif GameState.is_dungeon_cleared(_featured_dungeon_id):
		_label_featured_discovery.text += " · ノーマル CLEAR済"

	_populate_drop_row(_featured_drop_row, _featured_dungeon_id, 4)
	var unlocked: bool = GameState.is_dungeon_unlocked(_featured_dungeon_id)
	_btn_featured_select.text = "選択して出発"
	_btn_featured_select.disabled = not unlocked

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
	_clamp_selected_tier()
	_refresh_tier_tabs()
	_refresh_featured()
	_build_list()

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
			_list.add_child(_make_biome_card(data))
	if not sides.is_empty():
		_list.add_child(_make_section_header("寄り道"))
		for data in sides:
			_list.add_child(_make_biome_card(data))
	if not apexes.is_empty():
		_list.add_child(_make_section_header("最果て"))
		for data in apexes:
			_list.add_child(_make_biome_card(data))

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
	margin.add_child(header)
	return margin

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

	var title := Label.new()
	title.text = _dungeon_card_title(data)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_display(
		title,
		UiTypography.SIZE_BODY_SMALL,
		UiTypography.COLOR_GOLD if unlocked else UiTypography.COLOR_SUB
	)
	info.add_child(title)

	if int(data.recommended_level) > 0:
		var lv := Label.new()
		lv.text = "推奨Lv.%d〜" % int(data.recommended_level)
		UiTypography.apply_caption(lv)
		info.add_child(lv)

	if not str(data.flavor_text).is_empty():
		var flavor := Label.new()
		flavor.text = str(data.flavor_text)
		flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		flavor.max_lines_visible = 2
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
	label.text = "CLEAR"
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
	_on_select_pressed(_featured_dungeon_id)

func _on_select_pressed(dungeon_id: String) -> void:
	if DataRegistry.get_dungeon_data(dungeon_id) == null:
		return
	if not GameState.is_dungeon_unlocked(dungeon_id):
		return
	GameState.current_dungeon_id = dungeon_id
	_featured_dungeon_id = dungeon_id
	_clamp_selected_tier()
	SceneRouter.change_scene(DUNGEON_SCENE)

func _go_home() -> void:
	SceneRouter.change_scene(HOME_SCENE)
