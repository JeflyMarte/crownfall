extends GutTest

const _ChrIdlePortrait = preload("res://scripts/ui/ChrIdlePortrait.gd")
const _ChrIdlePortraitView = preload("res://scripts/ui/ChrIdlePortraitView.gd")

func test_swordsman_idle_frames_exist() -> void:
	var paths: PackedStringArray = _ChrIdlePortrait.idle_frame_paths("swordsman")
	assert_gt(paths.size(), 0, "swordsman idle frames")
	var tex: Texture2D = _ChrIdlePortrait.get_idle_texture("swordsman")
	assert_not_null(tex)

func test_unknown_job_has_no_idle() -> void:
	assert_eq(_ChrIdlePortrait.idle_frame_paths("not_a_job").size(), 0)
	assert_null(_ChrIdlePortrait.get_idle_texture("not_a_job"))


func test_idle_portrait_view_loads_swordsman() -> void:
	var view: Control = _ChrIdlePortraitView.new()
	add_child_autofree(view)
	view.set_portrait_size(128)
	view.set_from_entry({"member_id": "", "job_id": "swordsman"})
	var art: TextureRect = view.get_child(0) as TextureRect
	assert_not_null(art)
	assert_not_null(art.texture)
