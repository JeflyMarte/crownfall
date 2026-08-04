extends GutTest

## balance_sim / -s 向け: ペット判定が Script 静的に依存しないこと。


func test_is_pet_combatant_uses_id_prefix() -> void:
	var pet: Resource = load("res://scripts/domain/Adventurer.gd").new()
	pet.id = "pet_jack"
	var human: Resource = load("res://scripts/domain/Adventurer.gd").new()
	human.id = "adventurer_0"
	GameState.party_members = [human]
	GameState.active_pet = pet
	assert_false(GameState.is_pet_combatant(0))
	assert_true(GameState.is_pet_combatant(1), "combatants 末尾のペット")
	GameState.active_pet = null
	GameState.party_members = []
