extends GutTest
## 被弾 guard の半永久化防止（P3-BAL-GUARD-ONHIT-UPTIME-001）。


func test_bulwark_role_cd_and_skip_refresh() -> void:
	var d: Dictionary = CombatPassives.get_def("eq_bulwark_role")
	assert_false(d.is_empty())
	assert_eq(str(d.get("effect", "")), "taunt_and_guard")
	assert_almost_eq(float(d.get("cooldown", 0.0)), 12.0, 0.001)
	assert_true(bool(d.get("skip_if_status_active", false)))
	assert_eq(str(d.get("skip_status_id", "")), "guard")


func test_mirestaff_and_serdion_skip_refresh() -> void:
	var mist: Dictionary = CombatPassives.get_def("eq_abyss_mirestaff")
	assert_almost_eq(float(mist.get("cooldown", 0.0)), 14.0, 0.001)
	assert_true(bool(mist.get("skip_if_status_active", false)))
	var ward: Dictionary = CombatPassives.get_def("eq_serdion_ward")
	assert_almost_eq(float(ward.get("cooldown", 0.0)), 10.0, 0.001)
	assert_true(bool(ward.get("skip_if_status_active", false)))


func test_guard_status_is_half_damage_short() -> void:
	## 半減は維持。短持続＋再付与禁止で uptime を抑える。
	var guard: Resource = DataRegistry.get_status_effect("guard")
	assert_not_null(guard)
	assert_almost_eq(float(guard.incoming_damage_multiplier), 0.5, 0.001)
	assert_eq(int(guard.duration_ticks), 2)
