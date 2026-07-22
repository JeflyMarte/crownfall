extends GutTest
## キャラ個人ステ補正（P3-STAT-CHAR-001 / 初期バランス: ★序列＋バラつき）。

const _Bonuses = preload("res://scripts/roster/CharacterStatBonuses.gd")


func _make_member(id: String, job_id: String, rarity: int) -> Resource:
	var adv: Resource = load("res://scripts/domain/Adventurer.gd").new()
	adv.id = id
	adv.job_id = job_id
	adv.rarity = rarity
	return adv


func _all_roster() -> Array:
	return [
		_make_member("adventurer_0", "swordsman", 3),
		_make_member("adventurer_1", "ranger", 3),
		_make_member("adventurer_2", "alchemist", 3),
		_make_member("adventurer_3", "vanguard", 3),
		_make_member("adventurer_4", "beast_tamer", 3),
		_make_member("gacha_helper_a", "vanguard", 4),
		_make_member("gacha_helper_b", "ranger", 2),
		_make_member("gacha_helper_c", "alchemist", 3),
		_make_member("gacha_helper_d", "swordsman", 1),
		_make_member("gacha_helper_e", "beast_tamer", 3),
		_make_member("gacha_helper_f", "swordsman", 2),
		_make_member("gacha_helper_h", "alchemist", 1),
		_make_member("gacha_helper_i", "vanguard", 2),
	]


func _final_key(member: Resource) -> String:
	GachaRarityConfig.apply_stats_for_adventurer(member)
	return "%d/%d/%d" % [
		int(member.base_stats.hp),
		int(member.base_stats.attack),
		int(member.base_stats.defense),
	]


func _stat_total(member: Resource) -> int:
	GachaRarityConfig.apply_stats_for_adventurer(member)
	return (
		int(member.base_stats.hp)
		+ int(member.base_stats.attack)
		+ int(member.base_stats.defense)
	)


func test_base_member_hp_scaled() -> void:
	assert_eq(BalanceConfig.BASE_MEMBER_HP, 800)


func test_star_band_gaps_are_wide() -> void:
	var b2: Dictionary = GachaRarityConfig.get_stat_bonuses(2)
	var b3: Dictionary = GachaRarityConfig.get_stat_bonuses(3)
	var b4: Dictionary = GachaRarityConfig.get_stat_bonuses(4)
	assert_true(int(b3["hp"]) - int(b2["hp"]) >= 200, "★2→3 HP差")
	assert_true(int(b4["hp"]) - int(b3["hp"]) >= 300, "★3→4 HP差")
	assert_true(int(b3["attack"]) - int(b2["attack"]) >= 80, "★2→3 ATK差")
	assert_true(int(b4["attack"]) - int(b3["attack"]) >= 120, "★3→4 ATK差")


func test_all_defined_characters_have_unique_final_stats() -> void:
	var roster: Array = _all_roster()
	var seen: Dictionary = {}
	for member: Resource in roster:
		var key: String = _final_key(member)
		assert_false(seen.has(key), "ステ重複: %s = %s" % [member.id, key])
		seen[key] = str(member.id)
		assert_true(int(member.base_stats.hp) >= 800, "%s HP帯" % member.id)
		assert_true(int(member.base_stats.attack) >= 1, "%s ATK>=1" % member.id)
		assert_true(int(member.base_stats.defense) >= 1, "%s DEF>=1" % member.id)
	assert_eq(seen.size(), roster.size())


func test_personal_bonus_triplets_are_all_unique() -> void:
	var seen: Dictionary = {}
	for k: Variant in _Bonuses.STARTER_BONUS.keys():
		var b: Dictionary = _Bonuses.for_adventurer_id(str(k))
		var key: String = "%d/%d/%d" % [int(b["hp"]), int(b["attack"]), int(b["defense"])]
		assert_false(seen.has(key), "個人補正重複: %s = %s" % [str(k), key])
		seen[key] = str(k)
	for k: Variant in _Bonuses.HELPER_BONUS.keys():
		var hb: Dictionary = _Bonuses.for_helper_id(str(k))
		var hkey: String = "%d/%d/%d" % [int(hb["hp"]), int(hb["attack"]), int(hb["defense"])]
		assert_false(seen.has(hkey), "個人補正重複: %s = %s" % [str(k), hkey])
		seen[hkey] = str(k)


func test_starter_ald_profile() -> void:
	var ald: Resource = _make_member("adventurer_0", "swordsman", Adventurer.STARTER_RARITY)
	GachaRarityConfig.apply_stats_for_adventurer(ald)
	## P3-BAL-OPENING-002: HP/DEF×0.70・ATK×0.40 後の値
	assert_eq(int(ald.base_stats.hp), 1123)
	assert_eq(int(ald.base_stats.attack), 134)
	assert_eq(int(ald.base_stats.defense), 146)


func test_ally_stat_bonus_scale_is_opening_balance() -> void:
	assert_almost_eq(BalanceConfig.ALLY_STAT_BONUS_SCALE, 0.70, 0.001)
	assert_almost_eq(BalanceConfig.ALLY_ATK_BONUS_SCALE, 0.40, 0.001)
	assert_almost_eq(BalanceConfig.ENEMY_GLOBAL_HP_MULT, 2.00, 0.001)
	assert_almost_eq(BalanceConfig.ENEMY_GLOBAL_ATK_MULT, 1.30, 0.001)


func test_rarity_total_order_four_gt_three_gt_two() -> void:
	## 初期バランス: 合計ステで ★4 > ★3 > ★2 > ★1（個々のATK逆転はロール次第で可）
	var by_rarity: Dictionary = {1: [], 2: [], 3: [], 4: []}
	for member: Resource in _all_roster():
		var rarity: int = int(member.rarity)
		## helper は DataRegistry 側レアで上書きされ得る
		GachaRarityConfig.apply_stats_for_adventurer(member)
		rarity = int(member.rarity)
		by_rarity[rarity].append(_stat_total(member))
	var max1: int = by_rarity[1].max()
	var max2: int = by_rarity[2].max()
	var max3: int = by_rarity[3].max()
	var min2: int = by_rarity[2].min()
	var min3: int = by_rarity[3].min()
	var min4: int = by_rarity[4].min()
	assert_true(min4 > max3, "★4合計 > ★3最大")
	assert_true(min3 > max2, "★3合計 > ★2最大")
	assert_true(min2 > max1, "★2合計 > ★1最大")


func test_attack_and_defense_floor() -> void:
	var bonus: Dictionary = {"hp": 0, "attack": -9999, "defense": -9999}
	var adv: Resource = _make_member("extra_floor", "alchemist", 3)
	GachaRarityConfig.apply_base_stats_to_adventurer(
		adv, 3, CombatController.BASE_MEMBER_HP, bonus
	)
	assert_eq(int(adv.base_stats.attack), 1)
	assert_eq(int(adv.base_stats.defense), 1)
