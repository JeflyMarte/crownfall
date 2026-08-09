extends Control

## タイトル（はじめから / つづきから / デバッグ）— P3-UI-TITLE-001 / P3-INTRO-001 / デバッグフル所持。
## 背景は `UI_BG_TitleMain.png`（ロゴ焼込。テキストブランドは置かない）。
## はじめから → 世界観導入（IntroLore）へ。デバッグ → 拠点へ直入。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const STARTER_PICK_SCENE: String = "res://scenes/roster/StarterPickScene.tscn"
const INTRO_LORE_SCENE: String = "res://scenes/intro/IntroLoreScene.tscn"
const BG_PATH: String = "res://assets/ui/UI_BG_TitleMain.png"
const _DebugFullUnlock = preload("res://scripts/debug/DebugFullUnlock.gd")

## 背景太陽（右上の雲の切れ目）付近の薄い発光。比率は 720×1280 基準。
const SUN_GLOW_ANCHOR_X: float = 0.78
const SUN_GLOW_ANCHOR_Y: float = 0.24
const SUN_GLOW_SIZE_PX: float = 400.0
const SUN_GLOW_PULSE_SEC: float = 1.2
const SUN_GLOW_MODULATE_DIM: Color = Color(1.0, 0.9, 0.55, 0.22)
const SUN_GLOW_MODULATE_BRIGHT: Color = Color(1.0, 0.95, 0.7, 0.42)

var _btn_continue: Button
var _confirm_new: ConfirmationDialog
var _confirm_debug: ConfirmationDialog
var _btn_debug_reset: Button
var _load_error_dialog: AcceptDialog
var _sun_glow: TextureRect
var _sun_glow_tween: Tween


func _ready() -> void:
	_build_ui()
	_refresh_continue()
	AudioManager.play_bgm("title")


func _exit_tree() -> void:
	if _sun_glow_tween != null and is_instance_valid(_sun_glow_tween):
		_sun_glow_tween.kill()
	_sun_glow_tween = null


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fallback := ColorRect.new()
	fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fallback.color = Color(0.05, 0.06, 0.09, 1)
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fallback)

	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(BG_PATH):
		bg.texture = load(BG_PATH) as Texture2D
	add_child(bg)

	_add_sun_glow()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	# 焼込ロゴ＋城を避け、ボタンは下寄り
	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer_top.size_flags_stretch_ratio = 2.4
	root.add_child(spacer_top)

	var menu_wrap := CenterContainer.new()
	root.add_child(menu_wrap)

	var menu_col := VBoxContainer.new()
	menu_col.custom_minimum_size = Vector2(320, 0)
	menu_col.add_theme_constant_override("separation", 12)
	menu_wrap.add_child(menu_col)

	var btn_new := _make_menu_button("はじめから")
	btn_new.pressed.connect(_on_new_game_pressed)
	menu_col.add_child(btn_new)

	_btn_continue = _make_menu_button("つづきから")
	_btn_continue.pressed.connect(_on_continue)
	menu_col.add_child(_btn_continue)

	var btn_debug := _make_menu_button("デバッグ")
	btn_debug.pressed.connect(_on_debug_pressed)
	menu_col.add_child(btn_debug)

	var btn_settings := _make_menu_button("設定")
	btn_settings.pressed.connect(func() -> void: SceneRouter.open_settings("res://scenes/title/TitleScene.tscn"))
	menu_col.add_child(btn_settings)

	var spacer_bot := Control.new()
	spacer_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer_bot.size_flags_stretch_ratio = 0.55
	root.add_child(spacer_bot)

	var ver := Label.new()
	ver.text = "v%s" % str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(ver)
	root.add_child(ver)

	_confirm_new = ConfirmationDialog.new()
	_confirm_new.title = "はじめから"
	_confirm_new.dialog_text = "セーブデータを消して最初から始めます。\nよろしいですか？"
	_confirm_new.ok_button_text = "はじめる"
	_confirm_new.cancel_button_text = "やめる"
	_confirm_new.confirmed.connect(_on_new_game_confirmed)
	_confirm_new.canceled.connect(func() -> void: AudioManager.play_sfx("ui_cancel"))
	add_child(_confirm_new)

	_confirm_debug = ConfirmationDialog.new()
	_confirm_debug.title = "デバッグ"
	_confirm_debug.dialog_text = _debug_fresh_dialog_text()
	_confirm_debug.ok_button_text = "デバッグ開始"
	_confirm_debug.cancel_button_text = "やめる"
	_confirm_debug.confirmed.connect(_on_debug_confirmed)
	_confirm_debug.canceled.connect(func() -> void: AudioManager.play_sfx("ui_cancel"))
	_btn_debug_reset = _confirm_debug.add_button("リセットして開始", true, "reset_debug")
	_confirm_debug.custom_action.connect(_on_debug_custom_action)
	add_child(_confirm_debug)

	_load_error_dialog = AcceptDialog.new()
	_load_error_dialog.title = "読み込みエラー"
	_load_error_dialog.ok_button_text = "閉じる"
	add_child(_load_error_dialog)


func _add_sun_glow() -> void:
	_sun_glow = TextureRect.new()
	_sun_glow.name = "SunGlow"
	_sun_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sun_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sun_glow.stretch_mode = TextureRect.STRETCH_SCALE
	_sun_glow.texture = _make_sun_glow_texture()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_sun_glow.material = mat
	_sun_glow.modulate = SUN_GLOW_MODULATE_DIM
	var half: float = SUN_GLOW_SIZE_PX * 0.5
	_sun_glow.anchor_left = SUN_GLOW_ANCHOR_X
	_sun_glow.anchor_right = SUN_GLOW_ANCHOR_X
	_sun_glow.anchor_top = SUN_GLOW_ANCHOR_Y
	_sun_glow.anchor_bottom = SUN_GLOW_ANCHOR_Y
	_sun_glow.offset_left = - half
	_sun_glow.offset_right = half
	_sun_glow.offset_top = - half
	_sun_glow.offset_bottom = half
	add_child(_sun_glow)
	_start_sun_glow_pulse()


func _make_sun_glow_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.28, 0.65, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 0.95, 0.7, 1.0),
		Color(1.0, 0.82, 0.4, 0.55),
		Color(0.95, 0.55, 0.2, 0.12),
		Color(0.8, 0.4, 0.1, 0.0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


func _start_sun_glow_pulse() -> void:
	if _sun_glow == null:
		return
	if _sun_glow_tween != null and is_instance_valid(_sun_glow_tween):
		_sun_glow_tween.kill()
	_sun_glow.modulate = SUN_GLOW_MODULATE_DIM
	_sun_glow_tween = create_tween().set_loops()
	_sun_glow_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sun_glow_tween.tween_property(_sun_glow, "modulate", SUN_GLOW_MODULATE_BRIGHT, SUN_GLOW_PULSE_SEC)
	_sun_glow_tween.tween_property(_sun_glow, "modulate", SUN_GLOW_MODULATE_DIM, SUN_GLOW_PULSE_SEC)


func _make_menu_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 52)
	UiTypography.apply_button(btn)
	return btn


func _refresh_continue() -> void:
	SaveManager.use_normal_slot()
	var has: bool = SaveManager.has_normal_save()
	_btn_continue.disabled = not has
	if has:
		_btn_continue.text = "つづきから"
	else:
		_btn_continue.text = "つづきから（データなし）"


func _on_continue() -> void:
	SaveManager.use_normal_slot()
	if not SaveManager.has_normal_save():
		return
	## メモリ上の前セッション（デバッグ等）を落としてから適用。欠損キー汚染防止。
	GameState.reset_for_new_game()
	if not SaveManager.load_game():
		_show_load_error(
			"セーブデータが読めません。\nデータが壊れている可能性があります。\n（空の状態で拠点へは入りません）"
		)
		return
	if GameState.needs_starter_pick():
		SceneRouter.change_scene(STARTER_PICK_SCENE)
	else:
		SceneRouter.change_scene(HOME_SCENE)


func _on_new_game_pressed() -> void:
	SaveManager.use_normal_slot()
	if SaveManager.has_normal_save():
		_confirm_new.popup_centered()
	else:
		_on_new_game_confirmed()


func _on_new_game_confirmed() -> void:
	SaveManager.use_normal_slot()
	SaveManager.delete_normal_save()
	GameState.reset_for_new_game()
	DailyMissionSystem.ensure_refreshed()
	EventSystem.ensure_active()
	SceneRouter.change_scene(INTRO_LORE_SCENE)


func _debug_fresh_dialog_text() -> String:
	return (
		"デバッグ専用セーブで開始します（本編のセーブは消えません）。\n"
		+ "（図鑑全開放・全装備・キャラLvMAX・金999999・魔晶石9999・進行解放）\nよろしいですか？"
	)


func _on_debug_pressed() -> void:
	SaveManager.use_debug_slot()
	var has: bool = SaveManager.has_debug_save()
	if _btn_debug_reset != null:
		_btn_debug_reset.visible = has
	if has:
		_confirm_debug.dialog_text = (
			"保存済みのデバッグセーブを続けます（本編のセーブは消えません）。\n"
			+ "新規のフル所持でやり直す場合は『リセットして開始』を選んでください。"
		)
		_confirm_debug.ok_button_text = "つづける"
	else:
		_confirm_debug.dialog_text = _debug_fresh_dialog_text()
		_confirm_debug.ok_button_text = "デバッグ開始"
	_confirm_debug.popup_centered()


func _on_debug_confirmed() -> void:
	SaveManager.use_debug_slot()
	if SaveManager.has_debug_save():
		GameState.reset_for_new_game()
		if not SaveManager.load_game():
			_show_load_error(
				"デバッグセーブが読めません。\n『リセットして開始』で新規作成できます。"
			)
			SaveManager.use_normal_slot()
			return
	else:
		_DebugFullUnlock.apply()
		SaveManager.save_game()
	DailyMissionSystem.ensure_refreshed()
	EventSystem.ensure_active()
	SceneRouter.change_scene(HOME_SCENE)


func _on_debug_custom_action(action: StringName) -> void:
	if str(action) != "reset_debug":
		return
	_confirm_debug.hide()
	SaveManager.use_debug_slot()
	SaveManager.delete_debug_save()
	_DebugFullUnlock.apply()
	DailyMissionSystem.ensure_refreshed()
	EventSystem.ensure_active()
	SaveManager.save_game()
	SceneRouter.change_scene(HOME_SCENE)


func _show_load_error(message: String) -> void:
	AudioManager.play_sfx("ui_cancel")
	if _load_error_dialog == null:
		return
	_load_error_dialog.dialog_text = message
	_load_error_dialog.popup_centered()
