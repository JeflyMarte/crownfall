class_name CombatFormation
extends RefCounted

## 陣形（前列/後列）の戦闘解決（P3-D106c/d/e）。敵スキル列ターゲット・被弾分散・散開/密集 SSOT。

const TARGET_ALL_PARTY: String = "all_party"
const TARGET_PARTY_FRONT: String = "party_front"
const TARGET_PARTY_BACK: String = "party_back"

const DENSE_ROW_INCOMING: float = 1.08   # 同列2人以上＝密集ペナルティ（P3-D106e）
const SPREAD_ROW_INCOMING: float = 0.94    # 同列1人＝散開ボーナス
const DENSE_ROW_MIN_COUNT: int = 2

# 指定列の生存メンバー index（助っ人判定は is_member_alive 側で除外済み想定）。
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

# 列スキルの対象列。空なら反対列へフォールバック（P3-D106d）。
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

# 列内の Threat 比率で与ダメ配分（2人以上で [分散]）。合計 Threat 0 は均等割。
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

# 敵ダメージスキルの味方対象を解決。単体は pick_single_target を呼ぶ。
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

# 敵スキルログ用の列タグ（AoE 列範囲が明示されるときのみ）。
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

# 列内複数人への Threat 按分時のログタグ。
static func column_distribution_log_tag(member_indices: Array[int]) -> String:
	return " [分散]" if member_indices.size() > 1 else ""

# 同列の生存人数に応じた被ダメ倍率（P3-D106e）。
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

# 被ダメログ用（密集/散開）。
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
