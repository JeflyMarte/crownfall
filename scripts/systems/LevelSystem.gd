class_name LevelSystem
extends RefCounted

## キャラクターのレベル制（P3-D035 / P3-LV-099）。
## EXP はラン成功時にパーティ全員へ付与。レベルアップで HP/ATK が成長する。
## Lv1〜50: +6HP/+2ATK、Lv51〜99: +3HP/+1ATK（スキル習得は Lv50 まで据置）。

const MAX_LEVEL: int = BalanceConfig.MAX_PLAYER_LEVEL
const SOFT_CAP_LEVEL: int = BalanceConfig.SOFT_CAP_LEVEL

## 成長値の正は BalanceConfig。static var なのはバランスシミュ（tools/balance_sim.gd）の
## sweep 検証で一時上書きするため。ゲーム本体からは書き換えない。
static var hp_per_level: int = BalanceConfig.HP_PER_LEVEL
static var attack_per_level: int = BalanceConfig.ATTACK_PER_LEVEL

## level → level+1 に必要な EXP。
static func exp_to_next(level: int) -> int:
	return 100 * maxi(1, level)

## 現在レベルでの累積 HP 成長ボーナス（Lv1 = 0）。
static func level_hp_bonus(level: int) -> int:
	var lv: int = maxi(1, level)
	if lv <= 1:
		return 0
	var primary_levels: int = mini(lv - 1, SOFT_CAP_LEVEL - 1)
	var bonus: int = hp_per_level * primary_levels
	if lv > SOFT_CAP_LEVEL:
		bonus += BalanceConfig.HP_PER_LEVEL_MASTER * (lv - SOFT_CAP_LEVEL)
	return bonus

## 現在レベルでの累積 ATK 成長ボーナス（Lv1 = 0）。
static func level_attack_bonus(level: int) -> int:
	var lv: int = maxi(1, level)
	if lv <= 1:
		return 0
	var primary_levels: int = mini(lv - 1, SOFT_CAP_LEVEL - 1)
	var bonus: int = attack_per_level * primary_levels
	if lv > SOFT_CAP_LEVEL:
		bonus += BalanceConfig.ATTACK_PER_LEVEL_MASTER * (lv - SOFT_CAP_LEVEL)
	return bonus

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
