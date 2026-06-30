extends Control

const UNKNOWN_DISPLAY: String = "???"
const STATUS_DISCOVERED: String = "Discovered"
const STATUS_UNDISCOVERED: String = "Undiscovered"
const ICON_PLACEHOLDER_TEXT: String = "[Icon]"
const DEFAULT_ICON_SIZE: Vector2 = Vector2(48, 48)
const ENEMY_ART_SIZE: Vector2 = Vector2(256, 256)

const CATEGORIES: Array[String] = ["enemy", "dungeon", "material", "weapon", "history", "lore", "guide"]

const CATEGORY_DISPLAY: Dictionary = {
	"enemy": "Enemy",
	"dungeon": "Dungeon",
	"material": "Material",
	"weapon": "Weapon",
	"history": "History",
	"lore": "記録",
	"guide": "Guide",
}

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_PURPLE: Color = Color(0.42, 0.28, 0.6)
const COLOR_SUB: Color = Color(0.62, 0.6, 0.55)

# 属性の絵文字＋表記（弱点/耐性の即時表示用。専用アイコンは将来差し替え）。
const ELEMENT_EMOJI: Dictionary = {
	"fire": "🔥 火", "ice": "❄ 氷", "thunder": "⚡ 雷",
	"holy": "☀ 光", "light": "☀ 光", "dark": "🌑 闇",
	"water": "💧 水", "wind": "🌪 風", "earth": "⛰ 土",
}

var _current_category: String = "enemy"
var _entries: Array = []
var _selected_index: int = -1
var _entry_rows: Array = []

@onready var _label_detail_id: Label = $VBoxContainer/DetailPanel/TopRow/InfoCol/LabelDetailId
@onready var _label_detail_name: Label = $VBoxContainer/DetailPanel/TopRow/InfoCol/LabelDetailName
@onready var _label_detail_status: Label = $VBoxContainer/DetailPanel/TopRow/InfoCol/LabelDetailStatus
@onready var _label_detail_category: Label = $VBoxContainer/DetailPanel/TopRow/InfoCol/LabelDetailCategory
@onready var _label_detail_extra_a: Label = $VBoxContainer/DetailPanel/TopRow/InfoCol/LabelDetailExtraA
@onready var _label_detail_extra_b: Label = $VBoxContainer/DetailPanel/TopRow/InfoCol/LabelDetailExtraB
@onready var _label_detail_overview_header: Label = $VBoxContainer/DetailPanel/LabelDetailOverviewHeader
@onready var _label_detail_description: Label = $VBoxContainer/DetailPanel/LabelDetailDescription
@onready var _label_detail_related_header: Label = $VBoxContainer/DetailPanel/TopRow/InfoCol/LabelDetailRelatedHeader
@onready var _label_detail_related: Label = $VBoxContainer/DetailPanel/TopRow/InfoCol/LabelDetailRelated
@onready var _art_frame: PanelContainer = $VBoxContainer/DetailPanel/TopRow/ArtFrame
@onready var _icon_placeholder: PanelContainer = $VBoxContainer/DetailPanel/TopRow/ArtFrame/IconPlaceholder
@onready var _label_icon_placeholder: Label = $VBoxContainer/DetailPanel/TopRow/ArtFrame/IconPlaceholder/LabelIconPlaceholder
@onready var _texture_icon: TextureRect = $VBoxContainer/DetailPanel/TopRow/ArtFrame/TextureIcon

func _ready() -> void:
	_decorate_static()
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_pressed)
	$VBoxContainer/TabRow/ButtonTabEnemy.pressed.connect(func(): _select_category("enemy"))
	$VBoxContainer/TabRow/ButtonTabDungeon.pressed.connect(func(): _select_category("dungeon"))
	$VBoxContainer/TabRow/ButtonTabMaterial.pressed.connect(func(): _select_category("material"))
	$VBoxContainer/TabRow/ButtonTabWeapon.pressed.connect(func(): _select_category("weapon"))
	$VBoxContainer/TabRow/ButtonTabHistory.pressed.connect(func(): _select_category("history"))
	$VBoxContainer/TabRow/ButtonTabLore.pressed.connect(func(): _select_category("lore"))
	$VBoxContainer/TabRow/ButtonTabGuide.pressed.connect(func():
		_select_category("guide")
		_show_detail(0)
	)
	_select_category("enemy")

func _decorate_static() -> void:
	_art_frame.add_theme_stylebox_override("panel", _framed_box(COLOR_GOLD, 2, Color(0.05, 0.05, 0.06, 1.0)))
	_label_detail_name.add_theme_color_override("font_color", Color(0.93, 0.86, 0.66))
	_label_detail_name.add_theme_font_size_override("font_size", 18)

func _framed_box(border: Color, width: int, bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(width)
	sb.border_color = border
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(6.0)
	return sb

func _set_status(text: String, confirmed: bool) -> void:
	_label_detail_status.text = text
	_label_detail_status.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var box := StyleBoxFlat.new()
	box.bg_color = COLOR_PURPLE if confirmed else Color(0.18, 0.17, 0.16, 0.9)
	box.border_color = COLOR_GOLD if confirmed else Color(0.4, 0.38, 0.34, 0.7)
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	_label_detail_status.add_theme_stylebox_override("normal", box)
	_label_detail_status.add_theme_color_override("font_color", Color(0.97, 0.94, 0.85) if confirmed else COLOR_SUB)

func _format_elements(elements: Variant) -> String:
	if elements is not Array or (elements as Array).is_empty():
		return "なし"
	var parts: PackedStringArray = []
	for e in elements:
		parts.append(str(ELEMENT_EMOJI.get(str(e), str(e))))
	return "  ".join(parts)

func _pill_box(active: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PURPLE if active else Color(0.12, 0.11, 0.13, 0.95)
	sb.set_border_width_all(1)
	sb.border_color = COLOR_GOLD if active else Color(0.35, 0.33, 0.3, 0.7)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	return sb

func _select_category(category: String) -> void:
	if category not in CATEGORIES:
		return
	_current_category = category
	_entries = _fetch_entries(category)
	_selected_index = -1
	_update_tab_buttons()
	_rebuild_entry_list()
	_clear_detail()

func _fetch_entries(category: String) -> Array:
	match category:
		"enemy":
			return CatalogHelper.get_enemy_entries()
		"dungeon":
			return CatalogHelper.get_dungeon_entries()
		"material":
			return CatalogHelper.get_material_entries()
		"weapon":
			return CatalogHelper.get_weapon_entries()
		"history":
			return CatalogHelper.get_history_entries()
		"lore":
			return CatalogHelper.get_lore_entries()
		"guide":
			return CatalogHelper.get_guide_entries()
		_:
			return []

func _get_category_display() -> String:
	return str(CATEGORY_DISPLAY.get(_current_category, _current_category))

func _update_tab_buttons() -> void:
	var mapping: Dictionary = {
		"enemy": $VBoxContainer/TabRow/ButtonTabEnemy,
		"dungeon": $VBoxContainer/TabRow/ButtonTabDungeon,
		"material": $VBoxContainer/TabRow/ButtonTabMaterial,
		"weapon": $VBoxContainer/TabRow/ButtonTabWeapon,
		"history": $VBoxContainer/TabRow/ButtonTabHistory,
		"lore": $VBoxContainer/TabRow/ButtonTabLore,
		"guide": $VBoxContainer/TabRow/ButtonTabGuide,
	}
	for cat in CATEGORIES:
		var btn: Button = mapping[cat]
		var active: bool = cat == _current_category
		btn.disabled = active
		var on_box: StyleBoxFlat = _pill_box(active)
		btn.add_theme_stylebox_override("normal", on_box)
		btn.add_theme_stylebox_override("disabled", on_box)
		btn.add_theme_stylebox_override("hover", _pill_box(true))
		btn.add_theme_stylebox_override("pressed", _pill_box(true))
		btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85) if active else COLOR_SUB)
		btn.add_theme_color_override("font_disabled_color", Color(0.97, 0.94, 0.8))

func _rebuild_entry_list() -> void:
	var container: VBoxContainer = $VBoxContainer/EntryListScroll/EntryListContainer
	for child in container.get_children():
		child.queue_free()
	_entry_rows.clear()
	if _entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "（項目なし）"
		empty_label.add_theme_color_override("font_color", COLOR_SUB)
		container.add_child(empty_label)
		return
	for i in _entries.size():
		var entry: Dictionary = _entries[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 52)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.clip_text = true
		btn.text = "  " + _entry_list_name(entry)
		var tex: Texture2D = _entry_list_icon(entry)
		if tex != null:
			btn.icon = tex
			btn.expand_icon = true
		var chevron := Label.new()
		chevron.text = "›"
		chevron.add_theme_color_override("font_color", COLOR_GOLD)
		chevron.add_theme_font_size_override("font_size", 22)
		chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chevron.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		chevron.position = Vector2(-22, -14)
		btn.add_child(chevron)
		var idx: int = i
		btn.pressed.connect(func(): _show_detail(idx))
		container.add_child(btn)
		_entry_rows.append(btn)
	_highlight_selected()

func _entry_list_name(entry: Dictionary) -> String:
	if _current_category == "enemy":
		if int(entry.get("stage", 1)) <= 1:
			return UNKNOWN_DISPLAY
		return str(entry.get("display_name", UNKNOWN_DISPLAY))
	if not bool(entry.get("discovered", true)):
		return UNKNOWN_DISPLAY
	return str(entry.get("display_name", UNKNOWN_DISPLAY))

func _entry_list_icon(entry: Dictionary) -> Texture2D:
	if _current_category == "enemy" and int(entry.get("stage", 1)) <= 1:
		return null
	if _current_category != "enemy" and not bool(entry.get("discovered", true)):
		return null
	return IconPaths.get_icon_texture(str(entry.get("id", "")), _current_category)

func _highlight_selected() -> void:
	for i in _entry_rows.size():
		var btn: Button = _entry_rows[i]
		var sel: bool = i == _selected_index
		var box: StyleBoxFlat = _framed_box(COLOR_GOLD if sel else Color(0.3, 0.28, 0.26, 0.6), 2 if sel else 1, COLOR_PURPLE if sel else Color(0.1, 0.09, 0.11, 0.85))
		btn.add_theme_stylebox_override("normal", box)
		btn.add_theme_stylebox_override("hover", _framed_box(COLOR_GOLD, 2, Color(0.2, 0.16, 0.22, 0.95)))
		btn.add_theme_stylebox_override("pressed", box)

func _show_detail(index: int) -> void:
	if index < 0 or index >= _entries.size():
		_clear_detail()
		return
	_selected_index = index
	_highlight_selected()
	var entry: Dictionary = _entries[index]
	_label_detail_category.text = "Category: %s" % _get_category_display()
	_hide_bible_fields()
	if _current_category == "enemy":
		_apply_enemy_stage_fields(entry)
		return
	var discovered: bool = bool(entry.get("discovered", false))
	if discovered:
		_label_detail_id.text = "Entry ID: %s" % str(entry.get("id", ""))
		_label_detail_name.text = "Name: %s" % str(entry.get("display_name", ""))
		_set_status("確認済み", true)
		_label_detail_description.text = str(entry.get("description", ""))
		_update_icon(IconPaths.get_icon_texture(str(entry.get("id", "")), _current_category))
		_apply_bible_fields_discovered(entry)
	else:
		_label_detail_id.text = "Entry ID: %s" % UNKNOWN_DISPLAY
		_label_detail_name.text = "Name: %s" % UNKNOWN_DISPLAY
		_set_status("未確認", false)
		_label_detail_description.text = UNKNOWN_DISPLAY
		_update_icon(null)
		_apply_bible_fields_undiscovered()

func _apply_enemy_stage_fields(entry: Dictionary) -> void:
	var enemy_id: String = str(entry.get("id", ""))
	var stage: int = int(entry.get("stage", 1))
	const STAGE_LABELS: Array[String] = ["", "未発見", "発見", "初回討伐", "追加調査", "調査完了"]
	if stage == 1:
		_label_detail_id.text = "Entry ID: %s" % UNKNOWN_DISPLAY
		_label_detail_name.text = "Name: %s" % UNKNOWN_DISPLAY
		_set_status("未発見", false)
		_label_detail_overview_header.text = "調査記録:"
		_label_detail_overview_header.visible = true
		_label_detail_description.text = UNKNOWN_DISPLAY
		_update_icon(null)
		return
	_label_detail_id.text = "Entry ID: %s" % enemy_id
	_label_detail_name.text = "Name: %s" % str(entry.get("display_name", ""))
	_set_status("Stage %d | %s" % [stage, STAGE_LABELS[stage]], stage >= 3)
	_update_icon(IconPaths.get_icon_texture(enemy_id, "enemy"), true)
	_label_detail_overview_header.text = "調査記録:"
	_label_detail_overview_header.visible = true
	_label_detail_description.text = "調査記録なし"
	if stage < 3:
		return
	var codex_class: String = str(entry.get("codex_class", ""))
	var codex_danger: int = int(entry.get("codex_danger", 0))
	var codex_habitat: String = str(entry.get("codex_habitat", ""))
	var danger_stars: String = "★".repeat(codex_danger) if codex_danger > 0 else "—"
	if stage < 5:
		_label_detail_extra_a.text = "分類: %s" % codex_class
		_label_detail_extra_a.visible = true
		_label_detail_extra_b.text = "危険度: %s" % danger_stars
		_label_detail_extra_b.visible = true
		_label_detail_overview_header.text = "生息地:"
		_label_detail_description.text = codex_habitat
	else:
		_label_detail_extra_a.text = "分類: %s  危険度: %s" % [codex_class, danger_stars]
		_label_detail_extra_a.visible = true
		_label_detail_extra_b.text = "生息地: %s" % codex_habitat
		_label_detail_extra_b.visible = true
		_label_detail_overview_header.text = "調査記録:"
		var research_note: String = str(entry.get("codex_research_note", ""))
		var mat_ids: Array = entry.get("codex_materials", [])
		if not mat_ids.is_empty():
			var mat_parts: PackedStringArray = []
			for mat_id in mat_ids:
				var mat_data: Resource = DataRegistry.get_material_data(str(mat_id))
				var mat_name: String = str(mat_id) if mat_data == null else mat_data.display_name
				if mat_data != null and int(mat_data.rarity) >= 2:
					mat_name = "【レア】" + mat_name
				mat_parts.append(mat_name)
			research_note += "\n\n採取素材: " + "  /  ".join(mat_parts)
		_label_detail_description.text = research_note
	if stage >= 4:
		var weaknesses: Array = entry.get("element_weakness", [])
		var resists: Array = entry.get("element_resist", [])
		_label_detail_related_header.text = "弱点属性 / 耐性"
		_label_detail_related_header.visible = true
		# 生態特効ヒント（P3-D087）: この生態には codex_class 特効武器が有効。
		var bane_hint: String = "\n特効: %s" % codex_class if not codex_class.is_empty() else ""
		_label_detail_related.text = "弱点: %s\n耐性: %s%s" % [_format_elements(weaknesses), _format_elements(resists), bane_hint]
		_label_detail_related.visible = true

func _apply_bible_fields_discovered(entry: Dictionary) -> void:
	match _current_category:
		"history":
			_label_detail_overview_header.text = "Overview:"
			_label_detail_overview_header.visible = true
			var era: String = str(entry.get("era", ""))
			if not era.is_empty() and era != "—":
				_label_detail_extra_a.text = "Era: %s" % era
				_label_detail_extra_a.visible = true
			_show_related("Related:", entry.get("related_entries", []))
		"dungeon":
			_label_detail_overview_header.text = "Overview:"
			_label_detail_overview_header.visible = true
			var location: String = str(entry.get("location", ""))
			if not location.is_empty():
				_label_detail_extra_a.text = "Location: %s" % location
				_label_detail_extra_a.visible = true
			var theme: String = str(entry.get("exploration_theme", ""))
			if not theme.is_empty():
				_label_detail_extra_b.text = "Theme: %s" % theme
				_label_detail_extra_b.visible = true
			_show_related("Related History:", entry.get("related_history", []))
		_:
			_label_detail_overview_header.text = "Description:"
			_label_detail_overview_header.visible = true

func _apply_bible_fields_undiscovered() -> void:
	if _current_category == "history" or _current_category == "dungeon":
		_label_detail_overview_header.text = "Overview:"
		_label_detail_overview_header.visible = true
	else:
		_label_detail_overview_header.text = "Description:"
		_label_detail_overview_header.visible = true

func _show_related(header: String, related: Variant) -> void:
	if related is not Array or related.is_empty():
		return
	var parts: PackedStringArray = []
	for item in related:
		var text: String = str(item).strip_edges()
		if not text.is_empty():
			parts.append(text)
	if parts.is_empty():
		return
	_label_detail_related_header.text = header
	_label_detail_related_header.visible = true
	_label_detail_related.text = ", ".join(parts)
	_label_detail_related.visible = true

func _hide_bible_fields() -> void:
	_label_detail_extra_a.visible = false
	_label_detail_extra_b.visible = false
	_label_detail_related_header.visible = false
	_label_detail_related.visible = false

func _update_icon(texture: Texture2D, _big: bool = false) -> void:
	_texture_icon.texture = null
	_texture_icon.visible = false
	_icon_placeholder.visible = true
	_label_icon_placeholder.text = "？"
	if texture == null:
		return
	_texture_icon.texture = texture
	_texture_icon.visible = true
	_icon_placeholder.visible = false

func _clear_detail() -> void:
	_label_detail_id.text = "Entry ID: —"
	_label_detail_name.text = "Name: —"
	_set_status("—", false)
	_label_detail_category.text = "Category: %s" % _get_category_display()
	_label_detail_overview_header.text = "Description:"
	_label_detail_overview_header.visible = true
	_label_detail_description.text = "項目を選択してください"
	_hide_bible_fields()
	_update_icon(null)

func _on_back_pressed() -> void:
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
