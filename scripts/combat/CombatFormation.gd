class_name CombatFormation
extends RefCounted

## 陣形（前列/後列）の戦闘解決（P3-D106c〜e）。列ターゲット・被弾分散・散開/密集 SSOT。

const TARGET_ALL_PARTY: String = "all_party"
const TARGET_PARTY_FRONT: String = "party_front"
const TARGET_PARTY_BACK: String = "party_back"

const DENSE_ROW_INCOMING: float = BalanceConfig.DENSE_ROW_INCOMING
const SPREAD_ROW_INCOMING: float = BalanceConfig.SPREAD_ROW_INCOMING
const DENSE_ROW_MIN_COUNT: int = 2

static func get_column_member_indices(
	party_size: int,
	is_member_alive: Callable,
	want_back_row: bool
) -> Array[int]:
	var targets: Array[int] = []
	for i: int in party_size:
		if not is_member_alive.call(i):
			continue
		if GameState.is_member_back_row(i) == want_back_row:
			targets.append(i)
	return targets

static func resolve_column_members_with_fallback(
	target_type: String,
	party_size: int,
	is_member_alive: Callable
) -> Dictionary:
	var want_back: bool = target_type == TARGET_PARTY_BACK
	var indices: Array[int] = get_column_member_indices(party_size, is_member_alive, want_back)
	var used_fallback: bool = false
	if indices.is_empty() and target_type in [TARGET_PARTY_FRONT, TARGET_PARTY_BACK]:
		used_fallback = true
		indices = get_column_member_indices(party_size, is_member_alive, not want_back)
	return {"indices": indices, "fallback": used_fallback}

static func threat_damage_shares(member_indices: Array[int], get_threat: Callable) -> Dictionary:
	var shares: Dictionary = {}
	if member_indices.is_empty():
		return shares
	if member_indices.size() == 1:
		shares[member_indices[0]] = 1.0
		return shares
	var total: float = 0.0
	for i: int in member_indices:
		total += maxf(0.0, float(get_threat.call(i)))
	if total <= 0.0:
		var eq: float = 1.0 / float(member_indices.size())
		for i: int in member_indices:
			shares[i] = eq
		return shares
	for i: int in member_indices:
		shares[i] = maxf(0.0, float(get_threat.call(i))) / total
	return shares

static func resolve_enemy_party_targets(
	skill: Resource,
	party_size: int,
	is_member_alive: Callable,
	pick_single_target: Callable
) -> Array[int]:
	if skill == null:
		return []
	var target_type: String = str(skill.target_type)
	var targets: Array[int] = []
	match target_type:
		TARGET_ALL_PARTY:
			for i: int in party_size:
				if is_member_alive.call(i):
					targets.append(i)
		TARGET_PARTY_FRONT, TARGET_PARTY_BACK:
			var resolved: Dictionary = resolve_column_members_with_fallback(
				target_type, party_size, is_member_alive
			)
			targets = resolved["indices"]
		_:
			var t: int = int(pick_single_target.call())
			if t >= 0:
				targets.append(t)
	return targets

static func enemy_target_row_log_tag(target_type: String, used_fallback: bool = false) -> String:
	var base: String = ""
	match target_type:
		TARGET_PARTY_FRONT:
			base = "（前列）"
		TARGET_PARTY_BACK:
			base = "（後列）"
		TARGET_ALL_PARTY:
			base = "（全体）"
		_:
			base = ""
	if used_fallback and not base.is_empty():
		return base + "→反対列"
	return base

static func column_distribution_log_tag(member_indices: Array[int]) -> String:
	return " [分散]" if member_indices.size() > 1 else ""

static func density_incoming_multiplier(
	member_index: int,
	party_size: int,
	is_member_alive: Callable
) -> float:
	if member_index < 0 or not is_member_alive.call(member_index):
		return 1.0
	var row_count: int = get_column_member_indices(
		party_size,
		is_member_alive,
		GameState.is_member_back_row(member_index)
	).size()
	if row_count >= DENSE_ROW_MIN_COUNT:
		return DENSE_ROW_INCOMING
	if row_count == 1:
		return SPREAD_ROW_INCOMING
	return 1.0

static func density_log_tag(
	member_index: int,
	party_size: int,
	is_member_alive: Callable
) -> String:
	if member_index < 0 or not is_member_alive.call(member_index):
		return ""
	var row_count: int = get_column_member_indices(
		party_size,
		is_member_alive,
		GameState.is_member_back_row(member_index)
	).size()
	if row_count >= DENSE_ROW_MIN_COUNT:
		return " [密集]"
	if row_count == 1:
		return " [散開]"
	return ""
