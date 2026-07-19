extends SceneTree

## P3-UI-Base-A — 全画面 BottomNav 統一 headless 検証。

const SCENES: Array[Dictionary] = [
	{"path": "res://scenes/base/BaseScene.tscn", "require_wired": true},
	{"path": "res://scenes/roster/RosterScene.tscn", "require_wired": true},
	{"path": "res://scenes/dungeon/DungeonSelectScene.tscn", "require_wired": true},
	{"path": "res://scenes/equipment/EquipmentScene.tscn", "require_wired": true},
	{"path": "res://scenes/blacksmith/BlacksmithScene.tscn", "require_wired": true},
	{"path": "res://scenes/gacha/GachaScene.tscn", "require_wired": true},
	{"path": "res://scenes/codex/CodexScene.tscn", "require_wired": true},
	{"path": "res://scenes/guild/GuildScene.tscn", "require_wired": true},
]

const NAV_LABELS: Dictionary = {
	"NavHome": "ホーム",
	"NavParty": "パーティ",
	"NavAdventure": "ダンジョン",
	"NavForge": "強化",
	"NavShop": "ショップ",
	"NavMenu": "メニュー",
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: PackedStringArray = []
	for spec in SCENES:
		failures.append_array(await _verify_scene(spec))
	if failures.is_empty():
		print("VERIFY_BOTTOM_NAV: PASS (%d scenes)" % SCENES.size())
		quit(0)
	else:
		for msg in failures:
			push_error(msg)
		print("VERIFY_BOTTOM_NAV: FAIL (%d)" % failures.size())
		quit(1)

func _verify_scene(spec: Dictionary) -> PackedStringArray:
	var failures: PackedStringArray = []
	var path: String = str(spec["path"])
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		failures.append("%s: load failed" % path)
		return failures
	var root: Node = scene.instantiate()
	if root == null:
		failures.append("%s: instantiate failed" % path)
		return failures
	get_root().add_child(root)
	await create_timer(0.1).timeout
	var nav_row: HBoxContainer = root.get_node_or_null("BottomNav/NavRow") as HBoxContainer
	if nav_row == null:
		failures.append("%s: BottomNav/NavRow missing" % path)
		root.queue_free()
		return failures
	if nav_row.get_child_count() != 6:
		failures.append("%s: nav count=%d" % [path, nav_row.get_child_count()])
	for node_name in NAV_LABELS.keys():
		var btn: Button = nav_row.get_node_or_null(node_name) as Button
		if btn == null:
			failures.append("%s: missing %s" % [path, node_name])
			continue
		var expected: String = str(NAV_LABELS[node_name])
		if btn.text != expected and not (path.contains("EquipmentScene") and node_name == "NavForge" and btn.text == "強化 ●"):
			failures.append("%s: %s label='%s' expected='%s'" % [path, node_name, btn.text, expected])
		if btn.toggle_mode:
			failures.append("%s: %s toggle_mode still on" % [path, node_name])
		if bool(spec.get("require_wired", false)) and btn.pressed.get_connections().is_empty():
			failures.append("%s: %s not wired" % [path, node_name])
	var bottom: PanelContainer = root.get_node_or_null("BottomNav") as PanelContainer
	if bottom != null and bottom.z_index < 10:
		failures.append("%s: BottomNav z_index=%d" % [path, bottom.z_index])
	root.queue_free()
	return failures
