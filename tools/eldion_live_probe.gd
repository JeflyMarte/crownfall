extends SceneTree

## オーナー添付パーティ相当で DungeonScene 本番戦闘経路のエルディオン戦を回す。
## Usage: bash tools/eldion_live_probe.sh [--runs=3]
## 注意: `-s` では autoload 識別子をコンパイル時参照しない（balance_sim と同型）。

const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"
const MAX_FRAMES_PER_RUN: int = 120_000

var _runs: int = 3
var _wins: int = 0
var _wipes: int = 0
var _other: int = 0
var _gs: Node = null


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	_gs = get_root().get_node_or_null("GameState")
	if _gs == null:
		push_error("GameState autoload not found")
		quit(1)
		return
	_parse_args()
	print("=== Eldion Live Probe (DungeonScene) runs=%d ===" % _runs)
	Engine.time_scale = 6.0
	for i: int in _runs:
		var outcome: String = await _run_once(i + 1)
		match outcome:
			"clear":
				_wins += 1
			"wipe":
				_wipes += 1
			_:
				_other += 1
				print("RUN %d unexpected outcome=%s" % [i + 1, outcome])
	print("=== RESULT wins=%d wipes=%d other=%d / %d ===" % [_wins, _wipes, _other, _runs])
	quit(0 if _other == 0 else 2)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts: PackedStringArray = str(arg).split("=")
		if parts[0] == "--runs" and parts.size() > 1:
			_runs = maxi(1, int(parts[1]))


func _run_once(run_no: int) -> String:
	var party_script: Script = load("res://scripts/debug/DebugOwnerEldionParty.gd")
	party_script.apply()
	party_script.dump_party_stats()
	_gs.last_run_outcome = ""
	_gs.debug_start_at_boss = true
	var packed: PackedScene = load(DUNGEON_SCENE) as PackedScene
	if packed == null:
		push_error("missing DungeonScene")
		return "error"
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	print("RUN %d: entered DungeonScene (boss seek)" % run_no)
	var frames: int = 0
	var outcome: String = ""
	while frames < MAX_FRAMES_PER_RUN:
		await process_frame
		frames += 1
		outcome = str(_gs.last_run_outcome)
		if not outcome.is_empty():
			break
		if not is_instance_valid(scene):
			outcome = str(_gs.last_run_outcome)
			break
	if outcome.is_empty():
		outcome = "timeout"
	print("RUN %d: outcome=%s frames=%d time_scale=%.1f" % [run_no, outcome, frames, Engine.time_scale])
	if is_instance_valid(scene):
		scene.queue_free()
		await process_frame
	return outcome
