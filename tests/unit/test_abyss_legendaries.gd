extends GutTest

## P3-DG-ABYSS-001-C — 深層限定レジェンド5。

const _AbyssMilestoneRewards := preload("res://scripts/dungeon/AbyssMilestoneRewards.gd")
const _AbyssLegendaryWeapons := preload("res://scripts/dungeon/AbyssLegendaryWeapons.gd")
const _AbyssWeaponEffects = preload("res://scripts/combat/AbyssWeaponEffects.gd")
const _WeaponInstance = preload("res://scripts/domain/WeaponInstance.gd")

var _saved_progress: Dictionary = {}
var _saved_mats: Dictionary = {}
var _saved_tickets: Dictionary = {}
var _saved_inventory: Array = []
var _saved_token: int = 0
var _saved_notices: Array = []


func before_each() -> void:
	_saved_progress = GameState.dungeon_progress.duplicate(true)
	_saved_mats = GameState.material_inventory.duplicate(true)
	_saved_tickets = GameState.ticket_inventory.duplicate(true)
	_saved_inventory = GameState.inventory.duplicate()
	_saved_token = GameState.gacha_token
	_saved_notices = GameState.last_run_abyss_notices.duplicate() if GameState.last_run_abyss_notices is Array else []
	GameState.dungeon_progress = {}
	GameState.material_inventory = {}
	GameState.ticket_inventory = {}
	GameState.inventory = []
	GameState.gacha_token = 0
	GameState.last_run_token_reward = 0
	GameState.last_run_abyss_notices = []
	GameState.begin_run_material_tracking()
	_AbyssWeaponEffects.reset_combat()


func after_each() -> void:
	GameState.dungeon_progress = _saved_progress
	GameState.material_inventory = _saved_mats
	GameState.ticket_inventory = _saved_tickets
	GameState.inventory = _saved_inventory
	GameState.gacha_token = _saved_token
	GameState.last_run_abyss_notices = _saved_notices
	_AbyssWeaponEffects.reset_combat()


func test_five_weapons_and_passives_exist() -> void:
	for wid: String in _AbyssLegendaryWeapons.WEAPON_IDS:
		var data: Resource = DataRegistry.get_weapon_data(wid)
		assert_not_null(data, "weapon %s" % wid)
		assert_eq(int(data.rarity), 3)
		var pid: String = str(data.fixed_passive_id)
		assert_true(pid.begins_with("eq_abyss_"), pid)
		var def: Dictionary = CombatPassives.get_def(pid)
		assert_false(def.is_empty(), pid)
		assert_eq(str(def.get("category", "")), "weapon")


func test_biome_mapping() -> void:
	assert_eq(_AbyssLegendaryWeapons.weapon_id_for_abyss("abyss_mourngate"), "abyss_veinblade")
	assert_eq(_AbyssLegendaryWeapons.weapon_id_for_abyss("abyss_whisperwood"), "abyss_rootfang")
	assert_eq(_AbyssLegendaryWeapons.weapon_id_for_abyss("abyss_mistfen"), "abyss_mirestaff")
	assert_eq(_AbyssLegendaryWeapons.weapon_id_for_abyss("abyss_blackshore"), "abyss_netherbow")
	assert_eq(_AbyssLegendaryWeapons.weapon_id_for_abyss("abyss_frostridge"), "abyss_riftclaw")


func test_99_first_grants_legendary_weapon() -> void:
	var before: int = GameState.inventory.size()
	var g: Array = _AbyssMilestoneRewards.try_claim_for_floor("abyss_mourngate", 99)
	assert_eq(g.size(), 1)
	assert_eq(str(g[0].get("kind", "")), "first")
	assert_eq(GameState.inventory.size(), before + 1)
	var inst: Resource = GameState.inventory.back()
	assert_eq(str(inst.weapon_id), "abyss_veinblade")
	assert_true(bool(inst.is_appraised))
	var notices: Array = GameState.last_run_abyss_notices
	var joined: String = " ".join(PackedStringArray(notices))
	assert_true(joined.contains("虚脈の大剣"), joined)


func test_99_repeat_does_not_regrant_weapon() -> void:
	_AbyssMilestoneRewards.try_claim_for_floor("abyss_whisperwood", 99)
	var after_first: int = GameState.inventory.size()
	GameState.last_run_abyss_notices = []
	_AbyssMilestoneRewards.try_claim_for_floor("abyss_whisperwood", 99)
	assert_eq(GameState.inventory.size(), after_first)


func test_rootfang_same_target_stacks() -> void:
	## 装備をモック: party member 0 に rootfang
	var member: Resource = GameState.party_members[0] if GameState.party_members.size() > 0 else null
	if member == null:
		pending("no party member")
		return
	var saved_w: Resource = member.equipped_weapon
	var winst = _WeaponInstance.new()
	winst.instance_id = "test_rootfang"
	winst.weapon_id = "abyss_rootfang"
	winst.is_appraised = true
	member.equipped_weapon = winst
	_AbyssWeaponEffects.reset_combat()
	assert_eq(_AbyssWeaponEffects.outgoing_multiplier(0, 0, 1.0), 1.0)
	_AbyssWeaponEffects.after_attack_hit(0, 0, 10)
	assert_almost_eq(_AbyssWeaponEffects.outgoing_multiplier(0, 0, 1.0), 1.08, 0.001)
	_AbyssWeaponEffects.after_attack_hit(0, 0, 10)
	assert_almost_eq(_AbyssWeaponEffects.outgoing_multiplier(0, 0, 1.0), 1.16, 0.001)
	## 対象変更でリセット
	_AbyssWeaponEffects.after_attack_hit(0, 1, 10)
	assert_almost_eq(_AbyssWeaponEffects.outgoing_multiplier(0, 1, 1.0), 1.08, 0.001)
	assert_eq(_AbyssWeaponEffects.outgoing_multiplier(0, 0, 1.0), 1.0)
	member.equipped_weapon = saved_w


func test_tide_mark_burst_at_threshold() -> void:
	var member: Resource = GameState.party_members[0] if GameState.party_members.size() > 0 else null
	if member == null:
		pending("no party member")
		return
	var saved_w: Resource = member.equipped_weapon
	var winst = _WeaponInstance.new()
	winst.instance_id = "test_nether"
	winst.weapon_id = "abyss_netherbow"
	winst.is_appraised = true
	member.equipped_weapon = winst
	_AbyssWeaponEffects.reset_combat()
	assert_eq(_AbyssWeaponEffects.after_attack_hit(0, 2, 100), 0)
	assert_eq(_AbyssWeaponEffects.after_attack_hit(0, 2, 100), 0)
	assert_eq(_AbyssWeaponEffects.after_attack_hit(0, 2, 100), 0)
	var burst: int = _AbyssWeaponEffects.after_attack_hit(0, 2, 100)
	assert_eq(burst, 150)
	member.equipped_weapon = saved_w


func test_veinblade_missing_hp_bonus() -> void:
	var member: Resource = GameState.party_members[0] if GameState.party_members.size() > 0 else null
	if member == null:
		pending("no party member")
		return
	var saved_w: Resource = member.equipped_weapon
	var winst = _WeaponInstance.new()
	winst.instance_id = "test_vein"
	winst.weapon_id = "abyss_veinblade"
	winst.is_appraised = true
	member.equipped_weapon = winst
	assert_eq(_AbyssWeaponEffects.outgoing_multiplier(0, 0, 1.0), 1.0)
	assert_almost_eq(_AbyssWeaponEffects.outgoing_multiplier(0, 0, 0.0), 1.40, 0.001)
	assert_almost_eq(_AbyssWeaponEffects.outgoing_multiplier(0, 0, 0.5), 1.20, 0.001)
	member.equipped_weapon = saved_w


func test_is_abyss_legendary_helper() -> void:
	assert_true(_AbyssLegendaryWeapons.is_abyss_legendary_id("abyss_veinblade"))
	assert_false(_AbyssLegendaryWeapons.is_abyss_legendary_id("consecrated_maul"))
