extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")
const _JobEvolution = preload("res://scripts/systems/JobEvolution.gd")

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_OK: Color = Color(0.55, 0.88, 0.5)
const COLOR_ACCENT: Color = Color(0.75, 0.82, 0.95, 1)

@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _info_panel: PanelContainer = $MainScroll/MainVBox/InfoPanel
@onready var _list_container: VBoxContainer = $MainScroll/MainVBox/ListContainer
@onready var _label_status: Label = $MainScroll/MainVBox/LabelStatus

func _ready() -> void:
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	$BottomNav/NavRow/NavHome.pressed.connect(_go_to.bind(HOME_SCENE))
	$BottomNav/NavRow/NavAdventure.pressed.connect(_go_to.bind(DUNGEON_SCENE))
	$BottomNav/NavRow/NavParty.pressed.connect(_go_to.bind(ROSTER_SCENE))
	$BottomNav/NavRow/NavCodex.pressed.connect(_go_to.bind(CODEX_SCENE))
	$BottomNav/NavRow/NavShop.pressed.connect(_go_to.bind(GACHA_SCENE))
	_info_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
	)
	_refresh_all()

func _refresh_all() -> void:
	_update_currency()
	_rebuild_list()

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()

func _rebuild_list() -> void:
	for child in _list_container.get_children():
		child.queue_free()
	var roster: Array = GameState.get_roster()
	var sorted: Array = roster.duplicate()
	sorted.sort_custom(_sort_members)
	for adv in sorted:
		_list_container.add_child(_make_member_card(adv))

func _sort_members(a: Resource, b: Resource) -> bool:
	var rank_a: int = _member_sort_rank(a)
	var rank_b: int = _member_sort_rank(b)
	if rank_a != rank_b:
		return rank_a < rank_b
	if int(a.level) != int(b.level):
		return int(a.level) > int(b.level)
	return str(a.display_name) < str(b.display_name)

func _member_sort_rank(adv: Resource) -> int:
	if bool(adv.is_evolved):
		return 2
	if _JobEvolution.can_evolve(adv):
		return 0
	return 1

func _make_member_card(adv: Resource) -> PanelContainer:
	var can_certify: bool = _JobEvolution.can_evolve(adv)
	var evolved: bool = bool(adv.is_evolved)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override(
		"panel",
		CombatUiFrames.panel_style(
			CombatUiFrames.TIER_CARD_ACTIVE if can_certify else CombatUiFrames.TIER_CARD
		)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	row.add_child(_make_portrait(adv))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var name_lbl := Label.new()
	name_lbl.text = RosterUiHelper.short_display_name(str(adv.display_name))
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	info.add_child(name_lbl)
	var meta_lbl := Label.new()
	meta_lbl.text = "%s  Lv%d" % [RosterUiHelper.stars_text(int(adv.rarity)), int(adv.level)]
	meta_lbl.add_theme_font_size_override("font_size", 12)
	meta_lbl.add_theme_color_override("font_color", COLOR_SUB)
	info.add_child(meta_lbl)
	var mods: Dictionary = _JobStatCalculator.get_member_modifiers(adv)
	var job_display: String = str(mods.get("display_name", str(adv.job_id)))
	if job_display.is_empty():
		job_display = str(adv.job_id)
	var role: String = str(mods.get("role", ""))
	var job_lbl := Label.new()
	job_lbl.text = "%s %s" % [RosterUiHelper.role_glyph(role), job_display]
	job_lbl.add_theme_font_size_override("font_size", 12)
	job_lbl.add_theme_color_override("font_color", COLOR_ACCENT)
	info.add_child(job_lbl)
	var target_name: String = _JobEvolution.get_evolved_name(adv)
	if not target_name.is_empty():
		var evolve_lbl := Label.new()
		if evolved:
			evolve_lbl.text = "認定済 — %s" % target_name
			evolve_lbl.add_theme_color_override("font_color", COLOR_OK)
		else:
			evolve_lbl.text = "→ %s" % target_name
			evolve_lbl.add_theme_color_override("font_color", COLOR_SUB)
		evolve_lbl.add_theme_font_size_override("font_size", 12)
		info.add_child(evolve_lbl)
	row.add_child(_make_action_column(adv, can_certify, evolved))
	return card

func _make_portrait(adv: Resource) -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(72, 72)
	frame.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(64, 64)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = IconPaths.get_icon_texture(str(adv.job_id), "chr")
	frame.add_child(portrait)
	return frame

func _make_action_column(adv: Resource, can_certify: bool, evolved: bool) -> Control:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(96, 0)
	if evolved:
		btn.text = "認定済"
		btn.disabled = true
	elif can_certify:
		btn.text = "認定する"
		btn.pressed.connect(func(): _on_certify(adv))
	else:
		var req: int = _JobEvolution.required_level(adv)
		btn.text = "Lv%d必要" % req if req > 0 else "対象外"
		btn.disabled = true
	col.add_child(btn)
	return col

func _on_certify(adv: Resource) -> void:
	if not _JobEvolution.evolve(adv):
		_label_status.text = "認定できませんでした"
		return
	SaveManager.save_game()
	var evolved_name: String = _JobEvolution.get_evolved_name(adv)
	_label_status.text = "%s を %s に認定しました" % [adv.display_name, evolved_name]
	_refresh_all()

func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)

func _go_to(path: String) -> void:
	SceneRouter.change_scene(path)
