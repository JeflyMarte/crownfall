extends GutTest
## 影狩限定・死告武器（P3-EQ-SHADOW-DEATHREAP-001）


const _ShadowStalkerLoot = preload("res://scripts/dungeon/ShadowStalkerLoot.gd")
const _WanderingEnemyConfig = preload("res://scripts/dungeon/WanderingEnemyConfig.gd")


func before_each() -> void:
	GameState.reset_for_new_game()


func test_deathreap_weapon_data_and_passive() -> void:
	for wid in _ShadowStalkerLoot.WEAPON_IDS:
		var data: Resource = DataRegistry.get_weapon_data(wid)
		assert_not_null(data, "weapon exists: %s" % wid)
		assert_eq(int(data.rarity), Enums.Rarity.LEGENDARY)
		assert_eq(str(data.fixed_passive_id), _ShadowStalkerLoot.PASSIVE_ID)
		assert_eq(str(data.element), "dark")
	var def: Dictionary = CombatPassives.get_def(_ShadowStalkerLoot.PASSIVE_ID)
	assert_false(def.is_empty())
	assert_eq(str(def.get("effect", "")), "instant_kill_trash")
	assert_almost_eq(float(def.get("status_chance", 0.0)), 0.15, 0.001)
	assert_almost_eq(float(def.get("bleed_chance", 0.0)), 0.25, 0.001)


func test_instant_kill_eligible_normal_only() -> void:
	var trash: Resource = DataRegistry.get_enemy_data("sepia_hound")
	assert_not_null(trash)
	assert_true(_ShadowStalkerLoot.is_instant_kill_eligible(trash))
	var stalker: Resource = DataRegistry.get_enemy_data(_WanderingEnemyConfig.ID_SHADOW_STALKER)
	assert_not_null(stalker)
	assert_false(_ShadowStalkerLoot.is_instant_kill_eligible(stalker), "影狩本体は即死不可")
	var elite: Resource = DataRegistry.get_enemy_data("great_claw")
	if elite != null and int(elite.enemy_type) == Enums.EnemyType.ELITE:
		assert_false(_ShadowStalkerLoot.is_instant_kill_eligible(elite))


func test_first_kill_grants_one_deathreap() -> void:
	assert_false(_ShadowStalkerLoot.owns_any())
	var granted: String = _ShadowStalkerLoot.try_grant_on_kill()
	assert_true(_ShadowStalkerLoot.is_deathreap_id(granted), "初回は確定付与")
	assert_true(_ShadowStalkerLoot.owns_any())


func test_deathreap_excluded_from_legendary_pool_helper() -> void:
	for wid in _ShadowStalkerLoot.WEAPON_IDS:
		assert_true(_ShadowStalkerLoot.is_deathreap_id(wid))
