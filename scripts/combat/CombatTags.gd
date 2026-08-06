class_name CombatTags
extends RefCounted

## シナジータグ正式定義（P3-D094）。武器/スキルの `tags` に付与し、
## 状態異常コンボの起爆条件（CombatCombos.require_tag）などの連携キーに用いる。
## ここがタグ id の SSOT。未知 id は無視（正規化）する。
##
## 物理: slash 斬撃 / pierce 刺突 / blunt 打撃
## 属性: fire 炎 / ice 氷 / lightning 雷 / holy 光 / dark 闇
## 効果: bleed 出血 / poison 毒 / buff 強化 / debuff 弱体 / shield 防御 / heal 回復 / drain 吸収
##
## ダメージ属性 SSOT は ElementResolver の thunder。タグ空間は lightning。
## 誤記 thunder は normalize で lightning へ寄せる（P3-FIX-COMBAT-AUDIT-C-001）。

const _NAMES: Dictionary = {
	"slash": "斬撃",
	"pierce": "刺突",
	"blunt": "打撃",
	"fire": "炎",
	"ice": "氷",
	"lightning": "雷",
	"holy": "光",
	"dark": "闇",
	"bleed": "出血",
	"poison": "毒",
	"buff": "強化",
	"debuff": "弱体",
	"shield": "防御",
	"heal": "回復",
	"drain": "吸収",
	"ultimate": "必殺",
}

## データ誤記・ElementResolver id 混入の正規化（タグ SSOT へ）。
const _ALIASES: Dictionary = {
	"thunder": "lightning",
}

static func normalize(tag: String) -> String:
	var raw: String = str(tag)
	return str(_ALIASES.get(raw, raw))

static func is_known(tag: String) -> bool:
	return _NAMES.has(normalize(tag))

static func display_name(tag: String) -> String:
	var id: String = normalize(tag)
	return str(_NAMES.get(id, tag))

static func all_ids() -> Array:
	return _NAMES.keys()
