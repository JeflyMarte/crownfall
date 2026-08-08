class_name EquipmentUiHelper
extends RefCounted

## 装備レア表示 SSOT（P3-UI-RARITY-NREL-001）。キャラ★個数とは別。
## N＜R＜E＜L（＋M神話／エンシェントレア）。セル上の文字バッジはロゴ画像へ置換。
const RARITY_CODES: Array[String] = ["N", "R", "E", "L", "M", "エンシェントレア"]
## 装備セル左上のレアリティロゴ位置（N/R/E／L／M／エンシェント共通）。
const RARITY_BADGE_POS: Vector2 = Vector2(5.0, 3.0)
## 装備Lv（左下）。炉研ぎ +N は右下。ロックも右下（+N の左へ寄せる）。
const EQUIP_LEVEL_BADGE_POS: Vector2 = Vector2(4.0, -14.0)
## 詳細ボタン等の文言用（セル表示は ICO_UI_EquipLock）。
const LOCK_BADGE_TEXT: String = "錠"
const LOCK_BADGE_ICON_PATH: String = "res://assets/ui/equipment/ICO_UI_EquipLock.png"
## セル短辺に対するロックアイコン比。
const LOCK_BADGE_RATIO: float = 0.30
const LEVEL_CAP: int = LevelSystem.MAX_LEVEL

const SORT_LABELS: Dictionary = {
	"rarity": "レアリティ",
	"name": "名前",
}

const EQUIPPED_FILTER_LABELS: Dictionary = {
	"all": "すべて",
	"equipped": "装備中",
	"unequipped": "未装備",
	## ランダム行が上限（★）に1本以上到達した武／防／飾。
	"max": "MAXあり",
}

const CATEGORY_LABELS: Dictionary = {
	"all": "すべて",
	"weapon": "武器",
	"armor": "防具",
	"accessory": "装飾",
	"relic": "レリック",
}

static var _lock_badge_tex: Texture2D


static func lock_badge_size(cell_size: Vector2) -> Vector2:
	var side: float = minf(cell_size.x, cell_size.y) * LOCK_BADGE_RATIO
	return Vector2(side, side)


static func lock_badge_texture() -> Texture2D:
	if _lock_badge_tex != null:
		return _lock_badge_tex
	if ResourceLoader.exists(LOCK_BADGE_ICON_PATH):
		_lock_badge_tex = load(LOCK_BADGE_ICON_PATH) as Texture2D
	return _lock_badge_tex

static func category_label(category: String) -> String:
	return str(CATEGORY_LABELS.get(category, category))

static func rarity_code(rarity: int) -> String:
	return RARITY_CODES[clampi(rarity, 0, RARITY_CODES.size() - 1)]

static func rarity_gem(rarity: int) -> String:
	return rarity_code(rarity)

## キャラ／助っ人用★個数（装備レアではない）。
static func stars_text(rarity: int) -> String:
	return RosterUiHelper.stars_text(clampi(rarity, 1, 5))

static func level_line(level: int, max_level: int = LEVEL_CAP) -> String:
	return "Lv.%d / %d" % [clampi(level, 1, max_level), max_level]

## アイコン隅バッジ用。ロゴ画像を使うため文字は重ねない。
static func rarity_stars_text(_rarity: int) -> String:
	return ""

## 詳細・結果などテキスト行用（SET＝エンシェントレア）。
static func rarity_label_text(rarity: int) -> String:
	return rarity_code(rarity)

static func enhance_badge(item: Resource, category: String) -> String:
	if category != "weapon" or item == null:
		return ""
	var level: int = EquipmentEnhancer.get_enhance_level(item)
	if level <= 0:
		return ""
	return "+%d" % level

static func enhance_badge_font_size(cell_height: float) -> int:
	return maxi(14, int(cell_height * 0.22))

static func apply_enhance_badge(
	parent: Control,
	item: Resource,
	category: String,
	cell_size: Vector2,
	color: Color = Color(0.95, 0.78, 0.28, 1.0)
) -> void:
	var text: String = enhance_badge(item, category)
	if text.is_empty():
		return
	var font_size: int = enhance_badge_font_size(cell_size.y)
	var width: float = float(font_size) * maxf(2.0, float(text.length()) * 0.72)
	## ロックアイコンが右下を使うので、ロック中は +N を左へずらす。
	var x: float = cell_size.x - width - 3.0
	if EquipmentEnhancer.is_item_locked(item):
		x -= lock_badge_size(cell_size).x + 2.0
	add_corner_badge(
		parent,
		text,
		color,
		Vector2(x, cell_size.y - float(font_size) - 4.0),
		font_size
	)


static func equip_level_badge_text(item: Resource) -> String:
	if item == null or not ("equip_level" in item):
		return ""
	return "Lv.%d" % EquipmentEnhancer.get_equip_level(item)


static func equip_level_badge_font_size(cell_height: float) -> int:
	return maxi(10, int(cell_height * 0.14))


## 装備Lv を左下に表示（全レア共通）。炉研ぎ +N は右下のまま。
static func apply_equip_level_badge(
	parent: Control,
	item: Resource,
	cell_size: Vector2,
	color: Color = Color(0.96, 0.94, 0.88, 1.0)
) -> void:
	var text: String = equip_level_badge_text(item)
	if text.is_empty() or parent == null:
		return
	var font_size: int = equip_level_badge_font_size(cell_size.y)
	add_corner_badge(
		parent,
		text,
		color,
		Vector2(EQUIP_LEVEL_BADGE_POS.x, cell_size.y - float(font_size) + EQUIP_LEVEL_BADGE_POS.y),
		font_size
	)


## 誤分解・誤錬成防止ロック表示（右下アイコン。ロック中のみ。操作は装備一覧の長押し）。
static func apply_lock_badge(parent: Control, item: Resource, cell_size: Vector2) -> void:
	if parent == null or item == null:
		return
	var stale: Node = parent.get_node_or_null("LockBadge")
	if stale != null:
		stale.queue_free()
	if not EquipmentEnhancer.is_item_locked(item):
		return
	var tex: Texture2D = lock_badge_texture()
	var badge_size: Vector2 = lock_badge_size(cell_size)
	if tex == null:
		## フォールバック: 本文フォントの「錠」（絵文字🔒は iOS で欠落）。
		var font_size: int = maxi(14, int(cell_size.y * 0.22))
		var lbl := Label.new()
		lbl.name = "LockBadge"
		lbl.text = LOCK_BADGE_TEXT
		UiTypography.apply_body(
			lbl, font_size, Color(1.0, 0.92, 0.55, 1.0), UiTypography.OUTLINE_STRONG
		)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.z_index = 8
		lbl.position = Vector2(
			cell_size.x - badge_size.x - 2.0,
			cell_size.y - badge_size.y - 4.0
		)
		parent.add_child(lbl)
		return
	var icon := TextureRect.new()
	icon.name = "LockBadge"
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.z_index = 8
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.position = Vector2(
		cell_size.x - badge_size.x - 2.0,
		cell_size.y - badge_size.y - 4.0
	)
	icon.size = badge_size
	icon.custom_minimum_size = badge_size
	parent.add_child(icon)


## ドロップ直後の New バッジ（アイコン中央・点滅）。次のダンジョン潜行まで。
static func apply_new_badge(parent: Control, item: Resource, cell_size: Vector2) -> void:
	if parent == null or item == null:
		return
	if not GameState.is_equipment_new(item):
		return
	var existing: Node = parent.get_node_or_null("NewEquipBadgeHost")
	if existing != null:
		existing.queue_free()
	var host := Control.new()
	host.name = "NewEquipBadgeHost"
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.z_index = 6
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(center)
	var lbl := Label.new()
	lbl.name = "NewEquipBadge"
	lbl.text = "New"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font_size: int = maxi(12, int(cell_size.y * 0.24))
	UiTypography.apply_display(
		lbl, font_size, Color(1.0, 0.92, 0.35, 1.0), UiTypography.OUTLINE_STRONG
	)
	center.add_child(lbl)
	parent.add_child(host)
	var tween: Tween = parent.create_tween()
	tween.set_loops()
	tween.tween_property(lbl, "modulate:a", 0.2, 0.55).set_trans(Tween.TRANS_SINE)
	tween.tween_property(lbl, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)


## レアリティロゴをセルへ重ねる。
## N/R/E／L／M／エンシェント＝すべて左上。
static func apply_rarity_badges(parent: Control, rarity: int, cell_size: Vector2) -> void:
	if parent == null:
		return
	_apply_corner_rarity_logo(parent, rarity, cell_size)
	_apply_tier_wordmark_badge(parent, rarity, cell_size)


static func _apply_corner_rarity_logo(parent: Control, rarity: int, cell_size: Vector2) -> void:
	var tex: Texture2D = EquipmentUiTokens.corner_rarity_badge(rarity)
	if tex == null:
		return
	var badge_size: Vector2 = EquipmentUiTokens.corner_rarity_badge_size(cell_size)
	if badge_size.x <= 0.0 or badge_size.y <= 0.0:
		return
	var margin: float = EquipmentUiTokens.CORNER_RARITY_BADGE_MARGIN_PX
	var icon := TextureRect.new()
	icon.name = "RarityCornerBadge"
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.z_index = 2
	icon.position = Vector2(RARITY_BADGE_POS.x + margin, RARITY_BADGE_POS.y + margin)
	icon.size = badge_size
	icon.custom_minimum_size = badge_size
	parent.add_child(icon)


static func _apply_tier_wordmark_badge(parent: Control, rarity: int, cell_size: Vector2) -> void:
	var tex: Texture2D = EquipmentUiTokens.tier_badge(rarity)
	if tex == null:
		return
	var badge_size: Vector2 = EquipmentUiTokens.tier_badge_corner_size(cell_size, tex)
	if badge_size.x <= 0.0 or badge_size.y <= 0.0:
		return
	var margin: float = EquipmentUiTokens.CORNER_RARITY_BADGE_MARGIN_PX
	var icon := TextureRect.new()
	icon.name = "LegendaryBadge"
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.z_index = 2
	## N/R/E と同じ左上コーナー。
	icon.position = Vector2(RARITY_BADGE_POS.x + margin, RARITY_BADGE_POS.y + margin)
	icon.size = badge_size
	icon.custom_minimum_size = badge_size
	parent.add_child(icon)


## 互換: 旧名。内部は apply_rarity_badges。
static func apply_legendary_badge(parent: Control, rarity: int, cell_size: Vector2) -> void:
	apply_rarity_badges(parent, rarity, cell_size)

static func add_corner_badge(
	parent: Control,
	text: String,
	color: Color,
	pos: Vector2,
	font_size: int = 13,
	outline_size: int = 3
) -> void:
	if text.is_empty():
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", outline_size)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = pos
	parent.add_child(lbl)

static func equipped_member_index(item: Resource) -> int:
	if item == null:
		return -1
	return GameState.find_item_equipped_member_index(item)

static func equipped_owner_job_id(item: Resource) -> String:
	var idx: int = equipped_member_index(item)
	if idx < 0:
		return ""
	var member: Resource = GameState.get_member(idx)
	if member == null:
		return ""
	return str(member.job_id)

static func relic_equipped_member_index(relic_id: String) -> int:
	var pid: String = CombatPassives.migrate_relic_passive_id(relic_id)
	if pid.is_empty():
		return -1
	for i in GameState.party_members.size():
		var member: Resource = GameState.party_members[i]
		if member == null:
			continue
		if GameState.get_equipped_relic_passive_id(member) == pid:
			return i
	return -1

static func filter_by_equipped_state(
	entries: Array,
	state: String,
	member_index: int
) -> Array:
	if state == "all":
		return entries
	var out: Array = []
	for entry in entries:
		if entry is not Dictionary:
			continue
		var category: String = str(entry.get("category", ""))
		## MAXありは武／防／飾のランダム行のみ。レリックは対象外。
		if state == "max":
			if category == "relic":
				continue
			var max_item: Resource = entry.get("item") as Resource
			if EquipmentRollHelper.has_any_perfect_roll(max_item):
				out.append(entry)
			continue
		if category == "relic":
			var relic_id: String = str(entry.get("relic_id", ""))
			var owner: int = relic_equipped_member_index(relic_id)
			var on_self: bool = owner == member_index
			if state == "equipped" and owner >= 0:
				out.append(entry)
			elif state == "unequipped" and owner < 0:
				out.append(entry)
			elif state == "equipped_self" and on_self:
				out.append(entry)
			continue
		var item: Resource = entry.get("item")
		var owner: int = equipped_member_index(item)
		var on_self: bool = owner == member_index
		if state == "equipped" and owner >= 0:
			out.append(entry)
		elif state == "unequipped" and owner < 0:
			out.append(entry)
		elif state == "equipped_self" and on_self:
			out.append(entry)
	return out

static func sort_inventory_entries(entries: Array, sort_by: String = "rarity") -> Array:
	var sorted: Array = entries.duplicate()
	if sort_by == "name":
		sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var cat_a: String = str(a.get("category", ""))
			var cat_b: String = str(b.get("category", ""))
			if cat_a == "relic" or cat_b == "relic":
				return _relic_sort_name(str(a.get("relic_id", ""))) < _relic_sort_name(str(b.get("relic_id", "")))
			return _entry_sort_name(a.get("item"), cat_a) < _entry_sort_name(b.get("item"), cat_b)
		)
		return sorted
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var cat_a: String = str(a.get("category", ""))
		var cat_b: String = str(b.get("category", ""))
		if cat_a == "relic" or cat_b == "relic":
			return _relic_sort_name(str(a.get("relic_id", ""))) < _relic_sort_name(str(b.get("relic_id", "")))
		var item_a: Resource = a.get("item")
		var item_b: Resource = b.get("item")
		var rarity_a: int = _entry_rarity(item_a, cat_a)
		var rarity_b: int = _entry_rarity(item_b, cat_b)
		if rarity_a != rarity_b:
			return rarity_a > rarity_b
		return _entry_sort_name(item_a, cat_a) < _entry_sort_name(item_b, cat_b)
	)
	return sorted

static func _entry_rarity(item: Resource, category: String) -> int:
	if item == null:
		return 0
	match category:
		"weapon":
			var wd: Resource = DataRegistry.get_weapon_data(str(item.weapon_id))
			return int(wd.rarity) if wd != null else 0
		"armor":
			var ad: Resource = DataRegistry.get_armor_data(str(item.armor_id))
			return int(ad.rarity) if ad != null else 0
		"accessory":
			var ac: Resource = DataRegistry.get_accessory_data(str(item.accessory_id))
			return int(ac.rarity) if ac != null else 0
	return 0

static func _entry_sort_name(item: Resource, category: String) -> String:
	if item == null:
		return ""
	match category:
		"weapon":
			return EquipmentEnhancer.get_display_name(item)
		"armor":
			return EquipmentDisplayNames.get_instance_name(item, "armor")
		"accessory":
			return EquipmentDisplayNames.get_instance_name(item, "accessory")
	return ""

static func _relic_sort_name(relic_id: String) -> String:
	return CombatPassives.relic_display_name(relic_id)
