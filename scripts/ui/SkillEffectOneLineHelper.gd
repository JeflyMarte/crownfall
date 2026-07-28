class_name SkillEffectOneLineHelper
extends RefCounted

## スキル効果の戦闘向け一行要約（必殺カットイン等）。
## CD・威力x数値は出さず、「対象＋主効果＋付与状態」に絞る。

static func for_combat_ultimate(skill_data: Resource) -> String:
	if skill_data == null:
		return ""
	var target: String = _target_label(str(skill_data.target_type))
	var effect_type: String = str(skill_data.effect_type)
	match effect_type:
		"heal":
			return "%sを大きく回復" % target
		"buff":
			return _buff_one_line(skill_data, target)
		_:
			var main: String = "%sに大ダメージ" % target
			var statuses: String = _status_names(skill_data)
			if statuses.is_empty():
				return main
			return "%s＋%s" % [main, statuses]


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
			return "オトモ"
		_:
			return "対象"


static func _buff_one_line(skill_data: Resource, target: String) -> String:
	var status_id: String = str(skill_data.apply_status_id).strip_edges()
	if status_id.is_empty() or float(skill_data.apply_status_chance) <= 0.0:
		return "%sを強化" % target
	var eff: Resource = DataRegistry.get_status_effect(status_id)
	var st_name: String = str(eff.display_name) if eff != null else "強化"
	if st_name.is_empty():
		st_name = "強化"
	return "%sに%s" % [target, st_name]


static func _status_names(skill_data: Resource) -> String:
	var names: PackedStringArray = PackedStringArray()
	_append_status_name(names, str(skill_data.apply_status_id), float(skill_data.apply_status_chance))
	_append_status_name(names, str(skill_data.apply_status_id2), float(skill_data.apply_status_chance2))
	return "／".join(names)


static func _append_status_name(names: PackedStringArray, status_id: String, chance: float) -> void:
	var sid: String = status_id.strip_edges()
	if sid.is_empty() or chance <= 0.0:
		return
	var eff: Resource = DataRegistry.get_status_effect(sid)
	if eff == null:
		return
	var st_name: String = str(eff.display_name).strip_edges()
	if st_name.is_empty():
		return
	names.append(st_name)
