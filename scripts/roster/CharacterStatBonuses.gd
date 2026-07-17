extends RefCounted

## キャラ個人ステ補正（P3-STAT-CHAR-001 案A）。
## ★帯に加算。全キャラで最終 HP/ATK/DEF の組が一意。3桁見栄え用スケール。
## 参照は preload（`GachaRarityConfig`）経由。

## メイン5（★3帯 +50/+18/+12 の上）
const STARTER_BONUS: Dictionary = {
	## アルド: 高火力・標準耐久 → 約 162/78/20
	"adventurer_0": {"hp": 12, "attack": 60, "defense": 8},
	## リーヴァ: ガラス最高火力 → 約 102/102/10
	"adventurer_1": {"hp": -48, "attack": 84, "defense": -2},
	## エリアス: 高HP支援 → 約 246/12/42
	"adventurer_2": {"hp": 96, "attack": -6, "defense": 30},
	## ガレン: 重盾 → 約 270/14/90
	"adventurer_3": {"hp": 120, "attack": -4, "defense": 78},
	## ミレイ: 追撃火力 → 約 186/66/16
	"adventurer_4": {"hp": 36, "attack": 48, "defense": 4},
}

## ガチャ助っ人（helper_id）。プール外★1も含む。
const HELPER_BONUS: Dictionary = {
	## ヴァルデン★4: 重盾 → 約 274/24/118
	"helper_a": {"hp": 84, "attack": -16, "defense": 90},
	## イヴァル★2: 軽火力 → 約 100/62/14
	"helper_b": {"hp": -20, "attack": 54, "defense": 10},
	## セリン★3: 支援耐久 → 約 228/10/48
	"helper_c": {"hp": 78, "attack": -8, "defense": 36},
	## レオン★1: 軽火力 → 約 108/42/12
	"helper_d": {"hp": 8, "attack": 42, "defense": 12},
	## ミラ★3: 拘束火力 → 約 120/90/24
	"helper_e": {"hp": -30, "attack": 72, "defense": 12},
	## カイダ★2: 極ガラス砲 → 約 100/104/8
	"helper_f": {"hp": -20, "attack": 96, "defense": 4},
	## ドランテ★1: 軽耐久 → 約 148/12/24
	"helper_h": {"hp": 48, "attack": 12, "defense": 24},
	## ガルム★2: 盾 → 約 186/12/52
	"helper_i": {"hp": 66, "attack": 4, "defense": 48},
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
