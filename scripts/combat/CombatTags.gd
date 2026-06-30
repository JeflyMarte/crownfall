class_name CombatTags
extends RefCounted

## シナジータグ正式定義（P3-D094）。武器/スキルの `tags` に付与し、
## 状態異常コンボの起爆条件（CombatCombos.require_tag）などの連携キーに用いる。
## ここがタグ id の SSOT。未知 id は無視（正規化）する。
##
## 物理: slash 斬撃 / pierce 刺突 / blunt 打撃
## 属性: fire 炎 / ice 氷 / lightning 雷 / holy 光 / dark 闇
## 効果: bleed 出血 / poison 毒 / buff 強化 / debuff 弱体

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
}

static func is_known(tag: String) -> bool:
	return _NAMES.has(tag)

static func display_name(tag: String) -> String:
	return str(_NAMES.get(tag, tag))

static func all_ids() -> Array:
	return _NAMES.keys()
