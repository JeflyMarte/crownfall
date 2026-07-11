extends Node

const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")
const _AffixRoller = preload("res://scripts/equipment/AffixRoller.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _WanderingEnemyConfig = preload("res://scripts/dungeon/WanderingEnemyConfig.gd")
const _EvolutionTraits = preload("res://scripts/systems/EvolutionTraits.gd")

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
]

# 中間部屋の抽選重み（戦闘多めプリセット）。合計100。
const ROOM_WEIGHT_COMBAT: int = 52
const ROOM_WEIGHT_HEAL: int = 7
const ROOM_WEIGHT_LORE: int = 8
const ROOM_WEIGHT_TREASURE: int = 13
const ROOM_WEIGHT_TRAP: int = 8
const ROOM_WEIGHT_ELITE: int = 12

# 安全ガード（事故防止）
const ROOM_MAX_ELITE: int = 2      # 1ラン内のELITE上限
const ROOM_MIN_COMBAT: int = 3     # COMBAT最低数（肩慣らし含む / BOSS除く）



const TREASURE_GOLD: int = 30
const TREASURE_ACCESSORY_CHANCE: float = 0.2
const ELITE_REWARD_MULTIPLIER: float = 1.5
const ELITE_ARMOR_CHANCE: float = 0.35
const ELITE_ACCESSORY_CHANCE: float = 0.25
const ELITE_MATERIAL_CHANCE: float = 0.20
const DISCOVERY_PER_ROOM: float = 0.05
const DISCOVERY_BOSS_BONUS: float = 0.20

## 炉研ぎ素材のみ（`EquipmentEnhancer.EVENT_DROP_MATERIAL_IDS` と同期）。
const MOURNGATE_EVENT_MATERIAL_POOL: Array[String] = ["relic_shard", "ancient_bone"]
const MOURNGATE_ECOLOGY_DUNGEON_IDS: Array[String] = [
	"mourngate",
	"mourngate_deep",
	"astoria_ruins",
	"storm_crown_ruins",
]

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
		"description": "負傷した探索者と出会い、応急手当の知恵を得た。",
		"outcome": {"type": "heal", "amount": 10},
	},
]

const EVENTS_WHISPERWOOD: Array = [
	{
		"id": "whisperwood_moss_spring",
		"description": "苔むした岩の間に澄んだ湧水を見つけ、傷を洗った。",
		"outcome": {"type": "heal", "amount": 10},
	},
	{
		"id": "whisperwood_hollow_cache",
		"description": "大樹の木洞に、先行した探索者の備蓄が手つかずで残されていた。",
		"outcome": {"type": "gold", "amount": 30},
	},
	{
		"id": "whisperwood_symbiont_bloom",
		"description": "共生花の群落が放つ香気を浴び、身体が軽くなった。",
		"outcome": {"type": "buff", "multiplier": 1.12},
	},
	{
		"id": "whisperwood_warden_carving",
		"description": "森番が幹に刻んだ古い標を見つけ、書き写した。",
		"outcome": {"type": "lore", "label": "森番の刻印", "discovery_id": "whisperwood_warden_carving"},
	},
	{
		"id": "whisperwood_canopy_whisper",
		"description": "梢のざわめきから方角を読む口伝を思い出し、書き留めた。",
		"outcome": {"type": "lore", "label": "梢のささやき", "discovery_id": "whisperwood_canopy_whisper"},
	},
]

const EVENTS_MISTFEN: Array = [
	{
		"id": "mistfen_dry_islet",
		"description": "乾いた中州を見つけ、泥を落として小休止した。",
		"outcome": {"type": "heal", "amount": 12},
	},
	{
		"id": "mistfen_sunken_satchel",
		"description": "泥中から沈んだ革鞄を引き上げた。中身はまだ使える。",
		"outcome": {"type": "material", "label": "沼澱の試料", "material_id": "relic_shard", "discovery_id": "relic_shard", "amount": 1},
	},
	{
		"id": "mistfen_marsh_light",
		"description": "沼灯りの揺れを追って安全な浅瀬を渡り、時間を稼いだ。",
		"outcome": {"type": "gold", "amount": 34},
	},
	{
		"id": "mistfen_libris_seal",
		"description": "沈没書庫の残骸から封蝋の欠片を拾い、紋様を記録した。",
		"outcome": {"type": "lore", "label": "封緘の蝋印", "discovery_id": "mistfen_libris_seal"},
	},
	{
		"id": "mistfen_drowned_ledger",
		"description": "水浸しの台帳が浅瀬に沈んでいた。読める頁を書き写した。",
		"outcome": {"type": "lore", "label": "水浸しの台帳", "discovery_id": "mistfen_drowned_ledger"},
	},
]

const EVENTS_ASTORIA_RUINS: Array = [
	{
		"id": "astoria_crown_bridge_rubble",
		"description": "王冠橋の落石を避けながら、崩落前の街道標識を書き写した。",
		"outcome": {"type": "lore", "label": "落橋の標識", "discovery_id": "mourngate_pilgrim_marker"},
	},
	{
		"id": "astoria_bleeding_wall",
		"description": "壁の裂け目から滲む赤い鉱脈を採取し、持ち帰った。",
		"outcome": {"type": "material", "label": "赤鉱の欠片", "material_id": "relic_shard", "discovery_id": "relic_shard", "amount": 1},
	},
]

const EVENTS_GREEN_HOLLOW: Array = [
	{
		"id": "green_hollow_bog_fire",
		"description": "湿地の沼気に火を当て、毒霧を一時的に払った。",
		"outcome": {"type": "buff", "multiplier": 1.1},
	},
	{
		"id": "green_hollow_poison_sample",
		"description": "毒胞子の塊を採取し、耐性試料として持ち帰った。",
		"outcome": {"type": "material", "label": "湿地の毒試料", "material_id": "relic_shard", "discovery_id": "relic_shard", "amount": 1},
	},
]

const EVENTS_BLACKSHORE: Array = [
	{
		"id": "blackshore_tidal_pool",
		"description": "干潮の潮溜まりで聖別の残光を掬い、傷を癒した。",
		"outcome": {"type": "heal", "amount": 14},
	},
	{
		"id": "blackshore_wreck_cache",
		"description": "座礁船の貨物室から、まだ使える備蓄を回収した。",
		"outcome": {"type": "gold", "amount": 38},
	},
	{
		"id": "blackshore_pharos_echo",
		"description": "灯台の残響を聞き、潮位の変化を記録した。",
		"outcome": {"type": "lore", "label": "灯台の残響", "discovery_id": "blackshore_pharos_echo"},
	},
	{
		"id": "blackshore_tide_chart",
		"description": "海統王の潮見表の断片を見つけ、書き写した。",
		"outcome": {"type": "lore", "label": "潮見表の断片", "discovery_id": "blackshore_tide_chart"},
	},
	{
		"id": "blackshore_salt_blessing",
		"description": "潮の聖別を浴び、次の一戦に備えた。",
		"outcome": {"type": "buff", "multiplier": 1.12},
	},
]

const EVENTS_WESTBAY_FLATS: Array = [
	{
		"id": "westbay_shell_line",
		"description": "干潟の貝殻線を辿り、安全な渡し場を見つけた。",
		"outcome": {"type": "gold", "amount": 32},
	},
	{
		"id": "westbay_holy_spring",
		"description": "干潟の湧きから聖水を汲み、持ち帰った。",
		"outcome": {"type": "heal", "amount": 12},
	},
]

const EVENTS_FROSTRIDGE: Array = [
	{
		"id": "frostridge_snow_shelter",
		"description": "雪庇の下で体を温め、凍傷を防いだ。",
		"outcome": {"type": "heal", "amount": 16},
	},
	{
		"id": "frostridge_ice_cache",
		"description": "開拓隊の隠し倉から凍結保存された備蓄を見つけた。",
		"outcome": {"type": "gold", "amount": 42},
	},
	{
		"id": "frostridge_boundary_marker",
		"description": "北境の境界標を発見し、刻印を書き写した。",
		"outcome": {"type": "lore", "label": "北境の境界標", "discovery_id": "frostridge_boundary_marker"},
	},
	{
		"id": "frostridge_blizzard_note",
		"description": "吹雪の合間に残された開拓記録を読み、記録した。",
		"outcome": {"type": "lore", "label": "吹雪の記録", "discovery_id": "frostridge_blizzard_note"},
	},
	{
		"id": "frostridge_aurora_gleam",
		"description": "極光の残光が氷壁を照らし、一時的に視界が開けた。",
		"outcome": {"type": "buff", "multiplier": 1.12},
	},
]

const EVENTS_FROSTWALL_PATH: Array = [
	{
		"id": "frostwall_packed_snow",
		"description": "固まった雪道を整え、進路を確保した。",
		"outcome": {"type": "buff", "multiplier": 1.1},
	},
	{
		"id": "frostwall_ice_shard",
		"description": "壁沿いの氷柱を採取し、持ち帰った。",
		"outcome": {"type": "material", "label": "氷壁の欠片", "material_id": "relic_shard", "discovery_id": "relic_shard", "amount": 1},
	},
]

# ダンジョン別イベント（P3-EVT-001）。id 一致で EVENTS へ加算。
const DUNGEON_EVENTS: Dictionary = {
	"mourngate": EVENTS_MOURNGATE,
	"astoria_ruins": EVENTS_MOURNGATE + EVENTS_ASTORIA_RUINS,
	"whisperwood": EVENTS_WHISPERWOOD,
	"green_hollow": EVENTS_WHISPERWOOD + EVENTS_GREEN_HOLLOW,
	"mistfen": EVENTS_MISTFEN,
	"broken_marsh": EVENTS_MISTFEN,
	"blackshore": EVENTS_BLACKSHORE,
	"westbay_flats": EVENTS_BLACKSHORE + EVENTS_WESTBAY_FLATS,
	"frostridge": EVENTS_FROSTRIDGE,
	"frostwall_path": EVENTS_FROSTRIDGE + EVENTS_FROSTWALL_PATH,
	"mourngate_deep": EVENTS_MOURNGATE,
	"storm_crown_ruins": EVENTS_MOURNGATE,
	"red_ridge_mine": EVENTS_WHISPERWOOD,
	"mistfen_depths": EVENTS_MISTFEN,
	"thunder_peak": EVENTS_MISTFEN,
	"blackshore_abyss": EVENTS_BLACKSHORE,
	"red_forge_depths": EVENTS_FROSTRIDGE,
	"north_reach": EVENTS_FROSTRIDGE,
}

var current_dungeon_data: Resource = null
var current_stage_data: Resource = null
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
var _seen_event_ids: Array[String] = []

func start_dungeon(dungeon_id: String) -> void:
	current_stage_data = null
	current_dungeon_data = DataRegistry.get_dungeon_data(dungeon_id)
	if current_dungeon_data == null:
		push_error("DataRegistry: dungeon not found: %s" % dungeon_id)
		return
	room_sequence = _build_room_sequence(current_dungeon_data)
	_reset_run_state()

func start_stage(stage_id: String) -> void:
	current_stage_data = DataRegistry.get_stage_data(stage_id)
	if current_stage_data == null:
		push_error("DataRegistry: stage not found: %s" % stage_id)
		return
	current_dungeon_data = DataRegistry.get_dungeon_data(str(current_stage_data.biome_id))
	if current_dungeon_data == null:
		push_error("DataRegistry: biome not found for stage: %s" % stage_id)
		current_stage_data = null
		return
	room_sequence = _build_room_sequence_for_stage(current_stage_data)
	_reset_run_state()

func _reset_run_state() -> void:
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
	_seen_event_ids.clear()
	GameState.set_weather(CombatWeather.roll())
	_init_discovery()

func get_run_display_name() -> String:
	if current_stage_data != null and not str(current_stage_data.display_name).is_empty():
		return "%d-%d %s" % [
			int(current_stage_data.biome_index),
			int(current_stage_data.chapter_index),
			str(current_stage_data.display_name),
		]
	if current_dungeon_data != null:
		return str(current_dungeon_data.display_name)
	return "ダンジョン"

func get_run_chapter_label() -> String:
	if current_stage_data == null:
		return ""
	return "%d-%d" % [int(current_stage_data.biome_index), int(current_stage_data.chapter_index)]

func get_run_recommended_level() -> int:
	if current_stage_data != null and int(current_stage_data.recommended_level) > 0:
		return int(current_stage_data.recommended_level)
	if current_dungeon_data != null and int(current_dungeon_data.recommended_level) > 0:
		return int(current_dungeon_data.recommended_level)
	return 0

func get_display_floor_max() -> int:
	if current_stage_data != null:
		return maxi(1, int(current_stage_data.floor_count))
	return maxi(1, get_total_rooms())

func get_display_floor_current() -> int:
	return mini(current_room_index + 1, get_display_floor_max())

func get_display_floor_text() -> String:
	return "F%d/%d" % [get_display_floor_current(), get_display_floor_max()]

func get_run_biome_display_name() -> String:
	if current_dungeon_data != null:
		return str(current_dungeon_data.display_name)
	return "ダンジョン"

func get_run_biome_id() -> String:
	if current_dungeon_data != null:
		return str(current_dungeon_data.id)
	return ""

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
# floor_count > 0: ランダム抽選（肩慣らし COMBAT + 重み付き中間 + [BOSS]）。EXIT は別フロアにしない。
# floor_count <= 0: 従来固定列（ROOM_SEQUENCE を room_count で切り詰め）
func _build_room_sequence(dungeon: DungeonData) -> Array[int]:
	if dungeon.floor_count > 0:
		return _generate_random_sequence(dungeon, dungeon.floor_count, true, false)
	var legacy: Array[int] = []
	var n: int = dungeon.room_count if dungeon.room_count > 0 else ROOM_SEQUENCE.size()
	for i in mini(n, ROOM_SEQUENCE.size()):
		legacy.append(ROOM_SEQUENCE[i])
	return legacy

func _build_room_sequence_for_stage(stage: Resource) -> Array[int]:
	return _generate_random_sequence(
		current_dungeon_data,
		int(stage.floor_count),
		bool(stage.has_boss_floor()),
		bool(stage.requires_elite)
	)

func _generate_random_sequence(
	dungeon: DungeonData,
	floor_count: int,
	include_boss: bool,
	require_elite: bool
) -> Array[int]:
	var fc: int = maxi(floor_count, 3)
	var seq: Array[int] = []
	# F1 は中身のある戦闘フロアにする（エントランス演出は dive intro が担う）。
	seq.append(Enums.RoomType.COMBAT)
	var opener_count: int = 2 if fc >= 3 else 1
	if fc >= 3:
		seq.append(Enums.RoomType.COMBAT)
	var boss_slots: int = 1 if include_boss else 0
	var middle_count: int = maxi(0, fc - opener_count - boss_slots)
	var elite_count: int = 0
	var prev: int = Enums.RoomType.COMBAT
	for _i in middle_count:
		var rt: int = _roll_room_type(dungeon)
		if rt == Enums.RoomType.ELITE and (elite_count >= ROOM_MAX_ELITE or prev == Enums.RoomType.ELITE):
			rt = Enums.RoomType.COMBAT
		if rt == Enums.RoomType.ELITE:
			elite_count += 1
		seq.append(rt)
		prev = rt
	if include_boss:
		seq.append(Enums.RoomType.BOSS)
	_enforce_min_combat(seq)
	_enforce_min_event(seq, dungeon, middle_count)
	if require_elite:
		_enforce_required_elite(seq)
	_enforce_last_floor_combat(seq)
	return seq

func _enforce_last_floor_combat(seq: Array[int]) -> void:
	if seq.is_empty():
		return
	var last_idx: int = seq.size() - 1
	var rt: int = seq[last_idx]
	if rt in [Enums.RoomType.COMBAT, Enums.RoomType.ELITE, Enums.RoomType.BOSS]:
		return
	seq[last_idx] = Enums.RoomType.COMBAT

func _enforce_required_elite(seq: Array[int]) -> void:
	if seq.count(Enums.RoomType.ELITE) >= 1:
		return
	for i in range(1, seq.size() - 1):
		var rt: int = seq[i]
		if rt in [Enums.RoomType.COMBAT, Enums.RoomType.EVENT, Enums.RoomType.HEAL, Enums.RoomType.TREASURE, Enums.RoomType.TRAP]:
			seq[i] = Enums.RoomType.ELITE
			return

func _resolve_lore_room_weight(dungeon: DungeonData) -> int:
	if current_stage_data != null and int(current_stage_data.event_room_weight) > 0:
		return mini(int(current_stage_data.event_room_weight), 40)
	if dungeon != null and dungeon.event_room_weight > 0:
		return mini(dungeon.event_room_weight, 40)
	return ROOM_WEIGHT_LORE

func _resolve_room_weights(dungeon: DungeonData) -> Dictionary:
	var lore_w: int = _resolve_lore_room_weight(dungeon)
	var combat_w: int = clampi(ROOM_WEIGHT_COMBAT - (lore_w - ROOM_WEIGHT_LORE), 35, 70)
	return {
		"combat": combat_w,
		"heal": ROOM_WEIGHT_HEAL,
		"lore": lore_w,
		"treasure": ROOM_WEIGHT_TREASURE,
		"trap": ROOM_WEIGHT_TRAP,
		"elite": ROOM_WEIGHT_ELITE,
	}

func _required_min_event_rooms(dungeon: DungeonData, middle_count: int) -> int:
	if current_stage_data != null and int(current_stage_data.min_event_rooms) >= 0:
		return int(current_stage_data.min_event_rooms)
	if dungeon != null and dungeon.min_event_rooms > 0:
		return dungeon.min_event_rooms
	if middle_count >= 3 and _resolve_lore_room_weight(dungeon) > 0:
		return 1
	return 0

func _enforce_min_event(seq: Array[int], dungeon: DungeonData, middle_count: int) -> void:
	var required: int = _required_min_event_rooms(dungeon, middle_count)
	if required <= 0:
		return
	var lore_count: int = 0
	for i in range(1, seq.size() - 1):
		if seq[i] == Enums.RoomType.EVENT:
			lore_count += 1
	while lore_count < required:
		var converted: bool = false
		for i in range(1, seq.size() - 1):
			if seq[i] in [Enums.RoomType.TREASURE, Enums.RoomType.TRAP, Enums.RoomType.HEAL]:
				seq[i] = Enums.RoomType.EVENT
				lore_count += 1
				converted = true
				break
		if not converted:
			break

func _roll_room_type(dungeon: DungeonData) -> int:
	var weights: Dictionary = _resolve_room_weights(dungeon)
	var r: int = randi() % 100
	if r < int(weights["combat"]):
		return Enums.RoomType.COMBAT
	r -= int(weights["combat"])
	if r < int(weights["heal"]):
		return Enums.RoomType.HEAL
	r -= int(weights["heal"])
	if r < int(weights["lore"]):
		return Enums.RoomType.EVENT
	r -= int(weights["lore"])
	if r < int(weights["treasure"]):
		return Enums.RoomType.TREASURE
	r -= int(weights["treasure"])
	if r < int(weights["trap"]):
		return Enums.RoomType.TRAP
	return Enums.RoomType.ELITE

# COMBAT が ROOM_MIN_COMBAT 未満なら、中間の非COMBAT部屋をCOMBATへ変換して補う。
# START(先頭)・BOSS(末尾) は対象外。HEAL/TREASURE/EVENT を優先的に変換し、足りなければ ELITE も変換。
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
			# 1巡目は HEAL/EVENT/TREASURE のみ、2巡目で ELITE も対象
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

func is_final_combat_encounter() -> bool:
	if not is_combat_room():
		return false
	for i in range(current_room_index + 1, room_sequence.size()):
		var rt: int = room_sequence[i]
		if rt in [Enums.RoomType.COMBAT, Enums.RoomType.ELITE, Enums.RoomType.BOSS]:
			return false
	return true

func is_on_last_floor() -> bool:
	return not room_sequence.is_empty() and current_room_index >= room_sequence.size() - 1

func is_on_last_floor_before_exit() -> bool:
	return is_on_last_floor()

func accumulate_rewards(exp: int, gold: int) -> void:
	if exp > 0:
		exp = _AffixStatCalculator.apply_exp_bonus(exp)
	run_exp_reward += exp
	if gold > 0:
		gold = _AffixStatCalculator.apply_gold_bonus(gold)
		# 探索方針（素材優先）gold +15%（P3-D098）
		if GameState.get_exploration_policy() == "material":
			gold = int(round(float(gold) * 1.15))
	run_gold_reward += gold

func get_enemy_level() -> int:
	var base: int = 1
	if current_stage_data != null:
		base = maxi(1, int(current_stage_data.enemy_level))
	elif current_dungeon_data != null:
		base = maxi(1, int(current_dungeon_data.enemy_level))
	return base + _DungeonTierConfig.enemy_level_bonus(GameState.current_dungeon_tier)

func get_tier_rarity_weight(base_weight: int) -> int:
	var mult: float = _DungeonTierConfig.rarity_weight_mult(GameState.current_dungeon_tier)
	return maxi(1, int(round(float(base_weight) * mult)))

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
	if current_stage_data != null and not current_stage_data.spawn_weights.is_empty():
		return _pick_weighted_pool_enemy(pool, current_stage_data.spawn_weights)
	return DataRegistry.get_enemy_data(pool[randi() % pool.size()] as String)

## COMBAT 雑魚: `spawn_weights` × `codex_danger` で tier 抽選 → tier 内均等（P3-ENEMY-001）。
## プールに該当 danger が無い tier は重みから除外して再正規化。
func _pick_weighted_pool_enemy(pool: Array, spawn_weights: Dictionary) -> Resource:
	var by_danger: Dictionary = {}
	for raw_id in pool:
		var enemy_data: Resource = DataRegistry.get_enemy_data(str(raw_id))
		if enemy_data == null:
			continue
		var danger_key: String = str(maxi(1, int(enemy_data.codex_danger)))
		if not by_danger.has(danger_key):
			by_danger[danger_key] = []
		(by_danger[danger_key] as Array).append(enemy_data)
	var tier_entries: Array = []
	var total_weight: int = 0
	for danger_key in spawn_weights.keys():
		var tier_weight: int = int(spawn_weights[danger_key])
		if tier_weight <= 0:
			continue
		var enemies: Array = by_danger.get(str(danger_key), [])
		if enemies.is_empty():
			continue
		tier_entries.append({"weight": tier_weight, "enemies": enemies})
		total_weight += tier_weight
	if total_weight <= 0 or tier_entries.is_empty():
		return DataRegistry.get_enemy_data(pool[randi() % pool.size()] as String)
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	for entry in tier_entries:
		cumulative += int(entry["weight"])
		if roll < cumulative:
			var tier_enemies: Array = entry["enemies"]
			return tier_enemies[randi() % tier_enemies.size()]
	var fallback_enemies: Array = tier_entries[tier_entries.size() - 1]["enemies"]
	return fallback_enemies[randi() % fallback_enemies.size()]

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
	var boss_id: String = ""
	if current_stage_data != null and not str(current_stage_data.boss_id).is_empty():
		boss_id = str(current_stage_data.boss_id)
	else:
		boss_id = str(current_dungeon_data.boss_id)
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

# COMBAT 部屋で群れ出現を抽選する確率（P3-D082）。4人編成リバランスで微増（P3-BAL-003）。
const SWARM_CHANCE: float = BalanceConfig.SWARM_CHANCE
# 複数体出現時、追加枠を別種にする確率（P3-D110・混成エンカウント）。
const MIXED_SWARM_CHANCE: float = BalanceConfig.MIXED_SWARM_CHANCE

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

# 戦闘の敵編成を返す（P3-D082 + P3-D110 混成 + P3-WANDER-001 放浪差し込み）。
# BOSS/ELITE は常に単体。COMBAT は放浪抽選→群れ抽選の順。
func pick_combat_enemy_group() -> Array[Resource]:
	var group: Array[Resource] = []
	if current_room_type == Enums.RoomType.COMBAT:
		var wander: Resource = try_pick_wandering_enemy()
		if wander != null:
			group.append(wander)
			return group
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

func try_pick_wandering_enemy(rng: RandomNumberGenerator = null) -> Resource:
	if current_room_type != Enums.RoomType.COMBAT:
		return null
	var wander_id: String = _WanderingEnemyConfig.try_roll_wandering_id(rng)
	if wander_id.is_empty():
		return null
	return DataRegistry.get_enemy_data(wander_id)

func pick_event() -> Dictionary:
	var pool: Array = _filtered_event_pool()
	if pool.is_empty():
		pool = _get_event_pool()
	if pool.is_empty():
		return {}
	current_event = pool[randi() % pool.size()].duplicate(true)
	var event_id: String = str(current_event.get("id", ""))
	if not event_id.is_empty():
		_mark_event_seen(event_id)
	return current_event

func _filtered_event_pool() -> Array:
	var combined: Array = _get_event_pool()
	var filtered: Array = []
	for ev: Dictionary in combined:
		var event_id: String = str(ev.get("id", ""))
		if event_id.is_empty() or event_id in _seen_event_ids:
			continue
		filtered.append(ev)
	return filtered

func _mark_event_seen(event_id: String) -> void:
	if event_id.is_empty() or event_id in _seen_event_ids:
		return
	_seen_event_ids.append(event_id)

func _get_event_pool() -> Array:
	var combined: Array = []
	if current_dungeon_data == null:
		combined.append_array(EVENTS)
	else:
		combined.append_array(EVENTS)
		combined.append_array(DUNGEON_EVENTS.get(str(current_dungeon_data.id), []))
	var lore_only: Array = []
	for ev: Dictionary in combined:
		if _is_lore_event(ev):
			lore_only.append(ev)
	return lore_only

func _is_lore_event(event: Dictionary) -> bool:
	var outcome: Dictionary = event.get("outcome", {})
	return str(outcome.get("type", "")) == "lore"

func auto_resolve_event() -> Dictionary:
	return resolve_event_outcome(current_event.get("outcome", {"type": "nothing"}))

func resolve_event_outcome(outcome: Dictionary) -> Dictionary:
	var resolved: Dictionary = outcome.duplicate(true)
	if str(resolved.get("type", "")) != "material":
		return resolved
	if current_dungeon_data != null:
		var dungeon_id: String = str(current_dungeon_data.id)
		if dungeon_id in MOURNGATE_ECOLOGY_DUNGEON_IDS:
			if str(resolved.get("material_id", "relic_shard")) == "relic_shard":
				var mat_id: String = MOURNGATE_EVENT_MATERIAL_POOL[randi() % MOURNGATE_EVENT_MATERIAL_POOL.size()]
				resolved["material_id"] = mat_id
				resolved["discovery_id"] = mat_id
	return _finalize_material_outcome(resolved)

func _finalize_material_outcome(outcome: Dictionary) -> Dictionary:
	var resolved: Dictionary = outcome.duplicate(true)
	var mat_id: String = str(resolved.get("material_id", resolved.get("discovery_id", "relic_shard")))
	if not EquipmentEnhancer.is_enhancement_material(mat_id):
		mat_id = "relic_shard"
		resolved["material_id"] = mat_id
		resolved["discovery_id"] = mat_id
	resolved["label"] = DataRegistry.get_material_name(mat_id)
	return resolved

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

func generate_treasure_loot_failure() -> Dictionary:
	var gold: int = maxi(1, int(round(float(TREASURE_GOLD) * 0.5)))
	accumulate_rewards(0, gold)
	return {"gold": gold, "accessory_id": ""}

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

## x-5 初回ボス討伐（ノーマル）のレジェンド防具・装飾を確定付与（P3-EQ-LEG-001）。
func apply_boss_legendary_loot(stage: Resource) -> Dictionary:
	var bonus: Dictionary = {"armor_id": "", "accessory_id": ""}
	if stage == null or not bool(stage.has_boss_floor()):
		return bonus
	if GameState.current_dungeon_tier != _DungeonTierConfig.TIER_NORMAL:
		return bonus
	var stage_id: String = str(stage.id)
	if GameState.is_stage_cleared(stage_id, _DungeonTierConfig.TIER_NORMAL):
		return bonus
	var armor_id: String = str(stage.legendary_armor_id) if "legendary_armor_id" in stage else ""
	var accessory_id: String = str(stage.legendary_accessory_id) if "legendary_accessory_id" in stage else ""
	if not armor_id.is_empty():
		_spawn_armor(armor_id)
		bonus["armor_id"] = armor_id
	if not accessory_id.is_empty():
		_spawn_accessory(accessory_id)
		bonus["accessory_id"] = accessory_id
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

# P3-D074: 撃破時の武器直ドロップ。確率はボス/エリート/放浪個体で上書き可。
func roll_kill_weapon_drop(room_type: int, enemy_data: Resource = null) -> String:
	var chance: float = _resolve_weapon_drop_chance(room_type, enemy_data)
	if chance <= 0.0:
		return ""
	if randf() > chance:
		return ""
	var weapon_id: String = _pick_weighted_weapon(enemy_data)
	_spawn_weapon(weapon_id)
	return weapon_id

func _resolve_weapon_drop_chance(room_type: int, enemy_data: Resource) -> float:
	if enemy_data != null and float(enemy_data.weapon_drop_chance) >= 0.0:
		return minf(
			1.0,
			float(enemy_data.weapon_drop_chance)
			* EventSystem.get_modifier_mult(EventSystem.MOD_WEAPON_DROP)
			* _EvolutionTraits.party_weapon_drop_mult()
		)
	var chance: float = 0.25
	if room_type == Enums.RoomType.BOSS:
		chance = 1.0
	elif room_type == Enums.RoomType.ELITE:
		chance = 0.6
	return minf(1.0, chance * EventSystem.get_modifier_mult(EventSystem.MOD_WEAPON_DROP) * _EvolutionTraits.party_weapon_drop_mult())

# P3-D093: 撃破時の遺物ドロップ（解放型）。未所持の遺物から1つ解放する。
const RELIC_DROP_CHANCE_BOSS: float = 0.10
const RELIC_DROP_CHANCE_ELITE: float = 0.05
const RELIC_DROP_POLICY_BONUS: float = 0.05

func roll_kill_relic_drop(room_type: int) -> String:
	var pool: Array = GameState.unowned_relic_ids()
	if pool.is_empty():
		return ""
	var chance: float = 0.0
	var policy_bonus: float = RELIC_DROP_POLICY_BONUS if GameState.get_exploration_policy() == "relic" else 0.0
	if room_type == Enums.RoomType.BOSS:
		chance = RELIC_DROP_CHANCE_BOSS + policy_bonus
	elif room_type == Enums.RoomType.ELITE:
		chance = RELIC_DROP_CHANCE_ELITE + policy_bonus
	if chance <= 0.0 or randf() > chance:
		return ""
	var relic_id: String = str(pool[randi() % pool.size()])
	if GameState.unlock_relic(relic_id):
		last_relic_dropped = relic_id
		return relic_id
	return ""

# ダンジョン別武器プール（P3-D154）。未設定はグローバル既定 WEAPON_POOL。
func _active_weapon_pool() -> Array:
	if current_dungeon_data != null and not current_dungeon_data.weapon_pool.is_empty():
		return current_dungeon_data.weapon_pool
	return WEAPON_POOL

# 武器プールからレア度重みで1本抽選（放浪個体は weapon_rarity_weights で上書き可）。
func _pick_weighted_weapon(enemy_data: Resource = null) -> String:
	var pool: Array = _active_weapon_pool()
	var weights: Array[int] = []
	var total: int = 0
	for wid in pool:
		var wdata: Resource = DataRegistry.get_weapon_data(str(wid))
		var r: int = 0 if wdata == null else int(wdata.rarity)
		var base_w: int = _rarity_drop_weight_for(r, enemy_data)
		var w: int = get_tier_rarity_weight(
			_AffixStatCalculator.apply_rarity_drop_weight(base_w, r)
		)
		weights.append(w)
		total += w
	if total <= 0:
		return str(pool[randi() % pool.size()])
	var roll: int = randi() % total
	var cumulative: int = 0
	for i in pool.size():
		cumulative += weights[i]
		if roll < cumulative:
			return str(pool[i])
	return str(pool[pool.size() - 1])

func _rarity_drop_weight_for(rarity: int, enemy_data: Resource) -> int:
	if enemy_data != null and not enemy_data.weapon_rarity_weights.is_empty():
		var custom: Dictionary = enemy_data.weapon_rarity_weights
		if custom.has(rarity):
			return int(custom[rarity])
		var key: String = str(rarity)
		if custom.has(key):
			return int(custom[key])
	return int(RARITY_DROP_WEIGHT.get(rarity, 1))

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
	_WeaponStatResolver.apply_drop_stats(instance, weapon_data)
	EquipmentEnhancer.assign_drop_equip_level(instance, current_stage_data, current_dungeon_data)
	_auto_appraise(instance, _AffixRoller.CATEGORY_WEAPON, weapon_data.rarity)
	GameState.inventory.append(instance)
	last_weapon_dropped = weapon_id
	EventBus.weapon_obtained.emit(weapon_id)

func _generate_armor_loot() -> void:
	# ダンジョン別プール（P3-D154）。未設定は従来: 革(rarity0)70% / 骨(rarity1)30%
	if current_dungeon_data != null and not current_dungeon_data.armor_pool.is_empty():
		_spawn_armor(_pick_rarity_weighted(current_dungeon_data.armor_pool, "armor"))
		return
	var armor_id: String = "bone_armor" if randf() < 0.3 else "leather_armor"
	_spawn_armor(armor_id)

# プールからレア度重み（RARITY_DROP_WEIGHT）で1件抽選する（armor/accessory 共用）。
func _pick_rarity_weighted(pool: Array, category: String) -> String:
	var weights: Array[int] = []
	var total: int = 0
	for iid in pool:
		var data: Resource = null
		if category == "armor":
			data = DataRegistry.get_armor_data(str(iid))
		else:
			data = DataRegistry.get_accessory_data(str(iid))
		var r: int = 0 if data == null else int(data.rarity)
		var w: int = get_tier_rarity_weight(
			_AffixStatCalculator.apply_rarity_drop_weight(int(RARITY_DROP_WEIGHT.get(r, 1)), r)
		)
		weights.append(w)
		total += w
	if total <= 0:
		return str(pool[randi() % pool.size()])
	var roll: int = randi() % total
	var cumulative: int = 0
	for i in pool.size():
		cumulative += weights[i]
		if roll < cumulative:
			return str(pool[i])
	return str(pool[pool.size() - 1])

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
	_ArmorStatResolver.apply_drop_stats(instance, armor_data)
	instance.rarity = armor_data.rarity
	EquipmentEnhancer.assign_drop_equip_level(instance, current_stage_data, current_dungeon_data)
	_auto_appraise(instance, _AffixRoller.CATEGORY_ARMOR, armor_data.rarity)
	GameState.armor_inventory.append(instance)
	last_armor_dropped = armor_id

func _generate_accessory_loot() -> void:
	# ダンジョン別プール（P3-D154）。未設定は従来: silver_ring のみ
	if current_dungeon_data != null and not current_dungeon_data.accessory_pool.is_empty():
		_spawn_accessory(_pick_rarity_weighted(current_dungeon_data.accessory_pool, "accessory"))
		return
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
	_AccessoryStatResolver.apply_drop_stats(instance, accessory_data)
	EquipmentEnhancer.assign_drop_equip_level(instance, current_stage_data, current_dungeon_data)
	_auto_appraise(instance, _AffixRoller.CATEGORY_ACCESSORY, accessory_data.rarity)
	GameState.accessory_inventory.append(instance)
	last_accessory_dropped = accessory_id
