class_name AbyssWeaponEffects
extends RefCounted

## 深層レジェンド固有の戦闘状態（P3-DG-ABYSS-001-C）。
## スタック／印／氷殻。数値は CombatPassives の eq_abyss_* 定義を読む。

## member_idx → { "slot": int, "stacks": int }
static var _root_focus: Dictionary = {}
## member_idx → { "slot": int, "stacks": int }
static var _tide_marks: Dictionary = {}
## member_idx → expire_msec
static var _ice_shell_until: Dictionary = {}


static func reset_combat() -> void:
	_root_focus.clear()
	_tide_marks.clear()
	_ice_shell_until.clear()


static func _weapon_def(member_index: int) -> Dictionary:
	return CombatPassives.weapon_passive_def_for_member(
		GameState.party_members[member_index]
		if member_index >= 0 and member_index < GameState.party_members.size()
		else null
	)


static func outgoing_multiplier(member_index: int, target_slot: int, hp_ratio: float) -> float:
	var def: Dictionary = _weapon_def(member_index)
	if def.is_empty():
		return 1.0
	var mult: float = 1.0
	var missing_bonus: float = float(def.get("missing_hp_outgoing_bonus", 0.0))
	if missing_bonus > 0.0:
		var ratio: float = clampf(hp_ratio, 0.0, 1.0)
		mult *= 1.0 + missing_bonus * (1.0 - ratio)
	var stack_bonus: float = float(def.get("same_target_stack_bonus", 0.0))
	if stack_bonus > 0.0 and target_slot >= 0:
		var stacks: int = _root_stacks_for(member_index, target_slot)
		mult *= 1.0 + stack_bonus * float(stacks)
	return mult


static func incoming_shell_multiplier(member_index: int) -> float:
	if not _ice_shell_until.has(member_index):
		return 1.0
	if Time.get_ticks_msec() > int(_ice_shell_until[member_index]):
		_ice_shell_until.erase(member_index)
		return 1.0
	var def: Dictionary = _weapon_def(member_index)
	var shell: float = float(def.get("ice_shell_incoming_mult", 0.65))
	return clampf(shell, 0.05, 1.0)


static func _root_stacks_for(member_index: int, target_slot: int) -> int:
	if not _root_focus.has(member_index):
		return 0
	var entry: Dictionary = _root_focus[member_index]
	if int(entry.get("slot", -1)) != target_slot:
		return 0
	return int(entry.get("stacks", 0))


## 攻撃ヒット後。潮汐印バースト量を返す（0=なし）。
static func after_attack_hit(member_index: int, target_slot: int, damage: int) -> int:
	var def: Dictionary = _weapon_def(member_index)
	if def.is_empty() or target_slot < 0 or damage <= 0:
		return 0
	_update_root_focus(member_index, target_slot, def)
	return _update_tide_marks(member_index, target_slot, damage, def)


static func _update_root_focus(member_index: int, target_slot: int, def: Dictionary) -> void:
	var stack_bonus: float = float(def.get("same_target_stack_bonus", 0.0))
	if stack_bonus <= 0.0:
		return
	var max_stacks: int = maxi(1, int(def.get("same_target_stack_max", 5)))
	if _root_focus.has(member_index) and int(_root_focus[member_index].get("slot", -1)) == target_slot:
		var stacks: int = mini(max_stacks, int(_root_focus[member_index].get("stacks", 0)) + 1)
		_root_focus[member_index] = {"slot": target_slot, "stacks": stacks}
	else:
		_root_focus[member_index] = {"slot": target_slot, "stacks": 1}


static func _update_tide_marks(
	member_index: int, target_slot: int, damage: int, def: Dictionary
) -> int:
	var threshold: int = int(def.get("tide_mark_threshold", 0))
	if threshold <= 0:
		return 0
	var burst_frac: float = float(def.get("tide_mark_burst_fraction", 1.5))
	if not _tide_marks.has(member_index) or int(_tide_marks[member_index].get("slot", -1)) != target_slot:
		_tide_marks[member_index] = {"slot": target_slot, "stacks": 1}
		return 0
	var stacks: int = int(_tide_marks[member_index].get("stacks", 0)) + 1
	if stacks < threshold:
		_tide_marks[member_index] = {"slot": target_slot, "stacks": stacks}
		return 0
	_tide_marks[member_index] = {"slot": target_slot, "stacks": 0}
	return maxi(1, int(round(float(damage) * burst_frac)))


static func activate_ice_shell(member_index: int) -> bool:
	var def: Dictionary = _weapon_def(member_index)
	if float(def.get("ice_shell_incoming_mult", 0.0)) <= 0.0:
		return false
	var duration_sec: float = float(def.get("ice_shell_duration_sec", 4.0))
	_ice_shell_until[member_index] = Time.get_ticks_msec() + int(duration_sec * 1000.0)
	return true


## 敵ディスペル等で非 Status の氷殻も落とす。
static func clear_ice_shell(member_index: int) -> bool:
	if not _ice_shell_until.has(member_index):
		return false
	_ice_shell_until.erase(member_index)
	return true


## HP閾値で氷殻（被弾なしでも）。発動したら true。
static func try_low_hp_ice_shell(member_index: int, hp_ratio: float) -> bool:
	var def: Dictionary = _weapon_def(member_index)
	var threshold: float = float(def.get("ice_shell_hp_threshold", -1.0))
	if threshold < 0.0:
		return false
	if hp_ratio >= threshold:
		return false
	if _ice_shell_until.has(member_index) and Time.get_ticks_msec() <= int(_ice_shell_until[member_index]):
		return false
	return activate_ice_shell(member_index)


static func clear_focus_on_enemy_death(target_slot: int) -> void:
	for key: Variant in _root_focus.keys():
		if int(_root_focus[key].get("slot", -1)) == target_slot:
			_root_focus.erase(key)
	for key: Variant in _tide_marks.keys():
		if int(_tide_marks[key].get("slot", -1)) == target_slot:
			_tide_marks.erase(key)
