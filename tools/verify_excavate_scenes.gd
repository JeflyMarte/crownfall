extends SceneTree

## headless: 魔晶石発掘シーン instantiate（P3-UX-CRYSTAL-EXCAVATE-001 Exit Criteria）。

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var paths: Array[String] = [
		"res://scenes/excavate/CrystalExcavateSelectScene.tscn",
		"res://scenes/excavate/CrystalExcavateCombatScene.tscn",
		"res://scenes/excavate/CrystalExcavateResultScene.tscn",
	]
	var failures: PackedStringArray = []
	for path: String in paths:
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			failures.append("load failed: %s" % path)
			continue
		var node: Control = packed.instantiate() as Control
		if node == null:
			failures.append("instantiate failed: %s" % path)
			continue
		get_root().add_child(node)
		await create_timer(0.05).timeout
		node.queue_free()
	if failures.is_empty():
		print("VERIFY_EXCAVATE_SCENES: PASS")
		quit(0)
	else:
		for msg in failures:
			push_error(msg)
		print("VERIFY_EXCAVATE_SCENES: FAIL (%d)" % failures.size())
		quit(1)
