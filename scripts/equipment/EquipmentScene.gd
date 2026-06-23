extends Control

const _AffixDisplayFormatter = preload("res://scripts/equipment/AffixDisplayFormatter.gd")
const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")

func _ready() -> void:
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_pressed)
	_refresh_display()

func _refresh_display() -> void:
	_update_equipped_label()
	_rebuild_weapon_list()
	_update_armor_equipped_label()
	_rebuild_armor_list()
	_update_accessory_equipped_label()
	_rebuild_accessory_list()
	_update_build_summary()

func _update_equipped_label() -> void:
	var w: Resource = GameState.equipped_weapon
	if w == null:
		$VBoxContainer/LabelEquipped.text = "装備: なし"
		return
	var base_text: String = "装備: %s  ATK %d  SPD %.1f  CRT %.0f%%" % [
		w.weapon_id, w.rolled_attack, w.attack_speed, w.critical_rate * 100.0
	]
	$VBoxContainer/LabelEquipped.text = _AffixDisplayFormatter.append_to_text(base_text, w)

func _make_icon_rect(texture: Texture2D) -> TextureRect:
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(32, 32)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if texture != null:
		tr.texture = texture
	else:
		tr.visible = false
	return tr

func _rebuild_weapon_list() -> void:
	var list: Node = $VBoxContainer/WeaponList
	for child in list.get_children():
		child.queue_free()
	var weapons: Array = $EquipmentController.get_appraised_weapons()
	for item in weapons:
		var row := HBoxContainer.new()
		row.add_child(_make_icon_rect(IconPaths.get_icon_texture(item.weapon_id, "weapon")))
		var btn := Button.new()
		var base_text: String = "%s  ATK %d  SPD %.1f  CRT %.0f%%" % [
			item.weapon_id, item.rolled_attack, item.attack_speed, item.critical_rate * 100.0
		]
		btn.text = _AffixDisplayFormatter.append_to_text(base_text, item)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_equip_pressed.bind(item))
		row.add_child(btn)
		list.add_child(row)

func _on_equip_pressed(item: Resource) -> void:
	$EquipmentController.equip_weapon(item)
	_refresh_display()

func _update_armor_equipped_label() -> void:
	var a: Resource = GameState.equipped_armor
	if a == null:
		$VBoxContainer/LabelArmorEquipped.text = "防具: なし"
		return
	var base_text: String = "防具: %s  DEF %d  HP+%d" % [
		a.armor_id, a.rolled_defense, a.hp_bonus
	]
	$VBoxContainer/LabelArmorEquipped.text = _AffixDisplayFormatter.append_to_text(base_text, a)

func _rebuild_armor_list() -> void:
	var list: Node = $VBoxContainer/ArmorList
	for child in list.get_children():
		child.queue_free()
	var armors: Array = $EquipmentController.get_appraised_armors()
	for item in armors:
		var row := HBoxContainer.new()
		row.add_child(_make_icon_rect(IconPaths.get_icon_texture(item.armor_id, "armor")))
		var btn := Button.new()
		var base_text: String = "%s  DEF %d  HP+%d  WGT %.1f" % [
			item.armor_id, item.rolled_defense, item.hp_bonus, item.weight
		]
		btn.text = _AffixDisplayFormatter.append_to_text(base_text, item)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_equip_armor_pressed.bind(item))
		row.add_child(btn)
		list.add_child(row)

func _on_equip_armor_pressed(item: Resource) -> void:
	$EquipmentController.equip_armor(item)
	_refresh_display()

func _update_accessory_equipped_label() -> void:
	var acc: Resource = GameState.equipped_accessory
	if acc == null:
		$VBoxContainer/LabelAccessoryEquipped.text = "装飾品: なし"
		return
	var acc_data: Resource = load("res://resources/accessories/" + acc.accessory_id + ".tres")
	var base_text: String
	if acc_data == null:
		base_text = "装飾品: %s" % acc.accessory_id
	else:
		base_text = (
			"装飾品: %s  HP+%d  ATK+%d  DEF+%d  CRT+%.0f%%  LCK+%.1f" % [
				acc.accessory_id,
				acc_data.hp_bonus,
				acc_data.attack_bonus,
				acc_data.defense_bonus,
				acc_data.crit_rate_bonus * 100.0,
				acc_data.luck_bonus,
			]
		)
	$VBoxContainer/LabelAccessoryEquipped.text = _AffixDisplayFormatter.append_to_text(base_text, acc)

func _rebuild_accessory_list() -> void:
	var list: Node = $VBoxContainer/AccessoryList
	for child in list.get_children():
		child.queue_free()
	var accessories: Array = $EquipmentController.get_appraised_accessories()
	for item in accessories:
		var acc_data: Resource = load("res://resources/accessories/" + item.accessory_id + ".tres")
		var row := HBoxContainer.new()
		row.add_child(_make_icon_rect(IconPaths.get_icon_texture(item.accessory_id, "accessory")))
		var btn := Button.new()
		var base_text: String
		if acc_data != null:
			base_text = "%s  HP+%d  ATK+%d  DEF+%d  CRT+%.0f%%  LCK+%.1f" % [
				item.accessory_id,
				acc_data.hp_bonus,
				acc_data.attack_bonus,
				acc_data.defense_bonus,
				acc_data.crit_rate_bonus * 100.0,
				acc_data.luck_bonus,
			]
		else:
			base_text = item.accessory_id
		btn.text = _AffixDisplayFormatter.append_to_text(base_text, item)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_equip_accessory_pressed.bind(item))
		row.add_child(btn)
		list.add_child(row)

func _on_equip_accessory_pressed(item: Resource) -> void:
	$EquipmentController.equip_accessory(item)
	_refresh_display()

func _update_build_summary() -> void:
	$VBoxContainer/LabelBuildSummary.text = _build_summary_text()

func _build_summary_text() -> String:
	var lines: PackedStringArray = ["=== Build Summary ==="]
	var w: Resource = GameState.equipped_weapon
	lines.append("Weapon: %s  ATK %d" % [w.weapon_id, w.rolled_attack] if w != null else "Weapon: None")
	var a: Resource = GameState.equipped_armor
	lines.append("Armor: %s  DEF %d" % [a.armor_id, a.rolled_defense] if a != null else "Armor: None")
	var acc: Resource = GameState.equipped_accessory
	lines.append("Accessory: %s" % acc.accessory_id if acc != null else "Accessory: None")
	var affix_lines: PackedStringArray = _collect_affix_lines()
	if not affix_lines.is_empty():
		lines.append("")
		lines.append("Affix:")
		for l in affix_lines:
			lines.append(l)
	var job_lines: PackedStringArray = _collect_job_lines()
	if not job_lines.is_empty():
		lines.append("")
		lines.append("Jobs:")
		for l in job_lines:
			lines.append(l)
	lines.append("")
	lines.append("Build: " + _estimate_build_tags())
	return "\n".join(lines)

func _collect_affix_lines() -> PackedStringArray:
	var result: PackedStringArray = []
	var items: Array = [GameState.equipped_weapon, GameState.equipped_armor, GameState.equipped_accessory]
	for item in items:
		if item == null or not ("is_appraised" in item) or not item.is_appraised:
			continue
		var all_ids: Array = []
		if "prefix_ids" in item:
			all_ids.append_array(item.prefix_ids)
		if "suffix_ids" in item:
			all_ids.append_array(item.suffix_ids)
		for affix_id in all_ids:
			var sid: String = str(affix_id)
			if sid.is_empty():
				continue
			var affix_data: Resource = DataRegistry.get_affix_data(sid)
			if affix_data != null:
				var name_part: String = affix_data.display_name if not affix_data.display_name.is_empty() else sid
				result.append("- %s: %s" % [name_part, _format_affix_stat(affix_data)])
			else:
				result.append("- %s" % sid)
	return result

func _format_affix_stat(affix_data: Resource) -> String:
	if affix_data.stat_type.is_empty():
		return ""
	var pct_types: Array = ["Gold Gain", "Critical", "Attack Speed", "Rare Drop Rate"]
	if affix_data.stat_type in pct_types:
		return "%s +%d%%" % [affix_data.stat_type, int(round(float(affix_data.value) * 100.0))]
	return "%s +%s" % [affix_data.stat_type, str(int(affix_data.value))]

func _collect_job_lines() -> PackedStringArray:
	var result: PackedStringArray = []
	for member in GameState.party_members:
		if member == null:
			continue
		var mods: Dictionary = _JobStatCalculator.get_member_modifiers(member)
		var job_name: String = mods.get("display_name", "")
		if job_name.is_empty():
			job_name = member.job_id if not str(member.job_id).is_empty() else "?"
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
		var role: String = mods.get("role", "")
		var line: String = "- %s" % job_name
		if not mod_parts.is_empty():
			line += ": " + " ".join(mod_parts)
		elif not role.is_empty():
			line += ": %s" % role
		result.append(line)
	return result

func _estimate_build_tags() -> String:
	var has_attack: bool = false
	var has_critical: bool = false
	var has_survival: bool = false
	var has_exploration: bool = false
	var items: Array = [GameState.equipped_weapon, GameState.equipped_armor, GameState.equipped_accessory]
	for item in items:
		if item == null or not ("is_appraised" in item) or not item.is_appraised:
			continue
		var all_ids: Array = []
		if "prefix_ids" in item:
			all_ids.append_array(item.prefix_ids)
		if "suffix_ids" in item:
			all_ids.append_array(item.suffix_ids)
		for affix_id in all_ids:
			var affix_data: Resource = DataRegistry.get_affix_data(str(affix_id))
			if affix_data == null:
				continue
			var st: String = affix_data.stat_type.to_lower()
			if "attack" in st:
				has_attack = true
			if "critical" in st:
				has_critical = true
			if "hp" in st or "defense" in st or "healing" in st:
				has_survival = true
	for member in GameState.party_members:
		if member == null:
			continue
		var role: String = str(_JobStatCalculator.get_member_modifiers(member).get("role", "")).to_lower()
		if role == "dps":
			has_attack = true
		elif role == "tank":
			has_survival = true
		elif role == "scout":
			has_exploration = true
	var tags: PackedStringArray = []
	if has_attack:
		tags.append("Attack")
	if has_critical:
		tags.append("Critical")
	if has_survival:
		tags.append("Survival")
	if has_exploration:
		tags.append("Exploration")
	return " / ".join(tags) if not tags.is_empty() else "Basic"

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
