extends SceneTree

## YouTube #2 鍛冶クリップのみ再撮影。
## Godot.app --path . -s res://tools/yt_ep02_forge_only.gd

const OUT_RES: String = "res://docs/devlog/yt_ep02/footage/frames"
const WAIT_FRAMES: int = 20
const FPS: int = 30
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"

var _gs: Node
var _frame_i: int = 0
var _clip: String = "H_forge"


func _init() -> void:
	call_deferred("_run")


func _wait(n: int = WAIT_FRAMES) -> void:
	for _i in n:
		await process_frame


func _out_root() -> String:
	return ProjectSettings.globalize_path(OUT_RES)


func _clip_dir() -> String:
	return _out_root() + "/" + _clip


func _begin_clip() -> void:
	_frame_i = 0
	DirAccess.make_dir_recursive_absolute(_clip_dir())
	## 旧フレーム削除
	var dir := DirAccess.open(_clip_dir())
	if dir != null:
		dir.list_dir_begin()
		var fn: String = dir.get_next()
		while fn != "":
			if fn.ends_with(".jpg"):
				dir.remove(fn)
			fn = dir.get_next()
	print("[yt_ep02_forge] BEGIN")


func _capture_frame() -> void:
	_frame_i += 1
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_jpg("%s/%04d.jpg" % [_clip_dir(), _frame_i], 0.85)


func _record_seconds(sec: float) -> void:
	var target: int = int(sec * FPS)
	var captured: int = 0
	while captured < target:
		await process_frame
		_capture_frame()
		captured += 1


func _find_weapon(weapon_id: String) -> Resource:
	for item in _gs.get("inventory"):
		if item != null and str(item.weapon_id) == weapon_id:
			return item
	return null


func _unequip_weapons(ids: Array[String]) -> void:
	for member in _gs.call("get_roster"):
		if member == null or not ("equipped_weapon" in member):
			continue
		var ew: Resource = member.equipped_weapon
		if ew != null and str(ew.weapon_id) in ids:
			member.equipped_weapon = null


func _dismiss_forge_result(forge: Node) -> void:
	if forge == null:
		return
	if forge.has_method("_on_result_overlay_dim_input"):
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		forge.call("_on_result_overlay_dim_input", ev)
	await _wait(10)


func _run() -> void:
	await _wait(8)
	_gs = root.get_node_or_null("/root/GameState")
	if _gs == null:
		quit(1)
		return
	DisplayServer.window_set_size(Vector2i(720, 1280))
	var unlock_script: GDScript = load("res://scripts/debug/DebugFullUnlock.gd") as GDScript
	unlock_script.call("apply")
	_gs.set("gold", 99_999)

	_unequip_weapons(["iron_sword", "rusted_blade", "cairn_staff", "pharos_bow"])
	var base_w: Resource = _find_weapon("iron_sword")
	var fodder_w: Resource = null
	for item in _gs.get("inventory"):
		if item != null and str(item.weapon_id) == "iron_sword" and item != base_w:
			fodder_w = item
			break
	if base_w != null and "equip_level" in base_w:
		base_w.equip_level = 3
	if fodder_w != null and "equip_level" in fodder_w:
		fodder_w.equip_level = 1
	var dismantle_target: Resource = _find_weapon("rusted_blade")
	if dismantle_target == null:
		dismantle_target = _find_weapon("cairn_staff")

	change_scene_to_file(BLACKSMITH_SCENE)
	await _wait(28)
	_begin_clip()
	var forge: Node = current_scene
	await _record_seconds(4.0)

	## 炉研ぎ
	forge.call("_set_mode", "enhance")
	await _wait(12)
	await _record_seconds(3.0)
	var enhance_item: Resource = _find_weapon("pharos_bow")
	forge.set("_selected_enhance_item", enhance_item)
	forge.set("_category", "weapon")
	forge.call("_refresh_selection")
	await _wait(10)
	await _record_seconds(3.0)
	forge.call("_on_enhance_confirmed")
	await _wait(20)
	await _record_seconds(6.0)
	await _dismiss_forge_result(forge)

	## 錬成
	forge.call("_set_mode", "alchemy")
	await _wait(12)
	await _record_seconds(3.0)
	if base_w != null and fodder_w != null:
		forge.set("_selected_alchemy_base", base_w)
		forge.set("_selected_alchemy_fodder", fodder_w)
		forge.set("_pending_alchemy_fodder", fodder_w)
		forge.set("_category", "weapon")
		forge.call("_refresh_selection")
		await _wait(10)
		await _record_seconds(3.0)
		forge.call("_execute_alchemy")
		await _wait(20)
		await _record_seconds(6.0)
		await _dismiss_forge_result(forge)

	## 分解
	forge.call("_set_mode", "dismantle")
	await _wait(12)
	await _record_seconds(3.0)
	if dismantle_target != null:
		forge.set("_selected_dismantle_item", dismantle_target)
		forge.call("_refresh_selection")
		await _wait(8)
		await _record_seconds(2.5)
		forge.call("_execute_dismantle", dismantle_target)
		await _wait(18)
		await _record_seconds(5.0)
		await _dismiss_forge_result(forge)

	## 生産
	forge.call("_set_mode", "produce")
	await _wait(14)
	await _record_seconds(4.0)
	var craft: Resource = forge.get("_selected_craft") as Resource
	if craft != null:
		forge.set("_pending_craft", craft)
		forge.call("_on_craft_confirmed")
		await _wait(22)
		await _record_seconds(7.0)
		await _dismiss_forge_result(forge)

	await _record_seconds(3.0)
	print("[yt_ep02_forge] done frames=", _frame_i)
	quit(0)
