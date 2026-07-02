extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const DUNGEON_SELECT_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const _ElementResolver: Script = preload("res://scripts/combat/ElementResolver.gd")

const THUMB_SIZE: Vector2 = Vector2(72, 72)
const ENEMY_ICON_PX: int = 26
const DROP_ICON_SIZE: Vector2 = Vector2(24, 24)
const MAX_STARS: int = 3
const DROP_CAPTION: String = "主なドロップ報酬"

const COLOR_GOLD: Color = Color(0.95, 0.84, 0.4, 1)
const COLOR_SUB: Color = Color(0.78, 0.74, 0.6, 1)
const COLOR_CLEAR: Color = Color(0.45, 0.92, 0.55, 1)
const COLOR_TEAL: Color = Color(0.6, 0.82, 0.78, 1)

## P3-UI2-029 — 占位表示のみ（Beta B2 で実ロジック化）
## スタミナは P3-BETA-001b で撤回済み（占位含め表示しない）
const PLACEHOLDER_DAILY_CHALLENGES: String = "3/3"
const PLACEHOLDER_BONUS_PERCENT: int = 20
const PLACEHOLDER_BONUS_REMAINING: String = "残り2時間35分"
const PLACEHOLDER_SPECIAL_CURRENT: int = 2
const PLACEHOLDER_SPECIAL_TOTAL: int = 5

const DROP_PREVIEW: Dictionary = {
	"mourngate": [
		["weapon", "iron_sword"],
		["armor", "leather_armor"],
		["accessory", "silver_ring"],
		["material", "relic_shard"],
	],
	"whisperwood": [
		["weapon", "pyre_greatsword"],
		["armor", "moss_weave_garb"],
		["accessory", "verdant_ring"],
	],
	"mistfen": [
		["weapon", "storm_carver"],
		["armor", "mire_hide_garb"],
		["accessory", "marsh_pearl_ring"],
	],
	"broken_marsh": [
		["weapon", "galvanic_bow"],
		["armor", "bog_strider_cloak"],
		["accessory", "leech_oil_charm"],
	],
}

@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _featured_panel: PanelContainer = $FeaturedPanel
@onready var _featured_thumb_art: TextureRect = $FeaturedPanel/FeaturedRow/FeaturedThumb/FeaturedThumbArt
@onready var _label_featured_name: Label = $FeaturedPanel/FeaturedRow/FeaturedInfo/LabelFeaturedName
@onready var _label_featured_flavor: Label = $FeaturedPanel/FeaturedRow/FeaturedInfo/LabelFeaturedFlavor
@onready var _label_featured_meta: Label = $FeaturedPanel/FeaturedRow/FeaturedInfo/LabelFeaturedMeta
@onready var _label_featured_discovery: Label = $FeaturedPanel/FeaturedRow/FeaturedInfo/LabelFeaturedDiscovery
@onready var _featured_drop_row: HBoxContainer = $FeaturedPanel/FeaturedRow/FeaturedInfo/FeaturedDropRow
@onready var _btn_featured_challenge: Button = $FeaturedPanel/FeaturedRow/BtnFeaturedChallenge
@onready var _list: VBoxContainer = $ScrollList/ListVBox
@onready var _footer_panel: PanelContainer = $FooterPanel
@onready var _label_daily_challenges: Label = $FooterPanel/FooterRow/DailyCol/LabelDailyValue
@onready var _label_dungeon_bonus: Label = $FooterPanel/FooterRow/BonusCol/LabelBonusValue
@onready var _label_bonus_timer: Label = $FooterPanel/FooterRow/BonusCol/LabelBonusTimer
@onready var _label_special_progress: Label = $FooterPanel/FooterRow/SpecialCol/SpecialRow/LabelSpecialProgress
@onready var _special_progress_bar: ProgressBar = $FooterPanel/FooterRow/SpecialCol/SpecialRow/SpecialProgressBar
@onready var _btn_reward_list: Button = $FooterPanel/FooterRow/SpecialCol/BtnRewardList

var _featured_dungeon_id: String = ""

func _ready() -> void:
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.ADVENTURE)
	_btn_back.pressed.connect(_go_home)
	_btn_featured_challenge.pressed.connect(_on_featured_challenge_pressed)
	_featured_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	_footer_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	$FeaturedPanel/FeaturedRow/FeaturedThumb.add_theme_stylebox_override(
		"panel", _thumb_frame_style()
	)
	_btn_reward_list.disabled = true
	_btn_reward_list.tooltip_text = "準備中（Beta）"
	_apply_typography()
	_refresh_all()

func _apply_typography() -> void:
	UiTypography.apply_button(_btn_back, false)
	UiTypography.apply_button(_btn_featured_challenge)
	UiTypography.apply_button(_btn_reward_list, false)
	UiTypography.apply_body(_label_gold, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_token, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_display(_label_featured_name, UiTypography.SIZE_DISPLAY)
	UiTypography.apply_body(_label_featured_flavor, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB)
	UiTypography.apply_body(_label_featured_meta, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	UiTypography.apply_body(_label_featured_discovery, UiTypography.SIZE_BODY_SMALL, COLOR_CLEAR)
	UiTypography.apply_body(_label_daily_challenges, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_dungeon_bonus, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_caption(_label_bonus_timer)
	UiTypography.apply_body(_label_special_progress, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)

func _refresh_all() -> void:
	_update_currency()
	_refresh_featured()
	_refresh_footer_placeholder()
	_build_list()

func _refresh_footer_placeholder() -> void:
	_label_daily_challenges.text = PLACEHOLDER_DAILY_CHALLENGES
	var data: Resource = DataRegistry.get_dungeon_data(_featured_dungeon_id)
	var element_name: String = "闇"
	if data != null and not str(data.favored_element).is_empty():
		element_name = _ElementResolver.get_display_name(str(data.favored_element))
	_label_dungeon_bonus.text = "%s属性+%d%%" % [element_name, PLACEHOLDER_BONUS_PERCENT]
	_label_bonus_timer.text = PLACEHOLDER_BONUS_REMAINING
	_label_special_progress.text = "特別報酬まであと %d/%d" % [
		PLACEHOLDER_SPECIAL_CURRENT, PLACEHOLDER_SPECIAL_TOTAL
	]
	_special_progress_bar.max_value = float(PLACEHOLDER_SPECIAL_TOTAL)
	_special_progress_bar.value = float(PLACEHOLDER_SPECIAL_CURRENT)

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()

func _refresh_featured() -> void:
	_featured_dungeon_id = _resolve_featured_dungeon_id()
	var data: Resource = DataRegistry.get_dungeon_data(_featured_dungeon_id)
	if data == null:
		_featured_panel.visible = false
		return
	_featured_panel.visible = true
	_label_featured_name.text = str(data.display_name)
	_label_featured_flavor.text = str(data.flavor_text)
	_label_featured_flavor.visible = not str(data.flavor_text).is_empty()
	_featured_thumb_art.texture = _get_dungeon_thumb_texture(_featured_dungeon_id)

	var meta_parts: Array[String] = []
	if int(data.recommended_level) > 0:
		meta_parts.append("推奨Lv.%d〜" % int(data.recommended_level))
	meta_parts.append(_make_stars_text(int(data.difficulty)))
	if not str(data.favored_element).is_empty():
		meta_parts.append("%s 有利" % _ElementResolver.get_display_name(str(data.favored_element)))
	var policy: String = GameState.get_exploration_policy()
	if not policy.is_empty():
		meta_parts.append("方針:%s" % GameState.exploration_policy_label(policy))
	_label_featured_meta.text = " · ".join(meta_parts)

	var discovery_pct: int = _discovery_percent(_featured_dungeon_id)
	_label_featured_discovery.text = "発見率 %d%%" % discovery_pct
	if GameState.is_dungeon_cleared(_featured_dungeon_id):
		_label_featured_discovery.text += " · CLEAR済"

	_populate_drop_row(_featured_drop_row, _featured_dungeon_id, 4)
	_btn_featured_challenge.text = "挑戦"

func _resolve_featured_dungeon_id() -> String:
	var active_id: String = GameState.get_active_dungeon_id()
	if DataRegistry.get_dungeon_data(active_id) != null and GameState.is_dungeon_unlocked(active_id):
		return active_id
	# 未解放/不明を指していたら解放済みの先頭メインへフォールバック（P3-D157）。
	for data in DataRegistry.get_all_dungeon_data():
		if data != null and GameState.is_dungeon_unlocked(str(data.id)):
			return str(data.id)
	for data in DataRegistry.get_all_dungeon_data():
		if data != null:
			return str(data.id)
	return ""

func _discovery_percent(dungeon_id: String) -> int:
	var prog: Dictionary = GameState.dungeon_progress.get(dungeon_id, {})
	return int(round(float(prog.get("discovery", 0.0)) * 100.0))

func _populate_drop_row(row: HBoxContainer, dungeon_id: String, max_icons: int = 3) -> void:
	for child in row.get_children():
		child.queue_free()
	var caption := Label.new()
	caption.text = DROP_CAPTION
	UiTypography.apply_caption(caption)
	row.add_child(caption)
	var preview: Array = DROP_PREVIEW.get(dungeon_id, [])
	var shown: int = 0
	for pair in preview:
		if shown >= max_icons:
			break
		var tex: Texture2D = IconPaths.get_icon_texture(str(pair[1]), str(pair[0]))
		if tex == null:
			continue
		row.add_child(_make_drop_icon(tex))
		shown += 1

func _build_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	var data: Resource = DataRegistry.get_dungeon_data(_featured_dungeon_id)
	if data == null:
		return
	_append_dungeon_switcher()
	var header := Label.new()
	header.text = "階層一覧"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(header, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	_list.add_child(header)
	var floor_total: int = maxi(1, int(data.floor_count))
	for floor in range(1, floor_total + 1):
		var unlocked: bool = floor == 1
		_list.add_child(_make_floor_card(data, floor, unlocked))

func _make_floor_card(data: Resource, floor: int, unlocked: bool) -> PanelContainer:
	var dungeon_id: String = str(data.id)
	var cleared: bool = unlocked and GameState.is_dungeon_cleared(dungeon_id)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	if not unlocked:
		card.modulate = Color(0.72, 0.72, 0.76, 1.0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var thumb_tex: Texture2D = _get_dungeon_thumb_texture(dungeon_id)
	row.add_child(_make_thumb_with_ribbon(thumb_tex, cleared, not unlocked))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	info.add_child(title_row)
	var title := Label.new()
	title.text = "%s B%dF" % [str(data.display_name), floor]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_display(
		title,
		UiTypography.SIZE_BODY_SMALL,
		UiTypography.COLOR_GOLD if unlocked else UiTypography.COLOR_SUB
	)
	title_row.add_child(title)

	if int(data.recommended_level) > 0:
		var lv := Label.new()
		var floor_lv: int = int(data.recommended_level) + floor - 1
		lv.text = "推奨Lv.%d〜" % floor_lv
		UiTypography.apply_caption(lv)
		info.add_child(lv)

	var flavor := Label.new()
	flavor.text = _floor_flavor_text(data, floor)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.max_lines_visible = 2
	UiTypography.apply_caption(flavor, UiTypography.COLOR_MUTED)
	info.add_child(flavor)

	info.add_child(_make_enemy_icon_row(data, floor))

	var drop_row := HBoxContainer.new()
	drop_row.add_theme_constant_override("separation", 4)
	info.add_child(drop_row)
	var preview: Array = DROP_PREVIEW.get(dungeon_id, [])
	for i in mini(3, preview.size()):
		var pair: Array = preview[i]
		var tex: Texture2D = IconPaths.get_icon_texture(str(pair[1]), str(pair[0]))
		if tex != null:
			drop_row.add_child(_make_drop_icon(tex))

	var action := VBoxContainer.new()
	action.alignment = BoxContainer.ALIGNMENT_CENTER
	action.add_theme_constant_override("separation", 4)
	row.add_child(action)

	var power := Label.new()
	power.text = "推奨戦力\n%d" % _recommended_combat_power(data, floor)
	power.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(power, UiTypography.SIZE_CAPTION, COLOR_TEAL)
	action.add_child(power)
	action.add_child(_make_stars_label(int(data.difficulty)))

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(88, 40)
	if unlocked:
		btn.text = "挑戦"
		UiTypography.apply_button(btn)
		btn.pressed.connect(_on_select_pressed.bind(dungeon_id))
	else:
		btn.text = "ロック中"
		btn.disabled = true
	action.add_child(btn)
	return card

# 複数ダンジョンの切替行（P3-D154 / 寄り道対応 P3-SUB-001）。
# メイン（難易度順）→寄り道（難易度順・「寄」印）の順に表示し、選択中は無効化。
func _append_dungeon_switcher() -> void:
	var mains: Array = []
	var sides: Array = []
	for d in DataRegistry.get_all_dungeon_data():
		if d == null:
			continue
		if str(d.route_type) == "main":
			mains.append(d)
		elif str(d.route_type) == "side":
			sides.append(d)
	if mains.size() + sides.size() < 2:
		return
	var by_difficulty := func(a, b): return int(a.difficulty) < int(b.difficulty)
	mains.sort_custom(by_difficulty)
	sides.sort_custom(by_difficulty)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	for d in mains + sides:
		var did: String = str(d.id)
		var is_side: bool = str(d.route_type) == "side"
		var name_text: String = ("寄 %s" if is_side else "%s") % str(d.display_name)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 36)
		# 解放条件（P3-D157）: 未解放はロック表示・選択不可。
		if not GameState.is_dungeon_unlocked(did):
			btn.text = "🔒 %s" % name_text
			btn.disabled = true
			btn.tooltip_text = "前のダンジョンをクリアで解放"
			UiTypography.apply_button(btn, false)
		else:
			btn.text = name_text
			UiTypography.apply_button(btn, did != _featured_dungeon_id)
			if did == _featured_dungeon_id:
				btn.disabled = true
			else:
				btn.pressed.connect(_on_switch_dungeon.bind(did))
		row.add_child(btn)
	_list.add_child(row)

func _on_switch_dungeon(dungeon_id: String) -> void:
	GameState.current_dungeon_id = dungeon_id
	_refresh_all()

func _floor_flavor_text(data: Resource, floor: int) -> String:
	var floors: int = maxi(1, int(data.floor_count))
	if floor >= floors:
		return "最深部。ボスの気配が近い。"
	return "地下第%d層。魔術の残滓が濃くなる。" % floor

func _recommended_combat_power(data: Resource, floor: int) -> int:
	var base_lv: int = maxi(1, int(data.recommended_level))
	return (base_lv + floor - 1) * 130 + int(data.difficulty) * 45

func _enemy_preview_ids(data: Resource, floor: int) -> Array[String]:
	var floors: int = maxi(1, int(data.floor_count))
	var ids: Array[String] = []
	if floor >= floors and not str(data.boss_id).is_empty():
		ids.append(str(data.boss_id))
	for eid in data.enemy_pool:
		if ids.size() >= 3:
			break
		var enemy_id: String = str(eid)
		if enemy_id not in ids:
			ids.append(enemy_id)
	while ids.size() < 3:
		ids.append("")
	return ids

func _make_enemy_icon_row(data: Resource, floor: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for enemy_id in _enemy_preview_ids(data, floor):
		row.add_child(_make_enemy_icon_cell(enemy_id))
	return row

func _make_enemy_icon_cell(enemy_id: String) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(ENEMY_ICON_PX, ENEMY_ICON_PX)
	frame.add_theme_stylebox_override("panel", _enemy_icon_frame_style())
	if enemy_id.is_empty():
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_size_override("font_size", 12)
		glyph.add_theme_color_override("font_color", COLOR_SUB)
		frame.add_child(glyph)
		return frame
	var tex: Texture2D = IconPaths.get_icon_texture(enemy_id, "enemy")
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_size_override("font_size", 12)
		frame.add_child(glyph)
	return frame

func _enemy_icon_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.09, 0.14, 0.95)
	style.set_border_width_all(1)
	style.border_color = Color(0.45, 0.38, 0.22, 0.65)
	style.set_corner_radius_all(ENEMY_ICON_PX / 2)
	return style

func _get_dungeon_thumb_texture(dungeon_id: String) -> Texture2D:
	var tex: Texture2D = IconPaths.get_icon_texture(dungeon_id, "dungeon")
	if tex != null:
		return tex
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	if data == null:
		return null
	return IconPaths.get_icon_texture(str(data.boss_id), "enemy")

func _make_thumb_with_ribbon(tex: Texture2D, show_clear: bool, locked: bool) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = THUMB_SIZE
	var thumb := _make_thumb(tex, "🔒" if locked else "♛", THUMB_SIZE)
	thumb.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(thumb)
	if show_clear:
		var ribbon := _make_clear_ribbon()
		ribbon.position = Vector2(2, 2)
		wrap.add_child(ribbon)
	if locked:
		var lock := Label.new()
		lock.text = "🔒"
		lock.set_anchors_preset(Control.PRESET_CENTER)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock.add_theme_font_size_override("font_size", 22)
		wrap.add_child(lock)
	return wrap

func _make_clear_ribbon() -> PanelContainer:
	var ribbon := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.45, 0.22, 0.92)
	style.set_corner_radius_all(3)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	ribbon.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "CLEAR"
	UiTypography.apply_caption(label, COLOR_CLEAR)
	ribbon.add_child(label)
	return ribbon

func _make_thumb(tex: Texture2D, fallback_glyph: String, size: Vector2 = THUMB_SIZE) -> PanelContainer:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _thumb_frame_style())
	box.custom_minimum_size = size
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
		glyph.add_theme_font_size_override("font_size", 24)
		box.add_child(glyph)
	return box

func _thumb_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.13, 0.9)
	style.set_border_width_all(1)
	style.border_color = Color(0.45, 0.38, 0.2, 0.7)
	style.set_corner_radius_all(6)
	return style

func _make_drop_icon(tex: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = DROP_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

func _make_stars_text(difficulty: int) -> String:
	var filled: int = clampi(difficulty, 1, MAX_STARS)
	var text: String = ""
	for i in MAX_STARS:
		text += "★" if i < filled else "☆"
	return text

func _make_stars_label(difficulty: int) -> Label:
	var label := Label.new()
	label.text = _make_stars_text(difficulty)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(label, UiTypography.SIZE_CAPTION, Color(0.95, 0.78, 0.3))
	return label

func _on_featured_challenge_pressed() -> void:
	_on_select_pressed(_featured_dungeon_id)

func _on_select_pressed(dungeon_id: String) -> void:
	if DataRegistry.get_dungeon_data(dungeon_id) == null:
		return
	GameState.current_dungeon_id = dungeon_id
	SceneRouter.change_scene(DUNGEON_SCENE)

func _go_home() -> void:
	SceneRouter.change_scene(HOME_SCENE)

func _go_to(path: String) -> void:
	if path == DUNGEON_SELECT_SCENE:
		return
	if ResourceLoader.exists(path):
		SceneRouter.change_scene(path)
