class_name EnemyResistTelop
extends RefCounted
## T6/T7 被ダメ軽減の初回説明テロップ（P3-UX-ENEMY-RESIST-TELOP-001）。


const MSG_BASIC := "通常攻撃が通りにくい"
const MSG_SKILL := "スキルが通りにくい"


static func message(is_basic_attack: bool) -> String:
	return MSG_BASIC if is_basic_attack else MSG_SKILL


## 戦闘内一意キー（スロット × 通常/スキル）。
static func announce_key(slot: int, is_basic_attack: bool) -> String:
	return "%d:%s" % [slot, "basic" if is_basic_attack else "skill"]


static func should_announce(announced: Dictionary, slot: int, incoming_mult: float, is_basic_attack: bool) -> bool:
	if slot < 0:
		return false
	if incoming_mult >= 0.999:
		return false
	var key: String = announce_key(slot, is_basic_attack)
	return not announced.has(key)


static func mark_announced(announced: Dictionary, slot: int, is_basic_attack: bool) -> void:
	announced[announce_key(slot, is_basic_attack)] = true
