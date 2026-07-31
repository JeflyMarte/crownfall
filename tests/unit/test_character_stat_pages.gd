extends GutTest
## P3-UX-CHR-STAT-PAGES-001 — キャラカード StatsGrid 3ページ。

const _Pages := preload("res://scripts/roster/CharacterStatPages.gd")
const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	if Constants.STARTER_STORY_RECRUIT:
		GameState.select_starting_adventurer("adventurer_0")


func test_page_count_and_titles() -> void:
	assert_eq(_Pages.PAGE_COUNT, 3)
	assert_eq(_Pages.page_title(0), "基本")
	assert_eq(_Pages.page_title(1), "特殊")
	assert_eq(_Pages.page_title(2), "詳細")
	assert_eq(_Pages.clamp_page(-1), 0)
	assert_eq(_Pages.clamp_page(99), 2)


func test_basic_page_has_six_combat_rows() -> void:
	var basic: Dictionary = {
		"hp": 100, "attack": 20, "defense": 10,
		"speed": 1.0, "crit_rate": 0.05, "crit_damage": 1.5,
	}
	var rows: Array = _Pages.rows_for_page(null, _Pages.PAGE_BASIC, basic)
	assert_eq(rows.size(), 6)
	assert_eq(str((rows[0] as Dictionary).get("label", "")), "HP")
	assert_eq(str((rows[4] as Dictionary).get("label", "")), "会心率")


func test_special_and_detail_pages_same_row_count() -> void:
	var member: Resource = GameState.roster[0] if not GameState.roster.is_empty() else null
	assert_not_null(member)
	var special: Array = _Pages.rows_for_page(member, _Pages.PAGE_SPECIAL, {})
	var detail: Array = _Pages.rows_for_page(member, _Pages.PAGE_DETAIL, {})
	assert_eq(special.size(), 6)
	assert_eq(detail.size(), 6)
	assert_eq(str((special[0] as Dictionary).get("label", "")), "属性")
	assert_eq(str((special[3] as Dictionary).get("label", "")), "Gold獲得")
	assert_eq(str((detail[0] as Dictionary).get("label", "")), "素材獲得")
	assert_eq(str((detail[1] as Dictionary).get("label", "")), "状態付与")


func test_special_shows_weapon_element_when_equipped() -> void:
	var member: Resource = GameState.roster[0]
	assert_not_null(member)
	## 属性付き武器を仮装備。
	var wdata: Resource = null
	for data in DataRegistry.get_all_weapon_data():
		if data == null:
			continue
		if not str(data.element).is_empty():
			wdata = data
			break
	if wdata == null:
		pending("属性武器マスタが無い")
		return
	var inst: Resource = WeaponInstance.new()
	inst.weapon_id = str(wdata.id)
	inst.is_appraised = true
	_WeaponStatResolver.apply_drop_stats(inst, wdata)
	member.equipped_weapon = inst
	var snap: Dictionary = _Pages.summarize(member)
	assert_ne(str(snap.get("element_label", "なし")), "なし")
