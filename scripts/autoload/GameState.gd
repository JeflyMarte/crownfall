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
