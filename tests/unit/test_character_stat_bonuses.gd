extends GutTest
## キャラ個人ステ補正（P3-STAT-CHAR-001 案A）。


func _make_member(id: String, job_id: String, rarity: int) -> Resource:
	var adv: Resource = load("res://scripts/domain/Adventurer.gd").new()
	adv.id = id
	adv.job_id = job_id
	adv.rarity = rarity
	return adv


func test_star_band_gaps_are_wide() -> void:
	var b2: Dictionary = GachaRarityConfig.get_stat_bonuses(2)
	var b3: Dictionary = GachaRarityConfig.get_stat_bonuses(3)
	var b4: Dictionary = GachaRarityConfig.get_stat_bonuses(4)
	assert_true(int(b3["hp"]) - int(b2["hp"]) >= 6, "★2→3 HP差")
	assert_true(int(b4["hp"]) - int(b3["hp"]) >= 10, "★3→4 HP差")
	assert_true(int(b3["attack"]) - int(b2["attack"]) >= 2, "★2→3 ATK差")
	assert_true(int(b4["attack"]) - int(b3["attack"]) >= 4, "★3→4 ATK差")


func test_starter_bonus_applies_on_top_of_star3_band() -> void:
	var ald: Resource = _make_member("adventurer_0", "swordsman", Adventurer.STARTER_RARITY)
	GachaRarityConfig.apply_stats_for_adventurer(ald)
	## ★3帯 HP+14 ATK+5 DEF+3、アルド個人 ATK+5 → HP44 ATK10 DEF3
	assert_eq(int(ald.base_stats.hp), CombatController.BASE_MEMBER_HP + 14)
	assert_eq(int(ald.base_stats.attack), 10)
	assert_eq(int(ald.base_stats.defense), 3)


func test_galen_tank_bonus() -> void:
	var galen: Resource = _make_member("adventurer_3", "vanguard", Adventurer.STARTER_RARITY)
	GachaRarityConfig.apply_stats_for_adventurer(galen)
	## ★3 + 個人 HP+10 ATK-3 DEF+5 → HP54 ATK2 DEF8
	assert_eq(int(galen.base_stats.hp), CombatController.BASE_MEMBER_HP + 14 + 10)
	assert_eq(int(galen.base_stats.attack), 2)
	assert_eq(int(galen.base_stats.defense), 8)


func test_gacha_helper_bonus() -> void:
	var kaida: Resource = _make_member("gacha_helper_f", "swordsman", 2)
	GachaRarityConfig.apply_stats_for_adventurer(kaida)
	## ★2帯 HP+6 ATK+2 DEF+1 + 個人 HP-4 ATK+6 DEF-1 → HP32 ATK8 DEF0
	assert_eq(int(kaida.base_stats.hp), CombatController.BASE_MEMBER_HP + 6 - 4)
	assert_eq(int(kaida.base_stats.attack), 8)
	assert_eq(int(kaida.base_stats.defense), 0)


func test_attack_floors_at_zero() -> void:
	var bonus: Dictionary = {"hp": 0, "attack": -99, "defense": 0}
	var adv: Resource = _make_member("extra_floor", "alchemist", 3)
	GachaRarityConfig.apply_base_stats_to_adventurer(
		adv, 3, CombatController.BASE_MEMBER_HP, bonus
	)
	assert_eq(int(adv.base_stats.attack), 0)
