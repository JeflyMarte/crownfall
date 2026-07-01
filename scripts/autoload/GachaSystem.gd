extends Node

## 助っ人ガチャ（P3-D036b）。通貨 gacha_token を消費して単発抽選。
## キャラ★は全員★3固定。未所持優先、ハード天井30連。重複は token 還元。

const PULL_COST: int = 1
const TOKEN_PURCHASE_GOLD: int = 100
const HARD_PITY: int = 30
const REFUND_BY_RARITY: Dictionary = {3: 2}

var _pool: Array = []

func _get_pool() -> Array:
	if _pool.is_empty():
		_pool = DataRegistry.get_all_gacha_helper_data()
	return _pool

func can_pull() -> bool:
	return GameState.gacha_token >= PULL_COST

func add_tokens(n: int) -> void:
	if n > 0:
		GameState.gacha_token += n

# Gold で token を1枚購入。成功で true。
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
	# 天井: 未所持を最優先で確定付与
	if pity_forced:
		var unowned_all: Array = _filter_unowned(pool)
		if not unowned_all.is_empty():
			return unowned_all[randi() % unowned_all.size()]
	# キャラ★は全員★3固定。プールから未所持優先で抽選。
	var unowned: Array = _filter_unowned(pool)
	var candidates: Array = unowned if not unowned.is_empty() else pool
	if candidates.is_empty():
		return null
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
	adv.rarity = Adventurer.DEFAULT_RARITY
	if helper.base_stats != null:
		adv.base_stats = helper.base_stats.duplicate()
	else:
		adv.base_stats = stats_class.new()
	return adv
