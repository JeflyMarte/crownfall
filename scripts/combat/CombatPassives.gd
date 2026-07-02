class_name CombatPassives
extends RefCounted

## パッシブ / リアクション（P3-D088）。
## 共通フォーマット: Trigger → Condition → Effect → Cooldown。
## 基本5職ロスターはキャラ固有パッシブを優先、それ以外はジョブフォールバック。
##
## trigger: "on_combat_start" | "on_hit_taken" | "on_ally_death"
## condition: "always" | "self_hp_below"（value=HP割合）
## effect: "apply_status"（status_id / target="self"|"party"） | "heal"（value=回復量 / target="party"）
## cooldown: CT 秒（0 = 都度発火可。on_combat_start は実質1回）

const _DEFS: Dictionary = {
	# ---- 基本5職キャラ固有 ----
	"ald_royal_flame": {
		"display_name": "王炎の覇気",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "self",
		"cooldown": 0.0,
	},
	"riva_lone_focus": {
		"display_name": "孤高の集中",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "self",
		"cooldown": 0.0,
	},
	"elias_field_elixir": {
		"display_name": "野戦調合",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "heal", "target": "party", "value": 15,
		"cooldown": 0.0,
	},
	"galen_sacred_bastion": {
		"display_name": "聖盾の砦",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below", "value": 0.5,
		"effect": "apply_status", "status_id": "guard", "target": "self",
		"cooldown": 6.0,
	},
	"mirei_swarm_resonance": {
		"display_name": "群響の絆",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "party",
		"cooldown": 0.0,
	},
	# ---- ジョブフォールバック（非基本ロスター・助っ人等） ----
	"bulwark": {
		"display_name": "鉄壁",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below", "value": 0.5,
		"effect": "apply_status", "status_id": "guard", "target": "self",
		"cooldown": 6.0,
	},
	"battle_fervor": {
		"display_name": "高揚",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "self",
		"cooldown": 0.0,
	},
	"field_medic": {
		"display_name": "野戦救護",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "heal", "target": "party", "value": 12,
		"cooldown": 0.0,
	},
	"pack_instinct": {
		"display_name": "群れの本能",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "party",
		"cooldown": 0.0,
	},
	# ---- ガチャ助っ人固有（P3-GACHA-005） ----
	"leon_sword_focus": {
		"display_name": "剣勢の集中",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "self",
		"cooldown": 0.0,
	},
	"ivar_trail_sight": {
		"display_name": "狩場の目",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "self",
		"cooldown": 0.0,
	},
	"serin_quick_mend": {
		"display_name": "応急調合",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "heal", "target": "party", "value": 14,
		"cooldown": 0.0,
	},
	"mira_beast_call": {
		"display_name": "獣呼びの絆",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "party",
		"cooldown": 0.0,
	},
	"valden_iron_oath": {
		"display_name": "鉄誓の守護",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below", "value": 0.5,
		"effect": "apply_status", "status_id": "guard", "target": "self",
		"cooldown": 5.0,
	},
	# ---- ジョブフォールバック補完（P3-D155） ----
	"foresight": {
		"display_name": "先読み",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "guard", "target": "self",
		"cooldown": 0.0,
	},
	# ---- ★3 職固有（P3-D155 / P3-GACHA-006） ----
	"sword_charge": {
		"display_name": "剣気充填",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "self",
		"cooldown": 0.0,
	},
	"wind_reading": {
		"display_name": "風読み",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below", "value": 0.5,
		"effect": "apply_status", "status_id": "guard", "target": "self",
		"cooldown": 8.0,
	},
	"spare_vial": {
		"display_name": "予備薬瓶",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below", "value": 0.5,
		"effect": "heal", "target": "self", "heal_value": 12,
		"cooldown": 10.0,
	},
	"unyielding_stance": {
		"display_name": "不屈の構え",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below", "value": 0.35,
		"effect": "apply_status", "status_id": "guard", "target": "self",
		"cooldown": 6.0,
	},
	"tamer_whistle": {
		"display_name": "手懐けの笛",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "self",
		"cooldown": 0.0,
	},
	# ---- ★4 職固有（P3-D155 / P3-GACHA-006） ----
	"royal_sword_doctrine": {
		"display_name": "王軍剣範",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "party",
		"cooldown": 0.0,
	},
	"formation_eye": {
		"display_name": "隊列の眼",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "party",
		"cooldown": 0.0,
	},
	"panacea_gift": {
		"display_name": "万能薬進呈",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "heal", "target": "party", "value": 20,
		"cooldown": 0.0,
	},
	"greatshield_order": {
		"display_name": "大盾の号令",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below", "value": 0.5,
		"effect": "apply_status", "status_id": "guard", "target": "party",
		"cooldown": 12.0,
	},
	"herd_king_roar": {
		"display_name": "群王の咆哮",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "party",
		"cooldown": 0.0,
	},
}

# 基本5職ロスター adventurer_id → キャラ固有パッシブ id
const _BASE_ROSTER_PASSIVES: Dictionary = {
	"adventurer_0": "ald_royal_flame",
	"adventurer_1": "riva_lone_focus",
	"adventurer_2": "elias_field_elixir",
	"adventurer_3": "galen_sacred_bastion",
	"adventurer_4": "mirei_swarm_resonance",
}

# ジョブ → パッシブ id（基本ロスター以外のフォールバック）
const _JOB_PASSIVES: Dictionary = {
	"vanguard": ["bulwark"],
	"swordsman": ["battle_fervor"],
	"ranger": ["foresight"],
	"alchemist": ["field_medic"],
	"beast_tamer": ["pack_instinct"],
}

# ★3 / ★4 ガチャ冒険者の職固有パッシブ（P3-D155 / P3-GACHA-006）。
# ★1〜2 は付与なし（初期ステ差のみ）。★4 は ★4 定義のみ（★3 と重複付与しない）。
const _STAR3_JOB_PASSIVES: Dictionary = {
	"swordsman": "sword_charge",
	"ranger": "wind_reading",
	"alchemist": "spare_vial",
	"vanguard": "unyielding_stance",
	"beast_tamer": "tamer_whistle",
}
const _STAR4_JOB_PASSIVES: Dictionary = {
	"swordsman": "royal_sword_doctrine",
	"ranger": "formation_eye",
	"alchemist": "panacea_gift",
	"vanguard": "greatshield_order",
	"beast_tamer": "herd_king_roar",
}

# レア度に応じた職固有ティアパッシブ定義（該当なしは空 Dictionary）。
static func tier_def_for(job_id: String, rarity: int) -> Dictionary:
	if rarity >= 4:
		return _def_with_id(str(_STAR4_JOB_PASSIVES.get(job_id, "")))
	if rarity == 3:
		return _def_with_id(str(_STAR3_JOB_PASSIVES.get(job_id, "")))
	return {}

static func _def_with_id(passive_id: String) -> Dictionary:
	var def: Dictionary = _DEFS.get(passive_id, {}).duplicate()
	if def.is_empty():
		return {}
	def["id"] = passive_id
	return def

# 指定メンバーのパッシブ定義一覧（スターターはキャラ固有、ガチャは helper.passive_id、他はジョブ）。
# ガチャ冒険者は ★3/★4 で職固有ティアパッシブを追加付与する（P3-D155 / P3-GACHA-006）。
static func for_member(member: Resource) -> Array:
	if member == null:
		return []
	var adv_id: String = str(member.id)
	if _BASE_ROSTER_PASSIVES.has(adv_id):
		var char_def: Dictionary = _def_with_id(str(_BASE_ROSTER_PASSIVES[adv_id]))
		if not char_def.is_empty():
			return [char_def]
	var out: Array = []
	if adv_id.begins_with("gacha_"):
		var helper: Resource = DataRegistry.get_gacha_helper_data(adv_id.trim_prefix("gacha_"))
		if helper != null and not str(helper.passive_id).is_empty():
			var helper_def: Dictionary = _def_with_id(str(helper.passive_id))
			if not helper_def.is_empty():
				out.append(helper_def)
	if out.is_empty():
		out = for_job(str(member.job_id))
	var rarity: int = int(member.rarity) if "rarity" in member else 0
	var tier_def: Dictionary = tier_def_for(str(member.job_id), rarity)
	if not tier_def.is_empty():
		out.append(tier_def)
	return out

# 指定ジョブのパッシブ定義一覧（id 込み）を返す。
static func for_job(job_id: String) -> Array:
	var out: Array = []
	for pid in _JOB_PASSIVES.get(job_id, []):
		var def: Dictionary = _def_with_id(str(pid))
		if def.is_empty():
			continue
		out.append(def)
	return out
