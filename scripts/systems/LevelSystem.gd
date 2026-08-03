class_name LevelSystem
extends RefCounted

## キャラクターのレベル制（P3-D035 / P3-LV-099）。
## EXP はラン成功／敗北時に付与。撃破時点の生存者のみ積立（P3-BAL-DEAD-EXP-001）。
## レベルアップで HP/ATK が成長する。
## Lv1〜50: BalanceConfig.HP/ATTACK_PER_LEVEL、Lv51〜99: *_MASTER（スキル習得は Lv50 まで据置）。
##
## `-s` ツール（balance_sim）から load されてもパースできるよう、autoload / 他 class_name は
## 実行時解決する（P3-BAL-EXP-001-G）。

const MAX_LEVEL: int = BalanceConfig.MAX_PLAYER_LEVEL
const SOFT_CAP_LEVEL: int = BalanceConfig.SOFT_CAP_LEVEL

## 成長値の正は BalanceConfig。static var なのはバランスシミュ（tools/balance_sim.gd）の
## sweep 検証で一時上書きするため。ゲーム本体からは書き換えない。
static var hp_per_level: int = BalanceConfig.HP_PER_LEVEL
static var attack_per_level: int = BalanceConfig.ATTACK_PER_LEVEL

static func _game_state() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("GameState")

static func _combat_passives() -> GDScript:
	return load("res://scripts/combat/CombatPassives.gd") as GDScript

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
	var exp_mult: float = 1.0
	var gs: Node = _game_state()
	var passives: GDScript = _combat_passives()
	if gs != null and passives != null:
		var party: Array = gs.party_members
		for member in party:
			if member == adventurer:
				var idx: int = party.find(member)
				if idx >= 0:
					var mods: Dictionary = passives.skill_stat_modifiers_for_member(idx)
					exp_mult = float(mods.get("exp_gain_mult", 1.0))
				break
		exp_mult *= float(passives.party_exp_mult())
	var gained: int = 0
	adventurer.exp += maxi(0, int(round(float(amount) * exp_mult)))
	while adventurer.level < MAX_LEVEL and adventurer.exp >= exp_to_next(adventurer.level):
		adventurer.exp -= exp_to_next(adventurer.level)
		adventurer.level += 1
		gained += 1
	if adventurer.level >= MAX_LEVEL:
		adventurer.exp = 0
	return gained

## パーティ全員へ同量の EXP を付与。{ member_id: gained_levels } を返す（成長者のみ）。
static func grant_exp_to_party(amount: int) -> Dictionary:
	var by_member: Dictionary = {}
	var gs: Node = _game_state()
	if gs == null:
		return {}
	for member in gs.party_members:
		if member == null:
			continue
		by_member[str(member.id)] = amount
	if gs.active_pet != null:
		by_member[str(gs.active_pet.id)] = amount
	return grant_exp_by_member(by_member)


## メンバー別 EXP を付与。{ member_id: gained_levels }（成長者のみ）。
static func grant_exp_by_member(exp_by_member: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var gs: Node = _game_state()
	if gs == null or exp_by_member.is_empty():
		return result
	for member in gs.party_members:
		if member == null:
			continue
		var mid: String = str(member.id)
		var amount: int = int(exp_by_member.get(mid, 0))
		if amount <= 0:
			continue
		var gained: int = grant_exp(member, amount)
		if gained > 0:
			result[mid] = gained
	## 随伴ペットも個別積立分のみ（P3-PET-OTOMO-001）
	if gs.active_pet != null:
		var pet_id: String = str(gs.active_pet.id)
		var pet_amount: int = int(exp_by_member.get(pet_id, 0))
		if pet_amount > 0:
			var pet_gained: int = grant_exp(gs.active_pet, pet_amount)
			if pet_gained > 0:
				result[pet_id] = pet_gained
				const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
				_PetSystem.sync_pet_runtime(gs.active_pet)
	return result
