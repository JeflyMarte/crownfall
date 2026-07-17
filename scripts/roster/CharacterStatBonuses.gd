extends RefCounted

## キャラ個人ステ補正（P3-STAT-CHAR-001 案A）。
## ★帯に加算。全キャラで最終 HP/ATK/DEF の組が重複しないよう個別定義。
## 参照は preload（`GachaRarityConfig`）経由。

## メイン5（★3帯 +14/+5/+3 の上）
const STARTER_BONUS: Dictionary = {
	## アルド: 高火力・標準耐久
	"adventurer_0": {"hp": 4, "attack": 20, "defense": 2},
	## リーヴァ: 超ガラス・最高火力寄り
	"adventurer_1": {"hp": -16, "attack": 28, "defense": -4},
	## エリアス: 高HP・低攻撃・中防御
	"adventurer_2": {"hp": 32, "attack": -14, "defense": 10},
	## ガレン: 最高HP・最低攻撃・最高防御
	"adventurer_3": {"hp": 40, "attack": -16, "defense": 26},
	## ミレイ: 中高HP・高攻撃・低防御
	"adventurer_4": {"hp": 12, "attack": 16, "defense": -2},
}

## ガチャ助っ人（helper_id）。プール外★1も含む。
const HELPER_BONUS: Dictionary = {
	## ヴァルデン★4: 重盾（高HP/高DEF）
	"helper_a": {"hp": 28, "attack": -12, "defense": 30},
	## イヴァル★2: 軽快火力
	"helper_b": {"hp": -8, "attack": 18, "defense": 2},
	## セリン★3: 支援耐久（高HP・低ATK）
	"helper_c": {"hp": 26, "attack": -12, "defense": 12},
	## レオン★1: 素直な軽火力
	"helper_d": {"hp": 2, "attack": 14, "defense": 0},
	## ミラ★3: 拘束火力（中低HP・高ATK）
	"helper_e": {"hp": -10, "attack": 24, "defense": 4},
	## カイダ★2: 極ガラス砲
	"helper_f": {"hp": -20, "attack": 32, "defense": -6},
	## ドランテ★1: 軽耐久・低攻撃
	"helper_h": {"hp": 16, "attack": -6, "defense": 8},
	## ガルム★2: 盾（高HP/中DEF）
	"helper_i": {"hp": 22, "attack": -8, "defense": 16},
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
