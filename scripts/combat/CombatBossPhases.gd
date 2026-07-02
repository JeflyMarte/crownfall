class_name CombatBossPhases
extends RefCounted

## ボス戦フェーズ移行（P3-D116）。HP 閾値で形態が変わり、スキル率・攻撃力が変化する。
## カタログはコード内静的定義（MVP＝serdion のみ）。図鑑は目撃したフェーズのみ開示。

const _DEFS: Dictionary = {
	"serdion": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.40,
			"attack_mult": 1.0,
		},
		{
			"threshold": 0.50,
			"label": "第2形態・激昂",
			"skill_use_chance": 0.55,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】セルディオンが激昂した！",
		},
		{
			"threshold": 0.25,
			"label": "第3形態・断罪",
			"skill_use_chance": 0.70,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】断罪の波動が倍加する！",
			"skill_weight": {"boss_decree_wave": 2.0, "enemy_serdion_roar": 2.0},
		},
	],
	"granvel": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.40,
			"attack_mult": 1.0,
		},
		{
			"threshold": 0.50,
			"label": "第2形態・森の怒り",
			"skill_use_chance": 0.55,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】グランヴェルの体表で根と蔓が荒れ狂う！",
		},
		{
			"threshold": 0.25,
			"label": "第3形態・大森の化身",
			"skill_use_chance": 0.70,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】森そのものがグランヴェルに力を注ぐ！",
			"skill_weight": {"enemy_granvel_verdant_wave": 2.0, "enemy_granvel_bramble_crush": 2.0},
		},
	],
}

static func has_phases(enemy_id: String) -> bool:
	return _DEFS.has(enemy_id)

static func phase_count(enemy_id: String) -> int:
	return (_DEFS.get(enemy_id, []) as Array).size()

static func phase_def(enemy_id: String, phase_index: int) -> Dictionary:
	var phases: Array = _DEFS.get(enemy_id, [])
	if phase_index < 0 or phase_index >= phases.size():
		return {}
	return phases[phase_index]

# 現在 HP 割合からフェーズ index を決定（閾値以下の最大段階）。
static func resolve_phase_index(enemy_id: String, hp_ratio: float) -> int:
	var phases: Array = _DEFS.get(enemy_id, [])
	if phases.is_empty():
		return 0
	var idx: int = 0
	for i: int in phases.size():
		if hp_ratio <= float(phases[i].get("threshold", 1.0)):
			idx = i
	return idx

static func attack_mult(enemy_id: String, phase_index: int) -> float:
	return float(phase_def(enemy_id, phase_index).get("attack_mult", 1.0))

static func skill_use_chance(enemy_id: String, phase_index: int, fallback: float) -> float:
	var def: Dictionary = phase_def(enemy_id, phase_index)
	if def.is_empty():
		return fallback
	return float(def.get("skill_use_chance", fallback))

# 図鑑 stage5 用。目撃済みフェーズのみラベル開示（第1形態は常時）。
static func codex_phase_text(enemy_id: String, phases_seen: Array) -> String:
	if not has_phases(enemy_id):
		return ""
	var phases: Array = _DEFS[enemy_id]
	var parts: PackedStringArray = []
	for i: int in phases.size():
		var p: Dictionary = phases[i]
		if i == 0 or i in phases_seen:
			var th: float = float(p.get("threshold", 1.0))
			var suffix: String = "開始" if i == 0 else "HP≤%d%%" % int(round(th * 100.0))
			parts.append("%s（%s）" % [str(p.get("label", "")), suffix])
		else:
			parts.append("？？？")
	return "フェーズ: %s" % " → ".join(parts)
