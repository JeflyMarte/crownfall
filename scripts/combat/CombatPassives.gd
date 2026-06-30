class_name CombatPassives
extends RefCounted

## パッシブ / リアクション（P3-D088）。
## 共通フォーマット: Trigger → Condition → Effect → Cooldown。
## ジョブにパッシブ id を紐付け、戦闘イベントで発火する（DungeonScene がエンジン）。
##
## trigger: "on_combat_start" | "on_hit_taken" | "on_ally_death"
## condition: "always" | "self_hp_below"（value=HP割合）
## effect: "apply_status"（status_id / target="self"|"party"） | "heal"（value=回復量 / target="party"）
## cooldown: CT 秒（0 = 都度発火可。on_combat_start は実質1回）

const _DEFS: Dictionary = {
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
}

# ジョブ → パッシブ id。MVP は 1 ジョブ 1 パッシブ。
const _JOB_PASSIVES: Dictionary = {
	"vanguard": ["bulwark"],
	"swordsman": ["battle_fervor"],
	"ranger": ["battle_fervor"],
	"alchemist": ["field_medic"],
	"beast_tamer": ["pack_instinct"],
}

# 指定ジョブのパッシブ定義一覧（id 込み）を返す。
static func for_job(job_id: String) -> Array:
	var out: Array = []
	for pid in _JOB_PASSIVES.get(job_id, []):
		var def: Dictionary = _DEFS.get(str(pid), {}).duplicate()
		if def.is_empty():
			continue
		def["id"] = str(pid)
		out.append(def)
	return out
