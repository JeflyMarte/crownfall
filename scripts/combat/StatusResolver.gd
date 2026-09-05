class_name StatusResolver
extends RefCounted

const MAX_DISTINCT_STATUSES: int = 3
## ミストフェン象徴・瘴気。毒 DoT のみ増幅（天候乗算のあと）。
const MIRE_TOXIN_POISON_MULT: float = 1.4
## 同系統の弱い／強い状態は共存させない（与ダメ乗算の二重掛け防止）。
const MUTUALLY_EXCLUSIVE: Dictionary = {
	"curse": ["major_curse"],
	"major_curse": ["curse"],
	"empower": ["empower_minor"],
	"empower_minor": ["empower"],
	"empower_pet": [],
	"guard": ["guard_minor"],
	"guard_minor": ["guard"],
}

var _active: Dictionary = {}  # unit_id -> Array[StatusInstance]

func clear_all() -> void:
	_active.clear()

func clear_unit(unit_id: String) -> void:
	_active.erase(unit_id)

func apply_status(
	unit_id: String,
	effect_id: String,
	stacks_to_add: int = 1,
	source_attack: int = 0,
	duration_override: int = -1
) -> bool:
	if effect_id.is_empty():
		return false
	var effect: Resource = DataRegistry.get_status_effect(effect_id)
	if effect == null:
		return false
	stacks_to_add = maxi(1, stacks_to_add)
	if not _active.has(unit_id):
		_active[unit_id] = []
	var instances: Array = _active[unit_id]
	_remove_exclusive_statuses(instances, effect_id)
	var ticks: int = int(effect.duration_ticks)
	if duration_override >= 0:
		ticks = duration_override
	for inst: StatusInstance in instances:
		if inst.effect_id == effect_id:
			inst.stacks = mini(effect.max_stacks, inst.stacks + stacks_to_add)
			inst.remaining_ticks = ticks
			if source_attack > 0:
				inst.source_attack = source_attack
			return true
	if instances.size() >= MAX_DISTINCT_STATUSES:
		return false
	var new_inst := StatusInstance.new()
	new_inst.effect_id = effect_id
	new_inst.stacks = mini(stacks_to_add, effect.max_stacks)
	new_inst.remaining_ticks = ticks
	new_inst.source_attack = source_attack
	instances.append(new_inst)
	return true


func _remove_exclusive_statuses(instances: Array, effect_id: String) -> void:
	var blocked: Array = MUTUALLY_EXCLUSIVE.get(effect_id, [])
	if blocked.is_empty():
		return
	var i: int = instances.size() - 1
	while i >= 0:
		if str((instances[i] as StatusInstance).effect_id) in blocked:
			instances.remove_at(i)
		i -= 1

func tick_unit(unit_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if not _active.has(unit_id):
		return results
	var instances: Array = _active[unit_id]
	var survivors: Array = []
	for inst: StatusInstance in instances:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null:
			continue
		if effect.effect_type == "dot":
			var dmg: int = 0
			if effect.dot_percent_of_attack > 0.0:
				dmg += int(inst.source_attack * effect.dot_percent_of_attack * inst.stacks)
			if effect.dot_flat > 0:
				dmg += effect.dot_flat * inst.stacks
			if dmg > 0 and str(inst.effect_id) == "poison":
				var p_mult: float = CombatWeather.poison_damage_multiplier(GameState.get_weather())
				if get_status_stacks(unit_id, "mire_toxin") > 0:
					p_mult *= MIRE_TOXIN_POISON_MULT
				if not is_equal_approx(p_mult, 1.0):
					dmg = maxi(1, int(round(float(dmg) * p_mult)))
			## 味方上の DoT のみ厚く（敵付与想定・P3-BAL-ENEMY-PRESSURE-001）。
			if dmg > 0 and unit_id.begins_with("party_"):
				dmg = maxi(1, int(round(float(dmg) * BalanceConfig.ENEMY_DOT_ON_PARTY_MULT)))
			if dmg > 0:
				results.append({
					"effect_id": inst.effect_id,
					"display_name": effect.display_name,
					"damage": dmg,
					"unit_id": unit_id,
				})
		elif effect.effect_type == "hot":
			var heal_ratio: float = float(effect.hot_percent_of_max) * float(inst.stacks)
			if heal_ratio > 0.0:
				results.append({
					"effect_id": inst.effect_id,
					"display_name": effect.display_name,
					"heal_percent_max": heal_ratio,
					"unit_id": unit_id,
				})
		inst.remaining_ticks -= 1
		if inst.remaining_ticks > 0:
			survivors.append(inst)
	if survivors.is_empty():
		_active.erase(unit_id)
	else:
		_active[unit_id] = survivors
	return results

func get_status_stacks(unit_id: String, effect_id: String) -> int:
	if not _active.has(unit_id):
		return 0
	for inst: StatusInstance in _active[unit_id]:
		if inst.effect_id == effect_id:
			return inst.stacks
	return 0

## 味方バフ（防御／鼓舞／再生など）。敵ディスペル対象（P3-BAL-ENEMY-DISPEL-001）。
const BENEFICIAL_STATUS_IDS: PackedStringArray = [
	"guard",
	"guard_minor",
	"empower",
	"empower_minor",
	"empower_pet",
	"regen",
	"crit_surge",
	"blood_drain",
	"status_ward",
	"elemental_attune",
]


static func is_beneficial_status(effect_id: String) -> bool:
	return effect_id in BENEFICIAL_STATUS_IDS


func has_beneficial_status(unit_id: String) -> bool:
	if not _active.has(unit_id):
		return false
	for inst: StatusInstance in _active[unit_id]:
		if is_beneficial_status(str(inst.effect_id)):
			return true
	return false


## 有益バフをすべて除去。除去した effect_id 一覧を返す。
func remove_beneficial_statuses(unit_id: String) -> PackedStringArray:
	var removed: PackedStringArray = PackedStringArray()
	if not _active.has(unit_id):
		return removed
	var survivors: Array = []
	for inst: StatusInstance in _active[unit_id]:
		var sid: String = str(inst.effect_id)
		if is_beneficial_status(sid):
			if sid not in removed:
				removed.append(sid)
		else:
			survivors.append(inst)
	if survivors.is_empty():
		_active.erase(unit_id)
	else:
		_active[unit_id] = survivors
	return removed


# 指定状態を丸ごと除去し、消費したスタック数を返す（0=不在）。コンボ起爆用。
func consume_status(unit_id: String, effect_id: String) -> int:
	if not _active.has(unit_id):
		return 0
	var removed: int = 0
	var survivors: Array = []
	for inst: StatusInstance in _active[unit_id]:
		if inst.effect_id == effect_id:
			removed = inst.stacks
		else:
			survivors.append(inst)
	if survivors.is_empty():
		_active.erase(unit_id)
	else:
		_active[unit_id] = survivors
	return removed

## 1行動あたり最大1回の SKIP 抽選（P3-BAL-BOSS-CC-RESIST-001）。
## `chance_mult`: ボス0.5／エリート0.75／通常1.0。
func should_skip_action(unit_id: String, chance_mult: float = 1.0) -> bool:
	var chance: float = best_skip_action_chance(unit_id) * maxf(0.0, chance_mult)
	if chance <= 0.0:
		return false
	return randf() < clampf(chance, 0.0, 1.0)


## 付与中 SKIP 系の最大確率（耐性倍率前）。鈍化は interval 代理。
func best_skip_action_chance(unit_id: String) -> float:
	if not _active.has(unit_id):
		return 0.0
	var best: float = 0.0
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null:
			continue
		var chance: float = 0.0
		if effect.skip_action_chance > 0.0:
			chance = float(effect.skip_action_chance)
		elif effect.effect_type == "stat_mod" and effect.interval_multiplier > 1.0:
			chance = BalanceConfig.CC_INTERVAL_PROXY_SKIP_CHANCE
		if chance > best:
			best = chance
	return best


## Guaranteed skip only (effective chance >= 1). No RNG — safe for UI preview.
func has_guaranteed_action_skip(unit_id: String, chance_mult: float = 1.0) -> bool:
	return best_skip_action_chance(unit_id) * maxf(0.0, chance_mult) >= 1.0

func get_skip_action_label(unit_id: String) -> String:
	if not _active.has(unit_id):
		return ""
	var best: float = -1.0
	var label: String = ""
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null:
			continue
		var chance: float = 0.0
		if effect.skip_action_chance > 0.0:
			chance = float(effect.skip_action_chance)
		elif effect.effect_type == "stat_mod" and effect.interval_multiplier > 1.0:
			chance = BalanceConfig.CC_INTERVAL_PROXY_SKIP_CHANCE
		if chance > best:
			best = chance
			label = str(effect.display_name)
	return label

func get_outgoing_damage_multiplier(unit_id: String) -> float:
	var mult: float = 1.0
	if not _active.has(unit_id):
		return mult
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null:
			continue
		if effect.outgoing_damage_multiplier > 0.0:
			mult *= effect.outgoing_damage_multiplier
	return mult


func get_crit_rate_add(unit_id: String) -> float:
	var add: float = 0.0
	if not _active.has(unit_id):
		return add
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null or not ("crit_rate_add" in effect):
			continue
		add += maxf(0.0, float(effect.crit_rate_add))
	return add


func get_lifesteal_ratio(unit_id: String) -> float:
	var ratio: float = 0.0
	if not _active.has(unit_id):
		return ratio
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null or not ("lifesteal_ratio" in effect):
			continue
		ratio += maxf(0.0, float(effect.lifesteal_ratio))
	return ratio


func get_elemental_outgoing_mult(unit_id: String) -> float:
	var mult: float = 1.0
	if not _active.has(unit_id):
		return mult
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null or not ("elemental_outgoing_mult" in effect):
			continue
		var e_mult: float = float(effect.elemental_outgoing_mult)
		if e_mult > 0.0 and not is_equal_approx(e_mult, 1.0):
			mult *= e_mult
	return mult


func get_incoming_status_chance_mult(unit_id: String) -> float:
	var mult: float = 1.0
	if not _active.has(unit_id):
		return mult
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null or not ("incoming_status_chance_mult" in effect):
			continue
		var s_mult: float = float(effect.incoming_status_chance_mult)
		if s_mult > 0.0 and not is_equal_approx(s_mult, 1.0):
			mult *= s_mult
	return mult

func get_incoming_damage_multiplier(unit_id: String) -> float:
	var mult: float = 1.0
	if not _active.has(unit_id):
		return mult
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null:
			continue
		if effect.incoming_damage_multiplier > 0.0:
			mult *= effect.incoming_damage_multiplier
	return mult


## 被回復倍率（heal_block=0 等）。未付与は 1.0。
func get_healing_received_multiplier(unit_id: String) -> float:
	var mult: float = 1.0
	if not _active.has(unit_id):
		return mult
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null:
			continue
		if "healing_received_multiplier" in effect:
			mult *= float(effect.healing_received_multiplier)
	return mult

# 対象に乗った状態異常の DEF 減少率（armor_break 等・P3-D107）。
# 複数あれば乗算合成（1 - Π(1 - r)）。0.0=なし / 上限 0.95。
func get_defense_reduction(unit_id: String) -> float:
	if not _active.has(unit_id):
		return 0.0
	var remain: float = 1.0
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null:
			continue
		if effect.defense_reduction > 0.0:
			remain *= (1.0 - clampf(effect.defense_reduction, 0.0, 1.0))
	return clampf(1.0 - remain, 0.0, 0.95)

func should_skip_enemy_action(unit_id: String = "enemy") -> bool:
	return should_skip_action(unit_id)

func get_active_status_summary(unit_id: String) -> String:
	if not _active.has(unit_id):
		return ""
	var instances: Array = _active[unit_id]
	if instances.is_empty():
		return ""
	var parts: PackedStringArray = []
	for inst: StatusInstance in instances:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		var label: String = inst.effect_id
		if effect != null:
			label = effect.display_name
		if inst.stacks > 1:
			label += "×%d" % inst.stacks
		parts.append(label)
	return " ".join(parts)

func get_active_status_list(unit_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if not _active.has(unit_id):
		return results
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		var display_name: String = inst.effect_id
		if effect != null:
			display_name = effect.display_name
		results.append({
			"effect_id": inst.effect_id,
			"display_name": display_name,
			"stacks": inst.stacks,
			"remaining_ticks": inst.remaining_ticks,
		})
	return results
