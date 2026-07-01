extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const LINEUP_ICON_PX: int = 40

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_OWNED: Color = Color(0.55, 0.88, 0.5)
const COLOR_NEW: Color = Color(0.95, 0.78, 0.35)

@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _label_pity: Label = $MainScroll/MainVBox/LabelPity
@onready var _lineup_container: VBoxContainer = $MainScroll/MainVBox/LineupScrollContainer/LineupContainer
@onready var _label_result: Label = $MainScroll/MainVBox/LabelResult
@onready var _button_pull: Button = $MainScroll/MainVBox/ButtonPull
@onready var _button_buy_crystal: Button = $MainScroll/MainVBox/ButtonBuyCrystal

func _ready() -> void:
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	$BottomNav/NavRow/NavHome.pressed.connect(_go_to.bind(HOME_SCENE))
	$BottomNav/NavRow/NavAdventure.pressed.connect(_go_to.bind(DUNGEON_SCENE))
	$BottomNav/NavRow/NavParty.pressed.connect(_go_to.bind(ROSTER_SCENE))
	$BottomNav/NavRow/NavCodex.pressed.connect(_go_to.bind(CODEX_SCENE))
	_button_pull.pressed.connect(_on_pull_pressed)
	_button_buy_crystal.pressed.connect(_on_buy_crystal_pressed)
	_refresh()

func _refresh() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()
	var remaining: int = GachaSystem.HARD_PITY - GameState.gacha_pity
	_label_pity.text = "天井まで %d 連（★4確定）" % maxi(0, remaining)
	_button_pull.disabled = not GachaSystem.can_pull()
	_button_buy_crystal.disabled = GameState.gold < GachaSystem.TOKEN_PURCHASE_GOLD
	_button_pull.text = "単発召喚（%s 1）" % CurrencyHelper.DISPLAY_NAME
	_button_buy_crystal.text = "%s購入（%dG）" % [CurrencyHelper.DISPLAY_NAME, GachaSystem.TOKEN_PURCHASE_GOLD]
	_rebuild_lineup()

func _rebuild_lineup() -> void:
	for child in _lineup_container.get_children():
		child.queue_free()
	var helpers: Array = DataRegistry.get_all_gacha_helper_data()
	helpers.sort_custom(func(a, b): return int(a.rarity) > int(b.rarity))
	if helpers.is_empty():
		var lbl := Label.new()
		lbl.text = "（排出対象なし）"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lineup_container.add_child(lbl)
		return
	for helper in helpers:
		if helper == null:
			continue
		_lineup_container.add_child(_make_lineup_row(helper))

func _make_lineup_row(helper: Resource) -> PanelContainer:
	var helper_id: String = str(helper.id)
	var owned: bool = GameState.owned_helpers.has(helper_id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(LINEUP_ICON_PX, LINEUP_ICON_PX)
	var icon_tex: Texture2D = IconPaths.get_icon_texture(str(helper.job_id), "chr")
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_box.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_box.add_child(glyph)
	row.add_child(icon_box)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info.add_child(name_row)
	var name_label := Label.new()
	name_label.text = str(helper.display_name)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 15)
	name_row.add_child(name_label)
	var stars := Label.new()
	stars.text = RosterUiHelper.stars_text(int(helper.rarity))
	stars.add_theme_color_override("font_color", COLOR_GOLD)
	stars.add_theme_font_size_override("font_size", 14)
	name_row.add_child(stars)

	var sub := Label.new()
	var job_data: Resource = DataRegistry.get_job_data(str(helper.job_id))
	var role_id: String = str(job_data.role) if job_data != null else str(helper.job_id)
	sub.text = str(RosterUiHelper.ROLE_LABELS.get(role_id, str(helper.job_id)))
	sub.add_theme_color_override("font_color", COLOR_SUB)
	sub.add_theme_font_size_override("font_size", 13)
	info.add_child(sub)

	var badge := Label.new()
	badge.text = "所持済" if owned else "未所持"
	badge.add_theme_color_override("font_color", COLOR_OWNED if owned else COLOR_SUB)
	badge.add_theme_font_size_override("font_size", 13)
	row.add_child(badge)
	return panel

func _on_pull_pressed() -> void:
	var result: Dictionary = GachaSystem.pull()
	SaveManager.save_game()
	if not bool(result.get("ok", false)):
		var reason: String = str(result.get("reason", ""))
		if reason == "no_token":
			_label_result.text = "%sが足りません。" % CurrencyHelper.DISPLAY_NAME
		else:
			_label_result.text = "召喚に失敗しました（%s）。" % reason
		_refresh()
		return
	var helper_id: String = str(result.get("helper_id", ""))
	var rarity: int = int(result.get("rarity", 0))
	var is_new: bool = bool(result.get("is_new", false))
	var refund: int = int(result.get("refund", 0))
	var helper_data: Resource = DataRegistry.get_gacha_helper_data(helper_id)
	var name_str: String = helper_id if helper_data == null else str(helper_data.display_name)
	if is_new:
		_label_result.add_theme_color_override("font_color", COLOR_NEW)
		_label_result.text = "NEW! %s を獲得！" % name_str
	else:
		_label_result.add_theme_color_override("font_color", COLOR_SUB)
		_label_result.text = "%s（重複） → %s %d 還元" % [
			name_str, CurrencyHelper.DISPLAY_NAME, refund,
		]
	_refresh()

func _on_buy_crystal_pressed() -> void:
	var success: bool = GachaSystem.buy_token()
	SaveManager.save_game()
	if success:
		_label_result.add_theme_color_override("font_color", COLOR_OWNED)
		_label_result.text = "%sを1個購入しました。" % CurrencyHelper.DISPLAY_NAME
	else:
		_label_result.add_theme_color_override("font_color", COLOR_SUB)
		_label_result.text = "ゴールドが足りません。"
	_refresh()

func _on_back_pressed() -> void:
	_go_to(HOME_SCENE)

func _go_to(path: String) -> void:
	if path == GACHA_SCENE:
		return
	if ResourceLoader.exists(path):
		SceneRouter.change_scene(path)
