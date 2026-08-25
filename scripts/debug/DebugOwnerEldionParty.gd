class_name DebugOwnerEldionParty
extends RefCounted

## オーナー実機パーティ相当（エルディオン検証用）。
## 画面ステに合わせて Lv／装備実効値／装備スキルを寄せる。パッシブはキャラ固有がそのまま発火。

const _RosterUiHelper := preload("res://scripts/roster/RosterUiHelper.gd")
const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")

## 表示ステ目標（オーナー添付スクショ）。編成順＝前衛寄り→後衛。
const TARGETS: Array[Dictionary] = [
	{
		"kind": "helper",
		"helper_id": "helper_a",
		"level": 49,
		"hp": 5533,
		"attack": 1384,
		"defense": 2164,
		"speed": 1.0,
		"crit": 0.12,
		"skill": "drain_slash",
		"front": true,
	},
	{
		"kind": "starter",
		"adventurer_id": "adventurer_0",
		"level": 45,
		"hp": 3848,
		"attack": 1838,
		"defense": 1388,
		"speed": 1.3,
		"crit": 0.41,
		"skill": "blade_tempest",
		"front": true,
	},
	{
		"kind": "helper",
		"helper_id": "helper_m",
		"level": 51,
		"hp": 3410,
		"attack": 2218,
		"defense": 1553,
		"speed": 1.15,
		"crit": 0.0,
		"crit_damage": 1.73,
		"skill": "aimed_shot",
		"front": false,
	},
	{
		"kind": "starter",
		"adventurer_id": "adventurer_2",
		"level": 57,
		"hp": 4044,
		"attack": 1700,
		"defense": 1679,
		"speed": 1.1,
		"crit": 0.19,
		"skill": "mend",
		"front": false,
	},
]

const PET_TARGET: Dictionary = {
	"level": 47,
	"hp": 2958,
	"attack": 821,
	"defense": 426,
	"speed": 1.0,
	"crit": 0.0,
	"skill": "pet_jack_frenzy",
}


static func apply() -> void:
	GameState.reset_for_new_game()
	GameState.debug_full_unlock = true
	GameState.debug_start_at_boss = true
	GameState.gold = 99999
	GameState.gacha_token = 9999
	GameState.seed_all_starters_unlocked()
	GameState.starter_pick_pending = false
	GameState.owned_helpers.clear()
	GameState.owned_helpers["helper_a"] = 1
	GameState.owned_helpers["helper_m"] = 1
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()

	var by_id: Dictionary = {}
	for m: Variant in GameState.roster:
		if m != null:
			by_id[str(m.id)] = m

	var party: Array = []
	for spec: Dictionary in TARGETS:
		var member: Resource = null
		if str(spec.get("kind", "")) == "helper":
			var helper: Resource = DataRegistry.get_gacha_helper_data(str(spec.get("helper_id", "")))
			member = GachaSystem.create_adventurer_from_helper(helper)
			GameState.add_roster_member(member)
		else:
			var aid: String = str(spec.get("adventurer_id", ""))
			member = by_id.get(aid, null)
			if member == null:
				push_error("DebugOwnerEldionParty: missing %s" % aid)
				continue
		member.level = int(spec.get("level", 1))
		member.exp = 0
		member.formation_row = 0 if bool(spec.get("front", true)) else 1
		_fit_member_stats(member, spec)
		_equip_skill(member, str(spec.get("skill", "")))
		party.append(member)

	## ロスターをパーティ＋余りスターターに整える。
	GameState.roster.clear()
	for p: Variant in party:
		GameState.roster.append(p)
	for leftover: Variant in by_id.values():
		if leftover == null:
			continue
		var lid: String = str(leftover.id)
		var in_party := false
		for p2: Variant in party:
			if p2 != null and str(p2.id) == lid:
				in_party = true
				break
		if not in_party:
			GameState.roster.append(leftover)
	GameState.party_members = party

	_PetSystem.unlock_pet(_PetSystem.STARTER_PET_ID, false)
	_PetSystem.grant_starter_pet()
	if GameState.active_pet != null:
		GameState.active_pet.level = int(PET_TARGET.get("level", 47))
		GameState.active_pet.exp = 0
		_fit_member_stats(GameState.active_pet, PET_TARGET)
		_equip_skill(GameState.active_pet, str(PET_TARGET.get("skill", "")))

	GameState.normalize_all_equipped_skills()
	GameState.normalize_all_equipped_passives()
	GameState.migrate_formation_slots_if_needed()
	_unlock_frostridge_progress()
	GameState.current_dungeon_id = "frostridge"
	GameState.current_stage_id = "frostridge_5_5"
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL


static func _equip_skill(member: Resource, skill_id: String) -> void:
	if member == null or skill_id.is_empty():
		return
	var ids: Array[String] = [skill_id]
	member.equipped_skill_ids = ids


static func _fit_member_stats(member: Resource, spec: Dictionary) -> void:
	if member == null:
		return
	member.level = int(spec.get("level", member.level))
	member.exp = 0
	var target_hp: int = int(spec.get("hp", 0))
	var target_atk: int = int(spec.get("attack", 0))
	var target_def: int = int(spec.get("defense", 0))
	var target_spd: float = float(spec.get("speed", 1.0))
	var target_crit: float = float(spec.get("crit", 0.0))
	var target_cdmg: float = float(spec.get("crit_damage", BalanceConfig.CRITICAL_MULTIPLIER))

	var wpn_id: String = _preferred_weapon_id(str(member.job_id))
	var winst: Resource = WeaponInstance.new()
	winst.instance_id = "probe_wpn_%s" % str(member.id)
	winst.weapon_id = wpn_id
	winst.is_appraised = true
	## 表示ステ合わせは equip_level=1 で行い、レベル成長分と二重に跳ねないようにする。
	winst.equip_level = 1
	winst.equip_exp = 0
	winst.attack_speed = maxf(0.5, target_spd)
	winst.critical_rate = clampf(target_crit, 0.0, 0.95)
	winst.critical_damage = maxf(1.0, target_cdmg)
	## 装備実効は 0 にし、表示ステは base_stats で合わせる（二重スケール防止）。
	winst.rolled_attack = 0
	winst.enhance_level = 0
	winst.random_mods = []
	winst.element_power = 0
	member.equipped_weapon = winst

	var ainst: Resource = ArmorInstance.new()
	ainst.instance_id = "probe_arm_%s" % str(member.id)
	ainst.armor_id = "bone_armor"
	ainst.is_appraised = true
	ainst.rarity = 2
	ainst.equip_level = 1
	ainst.rolled_defense = 0
	ainst.hp_bonus = 0
	ainst.enhance_level = 0
	ainst.random_mods = []
	member.equipped_armor = ainst
	member.equipped_accessory = null

	_force_display_stats(member, target_hp, target_atk, target_def)


static func _preferred_weapon_id(job_id: String) -> String:
	match job_id:
		"swordsman", "vanguard":
			return "iron_sword"
		"ranger", "beast_tamer", "engineer":
			return "hunting_bow"
		"alchemist":
			return "apprentice_staff"
		_:
			return "rusted_blade"


## base_stats を二分探索して表示 HP/ATK/DEF を目標に合わせる。
static func _force_display_stats(member: Resource, target_hp: int, target_atk: int, target_def: int) -> void:
	if member == null or member.base_stats == null:
		return
	_bin_fit_base(member, "hp", target_hp)
	_bin_fit_base(member, "attack", target_atk)
	_bin_fit_base(member, "defense", target_def)


static func _bin_fit_base(member: Resource, key: String, target: int) -> void:
	if target <= 0:
		return
	var lo := 0
	var hi := 20000
	while lo < hi:
		var mid: int = (lo + hi) / 2
		match key:
			"hp":
				member.base_stats.hp = mid
			"attack":
				member.base_stats.attack = mid
			_:
				member.base_stats.defense = mid
		var got: int = int(_RosterUiHelper.compute_member_stats(member).get(key, 0))
		if got < target:
			lo = mid + 1
		else:
			hi = mid
	match key:
		"hp":
			member.base_stats.hp = maxi(1, lo)
		"attack":
			member.base_stats.attack = maxi(0, lo)
		_:
			member.base_stats.defense = maxi(0, lo)
	## 端数を最後に補正
	var got2: int = int(_RosterUiHelper.compute_member_stats(member).get(key, 0))
	var delta: int = target - got2
	if delta != 0:
		match key:
			"hp":
				member.base_stats.hp = maxi(1, int(member.base_stats.hp) + delta)
			"attack":
				member.base_stats.attack = maxi(0, int(member.base_stats.attack) + delta)
			_:
				member.base_stats.defense = maxi(0, int(member.base_stats.defense) + delta)


static func _unlock_frostridge_progress() -> void:
	for biome: String in ["mourngate", "whisperwood", "mistfen", "blackshore", "frostridge"]:
		var n: int = _biome_num(biome)
		for ch: int in range(1, 6):
			GameState.mark_stage_cleared("%s_%d_%d" % [biome, n, ch], _DungeonTierConfig.TIER_NORMAL)
	GameState.mark_dungeon_cleared("frostridge")


static func _biome_num(biome: String) -> int:
	match biome:
		"mourngate":
			return 1
		"whisperwood":
			return 2
		"mistfen":
			return 3
		"blackshore":
			return 4
		"frostridge":
			return 5
		_:
			return 1


static func dump_party_stats() -> void:
	print("=== Probe party stats ===")
	for m: Variant in GameState.party_members:
		if m == null:
			continue
		var st: Dictionary = _RosterUiHelper.compute_member_stats(m)
		print(
			"%s Lv%d HP%d ATK%d DEF%d SPD%.2f skills=%s"
			% [
				str(m.display_name),
				int(m.level),
				int(st.get("hp", 0)),
				int(st.get("attack", 0)),
				int(st.get("defense", 0)),
				float(st.get("speed", 0.0)),
				str(GameState.get_equipped_skill_ids(m)),
			]
		)
	if GameState.active_pet != null:
		var pst: Dictionary = _RosterUiHelper.compute_member_stats(GameState.active_pet)
		print(
			"%s Lv%d HP%d ATK%d DEF%d skills=%s"
			% [
				str(GameState.active_pet.display_name),
				int(GameState.active_pet.level),
				int(pst.get("hp", 0)),
				int(pst.get("attack", 0)),
				int(pst.get("defense", 0)),
				str(GameState.get_equipped_skill_ids(GameState.active_pet)),
			]
		)
