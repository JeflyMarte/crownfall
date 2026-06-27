extends Control

const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")
const _JobEvolution = preload("res://scripts/systems/JobEvolution.gd")

func _ready() -> void:
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_pressed)
	_rebuild_list()

func _rebuild_list() -> void:
	var container: VBoxContainer = $VBoxContainer/ScrollContainer/ListContainer
	for child in container.get_children():
		child.queue_free()
	for adv in GameState.get_roster():
		_add_row(container, adv)

func _add_row(container: VBoxContainer, adv: Resource) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = _format_member(adv)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var btn := Button.new()
	if bool(adv.is_evolved):
		btn.text = "認定済"
		btn.disabled = true
	elif _JobEvolution.can_evolve(adv):
		btn.text = "認定する"
		btn.pressed.connect(func(): _on_certify(adv))
	else:
		btn.text = "Lv%d必要" % _JobEvolution.required_level(adv)
		btn.disabled = true
	row.add_child(btn)
	container.add_child(row)

func _on_certify(adv: Resource) -> void:
	if not _JobEvolution.evolve(adv):
		$VBoxContainer/LabelStatus.text = "認定できませんでした"
		return
	SaveManager.save_game()
	var evolved_name: String = _JobEvolution.get_evolved_name(adv)
	$VBoxContainer/LabelStatus.text = "%s を %s に認定しました" % [adv.display_name, evolved_name]
	_rebuild_list()

func _format_member(adv: Resource) -> String:
	var mods: Dictionary = _JobStatCalculator.get_member_modifiers(adv)
	var job_display: String = mods.get("display_name", str(adv.job_id))
	if job_display.is_empty():
		job_display = str(adv.job_id)
	var line: String = "%s Lv%d / %s" % [adv.display_name, int(adv.level), job_display]
	if not bool(adv.is_evolved):
		var target: String = _JobEvolution.get_evolved_name(adv)
		if not target.is_empty():
			line += " → %s" % target
	return line

func _on_back_pressed() -> void:
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
