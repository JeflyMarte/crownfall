class_name CombatFormation
extends RefCounted

## 陣形（前列/後列）の戦闘解決。P3-D106e＝散開/密集（同列生存人数）。

const DENSE_ROW_INCOMING: float = 1.08   # 同列2人以上
const SPREAD_ROW_INCOMING: float = 0.94    # 同列1人のみ
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
