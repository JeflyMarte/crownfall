extends GutTest

## P3-ENEMY-001 — 章別 spawn_weights × codex_danger 重み抽選。

const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")

const _D1_IDS: Array[String] = ["crown_eater_rat", "grave_bell_bat"]
const _D2_IDS: Array[String] = [
	"sepia_hound",
	"rune_roach",
	"crystal_hedgehog",
	"crystal_scorpion",
]
const _D3_IDS: Array[String] = ["skullface_mantis"]
const _WW_D2_IDS: Array[String] = ["moss_boar", "moss_shell", "bloom_serpent", "crown_beetle"]
const _WW_D3_IDS: Array[String] = ["spore_widow", "jyuzen_cicada", "mirror_shell"]

func _make_controller(stage_id: String) -> Node:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_stage(stage_id)
	return dc

func _danger_of(enemy_data: Resource) -> int:
	return int(enemy_data.codex_danger)

func _pick_many(dc: Node, count: int) -> Array[String]:
	var ids: Array[String] = []
	for _i in count:
		var enemy: Resource = dc.pick_enemy_data()
		assert_not_null(enemy, "pick_enemy_data should not return null")
		ids.append(str(enemy.id))
	return ids

func test_stage_1_1_excludes_d3() -> void:
	var dc: Node = _make_controller("mourngate_1_1")
	for enemy_id in _pick_many(dc, 200):
		assert_false(enemy_id in _D3_IDS, "1-1 は D3=0 のため D3 種は出ない")

func test_stage_1_5_excludes_d1() -> void:
	var dc: Node = _make_controller("mourngate_1_5")
	for enemy_id in _pick_many(dc, 200):
		assert_false(enemy_id in _D1_IDS, "1-5 は D1=0 のため D1 種は出ない")

func test_stage_1_1_d1_ratio_near_ssot() -> void:
	seed(12345)
	var dc: Node = _make_controller("mourngate_1_1")
	var d1_count: int = 0
	var d2_count: int = 0
	for enemy_id in _pick_many(dc, 2000):
		if enemy_id in _D1_IDS:
			d1_count += 1
		elif enemy_id in _D2_IDS:
			d2_count += 1
	var total: int = d1_count + d2_count
	assert_gt(total, 0)
	var d1_ratio: float = float(d1_count) / float(total)
	assert_true(d1_ratio > 0.52 and d1_ratio < 0.68, "1-1 D1 比率 ~60%% (got %.2f)" % d1_ratio)

func test_whisperwood_2_5_d2_ratio_near_ssot() -> void:
	seed(12345)
	var dc: Node = _make_controller("whisperwood_2_5")
	var d2_count: int = 0
	var d3_count: int = 0
	for enemy_id in _pick_many(dc, 2000):
		if enemy_id in _WW_D2_IDS:
			d2_count += 1
		elif enemy_id in _WW_D3_IDS:
			d3_count += 1
	var total: int = d2_count + d3_count
	assert_gt(total, 0)
	var d2_ratio: float = float(d2_count) / float(total)
	assert_true(d2_ratio > 0.05 and d2_ratio < 0.15, "2-5 D2 比率 ~10%% (got %.2f)" % d2_ratio)

func test_whisperwood_2_1_d2_ratio_near_ssot() -> void:
	seed(54321)
	var dc: Node = _make_controller("whisperwood_2_1")
	var d2_count: int = 0
	var d3_count: int = 0
	for enemy_id in _pick_many(dc, 2000):
		if enemy_id in _WW_D2_IDS:
			d2_count += 1
		elif enemy_id in _WW_D3_IDS:
			d3_count += 1
	var total: int = d2_count + d3_count
	assert_gt(total, 0)
	var d2_ratio: float = float(d2_count) / float(total)
	assert_true(d2_ratio > 0.62 and d2_ratio < 0.78, "2-1 D2 比率 ~70%% (got %.2f)" % d2_ratio)

func test_missing_danger_tier_is_renormalized() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	var pool: Array = dc.current_dungeon_data.enemy_pool
	var weights: Dictionary = {"1": 50, "2": 50, "5": 100}
	for _i in 100:
		var enemy: Resource = dc._pick_weighted_pool_enemy(pool, weights)
		assert_not_null(enemy)
		assert_true(str(enemy.id) in pool)
		assert_false(_danger_of(enemy) == 5, "プールに無い D5 tier は除外")

func test_legacy_dungeon_stays_uniform() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_dungeon("mourngate")
	var seen: Dictionary = {}
	for _i in 300:
		var enemy: Resource = dc.pick_enemy_data()
		seen[str(enemy.id)] = true
	assert_gte(seen.size(), 4, "単体 DG は pool 均等のまま")
