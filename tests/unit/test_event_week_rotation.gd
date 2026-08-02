extends GutTest
## P3-EVT-FIELD-001 — 30分スロット野外速報。

const _WeekRotation = preload("res://scripts/event/EventWeekRotation.gd")
const _Schedule = preload("res://scripts/event/EventScheduleHelper.gd")


func _anchor_unix() -> int:
	return _Schedule.jst_day_start_unix(_WeekRotation.ANCHOR_DATE_JST)


func after_each() -> void:
	EventSystem.clear_debug_unix_for_tests()


func test_slot_length_is_30_minutes() -> void:
	assert_eq(_WeekRotation.SLOT_SECONDS, 30 * 60)


func test_none_has_highest_weight() -> void:
	var none_w: int = 0
	var max_other: int = 0
	for def: Dictionary in _WeekRotation.SLOT_DEFINITIONS:
		var w: int = int(def.get("weight", 0))
		if str(def.get("id", "")) == "none":
			none_w = w
		else:
			max_other = maxi(max_other, w)
	assert_gt(none_w, max_other)


func test_pool_includes_weather_duck_raven_none() -> void:
	var ids: Dictionary = {}
	for def: Dictionary in _WeekRotation.SLOT_DEFINITIONS:
		ids[str(def.get("id", ""))] = true
	for need: String in [
		"none",
		"weather_rain",
		"weather_night",
		"weather_fog",
		"weather_heat",
		"weather_snow",
		"wander_duck",
		"wander_raven",
	]:
		assert_true(ids.has(need), need)


func test_slot_copy_has_article_effect_and_memo() -> void:
	for def: Dictionary in _WeekRotation.SLOT_DEFINITIONS:
		var id: String = str(def.get("id", ""))
		assert_false(str(def.get("article", "")).strip_edges().is_empty(), "article %s" % id)
		assert_false(str(def.get("field_notes", "")).strip_edges().is_empty(), "field_notes %s" % id)
		assert_false(str(def.get("effect_summary", "")).strip_edges().is_empty(), "effect %s" % id)
		var pool: Variant = def.get("descriptions", [])
		assert_true(typeof(pool) == TYPE_ARRAY and (pool as Array).size() > 0, "memo pool %s" % id)
		for memo: Variant in pool as Array:
			assert_false(str(memo).strip_edges().is_empty(), "memo empty %s" % id)
		assert_true(str(def.get("effect_summary", "")).begins_with("・"), "bullet %s" % id)


func test_codex_slot_is_omitted_from_draw() -> void:
	var found: bool = false
	for def: Dictionary in _WeekRotation.SLOT_DEFINITIONS:
		if str(def.get("id", "")) != "codex":
			continue
		found = true
		assert_eq(int(def.get("weight", -1)), 0)
	assert_true(found, "codex def should remain for future restore")
	for slot: int in range(0, 256):
		var idx: int = _WeekRotation.definition_index_for_slot(slot)
		assert_ne(str(_WeekRotation.SLOT_DEFINITIONS[idx].get("id", "")), "codex")


func test_banner_desc_avoids_raw_multiplier_jargon() -> void:
	## バナーは世界観文。数値倍率は effect_summary 側。
	for def: Dictionary in _WeekRotation.SLOT_DEFINITIONS:
		var id: String = str(def.get("id", ""))
		var banner: String = str(def.get("banner_desc", ""))
		assert_false(banner.contains("×1."), "banner has mult %s: %s" % [id, banner])
		assert_false(banner.contains("出現率↑"), "banner rate jargon %s: %s" % [id, banner])
		assert_false(banner.contains("エリート素材"), "banner elite mat jargon %s" % id)
		assert_false(banner.contains("敵レベル"), "banner enemy lv jargon %s" % id)


func test_none_memo_pool_is_thick() -> void:
	for def: Dictionary in _WeekRotation.SLOT_DEFINITIONS:
		if str(def.get("id", "")) != "none":
			continue
		assert_gte((def.get("descriptions", []) as Array).size(), 12)
		return
	assert_true(false, "none def missing")


func test_nonoka_memo_pick_is_stable_and_varies() -> void:
	var none_def: Dictionary = {}
	for def: Dictionary in _WeekRotation.SLOT_DEFINITIONS:
		if str(def.get("id", "")) == "none":
			none_def = def
			break
	assert_false(none_def.is_empty())
	var a: String = _WeekRotation.pick_description(none_def, 10)
	var b: String = _WeekRotation.pick_description(none_def, 10)
	assert_eq(a, b)
	assert_false(a.strip_edges().is_empty())
	var seen: Dictionary = {}
	for slot: int in range(0, 64):
		seen[_WeekRotation.pick_description(none_def, slot)] = true
	assert_gte(seen.size(), 3, "same none should yield multiple memos across slots")


func test_build_active_event_copies_article() -> void:
	EventSystem.set_debug_unix_for_tests(_anchor_unix() + 60)
	var event: Resource = EventSystem.get_active_event()
	assert_not_null(event)
	assert_false(str(event.article).strip_edges().is_empty())
	assert_false(str(event.effect_summary).strip_edges().is_empty())


func test_slot_selection_is_stable() -> void:
	assert_eq(_WeekRotation.definition_index_for_slot(12), _WeekRotation.definition_index_for_slot(12))
	assert_eq(_WeekRotation.definition_index_for_slot(100), _WeekRotation.definition_index_for_slot(100))


func test_build_active_event_has_ima_tag() -> void:
	EventSystem.set_debug_unix_for_tests(_anchor_unix() + 60)
	var event: Resource = EventSystem.get_active_event()
	assert_not_null(event)
	assert_eq(str(event.tag_text), "ギルド情報誌")
	assert_true(EventSystem.is_event_running())


func test_forced_weather_when_weather_slot() -> void:
	var found_rain: bool = false
	for def: Dictionary in _WeekRotation.SLOT_DEFINITIONS:
		if str(def.get("id", "")) == "weather_rain":
			assert_eq(str(def.get("weather_id", "")), "rain")
			found_rain = true
	assert_true(found_rain)


func test_countdown_under_one_hour_uses_minutes() -> void:
	var text: String = _Schedule.format_countdown(25 * 60)
	assert_true(text.contains("分"), text)


func test_featured_biome_still_scopes_exp() -> void:
	var featured_slot: int = -1
	for slot: int in range(0, 2000):
		var idx: int = _WeekRotation.definition_index_for_slot(slot)
		if str(_WeekRotation.SLOT_DEFINITIONS[idx].get("modifier_type", "")) == "featured_biome":
			featured_slot = slot
			break
	assert_gte(featured_slot, 0)
	var unix: int = _anchor_unix() + featured_slot * _WeekRotation.SLOT_SECONDS + 10
	EventSystem.set_debug_unix_for_tests(unix)
	assert_eq(str(EventSystem.get_active_event().modifier_type), EventSystem.MOD_FEATURED_BIOME)
	var featured_id: String = EventSystem.get_featured_biome_id()
	GameState.current_dungeon_id = featured_id
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_EXP), 1.2)
	GameState.current_dungeon_id = "not_the_featured_biome_id"
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_EXP), 1.0)
