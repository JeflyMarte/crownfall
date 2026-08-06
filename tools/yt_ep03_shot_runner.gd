extends SceneTree

## YouTube #3: 戦闘の見方 — 音声 manifest どおり 1文=1ショットで撮る。
## 第2回と同型。セクションループ禁止。
##
## 実行:
##   Godot --path . --write-movie docs/devlog/yt_ep03/footage/ep03_shots.avi \
##     --fixed-fps 30 --disable-vsync -s res://tools/yt_ep03_shot_runner.gd

const FPS: int = 30
const MANIFEST_PATH: String = "res://docs/devlog/yt_ep03/voice/manifest.json"

const BASE_SCENE: String = "res://scenes/base/BaseScene.tscn"
const SELECT_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"
const RESULT_SCENE: String = "res://scenes/result/ResultScene.tscn"
const EQUIP_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"

const ELEM_WEAPONS: Array[String] = [
	"ember_fang",
	"frostspire_bow",
	"stormveil_needle",
]

## ショット表。"c"=キュー [from,to]／"k"=画面／"a"=引数／"s"=結果ステップ回数
const SHOTS: Array = [
	# ---- S1 前振り ----
	{"c": [0, 2], "k": "hub"},
	{"c": [3, 3], "k": "select"},
	{"c": [4, 8], "k": "dungeon"},
	# ---- S2 画面の基本配置 ----
	{"c": [9, 14], "k": "dungeon"},
	{"c": [15, 16], "k": "dungeon"},
	{"c": [17, 19], "k": "dungeon"},
	# ---- S3 技と必殺 ----
	{"c": [20, 24], "k": "dungeon"},
	{"c": [25, 29], "k": "dungeon"},
	# ---- S4 弱点と属性 ----
	{"c": [30, 31], "k": "dungeon"},
	{"c": [32, 33], "k": "cycle", "a": ELEM_WEAPONS},
	{"c": [34, 36], "k": "dungeon"},
	{"c": [37, 40], "k": "weapon", "a": "ember_fang"},
	# ---- S5 天候 ----
	{"c": [41, 46], "k": "dungeon_weather", "a": "rain"},
	# ---- S6 連携・陣形・パッシブ ----
	{"c": [47, 48], "k": "dungeon"},
	{"c": [49, 51], "k": "roster"},
	{"c": [52, 54], "k": "dungeon"},
	# ---- S7 状態異常 ----
	{"c": [55, 61], "k": "dungeon"},
	# ---- S8 結果 ----
	{"c": [62, 63], "k": "result", "a": "clear"},
	{"c": [64, 65], "k": "result_step", "a": "clear", "s": 2},
	{"c": [66, 69], "k": "result_step", "a": "clear", "s": 3},
	{"c": [70, 70], "k": "result", "a": "wipe"},
	{"c": [71, 71], "k": "roster"},
	# ---- S9 まとめ ----
	{"c": [72, 75], "k": "hub"},
	{"c": [76, 77], "k": "dungeon"},
	{"c": [78, 80], "k": "hub"},
	{"c": [81, 81], "k": "roster"},
	{"c": [82, 84], "k": "hub"},
]

var _gs: Node
var _frames: int = 0
var _drift: int = 0
var _cues: Array = []
var _cur_screen: String = ""


func _init() -> void:
	call_deferred("_run")


func _step() -> void:
	await process_frame
	_frames += 1


func _hold(n: int) -> void:
	var i: int = 0
	while i < n:
		await _step()
		i += 1


func _silence_guides() -> void:
	var hub_guide: GDScript = load("res://scripts/ui/HubSimpleGuideOverlay.gd") as GDScript
	if hub_guide != null and hub_guide.has_method("mark_done"):
		hub_guide.call("mark_done")
	var rare: GDScript = load("res://scripts/ui/NinaRareAcquireGuide.gd") as GDScript
	if rare != null and rare.has_method("mark_guide_done"):
		rare.call("mark_guide_done", "relic")
		rare.call("mark_guide_done", "legendary")
		rare.call("mark_guide_done", "mythic")
	var flags: Variant = _gs.get("tutorial_flags")
	if typeof(flags) == TYPE_DICTIONARY:
		flags["nina_guide_relic_done"] = true
		flags["nina_guide_legendary_done"] = true
		flags["nina_guide_mythic_done"] = true
		_gs.set("tutorial_flags", flags)
	_gs.set("pending_nina_rare_guides", [])
	_gs.set("pending_nina_nav_notices", [])
	_gs.set("pending_clear_nina_merit", false)
	var route: GDScript = load("res://scripts/ui/DungeonRouteGuideOverlay.gd") as GDScript
	if route != null and route.has_method("mark_seen"):
		route.call("mark_seen", "descent")
		route.call("mark_seen", "abyss")
		route.call("mark_seen", "event")


func _dismiss_overlays(scene: Node) -> void:
	if scene == null:
		return
	for ov_name: String in [
		"DungeonRouteGuideOverlay",
		"DungeonUnlockOverlay",
		"ContentUnlockNotice",
		"SimpleGuideOverlay",
		"HubSimpleGuideOverlay",
		"NinaDialogueOverlay",
	]:
		var ov: Node = scene.get_node_or_null(ov_name)
		if ov != null:
			ov.queue_free()
	for n in scene.find_children("*", "CanvasLayer", true, false):
		var nm: String = str(n.name)
		if nm.contains("Nina") or nm.contains("GuideOverlay") or nm.contains("Unlock"):
			n.queue_free()
	for n2 in scene.find_children("*", "Control", true, false):
		var nm2: String = str(n2.name)
		if nm2.contains("ContentUnlock") or nm2.contains("UnlockNotice"):
			n2.visible = false


func _goto(scene_path: String, settle: int) -> void:
	change_scene_to_file(scene_path)
	await _hold(settle)
	_silence_guides()
	_dismiss_overlays(current_scene)
	await _hold(4)


func _find_weapon(weapon_id: String) -> Resource:
	for item in _gs.get("inventory"):
		if item != null and str(item.weapon_id) == weapon_id:
			return item
	return null


func _open_weapon_detail(scene: Node, weapon_id: String) -> bool:
	var item: Resource = _find_weapon(weapon_id)
	if item == null:
		print("[ep03_shots] weapon missing: ", weapon_id)
		return false
	if scene != null and scene.has_method("_show_item_stats_overlay"):
		scene.call("_show_item_stats_overlay", item, "weapon", true)
		await _hold(8)
		return true
	return false


func _close_detail(scene: Node) -> void:
	if scene == null:
		return
	var overlay: Control = scene.get("_detail_overlay") as Control
	if overlay != null:
		overlay.visible = false
	await _hold(3)


func _party_ids() -> Array[String]:
	var ids: Array[String] = []
	for m in _gs.get("party_members"):
		if m != null:
			ids.append(str(m.id))
	return ids


func _seed_clear_run() -> void:
	var ids: Array[String] = _party_ids()
	_gs.set("last_run_outcome", "clear")
	_gs.set("last_run_exp_reward", 220)
	_gs.set("last_run_gold_reward", 310)
	_gs.set("last_run_token_reward", 2)
	_gs.set("last_run_weather", "rain")
	_gs.set("last_run_exploration_policy", "material")
	_gs.set("last_run_stage_id", "mourngate_1")
	_gs.set("last_run_material_gains", {"base_ore": 4, "relic_shard": 2})
	_gs.set("last_run_modifier_counts", {
		"弱点属性": 5,
		"パーティ連携": 3,
		"天候補正": 2,
		"パッシブ": 2,
		"属性シナジー": 2,
	})
	_gs.set("last_run_wipe_cause", {})
	_gs.set("last_run_equipment_drops", [
		{"category": "weapon", "instance_id": "", "item_id": "iron_sword"},
		{"category": "weapon", "instance_id": "", "item_id": "stormveil_needle"},
		{"category": "armor", "instance_id": "", "item_id": "leather_armor"},
		{"category": "weapon", "instance_id": "", "item_id": "volley_horizon_bow"},
		{"category": "accessory", "instance_id": "", "item_id": "silver_ring"},
	])
	var stats: Dictionary = {}
	if ids.size() >= 1:
		stats[ids[0]] = {
			"damage_total": 18420, "damage_max_hit": 3120,
			"damage_max_skill_id": "", "damage_max_skill_name": "王牙列断",
			"heal_total": 0, "kill_count": 11, "damage_taken": 4200,
			"ultimate_count": 3, "crit_count": 7,
		}
	if ids.size() >= 2:
		stats[ids[1]] = {
			"damage_total": 12100, "damage_max_hit": 2100,
			"damage_max_skill_id": "", "damage_max_skill_name": "デッドアイ",
			"heal_total": 0, "kill_count": 8, "damage_taken": 1800,
			"ultimate_count": 2, "crit_count": 5,
		}
	if ids.size() >= 3:
		stats[ids[2]] = {
			"damage_total": 4200, "damage_max_hit": 800,
			"damage_max_skill_id": "", "damage_max_skill_name": "野戦調合",
			"heal_total": 6400, "kill_count": 1, "damage_taken": 2100,
			"ultimate_count": 1, "crit_count": 0,
		}
	if ids.size() >= 4:
		stats[ids[3]] = {
			"damage_total": 2800, "damage_max_hit": 600,
			"damage_max_skill_id": "", "damage_max_skill_name": "聖盾打ち",
			"heal_total": 0, "kill_count": 2, "damage_taken": 9100,
			"ultimate_count": 1, "crit_count": 0,
		}
	_gs.set("last_run_combat_stats", stats)
	_gs.set("last_run_exp_by_member", {})
	_gs.set("last_run_exp_snapshots", {})
	_gs.set("last_run_level_ups", {})


func _seed_wipe_run() -> void:
	_seed_clear_run()
	_gs.set("last_run_outcome", "wipe")
	_gs.set("last_run_token_reward", 0)
	_gs.set("last_run_wipe_cause", {
		"floor": 3,
		"floors_total": 5,
		"room_kind": "trap",
		"enemy_name": "墓守スケルトン",
		"hint": "罠で全滅",
	})


func _normalize_equip_levels() -> void:
	for key: String in ["inventory", "armor_inventory", "accessory_inventory"]:
		for item in _gs.get(key):
			if item == null:
				continue
			if "equip_level" in item:
				item.equip_level = 1
			if "equip_exp" in item:
				item.equip_exp = 0


func _force_combat_speed_x1(scene: Node) -> void:
	if scene == null:
		return
	if scene.has_method("_apply_combat_speed"):
		scene.call("_apply_combat_speed", 1.0)
	var prefs: Node = root.get_node_or_null("/root/SettingsPrefs")
	if prefs != null and prefs.has_method("set_combat_speed_mult"):
		prefs.call("set_combat_speed_mult", 1.0)


func _ensure_screen(kind: String, scene_path: String, settle: int) -> void:
	if _cur_screen == kind and current_scene != null:
		return
	await _goto(scene_path, settle)
	_cur_screen = kind


func _enter_dungeon(weather: String = "") -> void:
	_gs.set("current_dungeon_id", "mourngate")
	_gs.set("current_dungeon_tier", 0)
	if not weather.is_empty() and _gs.has_method("set_weather"):
		_gs.call("set_weather", weather)
	elif not weather.is_empty():
		_gs.set("current_weather", weather)
	await _ensure_screen("dungeon_" + weather, DUNGEON_SCENE, 34)
	var dg: Node = current_scene
	if dg != null and bool(dg.get("_dive_intro_active")) and dg.has_method("_skip_dungeon_dive_intro"):
		dg.call("_skip_dungeon_dive_intro")
		await _hold(4)
	_force_combat_speed_x1(dg)
	## 戦闘が始まるまで少し待つ（ログ／ダメ数字が出やすい）
	if dg != null:
		await _hold(20)


func _setup_shot(kind: String, arg: Variant, steps: int) -> void:
	match kind:
		"hub":
			await _ensure_screen("hub", BASE_SCENE, 22)
		"roster":
			await _ensure_screen("roster", ROSTER_SCENE, 20)
		"select":
			await _ensure_screen("select", SELECT_SCENE, 24)
		"equip":
			await _ensure_screen("equip", EQUIP_SCENE, 20)
			await _close_detail(current_scene)
		"dungeon":
			await _enter_dungeon("")
		"dungeon_weather":
			await _enter_dungeon(str(arg) if arg != null else "rain")
		"weapon":
			await _ensure_screen("equip", EQUIP_SCENE, 20)
			await _close_detail(current_scene)
			var _ok: bool = await _open_weapon_detail(current_scene, str(arg))
		"result", "result_scroll", "result_step":
			var mode: String = str(arg) if arg != null else "clear"
			if mode == "wipe":
				_seed_wipe_run()
			else:
				_seed_clear_run()
			_cur_screen = ""
			await _goto(RESULT_SCENE, 26)
			_cur_screen = "result_" + mode
			var rs: Node = current_scene
			if kind == "result_scroll" and rs != null:
				var sc: ScrollContainer = rs.get_node_or_null("Scroll") as ScrollContainer
				if sc == null:
					sc = rs.find_child("Scroll", true, false) as ScrollContainer
				if sc != null:
					sc.scroll_vertical = 320
					await _hold(4)
			if kind == "result_step" and rs != null and rs.has_method("_advance_step"):
				var si: int = 0
				while si < maxi(1, steps):
					rs.call("_advance_step")
					await _hold(10)
					si += 1
		"cycle":
			await _ensure_screen("equip", EQUIP_SCENE, 20)
		_:
			push_warning("[ep03_shots] unknown shot kind: " + kind)


func _play_cycle(ids: Array, budget: int) -> void:
	var n: int = ids.size()
	if n <= 0:
		await _hold(budget)
		return
	var start: int = _frames
	var i: int = 0
	while i < n:
		var target_end: int = start + int(round(float(budget) * float(i + 1) / float(n)))
		await _close_detail(current_scene)
		var _ok2: bool = await _open_weapon_detail(current_scene, str(ids[i]))
		var remain: int = target_end - _frames
		if remain > 0:
			await _hold(remain)
		i += 1


func _load_cues() -> bool:
	var txt: String = FileAccess.get_file_as_string(MANIFEST_PATH)
	if txt.is_empty():
		push_error("[ep03_shots] cannot read " + MANIFEST_PATH)
		return false
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[ep03_shots] manifest parse failed")
		return false
	_cues = (parsed as Dictionary).get("cues", [])
	return _cues.size() > 0


func _shot_seconds(shot: Dictionary) -> float:
	var rng: Array = shot.get("c", [])
	if rng.size() < 2:
		return 0.0
	var a: int = int(rng[0])
	var b: int = int(rng[1])
	var total: float = 0.0
	var i: int = a
	while i <= b and i < _cues.size():
		total += float((_cues[i] as Dictionary).get("duration", 0.0))
		i += 1
	return total


func _run() -> void:
	await _hold(6)
	_gs = root.get_node_or_null("/root/GameState")
	if _gs == null:
		push_error("[ep03_shots] GameState missing")
		quit(1)
		return
	if not _load_cues():
		quit(1)
		return

	DisplayServer.window_set_size(Vector2i(720, 1280))

	var unlock: GDScript = load("res://scripts/debug/DebugFullUnlock.gd") as GDScript
	unlock.call("apply")
	_silence_guides()
	_normalize_equip_levels()
	_gs.set("gold", 24_500)
	_gs.set("gacha_token", 12)
	if _gs.has_method("set_weather"):
		_gs.call("set_weather", "rain")

	var covered: Dictionary = {}
	for shot_v in SHOTS:
		var rng: Array = (shot_v as Dictionary).get("c", [])
		var i: int = int(rng[0])
		while i <= int(rng[1]):
			if covered.has(i):
				push_error("[ep03_shots] cue %d covered twice" % i)
			covered[i] = true
			i += 1
	var missing: Array = []
	var ci: int = 0
	while ci < _cues.size():
		if not covered.has(ci):
			missing.append(ci)
		ci += 1
	if missing.size() > 0:
		push_error("[ep03_shots] uncovered cues: " + str(missing))
		quit(2)
		return

	var audio_sec: float = 0.0
	for c in _cues:
		audio_sec += float((c as Dictionary).get("duration", 0.0))
	var target_frames: int = int(round(audio_sec * float(FPS)))
	print("[ep03_shots] cues=%d audio=%.2fs target_frames=%d shots=%d"
		% [_cues.size(), audio_sec, target_frames, SHOTS.size()])

	var planned: int = 0
	var idx: int = 0
	for shot_var in SHOTS:
		var shot: Dictionary = shot_var
		var sec: float = _shot_seconds(shot)
		planned += int(round(sec * float(FPS)))
		var kind: String = str(shot.get("k", ""))
		var arg: Variant = shot.get("a")
		var steps: int = int(shot.get("s", 1))
		var began: int = _frames

		if kind == "cycle":
			await _setup_shot(kind, arg, steps)
			await _play_cycle(arg as Array, maxi(1, planned - _frames))
		else:
			await _setup_shot(kind, arg, steps)
			var remain: int = planned - _frames
			if remain > 0:
				await _hold(remain)

		var actual: int = _frames - began
		_drift = _frames - planned
		print("[ep03_shots] %2d %-16s cue%3d-%-3d want=%5.2fs got=%5.2fs cum_drift=%+d"
			% [idx, kind, int(shot["c"][0]), int(shot["c"][1]), sec, float(actual) / float(FPS), _drift])
		idx += 1

	var tail: int = target_frames - _frames
	if tail > 0:
		await _hold(tail)
	print("[ep03_shots] DONE frames=%d (%.2fs) target=%d" % [_frames, float(_frames) / float(FPS), target_frames])
	await _hold(2)
	quit(0)
