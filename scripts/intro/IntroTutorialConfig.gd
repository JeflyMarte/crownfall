extends RefCounted

## 導入 0-0 訓練坑（P3-INTRO-TUTORIAL-001）。Autoload にしない。

const DUNGEON_ID: String = "intro_training"
const STAGE_ID: String = "intro_0_0"
const FLAG_PENDING: String = "intro_tutorial_pending"
const FLAG_DONE: String = "intro_tutorial_done"
const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonScene.tscn"
const ART_BIOME_ID: String = "mourngate"

const ENEMY_COMBAT_1: String = "sepia_hound"
const ENEMY_COMBAT_2: String = "rune_roach"
const TRAIN_HP: int = 36
const TRAIN_ATK: int = 4
const TRAIN_DEF: int = 0
const TRAIN_ATK_SPEED: float = 0.75
const TRAIN_EXP: int = 4
const TRAIN_GOLD: int = 8
const TREASURE_GOLD: int = 50

const STEP_COMBAT: String = "combat"
const STEP_TREASURE: String = "treasure"
const STEP_CHOICE: String = "choice"
const STEP_COMBAT_2: String = "combat_2"
const STEP_DONE: String = "done"


static func is_done() -> bool:
	return bool(GameState.tutorial_flags.get(FLAG_DONE, false))


static func needs_run() -> bool:
	if is_done():
		return false
	return bool(GameState.tutorial_flags.get(FLAG_PENDING, false))


static func mark_pending() -> void:
	GameState.tutorial_flags[FLAG_PENDING] = true
	GameState.tutorial_flags[FLAG_DONE] = false


static func mark_done() -> void:
	GameState.tutorial_flags[FLAG_PENDING] = false
	GameState.tutorial_flags[FLAG_DONE] = true


static func begin_run() -> void:
	GameState.current_dungeon_id = DUNGEON_ID
	GameState.current_stage_id = STAGE_ID
	GameState.current_dungeon_tier = 0


static func is_stage_id(stage_id: String) -> bool:
	return stage_id == STAGE_ID


static func is_dungeon_id(dungeon_id: String) -> bool:
	return dungeon_id == DUNGEON_ID


static func is_run(controller: Node = null) -> bool:
	if GameState.current_stage_id == STAGE_ID or GameState.current_dungeon_id == DUNGEON_ID:
		return true
	if controller == null:
		return false
	var stage: Variant = controller.get("current_stage_data")
	if stage != null and str(stage.id) == STAGE_ID:
		return true
	var dungeon: Variant = controller.get("current_dungeon_data")
	if dungeon != null and str(dungeon.id) == DUNGEON_ID:
		return true
	return false


static func room_sequence() -> Array[int]:
	return [
		Enums.RoomType.COMBAT,
		Enums.RoomType.TREASURE,
		Enums.RoomType.COMBAT,
	]


static func enemy_id_for_room(room_index: int) -> String:
	if room_index <= 0:
		return ENEMY_COMBAT_1
	return ENEMY_COMBAT_2


static func enemy_group_for_room(room_index: int) -> Array[Resource]:
	var data: Resource = weaken_enemy(DataRegistry.get_enemy_data(enemy_id_for_room(room_index)))
	var group: Array[Resource] = []
	if data != null:
		group.append(data)
	return group


static func weaken_enemy(src: Resource) -> Resource:
	if src == null:
		return null
	var e: Resource = src.duplicate(true)
	e.max_hp = TRAIN_HP
	e.attack = TRAIN_ATK
	e.defense = TRAIN_DEF
	e.attack_speed = TRAIN_ATK_SPEED
	var empty_ids: Array[String] = []
	e.skill_ids = empty_ids
	e.basic_attack_skill_ids = empty_ids.duplicate()
	e.skill_use_chance = 0.0
	e.can_swarm = false
	e.lifesteal_ratio = 0.0
	e.trait_id = ""
	e.weapon_drop_chance = 0.0
	e.equip_category_weights = {}
	e.wander_flee_after_turns = 0
	e.exp_reward = TRAIN_EXP
	e.gold_reward = TRAIN_GOLD
	e.opening_companion_ids = empty_ids.duplicate()
	e.incoming_basic_mult = 1.0
	e.incoming_skill_mult = 1.0
	return e


static func page_for(step: String) -> Dictionary:
	match step:
		STEP_COMBAT:
			return {
				"title": "自動戦闘です",
				"body": (
					"隊長、このゲームの戦闘は[color=#9A5018][b]自動[/b][/color]です。\n\n"
					+ "隊員が自分で動きます。上のゲージが[color=#7A3E12][b]HP[/b][/color]。"
					+ "タップして操作する必要はありません。\n\n"
					+ "弱くて逃げない訓練用の相手です。しばらく見守ってください。"
				),
			}
		STEP_TREASURE:
			return {
				"title": "宝箱の部屋",
				"body": (
					"探索の途中で、[color=#9A5018][b]宝箱[/b][/color]の部屋に入ることがあります。\n\n"
					+ "開けて中身を受け取ります。本番では装備が出ることもあります。\n\n"
					+ "いまは訓練なので、[color=#7A3E12][b]少量のゴールド[/b][/color]だけです。"
				),
			}
		STEP_CHOICE:
			return {
				"title": "分かれ道",
				"body": (
					"戦闘のあとに[color=#9A5018][b]三択[/b][/color]が出ることがあります。\n\n"
					+ "戦力・回復・収穫など、次のフロアへの備えを一つ選んでください。\n\n"
					+ "選ばないと先に進めません。好きなものをタップして確定を。"
				),
			}
		STEP_COMBAT_2:
			return {
				"title": "もう一度、戦闘",
				"body": (
					"あとは同じです。自動で戦って、訓練を終えます。\n\n"
					+ "終わったら拠点へ戻ります。本調査の備えは、それからです。"
				),
			}
		STEP_DONE:
			return {
				"title": "訓練は以上です",
				"body": (
					"現場の感触、つかめましたか？\n\n"
					+ "拠点で備えを整えてください。"
					+ "ギルドから[color=#7A3E12][b]ジャック[/b][/color]も付けます。いきましょう！"
				),
			}
		_:
			return {"title": "", "body": ""}
