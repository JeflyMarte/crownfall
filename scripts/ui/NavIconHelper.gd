class_name NavIconHelper
extends RefCounted

## 拠点・各画面 BottomNav / メニューカード用アイコン適用（003_01 モック準拠）。

const ICON_SIZE_MENU: int = 36
const ICON_SIZE_NAV: int = 28

const BOTTOM_NAV_ICONS: Dictionary = {
	"NavHome": {"category": "ui", "id": "home"},
	"NavParty": {"category": "ui", "id": "party"},
	"NavAdventure": {"category": "ui", "id": "adventure"},
	"NavForge": {"category": "ui", "id": "blacksmith"},
	"NavShop": {"category": "ui", "id": "gacha"},
	"NavMenu": {"category": "ui", "id": "menu"},
}

static func apply_texture_to_button(btn: Button, category: String, icon_id: String, size_px: int) -> bool:
	var tex: Texture2D = IconPaths.get_icon_texture(icon_id, category)
	if tex == null:
		return false
	btn.icon = tex
	btn.add_theme_constant_override("icon_max_width", size_px)
	btn.add_theme_constant_override("icon_max_height", size_px)
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	return true

static func decorate_bottom_nav_row(nav_row: HBoxContainer, icon_size: int = ICON_SIZE_NAV) -> void:
	if nav_row == null:
		return
	for child in nav_row.get_children():
		if not child is Button:
			continue
		var spec: Variant = BOTTOM_NAV_ICONS.get(child.name, null)
		if spec is Dictionary:
			apply_texture_to_button(
				child as Button,
				str(spec["category"]),
				str(spec["id"]),
				icon_size
			)
