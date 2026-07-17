extends RefCounted

## キャラ個人ステ補正（P3-STAT-CHAR-001 案A）。
## ★帯ボーナスに加算。差を明確にしつつロール個性を出す。
## 参照は preload（`GachaRarityConfig`）経由。

## メイン5（★3標準帯の上に乗る）
const STARTER_BONUS: Dictionary = {
	"adventurer_0": {"hp": 0, "attack": 5, "defense": 0}, ## アルド — 火力
	"adventurer_1": {"hp": -2, "attack": 4, "defense": 0}, ## リーヴァ — ガラス火力
	"adventurer_2": {"hp": 6, "attack": -3, "defense": 1}, ## エリアス — 耐久／支援
	"adventurer_3": {"hp": 10, "attack": -3, "defense": 5}, ## ガレン — 重盾
	"adventurer_4": {"hp": 2, "attack": 3, "defense": 0}, ## ミレイ — 追撃寄り
}

## ガチャ助っ人（helper_id）。プール外★1も含む。
const HELPER_BONUS: Dictionary = {
	"helper_a": {"hp": 8, "attack": -2, "defense": 6}, ## ヴァルデン★4 — 重盾
	"helper_b": {"hp": 0, "attack": 3, "defense": 0}, ## イヴァル★2 — 軽火力
	"helper_c": {"hp": 6, "attack": -3, "defense": 1}, ## セリン★3 — 支援
	"helper_d": {"hp": 0, "attack": 2, "defense": 0}, ## レオン★1 — 軽火力
	"helper_e": {"hp": 0, "attack": 4, "defense": 0}, ## ミラ★3 — 拘束火力
	"helper_f": {"hp": -4, "attack": 6, "defense": -1}, ## カイダ★2 — ガラス砲
	"helper_h": {"hp": 3, "attack": -1, "defense": 0}, ## ドランテ★1 — 軽耐久
	"helper_i": {"hp": 6, "attack": -1, "defense": 3}, ## ガルム★2 — 盾
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
