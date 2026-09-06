extends GutTest

## Roster「詳細」→ Equipment のフォーカスが、パーティ優先ビューでも取り違えないこと。


func _make_adv(id: String, display_name: String, level: int) -> Resource:
	var adv: Resource = load("res://scripts/domain/Adventurer.gd").new()
	adv.id = id
	adv.display_name = display_name
	adv.job_id = "swordsman"
	adv.level = level
	adv.rarity = Enums.Rarity.RARE
	return adv


func test_equipment_focus_by_id_survives_view_reorder() -> void:
	GameState.reset_for_new_game()
	## ビューは「パーティ → 編成外ロスター」。roster index 0＝低Lvでも view[0]＝高Lv（パーティ）になるよう組む。
	var low: Resource = _make_adv("focus_probe_low", "低Lv", 5)
	var high: Resource = _make_adv("focus_probe_high", "高Lv", 50)
	GameState.roster.clear()
	GameState.party_members.clear()
	GameState.roster.append(low)
	GameState.roster.append(high)
	GameState.party_members.append(high)
	var roster_idx_low: int = GameState.get_roster().find(low)
	assert_eq(roster_idx_low, 0)
	## id フォーカス（修正後の正）。
	GameState.equipment_focus_member_id = "focus_probe_low"
	GameState.equipment_focus_member_index = -1
	var equip: Node = load("res://scenes/equipment/EquipmentScene.tscn").instantiate()
	add_child_autofree(equip)
	await get_tree().process_frame
	var view: Array = equip.call("_get_view_members")
	var sel_i: int = int(equip.get("_selected_member_index"))
	assert_eq(str(view[sel_i].id), "focus_probe_low")
	## 旧 index だけでも id 解決で低Lv側になる。
	equip.queue_free()
	await get_tree().process_frame
	GameState.equipment_focus_member_id = ""
	GameState.equipment_focus_member_index = roster_idx_low
	equip = load("res://scenes/equipment/EquipmentScene.tscn").instantiate()
	add_child_autofree(equip)
	await get_tree().process_frame
	view = equip.call("_get_view_members")
	sel_i = int(equip.get("_selected_member_index"))
	assert_eq(str(view[sel_i].id), "focus_probe_low")
	## 旧バグ: roster index をそのまま view index にすると別人（パーティ先頭＝高Lv）。
	assert_eq(str(view[0].id), "focus_probe_high")
	assert_ne(
		str(view[roster_idx_low].id),
		"focus_probe_low",
		"roster index must not equal view slot (precondition)"
	)


func test_roster_detail_sets_focus_member_id() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()
	var target: Resource = GameState.roster[GameState.roster.size() - 1]
	var scene: Node = load("res://scenes/roster/RosterScene.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._on_detail_pressed(target)
	assert_eq(str(GameState.equipment_focus_member_id), str(target.id))
	assert_eq(GameState.equipment_focus_member_index, -1)
