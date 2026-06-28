extends Control

const _AffixDisplayFormatter = preload("res://scripts/equipment/AffixDisplayFormatter.gd")
const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")
const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")

# CombatController.BASE_MEMBER_HP と同値（表示用の素HP）。
const BASE_MEMBER_HP: int = 30
# クリティカルダメージ倍率（DungeonScene.CRITICAL_MULTIPLIER と同値）。
const CRIT_DAMAGE_MULT: float = 1.5
const GRID_COLUMNS: int = 6
const CELL_SIZE: Vector2 = Vector2(72, 72)

# レア度別の枠色（COMMON/RARE/EPIC/LEGENDARY）。
const RARITY_COLORS: Array[Color] = [
	Color(0.60, 0.60, 0.60),
	Color(0.30, 0.55, 0.95),
	Color(0.70, 0.45, 0.95),
	Color(0.95, 0.75, 0.25),
]

@onready var _button_back: Button = $VBoxContainer/HeaderRow/ButtonBack
@onready var _label_gold: Label = $VBoxContainer/HeaderRow/LabelGold
@onready var _member_row: HBoxContainer = $VBoxContainer/MemberSelectRow
@onready var _label_stars: Label = $VBoxContainer/CharacterCard/CardRow/PortraitBox/LabelStars
@onready var _portrait_art: TextureRect = $VBoxContainer/CharacterCard/CardRow/PortraitBox/Portrait/PortraitArt
@onready var _portrait_glyph: Label = $VBoxContainer/CharacterCard/CardRow/PortraitBox/Portrait/PortraitGlyph
@onready var _label_name: Label = $VBoxContainer/CharacterCard/CardRow/InfoBox/LabelName
@onready var _label_job_level: Label = $VBoxContainer/CharacterCard/CardRow/InfoBox/LabelJobLevel
@onready var _stats_grid: GridContainer = $VBoxContainer/CharacterCard/CardRow/InfoBox/StatsGrid
@onready var _button_unequip_all: Button = $VBoxContainer/CharacterCard/CardRow/InfoBox/ButtonsRow/ButtonUnequipAll
@onready var _slots_row: HBoxContainer = $VBoxContainer/EquipSlotsRow
@onready var _tabs: TabContainer = $VBoxContainer/TabContainer
@onready var _effects_grid: GridContainer = $VBoxContainer/TabContainer/TabEquip/EquipContent/EffectsGrid
@onready var _category_row: HBoxContainer = $VBoxContainer/TabContainer/TabEquip/EquipContent/CategoryRow
@onready var _inventory_grid: GridContainer = $VBoxContainer/TabContainer/TabEquip/EquipContent/InventoryGrid
@onready var _skill_content: VBoxContainer = $VBoxContainer/TabContainer/TabSkill/SkillContent

var _selected_member_index: int = 0
# 所持一覧のカテゴリフィルタ: "all" / "weapon" / "armor" / "accessory"
var _inventory_filter: String = "all"

func _ready() -> void:
	_tabs.set_tab_title(0, "装備")
	_tabs.set_tab_title(1, "スキル")
	_button_back.pressed.connect(_on_back_pressed)
	_button_unequip_all.pressed.connect(_on_unequip_all_pressed)
	for i in 3:
		var btn: Button = _member_row.get_node("ButtonMember%d" % i) as Button
		btn.pressed.connect(_on_member_selected.bind(i))
	_connect_category_buttons()
	_inventory_grid.columns = GRID_COLUMNS
	_refresh_member_buttons()
	_refresh_display()

func _connect_category_buttons() -> void:
	var defs: Array = [
		["ButtonCatAll", "all"],
		["ButtonCatWeapon", "weapon"],
		["ButtonCatArmor", "armor"],
		["ButtonCatAccessory", "accessory"],
	]
	for d in defs:
		var btn: Button = _category_row.get_node(d[0]) as Button
		btn.pressed.connect(_on_category_selected.bind(str(d[1])))

func _on_category_selected(filter_id: String) -> void:
	_inventory_filter = filter_id
	_refresh_category_buttons()
	_rebuild_inventory_grid()

func _refresh_category_buttons() -> void:
	var map: Dictionary = {
		"ButtonCatAll": "all",
		"ButtonCatWeapon": "weapon",
		"ButtonCatArmor": "armor",
		"ButtonCatAccessory": "accessory",
	}
	for node_name in map:
		var btn: Button = _category_row.get_node(node_name) as Button
		btn.button_pressed = (map[node_name] == _inventory_filter)

func _on_member_selected(member_index: int) -> void:
	_selected_member_index = member_index
	_refresh_member_buttons()
	_refresh_display()

func _refresh_member_buttons() -> void:
	for i in 3:
		var btn: Button = _member_row.get_node("ButtonMember%d" % i) as Button
		if i < GameState.party_members.size():
			var member: Resource = GameState.party_members[i]
			btn.text = member.display_name
			btn.disabled = i == _selected_member_index
		else:
			btn.text = "—"
			btn.disabled = true

func _refresh_display() -> void:
	_update_header()
	_update_character_card()
	_rebuild_equip_slots()
	_rebuild_effects()
	_refresh_category_buttons()
	_rebuild_inventory_grid()
	_rebuild_skill_tab()

func _update_header() -> void:
	_label_gold.text = "🪙 %d" % GameState.gold

# ---- キャラクターカード ----
func _update_character_card() -> void:
	var member: Resource = GameState.get_member(_selected_member_index)
	if member == null:
		_label_name.text = "—"
		_label_job_level.text = ""
		_portrait_glyph.text = "?"
		return
	_label_name.text = member.display_name
	var job_mods: Dictionary = _JobStatCalculator.get_member_modifiers(member)
	var job_name: String = str(job_mods.get("display_name", member.job_id))
	_label_job_level.text = "Lv%d  %s" % [int(member.level), job_name]
	_portrait_art.texture = null
	_portrait_glyph.text = member.display_name.substr(0, 1)
	_label_stars.text = "★★★★★"
	var stats: Dictionary = _compute_member_stats(_selected_member_index)
	_populate_stat_grid(stats)

func _populate_stat_grid(stats: Dictionary) -> void:
	for child in _stats_grid.get_children():
		child.queue_free()
	var rows: Array = [
		["HP", str(stats["hp"])],
		["攻撃力", str(stats["attack"])],
		["防御力", str(stats["defense"])],
		["速度", "%.1f" % stats["speed"]],
		["クリティカル率", "%.0f%%" % (stats["crit_rate"] * 100.0)],
		["クリティカルダメージ", "%.0f%%" % (stats["crit_damage"] * 100.0)],
	]
	for r in rows:
		_stats_grid.add_child(_make_dim_label(str(r[0]) + ":"))
		_stats_grid.add_child(_make_value_label(str(r[1])))

func _make_dim_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.72, 0.69, 0.62))
	return l

func _make_value_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l

# ---- 装備中の効果（装備品由来のボーナス集計） ----
func _rebuild_effects() -> void:
	for child in _effects_grid.get_children():
		child.queue_free()
	var idx: int = _selected_member_index
	var armor: Resource = GameState.get_member_equipped_armor(idx)
	var acc_data: Resource = _accessory_data(GameState.get_member_equipped_accessory(idx))
	var affix: Dictionary = _AffixStatCalculator.get_bonuses(idx)
	var atk_bonus: int = int(affix.get("attack_flat", 0)) + (acc_data.attack_bonus if acc_data != null else 0)
	var def_bonus: int = int(affix.get("defense_flat", 0)) + (acc_data.defense_bonus if acc_data != null else 0)
	if armor != null:
		def_bonus += armor.rolled_defense
	var hp_bonus: int = int(affix.get("hp_flat", 0)) + (acc_data.hp_bonus if acc_data != null else 0)
	if armor != null:
		hp_bonus += armor.hp_bonus
	var crit_bonus: float = float(affix.get("crit_rate_add", 0.0)) + (acc_data.crit_rate_bonus if acc_data != null else 0.0)
	var rows: Array = []
	if atk_bonus != 0:
		rows.append(["攻撃力", "+%d" % atk_bonus])
	if def_bonus != 0:
		rows.append(["防御力", "+%d" % def_bonus])
	if hp_bonus != 0:
		rows.append(["HP", "+%d" % hp_bonus])
	if not is_zero_approx(crit_bonus):
		rows.append(["クリティカル率", "+%.0f%%" % (crit_bonus * 100.0)])
	if rows.is_empty():
		_effects_grid.add_child(_make_dim_label("（装備ボーナスなし）"))
		return
	for r in rows:
		_effects_grid.add_child(_make_dim_label(str(r[0]) + ":"))
		_effects_grid.add_child(_make_value_label(str(r[1])))

# ---- 装備スロット ----
func _rebuild_equip_slots() -> void:
	for child in _slots_row.get_children():
		child.queue_free()
	var idx: int = _selected_member_index
	_slots_row.add_child(_make_slot("武器", "weapon", GameState.get_member_equipped_weapon(idx)))
	_slots_row.add_child(_make_slot("防具", "armor", GameState.get_member_equipped_armor(idx)))
	_slots_row.add_child(_make_slot("装飾品", "accessory", GameState.get_member_equipped_accessory(idx)))

func _make_slot(slot_label: String, category: String, item: Resource) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var cap := Label.new()
	cap.text = slot_label
	cap.add_theme_color_override("font_color", Color(0.72, 0.69, 0.62))
	box.add_child(cap)
	var btn := Button.new()
	btn.custom_minimum_size = CELL_SIZE
	if item != null:
		var icon: Texture2D = _item_icon(item, category)
		if icon != null:
			btn.icon = icon
			btn.expand_icon = true
		btn.tooltip_text = _item_label(item, category)
		btn.add_theme_stylebox_override("normal", _rarity_box(_item_rarity(item, category), false))
	else:
		btn.text = "—"
	btn.pressed.connect(_on_slot_pressed.bind(category))
	box.add_child(btn)
	return box

func _on_slot_pressed(category: String) -> void:
	_inventory_filter = category
	_refresh_category_buttons()
	_rebuild_inventory_grid()
	_tabs.current_tab = 0

# ---- 所持一覧グリッド ----
func _rebuild_inventory_grid() -> void:
	for child in _inventory_grid.get_children():
		child.queue_free()
	var entries: Array = []
	if _inventory_filter == "all" or _inventory_filter == "weapon":
		for it in $EquipmentController.get_appraised_weapons_for_member(_selected_member_index):
			entries.append({"item": it, "category": "weapon"})
	if _inventory_filter == "all" or _inventory_filter == "armor":
		for it in $EquipmentController.get_appraised_armors_for_member(_selected_member_index):
			entries.append({"item": it, "category": "armor"})
	if _inventory_filter == "all" or _inventory_filter == "accessory":
		for it in $EquipmentController.get_appraised_accessories_for_member(_selected_member_index):
			entries.append({"item": it, "category": "accessory"})
	if entries.is_empty():
		_inventory_grid.add_child(_make_dim_label("該当する装備がありません"))
		return
	for e in entries:
		_inventory_grid.add_child(_make_item_cell(e["item"], str(e["category"])))

func _make_item_cell(item: Resource, category: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = CELL_SIZE
	var icon: Texture2D = _item_icon(item, category)
	if icon != null:
		btn.icon = icon
		btn.expand_icon = true
	var rarity: int = _item_rarity(item, category)
	var equipped: Resource = _equipped_for_category(category)
	var is_equipped: bool = item == equipped
	btn.tooltip_text = "%s  %s" % [_item_label(item, category), _compare_text(item, category)]
	btn.pressed.connect(_on_cell_pressed.bind(item, category))
	if is_equipped:
		btn.disabled = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.modulate = Color(0.5, 0.5, 0.5, 0.7)
		btn.add_theme_stylebox_override("disabled", _rarity_box(rarity, true))
	else:
		btn.add_theme_stylebox_override("normal", _rarity_box(rarity, false))
		btn.add_theme_stylebox_override("hover", _rarity_box(rarity, true))
	return btn

func _on_cell_pressed(item: Resource, category: String) -> void:
	match category:
		"weapon":
			$EquipmentController.equip_weapon(item, _selected_member_index)
		"armor":
			$EquipmentController.equip_armor(item, _selected_member_index)
		"accessory":
			$EquipmentController.equip_accessory(item, _selected_member_index)
	_refresh_display()

func _on_unequip_all_pressed() -> void:
	$EquipmentController.unequip_weapon(_selected_member_index)
	$EquipmentController.unequip_armor(_selected_member_index)
	$EquipmentController.unequip_accessory(_selected_member_index)
	_refresh_display()

# ---- レア度枠スタイル ----
func _rarity_box(rarity: int, highlight: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	var col: Color = RARITY_COLORS[clampi(rarity, 0, RARITY_COLORS.size() - 1)]
	sb.bg_color = Color(0.10, 0.09, 0.07, 0.95) if not highlight else Color(0.18, 0.16, 0.12, 1.0)
	sb.set_border_width_all(2)
	sb.border_color = col
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(4.0)
	return sb

# ---- アイテム情報ヘルパー ----
func _equipped_for_category(category: String) -> Resource:
	match category:
		"weapon":
			return GameState.get_member_equipped_weapon(_selected_member_index)
		"armor":
			return GameState.get_member_equipped_armor(_selected_member_index)
		"accessory":
			return GameState.get_member_equipped_accessory(_selected_member_index)
	return null

func _item_data(item: Resource, category: String) -> Resource:
	if item == null:
		return null
	match category:
		"weapon":
			return load("res://resources/weapons/" + item.weapon_id + ".tres")
		"armor":
			return load("res://resources/armors/" + item.armor_id + ".tres")
		"accessory":
			return load("res://resources/accessories/" + item.accessory_id + ".tres")
	return null

func _accessory_data(item: Resource) -> Resource:
	if item == null:
		return null
	return load("res://resources/accessories/" + item.accessory_id + ".tres")

func _item_rarity(item: Resource, category: String) -> int:
	var data: Resource = _item_data(item, category)
	if data != null and "rarity" in data:
		return int(data.rarity)
	return 0

func _item_icon(item: Resource, category: String) -> Texture2D:
	match category:
		"weapon":
			return IconPaths.get_icon_texture(item.weapon_id, "weapon")
		"armor":
			return IconPaths.get_icon_texture(item.armor_id, "armor")
		"accessory":
			return IconPaths.get_icon_texture(item.accessory_id, "accessory")
	return null

func _item_label(item: Resource, category: String) -> String:
	match category:
		"weapon":
			var wt: String = "%s  ATK %d  SPD %.1f  CRT %.0f%%" % [
				DataRegistry.get_weapon_name(item.weapon_id), item.rolled_attack, item.attack_speed, item.critical_rate * 100.0
			]
			return _AffixDisplayFormatter.append_to_text(wt, item)
		"armor":
			var at: String = "%s  DEF %d  HP+%d  WGT %.1f" % [
				DataRegistry.get_armor_name(item.armor_id), item.rolled_defense, item.hp_bonus, item.weight
			]
			return _AffixDisplayFormatter.append_to_text(at, item)
		"accessory":
			var acc_data: Resource = _accessory_data(item)
			var act: String
			if acc_data != null:
				act = "%s  HP+%d  ATK+%d  DEF+%d  CRT+%.0f%%  LCK+%.1f" % [
					DataRegistry.get_accessory_name(item.accessory_id),
					acc_data.hp_bonus, acc_data.attack_bonus, acc_data.defense_bonus,
					acc_data.crit_rate_bonus * 100.0, acc_data.luck_bonus,
				]
			else:
				act = DataRegistry.get_accessory_name(item.accessory_id)
			return _AffixDisplayFormatter.append_to_text(act, item)
	return ""

func _compare_text(candidate: Resource, category: String) -> String:
	var equipped: Resource = _equipped_for_category(category)
	if equipped == null:
		return "（未装備）"
	if candidate == equipped:
		return "（装備中）"
	match category:
		"weapon":
			return _weapon_compare(candidate, equipped)
		"armor":
			return _armor_compare(candidate, equipped)
		"accessory":
			return _accessory_compare(candidate, equipped)
	return ""

func _weapon_compare(candidate: Resource, equipped: Resource) -> String:
	var parts: PackedStringArray = []
	var atk_diff: int = candidate.rolled_attack - equipped.rolled_attack
	parts.append("ATK %s%d" % ["+" if atk_diff >= 0 else "", atk_diff])
	var spd_diff: float = candidate.attack_speed - equipped.attack_speed
	if not is_zero_approx(spd_diff):
		parts.append("SPD %s%.1f" % ["+" if spd_diff >= 0.0 else "", spd_diff])
	var crt_diff: float = candidate.critical_rate - equipped.critical_rate
	if not is_zero_approx(crt_diff):
		parts.append("CRT %s%.0f%%" % ["+" if crt_diff >= 0.0 else "", crt_diff * 100.0])
	return "[%s]" % " | ".join(parts)

func _armor_compare(candidate: Resource, equipped: Resource) -> String:
	var parts: PackedStringArray = []
	var def_diff: int = candidate.rolled_defense - equipped.rolled_defense
	if def_diff != 0:
		parts.append("DEF %s%d" % ["+" if def_diff >= 0 else "", def_diff])
	var hp_diff: int = candidate.hp_bonus - equipped.hp_bonus
	if hp_diff != 0:
		parts.append("HP %s%d" % ["+" if hp_diff >= 0 else "", hp_diff])
	if parts.is_empty():
		return "[±0]"
	return "[%s]" % " | ".join(parts)

func _accessory_compare(candidate: Resource, equipped: Resource) -> String:
	var c_data: Resource = _accessory_data(candidate)
	var e_data: Resource = _accessory_data(equipped)
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

# ---- ステータス計算（戦闘式と整合する表示用集計） ----
func _compute_member_stats(idx: int) -> Dictionary:
	var member: Resource = GameState.get_member(idx)
	var weapon: Resource = GameState.get_member_equipped_weapon(idx)
	var armor: Resource = GameState.get_member_equipped_armor(idx)
	var acc_data: Resource = _accessory_data(GameState.get_member_equipped_accessory(idx))
	var affix: Dictionary = _AffixStatCalculator.get_bonuses(idx)
	var job: Dictionary = _JobStatCalculator.get_member_modifiers(member)
	var level: int = int(member.level) if member != null else 1
	var hp: int = BASE_MEMBER_HP
	if armor != null:
		hp += armor.hp_bonus
	if acc_data != null:
		hp += acc_data.hp_bonus
	hp += int(affix.get("hp_flat", 0))
	hp += LevelSystem.level_hp_bonus(level)
	hp = int(round(float(hp) * float(job.get("hp_multiplier", 1.0))))
	var attack: int = 0
	if weapon != null:
		attack = weapon.rolled_attack
	if acc_data != null:
		attack += acc_data.attack_bonus
	attack += int(affix.get("attack_flat", 0))
	attack += LevelSystem.level_attack_bonus(level)
	var atk_mult: float = float(job.get("attack_multiplier", 1.0))
	if weapon != null:
		atk_mult *= _JobStatCalculator.get_preferred_weapon_multiplier(member, DataRegistry.get_weapon_data(weapon.weapon_id))
	attack = int(round(float(attack) * atk_mult))
	var defense: int = 0
	if armor != null:
		defense = armor.rolled_defense
	if acc_data != null:
		defense += acc_data.defense_bonus
	defense += int(affix.get("defense_flat", 0))
	defense = int(round(float(defense) * float(job.get("defense_multiplier", 1.0))))
	var speed: float = weapon.attack_speed if weapon != null else 1.0
	var crit: float = (weapon.critical_rate if weapon != null else 0.0)
	if acc_data != null:
		crit += acc_data.crit_rate_bonus
	crit += float(affix.get("crit_rate_add", 0.0))
	return {
		"hp": hp,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"crit_rate": crit,
		"crit_damage": CRIT_DAMAGE_MULT,
	}

# ---- スキルタブ（P3-D077） ----
func _rebuild_skill_tab() -> void:
	var member: Resource = GameState.get_member(_selected_member_index)
	var slots_label: Label = _skill_content.get_node("LabelSkillSlots") as Label
	var list: Node = _skill_content.get_node("SkillList")
	for child in list.get_children():
		child.queue_free()
	if member == null:
		slots_label.text = "装備中スキル: —"
		return
	var equipped: Array[String] = GameState.get_equipped_skill_ids(member)
	var equipped_names: PackedStringArray = []
	for sid in equipped:
		equipped_names.append(_skill_label_name(sid))
	var shown: String = " / ".join(equipped_names) if not equipped_names.is_empty() else "なし"
	slots_label.text = "装備中スキル (%d/%d): %s" % [equipped.size(), Constants.MAX_EQUIPPED_SKILLS, shown]
	var job: Resource = DataRegistry.get_job_data(member.job_id)
	if job == null:
		return
	for raw_sid in job.learnable_skill_ids:
		var sid: String = str(raw_sid)
		var skill_data: Resource = DataRegistry.get_skill_data(sid)
		if skill_data == null:
			continue
		var is_equipped: bool = equipped.has(sid)
		var row := HBoxContainer.new()
		var info := Label.new()
		info.text = _skill_info_text(skill_data)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.add_child(info)
		var btn := Button.new()
		btn.text = "解除" if is_equipped else "装備"
		btn.disabled = (not is_equipped) and equipped.size() >= Constants.MAX_EQUIPPED_SKILLS
		btn.pressed.connect(_on_skill_toggle_pressed.bind(sid))
		row.add_child(btn)
		list.add_child(row)

func _skill_label_name(skill_id: String) -> String:
	var sd: Resource = DataRegistry.get_skill_data(skill_id)
	if sd != null and not sd.display_name.is_empty():
		return sd.display_name
	return skill_id

func _skill_info_text(skill_data: Resource) -> String:
	match skill_data.effect_type:
		"heal":
			# HEAL_SKILL_BASE(=14) と同期。最も負傷した味方を回復。
			var amt: int = int(round(skill_data.power_multiplier * 14.0))
			return "%s  回復+%d  CD%.1fs" % [skill_data.display_name, amt, skill_data.cooldown]
		"buff":
			var parts_buff: PackedStringArray = [skill_data.display_name]
			var eff_b: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
			if eff_b != null:
				var up: int = int(round((eff_b.outgoing_damage_multiplier - 1.0) * 100.0))
				if up != 0:
					parts_buff.append("味方与ダメ+%d%%" % up)
				parts_buff.append("%dtick" % eff_b.duration_ticks)
			parts_buff.append("CD%.1fs" % skill_data.cooldown)
			return "  ".join(parts_buff)
	var parts: PackedStringArray = [
		skill_data.display_name,
		"威力x%.2f" % skill_data.power_multiplier,
		"CD%.1fs" % skill_data.cooldown,
	]
	if not str(skill_data.element).is_empty():
		parts.append("属性:%s" % skill_data.element)
	if not str(skill_data.apply_status_id).is_empty() and skill_data.apply_status_chance > 0.0:
		var eff: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
		var st_name: String = eff.display_name if eff != null else str(skill_data.apply_status_id)
		parts.append("%s%.0f%%" % [st_name, skill_data.apply_status_chance * 100.0])
	return "  ".join(parts)

func _on_skill_toggle_pressed(skill_id: String) -> void:
	var member: Resource = GameState.get_member(_selected_member_index)
	if member == null:
		return
	GameState.toggle_member_skill(member, skill_id)
	_rebuild_skill_tab()

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
