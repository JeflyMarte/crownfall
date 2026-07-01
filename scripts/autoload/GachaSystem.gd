extends Node

## 助っ人ガチャ（P3-D036b / P3-GACHA-004）。通貨=魔晶石（`GameState.gacha_token`）を消費して単発抽選。
## プール=`resources/gacha_helpers/` 全件。未所持優先・★4=20%/★3=80%・ハード天井30・重複還元。

const PULL_COST: int = 1
const TOKEN_PURCHASE_GOLD: int = 100
const HARD_PITY: int = 30
const RARITY_FOUR: int = 4
const RARITY_THREE: int = 3
const RATE_RARITY_FOUR: float = 0.20
const REFUND_BY_RARITY: Dictionary = {4: 5, 3: 2}

func _get_pool() -> Array:
	return DataRegistry.get_all_gacha_helper_data()

func can_pull() -> bool:
	return GameState.gacha_token >= PULL_COST

func rate_display_text() -> String:
	return "★4 %.0f%% / ★3 %.0f%%（未所持優先）" % [
		RATE_RARITY_FOUR * 100.0,
		(1.0 - RATE_RARITY_FOUR) * 100.0,
	]

func add_tokens(n: int) -> void:
	if n > 0:
		GameState.gacha_token += n

# Gold で魔晶石を1個購入。成功で true。
func buy_token() -> bool:
	if GameState.gold < TOKEN_PURCHASE_GOLD:
		return false
	GameState.gold -= TOKEN_PURCHASE_GOLD
	GameState.gacha_token += 1
	return true

# 単発抽選。結果 Dictionary を返す:
# { ok, reason?, helper_id, rarity, is_new, refund }
func pull() -> Dictionary:
	if GameState.gacha_token < PULL_COST:
		return {"ok": false, "reason": "no_token"}
	var pool: Array = _get_pool()
	if pool.is_empty():
		return {"ok": false, "reason": "empty_pool"}
	GameState.gacha_token -= PULL_COST
	GameState.gacha_pity += 1
	var pity_forced: bool = GameState.gacha_pity >= HARD_PITY
	var helper: Resource = _select_helper(pool, pity_forced)
	if helper == null:
		GameState.gacha_token += PULL_COST
		GameState.gacha_pity -= 1
		return {"ok": false, "reason": "empty_pool"}
	var hid: String = str(helper.id)
	var is_new: bool = not GameState.owned_helpers.has(hid)
	var refund: int = 0
	if is_new:
		GameState.owned_helpers[hid] = 1
		GameState.gacha_pity = 0
		var adv: Resource = create_adventurer_from_helper(helper)
		GameState.add_roster_member(adv)
	else:
		GameState.owned_helpers[hid] = int(GameState.owned_helpers[hid]) + 1
		refund = int(REFUND_BY_RARITY.get(int(helper.rarity), 0))
		GameState.gacha_token += refund
	return {
		"ok": true,
		"helper_id": hid,
		"rarity": int(helper.rarity),
		"is_new": is_new,
		"refund": refund,
	}

func _select_helper(pool: Array, pity_forced: bool) -> Resource:
	if pity_forced:
		var unowned_all: Array = _filter_unowned(pool)
		if not unowned_all.is_empty():
			return _pick_by_rarity(unowned_all)
	var unowned: Array = _filter_unowned(pool)
	var candidates: Array = unowned if not unowned.is_empty() else pool
	return _pick_by_rarity(candidates)

func _pick_by_rarity(candidates: Array) -> Resource:
	if candidates.is_empty():
		return null
	var by_rarity: Dictionary = {}
	for helper in candidates:
		if helper == null:
			continue
		var rarity: int = int(helper.rarity)
		if not by_rarity.has(rarity):
			by_rarity[rarity] = []
		(by_rarity[rarity] as Array).append(helper)
	var tier4: Array = by_rarity.get(RARITY_FOUR, [])
	var tier3: Array = by_rarity.get(RARITY_THREE, [])
	if not tier4.is_empty() and not tier3.is_empty():
		var pool_pick: Array = tier4 if randf() < RATE_RARITY_FOUR else tier3
		return pool_pick[randi() % pool_pick.size()]
	if not tier4.is_empty():
		return tier4[randi() % tier4.size()]
	if not tier3.is_empty():
		return tier3[randi() % tier3.size()]
	return candidates[randi() % candidates.size()]

func _filter_unowned(pool: Array) -> Array:
	var out: Array = []
	for h in pool:
		if h != null and not GameState.owned_helpers.has(str(h.id)):
			out.append(h)
	return out

func create_adventurer_from_helper(helper: Resource) -> Resource:
	var adventurer_class = load("res://scripts/domain/Adventurer.gd")
	var stats_class = load("res://scripts/domain/Stats.gd")
	var adv = adventurer_class.new()
	adv.id = "gacha_" + str(helper.id)
	adv.display_name = str(helper.display_name)
	adv.job_id = str(helper.job_id)
	adv.rarity = clampi(int(helper.rarity), 1, 5)
	if helper.base_stats != null:
		adv.base_stats = helper.base_stats.duplicate()
	else:
		adv.base_stats = stats_class.new()
	return adv
