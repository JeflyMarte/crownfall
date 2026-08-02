extends Node

const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")
const _AffixRoller = preload("res://scripts/equipment/AffixRoller.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _EnemyTierVariantConfig = preload("res://scripts/dungeon/EnemyTierVariantConfig.gd")
const _WanderingEnemyConfig = preload("res://scripts/dungeon/WanderingEnemyConfig.gd")
const _EvolutionTraits = preload("res://scripts/systems/EvolutionTraits.gd")
const MythicLoot = preload("res://scripts/equipment/MythicLoot.gd")
const _AbyssLegendaryWeapons = preload("res://scripts/dungeon/AbyssLegendaryWeapons.gd")
const _EventExclusiveRewards = preload("res://scripts/dungeon/EventExclusiveRewards.gd")
const _BalanceConfig = preload("res://scripts/combat/BalanceConfig.gd")

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



## P3-BAL-NONCOMBAT-001
const TREASURE_GOLD: int = 40
const TREASURE_ACCESSORY_CHANCE: float = 0.35
const TREASURE_WEAPON_CHANCE: float = BalanceConfig.TREASURE_WEAPON_CHANCE
const ELITE_REWARD_MULTIPLIER: float = 1.5
const ELITE_ARMOR_CHANCE: float = 0.35
const ELITE_ACCESSORY_CHANCE: float = 0.25
## P3-BAL-ECO-001: エリート骨鉱 20%→25%（素材優先は +10pt）
const ELITE_MATERIAL_CHANCE: float = 0.25
## P3-BAL-ECO-001: ボス深層結晶ボーナス 35%→45%
const BOSS_EPIC_ORE_CHANCE: float = 0.45
## P3-BAL-DROP-001: 雑魚直ドロップ武器率（旧 0.25）
const COMBAT_WEAPON_DROP_CHANCE: float = 0.20
const ELITE_WEAPON_DROP_CHANCE: float = 0.60
const BOSS_WEAPON_DROP_CHANCE: float = 1.00
## P3-BAL-DROP-001: ラン終了防具／装飾（旧 0.30 / 0.20）
const RUN_ARMOR_DROP_CHANCE: float = 0.40
const RUN_ACCESSORY_DROP_CHANCE: float = 0.30
const DISCOVERY_PER_ROOM: float = 0.05
const DISCOVERY_BOSS_BONUS: float = 0.20

## 炉研ぎ素材のみ（`EquipmentEnhancer.EVENT_DROP_MATERIAL_IDS` と同期）。
const MOURNGATE_EVENT_MATERIAL_POOL: Array[String] = ["base_ore", "relic_shard"]
const MOURNGATE_ECOLOGY_DUNGEON_IDS: Array[String] = [
	"mourngate",
	"chronos_mausoleum",
	"astoria_ruins",
]

const EVENTS: Array = [
	{
		"id": "fallen_altar",
		"description": "崩れた祭壇を発見し、碑文に触れた。",
		"outcome": {"type": "heal", "amount": 64},
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
		"id": "mourngate_blank_page",
		"description": "記録庁の聞き書きを写し、継承の書の白紙の話を残した。",
		"outcome": {"type": "lore", "label": "継承の白紙", "discovery_id": "mourngate_blank_page"},
	},
	{
		"id": "mourngate_no_victor",
		"description": "崩落期の断簡を見つけ、勝者なき戦の記述を書き写した。",
		"outcome": {"type": "lore", "label": "勝者なき戦", "discovery_id": "mourngate_no_victor"},
	},
	{
		"id": "mourngate_successor_stone",
		"description": "王座の深淵で崩れた石を見つけ、継ぐ者への碑文を書き留めた。",
		"outcome": {"type": "lore", "label": "継ぐ者への碑", "discovery_id": "mourngate_successor_stone"},
	},
	{
		"id": "mourngate_nameless_heir",
		"description": "記録保管区の断簡を見つけ、名なき継承の覚書を写した。",
		"outcome": {"type": "lore", "label": "名なき継承の覚書", "discovery_id": "mourngate_nameless_heir"},
	},
	{
		"id": "mourngate_war_versions",
		"description": "記録部の整理票を見つけ、戦争伝承の三つの写本を突き合わせた。",
		"outcome": {"type": "lore", "label": "三つの写本", "discovery_id": "mourngate_war_versions"},
	},
	{
		"id": "mourngate_chrono_shelf",
		"description": "クロノ庫の空棚を調べ、棚札の裏書きを記録した。",
		"outcome": {"type": "lore", "label": "クロノ庫の空棚", "discovery_id": "mourngate_chrono_shelf"},
	},
	{
		"id": "mourngate_shield_gate",
		"description": "ストームクラウン砦跡の門文の写しを見つけ、静けさの碑を書き留めた。",
		"outcome": {"type": "lore", "label": "静けさの門", "discovery_id": "mourngate_shield_gate"},
	},
	{
		"id": "mourngate_temp_companion",
		"description": "負傷した探索者と出会い、応急手当の知恵を得た。",
		"outcome": {"type": "heal", "amount": 80},
	},
]

const EVENTS_WHISPERWOOD: Array = [
	{
		"id": "whisperwood_moss_spring",
		"description": "苔むした岩の間に澄んだ湧水を見つけ、傷を洗った。",
		"outcome": {"type": "heal", "amount": 80},
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
	{
		"id": "whisperwood_worldtree_note",
		"description": "世界樹の照合票の写しを見つけ、覚書を記録した。",
		"outcome": {"type": "lore", "label": "世界樹の覚書", "discovery_id": "whisperwood_worldtree_note"},
	},
	{
		"id": "whisperwood_seed_verse",
		"description": "翠の祠で苔に覆われた詩片を見つけ、種の文言を書き写した。",
		"outcome": {"type": "lore", "label": "種の詩片", "discovery_id": "whisperwood_seed_verse"},
	},
	{
		"id": "whisperwood_verdant_oath",
		"description": "森番の柱の根元に古い刻を見つけ、翠の盟約の文言を記録した。",
		"outcome": {"type": "lore", "label": "翠の盟約の刻", "discovery_id": "whisperwood_verdant_oath"},
	},
]

const EVENTS_MISTFEN: Array = [
	{
		"id": "mistfen_dry_islet",
		"description": "乾いた中州を見つけ、泥を落として小休止した。",
		"outcome": {"type": "heal", "amount": 96},
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
	{
		"id": "mistfen_sealed_ask",
		"description": "半没書庫の楣に刻まれた一文を見つけ、欠落ごと書き留めた。",
		"outcome": {"type": "lore", "label": "封じの問い", "discovery_id": "mistfen_sealed_ask"},
	},
	{
		"id": "mistfen_idealess_relic",
		"description": "沈没書庫の欄外票を見つけ、理念なき遺産の聞き書きを写した。",
		"outcome": {"type": "lore", "label": "理念なき遺産", "discovery_id": "mistfen_idealess_relic"},
	},
	{
		"id": "mistfen_why_sealed",
		"description": "半没書庫の扉裏に走り書きを見つけ、封じの理由の欠落を記録した。",
		"outcome": {"type": "lore", "label": "封じの理由", "discovery_id": "mistfen_why_sealed"},
	},
]

const EVENTS_ASTORIA_RUINS: Array = [
	{
		"id": "astoria_crown_bridge_rubble",
		"description": "王冠橋の落石を避けながら、崩落前の街道標識を書き写した。",
		"outcome": {"type": "lore", "label": "落橋の標識", "discovery_id": "astoria_fallen_sign"},
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
	{
		"id": "green_hollow_root_mark",
		"description": "湿地の大根に小さな標を見つけ、刻文を書き写した。",
		"outcome": {"type": "lore", "label": "根の標", "discovery_id": "green_hollow_root_mark"},
	},
	{
		"id": "green_hollow_kyle_mark",
		"description": "湿地端の小さな標を見つけ、距離の文言を書き留めた。",
		"outcome": {"type": "lore", "label": "距離の標", "discovery_id": "green_hollow_kyle_mark"},
	},
]

const EVENTS_BLACKSHORE: Array = [
	{
		"id": "blackshore_tidal_pool",
		"description": "干潮の潮溜まりで聖別の残光を掬い、傷を癒した。",
		"outcome": {"type": "heal", "amount": 112},
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
		"id": "blackshore_lost_course",
		"description": "沈没旗艦の船室で塗りつぶされた航路名を見つけ、記録した。",
		"outcome": {"type": "lore", "label": "失われた航路", "discovery_id": "blackshore_lost_course"},
	},
	{
		"id": "blackshore_marek_log",
		"description": "座礁船の防水箱から航海録の端切れを見つけ、書き写した。",
		"outcome": {"type": "lore", "label": "航海録の端", "discovery_id": "blackshore_marek_log"},
	},
	{
		"id": "blackshore_first_flame",
		"description": "干潟の辻灯亭の落書きの写しを見つけ、最初の火の問いを記録した。",
		"outcome": {"type": "lore", "label": "最初の火", "discovery_id": "blackshore_first_flame"},
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
		"outcome": {"type": "heal", "amount": 96},
	},
	{
		"id": "westbay_salt_prayer",
		"description": "貝殻線の先に塩で描かれた円を見つけ、文言を書き留めた。",
		"outcome": {"type": "lore", "label": "塩の祈り", "discovery_id": "westbay_salt_prayer"},
	},
]

const EVENTS_FROSTRIDGE: Array = [
	{
		"id": "frostridge_snow_shelter",
		"description": "雪庇の下で体を温め、凍傷を防いだ。",
		"outcome": {"type": "heal", "amount": 128},
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
		"id": "frostridge_mapless_north",
		"description": "開拓隊の携帯地図の余白注記を見つけ、写し取った。",
		"outcome": {"type": "lore", "label": "地図なき北", "discovery_id": "frostridge_mapless_north"},
	},
	{
		"id": "frostridge_keep_flame",
		"description": "北境の宿場跡で灯火の教えを聞き書きし、記録した。",
		"outcome": {"type": "lore", "label": "絶やすなという教え", "discovery_id": "frostridge_keep_flame"},
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
	{
		"id": "frostwall_ice_oath",
		"description": "氷壁の裂け目に凍った布きれを見つけ、文言を書き写した。",
		"outcome": {"type": "lore", "label": "氷壁の誓い", "discovery_id": "frostwall_ice_oath"},
	},
	{
		"id": "frostwall_asten_margin",
		"description": "開拓隊の携帯地図の別葉を見つけ、余白の注記を写し取った。",
		"outcome": {"type": "lore", "label": "余白の注記", "discovery_id": "frostwall_asten_margin"},
	},
]

const EVENTS_BROKEN_MARSH: Array = [
	{
		"id": "broken_marsh_bridge_bell",
		"description": "崩落街道橋の欄干に残る錆びた鈴を見つけ、銘を書き留めた。",
		"outcome": {"type": "lore", "label": "落橋の鈴", "discovery_id": "broken_marsh_bridge_bell"},
	},
]

# ダンジョン別イベント（P3-EVT-001）。id 一致で EVENTS へ加算。
const DUNGEON_EVENTS: Dictionary = {
	"mourngate": EVENTS_MOURNGATE,
	"astoria_ruins": EVENTS_MOURNGATE + EVENTS_ASTORIA_RUINS,
	"whisperwood": EVENTS_WHISPERWOOD,
	"green_hollow": EVENTS_WHISPERWOOD + EVENTS_GREEN_HOLLOW,
	"mistfen": EVENTS_MISTFEN,
	"broken_marsh": EVENTS_MISTFEN + EVENTS_BROKEN_MARSH,
	"blackshore": EVENTS_BLACKSHORE,
	"westbay_flats": EVENTS_BLACKSHORE + EVENTS_WESTBAY_FLATS,
	"frostridge": EVENTS_FROSTRIDGE,
	"frostwall_path": EVENTS_FROSTRIDGE + EVENTS_FROSTWALL_PATH,
	"chronos_mausoleum": EVENTS_MOURNGATE,
	"valgard_boundary": EVENTS_WHISPERWOOD,
	"red_ridge_mine": EVENTS_WHISPERWOOD,
	"mistfen_depths": EVENTS_MISTFEN,
	"thunder_peak": EVENTS_MISTFEN,
	"blackshore_abyss": EVENTS_BLACKSHORE,
	"red_forge_depths": EVENTS_FROSTRIDGE,
	"north_reach": EVENTS_FROSTRIDGE,
}

static func get_event_display_name(event_id: String) -> String:
	if event_id.is_empty():
		return ""
	for ev: Dictionary in _all_event_definitions():
		if str(ev.get("id", "")) != event_id:
			continue
		var outcome: Dictionary = ev.get("outcome", {})
		var label: String = str(outcome.get("label", ""))
		if not label.is_empty():
			return label
		var desc: String = str(ev.get("description", ""))
		if not desc.is_empty():
			return desc
	return ""


static func _all_event_definitions() -> Array:
	var out: Array = []
	out.append_array(EVENTS)
	out.append_array(EVENTS_MOURNGATE)
	out.append_array(EVENTS_WHISPERWOOD)
	out.append_array(EVENTS_MISTFEN)
	out.append_array(EVENTS_ASTORIA_RUINS)
	out.append_array(EVENTS_GREEN_HOLLOW)
	out.append_array(EVENTS_BLACKSHORE)
	out.append_array(EVENTS_WESTBAY_FLATS)
	out.append_array(EVENTS_FROSTRIDGE)
	out.append_array(EVENTS_FROSTWALL_PATH)
	var seen: Dictionary = {}
	for ev: Dictionary in out:
		var id: String = str(ev.get("id", ""))
		if not id.is_empty():
			seen[id] = true
	for dungeon_id in DUNGEON_EVENTS:
		for ev: Dictionary in DUNGEON_EVENTS[dungeon_id]:
			var id: String = str(ev.get("id", ""))
			if id.is_empty() or id in seen:
				continue
			seen[id] = true
			out.append(ev)
	return out

var current_dungeon_data: Resource = null
var current_stage_data: Resource = null
var current_room_index: int = 0
var room_sequence: Array[int] = []
var current_room_type: int = Enums.RoomType.START
var is_completed: bool = false
var current_exploration_policy: int = Enums.ExplorationPolicy.EXPLORE
var run_exp_reward: int = 0
## 撃破時点の生存者ごとの累積EXP（死者は以降の撃破分を受け取らない）。
var run_exp_by_member: Dictionary = {}
var run_gold_reward: int = 0
var last_weapon_dropped: String = ""
var last_armor_dropped: String = ""
var last_accessory_dropped: String = ""
var last_relic_dropped: String = ""
## 深層: 直前 advance が 10F 境界で天候再抽選したか（Scene が VFX 更新に使う）。
var last_abyss_weather_rerolled: bool = false
## 再抽選の結果、天候 id が変わったか（同抽選ならログしない）。
var last_abyss_weather_changed: bool = false
var current_event: Dictionary = {}
var run_damage_multiplier: float = 1.0
## 碑文加護: 次フロア（部屋）限定。kind = exp|gold|equip。
var floor_blessing_kind: String = ""
var floor_blessing_room_index: int = -1
var _seen_event_ids: Array[String] = []
## ラン開始時に COMBAT 部屋ごとの放浪出現を事前抽選（予兆表示用）。未計画時はライブ抽選。
var _wander_plan_ready: bool = false
var _planned_wander_by_room: Dictionary = {}

func start_dungeon(dungeon_id: String) -> void:
	## 章データがあれば start_stage（深層含む。無限延長は route_type=abyss で維持）。
	## 深層の biome_id は abyss_* なので親メイン章へ誤誘導しない。
	if Constants.SUB_STAGES_PLAYABLE:
		var stage_id: String = GameState.resolve_stage_for_run(dungeon_id)
		if not stage_id.is_empty():
			start_stage(stage_id)
			return
	current_stage_data = null
	current_dungeon_data = DataRegistry.get_dungeon_data(dungeon_id)
	if current_dungeon_data == null:
		push_error("DataRegistry: dungeon not found: %s" % dungeon_id)
		return
	room_sequence = _build_room_sequence(current_dungeon_data)
	_reset_run_state()
	if _is_abyss_run():
		_sync_abyss_tier_for_current_floor()
		_note_abyss_progress()

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
	if _is_abyss_run():
		_sync_abyss_tier_for_current_floor()
		_note_abyss_progress()

func _reset_run_state() -> void:
	current_room_index = 0
	current_room_type = room_sequence[0]
	is_completed = false
	current_exploration_policy = Enums.ExplorationPolicy.EXPLORE
	run_exp_reward = 0
	run_exp_by_member = {}
	run_gold_reward = 0
	last_weapon_dropped = ""
	last_armor_dropped = ""
	last_accessory_dropped = ""
	last_relic_dropped = ""
	current_event = {}
	run_damage_multiplier = 1.0
	_clear_floor_blessing()
	_seen_event_ids.clear()
	## 前回ランまでの New バッジを潜行開始で消す。
	GameState.clear_new_equipment_marks()
	GameState.set_weather(_roll_run_weather())
	_init_discovery()
	_plan_wandering_encounters()


func _plan_wandering_encounters() -> void:
	_planned_wander_by_room.clear()
	_wander_plan_ready = true
	if current_dungeon_data != null and bool(current_dungeon_data.disable_wandering):
		return
	var tier: int = GameState.current_dungeon_tier
	var allow_stalker: bool = _shadow_stalker_allowed_on_current_stage()
	for i: int in range(room_sequence.size()):
		if room_sequence[i] != Enums.RoomType.COMBAT:
			continue
		var wander_id: String = _WanderingEnemyConfig.try_roll_wandering_id(
			null, tier, allow_stalker
		)
		if not wander_id.is_empty():
			_planned_wander_by_room[i] = wander_id


func _shadow_stalker_allowed_on_current_stage() -> bool:
	## 1-1〜1-3 は影狩りのみ除外（予兆計画・ライブ抽選の共通判定）。深層は制限しない。
	if current_stage_data == null or _is_abyss_run():
		return true
	return _WanderingEnemyConfig.is_shadow_stalker_allowed_on_stage(
		int(current_stage_data.biome_index),
		int(current_stage_data.chapter_index)
	)


func should_show_shadow_stalker_omen() -> bool:
	## 影狩り出現フロアの入場一幕で予兆を出す（前フロアだと次が別敵になり演出と不一致）。
	if current_room_index < 0 or current_room_index >= room_sequence.size():
		return false
	return (
		str(_planned_wander_by_room.get(current_room_index, ""))
		== _WanderingEnemyConfig.ID_SHADOW_STALKER
	)


func _roll_run_weather() -> String:
	var forced: String = EventSystem.forced_weather_id()
	if not forced.is_empty():
		return CombatWeather.normalize(forced)
	var dungeon_id: String = ""
	if current_dungeon_data != null:
		dungeon_id = str(current_dungeon_data.id)
	return CombatWeather.roll(dungeon_id)

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

## モーンゲート 1-1〜1-3（深層・他Biome除外）。
func _is_mourngate_early_chapter() -> bool:
	if current_stage_data == null or _is_abyss_run():
		return false
	var biome_i: int = int(current_stage_data.biome_index)
	var chapter_i: int = int(current_stage_data.chapter_index)
	return biome_i == 1 and chapter_i >= 1 and chapter_i <= 3


## 1-1〜1-3 のみ群れ率を下げる（イベント forced_swarm／深層は対象外）。
func _early_stage_swarm_chance_mult() -> float:
	if _is_mourngate_early_chapter():
		return BalanceConfig.EARLY_STAGE_SWARM_CHANCE_MULT
	return 1.0


## モーンゲート 1-1〜1-3・ノーマルのみ群れ頭数上限。非該当は -1（無制限＝既存キャップのみ）。
func _early_normal_swarm_size_cap() -> int:
	if not _is_mourngate_early_chapter():
		return -1
	if int(GameState.current_dungeon_tier) != _DungeonTierConfig.TIER_NORMAL:
		return -1
	return BalanceConfig.EARLY_STAGE_SWARM_SIZE_CAP


## モーンゲート 1-1〜1-3・ノーマルはエリート部屋を出さない。
func _early_normal_elites_disabled() -> bool:
	if not _is_mourngate_early_chapter():
		return false
	return int(GameState.current_dungeon_tier) == _DungeonTierConfig.TIER_NORMAL

func get_run_recommended_level() -> int:
	var base: int = 0
	if current_stage_data != null and int(current_stage_data.recommended_level) > 0:
		base = int(current_stage_data.recommended_level)
	elif current_dungeon_data != null and int(current_dungeon_data.recommended_level) > 0:
		base = int(current_dungeon_data.recommended_level)
	if base <= 0:
		return 0
	return _DungeonTierConfig.apply_tier_level(base, GameState.current_dungeon_tier)

func get_display_floor_max() -> int:
	if _is_abyss_run():
		return maxi(1, room_sequence.size())
	if current_stage_data != null:
		return maxi(1, int(current_stage_data.floor_count))
	return maxi(1, get_total_rooms())

func get_display_floor_current() -> int:
	if _is_abyss_run():
		return maxi(1, current_room_index + 1)
	return mini(current_room_index + 1, get_display_floor_max())

func get_display_floor_text() -> String:
	if _is_abyss_run():
		## 無限は分母なし。`12F/??`（P3-DG-ABYSS 表示）。
		return "%dF/??" % get_display_floor_current()
	return "F%d/%d" % [get_display_floor_current(), get_display_floor_max()]


## ランHUD用。現在フロア／最大フロア（例: 5/10 → 50%）。
## 深層は無限のため％なし（UIは「?」表示・P3-UX-ABYSS-PROGRESS-HIDE-001）。
func get_display_floor_progress_percent() -> int:
	if _is_abyss_run():
		return -1
	var floor_max: int = get_display_floor_max()
	if floor_max <= 0:
		return 0
	var floor_current: int = get_display_floor_current()
	return clampi(int(round(float(floor_current) * 100.0 / float(floor_max))), 0, 100)


func get_display_floor_progress_label() -> String:
	if _is_abyss_run():
		return "進行 ?%"
	return "進行 %d%%" % get_display_floor_progress_percent()


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
	var prog: Dictionary = GameState.dungeon_progress.get(did, {})
	if not prog.has("discovery"):
		prog["discovery"] = 0.0
	if not prog.has("hidden_room"):
		prog["hidden_room"] = false
	if not prog.has("hidden_boss"):
		prog["hidden_boss"] = false
	GameState.dungeon_progress[did] = prog

func set_policy(policy: int) -> void:
	current_exploration_policy = policy

func advance_room() -> void:
	last_abyss_weather_rerolled = false
	last_abyss_weather_changed = false
	current_room_index += 1
	_expire_floor_blessing_if_needed()
	if current_room_index >= room_sequence.size():
		if _is_abyss_run():
			_extend_abyss_chunk()
		else:
			is_completed = true
			return
	current_room_type = room_sequence[current_room_index]
	update_discovery()
	if _is_abyss_run():
		_sync_abyss_tier_for_current_floor()
		_note_abyss_progress()
		last_abyss_weather_rerolled = _maybe_reroll_abyss_block_weather()


func _clear_floor_blessing() -> void:
	floor_blessing_kind = ""
	floor_blessing_room_index = -1


func _expire_floor_blessing_if_needed() -> void:
	if floor_blessing_kind.is_empty():
		return
	if current_room_index > floor_blessing_room_index:
		_clear_floor_blessing()


## 碑文成功時。次フロア向けに EXP／Gold／装備ドロップのいずれか ×1.1。
func grant_lore_floor_blessing() -> Dictionary:
	var kinds: Array[String] = BalanceConfig.LORE_FLOOR_BLESSING_KINDS.duplicate()
	if kinds.is_empty():
		return {}
	floor_blessing_kind = str(kinds[randi() % kinds.size()])
	floor_blessing_room_index = current_room_index + 1
	return {
		"kind": floor_blessing_kind,
		"mult": BalanceConfig.LORE_FLOOR_BLESSING_MULT,
		"label": floor_blessing_label(floor_blessing_kind),
	}


static func floor_blessing_label(kind: String) -> String:
	match kind:
		"exp":
			return "経験値"
		"gold":
			return "ゴールド"
		"equip":
			return "装備ドロップ"
		_:
			return kind


func floor_blessing_mult_for(kind: String) -> float:
	if floor_blessing_kind.is_empty() or floor_blessing_kind != kind:
		return 1.0
	if current_room_index != floor_blessing_room_index:
		return 1.0
	return BalanceConfig.LORE_FLOOR_BLESSING_MULT


func has_active_floor_blessing() -> bool:
	return (
		not floor_blessing_kind.is_empty()
		and current_room_index == floor_blessing_room_index
	)

func get_total_rooms() -> int:
	return room_sequence.size()


func _is_abyss_run() -> bool:
	const _AbyssDungeonConfig := preload("res://scripts/dungeon/AbyssDungeonConfig.gd")
	return _AbyssDungeonConfig.is_abyss_data(current_dungeon_data)


func is_abyss_run() -> bool:
	return _is_abyss_run()


func _sync_abyss_tier_for_current_floor() -> void:
	if not _is_abyss_run():
		return
	const _AbyssDungeonConfig := preload("res://scripts/dungeon/AbyssDungeonConfig.gd")
	GameState.current_dungeon_tier = _AbyssDungeonConfig.synthetic_tier_for_floor(
		get_display_floor_current()
	)


func _note_abyss_progress() -> void:
	if not _is_abyss_run() or current_dungeon_data == null:
		return
	GameState.note_abyss_floor_reached(str(current_dungeon_data.id), get_display_floor_current())


func _extend_abyss_chunk() -> void:
	const _AbyssDungeonConfig := preload("res://scripts/dungeon/AbyssDungeonConfig.gd")
	if current_dungeon_data == null:
		is_completed = true
		return
	var chunk: Array[int] = _generate_random_sequence(
		current_dungeon_data,
		_AbyssDungeonConfig.CHUNK_FLOORS,
		false,
		false
	)
	for room_type: int in chunk:
		room_sequence.append(room_type)
	## 延長後も完走扱いにしない。
	is_completed = false


## 深層のみ: 10F チャンク先頭で天候を再抽選（本編は run 開始1回のまま・P3-D101）。
## 戻り値は境界で再抽選を実行したか。id 変化は last_abyss_weather_changed。
func _maybe_reroll_abyss_block_weather() -> bool:
	const _AbyssDungeonConfig := preload("res://scripts/dungeon/AbyssDungeonConfig.gd")
	if not _is_abyss_run():
		return false
	var floor_n: int = get_display_floor_current()
	if floor_n <= 1 or not _AbyssDungeonConfig.is_block_start_floor(floor_n):
		return false
	var prev: String = CombatWeather.normalize(GameState.get_weather())
	var next: String = CombatWeather.normalize(_roll_run_weather())
	GameState.set_weather(next)
	last_abyss_weather_changed = prev != next
	return true

# ── 部屋列の生成 ─────────────────────────────────────────────
# floor_count > 0: ランダム抽選（肩慣らし COMBAT + 重み付き中間 + [BOSS]）。EXIT は別フロアにしない。
# floor_count <= 0: 従来固定列（ROOM_SEQUENCE を room_count で切り詰め）
func _build_room_sequence(dungeon: DungeonData) -> Array[int]:
	if dungeon.floor_count > 0:
		var include_boss: bool = not str(dungeon.boss_id).is_empty()
		return _generate_random_sequence(dungeon, dungeon.floor_count, include_boss, false)
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
	if require_elite and not _early_normal_elites_disabled():
		_enforce_required_elite(seq)
	_enforce_last_floor_combat(seq)
	if _early_normal_elites_disabled():
		_strip_elite_rooms(seq)
	return seq


func _strip_elite_rooms(seq: Array[int]) -> void:
	for i: int in seq.size():
		if seq[i] == Enums.RoomType.ELITE:
			seq[i] = Enums.RoomType.COMBAT

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
	var elite_mult: float = EventSystem.get_elite_room_weight_mult()
	var weights: Dictionary = {}
	if dungeon != null and not dungeon.room_weight_overrides.is_empty():
		var o: Dictionary = dungeon.room_weight_overrides
		var elite_base: int = maxi(0, int(o.get("elite", ROOM_WEIGHT_ELITE)))
		weights = {
			"combat": maxi(0, int(o.get("combat", ROOM_WEIGHT_COMBAT))),
			"heal": maxi(0, int(o.get("heal", ROOM_WEIGHT_HEAL))),
			"lore": maxi(0, int(o.get("lore", ROOM_WEIGHT_LORE))),
			"treasure": maxi(0, int(o.get("treasure", ROOM_WEIGHT_TREASURE))),
			"trap": maxi(0, int(o.get("trap", ROOM_WEIGHT_TRAP))),
			## 上書きが 0 のダンジョン（イベントDG等）は 0 のまま維持。
			"elite": maxi(0, int(round(float(elite_base) * elite_mult))),
		}
	else:
		var lore_w: int = _resolve_lore_room_weight(dungeon)
		var combat_w: int = clampi(ROOM_WEIGHT_COMBAT - (lore_w - ROOM_WEIGHT_LORE), 35, 70)
		var elite_w: int = maxi(1, int(round(float(ROOM_WEIGHT_ELITE) * elite_mult)))
		weights = {
			"combat": combat_w,
			"heal": ROOM_WEIGHT_HEAL,
			"lore": lore_w,
			"treasure": ROOM_WEIGHT_TREASURE,
			"trap": ROOM_WEIGHT_TRAP,
			"elite": elite_w,
		}
	if _early_normal_elites_disabled():
		weights["elite"] = 0
	return weights

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
	r -= int(weights["trap"])
	if int(weights["elite"]) > 0 and r < int(weights["elite"]):
		return Enums.RoomType.ELITE
	return Enums.RoomType.COMBAT

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


func peek_next_room_type() -> int:
	var next_i: int = current_room_index + 1
	if next_i < 0 or next_i >= room_sequence.size():
		return -1
	return int(room_sequence[next_i])


func is_next_room_combat() -> bool:
	var rt: int = peek_next_room_type()
	return rt in [
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
	## 深層はチャンク末でも結果画面にせず、advance_room で延長する（P3-DG-ABYSS-001）。
	if _is_abyss_run():
		return false
	return is_on_last_floor()

func accumulate_rewards(exp: int, gold: int) -> int:
	## ボーナス適用後の EXP 量を返す（生存者への個別積立用）。
	if exp > 0:
		exp = _AffixStatCalculator.apply_exp_bonus(exp)
		var exp_bless: float = floor_blessing_mult_for("exp")
		if exp_bless > 1.0:
			exp = maxi(1, int(round(float(exp) * exp_bless)))
	run_exp_reward += exp
	if gold > 0:
		gold = _AffixStatCalculator.apply_gold_bonus(gold)
		# 探索方針（素材優先）gold +15%（P3-D098）
		if GameState.get_exploration_policy() == "material":
			gold = int(round(float(gold) * 1.15))
		var gold_bless: float = floor_blessing_mult_for("gold")
		if gold_bless > 1.0:
			gold = maxi(1, int(round(float(gold) * gold_bless)))
	run_gold_reward += gold
	return exp


## 撃破時点の生存メンバーへ同額を積む（分割しない＝従来の全員同額付与と同じ単位）。
func accumulate_exp_for_members(exp: int, member_ids: Array) -> void:
	if exp <= 0:
		return
	for raw_id in member_ids:
		var mid: String = str(raw_id).strip_edges()
		if mid.is_empty():
			continue
		run_exp_by_member[mid] = int(run_exp_by_member.get(mid, 0)) + exp


func get_member_run_exp(member_id: String) -> int:
	return int(run_exp_by_member.get(member_id, 0))


## CLEAR 時のみ呼ぶ。ラン中獲得 EXP の CLEAR_EXP_BONUS_RATIO を加算し、表示用ボーナス量を返す。
func apply_clear_exp_bonus() -> int:
	if run_exp_reward <= 0:
		return 0
	var bonus: int = int(round(float(run_exp_reward) * _BalanceConfig.CLEAR_EXP_BONUS_RATIO))
	if bonus <= 0:
		return 0
	run_exp_reward += bonus
	for mid in run_exp_by_member.keys():
		var cur: int = int(run_exp_by_member[mid])
		if cur <= 0:
			continue
		var member_bonus: int = int(round(float(cur) * _BalanceConfig.CLEAR_EXP_BONUS_RATIO))
		if member_bonus > 0:
			run_exp_by_member[mid] = cur + member_bonus
	return bonus


func get_enemy_level() -> int:
	## 深層は表示階の絶対Lv（P3-DG-ABYSS-LV-001）。Biome基準＋Hard/NMボーナスは使わない。
	if _is_abyss_run():
		const _AbyssDungeonConfig := preload("res://scripts/dungeon/AbyssDungeonConfig.gd")
		return (
			_AbyssDungeonConfig.enemy_level_for_floor(get_display_floor_current())
			+ EventSystem.get_enemy_level_bonus()
		)
	var base: int = 1
	if current_stage_data != null:
		base = maxi(1, int(current_stage_data.enemy_level))
	elif current_dungeon_data != null:
		base = maxi(1, int(current_dungeon_data.enemy_level))
	var tier_bonus: int = _DungeonTierConfig.enemy_level_bonus(GameState.current_dungeon_tier)
	return base + tier_bonus + EventSystem.get_enemy_level_bonus()

func get_tier_rarity_weight(base_weight: int) -> int:
	var t: int = clampi(GameState.current_dungeon_tier, 0, _DungeonTierConfig.RARITY_WEIGHT_MULT.size() - 1)
	var mult: float = float(_DungeonTierConfig.RARITY_WEIGHT_MULT[t])
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
	return _EnemyTierVariantConfig.apply_for_current_tier(
		_pick_enemy_from_pool_entries(pool)
	)

## COMBAT 雑魚: `spawn_weights` × `codex_danger` で tier 抽選 → tier 内は `spawn_weight_mult`（P3-ENEMY-001 / P3-BAL-ROCK-BISON-SPAWN-001）。
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
		return _EnemyTierVariantConfig.apply_for_current_tier(
			_pick_enemy_from_pool_entries(pool)
		)
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	for entry in tier_entries:
		cumulative += int(entry["weight"])
		if roll < cumulative:
			return _EnemyTierVariantConfig.apply_for_current_tier(
				_pick_enemy_data_weighted(entry["enemies"] as Array)
			)
	var fallback_enemies: Array = tier_entries[tier_entries.size() - 1]["enemies"]
	return _EnemyTierVariantConfig.apply_for_current_tier(
		_pick_enemy_data_weighted(fallback_enemies)
	)


## pool の id 列から EnemyData を集め、`spawn_weight_mult` で1体選ぶ。
func _pick_enemy_from_pool_entries(pool: Array) -> Resource:
	var enemies: Array = []
	for raw_id in pool:
		var enemy_data: Resource = DataRegistry.get_enemy_data(str(raw_id))
		if enemy_data != null:
			enemies.append(enemy_data)
	return _pick_enemy_data_weighted(enemies)


## 帯内／pool 内の重み抽選。`spawn_weight_mult`（既定1.0）。0以下は除外。
func _pick_enemy_data_weighted(enemies: Array) -> Resource:
	if enemies.is_empty():
		return null
	var total: float = 0.0
	var weights: Array[float] = []
	for ed in enemies:
		var w: float = 1.0
		if ed != null:
			w = maxf(0.0, float(ed.spawn_weight_mult))
		weights.append(w)
		total += w
	if total <= 0.0:
		return enemies[randi() % enemies.size()] as Resource
	var roll: float = randf() * total
	var acc: float = 0.0
	for i in enemies.size():
		acc += weights[i]
		if roll <= acc:
			return enemies[i] as Resource
	return enemies[enemies.size() - 1] as Resource

func pick_elite_enemy_data() -> Resource:
	if current_dungeon_data == null:
		return null
	var pool: Array = current_dungeon_data.elite_pool
	if pool.is_empty():
		pool = current_dungeon_data.enemy_pool
	if pool.is_empty():
		return null
	return _EnemyTierVariantConfig.apply_for_current_tier(
		_pick_enemy_from_pool_entries(pool)
	)

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
	return _EnemyTierVariantConfig.apply_for_current_tier(DataRegistry.get_enemy_data(boss_id))

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
	## 同種／混成の追加枠候補。護衛リーダー（escorts_minions）は含めない。
	return _swarm_pool_enemies(false)


func _swarm_minion_enemies() -> Array[Resource]:
	## 護衛付きリーダーが従える雑魚候補。
	return _swarm_pool_enemies(false)


## ELITE 部屋: 章雑魚を 1〜2 体追加（プール空・キャップ超過なら何もしない）。
func _append_elite_escorts(group: Array[Resource]) -> void:
	var minions: Array[Resource] = _swarm_minion_enemies()
	if minions.is_empty():
		return
	var cap: int = _DungeonTierConfig.swarm_size_cap()
	var room: int = maxi(0, cap - group.size())
	if room <= 0:
		return
	var lo: int = mini(BalanceConfig.ELITE_ESCORT_MIN, room)
	var hi: int = mini(BalanceConfig.ELITE_ESCORT_MAX, room)
	if hi < lo:
		return
	var n: int = randi_range(lo, hi)
	for _i in n:
		group.append(minions[randi() % minions.size()])


func _swarm_pool_enemies(include_escorts: bool) -> Array[Resource]:
	var out: Array[Resource] = []
	if current_dungeon_data == null:
		return out
	var seen: Dictionary = {}
	for raw_id in current_dungeon_data.enemy_pool:
		var ed: Resource = DataRegistry.get_enemy_data(str(raw_id))
		if ed == null or not bool(ed.can_swarm):
			continue
		if not include_escorts and bool(ed.escorts_minions):
			continue
		if seen.has(ed.id):
			continue
		seen[ed.id] = true
		out.append(_EnemyTierVariantConfig.apply_for_current_tier(ed))
	return out

# 戦闘の敵編成を返す（P3-D082 + P3-D110 混成 + P3-WANDER-001 放浪差し込み + P3-BAL-SWARM-001 護衛）。
# BOSS は常に単体。ELITE は本体＋章雑魚1〜2（P3-BAL-ELITE-BOSS-PRESSURE-001）。COMBAT は放浪→群れ。
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
	if current_room_type == Enums.RoomType.ELITE:
		_append_elite_escorts(group)
		return group
	if current_room_type != Enums.RoomType.COMBAT:
		return group
	var forced_swarm: bool = (
		current_dungeon_data != null and float(current_dungeon_data.forced_swarm_chance) >= 0.0
	)
	var escorts: bool = bool(base.escorts_minions)
	if not bool(base.can_swarm) and not forced_swarm and not escorts:
		return group
	var swarm_chance: float = SWARM_CHANCE
	if forced_swarm:
		swarm_chance = float(current_dungeon_data.forced_swarm_chance)
	# 探索方針（安全優先）群れ出現率を半減（P3-D098）
	elif GameState.get_exploration_policy() == "safe":
		swarm_chance *= 0.5
	if not forced_swarm:
		swarm_chance *= _early_stage_swarm_chance_mult()
	swarm_chance *= _DungeonTierConfig.swarm_chance_mult(GameState.current_dungeon_tier)
	swarm_chance = minf(0.95, swarm_chance * EventSystem.get_swarm_chance_mult())
	if randf() >= swarm_chance:
		return group
	## 敵ごとの swarm_min を尊重（1許可）。イベント forced_swarm は従来どおり下限2。
	var lo: int = maxi(1, int(base.swarm_min))
	var hi: int = maxi(lo, int(base.swarm_max))
	if forced_swarm:
		lo = maxi(2, int(current_dungeon_data.forced_swarm_min))
		hi = maxi(lo, int(current_dungeon_data.forced_swarm_max))
	var size_bonus: int = _DungeonTierConfig.swarm_size_bonus(GameState.current_dungeon_tier)
	hi = mini(_DungeonTierConfig.swarm_size_cap(), hi + size_bonus)
	## モーンゲート 1-1〜1-3 ノーマル: 群れ最高2体（forced_swarm イベントは対象外）。
	if not forced_swarm:
		var early_cap: int = _early_normal_swarm_size_cap()
		if early_cap > 0:
			hi = mini(hi, early_cap)
	lo = mini(lo, hi)
	var size: int = randi_range(lo, hi)
	var capable: Array[Resource] = _swarm_capable_enemies()
	if forced_swarm and capable.is_empty():
		capable.append(base)
	var minions: Array[Resource] = _swarm_minion_enemies()
	## 護衛リーダー: 追加枠は常に雑魚。雑魚プールが空なら単体のまま。
	if escorts:
		if minions.is_empty():
			return group
		for _i in (size - 1):
			group.append(minions[randi() % minions.size()])
		return group
	var mixed_chance: float = _DungeonTierConfig.swarm_mixed_chance(GameState.current_dungeon_tier)
	var use_mixed: bool = capable.size() >= 2 and randf() < mixed_chance
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
	if current_dungeon_data != null and bool(current_dungeon_data.disable_wandering):
		return null
	## ラン計画済みならそれを使う（直前フロア予兆と一致させる）。未計画はライブ抽選。
	var wander_id: String = ""
	if _wander_plan_ready:
		wander_id = str(_planned_wander_by_room.get(current_room_index, ""))
	else:
		## P3-WANDER-003: 全ダンジョン共通。出現率は周回帯（N/H/NM）で上昇。
		## 1-1〜1-3 は影狩りのみ除外。
		wander_id = _WanderingEnemyConfig.try_roll_wandering_id(
			rng, GameState.current_dungeon_tier, _shadow_stalker_allowed_on_current_stage()
		)
	if wander_id.is_empty():
		return null
	return _EnemyTierVariantConfig.apply_for_current_tier(DataRegistry.get_enemy_data(wander_id))

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
	# cleared のみの進捗（セーブ／デバッグ解放）でも discovery 欠落で落ちないよう補完する
	var prog: Dictionary = GameState.dungeon_progress.get(did, {})
	var discovery: float = float(prog.get("discovery", 0.0))
	discovery = minf(1.0, discovery + DISCOVERY_PER_ROOM + bonus)
	prog["discovery"] = discovery
	if not prog.has("hidden_room"):
		prog["hidden_room"] = false
	if not prog.has("hidden_boss"):
		prog["hidden_boss"] = false
	var unlocks: Dictionary = current_dungeon_data.discovery_unlocks
	if unlocks.has("hidden_room") and discovery >= float(unlocks["hidden_room"]):
		prog["hidden_room"] = true
	if unlocks.has("hidden_boss") and discovery >= float(unlocks["hidden_boss"]):
		prog["hidden_boss"] = true
	GameState.dungeon_progress[did] = prog

func generate_treasure_loot() -> Dictionary:
	accumulate_rewards(0, TREASURE_GOLD)
	var accessory_id: String = ""
	var acc_chance: float = TREASURE_ACCESSORY_CHANCE * floor_blessing_mult_for("equip")
	if randf() < acc_chance:
		_generate_accessory_loot()
		accessory_id = last_accessory_dropped
	var weapon_id: String = ""
	var wpn_chance: float = TREASURE_WEAPON_CHANCE * floor_blessing_mult_for("equip")
	if randf() < wpn_chance:
		weapon_id = _pick_weighted_weapon(null)
		if not weapon_id.is_empty():
			_spawn_weapon(weapon_id)
	return {"gold": TREASURE_GOLD, "accessory_id": accessory_id, "weapon_id": weapon_id}

func generate_treasure_loot_failure() -> Dictionary:
	var gold: int = maxi(1, int(round(float(TREASURE_GOLD) * 0.5)))
	accumulate_rewards(0, gold)
	return {"gold": gold, "accessory_id": ""}

func generate_accessory_loot() -> String:
	last_accessory_dropped = ""
	_generate_accessory_loot()
	return last_accessory_dropped

func apply_elite_bonus_loot() -> Dictionary:
	var bonus: Dictionary = {"armor_id": "", "accessory_id": "", "material_id": "", "material_amount": 0}
	if randf() < ELITE_ARMOR_CHANCE:
		_generate_armor_loot()
		bonus["armor_id"] = last_armor_dropped
	if randf() < ELITE_ACCESSORY_CHANCE:
		_generate_accessory_loot()
		bonus["accessory_id"] = last_accessory_dropped
	var material_chance: float = ELITE_MATERIAL_CHANCE
	# 探索方針（素材優先）ELITE 素材ドロップ率↑（P3-D098 / P3-BAL-ECO-001）
	if GameState.get_exploration_policy() == "material":
		material_chance = 0.35
	if randf() < material_chance:
		var amount: int = EventSystem.get_elite_material_amount(1)
		bonus["material_id"] = EquipmentEnhancer.RARE_ORE_ID
		bonus["material_amount"] = amount
		GameState.add_material(EquipmentEnhancer.RARE_ORE_ID, amount)
	return bonus

## ボス撃破で高品質遺跡の欠片を確定付与（P3-MAT-SUPPLY-001）。ハード以上は2個。
func apply_boss_material_loot() -> Dictionary:
	var amount: int = 1
	if GameState.current_dungeon_tier >= _DungeonTierConfig.TIER_HARD:
		amount = 2
	amount = EventSystem.get_elite_material_amount(amount)
	GameState.add_material(EquipmentEnhancer.LEGEND_ORE_ID, amount)
	var epic_bonus: Dictionary = {}
	if randf() < BOSS_EPIC_ORE_CHANCE:
		GameState.add_material(EquipmentEnhancer.EPIC_ORE_ID, 1)
		epic_bonus = {"material_id": EquipmentEnhancer.EPIC_ORE_ID, "amount": 1}
	return {
		"material_id": EquipmentEnhancer.LEGEND_ORE_ID,
		"amount": amount,
		"bonus_material_id": str(epic_bonus.get("material_id", "")),
		"bonus_material_amount": int(epic_bonus.get("amount", 0)),
	}

## x-5 初回ボス討伐のレジェンド防具・装飾を確定付与（P3-EQ-LEG-001 / P3-BAL-DROP-001）。
## ティア別初回（Normal / Hard / Nightmare それぞれ1回）。同一 ★ 装備。
func apply_boss_legendary_loot(stage: Resource) -> Dictionary:
	var bonus: Dictionary = {"armor_id": "", "accessory_id": ""}
	if stage == null or not bool(stage.has_boss_floor()):
		return bonus
	var tier: int = _DungeonTierConfig.clamp_tier(GameState.current_dungeon_tier)
	var stage_id: String = str(stage.id)
	if GameState.is_stage_cleared(stage_id, tier):
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

## ボス再クリア時の神話ドロップ（P3-EQ-MYTHIC-001）。通常レア抽選外。
func apply_boss_mythic_loot(stage: Resource) -> Dictionary:
	var bonus: Dictionary = {"category": "", "id": ""}
	var rolled: Dictionary = MythicLoot.roll_for_boss_reclear(stage)
	if rolled.is_empty():
		return bonus
	var category: String = str(rolled.get("category", ""))
	var item_id: String = str(rolled.get("id", ""))
	if category == "weapon":
		_spawn_weapon(item_id)
	elif category == "armor":
		_spawn_armor(item_id)
	elif category == "accessory":
		_spawn_accessory(item_id)
	else:
		return bonus
	bonus["category"] = category
	bonus["id"] = item_id
	return bonus

## 降臨イベント専用（P3-DG-EVENT-SET-001）。stage 無し DG のボス撃破で呼ぶ。
func apply_event_exclusive_boss_loot() -> Dictionary:
	var empty: Dictionary = {"weapon_id": "", "armor_id": "", "accessory_id": "", "relic_id": ""}
	if current_dungeon_data == null:
		return empty
	var dungeon_id: String = str(current_dungeon_data.id)
	if not _EventExclusiveRewards.is_event_dungeon(dungeon_id):
		return empty
	var granted: Dictionary = _EventExclusiveRewards.apply_boss_loot(
		dungeon_id, GameState.current_dungeon_tier
	)
	var weapon_id: String = str(granted.get("weapon_id", ""))
	var armor_id: String = str(granted.get("armor_id", ""))
	var accessory_id: String = str(granted.get("accessory_id", ""))
	if not weapon_id.is_empty():
		last_weapon_dropped = weapon_id
	if not armor_id.is_empty():
		last_armor_dropped = armor_id
	if not accessory_id.is_empty():
		last_accessory_dropped = accessory_id
	return granted

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

# レア度別ドロップ重み（レアほど低確率＝レア度を体感に反映）。
## P3-EQ-LEG-DROP-001: LEGENDARY 相対を約1/3へ（他帯×3）。雑魚含む全撃破で抽選可は据置。
const RARITY_DROP_WEIGHT: Dictionary = {
	Enums.Rarity.COMMON: 120,
	Enums.Rarity.RARE: 45,
	Enums.Rarity.EPIC: 15,
	Enums.Rarity.LEGENDARY: 1,
}

# P3-D074: 武器はラン終了一括ではなく撃破時に直ドロップ。ここでは防具/装飾のみ。
func generate_run_loot() -> void:
	## 降臨セットは Result 表示用に保持（ラン終了抽選で潰さない）。
	var keep_weapon: String = last_weapon_dropped if _EventExclusiveRewards.is_event_exclusive_weapon(last_weapon_dropped) else ""
	var keep_armor: String = last_armor_dropped if _EventExclusiveRewards.is_event_exclusive_armor(last_armor_dropped) else ""
	var keep_accessory: String = last_accessory_dropped if _EventExclusiveRewards.is_event_exclusive_accessory(last_accessory_dropped) else ""
	last_armor_dropped = ""
	last_accessory_dropped = ""
	if randf() < RUN_ARMOR_DROP_CHANCE:
		_generate_armor_loot()
	if randf() < RUN_ACCESSORY_DROP_CHANCE:
		_generate_accessory_loot()
	if not keep_weapon.is_empty():
		last_weapon_dropped = keep_weapon
	if not keep_armor.is_empty():
		last_armor_dropped = keep_armor
	if not keep_accessory.is_empty():
		last_accessory_dropped = keep_accessory

# P3-D074 / P3-WANDER-002: 撃破時装備ドロップ。
# 戻り値: {category, id}。空 Dictionary = なし。
# equip_category_weights 非空 → 武器/防具/装飾。それ以外は従来どおり武器のみ。
func roll_kill_equip_drop(room_type: int, enemy_data: Resource = null) -> Dictionary:
	if enemy_data != null and not enemy_data.equip_category_weights.is_empty():
		return _roll_multi_category_equip_drop(enemy_data)
	var weapon_id: String = roll_kill_weapon_drop(room_type, enemy_data)
	if weapon_id.is_empty():
		return {}
	return {"category": "weapon", "id": weapon_id}


func _roll_multi_category_equip_drop(enemy_data: Resource) -> Dictionary:
	var chance: float = minf(
		1.0,
		float(enemy_data.weapon_drop_chance)
		* EventSystem.get_modifier_mult(EventSystem.MOD_WEAPON_DROP)
		* _EvolutionTraits.party_weapon_drop_mult()
		* floor_blessing_mult_for("equip")
	)
	if chance <= 0.0 or randf() > chance:
		return {}
	## レイヴン／影狩り: 神話は通常レア抽選外の別枠（P3-WANDER-002 / P3-WANDER-004）
	if _WanderingEnemyConfig.grants_legendary_equip_pool(enemy_data):
		var mythic: Dictionary = _try_wander_mythic_drop(enemy_data)
		if not mythic.is_empty():
			return mythic
	var category: String = _pick_equip_category(enemy_data.equip_category_weights)
	match category:
		"armor":
			var armor_id: String = _pick_kill_armor_id(enemy_data)
			if armor_id.is_empty():
				return {}
			_spawn_armor(armor_id)
			return {"category": "armor", "id": armor_id}
		"accessory":
			var accessory_id: String = _pick_kill_accessory_id(enemy_data)
			if accessory_id.is_empty():
				return {}
			_spawn_accessory(accessory_id)
			return {"category": "accessory", "id": accessory_id}
		_:
			var weapon_id: String = _pick_weighted_weapon(enemy_data)
			if weapon_id.is_empty():
				return {}
			_spawn_weapon(weapon_id)
			return {"category": "weapon", "id": weapon_id}


func _try_crown_raven_mythic_drop() -> Dictionary:
	## 互換エイリアス（旧テスト／呼び出し）。
	return _try_wander_mythic_drop(DataRegistry.get_enemy_data(_WanderingEnemyConfig.ID_CROWN_RAVEN))


func _try_wander_mythic_drop(enemy_data: Resource) -> Dictionary:
	var chance: float = _WanderingEnemyConfig.mythic_chance_for(enemy_data)
	if chance <= 0.0 or randf() > chance:
		return {}
	var candidates: Array = MythicLoot.unowned_pool()
	if candidates.is_empty():
		candidates = MythicLoot.POOL.duplicate()
	if candidates.is_empty():
		return {}
	var picked: Dictionary = (candidates[randi() % candidates.size()] as Dictionary).duplicate()
	var category: String = str(picked.get("category", ""))
	var item_id: String = str(picked.get("id", ""))
	if item_id.is_empty():
		return {}
	match category:
		"weapon":
			_spawn_weapon(item_id)
		"armor":
			_spawn_armor(item_id)
		"accessory":
			_spawn_accessory(item_id)
		_:
			return {}
	return {"category": category, "id": item_id, "mythic": true}


func _pick_equip_category(weights: Dictionary) -> String:
	var total: int = 0
	for key: Variant in weights.keys():
		total += maxi(0, int(weights[key]))
	if total <= 0:
		return "weapon"
	var roll: int = randi() % total
	var acc: int = 0
	for key: Variant in weights.keys():
		acc += maxi(0, int(weights[key]))
		if roll < acc:
			return str(key)
	return "weapon"


func _pick_kill_armor_id(enemy_data: Resource) -> String:
	var pool: Array = []
	if current_dungeon_data != null and not current_dungeon_data.armor_pool.is_empty():
		pool = current_dungeon_data.armor_pool.duplicate()
	else:
		pool = ["leather_armor", "bone_armor"]
	pool = _augment_pool_with_legendaries(pool, "armor", enemy_data)
	return _pick_rarity_weighted(pool, "armor", enemy_data)


func _pick_kill_accessory_id(enemy_data: Resource) -> String:
	var pool: Array = []
	if current_dungeon_data != null and not current_dungeon_data.accessory_pool.is_empty():
		pool = current_dungeon_data.accessory_pool.duplicate()
	else:
		pool = ["silver_ring"]
	pool = _augment_pool_with_legendaries(pool, "accessory", enemy_data)
	return _pick_rarity_weighted(pool, "accessory", enemy_data)


## レイヴン／影狩り: ダンジョンプールに伝説が無くても ★3 が当たるよう候補を足す（神話は別枠）。
func _augment_pool_with_legendaries(pool: Array, category: String, enemy_data: Resource) -> Array:
	if not _WanderingEnemyConfig.grants_legendary_equip_pool(enemy_data):
		return pool
	var out: Array = pool.duplicate()
	for item_id: String in _all_legendary_ids(category):
		if item_id.is_empty() or item_id in out:
			continue
		out.append(item_id)
	return out


func _all_legendary_ids(category: String) -> Array[String]:
	var out: Array[String] = []
	var all: Array = []
	match category:
		"weapon":
			all = DataRegistry.get_all_weapon_data()
		"armor":
			all = DataRegistry.get_all_armor_data()
		"accessory":
			all = DataRegistry.get_all_accessory_data()
		_:
			return out
	for data: Resource in all:
		if data == null:
			continue
		if int(data.rarity) != Enums.Rarity.LEGENDARY:
			continue
		var item_id: String = ""
		match category:
			"weapon":
				item_id = str(data.id)
			"armor":
				item_id = str(data.armor_id)
			"accessory":
				item_id = str(data.id)
		if item_id.is_empty():
			continue
		## 神話はレア度抽選に載せない（別枠）
		if MythicLoot.is_mythic_id(item_id):
			continue
		## 灰冠の九は封蔵限定（Decision 28）。ダンジョンドロップに載せない。
		if item_id.begins_with("kaiwan_"):
			continue
		if category == "weapon" and _AbyssLegendaryWeapons.is_abyss_legendary_id(item_id):
			continue
		if category == "weapon" and _EventExclusiveRewards.is_event_exclusive_weapon(item_id):
			continue
		if category == "armor" and _EventExclusiveRewards.is_event_exclusive_armor(item_id):
			continue
		if category == "accessory" and _EventExclusiveRewards.is_event_exclusive_accessory(item_id):
			continue
		## SET レアは通常レジェンド抽選に載せない
		if int(data.rarity) == Enums.Rarity.SET:
			continue
		out.append(item_id)
	return out


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
	var bless: float = floor_blessing_mult_for("equip")
	if enemy_data != null and float(enemy_data.weapon_drop_chance) >= 0.0:
		return minf(
			1.0,
			float(enemy_data.weapon_drop_chance)
			* EventSystem.get_modifier_mult(EventSystem.MOD_WEAPON_DROP)
			* _EvolutionTraits.party_weapon_drop_mult()
			* bless
		)
	var chance: float = COMBAT_WEAPON_DROP_CHANCE
	if room_type == Enums.RoomType.BOSS:
		chance = BOSS_WEAPON_DROP_CHANCE
	elif room_type == Enums.RoomType.ELITE:
		chance = ELITE_WEAPON_DROP_CHANCE
	return minf(
		1.0,
		chance
		* EventSystem.get_modifier_mult(EventSystem.MOD_WEAPON_DROP)
		* _EvolutionTraits.party_weapon_drop_mult()
		* bless
	)

# P3-D093: 撃破時の遺物ドロップ（解放型）。未所持の遺物から1つ解放する。
const RELIC_DROP_CHANCE_BOSS: float = 0.10
const RELIC_DROP_CHANCE_ELITE: float = 0.05
const RELIC_DROP_POLICY_BONUS: float = 0.05

func roll_kill_relic_drop(room_type: int) -> String:
	var pool: Array = GameState.unowned_relic_ids()
	## 降臨専用レリックは汎用抽選から除外（専用ボス付与のみ）。
	var filtered: Array = []
	for rid in pool:
		if not _EventExclusiveRewards.is_event_exclusive_relic(str(rid)):
			filtered.append(rid)
	pool = filtered
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
	var pool: Array = _augment_pool_with_legendaries(_active_weapon_pool(), "weapon", enemy_data)
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
	## P3-EQ-DIABLO-001: Affix 抽選は apply_drop_stats → EquipmentRandomMods に統合済。
	if instance != null:
		instance.is_appraised = true
	return

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
	EquipmentEnhancer.assign_drop_equip_level(
		instance, current_stage_data, current_dungeon_data, get_enemy_level()
	)
	_auto_appraise(instance, _AffixRoller.CATEGORY_WEAPON, weapon_data.rarity)
	GameState.inventory.append(instance)
	last_weapon_dropped = weapon_id
	EventBus.weapon_obtained.emit(weapon_id)
	GameState.note_equipment_obtained(instance)
	GameState.mark_equipment_new(instance)
	GameState.record_last_run_equipment_drop(instance, "weapon")

func _generate_armor_loot() -> void:
	# ダンジョン別プール（P3-D154）。未設定は従来: 革(rarity0)70% / 骨(rarity1)30%
	if current_dungeon_data != null and not current_dungeon_data.armor_pool.is_empty():
		_spawn_armor(_pick_rarity_weighted(current_dungeon_data.armor_pool, "armor"))
		return
	var armor_id: String = "bone_armor" if randf() < 0.3 else "leather_armor"
	_spawn_armor(armor_id)

# プールからレア度重みで1件抽選（armor/accessory 共用）。enemy_data で放浪重み上書き可。
func _pick_rarity_weighted(pool: Array, category: String, enemy_data: Resource = null) -> String:
	var weights: Array[int] = []
	var total: int = 0
	for iid in pool:
		var data: Resource = null
		if category == "armor":
			data = DataRegistry.get_armor_data(str(iid))
		else:
			data = DataRegistry.get_accessory_data(str(iid))
		var r: int = 0 if data == null else int(data.rarity)
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
	EquipmentEnhancer.assign_drop_equip_level(
		instance, current_stage_data, current_dungeon_data, get_enemy_level()
	)
	_auto_appraise(instance, _AffixRoller.CATEGORY_ARMOR, armor_data.rarity)
	GameState.armor_inventory.append(instance)
	last_armor_dropped = armor_id
	GameState.note_equipment_obtained(instance)
	GameState.mark_equipment_new(instance)
	GameState.record_last_run_equipment_drop(instance, "armor")

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
	EquipmentEnhancer.assign_drop_equip_level(
		instance, current_stage_data, current_dungeon_data, get_enemy_level()
	)
	_auto_appraise(instance, _AffixRoller.CATEGORY_ACCESSORY, accessory_data.rarity)
	GameState.accessory_inventory.append(instance)
	last_accessory_dropped = accessory_id
	GameState.note_equipment_obtained(instance)
	GameState.mark_equipment_new(instance)
	GameState.record_last_run_equipment_drop(instance, "accessory")
