extends Control

const DUNGEON_SELECT_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"

@onready var _label_gold: Label = $TopBar/TopBarRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $TopBar/TopBarRow/TokenChip/TokenRow/LabelToken

@onready var _btn_adventure: Button = $LeftMenuPanel/MenuVBox/ButtonAdventure
@onready var _btn_equipment: Button = $LeftMenuPanel/MenuVBox/ButtonEquipment
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
	_btn_roster.pressed.connect(_on_roster_button_pressed)
	_btn_codex.pressed.connect(_on_codex_button_pressed)
	_btn_gacha.pressed.connect(_on_gacha_button_pressed)
	_btn_guild.pressed.connect(_on_guild_button_pressed)
	_nav_home.pressed.connect(_on_home_nav_pressed)
	_nav_adventure.pressed.connect(_on_dungeon_button_pressed)
	_nav_party.pressed.connect(_on_roster_button_pressed)
	_nav_codex.pressed.connect(_on_codex_button_pressed)
	_nav_shop.pressed.connect(_on_gacha_button_pressed)
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

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = "%d" % GameState.gacha_token

func _on_home_nav_pressed() -> void:
	_update_display()

func _on_dungeon_button_pressed() -> void:
	SceneRouter.change_scene(DUNGEON_SELECT_SCENE)

func _on_equipment_button_pressed() -> void:
	SceneRouter.change_scene("res://scenes/equipment/EquipmentScene.tscn")

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
