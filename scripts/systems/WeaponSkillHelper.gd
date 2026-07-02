class_name WeaponSkillHelper
extends RefCounted

## レジェンド武器の固有スキル（P3-SKILL-004）。装備枠を消費しない第3系統。

static func get_weapon_skill_id(member: Resource) -> String:
	if member == null:
		return ""
	var weapon: Resource = member.equipped_weapon
	if weapon == null or str(weapon.weapon_id).is_empty():
		return ""
	var weapon_data: Resource = DataRegistry.get_weapon_data(str(weapon.weapon_id))
	if weapon_data == null:
		return ""
	if int(weapon_data.rarity) < Enums.Rarity.LEGENDARY:
		return ""
	var skill_id: String = str(weapon_data.fixed_skill_id)
	if skill_id.is_empty():
		return ""
	if DataRegistry.get_skill_data(skill_id) == null:
		return ""
	return skill_id

static func get_weapon_skill_display(member: Resource) -> Dictionary:
	var skill_id: String = get_weapon_skill_id(member)
	if skill_id.is_empty():
		return {"skill_id": "", "skill_name": "", "weapon_name": ""}
	var skill_data: Resource = DataRegistry.get_skill_data(skill_id)
	var weapon: Resource = member.equipped_weapon if member != null else null
	var weapon_name: String = ""
	if weapon != null:
		weapon_name = EquipmentEnhancer.get_display_name(weapon)
	return {
		"skill_id": skill_id,
		"skill_name": str(skill_data.display_name) if skill_data != null else skill_id,
		"weapon_name": weapon_name,
	}

static func cooldown_key(member_idx: int, skill_id: String) -> String:
	return "%d:weapon:%s" % [member_idx, skill_id]
