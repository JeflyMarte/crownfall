extends GutTest

## 機巧士仕掛け頭上マーク（P3-JOB-ENGINEER-001-M1）

const _IconPaths := preload("res://scripts/ui/IconPaths.gd")


func test_engineer_trap_status_icons_resolve() -> void:
	for sid: String in ["eng_trap_spike", "eng_trap_snare", "eng_trap_break"]:
		var tex: Texture2D = _IconPaths.get_icon_texture(sid, "status")
		assert_not_null(tex, sid)
