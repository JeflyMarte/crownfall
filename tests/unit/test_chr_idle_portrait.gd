extends GutTest

const _ChrIdlePortrait = preload("res://scripts/ui/ChrIdlePortrait.gd")
const _ChrIdlePortraitView = preload("res://scripts/ui/ChrIdlePortraitView.gd")

func test_helper_idle_folder_prefers_helper_id() -> void:
	# Adventurer stub: gacha helper id resolves to helper_* idle folder.
	var adv: Resource = Adventurer.new()
	adv.id = "gacha_helper_a"
	adv.job_id = "vanguard"
	adv.display_name = "ヴァルデン"
	assert_eq(_ChrIdlePortrait.folder_id_for_member(adv), "helper_a")
	var paths: PackedStringArray = _ChrIdlePortrait.idle_frame_paths("helper_a")
	assert_gt(paths.size(), 0, "helper_a idle frames imported")
	var texs: Array[Texture2D] = _ChrIdlePortrait.load_idle_textures_for_member(adv)
	assert_gt(texs.size(), 0, "helper member loads own idle")


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


func test_idle_portrait_view_set_before_enter_tree() -> void:
	# MVP 表彰台は add_child 後でも親が未入場だと _ready 前に set_from_entry が走る。
	var view: Control = _ChrIdlePortraitView.new()
	view.set_portrait_size(160)
	view.set_from_entry({"member_id": "", "job_id": "beast_tamer"})
	assert_gte(view.get_child_count(), 1, "nodes should build without waiting for _ready")
	var art: TextureRect = view.get_child(0) as TextureRect
	assert_not_null(art)
	assert_not_null(art.texture)
	add_child_autofree(view)


func test_beast_tamer_idle_animates_in_place() -> void:
	var paths: PackedStringArray = _ChrIdlePortrait.idle_frame_paths("beast_tamer")
	assert_gt(paths.size(), 1)
	var textures: Array[Texture2D] = _ChrIdlePortrait.load_idle_textures("beast_tamer")
	assert_eq(textures.size(), paths.size(), "severe zoom idle keeps all frames via normalize")
	_assert_stable_height_and_feet(textures, 8.0)


func test_vanguard_idle_filters_zoom_frames() -> void:
	var paths: PackedStringArray = _ChrIdlePortrait.idle_frame_paths("vanguard")
	assert_gt(paths.size(), 1)
	var textures: Array[Texture2D] = _ChrIdlePortrait.load_idle_textures("vanguard")
	assert_gte(textures.size(), 2, "mild zoom idle keeps a playable loop")
	assert_lt(textures.size(), paths.size(), "mild zoom idle drops shrunken frames")
	_assert_stable_height_and_feet(textures, 28.0)


func _assert_stable_height_and_feet(textures: Array[Texture2D], max_foot_span: float) -> void:
	var heights: Array[int] = []
	var foot_xs: Array[float] = []
	for tex in textures:
		var img: Image = tex.get_image()
		assert_not_null(img)
		if img.is_compressed():
			img.decompress()
		var used: Rect2i = img.get_used_rect()
		heights.append(used.size.y)
		var band_h: int = maxi(1, int(round(float(used.size.y) * 0.18)))
		var y0: int = used.position.y + used.size.y - band_h
		var min_x: int = used.position.x + used.size.x
		var max_x: int = used.position.x
		for y in range(y0, used.position.y + used.size.y):
			for x in range(used.position.x, used.position.x + used.size.x):
				if img.get_pixel(x, y).a < 0.08:
					continue
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
		foot_xs.append(float(min_x + max_x) * 0.5)
	var min_h: int = heights[0]
	var max_h: int = heights[0]
	for h in heights:
		min_h = mini(min_h, h)
		max_h = maxi(max_h, h)
	assert_lte(max_h - min_h, 2, "idle height should stay near-stable")
	var min_fx: float = foot_xs[0]
	var max_fx: float = foot_xs[0]
	for fx in foot_xs:
		min_fx = minf(min_fx, fx)
		max_fx = maxf(max_fx, fx)
	assert_lt(max_fx - min_fx, max_foot_span, "should not dart sideways")
