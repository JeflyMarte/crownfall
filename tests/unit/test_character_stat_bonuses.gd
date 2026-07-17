extends GutTest
## キャラ個人ステ補正（P3-STAT-CHAR-001 案A）。

const _Bonuses = preload("res://scripts/roster/CharacterStatBonuses.gd")


func _make_member(id: String, job_id: String, rarity: int) -> Resource:
	var adv: Resource = load("res://scripts/domain/Adventurer.gd").new()
	adv.id = id
	adv.job_id = job_id
	adv.rarity = rarity
	return adv


func _final_key(member: Resource) -> String:
	GachaRarityConfig.apply_stats_for_adventurer(member)
	return "%d/%d/%d" % [
		int(member.base_stats.hp),
		int(member.base_stats.attack),
		int(member.base_stats.defense),
	]


func test_star_band_gaps_are_wide() -> void:
	var b2: Dictionary = GachaRarityConfig.get_stat_bonuses(2)
	var b3: Dictionary = GachaRarityConfig.get_stat_bonuses(3)
	var b4: Dictionary = GachaRarityConfig.get_stat_bonuses(4)
	assert_true(int(b3["hp"]) - int(b2["hp"]) >= 6, "★2→3 HP差")
	assert_true(int(b4["hp"]) - int(b3["hp"]) >= 10, "★3→4 HP差")


func test_all_defined_characters_have_unique_final_stats() -> void:
	var roster: Array = [
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
	var seen: Dictionary = {}
	for member: Resource in roster:
		var key: String = _final_key(member)
		assert_false(seen.has(key), "ステ重複: %s = %s" % [member.id, key])
		seen[key] = str(member.id)
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
	## ★3 + 個人 → HP48 ATK25 DEF5
	assert_eq(int(ald.base_stats.hp), CombatController.BASE_MEMBER_HP + 14 + 4)
	assert_eq(int(ald.base_stats.attack), 5 + 20)
	assert_eq(int(ald.base_stats.defense), 3 + 2)


func test_attack_floors_at_zero() -> void:
	var bonus: Dictionary = {"hp": 0, "attack": -99, "defense": 0}
	var adv: Resource = _make_member("extra_floor", "alchemist", 3)
	GachaRarityConfig.apply_base_stats_to_adventurer(
		adv, 3, CombatController.BASE_MEMBER_HP, bonus
	)
	assert_eq(int(adv.base_stats.attack), 0)
