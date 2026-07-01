extends Node

const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")
const _AffixRoller = preload("res://scripts/equipment/AffixRoller.gd")

const ROOM_SEQUENCE: Array[int] = [
	Enums.RoomType.START,
	Enums.RoomType.COMBAT,
	Enums.RoomType.EVENT,
	Enums.RoomType.TREASURE,
	Enums.RoomType.ELITE,
	Enums.RoomType.EVENT,
	Enums.RoomType.COMBAT,
	Enums.RoomType.COMBAT,
	Enums.RoomType.BOSS,
	Enums.RoomType.EXIT,
]

# 中間部屋の抽選重み（戦闘多めプリセット）。合計100。
const ROOM_WEIGHT_COMBAT: int = 60
const ROOM_WEIGHT_EVENT: int = 15
const ROOM_WEIGHT_TREASURE: int = 13
const ROOM_WEIGHT_ELITE: int = 12

# 安全ガード（事故防止）
const ROOM_MAX_ELITE: int = 2      # 1ラン内のELITE上限
const ROOM_MIN_COMBAT: int = 3     # COMBAT最低数（肩慣らし含む / BOSS除く）


const TREASURE_GOLD: int = 30
const TREASURE_ACCESSORY_CHANCE: float = 0.2
const ELITE_REWARD_MULTIPLIER: float = 1.5
const ELITE_ARMOR_CHANCE: float = 0.35
const ELITE_ACCESSORY_CHANCE: float = 0.25
const ELITE_MATERIAL_CHANCE: float = 0.15
const DISCOVERY_PER_ROOM: float = 0.05
const DISCOVERY_BOSS_BONUS: float = 0.20

const EVENTS: Array = [
	{
		"id": "fallen_altar",
		"description": "崩れた祭壇を発見し、碑文に触れた。",
		"outcome": {"type": "heal", "amount": 8},
	},
	{
		"id": "ancient_tome",
		"description": "古文書を見つけ、解読した。",
		"outcome": {"type": "gold", "amount": 25},
	},
	{
		"id": "sealed_door",
		"description": "封印された扉を開け、内部に足を踏み入れた。",
		"outcome": {"type": "buff", "multiplier": 1.15},
	},
	{
		"id": "ruined_crate",
		"description": "朽ちた木箱を調べ、中身を持ち帰った。",
		"outcome": {"type": "material", "label": "遺跡の欠片", "material_id": "relic_shard", "discovery_id": "relic_shard", "amount": 1},
	},
	{
		"id": "faded_inscription",
		"description": "色あせた碑文を発見し、記録した。",
		"outcome": {"type": "lore", "label": "風化した記録", "discovery_id": "ancient_record"},
	},
]

const EVENTS_MOURNGATE: Array = [
	{
		"id": "mourngate_crystal_vein",
		"description": "壁に水晶の鉱脈が走っていた。砕いて持ち帰った。",
		"outcome": {"type": "gold", "amount": 24},
	},
	{
		"id": "mourngate_old_scent",
		"description": "獣道に古い匂いをたどり、群れを巧みに避けた。",
		"outcome": {"type": "buff", "multiplier": 1.1},
	},
	{
		"id": "mourngate_rune_shell",
		"description": "古代文字が刻まれた甲殻の欠片を見つけ、読み解いた。",
		"outcome": {"type": "lore", "label": "ルーンの甲殻", "discovery_id": "mourngate_rune_shell"},
	},
	{
		"id": "mourngate_pilgrim_marker",
		"description": "旧王の大街道に残る道標を発見し、刻まれた落書きを書き留めた。",
		"outcome": {"type": "lore", "label": "巡礼の道標", "discovery_id": "mourngate_pilgrim_marker"},
	},
	{
		"id": "mourngate_record_margin",
		"description": "崩れた写字室で学識王の目録写しを見つけ、欄外の記述を記録した。",
		"outcome": {"type": "lore", "label": "写しの欄外", "discovery_id": "mourngate_record_margin"},
	},
	{
		"id": "mourngate_forge_brand",
		"description": "崩れた鍛冶場の炉壁に刻まれた銘を見つけ、書き写した。",
		"outcome": {"type": "lore", "label": "炉壁の銘", "discovery_id": "mourngate_forge_brand"},
	},
	{
		"id": "mourngate_lamp_relief",
		"description": "崩れた壁のレリーフを見つけ、刻まれた一文を書き留めた。",
		"outcome": {"type": "lore", "label": "灯火のレリーフ", "discovery_id": "mourngate_lamp_relief"},
	},
	{
		"id": "mourngate_temp_companion",
		"description": "負傷した探索者と出会い、同行を許可した。",
		"outcome": {"type": "event_helper"},
	},
]

var current_dungeon_data: Resource = null
var current_room_index: int = 0
var room_sequence: Array[int] = []
var current_room_type: int = Enums.RoomType.START
var is_completed: bool = false
var current_exploration_policy: int = Enums.ExplorationPolicy.EXPLORE
var run_exp_reward: int = 0
var run_gold_reward: int = 0
var last_weapon_dropped: String = ""
var last_armor_dropped: String = ""
var last_accessory_dropped: String = ""
var last_relic_dropped: String = ""
var current_event: Dictionary = {}
var run_damage_multiplier: float = 1.0

func start_dungeon(dungeon_id: String) -> void:
	current_dungeon_data = DataRegistry.get_dungeon_data(dungeon_id)
	if current_dungeon_data == null:
		push_error("DataRegistry: dungeon not found: %s" % dungeon_id)
		return
	room_sequence = _build_room_sequence(current_dungeon_data)
	current_room_index = 0
	current_room_type = room_sequence[0]
	is_completed = false
	current_exploration_policy = Enums.ExplorationPolicy.EXPLORE
	run_exp_reward = 0
	run_gold_reward = 0
	last_weapon_dropped = ""
	last_armor_dropped = ""
	last_accessory_dropped = ""
	last_relic_dropped = ""
	current_event = {}
	run_damage_multiplier = 1.0
	GameState.set_weather(CombatWeather.roll())
	_init_discovery()

func _init_discovery() -> void:
	var did: String = current_dungeon_data.id
	if not GameState.dungeon_progress.has(did):
		GameState.dungeon_progress[did] = {"discovery": 0.0, "hidden_room": false, "hidden_boss": false}

func set_policy(policy: int) -> void:
	current_exploration_policy = policy

func advance_room() -> void:
	current_room_index += 1
	if current_room_index >= room_sequence.size():
		is_completed = true
		return
	current_room_type = room_sequence[current_room_index]
	update_discovery()

func get_total_rooms() -> int:
	return room_sequence.size()

# ── 部屋列の生成 ─────────────────────────────────────────────
# floor_count > 0: ランダム抽選（START + 肩慣らしCOMBAT + 重み付き中間 + BOSS + EXIT）
# floor_count <= 0: 従来固定列（ROOM_SEQUENCE を room_count で切り詰め）
func _build_room_sequence(dungeon: DungeonData) -> Array[int]:
	if dungeon.floor_count > 0:
		return _generate_random_sequence(dungeon.floor_count)
	var legacy: Array[int] = []
	var n: int = dungeon.room_count if dungeon.room_count > 0 else ROOM_SEQUENCE.size()
	for i in mini(n, ROOM_SEQUENCE.size()):
		legacy.append(ROOM_SEQUENCE[i])
	return legacy

func _generate_random_sequence(floor_count: int) -> Array[int]:
	var fc: int = maxi(floor_count, 3)
	var seq: Array[int] = []
	seq.append(Enums.RoomType.START)            # F1: 入口
	if fc >= 3:
		seq.append(Enums.RoomType.COMBAT)       # F2: 肩慣らし（固定）
	# 中間（重み付き抽選）: START・肩慣らし・BOSS を除いた数
	var middle_count: int = maxi(0, fc - 3)
	var elite_count: int = 0
	var prev: int = Enums.RoomType.COMBAT
	for _i in middle_count:
		var rt: int = _roll_room_type()
		if rt == Enums.RoomType.ELITE and (elite_count >= ROOM_MAX_ELITE or prev == Enums.RoomType.ELITE):
			rt = Enums.RoomType.COMBAT
		if rt == Enums.RoomType.ELITE:
			elite_count += 1
		seq.append(rt)
		prev = rt
	seq.append(Enums.RoomType.BOSS)             # F(fc): ボス
	_enforce_min_combat(seq)
	seq.append(Enums.RoomType.EXIT)             # 脱出ゲート（フロア番号外）
	return seq

func _roll_room_type() -> int:
	var r: int = randi() % 100
	if r < ROOM_WEIGHT_COMBAT:
		return Enums.RoomType.COMBAT
	r -= ROOM_WEIGHT_COMBAT
	if r < ROOM_WEIGHT_EVENT:
		return Enums.RoomType.EVENT
	r -= ROOM_WEIGHT_EVENT
	if r < ROOM_WEIGHT_TREASURE:
		return Enums.RoomType.TREASURE
	return Enums.RoomType.ELITE

# COMBAT が ROOM_MIN_COMBAT 未満なら、中間の非COMBAT部屋をCOMBATへ変換して補う。
# START(先頭)・BOSS(末尾) は対象外。EVENT/TREASURE を優先的に変換し、足りなければ ELITE も変換。
func _enforce_min_combat(seq: Array[int]) -> void:
	var combat_total: int = seq.count(Enums.RoomType.COMBAT)
	if combat_total >= ROOM_MIN_COMBAT:
		return
	for pass_idx in 2:
		for i in range(1, seq.size() - 1):
			if combat_total >= ROOM_MIN_COMBAT:
				return
			var rt: int = seq[i]
			if rt == Enums.RoomType.COMBAT:
				continue
			# 1巡目は EVENT/TREASURE のみ、2巡目で ELITE も対象
			if pass_idx == 0 and rt == Enums.RoomType.ELITE:
				continue
			seq[i] = Enums.RoomType.COMBAT
			combat_total += 1

func is_combat_room() -> bool:
	return current_room_type in [
		Enums.RoomType.COMBAT,
		Enums.RoomType.ELITE,
		Enums.RoomType.BOSS,
	]

func accumulate_rewards(exp: int, gold: int) -> void:
	run_exp_reward += exp
	if gold > 0:
		gold = _AffixStatCalculator.apply_gold_bonus(gold)
		# 探索方針（素材優先）gold +15%（P3-D098）
		if GameState.get_exploration_policy() == "material":
			gold = int(round(float(gold) * 1.15))
	run_gold_reward += gold

func get_enemy_level() -> int:
	if current_dungeon_data == null:
		return 1
	return maxi(1, int(current_dungeon_data.enemy_level))

func get_reward_multiplier() -> float:
	if current_room_type == Enums.RoomType.ELITE:
		return ELITE_REWARD_MULTIPLIER
	return 1.0

func pick_enemy_data() -> Resource:
	if current_dungeon_data == null:
		return null
	var pool: Array = current_dungeon_data.enemy_pool
	if pool.is_empty():
		return null
	return DataRegistry.get_enemy_data(pool[randi() % pool.size()] as String)

func pick_elite_enemy_data() -> Resource:
	if current_dungeon_data == null:
		return null
	var pool: Array = current_dungeon_data.elite_pool
	if pool.is_empty():
		pool = current_dungeon_data.enemy_pool
	if pool.is_empty():
		return null
	return DataRegistry.get_enemy_data(pool[randi() % pool.size()] as String)

func pick_boss_enemy_data() -> Resource:
	if current_dungeon_data == null:
		return null
	var boss_id: String = current_dungeon_data.boss_id
	if boss_id.is_empty():
		return pick_enemy_data()
	return DataRegistry.get_enemy_data(boss_id)

func pick_combat_enemy_data() -> Resource:
	match current_room_type:
		Enums.RoomType.BOSS:
			return pick_boss_enemy_data()
		Enums.RoomType.ELITE:
			return pick_elite_enemy_data()
		_:
			return pick_enemy_data()

# COMBAT 部屋で群れ出現を抽選する確率（P3-D082）。
const SWARM_CHANCE: float = 0.20
# 複数体出現時、追加枠を別種にする確率（P3-D110・混成エンカウント）。
const MIXED_SWARM_CHANCE: float = 0.50

func _swarm_capable_enemies() -> Array[Resource]:
	var out: Array[Resource] = []
	if current_dungeon_data == null:
		return out
	var seen: Dictionary = {}
	for raw_id in current_dungeon_data.enemy_pool:
		var ed: Resource = DataRegistry.get_enemy_data(str(raw_id))
		if ed == null or not bool(ed.can_swarm):
			continue
		if seen.has(ed.id):
			continue
		seen[ed.id] = true
		out.append(ed)
	return out

# 戦闘の敵編成を返す（P3-D082 + P3-D110 混成）。
# BOSS/ELITE は常に単体。COMBAT は can_swarm 敵なら SWARM_CHANCE で複数体（同種 or 混成）。
func pick_combat_enemy_group() -> Array[Resource]:
	var group: Array[Resource] = []
	var base: Resource = pick_combat_enemy_data()
	if base == null:
		return group
	group.append(base)
	if current_room_type != Enums.RoomType.COMBAT:
		return group
	if not bool(base.can_swarm):
		return group
	var swarm_chance: float = SWARM_CHANCE
	# 探索方針（安全優先）群れ出現率を半減（P3-D098）
	if GameState.get_exploration_policy() == "safe":
		swarm_chance *= 0.5
	if randf() >= swarm_chance:
		return group
	var lo: int = maxi(2, int(base.swarm_min))
	var hi: int = maxi(lo, int(base.swarm_max))
	var size: int = randi_range(lo, hi)
	var capable: Array[Resource] = _swarm_capable_enemies()
	var use_mixed: bool = capable.size() >= 2 and randf() < MIXED_SWARM_CHANCE
	for _i in (size - 1):
		if use_mixed:
			var candidates: Array[Resource] = []
			for ed: Resource in capable:
				if ed.id != base.id:
					candidates.append(ed)
			if candidates.is_empty():
				candidates = capable
			group.append(candidates[randi() % candidates.size()])
		else:
			group.append(base)
	return group

func pick_event() -> Dictionary:
	var pool: Array = _get_event_pool()
	if pool.is_empty():
		return {}
	current_event = pool[randi() % pool.size()].duplicate(true)
	return current_event

func _get_event_pool() -> Array:
	if current_dungeon_data == null:
		return EVENTS
	var combined: Array = []
	combined.append_array(EVENTS)
	if current_dungeon_data.id == "mourngate":
		combined.append_array(EVENTS_MOURNGATE)
	return combined

func auto_resolve_event() -> Dictionary:
	return current_event.get("outcome", {"type": "nothing"})

func update_discovery(bonus: float = 0.0) -> void:
	if current_dungeon_data == null:
		return
	var did: String = current_dungeon_data.id
	if not GameState.dungeon_progress.has(did):
		GameState.dungeon_progress[did] = {"discovery": 0.0, "hidden_room": false, "hidden_boss": false}
	var prog: Dictionary = GameState.dungeon_progress[did]
	prog["discovery"] = min(1.0, prog["discovery"] + DISCOVERY_PER_ROOM + bonus)
	var unlocks: Dictionary = current_dungeon_data.discovery_unlocks
	if unlocks.has("hidden_room") and prog["discovery"] >= float(unlocks["hidden_room"]):
		prog["hidden_room"] = true
	if unlocks.has("hidden_boss") and prog["discovery"] >= float(unlocks["hidden_boss"]):
		prog["hidden_boss"] = true
	GameState.dungeon_progress[did] = prog

func generate_treasure_loot() -> Dictionary:
	accumulate_rewards(0, TREASURE_GOLD)
	var accessory_id: String = ""
	if randf() < TREASURE_ACCESSORY_CHANCE:
		_generate_accessory_loot()
		accessory_id = last_accessory_dropped
	return {"gold": TREASURE_GOLD, "accessory_id": accessory_id}

func generate_accessory_loot() -> String:
	last_accessory_dropped = ""
	_generate_accessory_loot()
	return last_accessory_dropped

func apply_elite_bonus_loot() -> Dictionary:
	var bonus: Dictionary = {"armor_id": "", "accessory_id": "", "material_id": ""}
	if randf() < ELITE_ARMOR_CHANCE:
		_generate_armor_loot()
		bonus["armor_id"] = last_armor_dropped
	if randf() < ELITE_ACCESSORY_CHANCE:
		_generate_accessory_loot()
		bonus["accessory_id"] = last_accessory_dropped
	var material_chance: float = ELITE_MATERIAL_CHANCE
	# 探索方針（素材優先）ELITE 素材ドロップ率↑（P3-D098）
	if GameState.get_exploration_policy() == "material":
		material_chance = 0.30
	if randf() < material_chance:
		bonus["material_id"] = "elite_relic_shard"
	return bonus

const WEAPON_POOL: Array[String] = [
	"iron_sword",
	"rusted_blade",
	"heater_blade",
	"frost_blade",
	"bolt_knife",
	"sanctified_dagger",
	"hunting_bow",
	"apprentice_staff",
	"ember_fang",
	"glacier_staff",
	"storm_edge",
	"umbral_fang",
	"consecrated_maul",
]

# レア度別ドロップ重み（レアほど低確率＝レア度を体感に反映）
const RARITY_DROP_WEIGHT: Dictionary = {
	Enums.Rarity.COMMON: 40,
	Enums.Rarity.RARE: 15,
	Enums.Rarity.EPIC: 5,
	Enums.Rarity.LEGENDARY: 1,
}

# P3-D074: 武器はラン終了一括ではなく撃破時に直ドロップ。ここでは防具/装飾のみ。
func generate_run_loot() -> void:
	last_armor_dropped = ""
	last_accessory_dropped = ""
	if randf() < 0.3:
		_generate_armor_loot()
	if randf() < 0.2:
		_generate_accessory_loot()

# P3-D074: 撃破時の武器直ドロップ。確率はボス/エリートで上昇。戻り値はドロップ weapon_id（無しは空）。
func roll_kill_weapon_drop(room_type: int) -> String:
	var chance: float = 0.25
	if room_type == Enums.RoomType.BOSS:
		chance = 1.0
	elif room_type == Enums.RoomType.ELITE:
		chance = 0.6
	if randf() > chance:
		return ""
	var weapon_id: String = _pick_weighted_weapon()
	_spawn_weapon(weapon_id)
	return weapon_id

# P3-D093: 撃破時の遺物ドロップ（解放型）。未所持の遺物から1つ解放する。
# ボス=未所持があれば確定 / エリート=15% / それ以外=なし。全所持済は ""。戻り値=解放した遺物id。
func roll_kill_relic_drop(room_type: int) -> String:
	var pool: Array = GameState.unowned_relic_ids()
	if pool.is_empty():
		return ""
	var chance: float = 0.0
	if room_type == Enums.RoomType.BOSS:
		chance = 1.0
	elif room_type == Enums.RoomType.ELITE:
		# 探索方針（遺物優先）ELITE 遺物ドロップ率↑（P3-D098）
		chance = 0.25 if GameState.get_exploration_policy() == "relic" else 0.15
	if chance <= 0.0 or randf() > chance:
		return ""
	var relic_id: String = str(pool[randi() % pool.size()])
	if GameState.unlock_relic(relic_id):
		last_relic_dropped = relic_id
		return relic_id
	return ""

# WEAPON_POOL からレア度重みで1本抽選
func _pick_weighted_weapon() -> String:
	var weights: Array[int] = []
	var total: int = 0
	for wid in WEAPON_POOL:
		var wdata: Resource = DataRegistry.get_weapon_data(wid)
		var r: int = 0 if wdata == null else int(wdata.rarity)
		var w: int = int(RARITY_DROP_WEIGHT.get(r, 1))
		weights.append(w)
		total += w
	if total <= 0:
		return WEAPON_POOL[randi() % WEAPON_POOL.size()]
	var roll: int = randi() % total
	var cumulative: int = 0
	for i in WEAPON_POOL.size():
		cumulative += weights[i]
		if roll < cumulative:
			return WEAPON_POOL[i]
	return WEAPON_POOL[WEAPON_POOL.size() - 1]

func _auto_appraise(instance: Resource, category: String, rarity: int) -> void:
	instance.is_appraised = true
	var roll: Dictionary = _AffixRoller.roll_for_equipment(category, rarity)
	if roll.is_empty() or roll.has("error"):
		instance.prefix_ids = []
		instance.suffix_ids = []
		return
	var prefix: Array[String] = []
	for v in roll.get("prefix_ids", []):
		prefix.append(str(v))
	var suffix: Array[String] = []
	for v in roll.get("suffix_ids", []):
		suffix.append(str(v))
	instance.prefix_ids = prefix
	instance.suffix_ids = suffix

func _spawn_weapon(weapon_id: String) -> void:
	var weapon_data = load("res://resources/weapons/" + weapon_id + ".tres")
	if weapon_data == null:
		return
	var instance_class = load("res://scripts/domain/WeaponInstance.gd")
	if instance_class == null:
		return
	var instance = instance_class.new()
	instance.instance_id = str(Time.get_ticks_msec()) + "_" + str(randi() % 100000)
	instance.weapon_id = weapon_id
	instance.rolled_attack = weapon_data.base_attack + randi() % 6
	instance.attack_speed = weapon_data.base_attack_speed
	instance.critical_rate = weapon_data.base_critical_rate
	instance.knockback = weapon_data.base_knockback
	instance.stagger_power = weapon_data.base_stagger_power
	instance.attack_range = weapon_data.base_attack_range
	instance.weight = weapon_data.weight
	_auto_appraise(instance, _AffixRoller.CATEGORY_WEAPON, weapon_data.rarity)
	GameState.inventory.append(instance)
	last_weapon_dropped = weapon_id
	EventBus.weapon_obtained.emit(weapon_id)

func _generate_armor_loot() -> void:
	# 革(rarity0/HP寄り) 70% / 骨(rarity1/DEF寄り) 30% でレア度感を維持
	var armor_id: String = "bone_armor" if randf() < 0.3 else "leather_armor"
	_spawn_armor(armor_id)

func _spawn_armor(armor_id: String) -> void:
	var armor_data = load("res://resources/armors/" + armor_id + ".tres")
	if armor_data == null:
		return
	var instance_class = load("res://scripts/domain/ArmorInstance.gd")
	if instance_class == null:
		return
	var instance = instance_class.new()
	instance.instance_id = str(Time.get_ticks_msec() + 1) + "_" + str(randi() % 100000)
	instance.armor_id = armor_id
	instance.rolled_defense = armor_data.base_defense + randi() % 4
	instance.hp_bonus = armor_data.base_hp_bonus
	instance.resistance = armor_data.base_resistance
	instance.weight = armor_data.weight
	instance.rarity = armor_data.rarity
	_auto_appraise(instance, _AffixRoller.CATEGORY_ARMOR, armor_data.rarity)
	GameState.armor_inventory.append(instance)
	last_armor_dropped = armor_id

func _generate_accessory_loot() -> void:
	const ACCESSORY_POOL: Array[String] = ["silver_ring"]
	_spawn_accessory(ACCESSORY_POOL[randi() % ACCESSORY_POOL.size()])

func _spawn_accessory(accessory_id: String) -> void:
	var accessory_data = load("res://resources/accessories/" + accessory_id + ".tres")
	if accessory_data == null:
		return
	var instance_class = load("res://scripts/domain/AccessoryInstance.gd")
	if instance_class == null:
		return
	var instance = instance_class.new()
	instance.instance_id = str(Time.get_ticks_msec() + 2) + "_" + str(randi() % 100000)
	instance.accessory_id = accessory_id
	_auto_appraise(instance, _AffixRoller.CATEGORY_ACCESSORY, accessory_data.rarity)
	GameState.accessory_inventory.append(instance)
	last_accessory_dropped = accessory_id
