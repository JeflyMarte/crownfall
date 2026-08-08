class_name PetSystem
extends RefCounted

## 随伴ペット runtime（P3-PET-OTOMO-001 / P3-PET-VARIANT-001）。

const _CombatTactics := preload("res://scripts/combat/CombatTactics.gd")
const STARTER_PET_ID: String = "pet_jack"
const PET_ASH_ID: String = "pet_ash"
const PET_INK_ID: String = "pet_ink"
const PET_DATA_PATH: String = "res://resources/pets/%s.tres"
const PLACEHOLDER_SPRITE: String = "res://resources/animation/PET_Jack.tres"
## 陣形UI外の固定前衛スロット（DungeonScene FORMATION_SLOT_RATIOS[4]）
const PET_FORMATION_SLOT: int = 4
## 前衛固定のため「低Threatで狙われうる」（P3-PET-OTOMO-001-6）。
## P3-BAL-PET-EVADE-THREAT-001 案C: 後列雑魚職相当（FORMATION_BACK_THREAT×1.0＝0.6）以下。
const PET_THREAT_BASE: float = 0.6
## ペット既定回避率（装備不可のため装備回避が乗らない穴を埋める）。
const PET_BASE_EVASION_RATE: float = 0.20
## はじめガイド後のギルド支給完了フラグ（tutorial_flags）。
const STARTER_PET_GRANTED_FLAG: String = "starter_pet_granted"

## ダンジョン SURVEY 100%（完全調査）→ 解放ペット id（P3-PET-SURVEY-UNLOCK-001）
## ジャックはガイド後のギルド支給（本表に載せない）。
const UNLOCK_SURVEY_TO_PET: Dictionary = {
	"whisperwood": PET_ASH_ID,
	"blackshore": PET_INK_ID,
}


static func is_starter_pet_granted() -> bool:
	return bool(GameState.tutorial_flags.get(STARTER_PET_GRANTED_FLAG, false))


## ギルド支給（はじめガイド後の加入演出／テスト用）。既に所持なら active を整えるだけ。
static func grant_starter_pet() -> Resource:
	GameState.tutorial_flags[STARTER_PET_GRANTED_FLAG] = true
	ensure_owned_pets_seeded()
	return ensure_starter_pet()


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
	## 三角役割の既定方針。プレイヤー設定（pet_tactics_ids）があればそれを優先。
	var saved_tid: String = str(GameState.pet_tactics_ids.get(pet_id, "")).strip_edges()
	if not saved_tid.is_empty():
		adv.tactics_id = _CombatTactics.normalize_id(saved_tid)
	elif pet_id == STARTER_PET_ID:
		adv.tactics_id = "support_focus"
	elif pet_id == PET_ASH_ID:
		adv.tactics_id = "attack_focus"
	else:
		adv.tactics_id = "balanced"
	var stats_class = load("res://scripts/domain/Stats.gd")
	var stats = stats_class.new()
	if data != null and data.base_stats != null:
		stats.hp = int(data.base_stats.hp)
		stats.attack = int(data.base_stats.attack)
		stats.defense = int(data.base_stats.defense)
	else:
		## P3-BAL-PET-STAT-DIVERGE-001: PetData 欠落時のフォールバック（インク基準）
		stats.hp = 630
		stats.attack = 105
		stats.defense = 53
	adv.base_stats = stats
	## ペットも装備枠1。解放済み先頭を既定装備（P3-PET-SKILL-001）。
	SkillProgression.apply_pet_new_skill_unlocks(adv)
	if adv.equipped_skill_ids.is_empty():
		var fallback_id: String = "pet_jack_frenzy"
		if pet_id == PET_ASH_ID:
			fallback_id = "pet_ash_bark"
		elif pet_id == PET_INK_ID:
			fallback_id = "pet_ink_toxin"
		var fallback: Array[String] = [fallback_id]
		adv.equipped_skill_ids = fallback
	return adv


static func ensure_owned_pets_seeded() -> void:
	## ジャックはガイド後支給まで所持に入れない。
	if not is_starter_pet_granted():
		return
	if GameState.owned_pet_ids.is_empty():
		GameState.owned_pet_ids = [STARTER_PET_ID]
	elif not GameState.owned_pet_ids.has(STARTER_PET_ID):
		GameState.owned_pet_ids.insert(0, STARTER_PET_ID)


static func owns_pet(pet_id: String) -> bool:
	if pet_id == STARTER_PET_ID and not is_starter_pet_granted():
		return false
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
	if pet_id == STARTER_PET_ID:
		grant_starter_pet()
		return true
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


static func complete_reward_pet_id(dungeon_id: String) -> String:
	if dungeon_id.is_empty():
		return ""
	return str(UNLOCK_SURVEY_TO_PET.get(dungeon_id, ""))


static func sync_unlocks_from_survey_progress(notify: bool = true) -> void:
	ensure_owned_pets_seeded()
	const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
	const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")
	for dungeon_id_v in UNLOCK_SURVEY_TO_PET.keys():
		var dungeon_id: String = str(dungeon_id_v)
		var pet_id: String = str(UNLOCK_SURVEY_TO_PET[dungeon_id])
		if _SurveySystem.get_survey_percent(dungeon_id) + 0.001 >= _SurveyConfig.SURVEY_COMPLETE_PERCENT:
			unlock_pet(pet_id, notify)


## 互換エイリアス（旧 stage 解放呼び出しを調査解放へリダイレクト）
static func sync_unlocks_from_stage_progress(notify: bool = true) -> void:
	sync_unlocks_from_survey_progress(notify)


static func set_active_pet_id(pet_id: String) -> bool:
	if not owns_pet(pet_id):
		return false
	var old: Resource = GameState.active_pet
	var neu: Resource = create_pet_adventurer(pet_id)
	if old != null and is_pet_member(old):
		neu.level = int(old.level)
		neu.exp = int(old.exp)
		## 基礎ステは PetData を正（切替で旧セーブ値を持ち込まない）。
		## スキルは個体固定（三角役割）。切替時に持ち越さない。
		## 行動方針は個体別（pet_tactics_ids）。未設定時のみ役割既定。
	sync_pet_runtime(neu)
	GameState.active_pet = neu
	return true


static func ensure_starter_pet() -> Resource:
	if not is_starter_pet_granted():
		GameState.active_pet = null
		return null
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
	## 表示名・基礎ステ・スキルは PetData を正（セーブ汚染／切替持ち越し防止）
	var data: Resource = get_pet_data(str(pet.id))
	if data != null and not str(data.display_name).is_empty():
		pet.display_name = str(data.display_name)
	if data != null and data.base_stats != null:
		var stats_class = load("res://scripts/domain/Stats.gd")
		var stats = stats_class.new()
		stats.hp = int(data.base_stats.hp)
		stats.attack = int(data.base_stats.attack)
		stats.defense = int(data.base_stats.defense)
		pet.base_stats = stats
	## Lv から解放スキルを同期（新規解放は自動装備）
	SkillProgression.apply_pet_new_skill_unlocks(pet)
	if pet.equipped_skill_ids.is_empty():
		var fallback_id: String = "pet_jack_frenzy"
		var pid: String = str(pet.id)
		if pid == PET_ASH_ID:
			fallback_id = "pet_ash_bark"
		elif pid == PET_INK_ID:
			fallback_id = "pet_ink_toxin"
		var fallback: Array[String] = [fallback_id]
		pet.equipped_skill_ids = fallback
	## ジャックはサポート寄り方針を維持（セーブで攻撃寄りに汚れていても戻すのはしない＝装備方針は尊重）。
	## プレイヤー設定 → 未設定時のみ役割既定。
	var pid: String = str(pet.id)
	var saved_tid: String = str(GameState.pet_tactics_ids.get(pid, "")).strip_edges()
	if not saved_tid.is_empty():
		pet.tactics_id = _CombatTactics.normalize_id(saved_tid)
	elif str(pet.tactics_id).is_empty():
		if pid == STARTER_PET_ID:
			pet.tactics_id = "support_focus"
		elif pid == PET_ASH_ID:
			pet.tactics_id = "attack_focus"
		else:
			pet.tactics_id = "balanced"
