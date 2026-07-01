extends Control

const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"
const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"

const COLOR_GOLD: Color = Color(0.85, 0.74, 0.45, 1)
const COLOR_TEXT: Color = Color(0.82, 0.84, 0.9, 1)
const COLOR_SUB: Color = Color(0.6, 0.62, 0.7, 1)

const COLOR_FAIL: Color = Color(0.82, 0.45, 0.42, 1)
const COLOR_RETIRE: Color = Color(0.72, 0.8, 0.95, 1)

@onready var _label_title: Label = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/LabelTitle
@onready var _label_dungeon: Label = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/LabelDungeon
@onready var _label_outcome: Label = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/LabelClear
@onready var _stars_row: HBoxContainer = $Scroll/Margin/Main/HeaderPanel/HeaderVBox/StarsRow
@onready var _reward_row: HBoxContainer = $Scroll/Margin/Main/RewardPanel/RewardVBox/RewardRow
@onready var _material_panel: PanelContainer = $Scroll/Margin/Main/MaterialPanel
@onready var _material_row: HBoxContainer = $Scroll/Margin/Main/MaterialPanel/MaterialVBox/MaterialRow
@onready var _label_craftable: Label = $Scroll/Margin/Main/MaterialPanel/MaterialVBox/LabelCraftable
@onready var _rare_panel: PanelContainer = $Scroll/Margin/Main/RarePanel
@onready var _rare_list: VBoxContainer = $Scroll/Margin/Main/RarePanel/RareVBox/RareList
@onready var _info_grid: GridContainer = $Scroll/Margin/Main/InfoPanel/InfoVBox/InfoGrid
@onready var _levelup_panel: PanelContainer = $Scroll/Margin/Main/LevelUpPanel
@onready var _label_levelup: Label = $Scroll/Margin/Main/LevelUpPanel/LabelLevelUp
@onready var _button_retry: Button = $FooterRow/Footer/ButtonRetry
@onready var _button_home: Button = $FooterRow/Footer/ButtonHome
@onready var _header_panel: PanelContainer = $Scroll/Margin/Main/HeaderPanel
@onready var _reward_panel: PanelContainer = $Scroll/Margin/Main/RewardPanel
@onready var _info_panel: PanelContainer = $Scroll/Margin/Main/InfoPanel

var _rewards_banked: bool = false

func _ready() -> void:
	_apply_panel_styles()
	_bank_rewards()
	_build_header()
	_build_rewards()
	_build_materials()
	_build_rare_items()
	_build_info()
	_build_levelup()
	_button_retry.pressed.connect(_on_retry_pressed)
	_button_home.pressed.connect(_on_home_pressed)

func _apply_panel_styles() -> void:
	_header_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	for panel in [_reward_panel, _material_panel, _rare_panel, _info_panel, _levelup_panel]:
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
	if data != null:
		var dn: Variant = data.get("display_name")
		if dn is String and not (dn as String).is_empty():
			name_text = dn
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
	_label_title.text = "探索結果"
	match outcome:
		GameState.RUN_OUTCOME_RETIRE:
			_label_outcome.text = "リタイア帰還"
			_label_outcome.add_theme_font_size_override("font_size", 44)
			_label_outcome.add_theme_color_override("font_color", COLOR_RETIRE)
		GameState.RUN_OUTCOME_WIPE:
			_label_outcome.text = "探索失敗"
			_label_outcome.add_theme_font_size_override("font_size", 44)
			_label_outcome.add_theme_color_override("font_color", COLOR_FAIL)
		_:
			_label_outcome.text = "CLEAR"
			_label_outcome.add_theme_font_size_override("font_size", 56)
			_label_outcome.add_theme_color_override("font_color", COLOR_GOLD)

func _build_stars(filled: int) -> void:
	for child in _stars_row.get_children():
		child.queue_free()
	var total: int = 3
	var n: int = clampi(filled, 0, total)
	for i in range(total):
		var star: Label = Label.new()
		star.text = "★" if i < n else "☆"
		star.add_theme_font_size_override("font_size", 28)
		star.add_theme_color_override("font_color", COLOR_GOLD if i < n else COLOR_SUB)
		_stars_row.add_child(star)

func _build_rewards() -> void:
	for child in _reward_row.get_children():
		child.queue_free()
	_reward_row.add_child(_make_reward_cell(null, "EXP", "EXP", str(GameState.last_run_exp_reward)))
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
			IconPaths.get_icon_texture(weapon, "weapon"), "", DataRegistry.get_weapon_name(weapon), "1"))
	var armor: String = GameState.last_run_armor_dropped
	if not armor.is_empty():
		_reward_row.add_child(_make_reward_cell(
			IconPaths.get_icon_texture(armor, "armor"), "", DataRegistry.get_armor_name(armor), "1"))
	var accessory: String = GameState.last_run_accessory_dropped
	if not accessory.is_empty():
		_reward_row.add_child(_make_reward_cell(
			IconPaths.get_icon_texture(accessory, "accessory"), "", DataRegistry.get_accessory_name(accessory), "1"))
	var relic: String = GameState.last_run_relic_dropped
	if not relic.is_empty():
		_reward_row.add_child(_make_reward_cell(
			null, "遺", CombatRelics.display_name(relic), "1"))

func _make_reward_cell(texture: Texture2D, glyph: String, name_text: String, value_text: String) -> Control:
	var cell: VBoxContainer = VBoxContainer.new()
	cell.custom_minimum_size = Vector2(86, 0)
	cell.alignment = BoxContainer.ALIGNMENT_BEGIN
	var frame: PanelContainer = PanelContainer.new()
	frame.custom_minimum_size = Vector2(64, 64)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	if texture != null:
		var icon: TextureRect = TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.add_child(icon)
	else:
		var glyph_label: Label = Label.new()
		glyph_label.text = glyph
		glyph_label.add_theme_font_size_override("font_size", 22)
		glyph_label.add_theme_color_override("font_color", COLOR_GOLD)
		glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		frame.add_child(glyph_label)
	cell.add_child(frame)
	var name_label: Label = Label.new()
	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", COLOR_SUB)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cell.add_child(name_label)
	var value_label: Label = Label.new()
	value_label.text = value_text
	value_label.add_theme_font_size_override("font_size", 17)
	value_label.add_theme_color_override("font_color", COLOR_TEXT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
		var icon: Texture2D = IconPaths.get_icon_texture(mat_key, "material")
		var glyph: String = "材"
		if icon == null and not mat_key.is_empty():
			glyph = mat_key.substr(0, 1)
		_material_row.add_child(_make_reward_cell(
			icon,
			glyph,
			DataRegistry.get_material_name(mat_key),
			str(qty),
		))
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
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var icon: TextureRect = TextureRect.new()
	icon.texture = IconPaths.get_icon_texture(item_id, category)
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label: Label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	col.add_child(name_label)
	if not desc.is_empty():
		var desc_label: Label = Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", COLOR_SUB)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(desc_label)
	row.add_child(col)
	var star: Label = Label.new()
	star.text = "★"
	star.add_theme_font_size_override("font_size", 20)
	star.add_theme_color_override("font_color", COLOR_GOLD)
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(star)
	_rare_list.add_child(row)
	return 1

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
	var dungeon_id: String = GameState.get_active_dungeon_id()
	var prog: Dictionary = GameState.dungeon_progress.get(dungeon_id, {})
	var discovery_pct: int = int(round(float(prog.get("discovery", 0.0)) * 100.0))
	_add_info_pair("発見率", "%d%%" % discovery_pct)
	_add_info_pair("入手経験値", "%d EXP" % GameState.last_run_exp_reward)
	_add_info_pair("入手ゴールド", "%d G" % GameState.last_run_gold_reward)
	if GameState.last_run_token_reward > 0:
		_add_info_pair("入手%s" % CurrencyHelper.DISPLAY_NAME, "%d" % GameState.last_run_token_reward)

func _add_info_pair(key: String, value: String) -> void:
	var key_label: Label = Label.new()
	key_label.text = key
	key_label.add_theme_font_size_override("font_size", 15)
	key_label.add_theme_color_override("font_color", COLOR_SUB)
	_info_grid.add_child(key_label)
	var value_label: Label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 15)
	value_label.add_theme_color_override("font_color", COLOR_TEXT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_grid.add_child(value_label)

func _build_levelup() -> void:
	var ups: Dictionary = GameState.last_run_level_ups
	if ups.is_empty():
		_levelup_panel.visible = false
		return
	var parts: PackedStringArray = []
	for member in GameState.party_members:
		if member != null and ups.has(member.id):
			parts.append("%s +%dLv (Lv%d)" % [member.display_name, int(ups[member.id]), int(member.level)])
	if parts.is_empty():
		_levelup_panel.visible = false
		return
	_levelup_panel.visible = true
	_label_levelup.text = "レベルアップ!  " + "  /  ".join(parts)

func _on_retry_pressed() -> void:
	_set_buttons_disabled(true)
	SaveManager.save_game()
	SceneRouter.change_scene(DUNGEON_SCENE)

func _on_home_pressed() -> void:
	_set_buttons_disabled(true)
	SaveManager.save_game()
	SceneRouter.change_scene(HOME_SCENE)

func _set_buttons_disabled(value: bool) -> void:
	_button_retry.disabled = value
	_button_home.disabled = value
