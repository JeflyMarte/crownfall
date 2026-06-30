extends Node

# 所持ゴールド（永続）
var gold: int = 0

# 編成中（アクティブ）の冒険者リスト（Adventurer Resource × 最大3）。roster の部分集合（参照）。
var party_members: Array = []

# 所持冒険者ロスター（基本5職 + ガチャ入手分）。party_members はここから3名選択（P3-D036b）。
var roster: Array = []

# ガチャ通貨（無償のみ） — P3-D036b
var gacha_token: int = 0
# ガチャ所持数 { helper_id: count }（重複＝凸用カウント。MVP は還元のみ）
var owned_helpers: Dictionary = {}
# 天井カウンタ（未所持が出ていない連続抽選回数）
var gacha_pity: int = 0

# 所持アイテムリスト（WeaponInstance）
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
# 直近ランで獲得したガチャ token（成功時のみ >0） — P3-D036b-D
var last_run_token_reward: int = 0
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

# ダンジョン選択画面の CLEAR バッジ用。ラン完走（ボス突破→EXIT 到達）時に立てる。
func mark_dungeon_cleared(dungeon_id: String) -> void:
	if dungeon_id.is_empty():
		return
	var progress: Dictionary = dungeon_progress.get(dungeon_id, {})
	progress["cleared"] = true
	dungeon_progress[dungeon_id] = progress

func is_dungeon_cleared(dungeon_id: String) -> bool:
	if dungeon_id.is_empty():
		return false
	var progress: Dictionary = dungeon_progress.get(dungeon_id, {})
	return bool(progress.get("cleared", false))

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

# ---- 装備スキル（P3-D077） ----
# ジョブ learnable_skill_ids の先頭 MAX_EQUIPPED_SKILLS 個を既定装備とする。
func get_default_skill_ids(member: Resource) -> Array[String]:
	var out: Array[String] = []
	if member == null or str(member.job_id).is_empty():
		return out
	var job: Resource = DataRegistry.get_job_data(member.job_id)
	if job == null:
		return out
	var pool: Array = job.learnable_skill_ids
	for i in mini(Constants.MAX_EQUIPPED_SKILLS, pool.size()):
		out.append(str(pool[i]))
	return out

# 現在の装備スキル。未設定（空）ならジョブ既定にフォールバック。
func get_equipped_skill_ids(member: Resource) -> Array[String]:
	if member == null:
		return [] as Array[String]
	if "equipped_skill_ids" in member and not member.equipped_skill_ids.is_empty():
		return member.equipped_skill_ids
	return get_default_skill_ids(member)

# スキルの装備/解除トグル（最大 MAX_EQUIPPED_SKILLS）。
func toggle_member_skill(member: Resource, skill_id: String) -> void:
	if member == null or skill_id.is_empty():
		return
	var ids: Array[String] = get_equipped_skill_ids(member).duplicate()
	if ids.has(skill_id):
		ids.erase(skill_id)
	elif ids.size() < Constants.MAX_EQUIPPED_SKILLS:
		ids.append(skill_id)
	else:
		return
	member.equipped_skill_ids = ids

# ---- 戦術（AI設定・P3-D086） ----
# メンバーの戦術 id（未設定/無効なら既定 "balanced"）。
func get_member_tactics_id(member: Resource) -> String:
	if member == null:
		return CombatTactics.DEFAULT_TACTICS_ID
	if "tactics_id" in member:
		return CombatTactics.normalize_id(str(member.tactics_id))
	return CombatTactics.DEFAULT_TACTICS_ID

func set_member_tactics(member: Resource, tactics_id: String) -> void:
	if member == null:
		return
	member.tactics_id = CombatTactics.normalize_id(tactics_id)

# ---- 遺物（Relics・P3-D090） ----
# メンバーの遺物 id（未設定/無効なら "" = なし）。
func get_member_relic_id(member: Resource) -> String:
	if member == null:
		return CombatRelics.NONE_ID
	if "relic_id" in member:
		return CombatRelics.normalize_id(str(member.relic_id))
	return CombatRelics.NONE_ID

func set_member_relic(member: Resource, relic_id: String) -> void:
	if member == null:
		return
	member.relic_id = CombatRelics.normalize_id(relic_id)

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
	"vanguard": "iron_sword",
	"beast_tamer": "hunting_bow",
}

# 初期ロスター（基本5職）。アクティブ3は先頭3名（P3-D036b-9）。
const BASE_ROSTER_DEFS: Array = [
	{"id": "adventurer_0", "name": "ソードマン", "job": "swordsman"},
	{"id": "adventurer_1", "name": "レンジャー", "job": "ranger"},
	{"id": "adventurer_2", "name": "アルケミスト", "job": "alchemist"},
	{"id": "adventurer_3", "name": "ヴァンガード", "job": "vanguard"},
	{"id": "adventurer_4", "name": "ビーストテイマー", "job": "beast_tamer"},
]
const ACTIVE_PARTY_SIZE: int = 3

func _ready() -> void:
	_init_party()

func _init_party() -> void:
	roster = []
	for def in BASE_ROSTER_DEFS:
		roster.append(_create_base_adventurer(def))
	party_members = []
	for i in mini(ACTIVE_PARTY_SIZE, roster.size()):
		party_members.append(roster[i])
	_grant_starting_equipment()

func _create_base_adventurer(def: Dictionary) -> Resource:
	var adventurer_class = load("res://scripts/domain/Adventurer.gd")
	var stats_class = load("res://scripts/domain/Stats.gd")
	var adv = adventurer_class.new()
	adv.id = str(def["id"])
	adv.display_name = str(def["name"])
	adv.job_id = str(def["job"])
	adv.base_stats = stats_class.new()
	return adv

# 初期武器を生成し、inventory に登録した上で装備させる（ロスター全員分）。
# 装備品が inventory に存在することは SaveManager の装備復元（instance_id 解決）の前提。
func _grant_starting_equipment() -> void:
	for member in roster:
		_grant_member_starting_weapon(member)

func _grant_member_starting_weapon(member: Resource) -> void:
	if member == null or member.equipped_weapon != null:
		return
	var weapon_id: String = str(STARTING_WEAPON_BY_JOB.get(member.job_id, ""))
	if weapon_id.is_empty():
		return
	var instance: Resource = _create_starting_weapon(member.id, weapon_id)
	if instance == null:
		return
	inventory.append(instance)
	member.equipped_weapon = instance

# 旧セーブ復元時など、ロスターに欠けている基本職を補完する（武器も付与）。
func ensure_base_roster_complete() -> void:
	for def in BASE_ROSTER_DEFS:
		if find_roster_member_by_id(str(def["id"])) != null:
			continue
		var adv: Resource = _create_base_adventurer(def)
		roster.append(adv)
		_grant_member_starting_weapon(adv)

# 旧セーブに残る基本職の display_name / job_id を現行定義へ正規化する。
# （旧名「戦士/盗賊/魔術師」等の残存を解消。基本職にカスタム改名機能は無いため上書き安全）
func normalize_base_roster() -> void:
	for def in BASE_ROSTER_DEFS:
		var m: Resource = find_roster_member_by_id(str(def["id"]))
		if m == null:
			continue
		m.display_name = str(def["name"])
		m.job_id = str(def["job"])

func _create_starting_weapon(member_id: String, weapon_id: String) -> Resource:
	var weapon_data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if weapon_data == null:
		return null
	var instance_class = load("res://scripts/domain/WeaponInstance.gd")
	if instance_class == null:
		return null
	var instance = instance_class.new()
	instance.instance_id = "starting_" + member_id + "_" + weapon_id
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

# ---- イベント助っ人（P3-D036a） ----
# ラン内一時参加。party_members に含めない（Save/EXP/装備/全滅判定対象外）。
var event_helper: Resource = null

func get_combatants() -> Array:
	if event_helper != null:
		return party_members + [event_helper]
	return party_members

func combatant_count() -> int:
	return party_members.size() + (1 if event_helper != null else 0)

func get_combatant(i: int) -> Resource:
	if i < 0 or i >= combatant_count():
		return null
	if i < party_members.size():
		return party_members[i]
	return event_helper

func is_helper_combatant(i: int) -> bool:
	return event_helper != null and i == party_members.size()

func set_event_helper(adv: Resource) -> void:
	event_helper = adv

func clear_event_helper() -> void:
	event_helper = null

# ---- 生態図鑑進捗（P3-CODEX5-001） ----
const STAGE4_KILLS: int = 3
const STAGE5_KILLS: int = 6

var enemy_codex: Dictionary = {}

func mark_enemy_seen(enemy_id: String) -> void:
	if enemy_id.is_empty():
		return
	if not enemy_codex.has(enemy_id):
		enemy_codex[enemy_id] = {"seen": true, "kills": 0}
	else:
		enemy_codex[enemy_id]["seen"] = true

func add_enemy_kill(enemy_id: String) -> void:
	if enemy_id.is_empty():
		return
	if not enemy_codex.has(enemy_id):
		enemy_codex[enemy_id] = {"seen": true, "kills": 1}
	else:
		enemy_codex[enemy_id]["seen"] = true
		enemy_codex[enemy_id]["kills"] = int(enemy_codex[enemy_id].get("kills", 0)) + 1

func get_enemy_stage(enemy_id: String) -> int:
	if not enemy_codex.has(enemy_id):
		return 1
	var entry: Dictionary = enemy_codex[enemy_id]
	var kills: int = int(entry.get("kills", 0))
	if kills >= STAGE5_KILLS:
		return 5
	if kills >= STAGE4_KILLS:
		return 4
	if kills >= 1:
		return 3
	if bool(entry.get("seen", false)):
		return 2
	return 1

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

# ---- ロスター / 編成（P3-D036b） ----

func get_roster() -> Array:
	return roster

func is_member_active(adv: Resource) -> bool:
	return adv != null and party_members.has(adv)

func add_roster_member(adv: Resource) -> void:
	if adv != null and not roster.has(adv):
		roster.append(adv)

func find_roster_member_by_id(member_id: String) -> Resource:
	if member_id.is_empty():
		return null
	for adv in roster:
		if adv != null and str(adv.id) == member_id:
			return adv
	return null

# アクティブ編成を更新。members は roster 内 Adventurer の配列（1〜ACTIVE_PARTY_SIZE）。
# 無効（roster外/重複/数超過/空）なら false で現状維持。
func set_active_party(members: Array) -> bool:
	if members.is_empty() or members.size() > ACTIVE_PARTY_SIZE:
		return false
	var seen: Array = []
	for adv in members:
		if adv == null or not roster.has(adv) or seen.has(adv):
			return false
		seen.append(adv)
	party_members = members.duplicate()
	return true
