extends GutTest

## 図鑑「実績」タブのオミット（P3-CODEX-ACHIEVE-OMIT）。


func test_codex_achieve_playable_flag_default_off() -> void:
	assert_false(Constants.CODEX_ACHIEVE_PLAYABLE, "βでは実績タブをオミット")


func test_playable_categories_omit_achieve_when_flag_off() -> void:
	var cats: Array[String] = CodexScene.playable_categories()
	assert_false(cats.has("achieve"), "フラグOFF時はカテゴリに実績を含めない")
	assert_true(cats.has("enemy"))
	assert_true(cats.has("guide"))
	assert_true(cats.has("lore"), "記録タブは残す")


func test_guide_survey_copy_omits_achieve_tab() -> void:
	var desc: String = ""
	for entry: Dictionary in GuideCatalog.get_entries():
		if str(entry.get("id", "")) == "SYS-G001":
			desc = str(entry.get("description", ""))
			break
	assert_false(desc.is_empty(), "調査室の条がある")
	assert_false(desc.contains("実績」タブ"), "手引きから実績タブ案内を撤去")
	assert_true(desc.contains("70"), "②解放条件は維持")
