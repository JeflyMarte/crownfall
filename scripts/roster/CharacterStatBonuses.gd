extends RefCounted

## キャラ個人ステ補正（P3-STAT-CHAR-001 案A）。
## ★帯ボーナスに加算する。値は小さく★序列を壊さない。
## 参照は preload（`GachaRarityConfig`）経由。

## メイン5（★3標準帯の上に乗る）
const STARTER_BONUS: Dictionary = {
	"adventurer_0": {"hp": 0, "attack": 2, "defense": 0}, ## アルド — 火力寄り
	"adventurer_1": {"hp": 0, "attack": 1, "defense": 0}, ## リーヴァ — 軽火力
	"adventurer_2": {"hp": 2, "attack": -1, "defense": 0}, ## エリアス — 耐久寄り
	"adventurer_3": {"hp": 3, "attack": -1, "defense": 2}, ## ガレン — 盾
	"adventurer_4": {"hp": 1, "attack": 1, "defense": 0}, ## ミレイ — 追撃寄り
}

## ガチャ助っ人（helper_id）。プール外★1も含む。
const HELPER_BONUS: Dictionary = {
	"helper_a": {"hp": 2, "attack": 0, "defense": 2}, ## ヴァルデン★4 — 盾
	"helper_b": {"hp": 0, "attack": 1, "defense": 0}, ## イヴァル★2
	"helper_c": {"hp": 2, "attack": -1, "defense": 0}, ## セリン★3 — 回復役
	"helper_d": {"hp": 0, "attack": 1, "defense": 0}, ## レオン★1
	"helper_e": {"hp": 0, "attack": 1, "defense": 0}, ## ミラ★3
	"helper_f": {"hp": -1, "attack": 2, "defense": 0}, ## カイダ★2 — ガラス
	"helper_h": {"hp": 1, "attack": 0, "defense": 0}, ## ドランテ★1
	"helper_i": {"hp": 2, "attack": 0, "defense": 1}, ## ガルム★2 — 盾
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
