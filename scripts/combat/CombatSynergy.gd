class_name CombatSynergy
extends RefCounted

## 同系統タグ・シナジー（P3-D095）。パーティの装備武器タグ(CombatTags)を集計し、
## 同じ属性タグを複数人で共有していると、その属性の与ダメにボーナスを付与する。
## 「炎で揃える」等のビルド選択に報酬を与える。物理/効果タグは対象外（MVP）。

const ELEMENT_TAGS: Array = ["fire", "ice", "lightning", "holy", "dark"]
const BONUS_TWO: float = 0.10   # 2人共有
const BONUS_THREE: float = 0.15 # 3人共有

# party 全員の装備武器タグから {element: bonus} を算出（2人未満の属性は含めない）。
static func compute_element_bonuses(members: Array) -> Dictionary:
	var counts: Dictionary = {}
	for m in members:
		if m == null:
			continue
		for t: String in _member_weapon_tags(m):
			if t in ELEMENT_TAGS:
				counts[t] = int(counts.get(t, 0)) + 1
	var out: Dictionary = {}
	for e: String in counts:
		var c: int = int(counts[e])
		if c >= 3:
			out[e] = BONUS_THREE
		elif c >= 2:
			out[e] = BONUS_TWO
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
