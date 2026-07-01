class_name CombatController
extends Node

const BASE_MEMBER_HP: int = 30
const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")
const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")
const _StatusResolver = preload("res://scripts/combat/StatusResolver.gd")

var is_in_combat: bool = false
var current_enemy_data: Resource = null
var current_enemy_hp: int = 0
var last_exp_reward: int = 0
var last_gold_reward: int = 0

# 敵レベル（P3-D081）。start_combat で決定し、ダンジョン中は不変。
# Lv1＝tres 基準値。HP/ATK は乗算スケール、DEF は据置、EXP は別係数で増加。
const ENEMY_LEVEL_HP_K: float = 0.10
const ENEMY_LEVEL_ATK_K: float = 0.10
const ENEMY_LEVEL_EXP_K: float = 0.15
var enemy_level: int = 1
var _scaled_max_hp: int = 0
var _scaled_attack: int = 0
var _scaled_defense: int = 0
var _scaled_exp: int = 0

# 群れ（複数敵）状態（P3-D082/D110）。current_enemy_* / _scaled_* は常に「アクティブ（フォーカス）敵」を映す。
# 敵状態異常はスロット別 enemy_<i>（P3-D110）。味方はフォーカス1体を集中攻撃。
var swarm_data: Array[Resource] = []
var swarm_hp: Array[int] = []
var swarm_max_hp: Array[int] = []
var swarm_atk: Array[int] = []
var swarm_def: Array[int] = []
var swarm_exp: Array[int] = []
var enemy_phase_index: Array[int] = []
var active_enemy_index: int = 0
# メンバー個別の攻撃対象スロット（P3-D111）。member_target_slot[i]=敵 swarm インデックス。
var member_target_slot: Array[int] = []
# 装備スキル①②のローテーション開始位置（P3-D113）。戦闘中のみ保持。
var member_skill_rot_idx: Array[int] = []

# CT/ATB スケジューラ（P3-D084）。各生存ユニット（味方/群れ各敵）は個別の CT を持ち、
# CT が 0 になったユニットから 1 体ずつ行動する。速度（initiative_score）が大きいほど
# 行動 CT が短く、行動回数が増える（ラウンド制 P3-D083 を置換）。
const BASE_ACTION_CT: float = 2.0
const _CT_EPSILON: float = 0.0001
# 生存ユニットごとの残り CT（key = "party_<i>" / "enemy_<slot>"）
var unit_ct: Dictionary = {}
# 直近 advance_to_next_actor で進めた CT 量（呼出側の状態異常/スキルCD進行に使う）
var _last_ct_step: float = 0.0
# 詠唱中ペイロード（P3-D112）。key = "party_<i>" / "enemy_<slot>"。
var _pending_casts: Dictionary = {}

var party_combat_hp: Array[int] = []
var party_max_hp: Array[int] = []
var _status_resolver: RefCounted = _StatusResolver.new()

# ── Threat / Aggro 基盤（P3-D104・ロードマップ フェーズA-2）──
# 敵は最大 Threat のメンバーを狙う。Threat は被ダメ肩代わり・与ダメ・挑発で増え、毎tick減衰。
var party_threat: Array[float] = []
const THREAT_DAMAGE_K: float = 0.10   # 与ダメ1あたりの加算
const THREAT_TAKEN_K: float = 0.15    # 被ダメ1あたりの加算（タンクが矢面で稼ぐ）
const THREAT_TAUNT: float = 40.0      # 挑発（防御スロット）スパイク
const THREAT_DECAY: float = 0.90      # status tick ごとの減衰率（基礎値へ寄せる）
const MELEE_ATTACK_RANGE_MAX: float = 2.5  # これ以下＝前列優先ターゲット（P3-D106d）

# ジョブ別の基礎 Threat 重み（タンクが引きやすい）。
func _job_threat_base(member_index: int) -> float:
	var c: Resource = GameState.get_combatant(member_index)
	if c == null:
		return 1.0
	var base: float = 1.0
	match str(c.job_id):
		"vanguard": base = 4.0
		"swordsman": base = 2.0
		_: base = 1.0
	# 陣形（後列は狙われにくい）（P3-D106）
	return base * GameState.formation_threat_multiplier(member_index)

func start_combat(enemy_data: Resource, level: int = 1) -> void:
	start_combat_group([enemy_data], level)

# 群れ対応の戦闘開始（P3-D082）。単体は要素1の配列として扱う。
func start_combat_group(enemies: Array, level: int = 1) -> void:
	is_in_combat = true
	enemy_level = maxi(1, level)
	var lf: float = float(enemy_level - 1)
	swarm_data.clear()
	swarm_hp.clear()
	swarm_max_hp.clear()
	swarm_atk.clear()
	swarm_def.clear()
	swarm_exp.clear()
	enemy_phase_index.clear()
	for e in enemies:
		if e == null:
			continue
		var hp: int = maxi(1, int(round(float(e.max_hp) * (1.0 + ENEMY_LEVEL_HP_K * lf))))
		var atk: int = maxi(1, int(round(float(e.attack) * (1.0 + ENEMY_LEVEL_ATK_K * lf))))
		var df: int = maxi(0, int(e.defense))
		var xp: int = maxi(0, int(round(float(e.exp_reward) * (1.0 + ENEMY_LEVEL_EXP_K * lf))))
		swarm_data.append(e)
		swarm_hp.append(hp)
		swarm_max_hp.append(hp)
		swarm_atk.append(atk)
		swarm_def.append(df)
		swarm_exp.append(xp)
		enemy_phase_index.append(0)
		GameState.mark_enemy_seen(e.id)
	active_enemy_index = 0
	_sync_active_enemy()
	last_exp_reward = 0
	last_gold_reward = 0
	_init_party_hp()
	_init_member_targets()
	_init_member_skill_rotation()
	init_ct()

# current_enemy_* / _scaled_* をアクティブ敵スロットに同期する。
func _sync_active_enemy() -> void:
	if active_enemy_index < 0 or active_enemy_index >= swarm_data.size():
		current_enemy_data = null
		current_enemy_hp = 0
		_scaled_max_hp = 0
		_scaled_attack = 0
		_scaled_defense = 0
		_scaled_exp = 0
		return
	current_enemy_data = swarm_data[active_enemy_index]
	current_enemy_hp = swarm_hp[active_enemy_index]
	_scaled_max_hp = swarm_max_hp[active_enemy_index]
	_scaled_attack = swarm_atk[active_enemy_index]
	_scaled_defense = swarm_def[active_enemy_index]
	_scaled_exp = swarm_exp[active_enemy_index]

func swarm_count() -> int:
	return swarm_data.size()

func is_enemy_slot_alive(i: int) -> bool:
	return i >= 0 and i < swarm_hp.size() and swarm_hp[i] > 0

func get_living_enemy_indices() -> Array[int]:
	var out: Array[int] = []
	for i in swarm_hp.size():
		if swarm_hp[i] > 0:
			out.append(i)
	return out

func living_enemy_count() -> int:
	return get_living_enemy_indices().size()

# 群れ全滅（戦闘クリア）判定。
func is_combat_cleared() -> bool:
	return is_in_combat and living_enemy_count() == 0

func get_enemy_attack_at(i: int) -> int:
	if i >= 0 and i < swarm_atk.size():
		return swarm_atk[i]
	return _scaled_attack

func get_enemy_defense_at(i: int) -> int:
	if i >= 0 and i < swarm_def.size():
		return swarm_def[i]
	return _scaled_defense

func get_enemy_max_hp_at(i: int) -> int:
	if i >= 0 and i < swarm_max_hp.size():
		return swarm_max_hp[i]
	return _scaled_max_hp

func get_enemy_hp_at(i: int) -> int:
	if i >= 0 and i < swarm_hp.size():
		return swarm_hp[i]
	return current_enemy_hp

func get_enemy_data_at(i: int) -> Resource:
	if i >= 0 and i < swarm_data.size():
		return swarm_data[i]
	return current_enemy_data

# 敵スロット別 StatusResolver ユニット id（P3-D110）。CT の enemy_<slot> と整合。
func enemy_status_unit_id(slot: int) -> String:
	return "enemy_%d" % slot

func get_active_enemy_status_unit_id() -> String:
	return enemy_status_unit_id(active_enemy_index)

# アクティブ敵を次の生存スロットへ繰り上げる（撃破スロットの状態は呼び出し側でクリア）。
func advance_active_enemy() -> int:
	for i in swarm_hp.size():
		if swarm_hp[i] > 0:
			active_enemy_index = i
			_sync_active_enemy()
			return i
	active_enemy_index = -1
	_sync_active_enemy()
	return -1

func clear_enemy_slot_status(slot: int) -> void:
	if slot < 0:
		return
	_status_resolver.clear_unit(enemy_status_unit_id(slot))

func _init_member_targets() -> void:
	member_target_slot.clear()
	for i in party_combat_hp.size():
		member_target_slot.append(0)

func _init_member_skill_rotation() -> void:
	member_skill_rot_idx.clear()
	for i in party_combat_hp.size():
		member_skill_rot_idx.append(0)

func get_skill_rotation_index(member_index: int) -> int:
	if member_index < 0 or member_index >= member_skill_rot_idx.size():
		return 0
	return member_skill_rot_idx[member_index]

func set_skill_rotation_after_cast(member_index: int, used_index: int, slot_count: int) -> void:
	if member_index < 0 or member_index >= member_skill_rot_idx.size() or slot_count <= 0:
		return
	member_skill_rot_idx[member_index] = (used_index + 1) % slot_count

func get_member_target_slot(member_index: int) -> int:
	if member_index < 0 or member_index >= member_target_slot.size():
		return active_enemy_index
	var slot: int = member_target_slot[member_index]
	if is_enemy_slot_alive(slot):
		return slot
	return pick_enemy_slot_by_rule(CombatTactics.DEFAULT_TARGET)

# 生存敵から target ルールで1体選ぶ（P3-D100/D111）。
func pick_enemy_slot_by_rule(rule: String) -> int:
	var living: Array[int] = get_living_enemy_indices()
	if living.is_empty():
		return -1
	if living.size() == 1:
		return living[0]
	var best: int = living[0]
	match rule:
		"lowest_hp":
			for i: int in living:
				if swarm_hp[i] < swarm_hp[best]:
					best = i
		"highest_hp":
			for i: int in living:
				if swarm_hp[i] > swarm_hp[best]:
					best = i
		"highest_atk":
			for i: int in living:
				if swarm_atk[i] > swarm_atk[best]:
					best = i
		"enemy_with_status":
			var with_status: Array[int] = []
			for i: int in living:
				if not get_enemy_status_list_at(i).is_empty():
					with_status.append(i)
			if with_status.is_empty():
				return living[0]
			best = with_status[0]
			for i: int in with_status:
				if swarm_hp[i] < swarm_hp[best]:
					best = i
		"back":
			return living[living.size() - 1]
		_:
			best = living[0]
	return best

# メンバー戦術の target ルールで狙いを決定し member_target_slot に保存する。
func resolve_member_target(member_index: int, rule: String) -> int:
	var slot: int = pick_enemy_slot_by_rule(rule)
	if member_index >= 0 and member_index < member_target_slot.size():
		member_target_slot[member_index] = slot
	return slot

# パーティ・フォーカス対象を target ルールで選び、アクティブ敵に設定する（P3-D100）。
# 単一アクティブ＝味方はフォーカス1体を集中攻撃。敵別状態スロット（P3-D110）で個体ごとに状態保持。
# rule: "front" | "lowest_hp" | "highest_hp" | "highest_atk"
func set_focus_by_rule(rule: String) -> int:
	var best: int = pick_enemy_slot_by_rule(rule)
	if best < 0:
		return active_enemy_index
	if best != active_enemy_index:
		active_enemy_index = best
		_sync_active_enemy()
	return active_enemy_index

func get_enemy_max_hp() -> int:
	return _scaled_max_hp

func get_enemy_attack() -> int:
	return _scaled_attack

func get_enemy_defense() -> int:
	return _scaled_defense

func end_combat() -> void:
	is_in_combat = false
	current_enemy_data = null
	current_enemy_hp = 0
	enemy_level = 1
	_scaled_max_hp = 0
	_scaled_attack = 0
	_scaled_defense = 0
	_scaled_exp = 0
	swarm_data.clear()
	swarm_hp.clear()
	swarm_max_hp.clear()
	swarm_atk.clear()
	swarm_def.clear()
	swarm_exp.clear()
	enemy_phase_index.clear()
	active_enemy_index = 0
	member_target_slot.clear()
	member_skill_rot_idx.clear()
	unit_ct.clear()
	_last_ct_step = 0.0
	_pending_casts.clear()
	_status_resolver.clear_all()

func _init_party_hp() -> void:
	party_combat_hp.clear()
	party_max_hp.clear()
	party_threat.clear()
	var combatants: Array = GameState.get_combatants()
	for i in combatants.size():
		var member: Resource = combatants[i]
		var max_hp: int = BASE_MEMBER_HP
		if member.base_stats != null and member.base_stats.hp > 0:
			max_hp = member.base_stats.hp
		var armor: Resource = member.equipped_armor
		if armor != null:
			max_hp += armor.hp_bonus
		var acc: Resource = member.equipped_accessory
		if acc != null:
			var acc_data: Resource = load("res://resources/accessories/" + acc.accessory_id + ".tres")
			if acc_data != null:
				max_hp += acc_data.hp_bonus
		# 助っ人は Affix ボーナスとレベル HP をスキップ（装備なし・EXP対象外）
		if not GameState.is_helper_combatant(i):
			var affix_bonuses: Dictionary = _AffixStatCalculator.get_bonuses(i)
			max_hp += int(affix_bonuses.get("hp_flat", 0))
			max_hp += LevelSystem.level_hp_bonus(member.level)
		var job_mods: Dictionary = _JobStatCalculator.get_member_modifiers(member)
		var hp_mult: float = float(job_mods.get("hp_multiplier", _JobStatCalculator.DEFAULT_MULTIPLIER))
		max_hp = maxi(1, int(round(float(max_hp) * hp_mult)))
		party_combat_hp.append(max_hp)
		party_max_hp.append(max_hp)
		party_threat.append(_job_threat_base(i))
		print(
			"[JobCombat] HP member=%s job=%s mult=%.2f max_hp=%d"
			% [member.display_name, job_mods.get("job_id", ""), hp_mult, max_hp]
		)

func is_member_alive(index: int) -> bool:
	if index < 0 or index >= party_combat_hp.size():
		return false
	return party_combat_hp[index] > 0

func get_alive_count() -> int:
	var count: int = 0
	for hp in party_combat_hp:
		if hp > 0:
			count += 1
	return count

func is_party_wiped() -> bool:
	# 助っ人のみ生存ではラン継続しない。メイン編成3人が全滅で判定。
	var main_count: int = GameState.party_members.size()
	for i in mini(main_count, party_combat_hp.size()):
		if party_combat_hp[i] > 0:
			return false
	return true

func apply_damage_to_enemy(amount: int) -> void:
	if not is_in_combat:
		return
	if active_enemy_index >= 0 and active_enemy_index < swarm_hp.size():
		swarm_hp[active_enemy_index] = max(0, swarm_hp[active_enemy_index] - amount)
		current_enemy_hp = swarm_hp[active_enemy_index]
	else:
		current_enemy_hp = max(0, current_enemy_hp - amount)

func apply_damage_to_member(index: int, amount: int) -> void:
	if index < 0 or index >= party_combat_hp.size():
		return
	party_combat_hp[index] = max(0, party_combat_hp[index] - amount)

func is_enemy_slot_defeated(slot: int) -> bool:
	return is_in_combat and not is_enemy_slot_alive(slot)

func is_enemy_defeated() -> bool:
	return is_enemy_slot_defeated(active_enemy_index)

func heal_party(amount: int) -> void:
	if party_combat_hp.is_empty():
		_init_party_hp()
	for i in party_combat_hp.size():
		if party_combat_hp[i] > 0:
			party_combat_hp[i] = min(party_combat_hp[i] + amount, party_max_hp[i])

## 指定メンバーを回復し、実際に回復した量を返す（死亡者は蘇生しない／上限クランプ）。
func heal_member(index: int, amount: int) -> int:
	if index < 0 or index >= party_combat_hp.size():
		return 0
	if party_combat_hp[index] <= 0:
		return 0
	var before: int = party_combat_hp[index]
	party_combat_hp[index] = min(before + amount, party_max_hp[index])
	return party_combat_hp[index] - before

## 最も負傷している生存メンバーのindexを返す（負傷者なしは -1）。
func get_most_injured_member_index() -> int:
	var best: int = -1
	var best_deficit: int = 0
	for i in party_combat_hp.size():
		if party_combat_hp[i] <= 0:
			continue
		var deficit: int = party_max_hp[i] - party_combat_hp[i]
		if deficit > best_deficit:
			best_deficit = deficit
			best = i
	return best

func pick_enemy_target_member_index() -> int:
	return pick_enemy_target_from_indices(_eligible_enemy_targets(false, false))

# 近接敵の通常攻撃用。前列 Threat 最大を優先し、前列全滅時は後列へ（P3-D106d）。
func pick_enemy_target_for_melee_attack(attacker_slot: int = -1) -> int:
	if _is_enemy_ranged_at(attacker_slot):
		return pick_enemy_target_member_index()
	var front: Array[int] = _eligible_enemy_targets(true, false)
	if not front.is_empty():
		return pick_enemy_target_from_indices(front)
	var back: Array[int] = _eligible_enemy_targets(false, true)
	return pick_enemy_target_from_indices(back)

func get_member_threat(member_index: int) -> float:
	return _threat_of(member_index)

func _is_enemy_ranged_at(slot: int) -> bool:
	var data: Resource = get_enemy_data_at(slot) if slot >= 0 else current_enemy_data
	if data == null:
		return false
	return float(data.attack_range) > MELEE_ATTACK_RANGE_MAX

func _eligible_enemy_targets(front_only: bool, back_only: bool) -> Array[int]:
	var alive: Array[int] = []
	for i in party_combat_hp.size():
		if not is_member_alive(i) or GameState.is_helper_combatant(i):
			continue
		var back: bool = GameState.is_member_back_row(i)
		if front_only and back:
			continue
		if back_only and not back:
			continue
		alive.append(i)
	return alive

func pick_enemy_target_from_indices(indices: Array[int]) -> int:
	if indices.is_empty():
		return -1
	var best: int = indices[0]
	for i in indices:
		if _threat_of(i) > _threat_of(best):
			best = i
		elif is_equal_approx(_threat_of(i), _threat_of(best)) and i < best:
			best = i
	return best

func _threat_of(member_index: int) -> float:
	if member_index < 0 or member_index >= party_threat.size():
		return 0.0
	return party_threat[member_index]

# Threat を加算（P3-D104）。member が範囲外なら無視。
func add_threat(member_index: int, amount: float) -> void:
	if member_index < 0 or member_index >= party_threat.size():
		return
	party_threat[member_index] = maxf(0.0, party_threat[member_index] + amount)

# 挑発（防御スロット等）。当該メンバーへ大きな Threat スパイクを与え矢面に立たせる。
func apply_taunt(member_index: int) -> void:
	add_threat(member_index, THREAT_TAUNT)

# status tick ごとに Threat を基礎値へ向けて減衰させる（挑発が時間で薄れる）。
func decay_threat() -> void:
	for i in party_threat.size():
		var base: float = _job_threat_base(i)
		party_threat[i] = base + (party_threat[i] - base) * THREAT_DECAY

func capture_rewards() -> void:
	capture_rewards_at(active_enemy_index)

func capture_rewards_at(slot: int) -> void:
	var data: Resource = get_enemy_data_at(slot)
	if data == null:
		return
	last_exp_reward = swarm_exp[slot] if slot >= 0 and slot < swarm_exp.size() else _scaled_exp
	last_gold_reward = data.gold_reward

func apply_status(
	unit_id: String,
	effect_id: String,
	stacks: int = 1,
	source_attack: int = 0
) -> bool:
	return _status_resolver.apply_status(unit_id, effect_id, stacks, source_attack)

func apply_status_to_active_enemy(
	effect_id: String,
	stacks: int = 1,
	source_attack: int = 0
) -> bool:
	return apply_status(get_active_enemy_status_unit_id(), effect_id, stacks, source_attack)

func apply_status_to_enemy_slot(
	slot: int,
	effect_id: String,
	stacks: int = 1,
	source_attack: int = 0
) -> bool:
	return apply_status(enemy_status_unit_id(slot), effect_id, stacks, source_attack)

func apply_damage_to_enemy_slot(slot: int, amount: int) -> void:
	if not is_in_combat:
		return
	if slot < 0 or slot >= swarm_hp.size():
		return
	swarm_hp[slot] = max(0, swarm_hp[slot] - amount)
	if slot == active_enemy_index:
		current_enemy_hp = swarm_hp[slot]

func get_enemy_id_at(slot: int) -> String:
	if slot < 0 or slot >= swarm_data.size():
		return ""
	var data: Resource = swarm_data[slot]
	if data == null:
		return ""
	return str(data.id)

func get_enemy_hp_ratio_at(slot: int) -> float:
	if slot < 0 or slot >= swarm_max_hp.size():
		return 1.0
	var maxhp: int = swarm_max_hp[slot]
	if maxhp <= 0:
		return 0.0
	return float(swarm_hp[slot]) / float(maxhp)

func get_enemy_phase_index(slot: int) -> int:
	if slot < 0 or slot >= enemy_phase_index.size():
		return 0
	return enemy_phase_index[slot]

func set_enemy_phase_index(slot: int, phase_index: int) -> void:
	if slot >= 0 and slot < enemy_phase_index.size():
		enemy_phase_index[slot] = maxi(0, phase_index)

func tick_all_statuses() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for slot in swarm_hp.size():
		if is_enemy_slot_alive(slot):
			results.append_array(_status_resolver.tick_unit(enemy_status_unit_id(slot)))
	for i in party_combat_hp.size():
		results.append_array(_status_resolver.tick_unit("party_%d" % i))
	return results

func should_enemy_skip_action_at(slot: int) -> bool:
	return _status_resolver.should_skip_action(enemy_status_unit_id(slot))

func should_enemy_skip_action() -> bool:
	return should_enemy_skip_action_at(active_enemy_index)

func get_enemy_skip_action_label_at(slot: int) -> String:
	return _status_resolver.get_skip_action_label(enemy_status_unit_id(slot))

func get_enemy_skip_action_label() -> String:
	return get_enemy_skip_action_label_at(active_enemy_index)

# メンバーの遺物効果倍率（P3-D090）。メイン編成のみ（助っ人は遺物なし）。
func _member_relic_effects(member_index: int) -> Dictionary:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return CombatRelics.effects_for(CombatRelics.NONE_ID)
	var member: Resource = GameState.party_members[member_index]
	var rid: String = ""
	if member != null and "relic_id" in member:
		rid = str(member.relic_id)
	var eff: Dictionary = CombatRelics.effects_for(rid)
	# 王国軍旗＝前列限定の与ダメ+10%（P3-D106）。後列では outgoing ボーナスを無効化。
	if rid == "war_banner" and GameState.is_member_back_row(member_index):
		eff = eff.duplicate()
		eff["outgoing_mult"] = 1.0
	return eff

func get_member_outgoing_damage_multiplier(member_index: int, action_range: String = "") -> float:
	var mult: float = _status_resolver.get_outgoing_damage_multiplier("party_%d" % member_index)
	mult *= float(_member_relic_effects(member_index).get("outgoing_mult", 1.0))
	# 物理タグシナジー＋ロール（攻勢）ボーナス（P3-D097・party 全体）
	mult *= 1.0 + CombatSynergy.compute_physical_bonus(GameState.party_members)
	mult *= float(CombatSynergy.compute_role_bonuses(GameState.party_members).get("outgoing_mult", 1.0))
	# 陣形×射程の与ダメ補正（P3-D106b）
	if not action_range.is_empty():
		mult *= GameState.formation_range_outgoing_multiplier(member_index, action_range)
	return mult

# 被ダメ補正（防御=guard 等）。1.0=等倍。P3-D085 で配線。遺物 incoming_mult も乗算（P3-D090）。
func get_member_incoming_damage_multiplier(member_index: int) -> float:
	var mult: float = _status_resolver.get_incoming_damage_multiplier("party_%d" % member_index)
	mult *= float(_member_relic_effects(member_index).get("incoming_mult", 1.0))
	# ロール（堅守）ボーナス（P3-D097・party 全体）
	mult *= float(CombatSynergy.compute_role_bonuses(GameState.party_members).get("incoming_mult", 1.0))
	# 探索方針（安全優先）被ダメ軽減（P3-D098）
	mult *= GameState.exploration_incoming_multiplier()
	# 天候（霧＝被ダメ軽減）（P3-D101）
	mult *= CombatWeather.incoming_multiplier(GameState.get_weather())
	# 陣形（後列＝被ダメ軽減）（P3-D106）
	mult *= GameState.formation_incoming_multiplier(member_index)
	# 散開/密集（同列人数・P3-D106e）
	mult *= CombatFormation.density_incoming_multiplier(
		member_index, party_combat_hp.size(), Callable(self, "is_member_alive")
	)
	return mult

func get_density_log_tag(member_index: int) -> String:
	return CombatFormation.density_log_tag(
		member_index, party_combat_hp.size(), Callable(self, "is_member_alive")
	)

# ロール編成ボーナス（P3-D097）。回復量倍率 / 会心率加算。
func get_party_role_heal_multiplier() -> float:
	return float(CombatSynergy.compute_role_bonuses(GameState.party_members).get("heal_mult", 1.0))

func get_party_role_crit_add() -> float:
	return float(CombatSynergy.compute_role_bonuses(GameState.party_members).get("crit_add", 0.0))

func get_enemy_incoming_damage_multiplier() -> float:
	return get_enemy_incoming_damage_multiplier_at(active_enemy_index)

func get_enemy_incoming_damage_multiplier_at(slot: int) -> float:
	return _status_resolver.get_incoming_damage_multiplier(enemy_status_unit_id(slot))

# アクティブ敵の DEF 減少率（armor_break・P3-D107）。0.0=なし。
func get_enemy_defense_reduction() -> float:
	return get_enemy_defense_reduction_at(active_enemy_index)

func get_enemy_defense_reduction_at(slot: int) -> float:
	return _status_resolver.get_defense_reduction(enemy_status_unit_id(slot))

# 同系統タグ・シナジー（P3-D095）。指定属性をパーティで複数人が共有する時の与ダメボーナス（0.0=なし）。
func get_element_synergy_bonus(element: String) -> float:
	if element.is_empty():
		return 0.0
	return float(CombatSynergy.compute_element_bonuses(GameState.party_members).get(element, 0.0))

func get_enemy_status_stacks(effect_id: String) -> int:
	return get_enemy_status_stacks_at(active_enemy_index, effect_id)

func get_enemy_status_stacks_at(slot: int, effect_id: String) -> int:
	return _status_resolver.get_status_stacks(enemy_status_unit_id(slot), effect_id)

# 状態異常コンボ起爆: アクティブ敵の指定状態を消費しスタック数を返す（P3-D089）。
func consume_enemy_status(effect_id: String) -> int:
	return consume_enemy_status_at(active_enemy_index, effect_id)

func consume_enemy_status_at(slot: int, effect_id: String) -> int:
	return _status_resolver.consume_status(enemy_status_unit_id(slot), effect_id)

func get_enemy_outgoing_damage_multiplier() -> float:
	return get_enemy_outgoing_damage_multiplier_at(active_enemy_index)

func get_enemy_outgoing_damage_multiplier_at(slot: int) -> float:
	return _status_resolver.get_outgoing_damage_multiplier(enemy_status_unit_id(slot))

func get_enemy_status_summary() -> String:
	return get_enemy_status_summary_at(active_enemy_index)

func get_enemy_status_summary_at(slot: int) -> String:
	return _status_resolver.get_active_status_summary(enemy_status_unit_id(slot))

func get_enemy_status_list() -> Array[Dictionary]:
	return get_enemy_status_list_at(active_enemy_index)

func get_enemy_status_list_at(slot: int) -> Array[Dictionary]:
	return _status_resolver.get_active_status_list(enemy_status_unit_id(slot))

func get_member_status_stacks(member_index: int, effect_id: String) -> int:
	return _status_resolver.get_status_stacks("party_%d" % member_index, effect_id)

# 味方コンボ起爆: メンバー自身の指定状態を消費（P3-D109）。
func consume_member_status(member_index: int, effect_id: String) -> int:
	return _status_resolver.consume_status("party_%d" % member_index, effect_id)

func get_member_status_summary(member_index: int) -> String:
	return _status_resolver.get_active_status_summary("party_%d" % member_index)

func get_member_status_list(member_index: int) -> Array[Dictionary]:
	return _status_resolver.get_active_status_list("party_%d" % member_index)

# ---- Initiative (P3-D019 Phase 1 + Phase 2) ----

# 単体メンバーのイニシアチブ（武器attack_speed×ジョブ補正×Affix）。死亡は 0。
func get_member_initiative_score(i: int) -> float:
	if not is_member_alive(i):
		return 0.0
	var spd: float = 1.0
	var weapon_inst: Resource = GameState.get_member_equipped_weapon(i)
	if weapon_inst != null and not weapon_inst.weapon_id.is_empty() and weapon_inst.attack_speed > 0.0:
		spd = weapon_inst.attack_speed
	var job_mod: float = 1.0
	if i < GameState.party_members.size():
		var member: Resource = GameState.party_members[i]
		if member != null and not member.job_id.is_empty():
			var job_data: Resource = DataRegistry.get_job_data(member.job_id)
			if job_data != null and job_data.base_initiative_modifier > 0.0:
				job_mod = job_data.base_initiative_modifier
	var affix_mult: float = float(_AffixStatCalculator.get_bonuses(i).get("attack_speed_mult_add", 0.0))
	var relic_speed: float = float(_member_relic_effects(i).get("speed_mult", 1.0))
	return spd * job_mod * (1.0 + affix_mult) * relic_speed

func get_party_initiative_score() -> float:
	var best: float = 0.0
	for i in party_combat_hp.size():
		best = maxf(best, get_member_initiative_score(i))
	return best if best > 0.0 else 1.0

func get_enemy_initiative_score() -> float:
	if current_enemy_data == null:
		return 1.0
	return current_enemy_data.attack_speed if current_enemy_data.attack_speed > 0.0 else 1.0

# 敵スロット別イニシアチブ（attack_speed）。
func get_enemy_initiative_score_at(slot: int) -> float:
	var d: Resource = get_enemy_data_at(slot)
	if d == null:
		return 1.0
	return d.attack_speed if d.attack_speed > 0.0 else 1.0

# ---- CT/ATB スケジューラ（P3-D084） ----

func _ct_unit_key(kind: String, index: int) -> String:
	return "%s_%d" % [kind, index]

func _ct_parse_key(key: String) -> Dictionary:
	var sep: int = key.rfind("_")
	return {"kind": key.substr(0, sep), "index": int(key.substr(sep + 1))}

# ユニットの行動 CT。速度（initiative_score）が速いほど短い＝多く動ける。
func get_unit_action_ct(kind: String, index: int) -> float:
	var spd: float = 1.0
	if kind == "party":
		spd = get_member_initiative_score(index)
	else:
		spd = get_enemy_initiative_score_at(index)
	if spd <= 0.0:
		spd = 1.0
	return BASE_ACTION_CT / spd

# 現在の生存ユニット一覧（味方→群れ敵の順）。各要素: {"kind","index"}。
func get_living_units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in party_combat_hp.size():
		if is_member_alive(i):
			out.append({"kind": "party", "index": i})
	for slot in swarm_hp.size():
		if is_enemy_slot_alive(slot):
			out.append({"kind": "enemy", "index": slot})
	return out

# 戦闘開始時に全生存ユニットの CT を初期化（満タン＝1回分）。
func init_ct() -> void:
	unit_ct.clear()
	for u in get_living_units():
		unit_ct[_ct_unit_key(u["kind"], u["index"])] = get_unit_action_ct(u["kind"], u["index"])
	_last_ct_step = 0.0

# unit_ct のキー集合を現在の生存ユニットへ同期（新規=満タン追加 / 死亡=除去）。
func _sync_ct_units() -> void:
	var living: Dictionary = {}
	for u in get_living_units():
		var key: String = _ct_unit_key(u["kind"], u["index"])
		living[key] = true
		if not unit_ct.has(key):
			unit_ct[key] = get_unit_action_ct(u["kind"], u["index"])
	for key in unit_ct.keys():
		if not living.has(key):
			unit_ct.erase(key)

# 次に行動するユニットへクロックを進める。{"kind","index"} を返す（生存ユニット無し={}）。
# 全ユニットの CT を最小残量ぶん減算し、0 に達したユニットを選ぶ（同時0は味方優先→index昇順）。
func advance_to_next_actor() -> Dictionary:
	_sync_ct_units()
	if unit_ct.is_empty():
		_last_ct_step = 0.0
		return {}
	var min_rem: float = INF
	for key in unit_ct:
		min_rem = minf(min_rem, unit_ct[key])
	if min_rem < 0.0:
		min_rem = 0.0
	for key in unit_ct:
		unit_ct[key] -= min_rem
	_last_ct_step = min_rem
	var ready: Array[Dictionary] = []
	for key in unit_ct:
		if unit_ct[key] <= _CT_EPSILON:
			var info: Dictionary = _ct_parse_key(key)
			ready.append({"key": key, "kind": info["kind"], "index": info["index"]})
	ready.sort_custom(func(a, b):
		if a["kind"] != b["kind"]:
			return a["kind"] == "party"
		return a["index"] < b["index"])
	var chosen: Dictionary = ready[0]
	unit_ct[chosen["key"]] = get_unit_action_ct(chosen["kind"], chosen["index"])
	return {"kind": chosen["kind"], "index": chosen["index"]}

# 直近 advance_to_next_actor で進めた CT 量。
func consume_last_ct_step() -> float:
	return _last_ct_step

# CT 残量の昇順（次に動く順）でユニットを返す。CT 表示UI用。
# 各要素: {"kind","index","ct"}。同値は味方優先→index 昇順。
func get_ct_order() -> Array[Dictionary]:
	_sync_ct_units()
	var entries: Array[Dictionary] = []
	for key in unit_ct:
		var info: Dictionary = _ct_parse_key(key)
		entries.append({"kind": info["kind"], "index": info["index"], "ct": float(unit_ct[key])})
	entries.sort_custom(func(a, b):
		if not is_equal_approx(a["ct"], b["ct"]):
			return a["ct"] < b["ct"]
		if a["kind"] != b["kind"]:
			return a["kind"] == "party"
		return a["index"] < b["index"])
	return entries

# ── 詠唱 / Action Lock（P3-D112）──

func _cast_unit_key(kind: String, index: int) -> String:
	return "%s_%d" % [kind, index]

func has_pending_cast(kind: String, index: int) -> bool:
	return _pending_casts.has(_cast_unit_key(kind, index))

func get_pending_cast(kind: String, index: int) -> Dictionary:
	var key: String = _cast_unit_key(kind, index)
	if not _pending_casts.has(key):
		return {}
	return _pending_casts[key].duplicate()

func begin_party_cast(member_index: int, skill_id: String, target_slot: int, turns_left: int) -> void:
	_pending_casts[_cast_unit_key("party", member_index)] = {
		"skill_id": skill_id,
		"target_slot": target_slot,
		"turns_left": maxi(1, turns_left),
	}

func begin_enemy_cast(slot: int, skill_id: String, turns_left: int) -> void:
	_pending_casts[_cast_unit_key("enemy", slot)] = {
		"skill_id": skill_id,
		"turns_left": maxi(1, turns_left),
	}

# 詠唱を1段進める。戻り値: "chant"（継続）/ "ready"（発動可）/ "none"
func advance_pending_cast(kind: String, index: int) -> String:
	var key: String = _cast_unit_key(kind, index)
	if not _pending_casts.has(key):
		return "none"
	var pending: Dictionary = _pending_casts[key]
	var left: int = int(pending.get("turns_left", 0))
	if left > 0:
		pending["turns_left"] = left - 1
		_pending_casts[key] = pending
		return "chant"
	return "ready"

func clear_pending_cast(kind: String, index: int) -> void:
	_pending_casts.erase(_cast_unit_key(kind, index))

func clear_pending_casts_for_kind(kind: String) -> void:
	var prefix: String = "%s_" % kind
	for key in _pending_casts.keys():
		if str(key).begins_with(prefix):
			_pending_casts.erase(key)
