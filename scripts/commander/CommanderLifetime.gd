class_name CommanderLifetime
extends RefCounted

const _MvpScore := preload("res://scripts/result/MvpScore.gd")
const _CommanderDefaults := preload("res://scripts/commander/CommanderDefaults.gd")
const _CommanderProfile := preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderTitles := preload("res://scripts/commander/CommanderTitles.gd")

## 指揮官の通算統計（P3-CMD-002）。

const HIGHLIGHT_LIMIT: int = 3


static func default_lifetime_dict() -> Dictionary:
	return _CommanderDefaults.default_lifetime_dict()


static func default_commander_dict() -> Dictionary:
	return _CommanderDefaults.default_commander_dict()


static func record_run_started() -> void:
	_CommanderProfile.ensure_commander()
	var lifetime: Dictionary = _CommanderProfile.get_lifetime()
	lifetime["runs_started"] = int(lifetime.get("runs_started", 0)) + 1
	for member: Resource in GameState.party_members:
		if member == null:
			continue
		var member_id: String = str(member.id)
		var counts: Dictionary = lifetime.get("deployment_counts", {})
		if not counts is Dictionary:
			counts = {}
		counts[member_id] = int(counts.get(member_id, 0)) + 1
		lifetime["deployment_counts"] = counts
	GameState.commander["lifetime"] = lifetime


static func record_run_finished(
	outcome: String,
	stats_snapshot: Dictionary,
	context: Dictionary = {}
) -> void:
	_CommanderProfile.ensure_commander()
	var lifetime: Dictionary = _CommanderProfile.get_lifetime()
	match outcome:
		GameState.RUN_OUTCOME_CLEAR:
			lifetime["runs_cleared"] = int(lifetime.get("runs_cleared", 0)) + 1
		GameState.RUN_OUTCOME_RETIRE:
			lifetime["runs_retired"] = int(lifetime.get("runs_retired", 0)) + 1
		GameState.RUN_OUTCOME_WIPE:
			lifetime["runs_wiped"] = int(lifetime.get("runs_wiped", 0)) + 1
	_merge_combat_stats(lifetime, stats_snapshot, context)
	_record_mvp(lifetime, stats_snapshot)
	GameState.commander["lifetime"] = lifetime
	_append_highlights(outcome, stats_snapshot, context)
	_CommanderTitles.refresh_unlocks()


static func _merge_combat_stats(
	lifetime: Dictionary,
	stats_snapshot: Dictionary,
	context: Dictionary
) -> void:
	var run_damage_total: int = 0
	var run_heal_total: int = 0
	var context_label: String = _context_label(context)
	for member_id: Variant in stats_snapshot.keys():
		var row: Dictionary = stats_snapshot[member_id]
		if not row is Dictionary:
			continue
		var damage_total: int = int(row.get("damage_total", 0))
		var heal_total: int = int(row.get("heal_total", 0))
		var max_hit: int = int(row.get("damage_max_hit", 0))
		run_damage_total += damage_total
		run_heal_total += heal_total
		if max_hit > int(lifetime.get("damage_max_hit", 0)):
			lifetime["damage_max_hit"] = max_hit
			lifetime["damage_max_hit_member_id"] = str(member_id)
			lifetime["damage_max_hit_skill_name"] = str(row.get("damage_max_skill_name", ""))
			lifetime["damage_max_hit_context"] = context_label
	if run_damage_total > int(lifetime.get("damage_max_run_total", 0)):
		lifetime["damage_max_run_total"] = run_damage_total
	if run_heal_total > int(lifetime.get("heal_max_run_total", 0)):
		lifetime["heal_max_run_total"] = run_heal_total


static func _record_mvp(lifetime: Dictionary, stats_snapshot: Dictionary) -> void:
	var mvp: Dictionary = _MvpScore.pick_mvp(stats_snapshot, GameState.party_members)
	if mvp.is_empty():
		return
	var member_id: String = str(mvp.get("member_id", ""))
	if member_id.is_empty():
		return
	var counts: Dictionary = lifetime.get("mvp_counts", {})
	if not counts is Dictionary:
		counts = {}
	counts[member_id] = int(counts.get(member_id, 0)) + 1
	lifetime["mvp_counts"] = counts


static func _append_highlights(
	outcome: String,
	stats_snapshot: Dictionary,
	context: Dictionary
) -> void:
	var lines: Array[String] = []
	var context_label: String = _context_label(context)
	if outcome == GameState.RUN_OUTCOME_CLEAR:
		if not context_label.is_empty():
			lines.append("%s を完走" % context_label)
	var lifetime: Dictionary = _CommanderProfile.get_lifetime()
	var max_hit: int = int(lifetime.get("damage_max_hit", 0))
	var skill_name: String = str(lifetime.get("damage_max_hit_skill_name", ""))
	if max_hit > 0 and _snapshot_has_max(stats_snapshot, max_hit):
		if skill_name.is_empty():
			lines.append("最大一撃 %s" % _format_int(max_hit))
		else:
			lines.append("最大一撃 %s（%s）" % [_format_int(max_hit), skill_name])
	if lines.is_empty():
		return
	var highlights: Array = _CommanderProfile.get_recent_highlights()
	for line: String in lines:
		highlights.insert(0, {"text": line})
	while highlights.size() > HIGHLIGHT_LIMIT:
		highlights.pop_back()
	GameState.commander["recent_highlights"] = highlights


static func _snapshot_has_max(stats_snapshot: Dictionary, max_hit: int) -> bool:
	for member_id: Variant in stats_snapshot.keys():
		var row: Dictionary = stats_snapshot[member_id]
		if row is Dictionary and int(row.get("damage_max_hit", 0)) == max_hit:
			return true
	return false


static func _context_label(context: Dictionary) -> String:
	var stage_id: String = str(context.get("stage_id", ""))
	if not stage_id.is_empty():
		var stage: Resource = DataRegistry.get_stage_data(stage_id)
		if stage != null and not str(stage.display_name).is_empty():
			return str(stage.display_name)
	var dungeon_id: String = str(context.get("dungeon_id", ""))
	if not dungeon_id.is_empty():
		var dungeon: Resource = DataRegistry.get_dungeon_data(dungeon_id)
		if dungeon != null and not str(dungeon.display_name).is_empty():
			return str(dungeon.display_name)
	return ""


static func _format_int(value: int) -> String:
	var text: String = str(value)
	var out: PackedStringArray = []
	var count: int = 0
	for i in range(text.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out.insert(0, ",")
		out.insert(0, text.substr(i, 1))
		count += 1
	return "".join(out)
