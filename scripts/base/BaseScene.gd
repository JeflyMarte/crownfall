extends Control

const DUNGEON_SELECT_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const MAX_VISIBLE_MATERIALS: int = 3

const COLOR_MAT_SUB: Color = Color(0.78, 0.74, 0.6, 1)
const COLOR_MAT_TEXT: Color = Color(0.92, 0.86, 0.65, 1)

@onready var _material_chip: PanelContainer = $TopBar/TopBarRow/MaterialChip
@onready var _material_icons: HBoxContainer = $TopBar/TopBarRow/MaterialChip/MaterialRow/MaterialIcons
@onready var _label_gold: Label = $TopBar/TopBarRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $TopBar/TopBarRow/TokenChip/TokenRow/LabelToken

@onready var _btn_adventure: Button = $LeftMenuPanel/MenuVBox/ButtonAdventure
@onready var _btn_equipment: Button = $LeftMenuPanel/MenuVBox/ButtonEquipment
@onready var _btn_blacksmith: Button = $LeftMenuPanel/MenuVBox/ButtonBlacksmith
@onready var _btn_roster: Button = $LeftMenuPanel/MenuVBox/ButtonRoster
@onready var _btn_codex: Button = $LeftMenuPanel/MenuVBox/ButtonCodex
@onready var _btn_gacha: Button = $LeftMenuPanel/MenuVBox/ButtonGacha
@onready var _btn_guild: Button = $LeftMenuPanel/MenuVBox/ButtonGuild

@onready var _nav_home: Button = $BottomNav/NavRow/NavHome
@onready var _nav_adventure: Button = $BottomNav/NavRow/NavAdventure
@onready var _nav_party: Button = $BottomNav/NavRow/NavParty
@onready var _nav_codex: Button = $BottomNav/NavRow/NavCodex
@onready var _nav_shop: Button = $BottomNav/NavRow/NavShop

func _ready() -> void:
	_btn_adventure.pressed.connect(_on_dungeon_button_pressed)
	_btn_equipment.pressed.connect(_on_equipment_button_pressed)
	_btn_blacksmith.pressed.connect(_on_blacksmith_button_pressed)
	_btn_roster.pressed.connect(_on_roster_button_pressed)
	_btn_codex.pressed.connect(_on_codex_button_pressed)
	_btn_gacha.pressed.connect(_on_gacha_button_pressed)
	_btn_guild.pressed.connect(_on_guild_button_pressed)
	_nav_home.pressed.connect(_on_home_nav_pressed)
	_nav_adventure.pressed.connect(_on_dungeon_button_pressed)
	_nav_party.pressed.connect(_on_roster_button_pressed)
	_nav_codex.pressed.connect(_on_codex_button_pressed)
	_nav_shop.pressed.connect(_on_gacha_button_pressed)
	_material_chip.gui_input.connect(_on_material_chip_gui_input)
	_ensure_valid_dungeon_selection()
	_update_display()

func _ensure_valid_dungeon_selection() -> void:
	if not _is_dungeon_available(GameState.current_dungeon_id):
		GameState.current_dungeon_id = Constants.DEFAULT_DUNGEON_ID

func _is_dungeon_available(dungeon_id: String) -> bool:
	if dungeon_id.is_empty():
		return false
	return DataRegistry.get_dungeon_data(dungeon_id) != null

func _update_display() -> void:
	_update_currency()
	_update_materials()

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = "%d" % GameState.gacha_token

func _update_materials() -> void:
	for child in _material_icons.get_children():
		child.queue_free()
	var entries: Array[Dictionary] = []
	for raw_id in GameState.material_inventory.keys():
		var mat_id: String = str(raw_id)
		var qty: int = GameState.get_material_quantity(mat_id)
		if qty > 0:
			entries.append({"id": mat_id, "qty": qty})
	if entries.is_empty():
		_material_chip.visible = false
		_material_chip.tooltip_text = ""
		return
	_material_chip.visible = true
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["qty"]) > int(b["qty"])
	)
	var tooltip_lines: PackedStringArray = []
	for entry in entries:
		tooltip_lines.append(
			"%s x%d" % [DataRegistry.get_material_name(str(entry["id"])), int(entry["qty"])]
		)
	_material_chip.tooltip_text = "\n".join(tooltip_lines)
	var show_count: int = mini(entries.size(), MAX_VISIBLE_MATERIALS)
	for i in show_count:
		var e: Dictionary = entries[i]
		_material_icons.add_child(_make_material_chip_cell(str(e["id"]), int(e["qty"])))
	var overflow: int = entries.size() - show_count
	if overflow > 0:
		var more := Label.new()
		more.text = "+%d" % overflow
		more.add_theme_font_size_override("font_size", 13)
		more.add_theme_color_override("font_color", COLOR_MAT_SUB)
		_material_icons.add_child(more)

func _make_material_chip_cell(mat_id: String, qty: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var icon_tex: Texture2D = IconPaths.get_icon_texture(mat_id, "material")
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(18, 18)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = "材"
		glyph.add_theme_font_size_override("font_size", 12)
		glyph.add_theme_color_override("font_color", COLOR_MAT_SUB)
		row.add_child(glyph)
	var qty_label := Label.new()
	qty_label.text = str(qty)
	qty_label.add_theme_font_size_override("font_size", 13)
	qty_label.add_theme_color_override("font_color", COLOR_MAT_TEXT)
	row.add_child(qty_label)
	return row

func _on_material_chip_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			SceneRouter.change_scene(BLACKSMITH_SCENE)

func _on_home_nav_pressed() -> void:
	_update_display()

func _on_dungeon_button_pressed() -> void:
	SceneRouter.change_scene(DUNGEON_SELECT_SCENE)

func _on_equipment_button_pressed() -> void:
	SceneRouter.change_scene("res://scenes/equipment/EquipmentScene.tscn")

func _on_blacksmith_button_pressed() -> void:
	SceneRouter.change_scene(BLACKSMITH_SCENE)

func _on_codex_button_pressed() -> void:
	SceneRouter.change_scene("res://scenes/codex/CodexScene.tscn")

func _on_gacha_button_pressed() -> void:
	var path: String = "res://scenes/gacha/GachaScene.tscn"
	if ResourceLoader.exists(path):
		SceneRouter.change_scene(path)

func _on_roster_button_pressed() -> void:
	var path: String = "res://scenes/roster/RosterScene.tscn"
	if ResourceLoader.exists(path):
		SceneRouter.change_scene(path)

func _on_guild_button_pressed() -> void:
	var path: String = "res://scenes/guild/GuildScene.tscn"
	if ResourceLoader.exists(path):
		SceneRouter.change_scene(path)
