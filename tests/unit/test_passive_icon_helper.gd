extends GutTest

const _PassiveIconHelper = preload("res://scripts/ui/PassiveIconHelper.gd")


func test_battle_fervor_icon_loads() -> void:
	var icon: Control = _PassiveIconHelper.make_icon("battle_fervor")
	if not ResourceLoader.exists("res://assets/ui/passives/ICO_PASSIVE_BattleFervor.png"):
		pass_test("passive art not installed")
		return
	assert_not_null(icon)
	assert_true(icon is TextureRect)


func test_foresight_icon_loads() -> void:
	if not ResourceLoader.exists("res://assets/ui/passives/ICO_PASSIVE_Foresight.png"):
		pass_test("foresight art not installed")
		return
	assert_not_null(_PassiveIconHelper.make_icon("foresight"))


func test_unknown_passive_uses_fallback_icon() -> void:
	if not ResourceLoader.exists(_PassiveIconHelper.FALLBACK_PATH):
		pass_test("fallback passive art not installed")
		return
	assert_not_null(_PassiveIconHelper.make_icon("nonexistent_passive"))
