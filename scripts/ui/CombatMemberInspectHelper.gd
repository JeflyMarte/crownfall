class_name CombatMemberInspectHelper
extends RefCounted

const _SkillEffectOneLineHelper = preload("res://scripts/ui/SkillEffectOneLineHelper.gd")
const _RosterUiHelper = preload("res://scripts/roster/RosterUiHelper.gd")


static func build(member: Resource) -> Dictionary:
	if member == null:
		return {}
	var skills: Array[Dictionary] = []
	for skill_id: String in GameState.get_equipped_skill_ids(member):
		var skill_data: Resource = DataRegistry.get_skill_data(skill_id)
		if skill_data == null:
			continue
		skills.append(_skill_entry(skill_data, false))
	var passives: Array[Dictionary] = []
	for passive_id: String in GameState.get_equipped_character_passive_ids(member):
		var def: Dictionary = CombatPassives.get_def(passive_id)
		if def.is_empty():
			continue
		passives.append({
			"name": str(def.get("display_name", passive_id)),
			"description": _RosterUiHelper.passive_description(def),
		})
	return {
		"name": str(member.display_name),
		"level": maxi(1, int(member.level)),
		"skills": skills,
		"passives": passives,
		"ultimate": _ultimate_entry(member),
	}


static func _skill_entry(skill_data: Resource, is_ultimate: bool) -> Dictionary:
	var description: String = str(skill_data.description).strip_edges()
	return {
		"name": str(skill_data.display_name),
		"effect": (
			_SkillEffectOneLineHelper.for_combat_ultimate(skill_data)
			if is_ultimate
			else _regular_skill_effect(skill_data)
		),
		"description": description,
	}


static func _ultimate_entry(member: Resource) -> Dictionary:
	if member == null or Constants.is_pet_id(str(member.id)):
		return {}
	var ultimate_id: String = Constants.DEFAULT_ULTIMATE_SKILL_ID
	var job_id: String = str(member.job_id)
	if not job_id.is_empty():
		var job_data: Resource = DataRegistry.get_job_data(job_id)
		if (
			job_data != null
			and "ultimate_skill_id" in job_data
			and not str(job_data.ultimate_skill_id).is_empty()
		):
			ultimate_id = str(job_data.ultimate_skill_id)
	if ultimate_id.is_empty():
		return {}
	var skill_data: Resource = DataRegistry.get_skill_data(ultimate_id)
	if skill_data == null:
		return {}
	return _skill_entry(skill_data, true)


static func _regular_skill_effect(skill_data: Resource) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var target: String = _target_label(str(skill_data.target_type))
	match str(skill_data.effect_type):
		"heal":
			parts.append("%sを最大HPの%d%%回復" % [
				target, int(round(float(skill_data.power_multiplier) * 100.0))
			])
		"buff":
			var status_names: String = _status_names(skill_data)
			parts.append(
				"%sを強化" % target
				if status_names.is_empty()
				else "%sに%s" % [target, status_names]
			)
		_:
			parts.append("%sに威力×%.1f" % [target, float(skill_data.power_multiplier)])
			var status_names: String = _status_names(skill_data)
			if not status_names.is_empty():
				parts.append(status_names)
	parts.append("再使用%.0f秒" % float(skill_data.cooldown))
	if float(skill_data.cast_time) >= 1.0:
		parts.append("詠唱%dターン" % int(skill_data.cast_time))
	return "／".join(parts)


static func _target_label(target_type: String) -> String:
	match target_type:
		"enemy":
			return "敵1体"
		"all_enemies":
			return "敵全体"
		"ally", "party":
			return "味方1体"
		"all_party":
			return "味方全体"
		"party_front":
			return "味方前列"
		"party_back":
			return "味方後列"
		"self":
			return "自身"
		"pet":
			return "ペット"
	return "対象"


static func _status_names(skill_data: Resource) -> String:
	var names: PackedStringArray = PackedStringArray()
	for key: String in ["apply_status_id", "apply_status_id2", "apply_status_id3"]:
		var chance_key: String = key.replace("id", "chance")
		var status_id: String = str(skill_data.get(key))
		if status_id.is_empty() or float(skill_data.get(chance_key)) <= 0.0:
			continue
		var status_data: Resource = DataRegistry.get_status_effect(status_id)
		if status_data != null:
			names.append(str(status_data.display_name))
	return "／".join(names)
