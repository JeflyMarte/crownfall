extends SceneTree
## One-shot: make near-black pixels transparent on starter card frame.


func _init() -> void:
	var path := "res://assets/ui/intro/UI_Card_Starter_Frame.png"
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		push_error("load failed %s" % err)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			if lum < 0.10 and c.r < 0.15 and c.g < 0.15 and c.b < 0.18:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	err = img.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("save failed %s" % err)
		quit(1)
		return
	print("frame alpha punched: %dx%d" % [w, h])
	quit(0)
