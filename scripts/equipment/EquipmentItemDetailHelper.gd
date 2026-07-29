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
const _EquipmentSetBonuses = preload("res://scripts/equipment/EquipmentSetBonuses.gd")
const _StatusEffectLinkHelper = preload("res://scripts/ui/StatusEffectLinkHelper.gd")

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
	var owner: Resource = GameState.find_item_equipped_owner(item)
	if owner == null:
		return "装備者: なし"
	return "装備者: %s" % str(owner.display_name)

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

static func _append_legendary_effect_block(
	host: VBoxContainer,
	item: Resource,
	category: String,
	meta_host: Node = null,
	wrap_width: int = 0,
	max_chars: int = 0
) -> void:
	var effect_text: String = _truncate_ui_text(
		equipment_legendary_effect_text(item, category), max_chars
	)
	if effect_text.is_empty():
		return
	host.add_child(_make_rule())
	var title := Label.new()
	title.text = "固有効果"
	UiTypography.apply_caption(title, COLOR_WEAPON_EFFECT)
	host.add_child(title)
	var popup_host: Node = meta_host if meta_host != null else host
	host.add_child(
		_make_detail_richtext(
			effect_text,
			UiTypography.SIZE_CAPTION,
			COLOR_WEAPON_EFFECT,
			popup_host,
			wrap_width
		)
	)


static func _append_set_bonus_block(
	host: VBoxContainer,
	item: Resource,
	category: String,
	meta_host: Node = null,
	wrap_width: int = 0,
	max_chars: int = 0
) -> void:
	if item == null:
		return
	var set_id: String = ""
	match category:
		"weapon":
			set_id = _EquipmentSetBonuses.set_id_of_weapon(str(item.weapon_id))
		"armor":
			set_id = _EquipmentSetBonuses.set_id_of_armor(str(item.armor_id))
		"accessory":
			set_id = _EquipmentSetBonuses.set_id_of_accessory(str(item.accessory_id))
	if set_id.is_empty():
		return
	var bonus_name: String = _EquipmentSetBonuses.display_name(set_id)
	var bonus_desc: String = _EquipmentSetBonuses.description(set_id)
	if bonus_name.is_empty() and bonus_desc.is_empty():
		return
	host.add_child(_make_rule())
	var title := Label.new()
	title.text = "セット加護（3部位）"
	UiTypography.apply_caption(title, Color(0.40, 0.90, 0.52))
	host.add_child(title)
	var body_text: String = _truncate_ui_text(
		"%s: %s" % [bonus_name, bonus_desc] if not bonus_name.is_empty() else bonus_desc,
		max_chars
	)
	var popup_host: Node = meta_host if meta_host != null else host
	host.add_child(
		_make_detail_richtext(
			body_text,
			UiTypography.SIZE_CAPTION,
			Color(0.62, 0.95, 0.70),
			popup_host,
			wrap_width
		)
	)


static func _truncate_ui_text(text: String, max_chars: int) -> String:
	var trimmed: String = text.strip_edges()
	if max_chars <= 0 or trimmed.length() <= max_chars:
		return trimmed
	return trimmed.substr(0, maxi(1, max_chars - 1)) + "…"


static func _make_detail_richtext(
	text: String,
	font_size: int,
	color: Color,
	meta_host: Node,
	wrap_width: int = 0
) -> RichTextLabel:
	var rtl: RichTextLabel = _StatusEffectLinkHelper.make_linked_richtext(
		text, font_size, color, meta_host
	)
	if wrap_width > 0:
		## 日本語は WORD_SMART だと1語扱いになり最小幅＝全文幅ではみ出す。
		rtl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		rtl.custom_minimum_size = Vector2(float(wrap_width), 0)
		rtl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return rtl

static func _stat_value(item: Resource, category: String, stat_key: String, value_text: String) -> String:
	## 例: 会心率 30%(10〜40)⭐️ — ランダム上下限を値の直後へ。
	var with_range: String = value_text + _EquipmentPerfectRollHelper.range_suffix(item, category, stat_key)
	return _EquipmentPerfectRollHelper.value_label(
		with_range,
		_EquipmentPerfectRollHelper.is_ui_stat_perfect(item, category, stat_key)
	)

static func stat_rows(item: Resource, category: String) -> Array:
	var rows: Array = []
	if item == null:
		return rows
	var _EquipmentRandomMods = load("res://scripts/equipment/EquipmentRandomMods.gd")
	_EquipmentRandomMods.ensure_migrated(item)
	## P3-EQ-DIABLO-001: 固定行（武器／防具）→ ランダム行。装飾はランダムのみ。
	match category:
		"weapon":
			rows.append({
				"key": "attack",
				"label": "攻撃力",
				"value": str(_EquipmentEnhancer.get_effective_attack(item)),
			})
		"armor":
			rows.append({
				"key": "defense",
				"label": "防御力",
				"value": str(_EquipmentEnhancer.effective_armor_defense(item)),
			})
		"accessory":
			pass
		_:
			return rows
	for mod: Variant in _EquipmentRandomMods.get_mods(item):
		if not mod is Dictionary:
			continue
		var line: String = _EquipmentRandomMods.format_mod_line(mod as Dictionary)
		rows.append({
			"key": EquipmentUiTokens.detail_stat_icon_key(mod as Dictionary),
			"label": "",
			"value": line,
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
	## 追加効果行は廃止（ランダムステに統合）。
	return ""

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

static func _append_description_block(
	host: VBoxContainer,
	item: Resource,
	category: String,
	wrap_width: int = 0,
	meta_host: Node = null,
	max_chars: int = 0
) -> void:
	var desc: String = _truncate_ui_text(description_text(item, category), max_chars)
	if desc.is_empty():
		return
	host.add_child(_make_rule())
	var popup_host: Node = meta_host if meta_host != null else host
	host.add_child(
		_make_detail_richtext(
			desc,
			UiTypography.SIZE_CAPTION,
			COLOR_SUB,
			popup_host,
			wrap_width
		)
	)

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

static func populate_stats_panel(
	host: VBoxContainer,
	item: Resource,
	category: String,
	meta_host: Node = null
) -> void:
	for child in host.get_children():
		child.queue_free()
	if item == null:
		host.add_child(_make_caption_label("装備を選択してください"))
		return
	var popup_host: Node = meta_host if meta_host != null else host
	var name_lbl := Label.new()
	name_lbl.text = short_name(item, category)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_display(name_lbl, UiTypography.SIZE_BODY_SMALL)
	host.add_child(name_lbl)
	host.add_child(_make_rule())
	for row in stat_rows(item, category):
		host.add_child(_make_stat_row(str(row.get("key", "")), str(row.get("label", "")), str(row.get("value", ""))))
	_append_description_block(host, item, category, 0, popup_host)
	_append_legendary_effect_block(host, item, category, popup_host)
	_append_set_bonus_block(host, item, category, popup_host)
	var affix: String = affix_text(item)
	if not affix.is_empty():
		host.add_child(_make_rule())
		host.add_child(
			_StatusEffectLinkHelper.make_linked_richtext(
				affix,
				UiTypography.SIZE_CAPTION,
				COLOR_VALUE,
				popup_host
			)
		)
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
	var show_owner: bool = bool(options.get("show_owner", true))
	var header_icon_px: int = int(options.get("header_icon_px", HEADER_ICON_PX))
	var indent_left: int = maxi(0, int(options.get("indent_left", 0)))
	var indent_right: int = maxi(0, int(options.get("indent_right", 0)))
	var desc_wrap_width: int = maxi(0, int(options.get("desc_wrap_width", 0)))
	var desc_max_chars: int = maxi(0, int(options.get("desc_max_chars", 0)))
	var effect_max_chars: int = maxi(0, int(options.get("effect_max_chars", 0)))
	var content_pad_top: int = maxi(0, int(options.get("content_pad_top", 0)))
	var framed_icon: bool = bool(options.get("framed_icon", false))
	var show_enhance_badge: bool = bool(options.get("show_enhance_badge", true))
	## レアロゴ基準辺。未指定時はアイコン辺。完了ポップは装備一覧 INV_CELL に合わせる。
	var badge_ref_px: int = maxi(1, int(options.get("badge_ref_px", header_icon_px)))
	var value_color: Color = COLOR_VALUE
	if options.has("value_color"):
		value_color = options["value_color"] as Color
	var popup_host: Node = options.get("meta_host", null) as Node
	if popup_host == null:
		popup_host = host
	var content_host: VBoxContainer = host
	if indent_left > 0 or indent_right > 0 or content_pad_top > 0:
		var pad := MarginContainer.new()
		pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pad.add_theme_constant_override("margin_left", indent_left)
		pad.add_theme_constant_override("margin_right", indent_right)
		pad.add_theme_constant_override("margin_top", content_pad_top)
		host.add_child(pad)
		content_host = VBoxContainer.new()
		content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_host.add_theme_constant_override("separation", host.get_theme_constant("separation"))
		pad.add_child(content_host)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	content_host.add_child(header)
	var rarity: int = _item_rarity(item, category)
	var item_id: String = _item_id(item, category)
	var icon_tex: Texture2D = _item_icon(item, category)
	var badge_size := Vector2(float(badge_ref_px), float(badge_ref_px))
	if icon_tex != null:
		if framed_icon:
			var frame := _make_framed_item_icon(item_id, category, rarity, header_icon_px, icon_tex)
			header.add_child(frame)
			EquipmentUiHelper.apply_rarity_badges(frame, rarity, badge_size)
			if show_enhance_badge:
				EquipmentUiHelper.apply_enhance_badge(frame, item, category, badge_size)
		else:
			var icon_wrap := Control.new()
			icon_wrap.custom_minimum_size = Vector2(header_icon_px, header_icon_px)
			icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			header.add_child(icon_wrap)
			var icon := TextureRect.new()
			icon.texture = icon_tex
			icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_wrap.add_child(icon)
			EquipmentUiHelper.apply_rarity_badges(icon_wrap, rarity, badge_size)
			if show_enhance_badge:
				EquipmentUiHelper.apply_enhance_badge(icon_wrap, item, category, badge_size)
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
	meta_lbl.text = "%s · %s" % [category_label(category), EquipmentUiHelper.rarity_label_text(rarity)]
	UiTypography.apply_caption(meta_lbl, COLOR_SUB)
	title_col.add_child(meta_lbl)
	content_host.add_child(_make_rule())
	if show_owner:
		content_host.add_child(_make_caption_label(owner_text(item)))
	var compare_member_res: Resource = compare_member
	if compare_member_res != null:
		var compare_lbl := _make_caption_label(compare_summary(item, category, compare_member_res))
		compare_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content_host.add_child(compare_lbl)
	for row in stat_rows(item, category):
		content_host.add_child(
			_make_stat_row(
				str(row.get("key", "")),
				str(row.get("label", "")),
				str(row.get("value", "")),
				value_color
			)
		)
	_append_description_block(
		content_host, item, category, desc_wrap_width, popup_host, desc_max_chars
	)
	_append_legendary_effect_block(
		content_host, item, category, popup_host, desc_wrap_width, effect_max_chars
	)
	_append_set_bonus_block(
		content_host, item, category, popup_host, desc_wrap_width, effect_max_chars
	)
	var affix2: String = _truncate_ui_text(affix_text(item), effect_max_chars)
	if not affix2.is_empty():
		content_host.add_child(_make_rule())
		content_host.add_child(
			_make_detail_richtext(
				affix2,
				UiTypography.SIZE_CAPTION,
				value_color,
				popup_host,
				desc_wrap_width
			)
		)
	_append_weapon_flavor_block(content_host, item, category, desc_wrap_width)


static func _add_wrapped_label(parent: Control, lbl: Label, wrap_width: int) -> void:
	if wrap_width <= 0:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(lbl)
		return
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(wrap_width, 0)
	box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## 日本語は空白無し1語扱いで WORD_SMART が全文幅になる。
	lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	box.add_child(lbl)
	parent.add_child(box)


static func _make_stat_row(
	stat_key: String,
	label_text: String,
	value_text: String,
	value_color: Color = COLOR_VALUE
) -> HBoxContainer:
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
	if label_text.is_empty():
		name_lbl.visible = false
		name_lbl.custom_minimum_size = Vector2(0, 0)
	else:
		name_lbl.custom_minimum_size = Vector2(STAT_LABEL_MIN_W, 0)
	name_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_CAPTION, COLOR_LABEL)
	row.add_child(name_lbl)
	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	## 数値行は折り返さず1行で見せる（毒付与の範囲表記など）。
	val_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	val_lbl.clip_text = false
	val_lbl.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(val_lbl, UiTypography.SIZE_CAPTION, value_color)
	row.add_child(val_lbl)
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

static func _item_id(item: Resource, category: String) -> String:
	if item == null:
		return ""
	match category:
		"weapon":
			return str(item.weapon_id)
		"armor":
			return str(item.armor_id)
		"accessory":
			return str(item.accessory_id)
	return ""


static func _make_framed_item_icon(
	item_id: String,
	category: String,
	rarity: int,
	cell_px: int,
	icon_tex: Texture2D
) -> Control:
	## 外側は自由配置の Control。PanelContainer 直下にレアロゴを足すと全面伸長する。
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(cell_px, cell_px)
	wrap.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wrap.clip_contents = true
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBox = EquipmentUiTokens.rarity_slot_style(rarity, false, cell_px)
	if style != null:
		style = style.duplicate()
		style.set_content_margin_all(0.0)
		frame.add_theme_stylebox_override("panel", style)
	wrap.add_child(frame)
	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(host)
	var tex: Texture2D = icon_tex
	if tex != null and category == "weapon" and not item_id.is_empty():
		tex = IconPaths.display_texture_for_weapon(item_id, tex)
	var inset: int = EquipmentUiTokens.icon_inset_for_item(
		cell_px,
		EquipmentUiTokens.INV_CELL_DESIGN_PX,
		item_id,
		category
	)
	var icon := TextureRect.new()
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = float(inset)
	icon.offset_top = float(inset)
	icon.offset_right = -float(inset)
	icon.offset_bottom = -float(inset)
	host.add_child(icon)
	return wrap


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

static func _append_weapon_flavor_block(
	host: VBoxContainer,
	item: Resource,
	category: String,
	wrap_width: int = 0
) -> void:
	var flavor: String = flavor_text(item, category)
	if flavor.is_empty():
		return
	host.add_child(_make_rule())
	var flavor_lbl := Label.new()
	flavor_lbl.text = "「%s」" % flavor
	UiTypography.apply_body(flavor_lbl, UiTypography.SIZE_CAPTION, COLOR_FLAVOR)
	_add_wrapped_label(host, flavor_lbl, wrap_width)

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
