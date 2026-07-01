class_name RosterUiHelper
extends RefCounted

const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")
const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")

const BASE_MEMBER_HP: int = 30

const ROLE_LABELS: Dictionary = {
	"dps": "アタッカー",
	"tank": "タンク",
	"scout": "斥候",
	"support": "サポート",
}

const ROLE_GLYPHS: Dictionary = {
	"dps": "⚔",
	"tank": "🛡",
	"scout": "🏹",
	"support": "✚",
}

const ROLE_FILTER_LABELS: Dictionary = {
	"all": "全職",
	"tank": "タンク",
	"dps": "アタッカー",
	"scout": "斥候",
	"support": "サポート",
}

static func leader_skill_display(member: Resource) -> Dictionary:
	if member == null:
		return {"name": "—", "description": "リーダーを編成してください。"}
	var passives: Array = CombatPassives.for_member(member)
	if passives.is_empty():
		return {"name": "—", "description": "リーダー効果はありません。"}
	var def: Dictionary = passives[0]
	return {
		"name": str(def.get("display_name", "—")),
		"description": passive_description(def),
	}

static func passive_description(def: Dictionary) -> String:
	var effect: String = str(def.get("effect", ""))
	var target: String = str(def.get("target", "self"))
	match effect:
		"heal":
			return "味方が倒れたとき、パーティを回復する。"
		"apply_status":
			var status_id: String = str(def.get("status_id", ""))
			var status_name: String = _status_label(status_id)
			if target == "party":
				return "味方が倒れたとき、パーティに%sを付与する。" % status_name
			if str(def.get("trigger", "")) == "on_combat_start":
				return "戦闘開始時、自身に%sを付与する。" % status_name
			if str(def.get("condition", "")) == "self_hp_below":
				return "HPが低下したとき、自身に%sを付与する。" % status_name
			return "条件を満たすと%sを付与する。" % status_name
	return "編成時に発動するリーダー特性（表示のみ）。"

static func _status_label(status_id: String) -> String:
	match status_id:
		"empower":
			return "鼓舞"
		"guard":
			return "防御"
		_:
			return status_id

static func stat_line(label: String, value: int) -> String:
	return "%s %d" % [label, value]

static func short_display_name(full_name: String) -> String:
	var text: String = str(full_name)
	var idx: int = text.find("（")
	if idx > 0:
		return text.substr(0, idx)
	return text

static func role_label(role: String) -> String:
	return str(ROLE_LABELS.get(role, role))

static func role_glyph(role: String) -> String:
	return str(ROLE_GLYPHS.get(role, "◆"))

static func stars_text(rarity: int) -> String:
	var count: int = clampi(rarity, 1, 5)
	var out: String = ""
	for _i in count:
		out += "★"
	return out

static func compute_combat_power(members: Array) -> int:
	var total: int = 0
	for member in members:
		if member == null:
			continue
		var stats: Dictionary = compute_member_stats(member, -1)
		total += int(stats.get("attack", 0))
		total += int(stats.get("defense", 0))
		total += int(stats.get("hp", 0))
	return total

static func compute_member_stats(member: Resource, party_index: int = -1) -> Dictionary:
	if member == null:
		return {"hp": 0, "attack": 0, "defense": 0}
	var weapon: Resource = member.equipped_weapon if "equipped_weapon" in member else null
	var armor: Resource = member.equipped_armor if "equipped_armor" in member else null
	var accessory: Resource = member.equipped_accessory if "equipped_accessory" in member else null
	var acc_data: Resource = null
	if accessory != null and not str(accessory.accessory_id).is_empty():
		acc_data = DataRegistry.get_accessory_data(str(accessory.accessory_id))
	var affix: Dictionary = (
		_AffixStatCalculator.get_bonuses(party_index)
		if party_index >= 0
		else _affixes_for_member(member)
	)
	var job: Dictionary = _JobStatCalculator.get_member_modifiers(member)
	var level: int = int(member.level)
	var hp: int = BASE_MEMBER_HP
	if armor != null:
		hp += int(armor.hp_bonus)
	if acc_data != null:
		hp += int(acc_data.hp_bonus)
	hp += int(affix.get("hp_flat", 0))
	hp += LevelSystem.level_hp_bonus(level)
	hp = int(round(float(hp) * float(job.get("hp_multiplier", 1.0))))
	var attack: int = 0
	if weapon != null:
		attack = _EquipmentEnhancer.get_effective_attack(weapon)
	if acc_data != null:
		attack += int(acc_data.attack_bonus)
	attack += int(affix.get("attack_flat", 0))
	attack += LevelSystem.level_attack_bonus(level)
	var atk_mult: float = float(job.get("attack_multiplier", 1.0))
	if weapon != null:
		atk_mult *= _JobStatCalculator.get_preferred_weapon_multiplier(
			member, DataRegistry.get_weapon_data(str(weapon.weapon_id))
		)
	attack = int(round(float(attack) * atk_mult))
	var defense: int = 0
	if armor != null:
		defense = int(armor.rolled_defense)
	if acc_data != null:
		defense += int(acc_data.defense_bonus)
	defense += int(affix.get("defense_flat", 0))
	defense = int(round(float(defense) * float(job.get("defense_multiplier", 1.0))))
	return {"hp": hp, "attack": attack, "defense": defense}

static func _affixes_for_member(member: Resource) -> Dictionary:
	var bonuses: Dictionary = {
		"attack_flat": 0,
		"defense_flat": 0,
		"hp_flat": 0,
	}
	for item in [member.equipped_weapon, member.equipped_armor, member.equipped_accessory]:
		if item == null or not bool(item.is_appraised):
			continue
		for affix_id in item.prefix_ids:
			_apply_affix_flat(bonuses, str(affix_id))
		if "suffix_ids" in item:
			for affix_id in item.suffix_ids:
				_apply_affix_flat(bonuses, str(affix_id))
	return bonuses

static func _apply_affix_flat(bonuses: Dictionary, affix_id: String) -> void:
	if affix_id.is_empty():
		return
	var affix_data: Resource = DataRegistry.get_affix_data(affix_id)
	if affix_data == null:
		return
	match str(affix_data.stat_type):
		"Attack":
			bonuses["attack_flat"] = int(bonuses.get("attack_flat", 0)) + int(affix_data.value)
		"Defense":
			bonuses["defense_flat"] = int(bonuses.get("defense_flat", 0)) + int(affix_data.value)
		"HP":
			bonuses["hp_flat"] = int(bonuses.get("hp_flat", 0)) + int(affix_data.value)

static func card_panel_style(active: bool, leader: bool) -> StyleBox:
	var tier: String = CombatUiFrames.TIER_CARD_ACTIVE if active else CombatUiFrames.TIER_CARD
	var style: StyleBox = CombatUiFrames.panel_style(tier)
	if leader and style is StyleBoxTexture:
		(style as StyleBoxTexture).modulate_color = Color(1.1, 0.92, 0.42, 1.0)
	return style
