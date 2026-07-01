extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const _ElementResolver: Script = preload("res://scripts/combat/ElementResolver.gd")

const THUMB_SIZE: Vector2 = Vector2(68, 68)
const DROP_ICON_SIZE: Vector2 = Vector2(28, 28)
const MAX_STARS: int = 3

# ダンジョン別の代表ドロップ（主なドロップ報酬プレビュー） [category, id]
const DROP_PREVIEW: Dictionary = {
	"mourngate": [
		["weapon", "iron_sword"],
		["armor", "leather_armor"],
		["accessory", "silver_ring"],
		["material", "relic_shard"],
	],
}

# 近日追加のロック行（名称は仮）
const LOCKED_DUNGEONS: Array = [
	{"name": "崩落坑道", "level": 10},
	{"name": "水晶回廊", "level": 20},
	{"name": "玉座への道", "level": 30},
]

@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _list: VBoxContainer = $ScrollList/ListVBox
@onready var _nav_home: Button = $BottomNav/NavRow/NavHome
@onready var _nav_party: Button = $BottomNav/NavRow/NavParty
@onready var _nav_codex: Button = $BottomNav/NavRow/NavCodex
@onready var _nav_shop: Button = $BottomNav/NavRow/NavShop

func _ready() -> void:
	_btn_back.pressed.connect(_go_home)
	_nav_home.pressed.connect(_go_home)
	_nav_party.pressed.connect(_go_to.bind(ROSTER_SCENE))
	_nav_codex.pressed.connect(_go_to.bind(CODEX_SCENE))
	_nav_shop.pressed.connect(_go_to.bind(GACHA_SCENE))
	_update_currency()
	_build_list()

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = "%d" % GameState.gacha_token

func _build_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	for data in DataRegistry.get_all_dungeon_data():
		if data == null:
			continue
		_list.add_child(_make_dungeon_card(data))
	for entry in LOCKED_DUNGEONS:
		_list.add_child(_make_locked_card(str(entry["name"]), int(entry["level"])))

func _make_dungeon_card(data: Resource) -> PanelContainer:
	var dungeon_id: String = str(data.id)
	var cleared: bool = GameState.is_dungeon_cleared(dungeon_id)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style(true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	row.add_child(_make_thumb(_get_dungeon_thumb_texture(dungeon_id), "♛"))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info.add_child(name_row)
	if cleared:
		name_row.add_child(_make_badge("CLEAR", Color(0.95, 0.84, 0.4)))
	var name_label := Label.new()
	name_label.text = str(data.display_name)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 16)
	name_row.add_child(name_label)
	name_row.add_child(_make_stars_label(int(data.difficulty)))

	if int(data.recommended_level) > 0:
		var lv := Label.new()
		lv.text = "推奨Lv %d〜" % int(data.recommended_level)
		lv.add_theme_font_size_override("font_size", 15)
		lv.add_theme_color_override("font_color", Color(0.78, 0.74, 0.6))
		info.add_child(lv)

	if not str(data.favored_element).is_empty():
		var biome := Label.new()
		biome.text = "地形相性: %s 有利" % _ElementResolver.get_display_name(str(data.favored_element))
		biome.add_theme_font_size_override("font_size", 15)
		biome.add_theme_color_override("font_color", Color(0.6, 0.82, 0.78))
		info.add_child(biome)

	info.add_child(_make_drop_row(dungeon_id))

	var action := VBoxContainer.new()
	action.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(action)
	var select_btn := Button.new()
	select_btn.text = "選択"
	select_btn.custom_minimum_size = Vector2(88, 40)
	select_btn.pressed.connect(_on_select_pressed.bind(dungeon_id))
	action.add_child(select_btn)
	return card

func _get_dungeon_thumb_texture(dungeon_id: String) -> Texture2D:
	var tex: Texture2D = IconPaths.get_icon_texture(dungeon_id, "dungeon")
	if tex != null:
		return tex
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	if data == null:
		return null
	return IconPaths.get_icon_texture(str(data.boss_id), "enemy")

func _make_locked_card(dungeon_name: String, level: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style(false))
	card.modulate = Color(0.75, 0.75, 0.78, 1.0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	row.add_child(_make_thumb(null, "未"))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	var name_label := Label.new()
	name_label.text = dungeon_name
	name_label.add_theme_font_size_override("font_size", 16)
	info.add_child(name_label)
	var lv := Label.new()
	lv.text = "推奨Lv %d〜（近日追加）" % level
	lv.add_theme_font_size_override("font_size", 15)
	lv.add_theme_color_override("font_color", Color(0.7, 0.68, 0.6))
	info.add_child(lv)

	var action := VBoxContainer.new()
	action.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(action)
	var locked_btn := Button.new()
	locked_btn.text = "ロック中"
	locked_btn.disabled = true
	locked_btn.custom_minimum_size = Vector2(88, 40)
	action.add_child(locked_btn)
	return card

func _make_thumb(tex: Texture2D, fallback_glyph: String) -> PanelContainer:
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.13, 0.9)
	style.set_border_width_all(1)
	style.border_color = Color(0.45, 0.38, 0.2, 0.7)
	style.set_corner_radius_all(6)
	box.add_theme_stylebox_override("panel", style)
	box.custom_minimum_size = THUMB_SIZE
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = fallback_glyph
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_size_override("font_size", 28)
		box.add_child(glyph)
	return box

func _make_stars_label(difficulty: int) -> Label:
	var filled: int = clampi(difficulty, 1, MAX_STARS)
	var text: String = ""
	for i in MAX_STARS:
		text += "★" if i < filled else "☆"
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.3))
	label.add_theme_font_size_override("font_size", 15)
	return label

func _make_badge(text: String, color: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.18)
	style.set_border_width_all(1)
	style.border_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	badge.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 13)
	badge.add_child(label)
	return badge

func _make_drop_row(dungeon_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var caption := Label.new()
	caption.text = "主なドロップ"
	caption.add_theme_font_size_override("font_size", 14)
	caption.add_theme_color_override("font_color", Color(0.7, 0.68, 0.6))
	row.add_child(caption)
	var preview: Array = DROP_PREVIEW.get(dungeon_id, [])
	for pair in preview:
		var tex: Texture2D = IconPaths.get_icon_texture(str(pair[1]), str(pair[0]))
		if tex == null:
			continue
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = DROP_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	return row

func _card_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.12, 0.85) if active else Color(0.05, 0.05, 0.08, 0.8)
	style.set_border_width_all(1)
	style.border_color = Color(0.55, 0.45, 0.18, 0.6) if active else Color(0.3, 0.3, 0.35, 0.5)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style

func _on_select_pressed(dungeon_id: String) -> void:
	if DataRegistry.get_dungeon_data(dungeon_id) == null:
		return
	GameState.current_dungeon_id = dungeon_id
	SceneRouter.change_scene(DUNGEON_SCENE)

func _go_home() -> void:
	SceneRouter.change_scene(HOME_SCENE)

func _go_to(path: String) -> void:
	if ResourceLoader.exists(path):
		SceneRouter.change_scene(path)
