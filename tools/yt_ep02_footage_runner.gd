extends SceneTree

## YouTube #2 画面クリップ用フレーム連番（実プレイ多め）。
## 実行: Godot.app --path . -s res://tools/yt_ep02_footage_runner.gd
## 出力: docs/devlog/yt_ep02/footage/frames/<clip>/0001.jpg …
## その後: tools/yt_ep02_encode_footage.sh で mp4 化

const OUT_RES: String = "res://docs/devlog/yt_ep02/footage/frames"
const WAIT_FRAMES: int = 20
const FPS: int = 30

const BASE_SCENE: String = "res://scenes/base/BaseScene.tscn"
const SELECT_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"
const RESULT_SCENE: String = "res://scenes/result/ResultScene.tscn"
const EQUIP_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"

## レア紹介用（N/R/E/L/M/SET）
const RARITY_WEAPON_IDS: Array[String] = [
	"iron_sword", ## N
	"pharos_bow", ## R
	"frostspire_bow", ## E
	"stormveil_needle", ## L
	"burial_crown_greatsword", ## M
	"chronos_toki_bow", ## SET / エンシェント
]

## 固有見せ用レジェンド
const UNIQUE_WEAPON_IDS: Array[String] = [
	"stormveil_needle",
	"volley_horizon_bow",
	"silent_rite_staff",
	"umbra_terminus_staff",
	"abyss_veinblade",
]

var _gs: Node
var _frame_i: int = 0
var _clip: String = ""
var _Enhancer: GDScript


func _init() -> void:
	call_deferred("_run")


func _wait(n: int = WAIT_FRAMES) -> void:
	for _i in n:
		await process_frame


func _out_root() -> String:
	return ProjectSettings.globalize_path(OUT_RES)


func _clip_dir() -> String:
	return _out_root() + "/" + _clip


func _begin_clip(name: String) -> void:
	_clip = name
	_frame_i = 0
	DirAccess.make_dir_recursive_absolute(_clip_dir())
	print("[yt_ep02_footage] BEGIN clip=", name)


func _capture_frame() -> void:
	_frame_i += 1
	var img: Image = root.get_viewport().get_texture().get_image()
	var file: String = "%s/%04d.jpg" % [_clip_dir(), _frame_i]
	img.save_jpg(file, 0.85)


func _record_seconds(sec: float) -> void:
	var target: int = int(sec * FPS)
	var captured: int = 0
	while captured < target:
		await process_frame
		_capture_frame()
		captured += 1
		if captured % 90 == 0:
			print("[yt_ep02_footage] ", _clip, " frames=", captured, "/", target)


func _silence_hub_guides() -> void:
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
	await _wait(6)


func _find_weapon(weapon_id: String) -> Resource:
	for item in _gs.get("inventory"):
		if item != null and str(item.weapon_id) == weapon_id:
			return item
	return null


func _find_weapon_by_rarity(rarity: int) -> Resource:
	## -s ツールでは class_name / 一部 autoload がパース時に見えないことがあるため、
	## DataRegistry は使わず weapon_id 固定リストから引く。
	var by_rarity: Dictionary = {
		0: "iron_sword",
		1: "pharos_bow",
		2: "frostspire_bow",
		3: "stormveil_needle",
		4: "burial_crown_greatsword",
		5: "chronos_toki_bow",
	}
	var wid: String = str(by_rarity.get(rarity, ""))
	if wid.is_empty():
		return null
	return _find_weapon(wid)


func _scroll_detail_bottom(scene: Node) -> void:
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
		await _wait(6)


func _close_detail(scene: Node) -> void:
	if scene == null:
		return
	var overlay: Control = scene.get("_detail_overlay") as Control
	if overlay != null:
		overlay.visible = false
	await _wait(4)


func _open_weapon_detail(scene: Node, weapon_id: String) -> bool:
	var item: Resource = _find_weapon(weapon_id)
	if item == null:
		print("[yt_ep02_footage] weapon missing: ", weapon_id)
		return false
	if scene != null and scene.has_method("_show_item_stats_overlay"):
		scene.call("_show_item_stats_overlay", item, "weapon", true)
		await _wait(10)
		await _scroll_detail_bottom(scene)
		return true
	return false


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
			"damage_total": 18420,
			"damage_max_hit": 3120,
			"damage_max_skill_id": "",
			"damage_max_skill_name": "王牙列断",
			"heal_total": 0,
			"kill_count": 11,
			"damage_taken": 4200,
			"ultimate_count": 3,
			"crit_count": 7,
		}
	if ids.size() >= 2:
		stats[ids[1]] = {
			"damage_total": 12100,
			"damage_max_hit": 2100,
			"damage_max_skill_id": "",
			"damage_max_skill_name": "デッドアイ",
			"heal_total": 0,
			"kill_count": 8,
			"damage_taken": 1800,
			"ultimate_count": 2,
			"crit_count": 5,
		}
	if ids.size() >= 3:
		stats[ids[2]] = {
			"damage_total": 4200,
			"damage_max_hit": 800,
			"damage_max_skill_id": "",
			"damage_max_skill_name": "野戦調合",
			"heal_total": 6400,
			"kill_count": 1,
			"damage_taken": 2100,
			"ultimate_count": 1,
			"crit_count": 0,
		}
	if ids.size() >= 4:
		stats[ids[3]] = {
			"damage_total": 2800,
			"damage_max_hit": 600,
			"damage_max_skill_id": "",
			"damage_max_skill_name": "聖盾打ち",
			"heal_total": 0,
			"kill_count": 2,
			"damage_taken": 9100,
			"ultimate_count": 1,
			"crit_count": 0,
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


func _dismiss_forge_result(forge: Node) -> void:
	if forge == null:
		return
	## 完了オーバーレイがあれば閉じる
	for n in forge.find_children("*", "Control", true, false):
		var nm: String = str(n.name)
		if nm.contains("Result") or nm.contains("Overlay"):
			if n.visible and n is CanvasItem:
				## 明示的な閉じメソッドがあれば使う
				pass
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
		push_error("[yt_ep02_footage] GameState missing")
		quit(1)
		return

	_Enhancer = load("res://scripts/equipment/EquipmentEnhancer.gd") as GDScript
	DirAccess.make_dir_recursive_absolute(_out_root())
	print("[yt_ep02_footage] output: ", _out_root())
	DisplayServer.window_set_size(Vector2i(720, 1280))

	_silence_hub_guides()
	var unlock_script: GDScript = load("res://scripts/debug/DebugFullUnlock.gd") as GDScript
	unlock_script.call("apply")
	_silence_hub_guides()
	_gs.set("gold", 99_999)
	_gs.set("gacha_token", 100)

	var guide_script: GDScript = load("res://scripts/ui/DungeonRouteGuideOverlay.gd") as GDScript
	if guide_script != null and guide_script.has_method("mark_seen"):
		guide_script.call("mark_seen", "descent")
		guide_script.call("mark_seen", "abyss")
		guide_script.call("mark_seen", "event")

	# ========== A: 拠点ナビ（ボタン遷移の入り） ==========
	change_scene_to_file(BASE_SCENE)
	await _wait(24)
	for _i in 5:
		_silence_hub_guides()
		await _dismiss_overlays(current_scene)
		await _wait(4)
	_begin_clip("A_hub")
	await _record_seconds(8.0)
	## 拠点でメニューを押す様子（シーン遷移前まで録画）
	var hub: Node = current_scene
	if hub != null and hub.has_method("_on_roster_button_pressed"):
		## 押す直前の反応を少し残す
		await _record_seconds(2.0)

	# ========== B: 一日の流れ（編成→装備→選択→戦闘導入） ==========
	change_scene_to_file(ROSTER_SCENE)
	await _wait(22)
	await _dismiss_overlays(current_scene)
	_begin_clip("B_day_loop")
	await _record_seconds(10.0)
	## 編成内でスクロールっぽく待つ
	var roster: Node = current_scene
	if roster != null:
		var sc: ScrollContainer = roster.find_child("Scroll", true, false) as ScrollContainer
		if sc == null:
			for c in roster.find_children("*", "ScrollContainer", true, false):
				sc = c as ScrollContainer
				break
		if sc != null:
			sc.scroll_vertical = 180
			await _record_seconds(3.0)
			sc.scroll_vertical = 0
			await _record_seconds(2.0)

	change_scene_to_file(EQUIP_SCENE)
	await _wait(22)
	await _dismiss_overlays(current_scene)
	## 装備一覧をざっと開閉
	var equip: Node = current_scene
	await _record_seconds(4.0)
	if await _open_weapon_detail(equip, "iron_sword"):
		await _record_seconds(3.0)
		await _close_detail(equip)
	if await _open_weapon_detail(equip, "stormveil_needle"):
		await _record_seconds(3.5)
		await _close_detail(equip)
	await _record_seconds(2.0)

	change_scene_to_file(SELECT_SCENE)
	await _wait(26)
	await _dismiss_overlays(current_scene)
	await _record_seconds(8.0)
	var select: Node = current_scene
	if select != null and select.has_method("_on_route_tab_pressed"):
		select.call("_on_route_tab_pressed", "event")
		await _wait(8)
		await _record_seconds(4.0)
		select.call("_on_route_tab_pressed", "main")
		await _wait(8)
		await _record_seconds(4.0)

	_gs.set("current_dungeon_id", "mourngate")
	_gs.set("current_dungeon_tier", 0)
	change_scene_to_file(DUNGEON_SCENE)
	await _wait(36)
	await _record_seconds(12.0)

	# ========== C: 戦闘ドロップ長め ==========
	_begin_clip("C_battle")
	## すでにダンジョンにいる想定。いなければ再入場
	if current_scene == null or not str(current_scene.get_script()).contains("Dungeon"):
		change_scene_to_file(DUNGEON_SCENE)
		await _wait(40)
	await _record_seconds(55.0)

	# ========== D: レアリティ各段階 ==========
	change_scene_to_file(EQUIP_SCENE)
	await _wait(22)
	await _dismiss_overlays(current_scene)
	_begin_clip("D_rarity")
	equip = current_scene
	await _record_seconds(3.0)
	for wid in RARITY_WEAPON_IDS:
		var ok: bool = await _open_weapon_detail(equip, wid)
		if not ok:
			## フォールバック: レア順で最初の1本
			continue
		await _record_seconds(4.0)
		await _close_detail(equip)
		await _record_seconds(1.0)

	# ========== E: 固有効果を複数クリック ==========
	_begin_clip("E_uniques")
	await _record_seconds(2.0)
	for wid2 in UNIQUE_WEAPON_IDS:
		if await _open_weapon_detail(equip, wid2):
			await _record_seconds(4.5)
			await _close_detail(equip)
			await _record_seconds(0.8)

	# ========== F: クリア結果 ==========
	_seed_clear_run()
	change_scene_to_file(RESULT_SCENE)
	await _wait(28)
	_begin_clip("F_result_clear")
	await _record_seconds(8.0)
	var result: Node = current_scene
	if result != null:
		var scroll: ScrollContainer = result.get_node_or_null("Scroll") as ScrollContainer
		if scroll == null:
			scroll = result.find_child("Scroll", true, false) as ScrollContainer
		if scroll != null:
			scroll.scroll_vertical = 280
			await _record_seconds(4.0)
			scroll.scroll_vertical = 520
			await _record_seconds(4.0)
		if result.has_method("_advance_step"):
			for _i in 5:
				result.call("_advance_step")
				await _wait(12)
				await _record_seconds(3.5)
				if int(result.get("_current_step")) == 2:
					await _record_seconds(8.0)
					break

	# ========== G: 全滅結果 ==========
	_seed_wipe_run()
	change_scene_to_file(RESULT_SCENE)
	await _wait(28)
	_begin_clip("G_result_wipe")
	await _record_seconds(12.0)

	# ========== H: 鍛冶 実操作 ==========
	## 錬成用に同系統の強化差を付ける（装備中だと失敗するので外す）
	var base_w: Resource = _find_weapon("iron_sword")
	var fodder_w: Resource = null
	for item in _gs.get("inventory"):
		if item == null:
			continue
		if str(item.weapon_id) == "iron_sword" and item != base_w:
			fodder_w = item
			break
	## 装備解除（錬成・分解のため）
	for member in _gs.call("get_roster"):
		if member == null:
			continue
		if "equipped_weapon" in member and member.equipped_weapon != null:
			var ew: Resource = member.equipped_weapon
			if ew == base_w or ew == fodder_w or (ew != null and str(ew.weapon_id) in ["iron_sword", "rusted_blade"]):
				member.equipped_weapon = null
	if base_w != null and "equip_level" in base_w:
		base_w.equip_level = 3
	if fodder_w != null and "equip_level" in fodder_w:
		fodder_w.equip_level = 1
	## 分解用コモン（未装備）
	var dismantle_target: Resource = _find_weapon("rusted_blade")
	if dismantle_target == null:
		dismantle_target = _find_weapon("cairn_staff")
	if dismantle_target == null:
		dismantle_target = _find_weapon_by_rarity(0)

	change_scene_to_file(BLACKSMITH_SCENE)
	await _wait(28)
	await _dismiss_overlays(current_scene)
	_begin_clip("H_forge")
	var forge: Node = current_scene
	await _record_seconds(4.0)

	## 1) 炉研ぎ実行
	if forge != null and forge.has_method("_set_mode"):
		forge.call("_set_mode", "enhance")
		await _wait(12)
		await _record_seconds(3.0)
	var enhance_item: Resource = _find_weapon("pharos_bow")
	if enhance_item == null:
		enhance_item = _find_weapon_by_rarity(1)
	if forge != null and enhance_item != null:
		forge.set("_selected_enhance_item", enhance_item)
		forge.set("_category", "weapon")
		if forge.has_method("_refresh_selection"):
			forge.call("_refresh_selection")
		await _wait(10)
		await _record_seconds(3.0)
		if forge.has_method("_on_enhance_confirmed"):
			forge.call("_on_enhance_confirmed")
			await _wait(20)
			await _record_seconds(6.0)
			await _dismiss_forge_result(forge)

	## 2) 錬成
	if forge != null and forge.has_method("_set_mode"):
		forge.call("_set_mode", "alchemy")
		await _wait(12)
		await _record_seconds(3.0)
	if forge != null and base_w != null and fodder_w != null:
		forge.set("_selected_alchemy_base", base_w)
		forge.set("_selected_alchemy_fodder", fodder_w)
		forge.set("_pending_alchemy_fodder", fodder_w)
		forge.set("_category", "weapon")
		if forge.has_method("_refresh_selection"):
			forge.call("_refresh_selection")
		await _wait(10)
		await _record_seconds(3.0)
		if forge.has_method("_execute_alchemy"):
			forge.call("_execute_alchemy")
			await _wait(20)
			await _record_seconds(6.0)
			await _dismiss_forge_result(forge)

	## 3) 分解（コモン）
	if forge != null and forge.has_method("_set_mode"):
		forge.call("_set_mode", "dismantle")
		await _wait(12)
		await _record_seconds(3.0)
	if forge != null and dismantle_target != null and forge.has_method("_execute_dismantle"):
		forge.set("_selected_dismantle_item", dismantle_target)
		if forge.has_method("_refresh_selection"):
			forge.call("_refresh_selection")
		await _wait(8)
		await _record_seconds(2.5)
		forge.call("_execute_dismantle", dismantle_target)
		await _wait(18)
		await _record_seconds(5.0)
		await _dismiss_forge_result(forge)

	## 4) 生産
	if forge != null and forge.has_method("_set_mode"):
		forge.call("_set_mode", "produce")
		await _wait(14)
		await _record_seconds(4.0)
	if forge != null:
		var craft: Resource = forge.get("_selected_craft") as Resource
		if craft == null:
			## レシピ先頭を拾う（CraftHelper は -s で未解決になり得るのでシーン側選択を優先）
			var recipes_v: Variant = null
			if forge.has_method("_rebuild_craftable_strip"):
				forge.call("_rebuild_craftable_strip")
			recipes_v = forge.get("_selected_craft")
			craft = recipes_v as Resource
			if craft != null:
				if forge.has_method("_refresh_selection"):
					forge.call("_refresh_selection")
				await _wait(10)
				await _record_seconds(3.0)
		if craft != null:
			forge.set("_pending_craft", craft)
			if forge.has_method("_on_craft_confirmed"):
				forge.call("_on_craft_confirmed")
				await _wait(22)
				await _record_seconds(7.0)
				await _dismiss_forge_result(forge)

	await _record_seconds(3.0)

	# ========== I: 締め用拠点 ==========
	change_scene_to_file(BASE_SCENE)
	await _wait(22)
	for _i in 3:
		_silence_hub_guides()
		await _dismiss_overlays(current_scene)
	_begin_clip("I_hub_close")
	await _record_seconds(10.0)

	print("[yt_ep02_footage] done frames_root=", _out_root())
	quit(0)
