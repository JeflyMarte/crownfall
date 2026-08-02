extends RefCounted

## 指揮官 許可強化（P3-CMD-PERMIT-BOOST-001 / Decision 58）。
## S+n 到達で許可点を付与し、略奪／成長／戦力へ割り振る。

const _CommanderProfile := preload("res://scripts/commander/CommanderProfile.gd")

const TRACK_PLUNDER: String = "plunder"
const TRACK_GROWTH: String = "growth"
const TRACK_POWER: String = "power"
const TRACK_ORDER: Array[String] = [TRACK_PLUNDER, TRACK_GROWTH, TRACK_POWER]

const TRACK_LABELS: Dictionary = {
	TRACK_PLUNDER: "略奪",
	TRACK_GROWTH: "成長",
	TRACK_POWER: "戦力",
}

## 1点あたりの薄い％（略奪・成長・HP）。
const PERCENT_PER_POINT: float = 0.02
## 戦力: 防御 flat（点×この値）。
const DEFENSE_FLAT_PER_POINT: int = 2


static func ensure() -> void:
	_CommanderProfile.ensure_commander()
	if not GameState.commander.has("permit_points_earned"):
		GameState.commander["permit_points_earned"] = 0
	if not GameState.commander.has("permit_alloc") or not GameState.commander["permit_alloc"] is Dictionary:
		GameState.commander["permit_alloc"] = _empty_alloc()
	else:
		var alloc: Dictionary = GameState.commander["permit_alloc"] as Dictionary
		for track: String in TRACK_ORDER:
			if not alloc.has(track):
				alloc[track] = 0
			else:
				alloc[track] = maxi(0, int(alloc[track]))
		GameState.commander["permit_alloc"] = alloc
	_clamp_alloc_to_earned()


static func ensure_and_sync() -> void:
	ensure()
	sync_earned_from_acknowledged_rank()


static func _empty_alloc() -> Dictionary:
	return {
		TRACK_PLUNDER: 0,
		TRACK_GROWTH: 0,
		TRACK_POWER: 0,
	}


static func sync_earned_from_acknowledged_rank() -> void:
	## 既存 S+ セーブ: 到達段数ぶんを下限として付与（未割り振り）。
	if not GameState.commander is Dictionary:
		return
	var ack: String = _CommanderProfile.normalize_rank_code(
		str(GameState.commander.get("acknowledged_rank", "D"))
	)
	var n: int = _CommanderProfile.s_plus_level(ack)
	if n < 1:
		return
	var earned: int = maxi(0, int(GameState.commander.get("permit_points_earned", 0)))
	if n > earned:
		GameState.commander["permit_points_earned"] = n


static func grant_points_for_ranks(rank_codes: Array) -> int:
	## S+n コードのみ数え、許可点を加算して付与数を返す。
	ensure()
	var add: int = 0
	for raw: Variant in rank_codes:
		if _CommanderProfile.s_plus_level(str(raw)) >= 1:
			add += 1
	if add <= 0:
		return 0
	GameState.commander["permit_points_earned"] = points_earned() + add
	return add


static func points_earned() -> int:
	if not GameState.commander is Dictionary:
		return 0
	return maxi(0, int(GameState.commander.get("permit_points_earned", 0)))


static func points_allocated() -> int:
	if not GameState.commander is Dictionary:
		return 0
	var raw: Variant = GameState.commander.get("permit_alloc", {})
	if not raw is Dictionary:
		return 0
	var total: int = 0
	var alloc: Dictionary = raw as Dictionary
	for track: String in TRACK_ORDER:
		total += maxi(0, int(alloc.get(track, 0)))
	return total


static func points_unspent() -> int:
	ensure()
	return maxi(0, points_earned() - points_allocated())


static func get_alloc(track: String) -> int:
	ensure()
	var alloc: Dictionary = GameState.commander["permit_alloc"] as Dictionary
	return maxi(0, int(alloc.get(track, 0)))


static func max_for_track(track: String) -> int:
	## 他系統を維持したまま振れる上限（音量スライダーと同型）。
	ensure()
	var others: int = 0
	var alloc: Dictionary = GameState.commander["permit_alloc"] as Dictionary
	for t: String in TRACK_ORDER:
		if t == track:
			continue
		others += maxi(0, int(alloc.get(t, 0)))
	return maxi(0, points_earned() - others)


static func set_alloc(track: String, value: int) -> int:
	ensure()
	if not TRACK_ORDER.has(track):
		return get_alloc(track)
	var clamped: int = clampi(value, 0, max_for_track(track))
	var alloc: Dictionary = GameState.commander["permit_alloc"] as Dictionary
	alloc[track] = clamped
	GameState.commander["permit_alloc"] = alloc
	return clamped


static func _clamp_alloc_to_earned() -> void:
	var earned: int = maxi(0, int(GameState.commander.get("permit_points_earned", 0)))
	var alloc: Dictionary = GameState.commander["permit_alloc"] as Dictionary
	var total: int = 0
	for track: String in TRACK_ORDER:
		total += maxi(0, int(alloc.get(track, 0)))
	if total <= earned:
		return
	## 超過時は戦力→成長→略奪の順に削る。
	var overflow: int = total - earned
	var reverse: Array[String] = [TRACK_POWER, TRACK_GROWTH, TRACK_PLUNDER]
	for track: String in reverse:
		if overflow <= 0:
			break
		var cur: int = maxi(0, int(alloc.get(track, 0)))
		var cut: int = mini(cur, overflow)
		alloc[track] = cur - cut
		overflow -= cut
	GameState.commander["permit_alloc"] = alloc


static func gold_mult() -> float:
	return 1.0 + PERCENT_PER_POINT * float(get_alloc(TRACK_PLUNDER))


static func material_mult() -> float:
	return 1.0 + PERCENT_PER_POINT * float(get_alloc(TRACK_PLUNDER))


static func exp_mult() -> float:
	return 1.0 + PERCENT_PER_POINT * float(get_alloc(TRACK_GROWTH))


static func hp_mult() -> float:
	return 1.0 + PERCENT_PER_POINT * float(get_alloc(TRACK_POWER))


static func defense_flat() -> int:
	return DEFENSE_FLAT_PER_POINT * get_alloc(TRACK_POWER)


static func track_bonus_caption(track: String) -> String:
	var n: int = get_alloc(track)
	var pct: int = int(round(PERCENT_PER_POINT * 100.0 * float(n)))
	match track:
		TRACK_PLUNDER:
			return "Gold・素材 +%d%%" % pct
		TRACK_GROWTH:
			return "経験値 +%d%%" % pct
		TRACK_POWER:
			return "HP +%d%% / 防御 +%d" % [pct, DEFENSE_FLAT_PER_POINT * n]
		_:
			return ""


static func summary_caption() -> String:
	var parts: PackedStringArray = []
	for track: String in TRACK_ORDER:
		var n: int = get_alloc(track)
		if n <= 0:
			continue
		parts.append("%s %d" % [str(TRACK_LABELS.get(track, track)), n])
	if parts.is_empty():
		return "未振り分け"
	return " / ".join(parts)
