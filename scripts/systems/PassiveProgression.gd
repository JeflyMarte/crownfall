class_name PassiveProgression
extends RefCounted

## パッシブ装備の正規化（スキル装備と同型）。レリックは専用枠（P3-RELIC-PASSIVE）。

static func selectable_passive_ids(member: Resource) -> Array[String]:
	return CombatPassives.selectable_passive_ids(member)

static func can_equip_passive(member: Resource, passive_id: String) -> bool:
	if member == null or passive_id.is_empty():
		return false
	if CombatPassives.is_relic_passive(passive_id):
		return false
	return selectable_passive_ids(member).has(passive_id)

static func normalize_equipped_passives(member: Resource) -> void:
	if member == null:
		return
	var character_ids: Array[String] = []
	var relic_id: String = ""
	if "relic_id" in member and not str(member.relic_id).is_empty():
		relic_id = CombatPassives.migrate_relic_passive_id(str(member.relic_id))
		member.relic_id = ""
	var allowed_character: Array[String] = selectable_passive_ids(member)
	if "equipped_passive_ids" in member:
		for raw_id in member.equipped_passive_ids:
			var pid: String = str(raw_id)
			if pid.is_empty():
				continue
			var migrated: String = CombatPassives.migrate_relic_passive_id(pid)
			if CombatPassives.is_relic_passive(migrated):
				if relic_id.is_empty() and GameState.has_relic(migrated):
					relic_id = migrated
				continue
			if not allowed_character.has(pid):
				continue
			if character_ids.size() >= Constants.MAX_EQUIPPED_PASSIVES:
				continue
			if not character_ids.has(pid):
				character_ids.append(pid)
	var merged: Array[String] = character_ids.duplicate()
	if not relic_id.is_empty():
		merged.append(relic_id)
	member.equipped_passive_ids = merged
