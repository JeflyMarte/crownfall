extends Control

const _AffixDisplayFormatter = preload("res://scripts/equipment/AffixDisplayFormatter.gd")
const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")
const BuildTagHelperScript: Script = preload("res://scripts/equipment/BuildTagHelper.gd")

@onready var _content: VBoxContainer = $VBoxContainer/ScrollContainer/ContentVBox

var _selected_member_index: int = 0

func _ready() -> void:
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_pressed)
	_content.get_node("MemberSelectRow/ButtonMember0").pressed.connect(_on_member_selected.bind(0))
	_content.get_node("MemberSelectRow/ButtonMember1").pressed.connect(_on_member_selected.bind(1))
	_content.get_node("MemberSelectRow/ButtonMember2").pressed.connect(_on_member_selected.bind(2))
	call_deferred("_sync_content_width_once")
	_refresh_member_buttons()
	_refresh_display()

func _sync_content_width_once() -> void:
	var scroll_width: float = $VBoxContainer/ScrollContainer.size.x
	if scroll_width > 1.0:
		_content.custom_minimum_size.x = scroll_width

func _on_member_selected(member_index: int) -> void:
	_selected_member_index = member_index
	_refresh_member_buttons()
	_refresh_display()

func _refresh_member_buttons() -> void:
	var buttons: Array[Node] = [
		_content.get_node("MemberSelectRow/ButtonMember0"),
		_content.get_node("MemberSelectRow/ButtonMember1"),
		_content.get_node("MemberSelectRow/ButtonMember2"),
	]
	for i in buttons.size():
		var btn: Button = buttons[i] as Button
		if i < GameState.party_members.size():
			var member: Resource = GameState.party_members[i]
			btn.text = member.display_name
			btn.disabled = i == _selected_member_index
		else:
			btn.text = "—"
			btn.disabled = true
	var member_label: Resource = GameState.get_member(_selected_member_index)
	var name_text: String = member_label.display_name if member_label != null else "—"
	_content.get_node("LabelSelectedMember").text = "編成: %s" % name_text

func _refresh_display() -> void:
	_update_equipped_label()
	_rebuild_weapon_list()
	_update_armor_equipped_label()
	_rebuild_armor_list()
	_update_accessory_equipped_label()
	_rebuild_accessory_list()
	_update_build_summary()
	_update_build_chips()

func _update_build_chips() -> void:
	var row: HBoxContainer = _content.get_node("BuildChipRow") as HBoxContainer
	BuildTagHelperScript.populate_chip_row(row)

func _update_equipped_label() -> void:
	var w: Resource = GameState.get_member_equipped_weapon(_selected_member_index)
	if w == null:
		_content.get_node("LabelEquipped").text = "武器: なし"
		return
	var base_text: String = "武器: %s  ATK %d  SPD %.1f  CRT %.0f%%" % [
		w.weapon_id, w.rolled_attack, w.attack_speed, w.critical_rate * 100.0
	]
	_content.get_node("LabelEquipped").text = _AffixDisplayFormatter.append_to_text(base_text, w)

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
	var list: Node = _content.get_node("WeaponList")
	for child in list.get_children():
		child.queue_free()
	var weapons: Array = $EquipmentController.get_appraised_weapons_for_member(_selected_member_index)
	for item in weapons:
		var row := HBoxContainer.new()
		row.add_child(_make_icon_rect(IconPaths.get_icon_texture(item.weapon_id, "weapon")))
		var btn := Button.new()
		var base_text: String = "%s  ATK %d  SPD %.1f  CRT %.0f%%" % [
			item.weapon_id, item.rolled_attack, item.attack_speed, item.critical_rate * 100.0
		]
		var compare_text: String = _get_weapon_compare_text(item)
		btn.text = _AffixDisplayFormatter.append_to_text(base_text, item) + "  " + compare_text
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_equip_pressed.bind(item))
		row.add_child(btn)
		list.add_child(row)

func _get_weapon_compare_text(candidate: Resource) -> String:
	var equipped: Resource = GameState.get_member_equipped_weapon(_selected_member_index)
	if equipped == null:
		return "（未装備）"
	if candidate == equipped:
		return "（装備中）"
	var parts: PackedStringArray = []
	var atk_diff: int = candidate.rolled_attack - equipped.rolled_attack
	var sign_atk: String = "+" if atk_diff >= 0 else ""
	parts.append("ATK %s%d" % [sign_atk, atk_diff])
	var spd_diff: float = candidate.attack_speed - equipped.attack_speed
	if not is_zero_approx(spd_diff):
		var sign_spd: String = "+" if spd_diff >= 0.0 else ""
		parts.append("SPD %s%.1f" % [sign_spd, spd_diff])
	var crt_diff: float = candidate.critical_rate - equipped.critical_rate
	if not is_zero_approx(crt_diff):
		var sign_crt: String = "+" if crt_diff >= 0.0 else ""
		parts.append("CRT %s%.0f%%" % [sign_crt, crt_diff * 100.0])
	return "[%s]" % " | ".join(parts)

func _on_equip_pressed(item: Resource) -> void:
	$EquipmentController.equip_weapon(item, _selected_member_index)
	_refresh_display()

func _update_armor_equipped_label() -> void:
	var a: Resource = GameState.get_member_equipped_armor(_selected_member_index)
	if a == null:
		_content.get_node("LabelArmorEquipped").text = "防具: なし"
		return
	var base_text: String = "防具: %s  DEF %d  HP+%d" % [
		a.armor_id, a.rolled_defense, a.hp_bonus
	]
	_content.get_node("LabelArmorEquipped").text = _AffixDisplayFormatter.append_to_text(base_text, a)

func _rebuild_armor_list() -> void:
	var list: Node = _content.get_node("ArmorList")
	for child in list.get_children():
		child.queue_free()
	var armors: Array = $EquipmentController.get_appraised_armors_for_member(_selected_member_index)
	for item in armors:
		var row := HBoxContainer.new()
		row.add_child(_make_icon_rect(IconPaths.get_icon_texture(item.armor_id, "armor")))
		var btn := Button.new()
		var base_text: String = "%s  DEF %d  HP+%d  WGT %.1f" % [
			item.armor_id, item.rolled_defense, item.hp_bonus, item.weight
		]
		var compare_text: String = _get_armor_compare_text(item)
		btn.text = _AffixDisplayFormatter.append_to_text(base_text, item) + "  " + compare_text
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_equip_armor_pressed.bind(item))
		row.add_child(btn)
		list.add_child(row)

func _get_armor_compare_text(candidate: Resource) -> String:
	var equipped: Resource = GameState.get_member_equipped_armor(_selected_member_index)
	if equipped == null:
		return "（未装備）"
	if candidate == equipped:
		return "（装備中）"
	var parts: PackedStringArray = []
	var def_diff: int = candidate.rolled_defense - equipped.rolled_defense
	if def_diff != 0:
		parts.append("DEF %s%d" % ["+" if def_diff >= 0 else "", def_diff])
	var hp_diff: int = candidate.hp_bonus - equipped.hp_bonus
	if hp_diff != 0:
		parts.append("HP %s%d" % ["+" if hp_diff >= 0 else "", hp_diff])
	if parts.is_empty():
		return "[DEF ±0]"
	return "[%s]" % " | ".join(parts)

func _on_equip_armor_pressed(item: Resource) -> void:
	$EquipmentController.equip_armor(item, _selected_member_index)
	_refresh_display()

func _update_accessory_equipped_label() -> void:
	var acc: Resource = GameState.get_member_equipped_accessory(_selected_member_index)
	if acc == null:
		_content.get_node("LabelAccessoryEquipped").text = "装飾品: なし"
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
	_content.get_node("LabelAccessoryEquipped").text = _AffixDisplayFormatter.append_to_text(base_text, acc)

func _rebuild_accessory_list() -> void:
	var list: Node = _content.get_node("AccessoryList")
	for child in list.get_children():
		child.queue_free()
	var accessories: Array = $EquipmentController.get_appraised_accessories_for_member(_selected_member_index)
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
		var compare_text: String = _get_accessory_compare_text(item)
		btn.text = _AffixDisplayFormatter.append_to_text(base_text, item) + "  " + compare_text
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_equip_accessory_pressed.bind(item))
		row.add_child(btn)
		list.add_child(row)

func _get_accessory_compare_text(candidate: Resource) -> String:
	var equipped: Resource = GameState.get_member_equipped_accessory(_selected_member_index)
	if equipped == null:
		return "（未装備）"
	if candidate == equipped:
		return "（装備中）"
	var c_data: Resource = load("res://resources/accessories/" + candidate.accessory_id + ".tres")
	var e_data: Resource = load("res://resources/accessories/" + equipped.accessory_id + ".tres")
	if c_data == null or e_data == null:
		return ""
	var parts: PackedStringArray = []
	var hp_d: int = c_data.hp_bonus - e_data.hp_bonus
	if hp_d != 0:
		parts.append("HP %s%d" % ["+" if hp_d >= 0 else "", hp_d])
	var atk_d: int = c_data.attack_bonus - e_data.attack_bonus
	if atk_d != 0:
		parts.append("ATK %s%d" % ["+" if atk_d >= 0 else "", atk_d])
	var def_d: int = c_data.defense_bonus - e_data.defense_bonus
	if def_d != 0:
		parts.append("DEF %s%d" % ["+" if def_d >= 0 else "", def_d])
	var crt_d: float = c_data.crit_rate_bonus - e_data.crit_rate_bonus
	if not is_zero_approx(crt_d):
		parts.append("CRT %s%.0f%%" % ["+" if crt_d >= 0.0 else "", crt_d * 100.0])
	var lck_d: float = c_data.luck_bonus - e_data.luck_bonus
	if not is_zero_approx(lck_d):
		parts.append("LCK %s%.1f" % ["+" if lck_d >= 0.0 else "", lck_d])
	if parts.is_empty():
		return "[±0]"
	return "[%s]" % " | ".join(parts)

func _on_equip_accessory_pressed(item: Resource) -> void:
	$EquipmentController.equip_accessory(item, _selected_member_index)
	_refresh_display()

func _update_build_summary() -> void:
	_content.get_node("LabelBuildSummary").text = _build_summary_text()

func _build_summary_text() -> String:
	var lines: PackedStringArray = ["=== Build Summary ==="]
	for i in GameState.party_members.size():
		var member: Resource = GameState.party_members[i]
		if member == null:
			continue
		lines.append("")
		lines.append("[%s]" % member.display_name)
		var w: Resource = member.equipped_weapon
		lines.append("Weapon: %s  ATK %d" % [w.weapon_id, w.rolled_attack] if w != null else "Weapon: None")
		var a: Resource = member.equipped_armor
		lines.append("Armor: %s  DEF %d" % [a.armor_id, a.rolled_defense] if a != null else "Armor: None")
		var acc: Resource = member.equipped_accessory
		lines.append("Accessory: %s" % acc.accessory_id if acc != null else "Accessory: None")
		var affix_lines: PackedStringArray = _collect_affix_lines_for_member(i)
		if not affix_lines.is_empty():
			lines.append("Affix:")
			for l in affix_lines:
				lines.append("  " + l)
	var job_lines: PackedStringArray = _collect_job_lines()
	if not job_lines.is_empty():
		lines.append("")
		lines.append("Jobs:")
		for l in job_lines:
			lines.append(l)
	lines.append("")
	lines.append("Build: " + _estimate_build_tags())
	return "\n".join(lines)

func _collect_affix_lines_for_member(member_index: int) -> PackedStringArray:
	var result: PackedStringArray = []
	var member: Resource = GameState.get_member(member_index)
	if member == null:
		return result
	var items: Array = [member.equipped_weapon, member.equipped_armor, member.equipped_accessory]
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
	return BuildTagHelperScript.format_tags_line()

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
