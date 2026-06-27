extends Control

@onready var _label_token: Label = $VBoxContainer/LabelToken
@onready var _label_gold: Label = $VBoxContainer/LabelGold
@onready var _label_pity: Label = $VBoxContainer/LabelPity
@onready var _lineup_container: VBoxContainer = $VBoxContainer/LineupScrollContainer/LineupContainer
@onready var _label_result: Label = $VBoxContainer/LabelResult
@onready var _button_pull: Button = $VBoxContainer/ButtonPull
@onready var _button_buy_token: Button = $VBoxContainer/ButtonBuyToken

func _ready() -> void:
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_pressed)
	_button_pull.pressed.connect(_on_pull_pressed)
	_button_buy_token.pressed.connect(_on_buy_token_pressed)
	_refresh()

func _refresh() -> void:
	_label_token.text = "Token: %d" % GameState.gacha_token
	_label_gold.text = "Gold: %d" % GameState.gold
	var remaining: int = GachaSystem.HARD_PITY - GameState.gacha_pity
	_label_pity.text = "次の確定まで %d 連" % remaining
	_button_pull.disabled = not GachaSystem.can_pull()
	_button_buy_token.disabled = GameState.gold < GachaSystem.TOKEN_PURCHASE_GOLD
	_rebuild_lineup()

func _rebuild_lineup() -> void:
	for child in _lineup_container.get_children():
		child.queue_free()
	var helpers: Array = DataRegistry.get_all_gacha_helper_data()
	helpers.sort_custom(func(a, b): return int(a.rarity) > int(b.rarity))
	if helpers.is_empty():
		var lbl := Label.new()
		lbl.text = "（排出対象なし）"
		_lineup_container.add_child(lbl)
		return
	for helper in helpers:
		if helper == null:
			continue
		var owned: bool = GameState.owned_helpers.has(str(helper.id))
		var owned_str: String = "【所持済】" if owned else "【未所持】"
		var lbl := Label.new()
		lbl.text = "%s ★%d  %s  (%s)" % [owned_str, int(helper.rarity), str(helper.display_name), str(helper.job_id)]
		_lineup_container.add_child(lbl)

func _on_pull_pressed() -> void:
	var result: Dictionary = GachaSystem.pull()
	SaveManager.save_game()
	if not bool(result.get("ok", false)):
		var reason: String = str(result.get("reason", ""))
		if reason == "no_token":
			_label_result.text = "token不足です。"
		else:
			_label_result.text = "ガチャに失敗しました（%s）。" % reason
		_refresh()
		return
	var helper_id: String = str(result.get("helper_id", ""))
	var rarity: int = int(result.get("rarity", 0))
	var is_new: bool = bool(result.get("is_new", false))
	var refund: int = int(result.get("refund", 0))
	var helper_data: Resource = DataRegistry.get_gacha_helper_data(helper_id)
	var name_str: String = helper_id if helper_data == null else str(helper_data.display_name)
	if is_new:
		_label_result.text = "NEW! ★%d  %s を獲得！" % [rarity, name_str]
	else:
		_label_result.text = "★%d  %s（重複） → %d token 還元" % [rarity, name_str, refund]
	_refresh()

func _on_buy_token_pressed() -> void:
	var success: bool = GachaSystem.buy_token()
	SaveManager.save_game()
	if success:
		_label_result.text = "token を1枚購入しました。"
	else:
		_label_result.text = "Gold不足です。"
	_refresh()

func _on_back_pressed() -> void:
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
