extends Control

## タイトル（つづきから / はじめから）— P3-UI-TITLE-001。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const STARTER_PICK_SCENE: String = "res://scenes/roster/StarterPickScene.tscn"

var _btn_continue: Button
var _confirm_new: ConfirmationDialog


func _ready() -> void:
	_build_ui()
	_refresh_continue()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.09, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)

	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer_top)

	var brand := Label.new()
	brand.text = "CROWNFALL"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(brand, 42)
	root.add_child(brand)

	var sub := Label.new()
	sub.text = "王冠凋落"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(sub, 18, Color(0.72, 0.74, 0.8))
	root.add_child(sub)

	var mid := Control.new()
	mid.custom_minimum_size = Vector2(0, 36)
	root.add_child(mid)

	_btn_continue = _make_menu_button("つづきから")
	_btn_continue.pressed.connect(_on_continue)
	root.add_child(_btn_continue)

	var btn_new := _make_menu_button("はじめから")
	btn_new.pressed.connect(_on_new_game_pressed)
	root.add_child(btn_new)

	var btn_settings := _make_menu_button("設定")
	btn_settings.pressed.connect(func() -> void: SceneRouter.open_settings("res://scenes/title/TitleScene.tscn"))
	root.add_child(btn_settings)

	var spacer_bot := Control.new()
	spacer_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	SceneRouter.change_scene(STARTER_PICK_SCENE)
