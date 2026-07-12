extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const UNKNOWN_DISPLAY: String = "???"
const STATUS_DISCOVERED: String = "Discovered"
const STATUS_UNDISCOVERED: String = "Undiscovered"
const ICON_PLACEHOLDER_TEXT: String = "[Icon]"
const DEFAULT_ICON_SIZE: Vector2 = Vector2(48, 48)
const ENEMY_ART_SIZE: Vector2 = Vector2(256, 256)

const CATEGORIES: Array[String] = ["enemy", "dungeon", "material", "weapon", "history", "lore", "guide"]

const CATEGORY_DISPLAY: Dictionary = {
	"enemy": "敵",
	"dungeon": "ダンジョン",
	"material": "素材",
	"weapon": "武器",
	"history": "歴史",
	"lore": "記録",
	"guide": "手引き",
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

@onready var _detail_overlay: Control = $DetailOverlay
@onready var _detail_panel: PanelContainer = $DetailOverlay/DetailPanel
@onready var _detail_scroll: ScrollContainer = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll
@onready var _label_detail_id: Label = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/TopRow/InfoCol/LabelDetailId
@onready var _label_detail_name: Label = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/TopRow/InfoCol/LabelDetailName
@onready var _label_detail_status: Label = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/TopRow/InfoCol/LabelDetailStatus
@onready var _label_detail_category: Label = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/TopRow/InfoCol/LabelDetailCategory
@onready var _label_detail_extra_a: Label = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/TopRow/InfoCol/LabelDetailExtraA
@onready var _label_detail_extra_b: Label = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/TopRow/InfoCol/LabelDetailExtraB
@onready var _label_detail_overview_header: Label = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/DescBox/DescInner/LabelDetailOverviewHeader
@onready var _label_detail_description: Label = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/DescBox/DescInner/LabelDetailDescription
@onready var _desc_box: PanelContainer = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/DescBox
@onready var _label_detail_related_header: Label = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/TopRow/InfoCol/LabelDetailRelatedHeader
@onready var _label_detail_related: Label = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/TopRow/InfoCol/LabelDetailRelated
@onready var _art_frame: PanelContainer = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/TopRow/ArtFrame
@onready var _icon_placeholder: PanelContainer = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/TopRow/ArtFrame/IconPlaceholder
@onready var _label_icon_placeholder: Label = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/TopRow/ArtFrame/IconPlaceholder/LabelIconPlaceholder
@onready var _texture_icon: TextureRect = $DetailOverlay/DetailPanel/DetailVBox/DetailScroll/DetailScrollInner/TopRow/ArtFrame/TextureIcon
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken

func _ready() -> void:
	$Header/HeaderRow/LabelTitle.text = ""
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.CODEX)
	_decorate_static()
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	$MainScroll/MainVBox/TabRow/ButtonTabEnemy.pressed.connect(func(): _select_category("enemy"))
	$MainScroll/MainVBox/TabRow/ButtonTabDungeon.pressed.connect(func(): _select_category("dungeon"))
	$MainScroll/MainVBox/TabRow/ButtonTabMaterial.pressed.connect(func(): _select_category("material"))
	$MainScroll/MainVBox/TabRow/ButtonTabWeapon.pressed.connect(func(): _select_category("weapon"))
	$MainScroll/MainVBox/TabRow/ButtonTabHistory.pressed.connect(func(): _select_category("history"))
	$MainScroll/MainVBox/TabRow/ButtonTabLore.pressed.connect(func(): _select_category("lore"))
	$MainScroll/MainVBox/TabRow/ButtonTabGuide.pressed.connect(func(): _select_category("guide"))
	$DetailOverlay/Dim.gui_input.connect(_on_detail_dim_input)
	$DetailOverlay/DetailPanel/DetailVBox/DetailHeaderRow/ButtonDetailClose.pressed.connect(_hide_detail_popup)
	_detail_overlay.visible = false
	_label_detail_id.visible = false
	_update_currency()
	_label_detail_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label_detail_name.clip_text = true
	_select_category("enemy")

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()

func _decorate_static() -> void:
	_detail_panel.add_theme_stylebox_override(
		"panel", _framed_box(COLOR_GOLD, 2, Color(0.1, 0.08, 0.12, 1.0))
	)
	_art_frame.add_theme_stylebox_override("panel", _framed_box(COLOR_GOLD, 2, Color(0.05, 0.05, 0.06, 1.0)))
	_label_detail_name.add_theme_color_override("font_color", Color(0.93, 0.86, 0.66))
	_label_detail_name.add_theme_font_size_override("font_size", 18)
	_desc_box.add_theme_stylebox_override(
		"panel", _framed_box(Color(0.35, 0.3, 0.24, 1.0), 1, Color(0.12, 0.1, 0.14, 1.0))
	)
	_label_detail_overview_header.add_theme_color_override("font_color", COLOR_GOLD)
	UiTypography.apply_menu_button(
		$DetailOverlay/DetailPanel/DetailVBox/DetailHeaderRow/ButtonDetailClose
	)

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
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
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
		"enemy": $MainScroll/MainVBox/TabRow/ButtonTabEnemy,
		"dungeon": $MainScroll/MainVBox/TabRow/ButtonTabDungeon,
		"material": $MainScroll/MainVBox/TabRow/ButtonTabMaterial,
		"weapon": $MainScroll/MainVBox/TabRow/ButtonTabWeapon,
		"history": $MainScroll/MainVBox/TabRow/ButtonTabHistory,
		"lore": $MainScroll/MainVBox/TabRow/ButtonTabLore,
		"guide": $MainScroll/MainVBox/TabRow/ButtonTabGuide,
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
	var container: VBoxContainer = $MainScroll/MainVBox/EntryListScroll/EntryListContainer
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
		btn.custom_minimum_size = Vector2(0, 68)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.clip_text = true
		btn.add_theme_font_size_override("font_size", 20)
		btn.text = "  " + _entry_list_name(entry)
		var tex: Texture2D = _entry_list_icon(entry)
		if tex != null:
			btn.icon = tex
			btn.expand_icon = true
			btn.add_theme_constant_override("icon_max_width", 52)
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
		_hide_detail_popup()
		return
	_selected_index = index
	_highlight_selected()
	var entry: Dictionary = _entries[index]
	$DetailOverlay/DetailPanel/DetailVBox/DetailHeaderRow/LabelDetailPopupTitle.text = _entry_list_name(entry)
	_label_detail_category.text = "種別: %s" % _get_category_display()
	_hide_bible_fields()
	if _current_category == "enemy":
		_apply_enemy_stage_fields(entry)
	else:
		var discovered: bool = bool(entry.get("discovered", false))
		if discovered:
			_label_detail_id.text = ""
			_label_detail_name.text = "%s" % str(entry.get("display_name", ""))
			_set_status("確認済み", true)
			_label_detail_description.text = str(entry.get("description", ""))
			_update_icon(IconPaths.get_icon_texture(str(entry.get("id", "")), _current_category))
			_apply_bible_fields_discovered(entry)
		else:
			_label_detail_id.text = ""
			_label_detail_name.text = "%s" % UNKNOWN_DISPLAY
			_set_status("未確認", false)
			_label_detail_description.text = "調査中"
			_update_icon(null)
			_apply_bible_fields_undiscovered()
	_detail_overlay.visible = true
	_detail_scroll.scroll_vertical = 0

func _hide_detail_popup() -> void:
	_detail_overlay.visible = false
	_selected_index = -1
	_highlight_selected()

func _on_detail_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_detail_popup()
	elif event is InputEventScreenTouch and event.pressed:
		_hide_detail_popup()

func _apply_enemy_stage_fields(entry: Dictionary) -> void:
	var enemy_id: String = str(entry.get("id", ""))
	var stage: int = int(entry.get("stage", 1))
	const STAGE_LABELS: Array[String] = ["", "未発見", "発見", "初回討伐", "追加調査", "調査完了"]
	if stage == 1:
		_label_detail_id.text = ""
		_label_detail_name.text = "%s" % UNKNOWN_DISPLAY
		_set_status("未発見", false)
		_label_detail_overview_header.text = "調査記録:"
		_label_detail_overview_header.visible = true
		_label_detail_description.text = "調査中"
		_update_icon(null)
		return
	_label_detail_id.text = ""
	_label_detail_name.text = "%s" % str(entry.get("display_name", ""))
	_set_status("段階%d ｜ %s" % [stage, STAGE_LABELS[stage]], stage >= 3)
	_update_icon(IconPaths.get_icon_texture(enemy_id, "enemy"), true)
	_label_detail_overview_header.text = "調査記録:"
	_label_detail_overview_header.visible = true
	_label_detail_description.text = "調査中"
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
		# 採取素材は敵別ではなく炉研ぎ共通3種（実ドロップと一致。P3-MAT-CODEx-001）。
		var mat_parts: PackedStringArray = EquipmentEnhancer.forge_material_display_names()
		if not mat_parts.is_empty():
			research_note += "\n\n炉研ぎ素材（ダンジョン共通）: " + "  /  ".join(mat_parts)
		_label_detail_description.text = research_note
	if stage >= 4:
		_apply_enemy_combat_data(entry, stage, codex_class)

# 戦闘データブロック（P3-D092・攻略本拡充）。stage4=基本戦闘情報 / stage5=スキル＋戦術ヒント。
func _apply_enemy_combat_data(entry: Dictionary, stage: int, codex_class: String) -> void:
	const BASE_ACTION_CT: float = 2.0  # CombatController.BASE_ACTION_CT と同値（CT秒目安）
	var weaknesses: Array = entry.get("element_weakness", [])
	var resists: Array = entry.get("element_resist", [])
	var lines: PackedStringArray = []
	lines.append("弱点: %s" % _format_elements(weaknesses))
	lines.append("耐性: %s" % _format_elements(resists))
	# 行動間隔の目安（attack_speed → CT秒換算）。
	var spd: float = float(entry.get("attack_speed", 1.0))
	if spd > 0.0:
		lines.append("行動間隔: 約%.1f秒" % (BASE_ACTION_CT / spd))
	# 攻撃時の付与状態異常。
	var on_hit: String = str(entry.get("on_hit_status_id", ""))
	if not on_hit.is_empty():
		var chance: float = float(entry.get("on_hit_status_chance", 0.0))
		var st_name: String = _status_display_name(on_hit)
		if chance > 0.0:
			lines.append("攻撃で付与: %s（%d%%）" % [st_name, int(round(chance * 100.0))])
		else:
			lines.append("攻撃で付与: %s" % st_name)
	if not codex_class.is_empty():
		lines.append("特効: %s" % codex_class)
	if stage >= 5:
		var skill_ids: Array = entry.get("skill_ids", [])
		var skill_names: PackedStringArray = []
		for sid in skill_ids:
			skill_names.append(_skill_display_name(str(sid)))
		if not skill_names.is_empty():
			lines.append("使用スキル: %s" % " / ".join(skill_names))
		var hint: String = _build_tactics_hint(weaknesses, codex_class)
		if not hint.is_empty():
			lines.append("有効戦術: %s" % hint)
		var enemy_id: String = str(entry.get("id", ""))
		var phase_text: String = CombatBossPhases.codex_phase_text(
			enemy_id, GameState.get_boss_phases_seen(enemy_id)
		)
		if not phase_text.is_empty():
			lines.append(phase_text)
	_label_detail_related_header.text = "戦闘データ"
	_label_detail_related_header.visible = true
	_label_detail_related.text = "\n".join(lines)
	_label_detail_related.visible = true

func _status_display_name(status_id: String) -> String:
	var eff: Resource = DataRegistry.get_status_effect(status_id)
	if eff != null and not eff.display_name.is_empty():
		return eff.display_name
	return status_id

func _skill_display_name(skill_id: String) -> String:
	var sd: Resource = DataRegistry.get_skill_data(skill_id)
	if sd != null and not sd.display_name.is_empty():
		return sd.display_name
	return skill_id

# 弱点属性＋特効分類から有効戦術ヒントを自動生成。
func _build_tactics_hint(weaknesses: Array, codex_class: String) -> String:
	var parts: PackedStringArray = []
	if weaknesses is Array and not weaknesses.is_empty():
		var elems: PackedStringArray = []
		for e in weaknesses:
			elems.append(str(ELEMENT_EMOJI.get(str(e), str(e))))
		parts.append("%s が有効" % " / ".join(elems))
	if not codex_class.is_empty():
		parts.append("%s特効が有効" % codex_class)
	return " ｜ ".join(parts)

func _apply_bible_fields_discovered(entry: Dictionary) -> void:
	match _current_category:
		"history":
			_label_detail_overview_header.text = "概要:"
			_label_detail_overview_header.visible = true
			var era: String = str(entry.get("era", ""))
			if not era.is_empty() and era != "—":
				_label_detail_extra_a.text = "時代: %s" % era
				_label_detail_extra_a.visible = true
			_show_related("関連:", entry.get("related_entries", []))
		"dungeon":
			_label_detail_overview_header.text = "概要:"
			_label_detail_overview_header.visible = true
			var location: String = str(entry.get("location", ""))
			if not location.is_empty():
				_label_detail_extra_a.text = "場所: %s" % location
				_label_detail_extra_a.visible = true
			var theme: String = str(entry.get("exploration_theme", ""))
			if not theme.is_empty():
				_label_detail_extra_b.text = "テーマ: %s" % theme
				_label_detail_extra_b.visible = true
			_show_related("関連史:", entry.get("related_history", []))
		_:
			_label_detail_overview_header.text = "解説:"
			_label_detail_overview_header.visible = true

func _apply_bible_fields_undiscovered() -> void:
	if _current_category == "history" or _current_category == "dungeon":
		_label_detail_overview_header.text = "概要:"
		_label_detail_overview_header.visible = true
	else:
		_label_detail_overview_header.text = "解説:"
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
	_hide_detail_popup()

func _on_back_pressed() -> void:
	_go_to(HOME_SCENE)

func _go_to(path: String) -> void:
	if path == CODEX_SCENE:
		return
	if ResourceLoader.exists(path):
		SceneRouter.change_scene(path)
