extends RefCounted

## キャラ個人ステ補正（P3-STAT-CHAR-001 案A）。
## ★帯に加算。最終組は一意。ATK/DEF差は抑えめ（全体×8スケール）。
## 参照は preload（`GachaRarityConfig`）経由。

## メイン5（★3帯 +400/+144/+96 の上）
const STARTER_BONUS: Dictionary = {
	## アルド → 1296/304/160
	"adventurer_0": {"hp": 96, "attack": 160, "defense": 64},
	## リーヴァ → 816/368/128
	"adventurer_1": {"hp": -384, "attack": 224, "defense": 32},
	## エリアス → 1968/224/208
	"adventurer_2": {"hp": 768, "attack": 80, "defense": 112},
	## ガレン → 2160/192/272
	"adventurer_3": {"hp": 960, "attack": 48, "defense": 176},
	## ミレイ → 1488/272/144
	"adventurer_4": {"hp": 288, "attack": 128, "defense": 48},
}

## ガチャ助っ人（helper_id）。プール外★1も含む。
const HELPER_BONUS: Dictionary = {
	## ヴァルデン★4 → 2192/256/288
	"helper_a": {"hp": 672, "attack": -64, "defense": 64},
	## イヴァル★2 → 800/320/176
	"helper_b": {"hp": -160, "attack": 256, "defense": 144},
	## セリン★3 → 1824/208/240
	"helper_c": {"hp": 624, "attack": 64, "defense": 144},
	## レオン★1 → 864/288/176
	"helper_d": {"hp": 64, "attack": 288, "defense": 176},
	## ミラ★3 → 960/336/176
	"helper_e": {"hp": -240, "attack": 192, "defense": 80},
	## カイダ★2 → 832/352/80
	"helper_f": {"hp": -128, "attack": 288, "defense": 48},
	## ドランテ★1 → 1184/208/192
	"helper_h": {"hp": 384, "attack": 208, "defense": 192},
	## ガルム★2 → 1488/160/240
	"helper_i": {"hp": 528, "attack": 96, "defense": 208},
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
