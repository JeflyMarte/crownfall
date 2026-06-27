extends Control

const DUNGEON_DISPLAY_NAMES: Dictionary = {
	Constants.MOURNGATE_DUNGEON_ID: "モーンゲート",
}
const BuildTagHelperScript: Script = preload("res://scripts/equipment/BuildTagHelper.gd")
const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")

func _ready() -> void:
	$VBoxContainer/DungeonSelectRow/ButtonSelectMourngate.pressed.connect(_on_select_mourngate_pressed)
	$VBoxContainer/ButtonDungeon.pressed.connect(_on_dungeon_button_pressed)
	$VBoxContainer/ButtonEquipment.pressed.connect(_on_equipment_button_pressed)
	$VBoxContainer/ButtonBlacksmith.pressed.connect(_on_blacksmith_button_pressed)
	$VBoxContainer/ButtonCodex.pressed.connect(_on_codex_button_pressed)
	$VBoxContainer/ButtonGacha.pressed.connect(_on_gacha_button_pressed)
	$VBoxContainer/ButtonRoster.pressed.connect(_on_roster_button_pressed)
	$VBoxContainer/ButtonGuild.pressed.connect(_on_guild_button_pressed)
	_ensure_valid_dungeon_selection()
	$VBoxContainer/LabelEquipped.visible = false
	$VBoxContainer/LabelArmorEquipped.visible = false
	$VBoxContainer/LabelAccessoryEquipped.visible = false
	_update_display()

func _ensure_valid_dungeon_selection() -> void:
	if not _is_dungeon_available(GameState.current_dungeon_id):
		GameState.current_dungeon_id = Constants.DEFAULT_DUNGEON_ID

func _is_dungeon_available(dungeon_id: String) -> bool:
	if dungeon_id.is_empty():
		return false
	return DataRegistry.get_dungeon_data(dungeon_id) != null

func _update_display() -> void:
	_update_gold_label()
	_update_party_display()
	_update_build_chips()
	_update_dungeon_selection_ui()

func _update_build_chips() -> void:
	var row: HBoxContainer = $VBoxContainer/BuildChipRow
	BuildTagHelperScript.populate_chip_row(row)

func _update_gold_label() -> void:
	$VBoxContainer/LabelGold.text = "Gold: %d" % GameState.gold

func _update_party_display() -> void:
	var labels: Array[Node] = [
		$VBoxContainer/LabelMember0,
		$VBoxContainer/LabelMember1,
		$VBoxContainer/LabelMember2,
	]
	for i in labels.size():
		if i < GameState.party_members.size():
			labels[i].text = _format_member_line(GameState.party_members[i])
		else:
			labels[i].text = ""

func _format_member_line(member: Resource) -> String:
	var line: String = _format_member_job_line(member)
	var equip_parts: PackedStringArray = []
	var w: Resource = member.equipped_weapon
	if w != null:
		equip_parts.append("W:%s" % w.weapon_id)
	var a: Resource = member.equipped_armor
	if a != null:
		equip_parts.append("A:%s" % a.armor_id)
	var acc: Resource = member.equipped_accessory
	if acc != null:
		equip_parts.append("Acc:%s" % acc.accessory_id)
	if equip_parts.is_empty():
		equip_parts.append("装備なし")
	line += "\n  " + " / ".join(equip_parts)
	return line

func _format_member_job_line(member: Resource) -> String:
	var member_name: String = member.display_name
	var job_id: String = str(member.job_id) if member.job_id != null else ""
	if job_id.is_empty():
		return "%s / Job: -" % member_name
	var mods: Dictionary = _JobStatCalculator.get_member_modifiers(member)
	var job_display: String = mods.get("display_name", job_id)
	if job_display.is_empty():
		job_display = job_id
	var role: String = mods.get("role", "")
	var level: int = int(member.level)
	var line: String = "%s Lv%d / Job: %s" % [member_name, level, job_display]
	if level < LevelSystem.MAX_LEVEL:
		line += " (EXP %d/%d)" % [int(member.exp), LevelSystem.exp_to_next(level)]
	else:
		line += " (MAX)"
	if not role.is_empty():
		line += " / Role: %s" % role
	var mod_parts: PackedStringArray = []
	var hp_mult: float = float(mods.get("hp_multiplier", 1.0))
	var atk_mult: float = float(mods.get("attack_multiplier", 1.0))
	var def_mult: float = float(mods.get("defense_multiplier", 1.0))
	if not is_equal_approx(hp_mult, 1.0):
		mod_parts.append("HP x%.2f" % hp_mult)
	if not is_equal_approx(atk_mult, 1.0):
		mod_parts.append("ATK x%.2f" % atk_mult)
	if not is_equal_approx(def_mult, 1.0):
		mod_parts.append("DEF x%.2f" % def_mult)
	if not mod_parts.is_empty():
		line += " / " + " ".join(mod_parts)
	return line

func _update_dungeon_selection_ui() -> void:
	var selected_id: String = GameState.get_active_dungeon_id()
	var display_name: String = str(DUNGEON_DISPLAY_NAMES.get(selected_id, selected_id))
	$VBoxContainer/LabelSelectedDungeon.text = "選択中: %s" % display_name
	$VBoxContainer/DungeonSelectRow/ButtonSelectMourngate.disabled = selected_id == Constants.MOURNGATE_DUNGEON_ID
	$VBoxContainer/ButtonDungeon.disabled = not _is_dungeon_available(selected_id)

func _select_dungeon(dungeon_id: String) -> void:
	if not _is_dungeon_available(dungeon_id):
		return
	GameState.current_dungeon_id = dungeon_id
	_update_dungeon_selection_ui()

func _on_select_mourngate_pressed() -> void:
	_select_dungeon(Constants.MOURNGATE_DUNGEON_ID)


func _on_dungeon_button_pressed() -> void:
	var dungeon_id: String = GameState.get_active_dungeon_id()
	if not _is_dungeon_available(dungeon_id):
		return
	GameState.current_dungeon_id = dungeon_id
	SceneRouter.change_scene("res://scenes/dungeon/DungeonScene.tscn")

func _on_equipment_button_pressed() -> void:
	SceneRouter.change_scene("res://scenes/equipment/EquipmentScene.tscn")

func _on_blacksmith_button_pressed() -> void:
	SceneRouter.change_scene("res://scenes/blacksmith/BlacksmithScene.tscn")

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
