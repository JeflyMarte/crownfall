extends SceneTree

## キャラ紹介｜アルド — 音声 manifest どおり 1文=1ショット。
## 第2回と同型。セクションループ禁止。累積フレームで音声総尺に追い込む。
##
## 実行:
##   Godot --path . --write-movie docs/devlog/yt_chr_ald/footage/chr_ald_shots.avi \
##     --fixed-fps 30 --disable-vsync -s res://tools/yt_chr_ald_shot_runner.gd

const FPS: int = 30
const MANIFEST_PATH: String = "res://docs/devlog/yt_chr_ald/voice/manifest.json"

const BASE_SCENE: String = "res://scenes/base/BaseScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const EQUIP_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"
const SHOWCASE_SCENE: String = "res://scenes/showcase/ShowcaseScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"
const RESULT_SCENE: String = "res://scenes/result/ResultScene.tscn"

const ID_ALD: String = "adventurer_0"
const ID_RIVA: String = "adventurer_1"
const ID_GALEN: String = "adventurer_3"
const ID_KAIDA: String = "gacha_helper_f"
const ID_FIREHAWK: String = "gacha_helper_p"

const WPN_PULSE: String = "pulsekeen_edge"
const ARM_BLOOD: String = "bloodpact_plate"
const ACC_VEIN: String = "bloodvein_signet"
const SKILL_BLOOD: String = "blood_mist_slash"
const RELIC_BERSERK: String = "relic_berserker_charm"

## "c"=キュー [from,to]／"k"=画面／"a"=引数／"s"=結果ステップ
const SHOTS: Array = [
	# ---- S1 前振り ----
	{"c": [0, 2], "k": "hub"},
	{"c": [3, 4], "k": "equip", "a": ID_ALD},
	{"c": [5, 7], "k": "roster"},
	# ---- S2 何者か ----
	{"c": [8, 10], "k": "equip", "a": ID_ALD},
	{"c": [11, 16], "k": "equip_passive", "a": ID_ALD},
	# ---- S3 同職比較 ----
	{"c": [17, 17], "k": "equip", "a": ID_ALD},
	{"c": [18, 20], "k": "equip_passive", "a": ID_KAIDA},
	{"c": [21, 23], "k": "equip_passive", "a": ID_FIREHAWK},
	{"c": [24, 28], "k": "equip", "a": ID_ALD},
	# ---- S4 出血主砲 ----
	{"c": [29, 30], "k": "showcase_staff", "a": "staff_aldo_bleed"},
	{"c": [31, 31], "k": "weapon", "a": WPN_PULSE},
	{"c": [32, 32], "k": "armor", "a": ARM_BLOOD},
	{"c": [33, 33], "k": "accessory", "a": ACC_VEIN},
	{"c": [34, 34], "k": "equip_skill", "a": ID_ALD},
	{"c": [35, 37], "k": "showcase_staff", "a": "staff_aldo_bleed"},
	{"c": [38, 40], "k": "weapon", "a": "ember_fang"},
	# ---- S5 相性 ----
	{"c": [41, 46], "k": "roster"},
	{"c": [47, 49], "k": "equip", "a": ID_ALD},
	# ---- S6 戦闘 ----
	{"c": [50, 53], "k": "dungeon"},
	{"c": [54, 55], "k": "result_step", "a": "clear", "s": 2},
	# ---- S7 締め ----
	{"c": [56, 60], "k": "equip", "a": ID_ALD},
	{"c": [61, 63], "k": "hub"},
	{"c": [64, 65], "k": "showcase_staff", "a": "staff_aldo_bleed"},
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
	var show_g: GDScript = load("res://scripts/ui/DungeonRouteGuideOverlay.gd") as GDScript
	if show_g != null and show_g.has_method("mark_seen"):
		show_g.call("mark_seen", "showcase")


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


func _goto(scene_path: String, settle: int) -> void:
	change_scene_to_file(scene_path)
	await _hold(settle)
	_silence_guides()
	_dismiss_overlays(current_scene)
	await _hold(4)


func _find_member(member_id: String) -> Resource:
	if _gs.has_method("find_roster_member_by_id"):
		return _gs.call("find_roster_member_by_id", member_id) as Resource
	for m in _gs.call("get_roster"):
		if m != null and str(m.id) == member_id:
			return m
	return null


func _find_weapon(weapon_id: String) -> Resource:
	for item in _gs.get("inventory"):
		if item != null and str(item.weapon_id) == weapon_id:
			return item
	var ald: Resource = _find_member(ID_ALD)
	if ald != null and ald.equipped_weapon != null and str(ald.equipped_weapon.weapon_id) == weapon_id:
		return ald.equipped_weapon
	return null


func _find_armor(armor_id: String) -> Resource:
	for item in _gs.get("armor_inventory"):
		if item != null and str(item.armor_id) == armor_id:
			return item
	var ald: Resource = _find_member(ID_ALD)
	if ald != null and ald.equipped_armor != null and str(ald.equipped_armor.armor_id) == armor_id:
		return ald.equipped_armor
	return null


func _find_accessory(acc_id: String) -> Resource:
	for item in _gs.get("accessory_inventory"):
		if item != null and str(item.accessory_id) == acc_id:
			return item
	var ald: Resource = _find_member(ID_ALD)
	if ald != null and ald.equipped_accessory != null and str(ald.equipped_accessory.accessory_id) == acc_id:
		return ald.equipped_accessory
	return null


func _open_item_detail(scene: Node, item: Resource, category: String) -> bool:
	if item == null or scene == null:
		return false
	if scene.has_method("_show_item_stats_overlay"):
		scene.call("_show_item_stats_overlay", item, category, true)
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


func _select_equip_member(scene: Node, member_id: String) -> void:
	if scene == null:
		return
	var members: Array = []
	if scene.has_method("_get_view_members"):
		members = scene.call("_get_view_members") as Array
	else:
		members = _gs.call("get_roster") as Array
	var idx: int = -1
	var i: int = 0
	while i < members.size():
		var m: Resource = members[i] as Resource
		if m != null and str(m.id) == member_id:
			idx = i
			break
		i += 1
	if idx < 0:
		print("[chr_ald] member not in equip view: ", member_id)
		return
	scene.set("_selected_member_index", idx)
	if scene.has_method("_refresh_display"):
		scene.call("_refresh_display")
	await _hold(8)


func _set_equip_tab(scene: Node, tab: int) -> void:
	if scene != null and scene.has_method("_set_active_tab"):
		scene.call("_set_active_tab", tab)
		await _hold(8)


func _ensure_party_for_video() -> void:
	var ald: Resource = _find_member(ID_ALD)
	var riva: Resource = _find_member(ID_RIVA)
	var galen: Resource = _find_member(ID_GALEN)
	var party: Array = []
	if ald != null:
		party.append(ald)
	if riva != null:
		party.append(riva)
	if galen != null:
		party.append(galen)
	## 4枠までスターターで埋める
	for m in _gs.call("get_roster"):
		if party.size() >= int(_gs.get("ACTIVE_PARTY_SIZE")):
			break
		if m == null:
			continue
		if party.has(m):
			continue
		if str(m.id).begins_with("adventurer_"):
			party.append(m)
	_gs.set("party_members", party)
	_gs.set("showcase_member_id", ID_ALD)


func _apply_ald_bleed_build() -> void:
	var ald: Resource = _find_member(ID_ALD)
	if ald == null:
		return
	var cat: GDScript = load("res://scripts/showcase/ShowcaseCatalog.gd") as GDScript
	var preset: Dictionary = {}
	if cat.has_method("find_staff_preset"):
		preset = cat.call("find_staff_preset", "staff_aldo_bleed") as Dictionary
	if preset.is_empty():
		for p in cat.get("STAFF_PRESETS"):
			if str((p as Dictionary).get("id", "")) == "staff_aldo_bleed":
				preset = p
				break
	if preset.is_empty():
		print("[chr_ald] staff_aldo_bleed missing")
		return
	## カタログの make を使い、実キャラへ装着＋インベントリにも残す（詳細表示用）
	var wpn: Resource = cat.call("_make_weapon", WPN_PULSE, "yt_ald", 4, 1) as Resource
	var arm: Resource = cat.call("_make_armor", ARM_BLOOD, "yt_ald", 4, 1) as Resource
	var acc: Resource = cat.call("_make_accessory", ACC_VEIN, "yt_ald", 4, 1) as Resource
	if wpn != null:
		ald.equipped_weapon = wpn
		(_gs.get("inventory") as Array).append(wpn)
	if arm != null:
		ald.equipped_armor = arm
		(_gs.get("armor_inventory") as Array).append(arm)
	if acc != null:
		ald.equipped_accessory = acc
		(_gs.get("accessory_inventory") as Array).append(acc)
	var skills: Array[String] = [SKILL_BLOOD]
	ald.equipped_skill_ids = skills
	if _gs.has_method("set_member_relic"):
		_gs.call("set_member_relic", ald, RELIC_BERSERK)
	## レベルは見せすぎない
	ald.level = clampi(int(ald.level), 1, 40)
	if "equip_level" in wpn:
		wpn.equip_level = 12
	if arm != null and "equip_level" in arm:
		arm.equip_level = 12
	if acc != null and "equip_level" in acc:
		acc.equip_level = 12


func _normalize_equip_levels() -> void:
	for key: String in ["inventory", "armor_inventory", "accessory_inventory"]:
		for item in _gs.get(key):
			if item == null:
				continue
			if "equip_level" in item and int(item.equip_level) > 40:
				item.equip_level = 12
			if "equip_exp" in item:
				item.equip_exp = 0


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
		"弱点属性": 3,
		"パーティ連携": 2,
		"パッシブ": 4,
		"属性シナジー": 1,
	})
	_gs.set("last_run_wipe_cause", {})
	_gs.set("last_run_equipment_drops", [
		{"category": "weapon", "instance_id": "", "item_id": WPN_PULSE},
	])
	var stats: Dictionary = {}
	if ids.size() >= 1:
		stats[ids[0]] = {
			"damage_total": 22100, "damage_max_hit": 3400,
			"damage_max_skill_id": "", "damage_max_skill_name": "血煙斬",
			"heal_total": 0, "kill_count": 12, "damage_taken": 3800,
			"ultimate_count": 3, "crit_count": 8,
		}
	if ids.size() >= 2:
		stats[ids[1]] = {
			"damage_total": 9800, "damage_max_hit": 1800,
			"damage_max_skill_id": "", "damage_max_skill_name": "デッドアイ",
			"heal_total": 0, "kill_count": 6, "damage_taken": 1600,
			"ultimate_count": 2, "crit_count": 4,
		}
	if ids.size() >= 3:
		stats[ids[2]] = {
			"damage_total": 2400, "damage_max_hit": 500,
			"damage_max_skill_id": "", "damage_max_skill_name": "聖盾打ち",
			"heal_total": 0, "kill_count": 1, "damage_taken": 9000,
			"ultimate_count": 1, "crit_count": 0,
		}
	_gs.set("last_run_combat_stats", stats)
	_gs.set("last_run_exp_by_member", {})
	_gs.set("last_run_exp_snapshots", {})
	_gs.set("last_run_level_ups", {})


func _ensure_screen(kind: String, scene_path: String, settle: int) -> void:
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
		"equip", "equip_passive", "equip_skill", "weapon", "armor", "accessory":
			await _ensure_screen("equip", EQUIP_SCENE, 22)
			await _close_detail(current_scene)
			var mid: String = ID_ALD
			if kind in ["equip", "equip_passive", "equip_skill"]:
				mid = str(arg) if arg != null else ID_ALD
			else:
				mid = ID_ALD
			await _select_equip_member(current_scene, mid)
			if kind == "equip_passive":
				await _set_equip_tab(current_scene, 3)
			elif kind == "equip_skill":
				await _set_equip_tab(current_scene, 1)
			elif kind == "weapon":
				await _set_equip_tab(current_scene, 0)
				await _close_detail(current_scene)
				var w: Resource = _find_weapon(str(arg))
				var _okw: bool = await _open_item_detail(current_scene, w, "weapon")
			elif kind == "armor":
				await _set_equip_tab(current_scene, 0)
				await _close_detail(current_scene)
				var a: Resource = _find_armor(str(arg))
				var _oka: bool = await _open_item_detail(current_scene, a, "armor")
			elif kind == "accessory":
				await _set_equip_tab(current_scene, 0)
				await _close_detail(current_scene)
				var x: Resource = _find_accessory(str(arg))
				var _okx: bool = await _open_item_detail(current_scene, x, "accessory")
		"showcase_staff":
			await _ensure_screen("showcase", SHOWCASE_SCENE, 28)
			var sc: Node = current_scene
			if sc != null:
				sc.set("_staff_preset_id", str(arg) if arg != null else "staff_aldo_bleed")
				if sc.has_method("_set_mode"):
					## Mode.STAFF = 1
					sc.call("_set_mode", 1)
				elif sc.has_method("_refresh_display"):
					sc.call("_refresh_display")
				await _hold(12)
		"dungeon":
			_gs.set("current_dungeon_id", "mourngate")
			_gs.set("current_dungeon_tier", 0)
			await _ensure_screen("dungeon", DUNGEON_SCENE, 34)
			var dg: Node = current_scene
			if dg != null and bool(dg.get("_dive_intro_active")) and dg.has_method("_skip_dungeon_dive_intro"):
				dg.call("_skip_dungeon_dive_intro")
				await _hold(4)
			if dg != null and dg.has_method("_apply_combat_speed"):
				dg.call("_apply_combat_speed", 1.0)
			await _hold(24)
		"result", "result_step":
			_seed_clear_run()
			_cur_screen = ""
			await _goto(RESULT_SCENE, 26)
			_cur_screen = "result_clear"
			var rs: Node = current_scene
			if kind == "result_step" and rs != null and rs.has_method("_advance_step"):
				var si: int = 0
				while si < maxi(1, steps):
					rs.call("_advance_step")
					await _hold(10)
					si += 1
		_:
			push_warning("[chr_ald] unknown shot: " + kind)


func _load_cues() -> bool:
	var txt: String = FileAccess.get_file_as_string(MANIFEST_PATH)
	if txt.is_empty():
		push_error("[chr_ald] cannot read " + MANIFEST_PATH)
		return false
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[chr_ald] manifest parse failed")
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
		push_error("[chr_ald] GameState missing")
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
	_ensure_party_for_video()
	_apply_ald_bleed_build()
	_gs.set("gold", 24_500)
	_gs.set("gacha_token", 12)

	var covered: Dictionary = {}
	for shot_v in SHOTS:
		var rng: Array = (shot_v as Dictionary).get("c", [])
		var i: int = int(rng[0])
		while i <= int(rng[1]):
			if covered.has(i):
				push_error("[chr_ald] cue %d covered twice" % i)
			covered[i] = true
			i += 1
	var missing: Array = []
	var ci: int = 0
	while ci < _cues.size():
		if not covered.has(ci):
			missing.append(ci)
		ci += 1
	if missing.size() > 0:
		push_error("[chr_ald] uncovered cues: " + str(missing))
		quit(2)
		return

	var audio_sec: float = 0.0
	for c in _cues:
		audio_sec += float((c as Dictionary).get("duration", 0.0))
	var target_frames: int = int(round(audio_sec * float(FPS)))
	print("[chr_ald] cues=%d audio=%.2fs target_frames=%d shots=%d"
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

		await _setup_shot(kind, arg, steps)
		var remain: int = planned - _frames
		if remain > 0:
			await _hold(remain)

		var actual: int = _frames - began
		_drift = _frames - planned
		print("[chr_ald] %2d %-16s cue%3d-%-3d want=%5.2fs got=%5.2fs cum_drift=%+d"
			% [idx, kind, int(shot["c"][0]), int(shot["c"][1]), sec, float(actual) / float(FPS), _drift])
		idx += 1

	var tail: int = target_frames - _frames
	if tail > 0:
		await _hold(tail)
	print("[chr_ald] DONE frames=%d (%.2fs) target=%d" % [_frames, float(_frames) / float(FPS), target_frames])
	await _hold(2)
	quit(0)
