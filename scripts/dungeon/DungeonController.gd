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


const TREASURE_GOLD: int = 30
const TREASURE_ACCESSORY_CHANCE: float = 0.2
const ELITE_REWARD_MULTIPLIER: float = 1.5
const ELITE_ARMOR_CHANCE: float = 0.35
const ELITE_ACCESSORY_CHANCE: float = 0.25
const ELITE_MATERIAL_CHANCE: float = 0.15
const DISCOVERY_PER_ROOM: float = 0.05
const DISCOVERY_BOSS_BONUS: float = 0.20

const MERCHANT_CATALOG: Array = [
	{"type": "armor",     "item_id": "leather_armor", "price": 40, "label": "革鎧"},
	{"type": "accessory", "item_id": "silver_ring",   "price": 60, "label": "銀の指輪"},
	{"type": "heal",      "amount": 15,              "price": 35, "label": "回復薬"},
]

const EVENTS: Array = [
	{
		"id": "fallen_altar",
		"description": "崩れた祭壇を発見した。碑文に触れるか？",
		"choice_a": "触れる",
		"choice_b": "無視する",
		"outcome_a": {"type": "heal", "amount": 8},
		"outcome_b": {"type": "nothing"},
	},
	{
		"id": "ancient_tome",
		"description": "古文書を発見した。解読するか？",
		"choice_a": "解読する",
		"choice_b": "無視する",
		"outcome_a": {"type": "gold", "amount": 25},
		"outcome_b": {"type": "nothing"},
	},
	{
		"id": "sealed_door",
		"description": "封印された扉を発見した。扉を開けるか？",
		"choice_a": "開ける",
		"choice_b": "立ち去る",
		"outcome_a": {"type": "buff", "multiplier": 1.15},
		"outcome_b": {"type": "nothing"},
	},
	{
		"id": "ruined_crate",
		"description": "朽ちた木箱を見つけた。中身を調べるか？",
		"choice_a": "調べる",
		"choice_b": "見送る",
		"outcome_a": {"type": "material", "label": "遺跡の欠片", "material_id": "relic_shard", "discovery_id": "relic_shard", "amount": 1},
		"outcome_b": {"type": "nothing"},
	},
	{
		"id": "faded_inscription",
		"description": "色あせた碑文を見つけた。記録するか？",
		"choice_a": "記録する",
		"choice_b": "見送る",
		"outcome_a": {"type": "lore", "label": "風化した記録", "discovery_id": "ancient_record"},
		"outcome_b": {"type": "nothing"},
	},
]

const EVENTS_MOURNGATE: Array = [
	{
		"id": "mourngate_crystal_vein",
		"description": "壁に水晶の鉱脈が走っている。砕いて持ち帰るか？",
		"choice_a": "砕く",
		"choice_b": "見送る",
		"outcome_a": {"type": "gold", "amount": 24},
		"outcome_b": {"type": "nothing"},
	},
	{
		"id": "mourngate_old_scent",
		"description": "獣道に古い匂いが残っている。たどると群れを避けられそうだ。",
		"choice_a": "たどる",
		"choice_b": "見送る",
		"outcome_a": {"type": "buff", "multiplier": 1.1},
		"outcome_b": {"type": "nothing"},
	},
	{
		"id": "mourngate_rune_shell",
		"description": "古代文字が刻まれた甲殻の欠片を見つけた。読み解くか？",
		"choice_a": "読み解く",
		"choice_b": "見送る",
		"outcome_a": {"type": "lore", "label": "ルーンの甲殻", "discovery_id": "mourngate_rune_shell"},
		"outcome_b": {"type": "nothing"},
	},
	{
		"id": "mourngate_temp_companion",
		"description": "負傷した探索者が壁に寄りかかっている。「もう少しだけ戦える」と同行を申し出てきた。",
		"choice_a": "同行を許可する",
		"choice_b": "断る",
		"outcome_a": {"type": "event_helper"},
		"outcome_b": {"type": "nothing"},
	},
]

var current_dungeon_data: Resource = null
var current_room_index: int = 0
var current_room_type: int = Enums.RoomType.START
var is_completed: bool = false
var current_exploration_policy: int = Enums.ExplorationPolicy.EXPLORE
var run_exp_reward: int = 0
var run_gold_reward: int = 0
var last_weapon_dropped: String = ""
var last_armor_dropped: String = ""
var last_accessory_dropped: String = ""
var current_merchant_offers: Array = []
var current_event: Dictionary = {}
var run_damage_multiplier: float = 1.0

func start_dungeon(dungeon_id: String) -> void:
	current_dungeon_data = DataRegistry.get_dungeon_data(dungeon_id)
	if current_dungeon_data == null:
		push_error("DataRegistry: dungeon not found: %s" % dungeon_id)
		return
	current_room_index = 0
	current_room_type = ROOM_SEQUENCE[0]
	is_completed = false
	current_exploration_policy = Enums.ExplorationPolicy.EXPLORE
	run_exp_reward = 0
	run_gold_reward = 0
	last_weapon_dropped = ""
	last_armor_dropped = ""
	last_accessory_dropped = ""
	current_merchant_offers = []
	current_event = {}
	run_damage_multiplier = 1.0
	_init_discovery()

func _init_discovery() -> void:
	var did: String = current_dungeon_data.id
	if not GameState.dungeon_progress.has(did):
		GameState.dungeon_progress[did] = {"discovery": 0.0, "hidden_room": false, "hidden_boss": false}

func set_policy(policy: int) -> void:
	current_exploration_policy = policy

func advance_room() -> void:
	current_room_index += 1
	if current_room_index >= current_dungeon_data.room_count:
		is_completed = true
		return
	current_room_type = ROOM_SEQUENCE[current_room_index]
	update_discovery()

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
	run_gold_reward += gold

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

func generate_merchant_offers() -> Array:
	var catalog: Array = _build_merchant_catalog()
	catalog.shuffle()
	current_merchant_offers = []
	for i in min(2, catalog.size()):
		var offer: Dictionary = catalog[i].duplicate()
		offer["purchased"] = false
		current_merchant_offers.append(offer)
	return current_merchant_offers

func _build_merchant_catalog() -> Array:
	var catalog: Array = MERCHANT_CATALOG.duplicate(true)
	for shop_item in DataRegistry.get_material_shop_items():
		if shop_item == null or shop_item.material_id.is_empty():
			continue
		var price: int = shop_item.price
		if price <= 0:
			price = DataRegistry.get_material_price(shop_item.material_id)
		if price <= 0:
			continue
		catalog.append({
			"type": "material",
			"item_id": shop_item.material_id,
			"price": price,
			"label": "Material: %s" % shop_item.material_id,
		})
	return catalog

func buy_merchant_item(offer_index: int) -> bool:
	if offer_index >= current_merchant_offers.size():
		return false
	var offer: Dictionary = current_merchant_offers[offer_index]
	if offer.get("purchased", false):
		return false
	if GameState.gold < offer["price"]:
		return false
	if offer.get("type") == "material":
		var material_id: String = str(offer.get("item_id", ""))
		if material_id.is_empty() or DataRegistry.get_material_price(material_id) < 0:
			return false
	GameState.gold -= offer["price"]
	match offer["type"]:
		"armor":
			_spawn_armor(offer["item_id"])
		"accessory":
			_spawn_accessory(offer["item_id"])
		"material":
			GameState.add_material(str(offer["item_id"]), 1)
			print("[Merchant] Material purchased: %s (-%dG)" % [offer["item_id"], offer["price"]])
		"heal":
			pass  # 即時回復は DungeonScene で適用
	current_merchant_offers[offer_index]["purchased"] = true
	return true

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

func resolve_event(choice_index: int) -> Dictionary:
	var key: String = "outcome_a" if choice_index == 0 else "outcome_b"
	if not current_event.has(key):
		return {"type": "nothing"}
	return current_event[key]

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

func apply_elite_bonus_loot() -> Dictionary:
	var bonus: Dictionary = {"armor_id": "", "accessory_id": "", "material_id": ""}
	if randf() < ELITE_ARMOR_CHANCE:
		_generate_armor_loot()
		bonus["armor_id"] = last_armor_dropped
	if randf() < ELITE_ACCESSORY_CHANCE:
		_generate_accessory_loot()
		bonus["accessory_id"] = last_accessory_dropped
	if randf() < ELITE_MATERIAL_CHANCE:
		bonus["material_id"] = "elite_relic_shard"
	return bonus

func generate_run_loot() -> void:
	last_weapon_dropped = ""
	last_armor_dropped = ""
	last_accessory_dropped = ""
	_generate_weapon_loot()
	if randf() < 0.3:
		_generate_armor_loot()
	if randf() < 0.2:
		_generate_accessory_loot()

func _generate_weapon_loot() -> void:
	const WEAPON_POOL: Array[String] = [
		"iron_sword",
		"rusted_blade",
		"heater_blade",
		"frost_blade",
		"bolt_knife",
		"sanctified_dagger",
	]
	_spawn_weapon(WEAPON_POOL[randi() % WEAPON_POOL.size()])

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
	const ARMOR_POOL: Array[String] = ["leather_armor"]
	_spawn_armor(ARMOR_POOL[randi() % ARMOR_POOL.size()])

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
