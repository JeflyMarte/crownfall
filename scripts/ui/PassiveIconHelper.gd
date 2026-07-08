class_name PassiveIconHelper
extends RefCounted

## パッシブアイコン。`assets/ui/passives/ICO_PASSIVE_{PascalCase}.png` を参照。

const DISPLAY_SIZE: Vector2 = Vector2(44, 44)
const ROOT: String = "res://assets/ui/passives/"
const FALLBACK_PATH: String = ROOT + "ICO_PASSIVE_BattleFervor.png"


static func icon_path(passive_id: String) -> String:
	if passive_id.is_empty():
		return ""
	var parts: PackedStringArray = passive_id.split("_")
	var pascal: String = ""
	for part in parts:
		if part.is_empty():
			continue
		pascal += part.substr(0, 1).to_upper() + part.substr(1)
	if pascal.is_empty():
		return ""
	return ROOT + "ICO_PASSIVE_%s.png" % pascal


static func resolve_texture_path(passive_id: String) -> String:
	var path: String = icon_path(passive_id)
	if not path.is_empty() and ResourceLoader.exists(path):
		return path
	path = IconPaths.passive_icon_path(passive_id)
	if not path.is_empty() and ResourceLoader.exists(path):
		return path
	if ResourceLoader.exists(FALLBACK_PATH):
		return FALLBACK_PATH
	return ""


static func make_icon(passive_id: String, display_size: Vector2 = DISPLAY_SIZE) -> Control:
	var path: String = resolve_texture_path(passive_id)
	if path.is_empty():
		return null
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return null
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = display_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon
