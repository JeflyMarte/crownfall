extends Node

# 所持ゴールド（MVP: 鑑定費用のみ消費）
var gold: int = 0

# 編成中の冒険者リスト（Adventurer Resource × 3）
var party_members: Array = []

# 所持アイテムリスト（WeaponInstance。未鑑定・鑑定済み混在）
var inventory: Array = []

# 現在選択中のダンジョンID
var current_dungeon_id: String = ""

# ダンジョン別の発見度・解放状態 { dungeon_id: { discovery: float, hidden_room: bool, hidden_boss: bool } }
var dungeon_progress: Dictionary = {}

# 発見登録 { "category:entry_id": true } — Codex 基盤（P2-Task018）
var discovery_registry: Dictionary = {}

# チュートリアル進行フラグ { flag_name: bool }
var tutorial_flags: Dictionary = {}

var armor_inventory: Array = []
var accessory_inventory: Array = []

var last_run_exp_reward: int = 0
var last_run_gold_reward: int = 0
var last_run_weapon_dropped: String = ""
var last_run_armor_dropped: String = ""
var last_run_accessory_dropped: String = ""
# 直近ランの獲得レベル { member_id: gained_levels } — Result 表示用（P3-D035）
var last_run_level_ups: Dictionary = {}

# 素材インベントリ { material_id: quantity } — P2-Task024
var material_inventory: Dictionary = {}

func get_active_dungeon_id() -> String:
	if current_dungeon_id.is_empty():
		return Constants.DEFAULT_DUNGEON_ID
	return current_dungeon_id

func get_member(member_index: int) -> Resource:
	if member_index < 0 or member_index >= party_members.size():
		return null
	return party_members[member_index]

func get_member_equipped_weapon(member_index: int) -> Resource:
	var member: Resource = get_member(member_index)
	if member == null:
		return null
	return member.equipped_weapon

func get_member_equipped_armor(member_index: int) -> Resource:
	var member: Resource = get_member(member_index)
	if member == null:
		return null
	return member.equipped_armor

func get_member_equipped_accessory(member_index: int) -> Resource:
	var member: Resource = get_member(member_index)
	if member == null:
		return null
	return member.equipped_accessory

func find_item_equipped_member_index(item: Resource) -> int:
	if item == null:
		return -1
	for i in party_members.size():
		var member: Resource = party_members[i]
		if member == null:
			continue
		if (
			member.equipped_weapon == item
			or member.equipped_armor == item
			or member.equipped_accessory == item
		):
			return i
	return -1

func clear_item_from_other_members(item: Resource, keep_member_index: int) -> void:
	if item == null:
		return
	for i in party_members.size():
		if i == keep_member_index:
			continue
		var member: Resource = party_members[i]
		if member == null:
			continue
		if member.equipped_weapon == item:
			member.equipped_weapon = null
		if member.equipped_armor == item:
			member.equipped_armor = null
		if member.equipped_accessory == item:
			member.equipped_accessory = null

# 新規ゲーム時にジョブごとへ付与する初期武器 { job_id: weapon_id }
const STARTING_WEAPON_BY_JOB: Dictionary = {
	"swordsman": "iron_sword",
	"ranger": "hunting_bow",
	"alchemist": "apprentice_staff",
}

func _ready() -> void:
	_init_party()

func _init_party() -> void:
	var adventurer_class = load("res://scripts/domain/Adventurer.gd")
	var stats_class = load("res://scripts/domain/Stats.gd")

	var swordsman = adventurer_class.new()
	swordsman.id = "adventurer_0"
	swordsman.display_name = "ソードマン"
	swordsman.job_id = "swordsman"
	swordsman.base_stats = stats_class.new()

	var ranger = adventurer_class.new()
	ranger.id = "adventurer_1"
	ranger.display_name = "レンジャー"
	ranger.job_id = "ranger"
	ranger.base_stats = stats_class.new()

	var alchemist = adventurer_class.new()
	alchemist.id = "adventurer_2"
	alchemist.display_name = "アルケミスト"
	alchemist.job_id = "alchemist"
	alchemist.base_stats = stats_class.new()

	party_members = [swordsman, ranger, alchemist]
	_grant_starting_equipment()

# 初期武器を生成し、inventory に登録した上で装備させる。
# 装備品が inventory に存在することは SaveManager の装備復元（instance_id 解決）の前提。
func _grant_starting_equipment() -> void:
	for member in party_members:
		if member == null or member.equipped_weapon != null:
			continue
		var weapon_id: String = str(STARTING_WEAPON_BY_JOB.get(member.job_id, ""))
		if weapon_id.is_empty():
			continue
		var instance: Resource = _create_starting_weapon(weapon_id)
		if instance == null:
			continue
		inventory.append(instance)
		member.equipped_weapon = instance

func _create_starting_weapon(weapon_id: String) -> Resource:
	var weapon_data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if weapon_data == null:
		return null
	var instance_class = load("res://scripts/domain/WeaponInstance.gd")
	if instance_class == null:
		return null
	var instance = instance_class.new()
	instance.instance_id = "starting_" + weapon_id
	instance.weapon_id = weapon_id
	instance.is_appraised = true
	instance.rolled_attack = weapon_data.base_attack
	instance.attack_speed = weapon_data.base_attack_speed
	instance.critical_rate = weapon_data.base_critical_rate
	instance.knockback = weapon_data.base_knockback
	instance.stagger_power = weapon_data.base_stagger_power
	instance.attack_range = weapon_data.base_attack_range
	instance.weight = weapon_data.weight
	return instance

func add_material(material_id: String, amount: int = 1) -> void:
	if material_id.is_empty() or amount <= 0:
		return
	var current: int = int(material_inventory.get(material_id, 0))
	material_inventory[material_id] = current + amount

func get_material_quantity(material_id: String) -> int:
	return int(material_inventory.get(material_id, 0))

func consume_materials(required_materials: Dictionary) -> bool:
	for mat_id in required_materials:
		if get_material_quantity(mat_id) < int(required_materials[mat_id]):
			return false
	for mat_id in required_materials:
		material_inventory[mat_id] = get_material_quantity(mat_id) - int(required_materials[mat_id])
	print("[GameState] consume_materials: ", required_materials)
	return true
