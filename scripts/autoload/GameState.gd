extends Node

# 所持ゴールド（MVP: 鑑定費用のみ消費）
var gold: int = 0

# 編成中の冒険者リスト（Adventurer Resource × 3）
var party_members: Array = []

# 所持アイテムリスト（ItemInstance。未鑑定・鑑定済み混在）
var inventory: Array = []

# 現在選択中のダンジョンID
var current_dungeon_id: String = ""

# ダンジョン別の発見度・解放状態 { dungeon_id: { discovery: float, hidden_room: bool, hidden_boss: bool } }
var dungeon_progress: Dictionary = {}

# チュートリアル進行フラグ { flag_name: bool }
var tutorial_flags: Dictionary = {}

func _ready() -> void:
	_init_party()

func _init_party() -> void:
	var adventurer_class = load("res://scripts/domain/Adventurer.gd")
	var stats_class = load("res://scripts/domain/Stats.gd")

	var warrior = adventurer_class.new()
	warrior.id = "adventurer_0"
	warrior.display_name = "戦士"
	warrior.job_id = "warrior"
	warrior.base_stats = stats_class.new()

	var thief = adventurer_class.new()
	thief.id = "adventurer_1"
	thief.display_name = "盗賊"
	thief.job_id = "thief"
	thief.base_stats = stats_class.new()

	var mage = adventurer_class.new()
	mage.id = "adventurer_2"
	mage.display_name = "魔術師"
	mage.job_id = "mage"
	mage.base_stats = stats_class.new()

	party_members = [warrior, thief, mage]
