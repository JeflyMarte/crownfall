class_name SkillProgression
extends RefCounted

## ジョブスキルのレベル習得（P3-SKILL-001）。解放状態はセーブせず Lv から導出。

static func get_unlock_entries(job_data: Resource) -> Array:
	if job_data == null:
		return []
	if "skill_unlocks" in job_data:
		var configured: Array = job_data.skill_unlocks
		if not configured.is_empty():
			return configured.duplicate()
	if "learnable_skill_ids" in job_data:
		var legacy: Array = []
		for raw_id in job_data.learnable_skill_ids:
			var sid: String = str(raw_id)
			if sid.is_empty():
				continue
			legacy.append({"skill_id": sid, "level": 1})
		return legacy
	return []

static func get_unlocked_job_skill_ids(member: Resource) -> Array[String]:
	var out: Array[String] = []
	if member == null:
		return out
	var job_data: Resource = DataRegistry.get_job_data(str(member.job_id))
	for entry in get_unlock_entries(job_data):
		if not entry is Dictionary:
			continue
		var sid: String = str(entry.get("skill_id", ""))
		if sid.is_empty() or out.has(sid):
			continue
		if int(member.level) >= int(entry.get("level", 1)):
			out.append(sid)
	return out

static func get_required_level(member: Resource, skill_id: String) -> int:
	if member == null or skill_id.is_empty():
		return 1
	var job_data: Resource = DataRegistry.get_job_data(str(member.job_id))
	for entry in get_unlock_entries(job_data):
		if not entry is Dictionary:
			continue
		if str(entry.get("skill_id", "")) == skill_id:
			return maxi(1, int(entry.get("level", 1)))
	return 999

static func is_job_skill_unlocked(member: Resource, skill_id: String) -> bool:
	if member == null or skill_id.is_empty():
		return false
	return get_unlocked_job_skill_ids(member).has(skill_id)

static func can_equip_job_skill(member: Resource, skill_id: String) -> bool:
	return is_job_skill_unlocked(member, skill_id)

static func normalize_equipped_skills(member: Resource) -> void:
	if member == null:
		return
	var allowed: Array[String] = get_unlocked_job_skill_ids(member)
	var ids: Array[String] = []
	if "equipped_skill_ids" in member:
		for raw_id in member.equipped_skill_ids:
			var sid: String = str(raw_id)
			if sid.is_empty() or not allowed.has(sid):
				continue
			if ids.size() >= Constants.MAX_EQUIPPED_SKILLS:
				break
			if not ids.has(sid):
				ids.append(sid)
	member.equipped_skill_ids = ids
