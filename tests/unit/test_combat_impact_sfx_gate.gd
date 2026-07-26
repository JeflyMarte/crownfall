extends GutTest
## 戦闘フロア入場前の幽霊 Hit／Heal SE 再発防止（CombatImpactSfxGate）。

const _Gate := preload("res://scripts/combat/CombatImpactSfxGate.gd")


func test_allow_only_when_ct_started() -> void:
	assert_true(_Gate.allow(true, true, false, false))
	assert_false(_Gate.allow(false, true, false, false), "入場〜出現遅延中は SE 禁止")
	assert_false(_Gate.allow(true, false, false, false), "戦闘外は SE 禁止")


func test_block_during_boss_or_elite_intro() -> void:
	assert_false(_Gate.allow(true, true, true, false), "ボス導入中は SE 禁止")
	assert_false(_Gate.allow(true, true, false, true), "エリート導入中は SE 禁止")


func test_trap_room_may_use_direct_hit_but_explore_must_not() -> void:
	## 仕様メモ: 罠部屋のみ combat_hit 直接再生可。探索罠は skip＋ゲート外。
	## Gate 自体は罠と無関係だが、入場時探索罠で Gate=false を前提にする。
	assert_false(_Gate.allow(false, true, false, false))
