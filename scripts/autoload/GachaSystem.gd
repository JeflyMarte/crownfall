extends Node

## 助っ人ガチャ（P3-D036b / P3-GACHA-005 / **P3-GACHA-LIMIT-001** / P3-TICKET-001）。
## 通貨=魔晶石。招待無料券は専用ボタン（use_ticket=true）でのみ消費。
## プール=`gacha_helpers/` のみ（スターター5職は除外）。
## ★2〜4 排出。重複は限界突破＋半額還元。

const _GachaRarityConfig: Script = preload("res://scripts/gacha/GachaRarityConfig.gd")
const _GachaLimitBreak: Script = preload("res://scripts/gacha/GachaLimitBreak.gd")
const _CombatControllerScript: Script = preload("res://scripts/combat/CombatController.gd")

const PULL_COST: int = 500
## 「はじめから」開始時の所持魔晶石（1回招待分）。
const STARTING_TOKENS: int = 500


func can_pull() -> bool:
	if not Constants.are_gacha_helpers_playable():
		return false
	return GameState.gacha_token >= PULL_COST

func can_pull_with_ticket() -> bool:
	if not Constants.are_gacha_helpers_playable():
		return false
	return TicketSystem.can_use_free_gacha()

func rate_display_text() -> String:
	return _GachaRarityConfig.rate_display_text()

func add_tokens(n: int) -> void:
	if n > 0:
		GameState.gacha_token += n

# 単発抽選。use_ticket=true で招待無料券、false で魔晶石。
# 結果: { ok, reason?, helper_id, rarity, is_new, refund, breakthrough, breakthrough_gained, paid_with_ticket }
func pull(use_ticket: bool = false) -> Dictionary:
	if not Constants.are_gacha_helpers_playable():
		return {"ok": false, "reason": "omitted"}
	var paid_with_ticket: bool = false
	if use_ticket:
		if not TicketSystem.try_consume_free_gacha():
			return {"ok": false, "reason": "no_ticket"}
		paid_with_ticket = true
	elif GameState.gacha_token >= PULL_COST:
		GameState.gacha_token -= PULL_COST
	else:
		return {"ok": false, "reason": "no_token"}
	var pool: Array = _get_pool()
	if pool.is_empty():
		_refund_pull_cost(paid_with_ticket)
		return {"ok": false, "reason": "empty_pool"}
	var helper: Resource = _select_helper(pool)
	if helper == null:
		_refund_pull_cost(paid_with_ticket)
		return {"ok": false, "reason": "empty_pool"}
	var hid: String = str(helper.id)
	var rarity: int = _GachaRarityConfig.clamp_rarity(int(helper.rarity))
	var is_new: bool = not GameState.owned_helpers.has(hid)
	var refund: int = 0
	var breakthrough: int = 0
	var breakthrough_gained: bool = false
	if is_new:
		GameState.owned_helpers[hid] = 1
		var adv: Resource = create_adventurer_from_helper(helper)
		GameState.add_roster_member(adv)
		breakthrough = 0
	else:
		var prev_count: int = int(GameState.owned_helpers[hid])
		var next_count: int = prev_count + 1
		GameState.owned_helpers[hid] = next_count
		var bt_before: int = _GachaLimitBreak.breakthrough_from_owned_count(prev_count)
		breakthrough = _GachaLimitBreak.breakthrough_from_owned_count(next_count)
		breakthrough_gained = breakthrough > bt_before
		refund = _GachaRarityConfig.get_refund(rarity)
		GameState.gacha_token += refund
	return {
		"ok": true,
		"helper_id": hid,
		"rarity": rarity,
		"is_new": is_new,
		"refund": refund,
		"breakthrough": breakthrough,
		"breakthrough_gained": breakthrough_gained,
		"paid_with_ticket": paid_with_ticket,
	}

func _refund_pull_cost(paid_with_ticket: bool) -> void:
	if paid_with_ticket:
		TicketSystem.refund_free_gacha()
	else:
		GameState.gacha_token += PULL_COST

func _get_pool() -> Array:
	if not Constants.are_gacha_helpers_playable():
		return []
	return DataRegistry.get_all_gacha_helper_data()

func _select_helper(pool: Array) -> Resource:
	return _pick_by_rarity(pool)

func _pick_by_rarity(candidates: Array) -> Resource:
	if candidates.is_empty():
		return null
	var by_rarity: Dictionary = {}
	for helper in candidates:
		if helper == null:
			continue
		var rarity: int = _GachaRarityConfig.clamp_rarity(int(helper.rarity))
		if not by_rarity.has(rarity):
			by_rarity[rarity] = []
		(by_rarity[rarity] as Array).append(helper)
	var tier: int = _GachaRarityConfig.roll_rarity_tier()
	if by_rarity.has(tier):
		var tier_pool: Array = by_rarity[tier]
		return tier_pool[randi() % tier_pool.size()]
	for fallback_tier in range(_GachaRarityConfig.MAX_RARITY, _GachaRarityConfig.MIN_RARITY - 1, -1):
		if by_rarity.has(fallback_tier):
			var tier_pool: Array = by_rarity[fallback_tier]
			return tier_pool[randi() % tier_pool.size()]
	return candidates[randi() % candidates.size()]

func create_adventurer_from_helper(helper: Resource) -> Resource:
	var adventurer_class = load("res://scripts/domain/Adventurer.gd")
	var adv = adventurer_class.new()
	adv.id = "gacha_" + str(helper.id)
	adv.display_name = str(helper.display_name)
	adv.job_id = str(helper.job_id)
	adv.rarity = _GachaRarityConfig.clamp_rarity(int(helper.rarity))
	_GachaRarityConfig.apply_stats_for_adventurer(adv)
	return adv
