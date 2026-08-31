extends GutTest
## エンシェント地力＋単品パッシブ（P3-EQ-ANCIENT-POWER-D-001）。


const WEAPON_ATK := {
	"chronos_toki_sword": 242,
	"chronos_toki_dual": 224,
	"chronos_toki_bow": 220,
	"chronos_toki_staff": 216,
	"albark_namerefuse_sword": 242,
	"albark_namerefuse_dual": 224,
	"albark_namerefuse_bow": 220,
	"albark_namerefuse_staff": 216,
	"albark_namerefuse_hammer": 260,
	"forge_slag_sword": 242,
	"forge_slag_dual": 224,
	"forge_slag_bow": 220,
	"forge_slag_staff": 216,
	"forge_slag_hammer": 260,
	"valgard_antique_blade": 220,
	"valgard_antique_dual": 202,
	"valgard_antique_arrow": 198,
	"valgard_antique_rod": 194,
}

const WEAPON_PASSIVE := {
	"chronos_toki_sword": "eq_set_chronos_weapon",
	"chronos_toki_dual": "eq_set_chronos_weapon",
	"chronos_toki_bow": "eq_set_chronos_weapon",
	"chronos_toki_staff": "eq_set_chronos_weapon",
	"albark_namerefuse_sword": "eq_set_namerefuse_weapon",
	"albark_namerefuse_dual": "eq_set_namerefuse_weapon",
	"albark_namerefuse_bow": "eq_set_namerefuse_weapon",
	"albark_namerefuse_staff": "eq_set_namerefuse_weapon",
	"albark_namerefuse_hammer": "eq_set_namerefuse_weapon",
	"forge_slag_sword": "eq_set_forge_weapon",
	"forge_slag_dual": "eq_set_forge_weapon",
	"forge_slag_bow": "eq_set_forge_weapon",
	"forge_slag_staff": "eq_set_forge_weapon",
	"forge_slag_hammer": "eq_set_forge_weapon",
	"valgard_antique_blade": "eq_set_valgard_weapon",
	"valgard_antique_dual": "eq_set_valgard_weapon",
	"valgard_antique_arrow": "eq_set_valgard_weapon",
	"valgard_antique_rod": "eq_set_valgard_weapon",
}

const ARMOR_STATS := {
	"chronos_toki_armor": {"def": 210, "hp": 350, "pid": "eq_set_chronos_armor"},
	"valgard_antique_armor": {"def": 195, "hp": 310, "pid": "eq_set_valgard_armor"},
	"albark_namerefuse_armor": {"def": 200, "hp": 330, "pid": "eq_set_namerefuse_armor"},
	"forge_slag_armor": {"def": 200, "hp": 330, "pid": "eq_set_forge_armor"},
}

const ACC_STATS := {
	"chronos_toki_orb": {"atk": 24, "def": 8, "hp": 110, "pid": "eq_set_chronos_acc"},
	"valgard_antique_amulet": {"atk": 10, "def": 28, "hp": 96, "pid": "eq_set_valgard_acc"},
	"albark_namerefuse_circlet": {"atk": 16, "def": 16, "hp": 80, "pid": "eq_set_namerefuse_acc"},
	"forge_slag_seal": {"atk": 16, "def": 16, "hp": 80, "pid": "eq_set_forge_acc"},
}


func _equip_weapon(member: Resource, weapon_id: String) -> void:
	var wpn: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	wpn.weapon_id = weapon_id
	member.equipped_weapon = wpn


func _equip_armor(member: Resource, armor_id: String) -> void:
	var arm: Resource = load("res://scripts/domain/ArmorInstance.gd").new()
	arm.armor_id = armor_id
	member.equipped_armor = arm


func _equip_accessory(member: Resource, accessory_id: String) -> void:
	var acc: Resource = load("res://scripts/domain/AccessoryInstance.gd").new()
	acc.accessory_id = accessory_id
	member.equipped_accessory = acc


func test_weapon_base_attack_and_passives() -> void:
	for weapon_id: String in WEAPON_ATK.keys():
		var wd: Resource = DataRegistry.get_weapon_data(weapon_id)
		assert_not_null(wd, weapon_id)
		assert_eq(int(wd.base_attack), int(WEAPON_ATK[weapon_id]), weapon_id)
		assert_eq(str(wd.fixed_passive_id), str(WEAPON_PASSIVE[weapon_id]), weapon_id)
		var def: Dictionary = CombatPassives.get_def(str(wd.fixed_passive_id))
		assert_false(def.is_empty(), str(wd.fixed_passive_id))


func test_armor_and_accessory_stats_and_passives() -> void:
	for armor_id: String in ARMOR_STATS.keys():
		var meta: Dictionary = ARMOR_STATS[armor_id]
		var ad: Resource = DataRegistry.get_armor_data(armor_id)
		assert_not_null(ad, armor_id)
		assert_eq(int(ad.base_defense), int(meta["def"]), armor_id)
		assert_eq(int(ad.base_hp_bonus), int(meta["hp"]), armor_id)
		assert_eq(str(ad.fixed_passive_id), str(meta["pid"]), armor_id)
		assert_false(CombatPassives.get_def(str(meta["pid"])).is_empty(), str(meta["pid"]))
	for acc_id: String in ACC_STATS.keys():
		var meta: Dictionary = ACC_STATS[acc_id]
		var acd: Resource = DataRegistry.get_accessory_data(acc_id)
		assert_not_null(acd, acc_id)
		assert_eq(int(acd.attack_bonus), int(meta["atk"]), acc_id)
		assert_eq(int(acd.defense_bonus), int(meta["def"]), acc_id)
		assert_eq(int(acd.hp_bonus), int(meta["hp"]), acc_id)
		assert_eq(str(acd.fixed_passive_id), str(meta["pid"]), acc_id)
		assert_false(CombatPassives.get_def(str(meta["pid"])).is_empty(), str(meta["pid"]))


func test_passive_def_values() -> void:
	assert_almost_eq(float(CombatPassives.get_def("eq_set_chronos_weapon").get("skill_cd_mult", 1.0)), 0.94, 0.001)
	assert_almost_eq(float(CombatPassives.get_def("eq_set_chronos_armor").get("incoming_mult", 1.0)), 0.97, 0.001)
	assert_almost_eq(float(CombatPassives.get_def("eq_set_chronos_acc").get("skill_cd_mult", 1.0)), 0.97, 0.001)
	assert_almost_eq(float(CombatPassives.get_def("eq_set_valgard_weapon").get("outgoing_mult", 1.0)), 1.06, 0.001)
	assert_almost_eq(float(CombatPassives.get_def("eq_set_valgard_armor").get("incoming_mult", 1.0)), 0.95, 0.001)
	assert_almost_eq(float(CombatPassives.get_def("eq_set_valgard_acc").get("outgoing_mult", 1.0)), 1.04, 0.001)
	assert_almost_eq(float(CombatPassives.get_def("eq_set_namerefuse_weapon").get("status_chance_mult", 1.0)), 1.10, 0.001)
	assert_almost_eq(float(CombatPassives.get_def("eq_set_namerefuse_acc").get("status_chance_mult", 1.0)), 1.06, 0.001)
	var forge_w: Dictionary = CombatPassives.get_def("eq_set_forge_weapon")
	assert_almost_eq(float(forge_w.get("outgoing_vs_status_mult", 1.0)), 1.08, 0.001)
	assert_eq(str(forge_w.get("trigger", "")), "on_skill_hit")
	assert_almost_eq(float(forge_w.get("status_chance", 0.0)), 0.15, 0.001)
	assert_almost_eq(float(CombatPassives.get_def("eq_set_forge_acc").get("outgoing_vs_status_mult", 1.0)), 1.05, 0.001)


func after_each() -> void:
	GameState.party_members = []


func test_namerefuse_status_chance_stacks_with_equipment() -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "ancient_nr"
	member.job_id = "swordsman"
	member.is_evolved = false
	_equip_weapon(member, "albark_namerefuse_sword")
	_equip_accessory(member, "albark_namerefuse_circlet")
	GameState.party_members = [member]
	## 加護なし（1〜2部位）＋単品武器1.10×装飾1.06。
	var mult: float = EvolutionTraits.member_status_chance_mult(0)
	assert_almost_eq(mult, 1.10 * 1.06, 0.001)


func test_chronos_skill_cd_from_weapon_and_acc() -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "ancient_ch"
	member.job_id = "swordsman"
	_equip_weapon(member, "chronos_toki_sword")
	_equip_accessory(member, "chronos_toki_orb")
	GameState.party_members = [member]
	var mult: float = CombatPassives.relic_skill_cd_mult(0)
	assert_almost_eq(mult, 0.94 * 0.97, 0.001)
