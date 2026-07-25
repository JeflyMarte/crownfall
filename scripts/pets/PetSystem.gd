class_name PetSystem
extends RefCounted

## 随伴オトモ runtime（P3-PET-OTOMO-001 / P3-PET-VARIANT-001）。

const STARTER_PET_ID: String = "pet_jack"
const PET_ASH_ID: String = "pet_ash"
const PET_INK_ID: String = "pet_ink"
const PET_DATA_PATH: String = "res://resources/pets/%s.tres"
const PLACEHOLDER_SPRITE: String = "res://resources/animation/PET_Jack.tres"
## 陣形UI外の固定前衛スロット（DungeonScene FORMATION_SLOT_RATIOS[4]）
const PET_FORMATION_SLOT: int = 4
## 前衛固定のため「低Threatで狙われうる」（P3-PET-OTOMO-001-6）。
## 旧 0.55 は max_threat 選択下で人間（≥1.0）がいる限り一度も狙われず無敵に見えた。
## 雑魚職(1.0)より少し高く、剣士(2.0)／盾(4.0)より低く保つ。
const PET_THREAT_BASE: float = 1.35

## stage_id → 解放ペット id（U1）
const UNLOCK_STAGE_TO_PET: Dictionary = {
	"mourngate_1_5": PET_ASH_ID,
	"whisperwood_2_5": PET_INK_ID,
}


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
	# オトモは装備枠1の人間ルール外（固定スキル列をそのまま持つ）。
	if skills.is_empty():
		skills.append("pet_nibble")
		skills.append("pet_pounce")
	adv.equipped_skill_ids = skills
	return adv


static func ensure_owned_pets_seeded() -> void:
	if GameState.owned_pet_ids.is_empty():
		GameState.owned_pet_ids = [STARTER_PET_ID]
	elif not GameState.owned_pet_ids.has(STARTER_PET_ID):
		GameState.owned_pet_ids.insert(0, STARTER_PET_ID)


static func owns_pet(pet_id: String) -> bool:
	ensure_owned_pets_seeded()
	return GameState.owned_pet_ids.has(pet_id)


static func owned_pet_ids_ordered() -> Array[String]:
	ensure_owned_pets_seeded()
	var order: Array[String] = [STARTER_PET_ID, PET_ASH_ID, PET_INK_ID]
	var out: Array[String] = []
	for pid in order:
		if GameState.owned_pet_ids.has(pid):
			out.append(pid)
	for pid_v in GameState.owned_pet_ids:
		var pid: String = str(pid_v)
		if not out.has(pid) and is_pet_id(pid):
			out.append(pid)
	return out


static func unlock_pet(pet_id: String, notify: bool = true) -> bool:
	if not is_pet_id(pet_id) or get_pet_data(pet_id) == null:
		return false
	ensure_owned_pets_seeded()
	if GameState.owned_pet_ids.has(pet_id):
		return false
	GameState.owned_pet_ids.append(pet_id)
	if notify:
		var data: Resource = get_pet_data(pet_id)
		var name_str: String = str(data.display_name) if data != null else pet_id
		const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")
		_ContentUnlockNotice._queue_entry("pet", pet_id, "随伴ペット「%s」" % name_str)
	return true


static func sync_unlocks_from_stage_progress(notify: bool = true) -> void:
	ensure_owned_pets_seeded()
	for stage_id_v in UNLOCK_STAGE_TO_PET.keys():
		var stage_id: String = str(stage_id_v)
		var pet_id: String = str(UNLOCK_STAGE_TO_PET[stage_id])
		## ノーマル章クリア（tiers 無しの legacy cleared も可）
		if GameState.is_stage_cleared(stage_id):
			unlock_pet(pet_id, notify)


static func set_active_pet_id(pet_id: String) -> bool:
	if not owns_pet(pet_id):
		return false
	var old: Resource = GameState.active_pet
	var neu: Resource = create_pet_adventurer(pet_id)
	if old != null and is_pet_member(old):
		neu.level = int(old.level)
		neu.exp = int(old.exp)
		neu.tactics_id = str(old.tactics_id)
		if old.base_stats != null:
			var stats_class = load("res://scripts/domain/Stats.gd")
			var stats = stats_class.new()
			stats.hp = int(old.base_stats.hp)
			stats.attack = int(old.base_stats.attack)
			stats.defense = int(old.base_stats.defense)
			neu.base_stats = stats
		## スキルは個体固定（三角役割）。切替時に持ち越さない。
	sync_pet_runtime(neu)
	GameState.active_pet = neu
	return true


static func ensure_starter_pet() -> Resource:
	ensure_owned_pets_seeded()
	if GameState.active_pet != null and is_pet_member(GameState.active_pet):
		## 所持外の id が残っていたらジャックへ戻す
		if not owns_pet(str(GameState.active_pet.id)):
			set_active_pet_id(STARTER_PET_ID)
		else:
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
	## 表示名・スキルは PetData を正に（セーブ汚染／切替持ち越し防止）
	var data: Resource = get_pet_data(str(pet.id))
	if data != null and not str(data.display_name).is_empty():
		pet.display_name = str(data.display_name)
	var skills: Array[String] = []
	if data != null:
		for sid in data.skill_ids:
			var s: String = str(sid)
			if not s.is_empty() and not skills.has(s):
				skills.append(s)
	if skills.is_empty():
		skills.append("pet_nibble")
		skills.append("pet_pounce")
	pet.equipped_skill_ids = skills
