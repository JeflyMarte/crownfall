class_name SkillProgression
extends RefCounted

## ジョブ／ペットスキルのレベル習得（P3-SKILL-001 / P3-PET-SKILL-001）。
## 解放状態はセーブせず Lv から導出。

## キット差し替え時の旧装備ID→新ID（P3-SKILL-KIT-DIVERGE-001）。
const EQUIPPED_SKILL_REMAP: Dictionary = {
	"chain_slash": "blade_dance",
	"armor_cleave": "battle_spirit",
	"momentum_slash": "battle_spirit",
	"mark_pursuit": "piercing_shot",
	"shield_ram": "cover_guard",
}


static func remap_equipped_skill_id(skill_id: String) -> String:
	if EQUIPPED_SKILL_REMAP.has(skill_id):
		return str(EQUIPPED_SKILL_REMAP[skill_id])
	return skill_id


static func get_unlock_entries(data: Resource) -> Array:
	if data == null:
		return []
	if "skill_unlocks" in data:
		var configured: Array = data.skill_unlocks
		if not configured.is_empty():
			return configured.duplicate()
	if "learnable_skill_ids" in data:
		var legacy: Array = []
		for raw_id in data.learnable_skill_ids:
			var sid: String = str(raw_id)
			if sid.is_empty():
				continue
			legacy.append({"skill_id": sid, "level": 1})
		return legacy
	## PetData フォールバック: skill_ids を Lv1 全解放扱い
	if "skill_ids" in data:
		var pet_legacy: Array = []
		for raw_id in data.skill_ids:
			var sid2: String = str(raw_id)
			if sid2.is_empty():
				continue
			pet_legacy.append({"skill_id": sid2, "level": 1})
		return pet_legacy
	return []


static func _unlocked_ids_from_entries(entries: Array, level: int) -> Array[String]:
	var out: Array[String] = []
	for entry in entries:
		if not entry is Dictionary:
			continue
		var sid: String = str(entry.get("skill_id", ""))
		if sid.is_empty() or out.has(sid):
			continue
		if level >= int(entry.get("level", 1)):
			out.append(sid)
	return out


static func _required_level_from_entries(entries: Array, skill_id: String) -> int:
	for entry in entries:
		if not entry is Dictionary:
			continue
		if str(entry.get("skill_id", "")) == skill_id:
			return maxi(1, int(entry.get("level", 1)))
	return 999


static func get_unlocked_job_skill_ids(member: Resource) -> Array[String]:
	var out: Array[String] = []
	if member == null:
		return out
	var job_data: Resource = DataRegistry.get_job_data(str(member.job_id))
	return _unlocked_ids_from_entries(get_unlock_entries(job_data), int(member.level))


static func get_unlocked_pet_skill_ids(pet: Resource) -> Array[String]:
	var out: Array[String] = []
	if pet == null or not Constants.is_pet_id(str(pet.id)):
		return out
	var pet_data: Resource = _load_pet_data(str(pet.id))
	return _unlocked_ids_from_entries(get_unlock_entries(pet_data), int(pet.level))


static func get_required_level(member: Resource, skill_id: String) -> int:
	if member == null or skill_id.is_empty():
		return 1
	if Constants.is_pet_id(str(member.id)):
		return get_pet_required_level(member, skill_id)
	var job_data: Resource = DataRegistry.get_job_data(str(member.job_id))
	return _required_level_from_entries(get_unlock_entries(job_data), skill_id)


static func get_pet_required_level(pet: Resource, skill_id: String) -> int:
	if pet == null or skill_id.is_empty():
		return 1
	var pet_data: Resource = _load_pet_data(str(pet.id))
	return _required_level_from_entries(get_unlock_entries(pet_data), skill_id)


static func _load_pet_data(pet_id: String) -> Resource:
	if pet_id.is_empty():
		return null
	var path: String = "res://resources/pets/%s.tres" % pet_id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Resource


static func is_job_skill_unlocked(member: Resource, skill_id: String) -> bool:
	if member == null or skill_id.is_empty():
		return false
	if Constants.is_pet_id(str(member.id)):
		return get_unlocked_pet_skill_ids(member).has(skill_id)
	return get_unlocked_job_skill_ids(member).has(skill_id)


static func can_equip_job_skill(member: Resource, skill_id: String) -> bool:
	return is_job_skill_unlocked(member, skill_id)


static func normalize_equipped_skills(member: Resource) -> void:
	if member == null:
		return
	## ペットも人間と同じく装備枠1（解放済みからの選択）（P3-PET-SKILL-001）
	var allowed: Array[String] = (
		get_unlocked_pet_skill_ids(member)
		if Constants.is_pet_id(str(member.id))
		else get_unlocked_job_skill_ids(member)
	)
	var ids: Array[String] = []
	if "equipped_skill_ids" in member:
		for raw_id in member.equipped_skill_ids:
			var sid: String = remap_equipped_skill_id(str(raw_id))
			if sid.is_empty() or not allowed.has(sid):
				continue
			if ids.size() >= Constants.MAX_EQUIPPED_SKILLS:
				break
			if not ids.has(sid):
				ids.append(sid)
	## 空なら解放済み先頭を既定装備
	if ids.is_empty() and not allowed.is_empty():
		ids.append(allowed[0])
	member.equipped_skill_ids = ids


## レベルアップで新たに解放されるスキル ID（level_before < req <= level_after）。
static func skill_ids_unlocked_between(member: Resource, level_before: int, level_after: int) -> Array[String]:
	var out: Array[String] = []
	if member == null or level_after <= level_before:
		return out
	var entries: Array = []
	if Constants.is_pet_id(str(member.id)):
		entries = get_unlock_entries(_load_pet_data(str(member.id)))
	else:
		entries = get_unlock_entries(DataRegistry.get_job_data(str(member.job_id)))
	for entry in entries:
		if not entry is Dictionary:
			continue
		var sid: String = str(entry.get("skill_id", ""))
		if sid.is_empty() or out.has(sid):
			continue
		var req: int = maxi(1, int(entry.get("level", 1)))
		if req > level_before and req <= level_after:
			out.append(sid)
	return out


## 指定レベルちょうどで解放されるスキル ID。
static func skill_ids_unlocked_at_level(member: Resource, level: int) -> Array[String]:
	return skill_ids_unlocked_between(member, level - 1, level)


## レベルアップ時: 未装備なら新規解放を既定装備候補に載せない（枠1のため現状維持）。
## 装備が空／無効だけになったとき normalize で先頭へ。
static func apply_pet_new_skill_unlocks(pet: Resource) -> void:
	if pet == null or not Constants.is_pet_id(str(pet.id)):
		return
	normalize_equipped_skills(pet)
