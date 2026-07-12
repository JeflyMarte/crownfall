extends GutTest

func test_swordsman_idle_frames_exist() -> void:
	var paths: PackedStringArray = ChrIdlePortrait.idle_frame_paths("swordsman")
	assert_gt(paths.size(), 0, "swordsman idle frames")
	var tex: Texture2D = ChrIdlePortrait.get_idle_texture("swordsman")
	assert_not_null(tex)

func test_unknown_job_has_no_idle() -> void:
	assert_eq(ChrIdlePortrait.idle_frame_paths("not_a_job").size(), 0)
	assert_null(ChrIdlePortrait.get_idle_texture("not_a_job"))
