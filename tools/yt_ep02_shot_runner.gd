extends SceneTree

## YouTube #2 撮り直し: 音声 manifest を読み、1文（キュー）単位で画面を切り替えて撮る。
##
## 従来の失敗: セクション（21〜93秒）に1クリップを割り当ててループ／切断していたため、
## 話している内容と画面が無関係になっていた。本ランナーは各ショットの尺を
## manifest のキュー秒数から算出し、フレーム数で厳密に消費する。
##
## Movie Maker で録るので「描画したフレーム数 = 動画の長さ」。
## セットアップに使ったフレームもショット尺に含めて数え、ズレは次ショットへ繰り越して相殺する。
##
## 実行:
##   Godot --path . --write-movie docs/devlog/yt_ep02/footage/ep02_shots.avi \
##     --fixed-fps 30 --disable-vsync -s res://tools/yt_ep02_shot_runner.gd

const FPS: int = 30
const MANIFEST_PATH: String = "res://docs/devlog/yt_ep02/voice/manifest.json"

const BASE_SCENE: String = "res://scenes/base/BaseScene.tscn"
const SELECT_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"
const RESULT_SCENE: String = "res://scenes/result/ResultScene.tscn"
const EQUIP_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"

## レアリティ順（N/R/E/L/M/エンシェント）
const RARITY_WEAPONS: Array[String] = [
	"iron_sword",
	"pharos_bow",
	"frostspire_bow",
	"stormveil_needle",
	"burial_crown_greatsword",
	"chronos_toki_bow",
]

## ショット表。"c" = manifest のキュー番号 [from, to]（両端含む）。
## "k" = 画面の種類。"a" = 引数。
## 台本の文と画面を1対1で対応させる（ここがズレ再発防止の要）。
const SHOTS: Array = [
	# ---- S1 前振り ----
	{"c": [0, 2], "k": "hub"},
	{"c": [3, 3], "k": "dungeon"},
	{"c": [4, 5], "k": "hub"},
	# ---- S2 一日の流れ ----
	{"c": [6, 6], "k": "hub"},
	{"c": [7, 8], "k": "roster"},
	{"c": [9, 9], "k": "select"},
	{"c": [10, 12], "k": "dungeon"},
	{"c": [13, 14], "k": "result", "a": "clear"},
	{"c": [15, 16], "k": "forge", "a": "enhance"},
	{"c": [17, 17], "k": "hub"},
	# ---- S3 装備の落ち方（実戦を通しで見せる） ----
	{"c": [18, 23], "k": "dungeon"},
	{"c": [24, 28], "k": "dungeon"},
	{"c": [29, 32], "k": "result", "a": "wipe"},
	# ---- S4 レアリティ・ランダム・固有 ----
	{"c": [33, 34], "k": "equip"},
	{"c": [35, 35], "k": "cycle", "a": RARITY_WEAPONS},
	{"c": [36, 37], "k": "weapon", "a": "stormveil_needle"},
	{"c": [38, 38], "k": "weapon", "a": "burial_crown_greatsword"},
	{"c": [39, 40], "k": "weapon", "a": "frostspire_bow"},
	{"c": [41, 43], "k": "weapon_scroll", "a": "stormveil_needle"},
	{"c": [44, 47], "k": "weapon", "a": "stormveil_needle"},
	{"c": [48, 48], "k": "weapon", "a": "stormveil_needle"},
	{"c": [49, 49], "k": "weapon", "a": "volley_horizon_bow"},
	{"c": [50, 51], "k": "weapon", "a": "silent_rite_staff"},
	{"c": [52, 53], "k": "cycle", "a": ["ember_fang", "frostspire_bow"]},
	{"c": [54, 55], "k": "roster"},
	# ---- S5 結果画面 ----
	{"c": [56, 57], "k": "result", "a": "clear"},
	{"c": [58, 61], "k": "result_scroll", "a": "clear"},
	{"c": [62, 63], "k": "result_step", "a": "clear", "s": 1},
	{"c": [64, 66], "k": "result_step", "a": "clear", "s": 2},
	{"c": [67, 71], "k": "result_step", "a": "clear", "s": 3},
	{"c": [72, 75], "k": "result", "a": "wipe"},
	{"c": [76, 77], "k": "result", "a": "clear"},
	# ---- S6 鍛冶 ----
	{"c": [78, 80], "k": "forge"},
	{"c": [81, 81], "k": "forge", "a": "enhance"},
	{"c": [82, 84], "k": "forge_run", "a": "enhance"},
	{"c": [85, 86], "k": "forge_run", "a": "alchemy"},
	{"c": [87, 89], "k": "forge_run", "a": "dismantle"},
	{"c": [90, 92], "k": "forge", "a": "produce"},
	{"c": [93, 93], "k": "forge"},
	## 「おすすめの見方」は4画面を名指しするので、必ず1文=1画面にする
	{"c": [94, 94], "k": "dungeon"},
	{"c": [95, 95], "k": "result", "a": "clear"},
	{"c": [96, 96], "k": "equip"},
	{"c": [97, 97], "k": "forge", "a": "enhance"},
	{"c": [98, 99], "k": "hub"},
	# ---- S7 まとめ ----
	{"c": [100, 102], "k": "hub"},
	{"c": [103, 105], "k": "equip"},
	{"c": [106, 107], "k": "hub"},
	# ---- S8 締め ----
	{"c": [108, 109], "k": "hub"},
	{"c": [110, 110], "k": "roster"},
	{"c": [111, 113], "k": "hub"},
]

var _gs: Node
var _frames: int = 0
var _drift: int = 0
var _cues: Array = []
var _cur_screen: String = ""


func _init() -> void:
	call_deferred("_run")


# ---------------- フレーム進行（動画尺の唯一の基準） ----------------

func _step() -> void:
	await process_frame
	_frames += 1


func _hold(n: int) -> void:
	var i: int = 0
	while i < n:
		await _step()
		i += 1


# ---------------- 共通ユーティリティ ----------------

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
		print("[ep02_shots] weapon missing: ", weapon_id)
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


func _scroll_detail(scene: Node) -> void:
	if scene == null:
		return
	var overlay: Control = scene.get("_detail_overlay") as Control
	if overlay == null:
		return
	var sc: ScrollContainer = overlay.find_child("ScrollContainer", true, false) as ScrollContainer
	if sc == null:
		for c in overlay.find_children("*", "ScrollContainer", true, false):
			sc = c as ScrollContainer
			break
	if sc != null:
		sc.scroll_vertical = 9999
		await _hold(4)


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


## 錬成は「同系統2本」かつ「未装備」が要る。DebugFullUnlock は1 ID 1本しか配らないので複製する。
func _prepare_forge_items() -> void:
	var base_w: Resource = _find_weapon("iron_sword")
	if base_w == null:
		return
	var fodder: Resource = base_w.duplicate()
	fodder.instance_id = "yt_alchemy_fodder"
	fodder.equip_level = 1
	var inv: Array = _gs.get("inventory")
	inv.append(fodder)
	base_w.equip_level = 3

	## 錬成・分解に使う個体が装備中だと弾かれる
	var protect: Array[String] = ["iron_sword", "rusted_blade"]
	for member in _gs.call("get_roster"):
		if member == null:
			continue
		if "equipped_weapon" in member and member.equipped_weapon != null:
			if str(member.equipped_weapon.weapon_id) in protect:
				member.equipped_weapon = null


func _dismiss_forge_result(forge: Node) -> void:
	if forge == null:
		return
	if forge.has_method("_on_result_overlay_dim_input"):
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		forge.call("_on_result_overlay_dim_input", ev)
	await _hold(6)


# ---------------- ショット種別ごとの画面づくり ----------------

func _ensure_screen(kind: String, scene_path: String, settle: int) -> void:
	## 同じ画面が続くときは遷移しない（短いショットで遷移フレームを食わない）
	if _cur_screen == kind and current_scene != null:
		return
	await _goto(scene_path, settle)
	_cur_screen = kind


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
			_gs.set("current_dungeon_id", "mourngate")
			_gs.set("current_dungeon_tier", 0)
			await _ensure_screen("dungeon", DUNGEON_SCENE, 34)
			var dg: Node = current_scene
			if dg != null and bool(dg.get("_dive_intro_active")) and dg.has_method("_skip_dungeon_dive_intro"):
				dg.call("_skip_dungeon_dive_intro")
				await _hold(4)
		"weapon", "weapon_scroll":
			await _ensure_screen("equip", EQUIP_SCENE, 20)
			await _close_detail(current_scene)
			var ok: bool = await _open_weapon_detail(current_scene, str(arg))
			if ok and kind == "weapon_scroll":
				await _scroll_detail(current_scene)
		"result", "result_scroll", "result_step":
			var mode: String = str(arg) if arg != null else "clear"
			if mode == "wipe":
				_seed_wipe_run()
			else:
				_seed_clear_run()
			## 結果は毎回入り直して先頭から見せる
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
		"forge", "forge_run":
			await _ensure_screen("forge", BLACKSMITH_SCENE, 26)
			var forge: Node = current_scene
			var mode2: String = str(arg) if arg != null else ""
			if forge != null and not mode2.is_empty() and forge.has_method("_set_mode"):
				forge.call("_set_mode", mode2)
				await _hold(10)
			if kind == "forge_run":
				await _run_forge(forge, mode2)
		"cycle":
			await _ensure_screen("equip", EQUIP_SCENE, 20)
		_:
			push_warning("[ep02_shots] unknown shot kind: " + kind)


func _run_forge(forge: Node, mode: String) -> void:
	if forge == null:
		return
	match mode:
		"enhance":
			var item: Resource = _find_weapon("pharos_bow")
			if item == null:
				item = _find_weapon("iron_sword")
			if item != null:
				forge.set("_selected_enhance_item", item)
				forge.set("_category", "weapon")
				if forge.has_method("_refresh_selection"):
					forge.call("_refresh_selection")
				await _hold(8)
				if forge.has_method("_on_enhance_confirmed"):
					forge.call("_on_enhance_confirmed")
					await _hold(18)
					await _dismiss_forge_result(forge)
		"alchemy":
			var base_w: Resource = _find_weapon("iron_sword")
			var fodder: Resource = null
			for it in _gs.get("inventory"):
				if it == null:
					continue
				if str(it.weapon_id) == "iron_sword" and it != base_w:
					fodder = it
					break
			if base_w != null and fodder != null:
				forge.set("_selected_alchemy_base", base_w)
				forge.set("_selected_alchemy_fodder", fodder)
				forge.set("_pending_alchemy_fodder", fodder)
				forge.set("_category", "weapon")
				if forge.has_method("_refresh_selection"):
					forge.call("_refresh_selection")
				await _hold(8)
				if forge.has_method("_execute_alchemy"):
					forge.call("_execute_alchemy")
					await _hold(18)
					await _dismiss_forge_result(forge)
		"dismantle":
			var target: Resource = _find_weapon("rusted_blade")
			if target == null:
				target = _find_weapon("iron_sword")
			if target != null and forge.has_method("_execute_dismantle"):
				forge.set("_selected_dismantle_item", target)
				if forge.has_method("_refresh_selection"):
					forge.call("_refresh_selection")
				await _hold(6)
				forge.call("_execute_dismantle", target)
				await _hold(16)
				await _dismiss_forge_result(forge)


## 複数の武器を、与えられたフレーム予算内で均等に見せる。
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
		var _ok: bool = await _open_weapon_detail(current_scene, str(ids[i]))
		var remain: int = target_end - _frames
		if remain > 0:
			await _hold(remain)
		i += 1


# ---------------- メイン ----------------

func _load_cues() -> bool:
	var txt: String = FileAccess.get_file_as_string(MANIFEST_PATH)
	if txt.is_empty():
		push_error("[ep02_shots] cannot read " + MANIFEST_PATH)
		return false
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[ep02_shots] manifest parse failed")
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
		push_error("[ep02_shots] GameState missing")
		quit(1)
		return
	if not _load_cues():
		quit(1)
		return

	DisplayServer.window_set_size(Vector2i(720, 1280))

	## 全所持（各レアリティ・固有装備を名指しで見せるため）
	var unlock: GDScript = load("res://scripts/debug/DebugFullUnlock.gd") as GDScript
	unlock.call("apply")
	_silence_guides()
	## DebugFullUnlock は Lv.99・所持金100万で配る。台本は「序盤」を語るので見え方を戻す。
	_normalize_equip_levels()
	_gs.set("gold", 24_500)
	_gs.set("gacha_token", 12)
	_prepare_forge_items()

	## 検算: ショット表が全キューを漏れなく1回ずつ覆っているか
	var covered: Dictionary = {}
	for shot_v in SHOTS:
		var rng: Array = (shot_v as Dictionary).get("c", [])
		var i: int = int(rng[0])
		while i <= int(rng[1]):
			if covered.has(i):
				push_error("[ep02_shots] cue %d covered twice" % i)
			covered[i] = true
			i += 1
	var missing: Array = []
	var ci: int = 0
	while ci < _cues.size():
		if not covered.has(ci):
			missing.append(ci)
		ci += 1
	if missing.size() > 0:
		push_error("[ep02_shots] uncovered cues: " + str(missing))
		quit(2)
		return

	var audio_sec: float = 0.0
	for c in _cues:
		audio_sec += float((c as Dictionary).get("duration", 0.0))
	var target_frames: int = int(round(audio_sec * float(FPS)))
	print("[ep02_shots] cues=%d audio=%.2fs target_frames=%d shots=%d"
		% [_cues.size(), audio_sec, target_frames, SHOTS.size()])

	## 累積の計画フレーム数に対して実フレーム数を毎回追い込む。
	## こうすると1ショットの超過が後続で必ず吸収され、総尺が音声とズレない。
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
		print("[ep02_shots] %2d %-14s cue%3d-%-3d want=%5.2fs got=%5.2fs cum_drift=%+d"
			% [idx, kind, int(shot["c"][0]), int(shot["c"][1]), sec, float(actual) / float(FPS), _drift])
		idx += 1

	## 端数を合わせて、動画長 = 音声長 にする
	var tail: int = target_frames - _frames
	if tail > 0:
		await _hold(tail)
	print("[ep02_shots] DONE frames=%d (%.2fs) target=%d" % [_frames, float(_frames) / float(FPS), target_frames])
	await _hold(2)
	quit(0)
