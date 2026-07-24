extends SceneTree

## tools/verify_equip_diablo_stats.gd — P3-EQ-DIABLO-001 smoke

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var WSR = load("res://scripts/equipment/WeaponStatResolver.gd")
	var Enh = load("res://scripts/equipment/EquipmentEnhancer.gd")
	var Detail = load("res://scripts/equipment/EquipmentItemDetailHelper.gd")
	var wd: Resource = DataRegistry.get_weapon_data("iron_sword")
	if wd == null:
		push_error("iron_sword missing")
		quit(1)
		return
	var inst: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	inst.instance_id = "verify_diablo"
	inst.weapon_id = str(wd.id)
	WSR.apply_drop_stats(inst, wd)
	print("base=", wd.base_attack, " rolled=", inst.rolled_attack, " mods=", inst.random_mods.size())
	print("mods_detail=", inst.random_mods)
	print("eff=", Enh.get_effective_attack(inst))
	for row: Variant in Detail.stat_rows(inst, "weapon"):
		print("ROW ", row)
	if int(inst.rolled_attack) != int(wd.base_attack):
		push_error("rolled_attack should equal base")
		quit(1)
		return
	if not (inst.random_mods is Array):
		push_error("random_mods missing")
		quit(1)
		return
	print("PASS")
	quit(0)
