extends Node

## 王痕育成 UI スクショ（autoload 付き）。rank 0/3/5 を連続保存。

const _DebugFullUnlock := preload("res://scripts/debug/DebugFullUnlock.gd")
const SCENE: String = "res://scenes/royal_mark/RoyalMarkScene.tscn"
const OUT_DIR: String = "res://review/royal_mark_ui_hierarchy/after/"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_DebugFullUnlock.apply()
	var member_id: String = ""
	for m: Variant in GameState.roster:
		if m != null and str(m.id).begins_with("adventurer_"):
			member_id = str(m.id)
			break
	if member_id.is_empty():
		print("SHOT_FAIL no adventurer")
		get_tree().quit(1)
		return
	## 装備スキルがある想定で Rank III/V 文言を出す
	for m: Variant in GameState.roster:
		if m != null and str(m.id) == member_id:
			m.level = 50
			break
	GameState.royal_mark_shards = 50
	GameState.gold = maxi(int(GameState.gold), 99999)
	for rank in [0, 3, 5]:
		if rank <= 0:
			GameState.royal_mark_ranks.erase(member_id)
		else:
			GameState.royal_mark_ranks[member_id] = rank
		SaveManager.save_game()
		var scene: Control = (load(SCENE) as PackedScene).instantiate() as Control
		get_tree().root.add_child(scene)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		var img: Image = get_viewport().get_texture().get_image()
		var out: String = "%sshot_rank%d.png" % [OUT_DIR, rank]
		if img != null:
			img.save_png(out)
			print("SHOT_OK ", out)
		else:
			print("SHOT_FAIL ", out)
		scene.queue_free()
		await get_tree().process_frame
	get_tree().quit()
