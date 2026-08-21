extends GutTest

## SaveManager.request_save debounce（弱機フリーズ種対策）。


func before_each() -> void:
	SaveManager.use_normal_slot()
	SaveManager.delete_normal_save()
	SaveManager.flush_pending_save()
	## pending を確実に落とす（flush 後もフラグが残らないこと）。
	assert_false(SaveManager.has_pending_save())


func after_each() -> void:
	SaveManager.flush_pending_save()
	SaveManager.delete_normal_save()


func test_request_save_debounces_until_flush() -> void:
	GameState.gold = 12345
	SaveManager.request_save()
	assert_true(SaveManager.has_pending_save())
	## debounce 中はまだディスクへ書いていない想定（即時 save ではない）。
	## flush で確定する。
	SaveManager.flush_pending_save()
	assert_false(SaveManager.has_pending_save())
	assert_true(SaveManager.has_save())
	GameState.gold = 0
	assert_true(SaveManager.load_game())
	assert_eq(GameState.gold, 12345)


func test_request_save_immediate_writes_now() -> void:
	GameState.gold = 777
	SaveManager.request_save(0.0)
	assert_false(SaveManager.has_pending_save())
	assert_true(SaveManager.has_save())
	GameState.gold = 0
	assert_true(SaveManager.load_game())
	assert_eq(GameState.gold, 777)


func test_equip_controller_uses_debounced_save() -> void:
	if GameState.party_members.is_empty():
		GameState.seed_all_starters_unlocked()
	var member: Resource = GameState.party_members[0]
	var cls = load("res://scripts/domain/WeaponInstance.gd")
	var item: Resource = cls.new()
	item.instance_id = "debounce_w_%d" % randi()
	item.weapon_id = "iron_sword"
	item.is_appraised = true
	item.equip_level = 1
	GameState.inventory.append(item)
	var ctrl: Node = load("res://scripts/equipment/EquipmentController.gd").new()
	add_child_autofree(ctrl)
	## pending を捨ててから着脱。
	SaveManager.request_save(0.0)
	SaveManager.delete_normal_save()
	assert_false(SaveManager.has_pending_save())
	ctrl.equip_weapon_for_member(item, member)
	assert_eq(member.equipped_weapon, item)
	assert_true(SaveManager.has_pending_save(), "equip should debounce save")
	SaveManager.flush_pending_save()
	assert_false(SaveManager.has_pending_save())
