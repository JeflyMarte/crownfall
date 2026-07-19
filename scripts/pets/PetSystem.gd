class_name PetSystem
extends RefCounted

## 随伴オトモ runtime（P3-PET-OTOMO-001）。

const STARTER_PET_ID: String = "pet_jack"
const PET_DATA_PATH: String = "res://resources/pets/%s.tres"
const PLACEHOLDER_SPRITE: String = "res://resources/animation/ENM_CrownEaterRat.tres"
## 陣形UI外の固定前衛スロット（DungeonScene FORMATION_SLOT_RATIOS[4]）
const PET_FORMATION_SLOT: int = 4
const PET_THREAT_BASE: float = 0.55


static func is_pet_id(member_id: String) -> bool:
	return member_id.begins_with("pet_")


static func is_pet_member(member: Resource) -> bool:
	return member != null and is_pet_id(str(member.id))


static func get_pet_data(pet_id: String) -> Resource:
	if pet_id.is_empty():
		return null
	var path: String = PET_DATA_PATH % pet_id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Resource


static func sprite_path_for(member: Resource) -> String:
	if not is_pet_member(member):
		return ""
	var data: Resource = get_pet_data(str(member.id))
	if data != null:
		var path: String = str(data.sprite_resource_path)
		if not path.is_empty() and ResourceLoader.exists(path):
			return path
	if ResourceLoader.exists(PLACEHOLDER_SPRITE):
		return PLACEHOLDER_SPRITE
	return ""


static func create_pet_adventurer(pet_id: String = STARTER_PET_ID) -> Resource:
	var data: Resource = get_pet_data(pet_id)
	var adventurer_class = load("res://scripts/domain/Adventurer.gd")
	var adv = adventurer_class.new()
	adv.id = pet_id if data == null else str(data.id)
	adv.display_name = "ジャック" if data == null else str(data.display_name)
	adv.job_id = ""
	adv.rarity = 1 if data == null else clampi(int(data.rarity), 1, 1)
	adv.level = 1
	adv.exp = 0
	adv.formation_row = 0
	adv.formation_slot = 0
	adv.passive_slots_customized = true
	var empty_passives: Array[String] = []
	adv.equipped_passive_ids = empty_passives
	adv.tactics_id = "balanced"
	var stats_class = load("res://scripts/domain/Stats.gd")
	var stats = stats_class.new()
	if data != null and data.base_stats != null:
		stats.hp = int(data.base_stats.hp)
		stats.attack = int(data.base_stats.attack)
		stats.defense = int(data.base_stats.defense)
	else:
		stats.hp = 420
		stats.attack = 70
		stats.defense = 35
	adv.base_stats = stats
	var skills: Array[String] = []
	if data != null:
		for sid in data.skill_ids:
			var s: String = str(sid)
			if not s.is_empty() and not skills.has(s):
				skills.append(s)
			if skills.size() >= Constants.MAX_EQUIPPED_SKILLS:
				break
	if skills.is_empty():
		skills.append("pet_nibble")
		skills.append("pet_pounce")
	adv.equipped_skill_ids = skills
	return adv


static func ensure_starter_pet() -> Resource:
	if GameState.active_pet != null and is_pet_member(GameState.active_pet):
		sync_pet_runtime(GameState.active_pet)
		return GameState.active_pet
	GameState.active_pet = create_pet_adventurer(STARTER_PET_ID)
	return GameState.active_pet


static func sync_pet_runtime(pet: Resource) -> void:
	if pet == null:
		return
	pet.rarity = 1
	pet.job_id = ""
	pet.equipped_weapon = null
	pet.equipped_armor = null
	pet.equipped_accessory = null
	pet.passive_slots_customized = true
	var empty_passives: Array[String] = []
	pet.equipped_passive_ids = empty_passives
	pet.formation_row = 0
	if pet.equipped_skill_ids.is_empty():
		var data: Resource = get_pet_data(str(pet.id))
		var skills: Array[String] = []
		if data != null:
			for sid in data.skill_ids:
				var s: String = str(sid)
				if not s.is_empty() and not skills.has(s):
					skills.append(s)
				if skills.size() >= Constants.MAX_EQUIPPED_SKILLS:
					break
		if skills.is_empty():
			skills.append("pet_nibble")
			skills.append("pet_pounce")
		pet.equipped_skill_ids = skills
