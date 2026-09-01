extends RefCounted

## キャラ別レベル成長倍率（P3-BAL-GROWTH-H1-001）。
## 基礎伸び（BalanceConfig の HP/ATK/DEF per Lv）に乗算する。
## 未定義 id（ペット・プール外など）は 1.0。

const DEFAULT_MULT: Dictionary = {"hp": 1.0, "attack": 1.0, "defense": 1.0}

## スターター＋現行ガチャプール（オーナー承認表）。
const GROWTH_BY_ADVENTURER_ID: Dictionary = {
	"adventurer_0": {"hp": 1.00, "attack": 1.05, "defense": 1.00}, ## アルド
	"adventurer_1": {"hp": 0.90, "attack": 1.15, "defense": 0.85}, ## リーヴァ
	"adventurer_2": {"hp": 1.05, "attack": 0.90, "defense": 1.10}, ## エリアス
	"adventurer_3": {"hp": 1.15, "attack": 0.85, "defense": 1.20}, ## ガレン
	"adventurer_4": {"hp": 1.00, "attack": 1.00, "defense": 0.95}, ## ミレイ
	"gacha_helper_a": {"hp": 1.10, "attack": 0.90, "defense": 1.15}, ## ヴァルデン
	"gacha_helper_b": {"hp": 0.95, "attack": 1.10, "defense": 0.95}, ## イヴァル
	"gacha_helper_c": {"hp": 1.05, "attack": 0.90, "defense": 1.00}, ## セリン
	"gacha_helper_e": {"hp": 0.95, "attack": 1.10, "defense": 0.95}, ## ルーシェ
	"gacha_helper_f": {"hp": 0.90, "attack": 1.20, "defense": 0.85}, ## カイダ
	"gacha_helper_i": {"hp": 1.10, "attack": 0.90, "defense": 1.15}, ## ウォール
	"gacha_helper_k": {"hp": 0.85, "attack": 1.20, "defense": 0.80}, ## レノール
	"gacha_helper_m": {"hp": 1.00, "attack": 0.95, "defense": 0.95}, ## シアン
	"gacha_helper_n": {"hp": 1.05, "attack": 0.95, "defense": 1.10}, ## ボルグ
	"gacha_helper_o": {"hp": 0.95, "attack": 0.85, "defense": 0.95}, ## ネリ
	"gacha_helper_p": {"hp": 0.90, "attack": 1.25, "defense": 0.85}, ## 火鷹
	"gacha_helper_q": {"hp": 1.00, "attack": 1.05, "defense": 0.95}, ## トリム
	"gacha_helper_r": {"hp": 0.85, "attack": 1.15, "defense": 0.90}, ## ブラン
	"gacha_helper_s": {"hp": 0.95, "attack": 1.10, "defense": 0.90}, ## オルソ
}

## helper_id（gacha_ なし）からも引けるようにする。
const GROWTH_BY_HELPER_ID: Dictionary = {
	"helper_a": "gacha_helper_a",
	"helper_b": "gacha_helper_b",
	"helper_c": "gacha_helper_c",
	"helper_e": "gacha_helper_e",
	"helper_f": "gacha_helper_f",
	"helper_i": "gacha_helper_i",
	"helper_k": "gacha_helper_k",
	"helper_m": "gacha_helper_m",
	"helper_n": "gacha_helper_n",
	"helper_o": "gacha_helper_o",
	"helper_p": "gacha_helper_p",
	"helper_q": "gacha_helper_q",
	"helper_r": "gacha_helper_r",
	"helper_s": "gacha_helper_s",
}


static func normalize(raw: Dictionary) -> Dictionary:
	var out: Dictionary = DEFAULT_MULT.duplicate()
	if raw.is_empty():
		return out
	out["hp"] = maxf(0.0, float(raw.get("hp", 1.0)))
	out["attack"] = maxf(0.0, float(raw.get("attack", 1.0)))
	out["defense"] = maxf(0.0, float(raw.get("defense", 1.0)))
	return out


static func for_adventurer_id(adventurer_id: String) -> Dictionary:
	if adventurer_id.is_empty():
		return DEFAULT_MULT.duplicate()
	if GROWTH_BY_ADVENTURER_ID.has(adventurer_id):
		return normalize(GROWTH_BY_ADVENTURER_ID[adventurer_id])
	if adventurer_id.begins_with("gacha_"):
		return for_helper_id(adventurer_id.trim_prefix("gacha_"))
	return DEFAULT_MULT.duplicate()


static func for_helper_id(helper_id: String) -> Dictionary:
	if helper_id.is_empty():
		return DEFAULT_MULT.duplicate()
	if GROWTH_BY_HELPER_ID.has(helper_id):
		return for_adventurer_id(str(GROWTH_BY_HELPER_ID[helper_id]))
	var keyed: String = helper_id if helper_id.begins_with("helper_") else "helper_%s" % helper_id
	if GROWTH_BY_HELPER_ID.has(keyed):
		return for_adventurer_id(str(GROWTH_BY_HELPER_ID[keyed]))
	return DEFAULT_MULT.duplicate()


static func for_adventurer(member: Resource) -> Dictionary:
	if member == null:
		return DEFAULT_MULT.duplicate()
	return for_adventurer_id(str(member.id))
