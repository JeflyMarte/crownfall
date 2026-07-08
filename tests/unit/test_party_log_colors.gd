extends GutTest
## パーティ名ログ色の共通 SSOT。

const _PartyLogColors = preload("res://scripts/ui/PartyLogColors.gd")


func test_party_color_by_job() -> void:
	var member: Resource = GameState.roster[0]
	member.job_id = "ranger"
	assert_eq(_PartyLogColors.party_color(member), Color("#88C0D0"))


func test_wrap_bbcode_levelup_yellow() -> void:
	var bb: String = _PartyLogColors.wrap_bbcode("レベルアップ!", Color("#FFD700"))
	assert_true(bb.contains("[color="))
	assert_true(bb.contains("レベルアップ!"))
