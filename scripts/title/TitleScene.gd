extends Control

## タイトル（はじめから / つづきから / デバッグ）— P3-UI-TITLE-001 / P3-INTRO-001 / デバッグフル所持。
## 背景は `UI_BG_TitleMain.png`（ロゴ焼込。テキストブランドは置かない）。
## はじめから → 世界観導入（IntroLore）へ。デバッグ → 拠点へ直入。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const STARTER_PICK_SCENE: String = "res://scenes/roster/StarterPickScene.tscn"
const INTRO_LORE_SCENE: String = "res://scenes/intro/IntroLoreScene.tscn"
const BG_PATH: String = "res://assets/ui/UI_BG_TitleMain.png"
const _DebugFullUnlock = preload("res://scripts/debug/DebugFullUnlock.gd")

var _btn_continue: Button
var _confirm_new: ConfirmationDialog
var _confirm_debug: ConfirmationDialog


func _ready() -> void:
	_build_ui()
	_refresh_continue()
	AudioManager.play_bgm("title")


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
	_confirm_debug.dialog_text = (
		"セーブを上書きしてデバッグ用データで開始します。\n"
		+ "（全装備・全キャラ・金999999・魔晶石9999・進行解放）\nよろしいですか？"
	)
	_confirm_debug.ok_button_text = "デバッグ開始"
	_confirm_debug.cancel_button_text = "やめる"
	_confirm_debug.confirmed.connect(_on_debug_confirmed)
	_confirm_debug.canceled.connect(func() -> void: AudioManager.play_sfx("ui_cancel"))
	add_child(_confirm_debug)
	SafeAreaHelper.apply_scene_chrome(self)


func _make_menu_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 52)
	UiTypography.apply_button(btn)
	return btn


func _refresh_continue() -> void:
	var has: bool = SaveManager.has_save()
	_btn_continue.disabled = not has
	if has:
		_btn_continue.text = "つづきから"
	else:
		_btn_continue.text = "つづきから（データなし）"


func _on_continue() -> void:
	if not SaveManager.has_save():
		return
	SaveManager.load_game()
	if GameState.needs_starter_pick():
		SceneRouter.change_scene(STARTER_PICK_SCENE)
	else:
		SceneRouter.change_scene(HOME_SCENE)


func _on_new_game_pressed() -> void:
	if SaveManager.has_save():
		_confirm_new.popup_centered()
	else:
		_on_new_game_confirmed()


func _on_new_game_confirmed() -> void:
	SaveManager.delete_save()
	GameState.reset_for_new_game()
	DailyMissionSystem.ensure_refreshed()
	EventSystem.ensure_active()
	SceneRouter.change_scene(INTRO_LORE_SCENE)


func _on_debug_pressed() -> void:
	if SaveManager.has_save():
		_confirm_debug.popup_centered()
	else:
		_on_debug_confirmed()


func _on_debug_confirmed() -> void:
	_DebugFullUnlock.apply()
	DailyMissionSystem.ensure_refreshed()
	EventSystem.ensure_active()
	SaveManager.save_game()
	SceneRouter.change_scene(HOME_SCENE)
