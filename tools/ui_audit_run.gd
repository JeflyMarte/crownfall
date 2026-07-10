extends SceneTree

## UI 監査（戦闘・リザルト編 / P3-UI3-002）。
## DungeonScene を実走させ複数時点でスクショ、その後 last_run_* を投入して ResultScene を撮影。
## 実行: godot --path . -s tools/ui_audit_run.gd  （ヘッドレス不可）

const OUT_SUBDIR: String = "/ui_audit"

var _out_dir: String

func _init() -> void:
	call_deferred("_run")

func _shot(tag: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	var file: String = _out_dir + "/%s.png" % tag
	img.save_png(file)
	print("[ui_audit_run] saved: ", file)

func _wait_frames(n: int) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	_out_dir = OS.get_user_data_dir() + OUT_SUBDIR
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var gs: Node = root.get_node("/root/GameState")

	# --- 戦闘画面: モーンゲートを実走 ---
	gs.set("current_dungeon_id", "mourngate")
	change_scene_to_file("res://scenes/dungeon/DungeonScene.tscn")
	await _wait_frames(20)
	_shot("combat_intro")
	# 戦闘・部屋進行を実時間で追う（60fps想定で約4/10/20秒地点）
	await _wait_frames(240)
	_shot("combat_early")
	await _wait_frames(360)
	_shot("combat_mid")
	await _wait_frames(600)
	_shot("combat_late")

	# --- リザルト画面: last_run_* を投入して撮影 ---
	gs.set("last_run_outcome", gs.get("RUN_OUTCOME_CLEAR") if false else "clear")
	gs.set("last_run_exp_reward", 180)
	gs.set("last_run_gold_reward", 240)
	gs.set("last_run_token_reward", 1)
	gs.set("last_run_weapon_dropped", "iron_sword")
	gs.set("last_run_armor_dropped", "leather_armor")
	gs.set("last_run_accessory_dropped", "silver_ring")
	gs.set("last_run_material_gains", {"relic_shard": 3, "ancient_bone": 1})
	gs.set("last_run_exploration_policy", "balanced")
	change_scene_to_file("res://scenes/result/ResultScene.tscn")
	await _wait_frames(20)
	_shot("result_clear")

	# 全滅リザルトも確認
	gs.set("last_run_outcome", "wipe")
	gs.set("last_run_gold_reward", 40)
	gs.set("last_run_token_reward", 0)
	gs.set("last_run_weapon_dropped", "")
	gs.set("last_run_armor_dropped", "")
	gs.set("last_run_accessory_dropped", "")
	change_scene_to_file("res://scenes/result/ResultScene.tscn")
	await _wait_frames(20)
	_shot("result_wipe")

	print("[ui_audit_run] done")
	quit(0)
