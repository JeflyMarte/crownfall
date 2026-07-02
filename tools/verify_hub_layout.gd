extends SceneTree

## 拠点画面の横はみ出し防止（HubLayoutHelper 適用）headless 検証。

const CONTENT_MARGIN_H: float = 12.0

const SCENES: Array[String] = [
	"res://scenes/roster/RosterScene.tscn",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: PackedStringArray = []
	for path in SCENES:
		failures.append_array(await _verify_scene(path))
	if failures.is_empty():
		print("VERIFY_HUB_LAYOUT: PASS (%d scenes)" % SCENES.size())
		quit(0)
	else:
		for msg in failures:
			push_error(msg)
		print("VERIFY_HUB_LAYOUT: FAIL (%d)" % failures.size())
		quit(1)

func _verify_scene(path: String) -> PackedStringArray:
	var failures: PackedStringArray = []
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		failures.append("%s: load failed" % path)
		return failures
	var root: Node = scene.instantiate()
	if root == null:
		failures.append("%s: instantiate failed" % path)
		return failures
	root.name = "VerifyRoot"
	get_root().add_child(root)
	await process_frame
	await process_frame
	var scroll: ScrollContainer = root.find_child("MainScroll", true, false) as ScrollContainer
	if scroll == null:
		failures.append("%s: MainScroll missing" % path)
	else:
		if scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			failures.append("%s: MainScroll horizontal scroll must be disabled" % path)
		if absf(scroll.offset_left - CONTENT_MARGIN_H) > 0.5:
			failures.append(
				"%s: MainScroll offset_left=%.1f expected %.1f"
				% [path, scroll.offset_left, CONTENT_MARGIN_H]
			)
		if absf(scroll.offset_right + CONTENT_MARGIN_H) > 0.5:
			failures.append(
				"%s: MainScroll offset_right=%.1f expected -%.1f"
				% [path, scroll.offset_right, CONTENT_MARGIN_H]
			)
	root.queue_free()
	return failures
