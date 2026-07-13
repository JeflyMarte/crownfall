class_name EquipmentItemDetailHelper
extends RefCounted

const _AffixDisplayFormatter = preload("res://scripts/equipment/AffixDisplayFormatter.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _WeaponFlavorHelper = preload("res://scripts/systems/WeaponFlavorHelper.gd")
const _ElementResolver = preload("res://scripts/combat/ElementResolver.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _EquipmentPerfectRollHelper = preload("res://scripts/equipment/EquipmentPerfectRollHelper.gd")

const COLOR_SUB: Color = Color(0.90, 0.87, 0.80)
const COLOR_LABEL: Color = Color(0.97, 0.94, 0.87)
const COLOR_VALUE: Color = Color(1.0, 0.98, 0.92)
const COLOR_POS: Color = Color(0.55, 0.88, 0.5)
const COLOR_NEG: Color = Color(0.95, 0.45, 0.42)
const COLOR_FLAVOR: Color = Color(0.86, 0.82, 0.72)
const COLOR_WEAPON_EFFECT: Color = Color(0.75, 0.82, 0.95)
const STAT_ICON_PX: int = 24
const STAT_LABEL_MIN_W: int = 92
const HEADER_ICON_PX: int = 56

static func short_name(item: Resource, category: String) -> String:
	if item == null:
		return "—"
	match category:
		"weapon":
			return _EquipmentEnhancer.get_display_name(item)
		"armor":
			return EquipmentDisplayNames.get_instance_name(item, "armor")
		"accessory":
			return EquipmentDisplayNames.get_instance_name(item, "accessory")
	return "—"

static func category_label(category: String) -> String:
	return EquipmentUiHelper.category_label(category)

static func owner_text(item: Resource) -> String:
	var idx: int = EquipmentUiHelper.equipped_member_index(item)
	if idx < 0:
		return "装備者: なし"
	var member: Resource = GameState.get_member(idx)
	if member == null:
		return "装備者: なし"
	return "装備者: %s" % str(member.display_name)

static func weapon_legendary_effect_text_from_data(weapon_data: Resource) -> String:
	if weapon_data == null:
		return ""
	var pid: String = str(weapon_data.fixed_passive_id) if "fixed_passive_id" in weapon_data else ""
	if pid.is_empty():
		return ""
	return CombatPassives.weapon_passive_description(pid)

static func equipment_legendary_effect_text_from_passive_id(passive_id: String) -> String:
	if passive_id.is_empty():
		return ""
	return CombatPassives.relic_description(passive_id)

static func equipment_legendary_effect_text(item: Resource, category: String) -> String:
	if item == null:
		return ""
	match category:
		"weapon":
			return weapon_legendary_effect_text(item, category)
		"armor":
			var armor_data: Resource = DataRegistry.get_armor_data(str(item.armor_id))
			if armor_data == null:
				return ""
			return equipment_legendary_effect_text_from_passive_id(
				str(armor_data.fixed_passive_id) if "fixed_passive_id" in armor_data else ""
			)
		"accessory":
			var acc_data: Resource = DataRegistry.get_accessory_data(str(item.accessory_id))
			if acc_data == null:
				return ""
			return equipment_legendary_effect_text_from_passive_id(
				str(acc_data.fixed_passive_id) if "fixed_passive_id" in acc_data else ""
			)
	return ""

static func weapon_legendary_effect_text(item: Resource, category: String) -> String:
	if item == null or category != "weapon":
		return ""
	var weapon_data: Resource = DataRegistry.get_weapon_data(str(item.weapon_id))
	return weapon_legendary_effect_text_from_data(weapon_data)

static func _append_legendary_effect_block(host: VBoxContainer, item: Resource, category: String) -> void:
	var effect_text: String = equipment_legendary_effect_text(item, category)
	if effect_text.is_empty():
		return
	host.add_child(_make_rule())
	var title := Label.new()
	title.text = "固有効果"
	UiTypography.apply_caption(title, COLOR_WEAPON_EFFECT)
	host.add_child(title)
	var body := Label.new()
	body.text = effect_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(body, UiTypography.SIZE_CAPTION, COLOR_WEAPON_EFFECT)
	host.add_child(body)

static func _stat_value(item: Resource, category: String, stat_key: String, value_text: String) -> String:
	return _EquipmentPerfectRollHelper.value_label(
		value_text,
		_EquipmentPerfectRollHelper.is_ui_stat_perfect(item, category, stat_key)
	)

static func stat_rows(item: Resource, category: String) -> Array:
	var rows: Array = []
	if item == null:
		return rows
	match category:
		"weapon":
			rows.append({
				"key": "attack",
				"label": "攻撃力",
				"value": _stat_value(
					item, category, "attack",
					str(_EquipmentEnhancer.get_effective_attack(item))
				),
			})
			var elem: String = _WeaponStatResolver.resolve_element(item)
			if not elem.is_empty():
				rows.append({
					"key": "element",
					"label": "属性",
					"value": _ElementResolver.get_display_name(elem),
				})
				var elem_power: int = _WeaponStatResolver.resolve_element_power(item)
				if elem_power > 0:
					rows.append({
						"key": "element_power",
						"label": "属性値",
						"value": _stat_value(item, category, "element_power", "+%d" % elem_power),
					})
			var bane: Dictionary = _WeaponStatResolver.resolve_bane(item)
			if not str(bane.get("class", "")).is_empty():
				rows.append({
					"key": "bane",
					"label": "生態特効",
					"value": "%s ×%.1f" % [str(bane.get("class", "")), float(bane.get("mult", 1.0))],
				})
			rows.append({
				"key": "speed",
				"label": "攻撃速度",
				"value": _stat_value(
					item, category, "speed",
					"%.1f" % _WeaponStatResolver.resolve_attack_speed(item)
				),
			})
			rows.append({
				"key": "crit_rate",
				"label": "会心率",
				"value": _stat_value(
					item, category, "crit_rate",
					"%.0f%%" % (_WeaponStatResolver.resolve_critical_rate(item) * 100.0)
				),
			})
			var on_hit_status_id: String = _WeaponStatResolver.resolve_on_hit_status_id(item)
			if not on_hit_status_id.is_empty():
				var on_hit_chance: float = _WeaponStatResolver.resolve_on_hit_status_chance(item)
				var status_effect: Resource = DataRegistry.get_status_effect(on_hit_status_id)
				var status_label: String = (
					status_effect.display_name if status_effect != null else on_hit_status_id
				)
				rows.append({
					"key": "on_hit_status",
					"label": "状態付与",
					"value": _stat_value(
						item, category, "on_hit_status",
						"%s %.0f%%" % [status_label, on_hit_chance * 100.0]
					),
				})
		"armor":
			rows.append({
				"key": "defense",
				"label": "防御力",
				"value": _stat_value(item, category, "defense", str(int(item.rolled_defense))),
			})
			var hp_bonus: int = _ArmorStatResolver.resolve_hp_bonus(item)
			if hp_bonus > 0:
				rows.append({
					"key": "hp",
					"label": "HP",
					"value": _stat_value(item, category, "hp", "+%d" % hp_bonus),
				})
			var resist: String = _armor_resist_text(item)
			if not resist.is_empty():
				rows.append({
					"key": "resist",
					"label": "属性耐性",
					"value": _stat_value(item, category, "resist", resist),
				})
			_append_rate_row(rows, item, category, "exp_gain", "経験値獲得", _ArmorStatResolver.resolve_exp_gain_rate(item))
			_append_rate_row(rows, item, category, "gold_gain", "ゴールド獲得", _ArmorStatResolver.resolve_gold_gain_rate(item))
			_append_rate_row(rows, item, category, "rare_drop", "レアドロップ", _ArmorStatResolver.resolve_rare_drop_rate(item))
			var immunity_text: String = _armor_immunity_text(item)
			if not immunity_text.is_empty():
				rows.append({
					"key": "status_immunity",
					"label": "状態異常無効",
					"value": _stat_value(item, category, "status_immunity", immunity_text),
				})
			var evasion: float = _ArmorStatResolver.resolve_evasion_rate(item)
			if evasion > 0.0:
				rows.append({
					"key": "evasion_rate",
					"label": "回避率",
					"value": _stat_value(item, category, "evasion_rate", "+%.0f%%" % (evasion * 100.0)),
				})
		"accessory":
			var acc_data: Resource = DataRegistry.get_accessory_data(str(item.accessory_id))
			var hp: int = _AccessoryStatResolver.resolve_hp_bonus(item, acc_data)
			if hp > 0:
				rows.append({"key": "hp", "label": "HP", "value": _stat_value(item, category, "hp", "+%d" % hp)})
			var atk: int = _AccessoryStatResolver.resolve_attack_bonus(item, acc_data)
			if atk > 0:
				rows.append({
					"key": "attack",
					"label": "攻撃力",
					"value": _stat_value(item, category, "attack", "+%d" % atk),
				})
			var def: int = _AccessoryStatResolver.resolve_defense_bonus(item, acc_data)
			if def > 0:
				rows.append({
					"key": "defense",
					"label": "防御力",
					"value": _stat_value(item, category, "defense", "+%d" % def),
				})
			var crit: float = _AccessoryStatResolver.resolve_crit_rate_bonus(item, acc_data)
			if crit > 0.0:
				rows.append({
					"key": "crit_rate",
					"label": "会心率",
					"value": _stat_value(item, category, "crit_rate", "+%.0f%%" % (crit * 100.0)),
				})
			_append_rate_row(
				rows, item, category, "exp_gain", "経験値獲得",
				_AccessoryStatResolver.resolve_exp_gain_rate(item, acc_data)
			)
			_append_rate_row(
				rows, item, category, "gold_gain", "ゴールド獲得",
				_AccessoryStatResolver.resolve_gold_gain_rate(item, acc_data)
			)
			_append_rate_row(
				rows, item, category, "rare_drop", "レアドロップ",
				_AccessoryStatResolver.resolve_rare_drop_rate(item, acc_data)
			)
			var evasion: float = _AccessoryStatResolver.resolve_evasion_rate(item, acc_data)
			if evasion > 0.0:
				rows.append({
					"key": "evasion_rate",
					"label": "回避率",
					"value": _stat_value(item, category, "evasion_rate", "+%.0f%%" % (evasion * 100.0)),
				})
	return rows

static func _append_rate_row(
	rows: Array,
	item: Resource,
	category: String,
	key: String,
	label: String,
	rate: float
) -> void:
	if rate > 0.0:
		rows.append({
			"key": key,
			"label": label,
			"value": _stat_value(item, category, key, "+%.0f%%" % (rate * 100.0)),
		})

static func affix_text(item: Resource) -> String:
	return _AffixDisplayFormatter.format_for_instance(item)

static func description_text(item: Resource, category: String) -> String:
	if item == null:
		return ""
	var data: Resource = _master_data_for_item(item, category)
	if data != null and "description" in data:
		return str(data.description).strip_edges()
	return ""

static func flavor_text(item: Resource, category: String) -> String:
	if category != "weapon" or item == null:
		return ""
	return _WeaponFlavorHelper.get_flavor_text_for_item(item)

static func _append_description_block(host: VBoxContainer, item: Resource, category: String) -> void:
	var desc: String = description_text(item, category)
	if desc.is_empty():
		return
	host.add_child(_make_rule())
	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(desc_lbl, UiTypography.SIZE_CAPTION, COLOR_SUB)
	host.add_child(desc_lbl)

static func hover_summary(item: Resource, category: String, member: Resource = null) -> String:
	if item == null:
		return ""
	var lines: PackedStringArray = PackedStringArray([short_name(item, category)])
	var stat_limit: int = 4
	for row: Dictionary in stat_rows(item, category):
		if lines.size() >= stat_limit + 1:
			break
		lines.append("%s %s" % [str(row.get("label", "")), str(row.get("value", ""))])
	var owner: String = owner_text(item)
	if owner != "装備者: なし":
		lines.append(owner)
	if member != null:
		var compare: String = compare_summary(item, category, member)
		if not compare.is_empty():
			lines.append(compare)
	return "\n".join(lines)

static func relic_hover_summary(relic_id: String) -> String:
	if relic_id.is_empty():
		return ""
	var lines: PackedStringArray = PackedStringArray([CombatPassives.relic_display_name(relic_id)])
	var desc: String = CombatPassives.relic_description(relic_id)
	if not desc.is_empty():
		if desc.length() > 72:
			desc = desc.substr(0, 69) + "..."
		lines.append(desc)
	var owner_idx: int = EquipmentUiHelper.relic_equipped_member_index(relic_id)
	if owner_idx >= 0:
		var member: Resource = GameState.get_member(owner_idx)
		if member != null:
			lines.append("装備者: %s" % str(member.display_name))
	return "\n".join(lines)

static func compare_summary(item: Resource, category: String, member: Resource) -> String:
	if item == null or member == null:
		return ""
	var equipped: Resource = _equipped_for_member(member, category)
	if equipped == null:
		return "比較: 未装備"
	if equipped == item:
		return "比較: 装備中"
	match category:
		"weapon":
			return _weapon_compare(item, equipped)
		"armor":
			return _armor_compare(item, equipped)
		"accessory":
			return _accessory_compare(item, equipped)
	return ""

static func populate_stats_panel(host: VBoxContainer, item: Resource, category: String) -> void:
	for child in host.get_children():
		child.queue_free()
	if item == null:
		host.add_child(_make_caption_label("装備を選択してください"))
		return
	var name_lbl := Label.new()
	name_lbl.text = short_name(item, category)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_display(name_lbl, UiTypography.SIZE_BODY_SMALL)
	host.add_child(name_lbl)
	host.add_child(_make_rule())
	for row in stat_rows(item, category):
		host.add_child(_make_stat_row(str(row.get("key", "")), str(row.get("label", "")), str(row.get("value", ""))))
	_append_description_block(host, item, category)
	_append_legendary_effect_block(host, item, category)
	_append_weapon_flavor_block(host, item, category)

static func populate_panel(
	host: VBoxContainer,
	item: Resource,
	category: String,
	options: Dictionary = {}
) -> void:
	for child in host.get_children():
		child.queue_free()
	if item == null:
		host.add_child(_make_caption_label("装備を選択してください"))
		return
	var compare_member: Resource = options.get("compare_member", null)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	host.add_child(header)
	var icon_tex: Texture2D = _item_icon(item, category)
	if icon_tex != null:
		var icon_wrap := Control.new()
		icon_wrap.custom_minimum_size = Vector2(HEADER_ICON_PX, HEADER_ICON_PX)
		icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(icon_wrap)
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_wrap.add_child(icon)
		var icon_size := Vector2(HEADER_ICON_PX, HEADER_ICON_PX)
		EquipmentUiHelper.apply_legendary_badge(icon_wrap, _item_rarity(item, category), icon_size)
		EquipmentUiHelper.apply_enhance_badge(icon_wrap, item, category, icon_size)
	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 2)
	header.add_child(title_col)
	var name_lbl := Label.new()
	name_lbl.text = short_name(item, category)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_display(name_lbl, UiTypography.SIZE_BODY_SMALL)
	title_col.add_child(name_lbl)
	var meta_lbl := Label.new()
	var rarity: int = _item_rarity(item, category)
	meta_lbl.text = "%s · %s" % [category_label(category), EquipmentUiHelper.rarity_stars_text(rarity)]
	UiTypography.apply_caption(meta_lbl, COLOR_SUB)
	title_col.add_child(meta_lbl)
	host.add_child(_make_rule())
	host.add_child(_make_caption_label(owner_text(item)))
	var compare_member_res: Resource = compare_member
	if compare_member_res != null:
		var compare_lbl := _make_caption_label(compare_summary(item, category, compare_member_res))
		compare_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		host.add_child(compare_lbl)
	for row in stat_rows(item, category):
		host.add_child(_make_stat_row(str(row.get("key", "")), str(row.get("label", "")), str(row.get("value", ""))))
	_append_description_block(host, item, category)
	_append_legendary_effect_block(host, item, category)
	var affix: String = affix_text(item)
	if not affix.is_empty():
		host.add_child(_make_rule())
		var affix_lbl := Label.new()
		affix_lbl.text = affix
		affix_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiTypography.apply_body(affix_lbl, UiTypography.SIZE_CAPTION, COLOR_VALUE)
		host.add_child(affix_lbl)
	_append_weapon_flavor_block(host, item, category)

static func _make_stat_row(stat_key: String, label_text: String, value_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not stat_key.is_empty():
		var tex: Texture2D = EquipmentUiTokens.stat_icon(stat_key)
		if tex != null:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.custom_minimum_size = Vector2(STAT_ICON_PX, STAT_ICON_PX)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.custom_minimum_size = Vector2(STAT_LABEL_MIN_W, 0)
	name_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_CAPTION, COLOR_LABEL)
	row.add_child(name_lbl)
	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	val_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(val_lbl, UiTypography.SIZE_CAPTION, COLOR_VALUE)
	row.add_child(val_lbl)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	return row

static func _make_caption_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(lbl, COLOR_SUB)
	return lbl

static func _make_rule() -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	return gap

static func _item_icon(item: Resource, category: String) -> Texture2D:
	match category:
		"weapon":
			return IconPaths.get_icon_texture(str(item.weapon_id), "weapon")
		"armor":
			return IconPaths.get_icon_texture(str(item.armor_id), "armor")
		"accessory":
			return IconPaths.get_icon_texture(str(item.accessory_id), "accessory")
	return null

static func _master_data_for_item(item: Resource, category: String) -> Resource:
	match category:
		"weapon":
			return DataRegistry.get_weapon_data(str(item.weapon_id))
		"armor":
			return DataRegistry.get_armor_data(str(item.armor_id))
		"accessory":
			return DataRegistry.get_accessory_data(str(item.accessory_id))
	return null

static func _item_rarity(item: Resource, category: String) -> int:
	var data: Resource = _master_data_for_item(item, category)
	if data != null and "rarity" in data:
		return int(data.rarity)
	return 0

static func _append_weapon_flavor_block(host: VBoxContainer, item: Resource, category: String) -> void:
	var flavor: String = flavor_text(item, category)
	if flavor.is_empty():
		return
	host.add_child(_make_rule())
	var flavor_lbl := Label.new()
	flavor_lbl.text = "「%s」" % flavor
	flavor_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(flavor_lbl, UiTypography.SIZE_CAPTION, COLOR_FLAVOR)
	host.add_child(flavor_lbl)

static func _armor_resist_text(item: Resource) -> String:
	if item == null:
		return ""
	var elements: Array[String] = _ArmorStatResolver.resolve_resist_elements(item)
	if elements.is_empty():
		return ""
	var names: PackedStringArray = []
	for e in elements:
		var nm: String = _ElementResolver.get_display_name(str(e))
		if not nm.is_empty():
			names.append(nm)
	var joined: String = "/".join(names)
	var mult: float = _ArmorStatResolver.resolve_resist_multiplier(item)
	if is_equal_approx(mult, 1.0):
		return joined
	var reduction: int = int(round((1.0 - mult) * 100.0))
	return "%s (-%d%%)" % [joined, reduction]

static func _armor_immunity_text(item: Resource) -> String:
	if item == null:
		return ""
	var immunities: Array[String] = _ArmorStatResolver.resolve_status_immunities(item)
	if immunities.is_empty():
		return ""
	var names: PackedStringArray = []
	for status_id in immunities:
		var effect: Resource = DataRegistry.get_status_effect(str(status_id))
		var label: String = effect.display_name if effect != null else str(status_id)
		if not label.is_empty():
			names.append(label)
	return "/".join(names)

static func _equipped_for_member(member: Resource, category: String) -> Resource:
	if member == null:
		return null
	match category:
		"weapon":
			return member.equipped_weapon
		"armor":
			return member.equipped_armor
		"accessory":
			return member.equipped_accessory
	return null

static func _weapon_compare(candidate: Resource, equipped: Resource) -> String:
	var parts: PackedStringArray = []
	var atk_diff: int = (
		_EquipmentEnhancer.get_effective_attack(candidate)
		- _EquipmentEnhancer.get_effective_attack(equipped)
	)
	parts.append("攻撃力 %s%d" % ["+" if atk_diff >= 0 else "", atk_diff])
	var spd_diff: float = float(candidate.attack_speed) - float(equipped.attack_speed)
	if not is_zero_approx(spd_diff):
		parts.append("攻撃速度 %s%.1f" % ["+" if spd_diff >= 0.0 else "", spd_diff])
	var crt_diff: float = float(candidate.critical_rate) - float(equipped.critical_rate)
	if not is_zero_approx(crt_diff):
		parts.append("会心率 %s%.0f%%" % ["+" if crt_diff >= 0.0 else "", crt_diff * 100.0])
	return "比較: " + " / ".join(parts)

static func _armor_compare(candidate: Resource, equipped: Resource) -> String:
	var parts: PackedStringArray = []
	var def_diff: int = int(candidate.rolled_defense) - int(equipped.rolled_defense)
	parts.append("防御力 %s%d" % ["+" if def_diff >= 0 else "", def_diff])
	var hp_diff: int = int(candidate.hp_bonus) - int(equipped.hp_bonus)
	if hp_diff != 0:
		parts.append("HP %s%d" % ["+" if hp_diff >= 0 else "", hp_diff])
	return "比較: " + " / ".join(parts)

static func _accessory_compare(candidate: Resource, equipped: Resource) -> String:
	var cand_data: Resource = DataRegistry.get_accessory_data(str(candidate.accessory_id))
	var eq_data: Resource = DataRegistry.get_accessory_data(str(equipped.accessory_id))
	if cand_data == null or eq_data == null:
		return "比較: —"
	var parts: PackedStringArray = []
	var hp_diff: int = (
		_AccessoryStatResolver.resolve_hp_bonus(candidate, cand_data)
		- _AccessoryStatResolver.resolve_hp_bonus(equipped, eq_data)
	)
	if hp_diff != 0:
		parts.append("HP %s%d" % ["+" if hp_diff >= 0 else "", hp_diff])
	var atk_diff: int = (
		_AccessoryStatResolver.resolve_attack_bonus(candidate, cand_data)
		- _AccessoryStatResolver.resolve_attack_bonus(equipped, eq_data)
	)
	if atk_diff != 0:
		parts.append("攻撃力 %s%d" % ["+" if atk_diff >= 0 else "", atk_diff])
	return "比較: " + " / ".join(parts) if not parts.is_empty() else "比較: 差なし"
