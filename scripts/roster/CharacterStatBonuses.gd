extends RefCounted

## キャラ個人ステ補正（P3-STAT-CHAR-001 案A）。
## ★帯に加算。最終組は一意。ATK/DEF差は抑えめ、差は主にHPで出す。
## 参照は preload（`GachaRarityConfig`）経由。

## メイン5（★3帯 +50/+18/+12 の上）
const STARTER_BONUS: Dictionary = {
	## アルド → 162/38/20
	"adventurer_0": {"hp": 12, "attack": 20, "defense": 8},
	## リーヴァ → 102/46/16
	"adventurer_1": {"hp": -48, "attack": 28, "defense": 4},
	## エリアス → 246/28/26
	"adventurer_2": {"hp": 96, "attack": 10, "defense": 14},
	## ガレン → 270/24/34
	"adventurer_3": {"hp": 120, "attack": 6, "defense": 22},
	## ミレイ → 186/34/18
	"adventurer_4": {"hp": 36, "attack": 16, "defense": 6},
}

## ガチャ助っ人（helper_id）。プール外★1も含む。
const HELPER_BONUS: Dictionary = {
	## ヴァルデン★4 → 274/32/36
	"helper_a": {"hp": 84, "attack": -8, "defense": 8},
	## イヴァル★2 → 100/40/22
	"helper_b": {"hp": -20, "attack": 32, "defense": 18},
	## セリン★3 → 228/26/30
	"helper_c": {"hp": 78, "attack": 8, "defense": 18},
	## レオン★1 → 108/36/22
	"helper_d": {"hp": 8, "attack": 36, "defense": 22},
	## ミラ★3 → 120/42/22
	"helper_e": {"hp": -30, "attack": 24, "defense": 10},
	## カイダ★2 → 104/44/10
	"helper_f": {"hp": -16, "attack": 36, "defense": 6},
	## ドランテ★1 → 148/26/24
	"helper_h": {"hp": 48, "attack": 26, "defense": 24},
	## ガルム★2 → 186/20/30
	"helper_i": {"hp": 66, "attack": 12, "defense": 26},
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
