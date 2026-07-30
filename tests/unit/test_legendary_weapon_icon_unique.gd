extends GutTest

## レジェンド武器アイコンがテンプレ流用／同一バイトでないこと（案B）。

const PLAN_B_IDS: Array[String] = [
	"silvaria_oathblade",
	"volgrave_thunderblade",
	"eldion_frostbrand",
	"nereidas_tideblade",
	"consecrated_maul",
	"aegis_line_sword",
	"pulsekeen_edge",
	"shadowcord",
	"blightcord_bow",
]


func _weapon_icon_path(weapon_id: String) -> String:
	return str(IconPaths.ICON_MAP.get("weapon:%s" % weapon_id, ""))


func test_plan_b_icons_exist_and_unique() -> void:
	var seen: Dictionary = {}
	for weapon_id in PLAN_B_IDS:
		var path: String = _weapon_icon_path(weapon_id)
		assert_false(path.is_empty(), weapon_id)
		assert_true(FileAccess.file_exists(path), path)
		var md5: String = FileAccess.get_md5(path)
		assert_false(seen.has(md5), "duplicate icon bytes: %s vs %s" % [weapon_id, seen.get(md5, "")])
		seen[md5] = weapon_id


func test_all_legendary_weapon_icons_unique_bytes() -> void:
	## rarity=LEGENDARY 全本の PNG 中身が互いに異なること。
	var seen: Dictionary = {}
	for wd in DataRegistry.get_all_weapon_data():
		if wd == null or int(wd.rarity) != int(Enums.Rarity.LEGENDARY):
			continue
		var weapon_id: String = str(wd.id)
		var path: String = _weapon_icon_path(weapon_id)
		assert_true(FileAccess.file_exists(path), "%s missing %s" % [weapon_id, path])
		var md5: String = FileAccess.get_md5(path)
		assert_false(
			seen.has(md5),
			"legendary icon collision: %s vs %s (%s)" % [weapon_id, seen.get(md5, ""), path]
		)
		seen[md5] = weapon_id
	assert_gte(seen.size(), 30, "expected full legendary set")
