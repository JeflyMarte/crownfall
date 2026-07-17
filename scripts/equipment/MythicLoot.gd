class_name MythicLoot
extends RefCounted

## 神話装備ドロップ SSOT（P3-EQ-MYTHIC-001）。通常レア抽選には載せない。

const CHANCE: float = 0.01
const BIOME_ID: String = "mourngate"

const WEAPON_ID: String = "burial_crown_greatsword"
const ARMOR_ID: String = "immortal_cenotaph_plate"
const ACCESSORY_ID: String = "council_hegemony_seal"

const POOL: Array[Dictionary] = [
	{"category": "weapon", "id": WEAPON_ID},
	{"category": "armor", "id": ARMOR_ID},
	{"category": "accessory", "id": ACCESSORY_ID},
]


static func is_mythic_id(item_id: String) -> bool:
	return item_id == WEAPON_ID or item_id == ARMOR_ID or item_id == ACCESSORY_ID


static func owns_id(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	for w in GameState.inventory:
		if w != null and "weapon_id" in w and str(w.weapon_id) == item_id:
			return true
	for a in GameState.armor_inventory:
		if a != null and str(a.armor_id) == item_id:
			return true
	for acc in GameState.accessory_inventory:
		if acc != null and str(acc.accessory_id) == item_id:
			return true
	return false


static func unowned_pool() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in POOL:
		if not owns_id(str(entry["id"])):
			out.append(entry)
	return out


## ボス再クリア時のみ。成功時 {category, id}、失敗時空。
static func roll_for_boss_reclear(stage: Resource, rng: RandomNumberGenerator = null) -> Dictionary:
	var empty: Dictionary = {}
	if stage == null or not bool(stage.has_boss_floor()):
		return empty
	var stage_id: String = str(stage.id)
	var dungeon_id: String = str(GameState.current_dungeon_id)
	if dungeon_id.is_empty() and stage_id.begins_with(BIOME_ID):
		dungeon_id = BIOME_ID
	if dungeon_id != BIOME_ID and not stage_id.begins_with(BIOME_ID):
		return empty
	if not GameState.is_stage_cleared(stage_id, GameState.current_dungeon_tier):
		return empty
	var roll: float = rng.randf() if rng != null else randf()
	if roll > CHANCE:
		return empty
	var candidates: Array[Dictionary] = unowned_pool()
	if candidates.is_empty():
		candidates = POOL.duplicate()
	var idx: int = rng.randi_range(0, candidates.size() - 1) if rng != null else randi() % candidates.size()
	return candidates[idx].duplicate()
