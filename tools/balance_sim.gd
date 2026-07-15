extends SceneTree

## P3-BAL-005 — headless バランスシミュレーションハーネス。
##
## 実データ（DungeonController の部屋列/エンカウント抽選・CombatController の
## CT/Threat/陣形/人数補正・DamageCalculator のダメージ式・天候ロール）を使い、
## ダンジョン周回を N 回一括シミュレートして 勝率 / 全滅箇所 / TTK / 与ダメ内訳 を出す。
##
## 【近似の範囲・v2】通常攻撃＋装備スキル①②（damage/heal・CD準拠・詠唱無視）を
## シミュレートする。未シミュレート＝必殺技・buff/状態異常付与・戦術ガンビット・
## パッシブ・遺物・コンボ・連携・ボスフェーズ。実プレイよりやや辛めの指標として読む。
##
## --sweep モードはレベル成長値（LevelSystem.hp_per_level / attack_per_level）の
## 組合せを掃引し、レベル帯ごとのクリア率グリッドを出力する（P3-BAL-006）。
##
## 【実装注意】`-s` 実行ではスクリプト起動時コンパイルの時点で autoload が未登録の
## ため、GameState 等を参照するゲームクラスをコンパイル時識別子で参照すると
## 連鎖コンパイル失敗する。ゲームクラスは必ず実行時 load() で取得すること。
##
## Usage:
##   godot --headless -s res://tools/balance_sim.gd -- --runs=300 --dungeon=mourngate --party-level=1
##   godot --headless -s res://tools/balance_sim.gd -- --stage=mourngate_1_1 --party-size=1 --party-level=3 --runs=100
##   godot --headless -s res://tools/balance_sim.gd -- --mourngate-screen --runs=80
##   （tools/balance_sim.sh 経由推奨）

const BATTLE_ACTION_CAP: int = 600
## 回復スキル使用の HP しきい値（最負傷者がこの割合未満なら回復を優先）
const HEAL_HP_THRESHOLD: float = 0.6

var _runs: int = 300
var _dungeon_id: String = ""
var _stage_id: String = ""
var _party_level: int = 1
var _party_size: int = -1
## カンマ区切り adventurer_id（指定時はこれだけ編成）
var _party_ids: PackedStringArray = PackedStringArray()
var _sweep: bool = false
var _mourngate_screen: bool = false
## 敵ステータス一括倍率（探索用・ゲーム本体には影響しない）
var _enemy_scale: float = 1.0
## ボス部屋のみの倍率（探索用）
var _boss_scale: float = 1.0
## 成長値の一時上書き（<0 なら BalanceConfig の現行値）
var _hp_per_level_override: int = -1
var _atk_per_level_override: int = -1
## 想定装備ティア（<0 なら初期装備のまま）: 武器実効ATK / 防具DEF / 防具HPボーナス
var _gear_atk: int = -1
var _gear_def: int = -1
var _gear_hp: int = -1

# 戦闘中スキル CD 管理（battle CT クロック基準）: "midx:skill_id" → 次回使用可能 CT
var _battle_ct: float = 0.0
var _skill_ready_at: Dictionary = {}

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
	if _mourngate_screen:
		_run_mourngate_screen()
		quit(0)
		return
	if _sweep:
		_run_sweep()
		quit(0)
		return
	if _hp_per_level_override >= 0:
		_level_system.hp_per_level = _hp_per_level_override
	if _atk_per_level_override >= 0:
		_level_system.attack_per_level = _atk_per_level_override
	_prepare_party()
	print("=== Crownfall Balance Sim ===")
	print("dungeon=%s stage=%s runs=%d party_level=%d party_size=%d hp/Lv=%d atk/Lv=%d enemy_scale=%.2f" % [
		_dungeon_id,
		_stage_id if not _stage_id.is_empty() else "-",
		_runs,
		_party_level,
		_gs.party_members.size(),
		_level_system.hp_per_level,
		_level_system.attack_per_level,
		_enemy_scale,
	])
	_apply_party_level()
	var stats: Dictionary = _simulate_all()
	_report(stats)
	quit(0)

## 成長値 sweep（P3-BAL-006）。hp/atk per Lv の組合せ × レベル帯でクリア率グリッドを出す。
const SWEEP_HP_VALUES: Array[int] = [3, 4, 5, 6]
const SWEEP_ATK_VALUES: Array[int] = [1, 2]
const SWEEP_LEVELS: Array[int] = [1, 3, 6, 10, 13, 16, 20]

func _run_sweep() -> void:
	print("=== Crownfall Balance Sweep (dungeon=%s runs=%d/cell) ===" % [_dungeon_id, _runs])
	var header: String = "hp/atk per Lv |"
	for lv in SWEEP_LEVELS:
		header += " Lv%-3d" % lv
	print(header)
	for hp_v in SWEEP_HP_VALUES:
		for atk_v in SWEEP_ATK_VALUES:
			_level_system.hp_per_level = hp_v
			_level_system.attack_per_level = atk_v
			var row: String = "HP+%d / ATK+%d  |" % [hp_v, atk_v]
			for lv in SWEEP_LEVELS:
				_party_level = lv
				_apply_party_level()
				var stats: Dictionary = _simulate_all()
				row += " %4.0f%%" % [100.0 * int(stats["clears"]) / _runs]
			print(row)
	# 現行値へ復元
	_level_system.hp_per_level = _balance.HP_PER_LEVEL
	_level_system.attack_per_level = _balance.ATTACK_PER_LEVEL
	print("BALANCE_SWEEP: DONE")

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
			"--stage":
				if parts.size() > 1:
					_stage_id = parts[1]
			"--party-level":
				if parts.size() > 1:
					_party_level = clampi(int(parts[1]), 1, _level_system.MAX_LEVEL)
			"--party-size":
				if parts.size() > 1:
					_party_size = clampi(int(parts[1]), 1, 4)
			"--party-ids":
				if parts.size() > 1:
					_party_ids = parts[1].split(",", false)
			"--mourngate-screen":
				_mourngate_screen = true
			"--sweep":
				_sweep = true
			"--enemy-scale":
				if parts.size() > 1:
					_enemy_scale = clampf(float(parts[1]), 0.1, 3.0)
			"--boss-scale":
				if parts.size() > 1:
					_boss_scale = clampf(float(parts[1]), 0.1, 3.0)
			"--hp-per-level":
				if parts.size() > 1:
					_hp_per_level_override = clampi(int(parts[1]), 0, 20)
			"--atk-per-level":
				if parts.size() > 1:
					_atk_per_level_override = clampi(int(parts[1]), 0, 10)
			"--gear-atk":
				if parts.size() > 1:
					_gear_atk = maxi(0, int(parts[1]))
			"--gear-def":
				if parts.size() > 1:
					_gear_def = maxi(0, int(parts[1]))
			"--gear-hp":
				if parts.size() > 1:
					_gear_hp = maxi(0, int(parts[1]))


## 編成人数／メンバー指定を適用（基本ロスター前提）。
func _prepare_party() -> void:
	# フル基本ロスターへ戻してから削る
	if _gs.has_method("reset_for_new_game"):
		_gs.reset_for_new_game()
	# starter_progression だと1人になるため、旧モード相当で5人揃える
	_gs.starter_progression_v1 = false
	if _gs.has_method("ensure_base_roster_complete"):
		_gs.ensure_base_roster_complete()
	if _gs.roster.is_empty() and _gs.has_method("_init_party"):
		_gs._init_party()
	var members: Array = []
	if not _party_ids.is_empty():
		for raw_id: String in _party_ids:
			var adv_id: String = raw_id.strip_edges()
			var found: Resource = null
			for adv: Resource in _gs.roster:
				if adv != null and str(adv.id) == adv_id:
					found = adv
					break
			if found != null and not members.has(found):
				members.append(found)
	elif _party_size > 0:
		for i: int in mini(_party_size, _gs.roster.size()):
			members.append(_gs.roster[i])
	else:
		return
	if members.is_empty():
		push_error("party setup empty — check --party-ids / --party-size")
		return
	_gs.set_active_party(members)


## モーンゲート 1-1〜1-5 スクリーニング（ソロStress＋章加入進行想定）。
func _run_mourngate_screen() -> void:
	print("=== Mourngate Solo / Join Progression Screen ===")
	print("近似: 通常攻撃+スキル①②のみ。実プレイよりやや辛め。runs/cell=%d" % _runs)
	print("")
	print("── A) 純ソロ Stress（全員アルド単独・推奨Lv）──")
	_print_screen_header()
	for chapter: int in range(1, 6):
		var stage_id: String = "mourngate_1_%d" % chapter
		var rec_lv: int = _stage_recommended_level(stage_id)
		_run_screen_cell("solo@rec", stage_id, ["adventurer_0"], rec_lv)
	print("")
	print("── B) 純ソロ Stress（アルド・低Lv寄り）──")
	_print_screen_header()
	var low_levels: Array[int] = [1, 2, 3, 4, 5]
	for chapter: int in range(1, 6):
		var stage_id2: String = "mourngate_1_%d" % chapter
		_run_screen_cell("solo@low", stage_id2, ["adventurer_0"], low_levels[chapter - 1])
	print("")
	print("── C) 章加入進行想定（クリア後に+1）──")
	print("   1-1:1人 / 1-2:2人 / 1-3:3人 / 1-4〜1-5:4人（キュー: アルド→ガレン→リーヴァ→アイリス）")
	_print_screen_header()
	var prog: Array[Dictionary] = [
		{"stage": "mourngate_1_1", "ids": ["adventurer_0"], "lv": 1},
		{"stage": "mourngate_1_1", "ids": ["adventurer_0"], "lv": 3},
		{"stage": "mourngate_1_2", "ids": ["adventurer_0", "adventurer_3"], "lv": 3},
		{"stage": "mourngate_1_2", "ids": ["adventurer_0", "adventurer_3"], "lv": 4},
		{"stage": "mourngate_1_3", "ids": ["adventurer_0", "adventurer_3", "adventurer_1"], "lv": 4},
		{"stage": "mourngate_1_3", "ids": ["adventurer_0", "adventurer_3", "adventurer_1"], "lv": 5},
		{"stage": "mourngate_1_4", "ids": ["adventurer_0", "adventurer_3", "adventurer_1", "adventurer_2"], "lv": 5},
		{"stage": "mourngate_1_4", "ids": ["adventurer_0", "adventurer_3", "adventurer_1", "adventurer_2"], "lv": 6},
		{"stage": "mourngate_1_5", "ids": ["adventurer_0", "adventurer_3", "adventurer_1", "adventurer_2"], "lv": 6},
		{"stage": "mourngate_1_5", "ids": ["adventurer_0", "adventurer_3", "adventurer_1", "adventurer_2"], "lv": 7},
	]
	for row: Dictionary in prog:
		_run_screen_cell("join-path", str(row["stage"]), row["ids"], int(row["lv"]))
	print("")
	print("── D) 1-1 ソロ職比較（Lv1 / Lv3）──")
	_print_screen_header()
	for starter: String in ["adventurer_0", "adventurer_3", "adventurer_1", "adventurer_2", "adventurer_4"]:
		_run_screen_cell("1-1 Lv1", "mourngate_1_1", [starter], 1)
		_run_screen_cell("1-1 Lv3", "mourngate_1_1", [starter], 3)
	print("")
	print("BALANCE_SCREEN: DONE")


func _print_screen_header() -> void:
	print("%-10s %-16s n Lv clear%% wipe%% hp%% avgActN" % ["tag", "stage"])


func _stage_recommended_level(stage_id: String) -> int:
	var stage: Resource = _dr().get_stage_data(stage_id)
	if stage != null and int(stage.recommended_level) > 0:
		return int(stage.recommended_level)
	return 1


func _run_screen_cell(tag: String, stage_id: String, ids: Array, level: int) -> void:
	_stage_id = stage_id
	_dungeon_id = "mourngate"
	_party_level = level
	_party_ids = PackedStringArray()
	for id_v: Variant in ids:
		_party_ids.append(str(id_v))
	_party_size = ids.size()
	_prepare_party()
	_apply_party_level()
	var stats: Dictionary = _simulate_all()
	var clears: int = int(stats["clears"])
	var wipes: int = int(stats["wipes"])
	var clear_pct: float = 100.0 * clears / _runs
	var wipe_pct: float = 100.0 * wipes / _runs
	var hp_pct: float = 0.0
	if clears > 0:
		hp_pct = 100.0 * float(stats["end_hp_ratio_sum"]) / clears
	var act_n: float = 0.0
	var arr: Array = stats["battle_actions"]["normal"]
	if not arr.is_empty():
		var total: int = 0
		for v: Variant in arr:
			total += int(v)
		act_n = float(total) / arr.size()
	print("%-10s %-16s %d %2d %6.1f %6.1f %5.1f %6.1f" % [
		tag, stage_id, ids.size(), level, clear_pct, wipe_pct, hp_pct, act_n
	])

func _apply_party_level() -> void:
	for member in _gs.roster:
		member.level = _party_level
		member.exp = 0
	_apply_gear_tier()

## --gear-atk/--gear-def/--gear-hp: 想定装備ティアを合成装備で再現する。
## 武器は初期装備の rolled_attack を上書き（属性/武器種は維持）、防具は合成インスタンスを装着。
func _apply_gear_tier() -> void:
	if _gear_atk < 0 and _gear_def < 0 and _gear_hp < 0:
		return
	var armor_class = load("res://scripts/domain/ArmorInstance.gd")
	for member in _gs.roster:
		if _gear_atk >= 0 and member.equipped_weapon != null:
			member.equipped_weapon.rolled_attack = _gear_atk
			member.equipped_weapon.enhance_level = 0
		if _gear_def >= 0 or _gear_hp >= 0:
			var armor = armor_class.new()
			armor.instance_id = "sim_armor_" + str(member.id)
			armor.armor_id = ""
			armor.rolled_defense = maxi(0, _gear_def)
			armor.hp_bonus = maxi(0, _gear_hp)
			armor.is_appraised = true
			member.equipped_armor = armor

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
		"skill_casts": 0,              # damage スキル使用回数
		"heal_casts": 0,               # heal スキル使用回数
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
	if not _stage_id.is_empty():
		dc.start_stage(_stage_id)
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

## 通常攻撃＋装備スキル①②の CT 駆動バトル（v2）。戻り値 {wiped, stalemate, actions}
func _simulate_battle(cc: Node, dc: Node, group: Array, stats: Dictionary) -> Dictionary:
	cc.start_combat_group(group, dc.get_enemy_level())
	var is_boss_room: bool = dc.current_room_type == _enums.RoomType.BOSS
	_apply_enemy_scale(cc, _boss_scale if is_boss_room else _enemy_scale)
	_battle_ct = 0.0
	_skill_ready_at.clear()
	var actions: int = 0
	while not cc.is_combat_cleared() and not cc.is_party_wiped():
		actions += 1
		if actions > BATTLE_ACTION_CAP:
			cc.end_combat()
			return {"wiped": false, "stalemate": true, "actions": actions}
		var actor: Dictionary = cc.advance_to_next_actor()
		if actor.is_empty():
			break
		_battle_ct += float(cc.consume_last_ct_step())
		if actor["kind"] == "party":
			_do_member_turn(cc, dc, int(actor["index"]), stats)
		else:
			_do_enemy_attack(cc, int(actor["index"]))
		cc.decay_threat()
	var wiped: bool = cc.is_party_wiped()
	cc.end_combat()
	return {"wiped": wiped, "stalemate": false, "actions": actions}

## --enemy-scale / --boss-scale: 敵 HP/ATK を一括倍率で調整（探索専用の what-if）。
func _apply_enemy_scale(cc: Node, scale: float) -> void:
	if is_equal_approx(scale, 1.0):
		return
	for i in cc.swarm_hp.size():
		cc.swarm_hp[i] = maxi(1, int(round(float(cc.swarm_hp[i]) * scale)))
		cc.swarm_max_hp[i] = maxi(1, int(round(float(cc.swarm_max_hp[i]) * scale)))
		cc.swarm_atk[i] = maxi(1, int(round(float(cc.swarm_atk[i]) * scale)))
	cc._sync_active_enemy()

## 1 行動: 回復スキル（味方負傷時）→ ダメージスキル → 通常攻撃 の優先で 1 手だけ。
func _do_member_turn(cc: Node, dc: Node, member_idx: int, stats: Dictionary) -> void:
	if not cc.is_member_alive(member_idx):
		return
	var skill: Resource = _pick_ready_skill(cc, member_idx)
	if skill != null:
		if str(skill.effect_type) == "heal":
			stats["heal_casts"] = int(stats["heal_casts"]) + 1
			_do_member_heal(cc, member_idx, skill)
			return
		stats["skill_casts"] = int(stats["skill_casts"]) + 1
		_do_member_attack(cc, dc, member_idx, stats, skill)
		return
	_do_member_attack(cc, dc, member_idx, stats)

## 装備スキル①②から使用可能な 1 つを選ぶ（heal は負傷者がいる時のみ・CD は battle CT 基準）。
func _pick_ready_skill(cc: Node, member_idx: int) -> Resource:
	var combatants: Array = _gs.get_combatants()
	if member_idx < 0 or member_idx >= combatants.size():
		return null
	var member: Resource = combatants[member_idx]
	if member == null:
		return null
	for sid in _gs.get_equipped_skill_ids(member):
		var skill_id: String = str(sid)
		if skill_id.is_empty():
			continue
		var skill: Resource = _dr().get_skill_data(skill_id)
		if skill == null:
			continue
		var effect: String = str(skill.effect_type)
		if effect != "damage" and effect != "heal":
			continue
		var key: String = "%d:%s" % [member_idx, skill_id]
		if _battle_ct < float(_skill_ready_at.get(key, 0.0)):
			continue
		if effect == "heal":
			var injured: int = cc.get_most_injured_member_index()
			if injured < 0:
				continue
			var ratio: float = float(cc.party_combat_hp[injured]) / maxf(1.0, float(cc.party_max_hp[injured]))
			if ratio >= HEAL_HP_THRESHOLD:
				continue
		_skill_ready_at[key] = _battle_ct + maxf(0.0, float(skill.cooldown))
		return skill
	return null

func _do_member_heal(cc: Node, member_idx: int, skill: Resource) -> void:
	var target: int = cc.get_most_injured_member_index()
	if target < 0:
		return
	var amount: int = int(round(float(skill.power_multiplier) * float(_balance.HEAL_SKILL_BASE)))
	amount = int(round(float(amount) * float(cc.get_party_role_heal_multiplier())))
	cc.heal_member(target, amount)

func _do_member_attack(
	cc: Node, dc: Node, member_idx: int, stats: Dictionary, skill: Resource = null
) -> void:
	if not cc.is_member_alive(member_idx):
		return
	var slot: int = cc.resolve_member_target(member_idx, "front")
	if not cc.is_enemy_slot_alive(slot):
		return
	var result: Dictionary = _dmg_calc.member_attack_damage(
		cc, dc.current_dungeon_data, dc.run_damage_multiplier, member_idx, slot
	)
	var dmg: int = int(result["damage"])
	# ダメージスキル: 通常攻撃値 × power_multiplier の近似（属性/軽減は上で反映済み）
	if skill != null and str(skill.effect_type) == "damage":
		dmg = maxi(1, int(round(float(dmg) * float(skill.power_multiplier))))
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

func _dr() -> Node:
	return get_root().get_node("DataRegistry")

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
	print("スキル使用  : 攻撃 %.1f 回/ラン ／ 回復 %.1f 回/ラン" % [
		float(stats["skill_casts"]) / _runs, float(stats["heal_casts"]) / _runs
	])
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
