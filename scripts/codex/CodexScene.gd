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

var _current_category: String = "enemy"
var _entries: Array = []

@onready var _label_detail_id: Label = $VBoxContainer/DetailPanel/LabelDetailId
@onready var _label_detail_name: Label = $VBoxContainer/DetailPanel/LabelDetailName
@onready var _label_detail_status: Label = $VBoxContainer/DetailPanel/LabelDetailStatus
@onready var _label_detail_category: Label = $VBoxContainer/DetailPanel/LabelDetailCategory
@onready var _label_detail_extra_a: Label = $VBoxContainer/DetailPanel/LabelDetailExtraA
@onready var _label_detail_extra_b: Label = $VBoxContainer/DetailPanel/LabelDetailExtraB
@onready var _label_detail_overview_header: Label = $VBoxContainer/DetailPanel/LabelDetailOverviewHeader
@onready var _label_detail_description: Label = $VBoxContainer/DetailPanel/LabelDetailDescription
@onready var _label_detail_related_header: Label = $VBoxContainer/DetailPanel/LabelDetailRelatedHeader
@onready var _label_detail_related: Label = $VBoxContainer/DetailPanel/LabelDetailRelated
@onready var _icon_placeholder: PanelContainer = $VBoxContainer/DetailPanel/IconRow/IconPlaceholder
@onready var _label_icon_placeholder: Label = $VBoxContainer/DetailPanel/IconRow/IconPlaceholder/LabelIconPlaceholder
@onready var _texture_icon: TextureRect = $VBoxContainer/DetailPanel/IconRow/TextureIcon

func _ready() -> void:
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

func _select_category(category: String) -> void:
	if category not in CATEGORIES:
		return
	_current_category = category
	_entries = _fetch_entries(category)
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
		btn.disabled = cat == _current_category

func _rebuild_entry_list() -> void:
	var container: VBoxContainer = $VBoxContainer/EntryListScroll/EntryListContainer
	for child in container.get_children():
		child.queue_free()
	if _entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "（項目なし）"
		container.add_child(empty_label)
		return
	for i in _entries.size():
		var entry: Dictionary = _entries[i]
		var btn := Button.new()
		btn.text = str(entry.get("display_name", UNKNOWN_DISPLAY))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var idx: int = i
		btn.pressed.connect(func(): _show_detail(idx))
		container.add_child(btn)

func _show_detail(index: int) -> void:
	if index < 0 or index >= _entries.size():
		_clear_detail()
		return
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
		_label_detail_status.text = "Status: %s" % STATUS_DISCOVERED
		_label_detail_description.text = str(entry.get("description", ""))
		_update_icon(IconPaths.get_icon_texture(str(entry.get("id", "")), _current_category))
		_apply_bible_fields_discovered(entry)
	else:
		_label_detail_id.text = "Entry ID: %s" % UNKNOWN_DISPLAY
		_label_detail_name.text = "Name: %s" % UNKNOWN_DISPLAY
		_label_detail_status.text = "Status: %s" % STATUS_UNDISCOVERED
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
		_label_detail_status.text = "Stage 1 | 未発見"
		_label_detail_overview_header.text = "調査記録:"
		_label_detail_overview_header.visible = true
		_label_detail_description.text = UNKNOWN_DISPLAY
		_update_icon(null)
		return
	_label_detail_id.text = "Entry ID: %s" % enemy_id
	_label_detail_name.text = "Name: %s" % str(entry.get("display_name", ""))
	_label_detail_status.text = "Stage %d | %s" % [stage, STAGE_LABELS[stage]]
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
		var weak_str: String = ", ".join(weaknesses) if not weaknesses.is_empty() else "なし"
		var resist_str: String = ", ".join(resists) if not resists.is_empty() else "なし"
		_label_detail_related_header.text = "弱点 / 耐性"
		_label_detail_related_header.visible = true
		_label_detail_related.text = "弱: %s  耐: %s" % [weak_str, resist_str]
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

func _update_icon(texture: Texture2D, big: bool = false) -> void:
	var icon_size: Vector2 = ENEMY_ART_SIZE if big else DEFAULT_ICON_SIZE
	_texture_icon.custom_minimum_size = icon_size
	_icon_placeholder.custom_minimum_size = icon_size
	_texture_icon.texture = null
	_texture_icon.visible = false
	_icon_placeholder.visible = true
	_label_icon_placeholder.text = ICON_PLACEHOLDER_TEXT
	if texture == null:
		return
	_texture_icon.texture = texture
	_texture_icon.visible = true
	_icon_placeholder.visible = false

func _clear_detail() -> void:
	_label_detail_id.text = "Entry ID: —"
	_label_detail_name.text = "Name: —"
	_label_detail_status.text = "Status: —"
	_label_detail_category.text = "Category: %s" % _get_category_display()
	_label_detail_overview_header.text = "Description:"
	_label_detail_overview_header.visible = true
	_label_detail_description.text = "項目を選択してください"
	_hide_bible_fields()
	_update_icon(null)

func _on_back_pressed() -> void:
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
