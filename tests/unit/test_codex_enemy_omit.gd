extends GutTest

## 図鑑敵タブ: 非プレイ／プール外モンスターのオミット（P3-CODEX-ENEMY-OMIT-001）。


func test_playable_enemy_set_excludes_pool_omitted() -> void:
	var playable: Dictionary = CatalogHelper.playable_enemy_id_set()
	assert_false(playable.has("bloom_serpent"), "WW プールオミット敵は図鑑対象外")
	assert_false(playable.has("polar_tricera"), "FR プールオミット敵は図鑑対象外")
	assert_false(playable.has("ice_tail_fox"), "置換済み・プール外は図鑑対象外")


func test_playable_enemy_set_excludes_apex_only_when_sub_omitted() -> void:
	if Constants.SUB_DUNGEONS_PLAYABLE:
		pass_test("SUB 有効時は apex 専用敵も掲載対象になりうる")
		return
	var playable: Dictionary = CatalogHelper.playable_enemy_id_set()
	## 征討専用ボス（イベント降臨の chronos_wave / valgard は event のため掲載対象）。
	for eid: String in [
		"skarpedion", "mycolga_ancient",
		"karna_smoke", "nereion_depths", "forgedormient", "albark",
	]:
		assert_false(playable.has(eid), "%s は征討専用のため図鑑からオミット" % eid)
	assert_true(playable.has("chronos_wave"), "時環降臨ボスは event のため図鑑対象")
	assert_true(playable.has("valgard"), "境界廊降臨ボスは event のため図鑑対象")


func test_enemy_entries_match_playable_set() -> void:
	var playable: Dictionary = CatalogHelper.playable_enemy_id_set()
	var entries: Array = CatalogHelper.get_enemy_entries()
	assert_gt(entries.size(), 20, "メイン等の敵は残る")
	var expected: int = 0
	for data in DataRegistry.get_all_enemy_data():
		if data != null and playable.has(str(data.id)):
			expected += 1
	assert_eq(entries.size(), expected, "図鑑行数＝EnemyData ∩ プレイ可能")
	for row: Dictionary in entries:
		var eid: String = str(row.get("id", ""))
		assert_true(playable.has(eid), "掲載敵はプレイ可能セットに含まれる: %s" % eid)
	assert_true(CatalogHelper.is_playable_codex_enemy("serdion"))
	assert_false(CatalogHelper.is_playable_codex_enemy("bloom_serpent"))
