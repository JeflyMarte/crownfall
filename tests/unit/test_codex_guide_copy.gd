extends GutTest

## P3-CODEX-COPY-001 — 手引きのプレイヤー向け文言点検。

const _CodexRichText = preload("res://scripts/codex/CodexRichText.gd")

const FORBIDDEN_ASCII_TERMS: Array[String] = [
	"Element", "Affix", "Threat", "Biome", "Relic", "DoT", "tick",
	"on_hit", "equip_level", "power_multiplier", "cast_time",
	"prefix", "suffix", "melee", "ultimate_ready", "apply_status_chance",
	"Discovered", "Undiscovered",
]

const FORBIDDEN_JP_OMIT: Array[String] = [
	"鑑定",
]


func test_guide_entries_exist() -> void:
	var entries: Array = CatalogHelper.get_guide_entries()
	assert_gt(entries.size(), 20, "手引きエントリがあること")


func test_guide_has_no_dev_english_or_appraisal() -> void:
	for entry in CatalogHelper.get_guide_entries():
		var body: String = str(entry.get("description", ""))
		var title: String = str(entry.get("display_name", ""))
		var blob: String = "%s\n%s" % [title, body]
		for term in FORBIDDEN_ASCII_TERMS:
			assert_false(blob.find(term) >= 0, "%s に英語/内部語 '%s' が残っている" % [entry.get("id"), term])
		for term in FORBIDDEN_JP_OMIT:
			assert_false(blob.find(term) >= 0, "%s にオミット語 '%s' が残っている" % [entry.get("id"), term])


func test_guide_uses_current_material_names() -> void:
	var joined: String = ""
	for entry in CatalogHelper.get_guide_entries():
		joined += str(entry.get("description", ""))
	assert_true(joined.find("基礎鉱") >= 0)
	assert_true(joined.find("遺跡の結晶") >= 0)
	assert_true(joined.find("基礎鉱石") < 0)
	assert_true(joined.find("遺物の欠片") < 0)


func test_guide_mentions_equipment_not_codex_for_relics() -> void:
	var body: String = ""
	for entry in CatalogHelper.get_guide_entries():
		if str(entry.get("id")) == "COMBAT-G015":
			body = str(entry.get("description", ""))
			break
	assert_false(body.is_empty())
	assert_true(body.find("装備画面") >= 0)
	assert_true(body.find("図鑑で確認") < 0)


func test_codex_richtext_decorate_colors_sections() -> void:
	var out: String = _CodexRichText.decorate("【弱点】テストとモーンゲート")
	assert_true(out.find("[color=") >= 0)
	assert_true(out.find("モーンゲート") >= 0)
