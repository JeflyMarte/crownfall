extends RefCounted

## キャラ個人ステ補正（P3-STAT-CHAR-001 案A）。
## ★帯に加算。最終組は一意。
## 初期バランス: ★序列（4>3>2>1）を合計で明確化。個差はだいたい50前後でバラす（綺麗な梯子にしない）。
## 参照は preload（`GachaRarityConfig`）経由。

## メイン5（★3帯の上）。最終表示値は HP/DEF×ALLY_STAT_BONUS_SCALE・ATK×ALLY_ATK_BONUS_SCALE 後。
const STARTER_BONUS: Dictionary = {
	## アルド → 補正後 1123/134/146
	"adventurer_0": {"hp": 81, "attack": 144, "defense": 93},
	## リーヴァ → 1008/161/97
	"adventurer_1": {"hp": -83, "attack": 213, "defense": 23},
	## エリアス → 1287/91/209
	"adventurer_2": {"hp": 316, "attack": 37, "defense": 183},
	## ガレン → 1348/76/239
	"adventurer_3": {"hp": 403, "attack": 1, "defense": 226},
	## ミレイ → 1169/113/122
	"adventurer_4": {"hp": 147, "attack": 93, "defense": 59},
}

## ガチャ助っ人（helper_id）。プール外★1も含む。
const HELPER_BONUS: Dictionary = {
	## ヴァルデン★4 → 1674/418/392
	"helper_a": {"hp": 94, "attack": 58, "defense": 102},
	## イヴァル★2 → 928/274/161
	"helper_b": {"hp": 28, "attack": 204, "defense": 116},
	## セリン★3 → 1438/246/271
	"helper_c": {"hp": 258, "attack": 56, "defense": 156},
	## レオン★1 → 853/239/129
	"helper_d": {"hp": 53, "attack": 239, "defense": 129},
	## ミラ★3 → 1194/361/186
	"helper_e": {"hp": 14, "attack": 171, "defense": 71},
	## カイダ★2 → 961/307/92
	"helper_f": {"hp": 61, "attack": 237, "defense": 47},
	## ドランテ★1 → 889/211/177
	"helper_h": {"hp": 89, "attack": 211, "defense": 177},
	## ガルム★2 → 1042/168/203
	"helper_i": {"hp": 142, "attack": 98, "defense": 158},
}


static func empty_bonus() -> Dictionary:
	return {"hp": 0, "attack": 0, "defense": 0}


static func normalize_bonus(raw: Dictionary) -> Dictionary:
	var out: Dictionary = empty_bonus()
	if raw.is_empty():
		return out
	out["hp"] = int(raw.get("hp", 0))
	out["attack"] = int(raw.get("attack", 0))
	out["defense"] = int(raw.get("defense", 0))
	return out


static func for_adventurer_id(adventurer_id: String) -> Dictionary:
	if adventurer_id.is_empty():
		return empty_bonus()
	if STARTER_BONUS.has(adventurer_id):
		return normalize_bonus(STARTER_BONUS[adventurer_id])
	if adventurer_id.begins_with("gacha_"):
		return for_helper_id(adventurer_id.trim_prefix("gacha_"))
	return empty_bonus()


static func for_helper_id(helper_id: String) -> Dictionary:
	if helper_id.is_empty():
		return empty_bonus()
	if HELPER_BONUS.has(helper_id):
		return normalize_bonus(HELPER_BONUS[helper_id])
	return empty_bonus()


static func for_adventurer(member: Resource) -> Dictionary:
	if member == null:
		return empty_bonus()
	return for_adventurer_id(str(member.id))
