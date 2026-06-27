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

var party_combat_hp: Array[int] = []
var party_max_hp: Array[int] = []
var _status_resolver: RefCounted = _StatusResolver.new()

func start_combat(enemy_data: Resource) -> void:
	is_in_combat = true
	current_enemy_data = enemy_data
	current_enemy_hp = enemy_data.max_hp
	last_exp_reward = 0
	last_gold_reward = 0
	GameState.mark_enemy_seen(enemy_data.id)
	_init_party_hp()

func end_combat() -> void:
	is_in_combat = false
	current_enemy_data = null
	current_enemy_hp = 0
	_status_resolver.clear_all()

func _init_party_hp() -> void:
	party_combat_hp.clear()
	party_max_hp.clear()
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
	current_enemy_hp = max(0, current_enemy_hp - amount)

func apply_damage_to_member(index: int, amount: int) -> void:
	if index < 0 or index >= party_combat_hp.size():
		return
	party_combat_hp[index] = max(0, party_combat_hp[index] - amount)

func is_enemy_defeated() -> bool:
	return is_in_combat and current_enemy_hp <= 0

func heal_party(amount: int) -> void:
	if party_combat_hp.is_empty():
		_init_party_hp()
	for i in party_combat_hp.size():
		if party_combat_hp[i] > 0:
			party_combat_hp[i] = min(party_combat_hp[i] + amount, party_max_hp[i])

func pick_enemy_target_member_index() -> int:
	var alive: Array[int] = []
	for i in party_combat_hp.size():
		if is_member_alive(i):
			alive.append(i)
	if alive.is_empty():
		return -1
	for tag in ["vanguard", "swordsman"]:
		for i in alive:
			if GameState.is_helper_combatant(i):
				continue
			var c: Resource = GameState.get_combatant(i)
			if c != null and c.job_id == tag:
				return i
	return alive[randi() % alive.size()]

func capture_rewards() -> void:
	if current_enemy_data == null:
		return
	last_exp_reward = current_enemy_data.exp_reward
	last_gold_reward = current_enemy_data.gold_reward

func apply_status(
	unit_id: String,
	effect_id: String,
	stacks: int = 1,
	source_attack: int = 0
) -> bool:
	return _status_resolver.apply_status(unit_id, effect_id, stacks, source_attack)

func tick_all_statuses() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	results.append_array(_status_resolver.tick_unit("enemy"))
	for i in party_combat_hp.size():
		results.append_array(_status_resolver.tick_unit("party_%d" % i))
	return results

func should_enemy_skip_action() -> bool:
	return _status_resolver.should_skip_action("enemy")

func get_enemy_skip_action_label() -> String:
	return _status_resolver.get_skip_action_label("enemy")

func get_member_outgoing_damage_multiplier(member_index: int) -> float:
	return _status_resolver.get_outgoing_damage_multiplier("party_%d" % member_index)

func get_enemy_incoming_damage_multiplier() -> float:
	return _status_resolver.get_incoming_damage_multiplier("enemy")

func get_enemy_outgoing_damage_multiplier() -> float:
	return _status_resolver.get_outgoing_damage_multiplier("enemy")

func get_enemy_status_summary() -> String:
	return _status_resolver.get_active_status_summary("enemy")

func get_member_status_summary(member_index: int) -> String:
	return _status_resolver.get_active_status_summary("party_%d" % member_index)

func get_enemy_status_list() -> Array[Dictionary]:
	return _status_resolver.get_active_status_list("enemy")

func get_member_status_list(member_index: int) -> Array[Dictionary]:
	return _status_resolver.get_active_status_list("party_%d" % member_index)

# ---- Initiative (P3-D019 Phase 1 + Phase 2) ----

func get_party_initiative_score() -> float:
	var best: float = 0.0
	for i in party_combat_hp.size():
		if not is_member_alive(i):
			continue
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
		best = maxf(best, spd * job_mod * (1.0 + affix_mult))
	return best if best > 0.0 else 1.0

func get_enemy_initiative_score() -> float:
	if current_enemy_data == null:
		return 1.0
	return current_enemy_data.attack_speed if current_enemy_data.attack_speed > 0.0 else 1.0

func does_enemy_act_first() -> bool:
	return get_enemy_initiative_score() > get_party_initiative_score()
