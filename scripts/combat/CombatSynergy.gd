class_name CombatSynergy
extends RefCounted

## 同系統タグ・シナジー（P3-D095）。パーティの装備武器タグ(CombatTags)を集計し、
## 同じ属性タグを複数人で共有していると、その属性の与ダメにボーナスを付与する。
## 「炎で揃える」等のビルド選択に報酬を与える。物理/効果タグは対象外（MVP）。

# 属性 id は ElementResolver（ダメージ SSOT）に揃える。タグ空間の "lightning" は
# 攻撃属性 "thunder" と同一物なので集計時に正規化する（P3-D099 整合修正）。
const ELEMENT_TAGS: Array = ["fire", "ice", "thunder", "holy", "dark"]
const _ELEMENT_TAG_ALIAS: Dictionary = {"lightning": "thunder"}
const BONUS_TWO: float = 0.10   # 2人共有
const BONUS_THREE: float = 0.15 # 3人共有

# party 全員の装備武器タグから {element: bonus} を算出（2人未満の属性は含めない）。
# キーは ElementResolver id（attack_element と一致する）。
static func compute_element_bonuses(members: Array) -> Dictionary:
	var counts: Dictionary = {}
	for m in members:
		if m == null:
			continue
		for t: String in _member_weapon_tags(m):
			var e: String = str(_ELEMENT_TAG_ALIAS.get(t, t))
			if e in ELEMENT_TAGS:
				counts[e] = int(counts.get(e, 0)) + 1
	var out: Dictionary = {}
	for e: String in counts:
		var c: int = int(counts[e])
		if c >= 3:
			out[e] = BONUS_THREE
		elif c >= 2:
			out[e] = BONUS_TWO
	return out

# ---- ロールボーナス / 物理タグシナジー（P3-D097） ----

const PHYSICAL_TAGS: Array = ["slash", "pierce", "blunt"]
const SYNERGY_THRESHOLD: int = 2
const PHYS_BONUS_TWO: float = 0.05
const PHYS_BONUS_THREE: float = 0.08

# 物理タグ（斬/刺/打）を 2人以上で共有していると全員の与ダメに加わるフラットボーナス（最大値を採用）。
static func compute_physical_bonus(members: Array) -> float:
	var counts: Dictionary = {}
	for m in members:
		if m == null:
			continue
		for t: String in _member_weapon_tags(m):
			if t in PHYSICAL_TAGS:
				counts[t] = int(counts.get(t, 0)) + 1
	var best: float = 0.0
	for t: String in counts:
		var c: int = int(counts[t])
		if c >= 3:
			best = maxf(best, PHYS_BONUS_THREE)
		elif c >= 2:
			best = maxf(best, PHYS_BONUS_TWO)
	return best

# ロール（tank/dps/support/scout）を 2人以上で共有すると編成ボーナス。
# 戻り値: {incoming_mult, outgoing_mult, heal_mult, crit_add, labels}
static func compute_role_bonuses(members: Array) -> Dictionary:
	var counts: Dictionary = {}
	for m in members:
		if m == null:
			continue
		var role: String = str(JobStatCalculator.get_member_modifiers(m).get("role", ""))
		if role.is_empty():
			continue
		counts[role] = int(counts.get(role, 0)) + 1
	var out: Dictionary = {
		"incoming_mult": 1.0, "outgoing_mult": 1.0,
		"heal_mult": 1.0, "crit_add": 0.0, "labels": [],
	}
	if int(counts.get("tank", 0)) >= SYNERGY_THRESHOLD:
		out["incoming_mult"] *= 0.92
		out["labels"].append("堅守 被ダメ-8%")
	if int(counts.get("dps", 0)) >= SYNERGY_THRESHOLD:
		out["outgoing_mult"] *= 1.06
		out["labels"].append("攻勢 与ダメ+6%")
	if int(counts.get("support", 0)) >= SYNERGY_THRESHOLD:
		out["heal_mult"] *= 1.20
		out["labels"].append("治癒 回復+20%")
	if int(counts.get("scout", 0)) >= SYNERGY_THRESHOLD:
		out["crit_add"] += 0.08
		out["labels"].append("索敵 会心+8%")
	return out

static func _member_weapon_tags(member: Resource) -> Array:
	var winst: Resource = member.equipped_weapon
	if winst == null or str(winst.weapon_id).is_empty():
		return []
	var wd: Resource = DataRegistry.get_weapon_data(winst.weapon_id)
	if wd == null or not ("tags" in wd):
		return []
	var out: Array = []
	for t in wd.tags:
		out.append(str(t))
	return out
