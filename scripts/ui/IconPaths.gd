class_name IconPaths
extends RefCounted

static func get_icon_texture(id: String, _category: String) -> Texture2D:
	if id.is_empty():
		return null
	var path: String = "res://assets/ui/batch2/ICO_%s.png" % id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
