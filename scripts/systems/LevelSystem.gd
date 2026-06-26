class_name LevelSystem
extends RefCounted

## キャラクターのレベル制（P3-D035）。
## EXP はラン成功時にパーティ全員へ付与。レベルアップで HP/ATK が成長する。
## 成長は CombatController（HP）/ DungeonScene（ATK）の flat 加算点で参照される。

const MAX_LEVEL: int = 20
const HP_PER_LEVEL: int = 6
const ATTACK_PER_LEVEL: int = 2

## level → level+1 に必要な EXP。
static func exp_to_next(level: int) -> int:
	return 100 * maxi(1, level)

## 現在レベルでの累積 HP 成長ボーナス（Lv1 = 0）。
static func level_hp_bonus(level: int) -> int:
	return HP_PER_LEVEL * maxi(0, level - 1)

## 現在レベルでの累積 ATK 成長ボーナス（Lv1 = 0）。
static func level_attack_bonus(level: int) -> int:
	return ATTACK_PER_LEVEL * maxi(0, level - 1)

## 単体に EXP を付与しレベルアップ処理。獲得レベル数を返す。
static func grant_exp(adventurer: Resource, amount: int) -> int:
	if adventurer == null or amount <= 0:
		return 0
	if adventurer.level >= MAX_LEVEL:
		adventurer.exp = 0
		return 0
	var gained: int = 0
	adventurer.exp += amount
	while adventurer.level < MAX_LEVEL and adventurer.exp >= exp_to_next(adventurer.level):
		adventurer.exp -= exp_to_next(adventurer.level)
		adventurer.level += 1
		gained += 1
	if adventurer.level >= MAX_LEVEL:
		adventurer.exp = 0
	return gained

## パーティ全員へ同量の EXP を付与。{ member_id: gained_levels } を返す（成長者のみ）。
static func grant_exp_to_party(amount: int) -> Dictionary:
	var result: Dictionary = {}
	for member in GameState.party_members:
		if member == null:
			continue
		var gained: int = grant_exp(member, amount)
		if gained > 0:
			result[member.id] = gained
	return result
