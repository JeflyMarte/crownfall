class_name EnemyResistTelop
extends RefCounted
## T6/T7 被ダメ軽減パッシブ表示（P3-BAL-TRICKY-RESIST-A-001）。
## 軽減が実際に効いた攻撃のたびに短いパッシブ名を出す（P2）。


const PASSIVE_BASIC := "硬殻"
const PASSIVE_SKILL := "幻障"
## 互換・ログ用の長文。
const MSG_BASIC := "通常攻撃が通りにくい"
const MSG_SKILL := "スキルが通りにくい"


static func message(is_basic_attack: bool) -> String:
	return MSG_BASIC if is_basic_attack else MSG_SKILL


static func passive_name(is_basic_attack: bool) -> String:
	return PASSIVE_BASIC if is_basic_attack else PASSIVE_SKILL


## 軽減が効く攻撃か（×1未満）。
static func should_show_on_hit(incoming_mult: float) -> bool:
	return incoming_mult < 0.999


## 旧: 戦闘内初回のみ。P2 ではヒットごと表示に切替（互換のため残置）。
static func announce_key(slot: int, is_basic_attack: bool) -> String:
	return "%d:%s" % [slot, "basic" if is_basic_attack else "skill"]


static func should_announce(announced: Dictionary, slot: int, incoming_mult: float, is_basic_attack: bool) -> bool:
	if slot < 0:
		return false
	if not should_show_on_hit(incoming_mult):
		return false
	var key: String = announce_key(slot, is_basic_attack)
	return not announced.has(key)


static func mark_announced(announced: Dictionary, slot: int, is_basic_attack: bool) -> void:
	announced[announce_key(slot, is_basic_attack)] = true
