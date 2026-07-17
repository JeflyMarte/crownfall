extends GutTest
## キャラ個人ステ補正（P3-STAT-CHAR-001 案A）。


func _make_member(id: String, job_id: String, rarity: int) -> Resource:
	var adv: Resource = load("res://scripts/domain/Adventurer.gd").new()
	adv.id = id
	adv.job_id = job_id
	adv.rarity = rarity
	return adv


func test_starter_bonus_applies_on_top_of_star3_band() -> void:
	var ald: Resource = _make_member("adventurer_0", "swordsman", Adventurer.STARTER_RARITY)
	GachaRarityConfig.apply_stats_for_adventurer(ald)
	## ★3帯 = HP+6 ATK+2 DEF+1、アルド個人 = ATK+2
	assert_eq(int(ald.base_stats.hp), CombatController.BASE_MEMBER_HP + 6)
	assert_eq(int(ald.base_stats.attack), 4)
	assert_eq(int(ald.base_stats.defense), 1)


func test_galen_tank_bonus() -> void:
	var galen: Resource = _make_member("adventurer_3", "vanguard", Adventurer.STARTER_RARITY)
	GachaRarityConfig.apply_stats_for_adventurer(galen)
	## ★3 + 個人 HP+3 ATK-1 DEF+2 → HP39 ATK1 DEF3
	assert_eq(int(galen.base_stats.hp), CombatController.BASE_MEMBER_HP + 6 + 3)
	assert_eq(int(galen.base_stats.attack), 1)
	assert_eq(int(galen.base_stats.defense), 3)


func test_gacha_helper_bonus() -> void:
	var kaida: Resource = _make_member("gacha_helper_f", "swordsman", 2)
	GachaRarityConfig.apply_stats_for_adventurer(kaida)
	## ★2帯 HP+3 ATK+1 + 個人 HP-1 ATK+2 → HP32 ATK3 DEF0
	assert_eq(int(kaida.base_stats.hp), CombatController.BASE_MEMBER_HP + 3 - 1)
	assert_eq(int(kaida.base_stats.attack), 3)
	assert_eq(int(kaida.base_stats.defense), 0)


func test_attack_floors_at_zero() -> void:
	var bonus: Dictionary = {"hp": 0, "attack": -99, "defense": 0}
	var adv: Resource = _make_member("extra_floor", "alchemist", 3)
	GachaRarityConfig.apply_base_stats_to_adventurer(
		adv, 3, CombatController.BASE_MEMBER_HP, bonus
	)
	assert_eq(int(adv.base_stats.attack), 0)
