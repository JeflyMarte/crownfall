extends GutTest

const _DungeonScene := preload("res://scripts/dungeon/DungeonScene.gd")


func test_party_formation_is_left_of_swarm_center() -> void:
	## 味方を左へ寄せたあとでも、前衛右は群れ中心より左にいること。
	var ratios: Array = _DungeonScene.FORMATION_SLOT_RATIOS
	assert_eq(ratios.size(), 5)
	var front_right: Vector2 = ratios[1]
	assert_lt(front_right.x, _DungeonScene.SWARM_CENTER_X_RATIO)
	## 旧値 (0.583, 0.72) より左下。
	assert_lt(front_right.x, 0.58)
	assert_gt(front_right.y, 0.72)
	## 後衛左が画面端に食い込みすぎない。
	assert_gt(float(ratios[2].x), 0.10)
	## 後衛右の足元が clamp 余裕内（COMBAT_Y_BIAS 加算後）。
	assert_lt(float(ratios[3].y) + _DungeonScene.COMBAT_Y_BIAS, 0.96)
