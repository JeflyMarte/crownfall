extends Control

const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")

var _selected: Array = []

func _ready() -> void:
	$VBoxContainer/ButtonConfirm.pressed.connect(_on_confirm_pressed)
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_pressed)
	_selected = GameState.party_members.duplicate()
	_rebuild_roster_list()
	_update_confirm_button()

func _rebuild_roster_list() -> void:
	var container: VBoxContainer = $VBoxContainer/ScrollContainer/RosterListContainer
	for child in container.get_children():
		child.queue_free()
	for adv in GameState.get_roster():
		_add_roster_row(container, adv)

func _add_roster_row(container: VBoxContainer, adv: Resource) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var btn := Button.new()
	btn.text = "★" if _selected.has(adv) else "☆"
	btn.pressed.connect(func(): _toggle_selection(adv))
	row.add_child(btn)
	var icon_tex: Texture2D = IconPaths.get_icon_texture(str(adv.job_id), "chr")
	if icon_tex != null:
		var portrait := TextureRect.new()
		portrait.texture = icon_tex
		portrait.custom_minimum_size = Vector2(48, 48)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(portrait)
	var lbl := Label.new()
	lbl.text = _format_roster_member(adv)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	container.add_child(row)

func _toggle_selection(adv: Resource) -> void:
	if _selected.has(adv):
		if _selected.size() > 1:
			_selected.erase(adv)
	else:
		if _selected.size() < GameState.ACTIVE_PARTY_SIZE:
			_selected.append(adv)
	_rebuild_roster_list()
	_update_confirm_button()

func _update_confirm_button() -> void:
	var count: int = _selected.size()
	$VBoxContainer/ButtonConfirm.disabled = count < 1 or count > GameState.ACTIVE_PARTY_SIZE

func _on_confirm_pressed() -> void:
	if not GameState.set_active_party(_selected):
		$VBoxContainer/LabelStatus.text = "編成の変更に失敗しました（1〜3名・重複不可）"
		return
	SaveManager.save_game()
	$VBoxContainer/LabelStatus.text = "編成を更新しました"

func _format_roster_member(adv: Resource) -> String:
	var mods: Dictionary = _JobStatCalculator.get_member_modifiers(adv)
	var job_display: String = mods.get("display_name", str(adv.job_id))
	if job_display.is_empty():
		job_display = str(adv.job_id)
	var role: String = mods.get("role", "")
	var level: int = int(adv.level)
	var prefix: String = "[アクティブ] " if _selected.has(adv) else "           "
	var line: String = "%s%s Lv%d / Job: %s" % [prefix, adv.display_name, level, job_display]
	if not role.is_empty():
		line += " / %s" % role
	return line

func _on_back_pressed() -> void:
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
