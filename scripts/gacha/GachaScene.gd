extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const LINEUP_ICON_PX: int = 40

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_OWNED: Color = Color(0.55, 0.88, 0.5)
const COLOR_NEW: Color = Color(0.95, 0.78, 0.35)

@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _label_pity: Label = $MainScroll/MainVBox/LabelPity
@onready var _label_rate: Label = $MainScroll/MainVBox/LabelRate
@onready var _lineup_container: VBoxContainer = $MainScroll/MainVBox/LineupScrollContainer/LineupContainer
@onready var _label_result: Label = $MainScroll/MainVBox/LabelResult
@onready var _button_pull: Button = $MainScroll/MainVBox/ButtonPull
@onready var _button_buy_crystal: Button = $MainScroll/MainVBox/ButtonBuyCrystal
@onready var _summon_layer: CanvasLayer = $SummonRevealLayer
@onready var _summon_dim: ColorRect = $SummonRevealLayer/Dim
@onready var _reveal_panel: PanelContainer = $SummonRevealLayer/RevealPanel
@onready var _flash_icon: TextureRect = $SummonRevealLayer/RevealPanel/RevealVBox/FlashIcon
@onready var _portrait_frame: PanelContainer = $SummonRevealLayer/RevealPanel/RevealVBox/PortraitFrame
@onready var _portrait_icon: TextureRect = $SummonRevealLayer/RevealPanel/RevealVBox/PortraitFrame/PortraitIcon
@onready var _label_banner: Label = $SummonRevealLayer/RevealPanel/RevealVBox/LabelBanner
@onready var _label_reveal_name: Label = $SummonRevealLayer/RevealPanel/RevealVBox/LabelRevealName
@onready var _label_reveal_sub: Label = $SummonRevealLayer/RevealPanel/RevealVBox/LabelRevealSub
@onready var _label_tap_hint: Label = $SummonRevealLayer/RevealPanel/RevealVBox/LabelTapHint

var _summon_active: bool = false
var _summon_can_dismiss: bool = false
var _summon_tween: Tween = null

func _ready() -> void:
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.GACHA)
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	_button_pull.pressed.connect(_on_pull_pressed)
	_button_buy_crystal.pressed.connect(_on_buy_crystal_pressed)
	_summon_dim.gui_input.connect(_on_summon_overlay_input)
	_reveal_panel.gui_input.connect(_on_summon_overlay_input)
	_portrait_frame.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	_reveal_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
	)
	_summon_layer.visible = false
	_refresh()

func _refresh() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()
	var remaining: int = GachaSystem.HARD_PITY - GameState.gacha_pity
	_label_pity.text = "天井まで %d 連（未所持確定）" % maxi(0, remaining)
	_label_rate.text = GachaSystem.rate_display_text()
	_set_pull_controls_enabled(not _summon_active)
	_button_pull.text = "単発召喚（%s 1）" % CurrencyHelper.DISPLAY_NAME
	_button_buy_crystal.text = "%s購入（%dG）" % [CurrencyHelper.DISPLAY_NAME, GachaSystem.TOKEN_PURCHASE_GOLD]
	_button_buy_crystal.disabled = _summon_active or GameState.gold < GachaSystem.TOKEN_PURCHASE_GOLD
	_rebuild_lineup()

func _set_pull_controls_enabled(enabled: bool) -> void:
	_button_pull.disabled = not enabled or not GachaSystem.can_pull()
	$Header/HeaderRow/ButtonBack.disabled = not enabled
	for nav_btn in $BottomNav/NavRow.get_children():
		if nav_btn is Button:
			(nav_btn as Button).disabled = not enabled

func _rebuild_lineup() -> void:
	for child in _lineup_container.get_children():
		child.queue_free()
	var helpers: Array = DataRegistry.get_all_gacha_helper_data()
	helpers.sort_custom(func(a, b): return int(a.rarity) > int(b.rarity))
	if helpers.is_empty():
		var lbl := Label.new()
		lbl.text = "（排出対象なし）"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lineup_container.add_child(lbl)
		return
	for helper in helpers:
		if helper == null:
			continue
		_lineup_container.add_child(_make_lineup_row(helper))

func _make_lineup_row(helper: Resource) -> PanelContainer:
	var helper_id: String = str(helper.id)
	var owned: bool = GameState.owned_helpers.has(helper_id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(LINEUP_ICON_PX, LINEUP_ICON_PX)
	var icon_tex: Texture2D = helper.get_portrait_texture()
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_box.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_box.add_child(glyph)
	row.add_child(icon_box)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info.add_child(name_row)
	var name_label := Label.new()
	name_label.text = str(helper.display_name)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 15)
	name_row.add_child(name_label)
	var stars := Label.new()
	stars.text = RosterUiHelper.stars_text(int(helper.rarity))
	stars.add_theme_color_override("font_color", COLOR_GOLD)
	stars.add_theme_font_size_override("font_size", 14)
	name_row.add_child(stars)

	var sub := Label.new()
	var job_data: Resource = DataRegistry.get_job_data(str(helper.job_id))
	var role_id: String = str(job_data.role) if job_data != null else str(helper.job_id)
	var origin_note: String = str(helper.origin_note) if "origin_note" in helper else ""
	if not origin_note.is_empty():
		sub.text = origin_note
	else:
		sub.text = str(RosterUiHelper.ROLE_LABELS.get(role_id, str(helper.job_id)))
	sub.add_theme_color_override("font_color", COLOR_SUB)
	sub.add_theme_font_size_override("font_size", 13)
	info.add_child(sub)

	var badge := Label.new()
	badge.text = "所持済" if owned else "未所持"
	badge.add_theme_color_override("font_color", COLOR_OWNED if owned else COLOR_SUB)
	badge.add_theme_font_size_override("font_size", 13)
	row.add_child(badge)
	return panel

func _on_pull_pressed() -> void:
	if _summon_active:
		return
	var result: Dictionary = GachaSystem.pull()
	SaveManager.save_game()
	if not bool(result.get("ok", false)):
		var reason: String = str(result.get("reason", ""))
		if reason == "no_token":
			_label_result.text = "%sが足りません。" % CurrencyHelper.DISPLAY_NAME
		else:
			_label_result.text = "召喚に失敗しました（%s）。" % reason
		_refresh()
		return
	_play_summon_reveal(result)

func _play_summon_reveal(result: Dictionary) -> void:
	_summon_active = true
	_summon_can_dismiss = false
	_set_pull_controls_enabled(false)
	_reset_reveal_visuals()
	_summon_layer.visible = true

	var helper_id: String = str(result.get("helper_id", ""))
	var is_new: bool = bool(result.get("is_new", false))
	var refund: int = int(result.get("refund", 0))
	var helper_data: Resource = DataRegistry.get_gacha_helper_data(helper_id)
	var name_str: String = helper_id if helper_data == null else str(helper_data.display_name)
	var job_id: String = str(helper_data.job_id) if helper_data != null else ""
	var portrait_tex: Texture2D = helper_data.get_portrait_texture() if helper_data != null else IconPaths.get_icon_texture(job_id, "chr")

	if is_new:
		_label_banner.text = "NEW!"
		_label_banner.add_theme_color_override("font_color", COLOR_NEW)
		_label_reveal_sub.text = "ロスターに追加されました"
		_label_result.add_theme_color_override("font_color", COLOR_NEW)
		_label_result.text = "NEW! %s を獲得！" % name_str
	else:
		_label_banner.text = "重複"
		_label_banner.add_theme_color_override("font_color", COLOR_SUB)
		_label_reveal_sub.text = "%s %d 還元" % [CurrencyHelper.DISPLAY_NAME, refund]
		_label_result.add_theme_color_override("font_color", COLOR_SUB)
		_label_result.text = "%s（重複） → %s %d 還元" % [
			name_str, CurrencyHelper.DISPLAY_NAME, refund,
		]

	_label_reveal_name.text = name_str
	if helper_data != null:
		var job_data: Resource = DataRegistry.get_job_data(job_id)
		var role_id: String = str(job_data.role) if job_data != null else job_id
		var role_label: String = str(RosterUiHelper.ROLE_LABELS.get(role_id, job_id))
		_label_reveal_name.text = "%s\n%s  %s" % [
			name_str,
			RosterUiHelper.stars_text(int(helper_data.rarity)),
			role_label,
		]
	_portrait_icon.texture = portrait_tex

	if _summon_tween != null and _summon_tween.is_valid():
		_summon_tween.kill()
	_summon_tween = create_tween()
	_summon_tween.set_parallel(false)
	_summon_tween.tween_property(_summon_dim, "modulate:a", 1.0, 0.22)
	_summon_tween.tween_property(_reveal_panel, "modulate:a", 1.0, 0.18)
	_summon_tween.tween_property(_flash_icon, "scale", Vector2(1.35, 1.35), 0.16).set_trans(Tween.TRANS_BACK)
	_summon_tween.tween_property(_flash_icon, "scale", Vector2(1.0, 1.0), 0.12)
	_summon_tween.tween_callback(func() -> void:
		_flash_icon.visible = false
		_portrait_frame.visible = true
		_portrait_frame.scale = Vector2(0.55, 0.55)
		_portrait_frame.modulate.a = 0.0
	)
	_summon_tween.tween_property(_portrait_frame, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK)
	_summon_tween.tween_property(_portrait_frame, "modulate:a", 1.0, 0.18)
	_summon_tween.tween_callback(func() -> void:
		_label_banner.visible = true
		_label_reveal_name.visible = true
		_label_reveal_sub.visible = true
		_label_tap_hint.visible = true
		_summon_can_dismiss = true
	)

func _reset_reveal_visuals() -> void:
	_summon_dim.modulate = Color(1, 1, 1, 0)
	_reveal_panel.modulate = Color(1, 1, 1, 0)
	_flash_icon.visible = true
	_flash_icon.scale = Vector2.ONE
	_portrait_frame.visible = false
	_portrait_frame.scale = Vector2.ONE
	_portrait_frame.modulate = Color(1, 1, 1, 1)
	_label_banner.visible = false
	_label_reveal_name.visible = false
	_label_reveal_sub.visible = false
	_label_tap_hint.visible = false

func _on_summon_overlay_input(event: InputEvent) -> void:
	if not _summon_can_dismiss:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_dismiss_summon_reveal()
	elif event is InputEventScreenTouch and event.pressed:
		_dismiss_summon_reveal()

func _dismiss_summon_reveal() -> void:
	if not _summon_active:
		return
	_summon_can_dismiss = false
	if _summon_tween != null and _summon_tween.is_valid():
		_summon_tween.kill()
	_summon_tween = create_tween()
	_summon_tween.tween_property(_summon_dim, "modulate:a", 0.0, 0.2)
	_summon_tween.parallel().tween_property(_reveal_panel, "modulate:a", 0.0, 0.2)
	_summon_tween.chain().tween_callback(func() -> void:
		_summon_layer.visible = false
		_summon_active = false
		_refresh()
	)

func _on_buy_crystal_pressed() -> void:
	if _summon_active:
		return
	var success: bool = GachaSystem.buy_token()
	SaveManager.save_game()
	if success:
		_label_result.add_theme_color_override("font_color", COLOR_OWNED)
		_label_result.text = "%sを1個購入しました。" % CurrencyHelper.DISPLAY_NAME
	else:
		_label_result.add_theme_color_override("font_color", COLOR_SUB)
		_label_result.text = "ゴールドが足りません。"
	_refresh()

func _on_back_pressed() -> void:
	if _summon_active:
		_dismiss_summon_reveal()
		return
	_go_to(HOME_SCENE)

func _go_to(path: String) -> void:
	if _summon_active:
		return
	if path == GACHA_SCENE:
		return
	if ResourceLoader.exists(path):
		SceneRouter.change_scene(path)
