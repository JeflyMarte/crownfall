extends Control

@onready var _icon_current: TextureRect = $VBoxContainer/IconCurrentItem

func _ready() -> void:
	$VBoxContainer/ButtonAppraise.pressed.connect(_on_appraise_pressed)
	$VBoxContainer/ButtonAppraiseAll.pressed.connect(_on_appraise_all_pressed)
	$VBoxContainer/ButtonEquipment.pressed.connect(_on_equipment_pressed)
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_pressed)
	_update_gold_label()
	_update_inventory_label()
	_update_batch_info()

func _update_gold_label() -> void:
	$VBoxContainer/LabelGold.text = "Gold: %d" % GameState.gold

func _update_inventory_label() -> void:
	var lines: PackedStringArray = []
	for item in GameState.inventory:
		if not item.is_appraised:
			lines.append("・未鑑定の武器 [%s]" % item.weapon_id)
	for item in GameState.armor_inventory:
		if not item.is_appraised:
			lines.append("・未鑑定の防具 [%s]" % item.armor_id)
	for item in GameState.accessory_inventory:
		if not item.is_appraised:
			lines.append("・未鑑定の装飾品 [%s]" % item.accessory_id)
	if lines.is_empty():
		$VBoxContainer/LabelInventory.text = "未鑑定アイテム: なし"
	else:
		$VBoxContainer/LabelInventory.text = "未鑑定アイテム:\n" + "\n".join(lines)
	_refresh_pending_icon()

func _refresh_pending_icon() -> void:
	for item in GameState.inventory:
		if not item.is_appraised:
			_set_icon(_icon_current, IconPaths.get_icon_texture("unidentified", "weapon"))
			return
	for item in GameState.armor_inventory:
		if not item.is_appraised:
			_set_icon(_icon_current, IconPaths.get_icon_texture("unidentified", "armor"))
			return
	for item in GameState.accessory_inventory:
		if not item.is_appraised:
			_set_icon(_icon_current, IconPaths.get_icon_texture("unidentified", "accessory"))
			return
	_set_icon(_icon_current, null)

func _set_icon(tex_rect: TextureRect, texture: Texture2D) -> void:
	tex_rect.texture = texture
	tex_rect.visible = texture != null

func _update_batch_info() -> void:
	var count: int = $AppraisalController.count_unappraised()
	var cost: int = $AppraisalController.get_batch_cost()
	var can_afford: bool = GameState.gold >= $AppraisalController.APPRAISAL_COST
	if count == 0:
		$VBoxContainer/LabelBatchInfo.text = "未鑑定: なし"
		$VBoxContainer/ButtonAppraiseAll.disabled = true
	else:
		$VBoxContainer/LabelBatchInfo.text = "未鑑定: %d件（一括 %dG）" % [count, cost]
		$VBoxContainer/ButtonAppraiseAll.disabled = not can_afford

func _on_appraise_all_pressed() -> void:
	var count: int = $AppraisalController.count_unappraised()
	if count == 0:
		$VBoxContainer/LabelLog.text = "未鑑定アイテムがありません"
		return
	if not $AppraisalController.has_enough_gold():
		$VBoxContainer/LabelLog.text = "Gold不足（必要: %dG）" % $AppraisalController.APPRAISAL_COST
		return
	var result: Dictionary = $AppraisalController.appraise_all()
	var appraised: int = int(result.get("count", 0))
	var spent: int = int(result.get("spent", 0))
	var reason: String = str(result.get("stopped_reason", "done"))
	if appraised == 0:
		$VBoxContainer/LabelLog.text = "鑑定できませんでした"
	else:
		var log: String = "%d件鑑定完了（-%dG）" % [appraised, spent]
		if reason == "gold":
			log += "\nGold不足により途中停止"
		$VBoxContainer/LabelLog.text = log
	_update_gold_label()
	_update_inventory_label()
	_update_batch_info()

func _on_appraise_pressed() -> void:
	if not $AppraisalController.has_unappraised():
		$VBoxContainer/LabelLog.text = "未鑑定アイテムがありません"
		return
	if not $AppraisalController.has_enough_gold():
		$VBoxContainer/LabelLog.text = "Gold不足（必要: 100G）"
		return
	var result: Dictionary = $AppraisalController.appraise_next()
	if result.is_empty():
		return
	var item: Resource = result["item"]
	var log_text: String = _build_appraisal_log(item)
	var affix_text: String = str(result.get("affix_text", ""))
	if not affix_text.is_empty():
		log_text += "\n" + affix_text
	$VBoxContainer/LabelLog.text = log_text
	_update_gold_label()
	_update_inventory_label()
	var tex: Texture2D = null
	if "weapon_id" in item:
		tex = IconPaths.get_icon_texture(item.weapon_id, "weapon")
	elif "armor_id" in item:
		tex = IconPaths.get_icon_texture(item.armor_id, "armor")
	elif "accessory_id" in item:
		tex = IconPaths.get_icon_texture(item.accessory_id, "accessory")
	_set_icon(_icon_current, tex)
	_update_batch_info()

func _build_appraisal_log(item: Resource) -> String:
	if "weapon_id" in item:
		return "鑑定完了: %s  ATK %d" % [item.weapon_id, item.rolled_attack]
	if "armor_id" in item:
		return "鑑定完了: %s  DEF %d  HP+%d" % [
			item.armor_id,
			item.rolled_defense,
			item.hp_bonus,
		]
	return "鑑定完了: %s" % item.accessory_id

func _on_equipment_pressed() -> void:
	SceneRouter.change_scene("res://scenes/equipment/EquipmentScene.tscn")

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
