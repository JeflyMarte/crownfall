extends SceneTree

## P3-BAL-005 — headless バランスシミュレーションハーネス。
##
## 実データ（DungeonController の部屋列/エンカウント抽選・CombatController の
## CT/Threat/陣形/人数補正・DamageCalculator のダメージ式・天候ロール）を使い、
## ダンジョン周回を N 回一括シミュレートして 勝率 / 全滅箇所 / TTK / 与ダメ内訳 を出す。
##
## 【近似の範囲】通常攻撃のみで解決する（スキル・戦術ガンビット・パッシブ・遺物・
## 状態異常・コンボ・連携・ボスフェーズは未シミュレート）。実プレイより辛めの
## ベースライン＝「素の武器と編成だけで成立するか」の下限指標として読むこと。
##
## 【実装注意】`-s` 実行ではスクリプト起動時コンパイルの時点で autoload が未登録の
## ため、GameState 等を参照するゲームクラスをコンパイル時識別子で参照すると
## 連鎖コンパイル失敗する。ゲームクラスは必ず実行時 load() で取得すること。
##
## Usage:
##   godot --headless -s res://tools/balance_sim.gd -- --runs=300 --dungeon=mourngate --party-level=1
##   （tools/balance_sim.sh 経由推奨）

const BATTLE_ACTION_CAP: int = 600

var _runs: int = 300
var _dungeon_id: String = ""
var _party_level: int = 1

# 実行時ロード（コンパイル時識別子は使わない — ヘッダ注意書き参照）
var _gs: Node = null
var _enums: GDScript = null
var _dmg_calc: GDScript = null
var _balance: GDScript = null
var _level_system: GDScript = null
var _dc_script: GDScript = null
var _cc_script: GDScript = null

func _init() -> void:
	call_deferred("_main")

func _main() -> void:
	_gs = get_root().get_node_or_null("GameState")
	if _gs == null:
		push_error("GameState autoload not found — run inside project")
		quit(1)
		return
	_enums = load("res://scripts/core/Enums.gd")
	_dmg_calc = load("res://scripts/combat/DamageCalculator.gd")
	_balance = load("res://scripts/combat/BalanceConfig.gd")
	_level_system = load("res://scripts/systems/LevelSystem.gd")
	_dc_script = load("res://scripts/dungeon/DungeonController.gd")
	_cc_script = load("res://scripts/combat/CombatController.gd")
	_parse_args()
	if _dungeon_id.is_empty():
		_dungeon_id = load("res://scripts/core/Constants.gd").DEFAULT_DUNGEON_ID
	print("=== Crownfall Balance Sim ===")
	print("dungeon=%s runs=%d party_level=%d party_size=%d" % [
		_dungeon_id, _runs, _party_level, _gs.ACTIVE_PARTY_SIZE
	])
	_apply_party_level()
	var stats: Dictionary = _simulate_all()
	_report(stats)
	quit(0)

func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts: PackedStringArray = str(arg).split("=")
		match parts[0]:
			"--runs":
				if parts.size() > 1:
					_runs = maxi(1, int(parts[1]))
			"--dungeon":
				if parts.size() > 1:
					_dungeon_id = parts[1]
			"--party-level":
				if parts.size() > 1:
					_party_level = clampi(int(parts[1]), 1, 50)

func _apply_party_level() -> void:
	for member in _gs.roster:
		member.level = _party_level
		member.exp = 0

func _simulate_all() -> Dictionary:
	var stats: Dictionary = {
		"clears": 0,
		"wipes": 0,
		"stalemates": 0,
		"wipe_room_hist": {},          # 部屋index → 全滅回数
		"wipe_kind_hist": {},          # 敵種別(normal/elite/boss) → 全滅回数
		"end_hp_ratio_sum": 0.0,       # クリア時のみ
		"deaths_sum": 0,
		"battle_actions": {"normal": [], "elite": [], "boss": []},
		"member_damage": {},           # member_id → 累計与ダメ
		"exp_sum": 0,
		"gold_sum": 0,
	}
	for run_i in _runs:
		_simulate_run(stats)
	return stats

func _simulate_run(stats: Dictionary) -> void:
	var dc: Node = _dc_script.new()
	var cc: Node = _cc_script.new()
	get_root().add_child(dc)
	get_root().add_child(cc)
	dc.start_dungeon(_dungeon_id)
	cc.reset_party_hp_for_run()
	var rt_combat: int = _enums.RoomType.COMBAT
	var rt_elite: int = _enums.RoomType.ELITE
	var rt_boss: int = _enums.RoomType.BOSS
	var wiped: bool = false
	var stalemate: bool = false
	while not dc.is_completed and not wiped and not stalemate:
		var rt: int = dc.current_room_type
		if rt == rt_combat or rt == rt_elite or rt == rt_boss:
			var kind: String = _room_kind(rt)
			var group: Array = dc.pick_combat_enemy_group()
			if not group.is_empty():
				var outcome: Dictionary = _simulate_battle(cc, dc, group, stats)
				(stats["battle_actions"][kind] as Array).append(int(outcome["actions"]))
				if outcome["wiped"]:
					wiped = true
					var room_key: String = str(dc.current_room_index)
					stats["wipe_room_hist"][room_key] = int(stats["wipe_room_hist"].get(room_key, 0)) + 1
					stats["wipe_kind_hist"][kind] = int(stats["wipe_kind_hist"].get(kind, 0)) + 1
				elif outcome["stalemate"]:
					stalemate = true
		dc.advance_room()
	if wiped:
		stats["wipes"] = int(stats["wipes"]) + 1
	elif stalemate:
		stats["stalemates"] = int(stats["stalemates"]) + 1
	else:
		stats["clears"] = int(stats["clears"]) + 1
		stats["end_hp_ratio_sum"] = float(stats["end_hp_ratio_sum"]) + _party_hp_ratio(cc)
	stats["deaths_sum"] = int(stats["deaths_sum"]) + _dead_count(cc)
	stats["exp_sum"] = int(stats["exp_sum"]) + int(dc.run_exp_reward)
	stats["gold_sum"] = int(stats["gold_sum"]) + int(dc.run_gold_reward)
	dc.queue_free()
	cc.queue_free()

func _room_kind(rt: int) -> String:
	if rt == _enums.RoomType.BOSS:
		return "boss"
	if rt == _enums.RoomType.ELITE:
		return "elite"
	return "normal"

## 通常攻撃のみの CT 駆動バトル。戻り値 {wiped, stalemate, actions}
func _simulate_battle(cc: Node, dc: Node, group: Array, stats: Dictionary) -> Dictionary:
	cc.start_combat_group(group, dc.get_enemy_level())
	var actions: int = 0
	while not cc.is_combat_cleared() and not cc.is_party_wiped():
		actions += 1
		if actions > BATTLE_ACTION_CAP:
			cc.end_combat()
			return {"wiped": false, "stalemate": true, "actions": actions}
		var actor: Dictionary = cc.advance_to_next_actor()
		if actor.is_empty():
			break
		if actor["kind"] == "party":
			_do_member_attack(cc, dc, int(actor["index"]), stats)
		else:
			_do_enemy_attack(cc, int(actor["index"]))
		cc.decay_threat()
	var wiped: bool = cc.is_party_wiped()
	cc.end_combat()
	return {"wiped": wiped, "stalemate": false, "actions": actions}

func _do_member_attack(cc: Node, dc: Node, member_idx: int, stats: Dictionary) -> void:
	if not cc.is_member_alive(member_idx):
		return
	var slot: int = cc.resolve_member_target(member_idx, "front")
	if not cc.is_enemy_slot_alive(slot):
		return
	var result: Dictionary = _dmg_calc.member_attack_damage(
		cc, dc.current_dungeon_data, dc.run_damage_multiplier, member_idx, slot
	)
	var dmg: int = int(result["damage"])
	cc.apply_damage_to_enemy_slot(slot, dmg)
	cc.add_threat(member_idx, float(dmg) * _balance.THREAT_DAMAGE_K)
	_track_member_damage(stats, member_idx, dmg)
	if cc.is_enemy_slot_defeated(slot):
		cc.capture_rewards_at(slot)
		var mult: float = dc.get_reward_multiplier()
		dc.accumulate_rewards(
			int(round(cc.last_exp_reward * mult)),
			int(round(cc.last_gold_reward * mult))
		)

func _do_enemy_attack(cc: Node, slot: int) -> void:
	if not cc.is_enemy_slot_alive(slot):
		return
	if cc.should_enemy_skip_action_at(slot):
		return
	var target: int = cc.pick_enemy_target_member_index(slot)
	if target < 0:
		return
	var result: Dictionary = _dmg_calc.enemy_damage_to_member(
		cc, target, 1.0, cc.get_enemy_attack_at(slot), slot
	)
	var dmg: int = int(result["final"])
	cc.apply_damage_to_member(target, dmg)
	cc.add_threat(target, float(dmg) * _balance.THREAT_TAKEN_K)

func _track_member_damage(stats: Dictionary, member_idx: int, dmg: int) -> void:
	var combatants: Array = _gs.get_combatants()
	if member_idx < 0 or member_idx >= combatants.size():
		return
	var member: Resource = combatants[member_idx]
	if member == null:
		return
	var key: String = "%s(%s)" % [str(member.display_name), str(member.job_id)]
	stats["member_damage"][key] = int(stats["member_damage"].get(key, 0)) + dmg

func _party_hp_ratio(cc: Node) -> float:
	var cur: int = 0
	var mx: int = 0
	for i in cc.party_combat_hp.size():
		cur += maxi(0, int(cc.party_combat_hp[i]))
		mx += maxi(1, int(cc.party_max_hp[i]))
	return float(cur) / float(mx) if mx > 0 else 0.0

func _dead_count(cc: Node) -> int:
	var n: int = 0
	for hp in cc.party_combat_hp:
		if int(hp) <= 0:
			n += 1
	return n

func _report(stats: Dictionary) -> void:
	var clears: int = int(stats["clears"])
	var wipes: int = int(stats["wipes"])
	var stalemates: int = int(stats["stalemates"])
	print("")
	print("── 結果 ──────────────────────────────")
	print("クリア率   : %5.1f%%  (%d/%d)" % [100.0 * clears / _runs, clears, _runs])
	print("全滅率     : %5.1f%%  (%d)" % [100.0 * wipes / _runs, wipes])
	if stalemates > 0:
		print("膠着       : %d 回（%d行動超・要調査）" % [stalemates, BATTLE_ACTION_CAP])
	if clears > 0:
		print("クリア時 残HP: %5.1f%%" % [100.0 * float(stats["end_hp_ratio_sum"]) / clears])
	print("平均戦闘不能: %.2f 人/ラン" % [float(stats["deaths_sum"]) / _runs])
	print("平均EXP/ラン: %.0f ／ 平均Gold/ラン: %.0f" % [
		float(stats["exp_sum"]) / _runs, float(stats["gold_sum"]) / _runs
	])
	print("")
	print("── 戦闘の長さ（行動数・全ユニット計） ──")
	for kind in ["normal", "elite", "boss"]:
		var arr: Array = stats["battle_actions"][kind]
		if arr.is_empty():
			continue
		var total: int = 0
		for v in arr:
			total += int(v)
		print("%-7s: 平均 %5.1f 行動（n=%d）" % [kind, float(total) / arr.size(), arr.size()])
	print("")
	print("── 全滅箇所 ──────────────────────────")
	if wipes == 0:
		print("（全滅なし）")
	else:
		for kind in stats["wipe_kind_hist"]:
			print("%-7s: %d 回" % [kind, int(stats["wipe_kind_hist"][kind])])
		var rooms: Array = stats["wipe_room_hist"].keys()
		rooms.sort_custom(func(a, b): return int(a) < int(b))
		for room in rooms:
			print("  部屋 %2d: %d 回" % [int(room), int(stats["wipe_room_hist"][room])])
	print("")
	print("── 与ダメ内訳（ジョブバランス） ──────")
	var total_dmg: int = 0
	for key in stats["member_damage"]:
		total_dmg += int(stats["member_damage"][key])
	var entries: Array = stats["member_damage"].keys()
	entries.sort_custom(func(a, b):
		return int(stats["member_damage"][a]) > int(stats["member_damage"][b]))
	for key in entries:
		var d: int = int(stats["member_damage"][key])
		print("%-24s: %5.1f%%  (計 %d)" % [key, 100.0 * d / maxi(1, total_dmg), d])
	print("")
	print("BALANCE_SIM: DONE")
