extends GutTest
## P3-SURVEY-REWARD-VAR-001 — DISPATCH 素材帯テーブル＋派遣先武器プール。

const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")
const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")


func test_material_weights_by_dungeon() -> void:
	var m: Dictionary = _SurveyConfig.material_weights_for("mourngate")
	assert_true(m.has("base_ore"))
	assert_true(m.has("relic_shard"))
	assert_false(m.has("elite_relic_shard"))
	var f: Dictionary = _SurveyConfig.material_weights_for("frostridge")
	assert_true(f.has("epic_ore"))
	assert_true(f.has("elite_relic_shard"))
	var unknown: Dictionary = _SurveyConfig.material_weights_for("not_a_dungeon")
	assert_eq(int(unknown.get("base_ore", 0)), 70)


func test_roll_material_id_respects_weights() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var counts: Dictionary = {}
	for _i in 200:
		var mid: String = _SurveyConfig.roll_material_id("mourngate", rng)
		counts[mid] = int(counts.get(mid, 0)) + 1
	assert_gt(int(counts.get("base_ore", 0)), int(counts.get("relic_shard", 0)))
	assert_eq(int(counts.get("ancient_bone", 0)), 0)


func test_pick_weapon_uses_target_dungeon_pool() -> void:
	## whisperwood プールに無い鉄剣（モーン）を引かないよう、レア0で森プールのみ。
	var seen_outside: bool = false
	var ww: Resource = DataRegistry.get_dungeon_data("whisperwood")
	assert_not_null(ww)
	var pool: Dictionary = {}
	for wid in ww.weapon_pool:
		pool[str(wid)] = true
	for _i in 40:
		var wid: String = _SurveySystem._pick_weapon_id(0, "whisperwood")
		if wid.is_empty():
			continue
		if not pool.has(wid):
			## フォールバック全武器になった場合はレア0が森に無い可能性 — 許容しつつ記録。
			seen_outside = true
			break
		assert_true(pool.has(wid), wid)
	## 少なくとも森プールから取れるレアがあること。
	var any_r0: bool = false
	for wid in ww.weapon_pool:
		var data: Resource = DataRegistry.get_weapon_data(str(wid))
		if data != null and int(data.rarity) == 0:
			any_r0 = true
			break
	assert_true(any_r0, "whisperwood should have rarity0 weapons")
	if seen_outside:
		fail_test("picked weapon outside whisperwood pool")


func test_roll_rewards_material_not_always_base_ore() -> void:
	var hits: Dictionary = {}
	for _i in 80:
		var r: Dictionary = _SurveySystem._roll_rewards(
			_SurveyConfig.PRESET_SHORT,
			false,
			"frostridge"
		)
		var mid: String = str(r.get("material_id", ""))
		hits[mid] = int(hits.get(mid, 0)) + 1
	assert_gt(hits.size(), 1, "frostridge should vary materials over rolls")
