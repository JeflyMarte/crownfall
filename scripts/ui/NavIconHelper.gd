class_name NavIconHelper
extends RefCounted

## 拠点・各画面 BottomNav / メニューカード用アイコン適用。

const ICON_SIZE_MENU: int = NavUiTokens.SIDE_MENU_ICON

static func apply_texture_to_button(btn: Button, category: String, icon_id: String, size_px: int) -> bool:
	var tex: Texture2D = IconPaths.get_icon_texture(icon_id, category)
	if tex == null:
		return false
	btn.icon = tex
	btn.add_theme_constant_override("icon_max_width", size_px)
	btn.add_theme_constant_override("icon_max_height", size_px)
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	return true

static func decorate_bottom_nav_row(nav_row: HBoxContainer) -> void:
	if nav_row == null:
		return
	for entry in BottomNavHelper.BOTTOM_NAV_ENTRIES:
		var btn: Button = nav_row.get_node_or_null(str(entry["node"])) as Button
		if btn == null:
			continue
		NavUiTokens.set_bottom_nav_icon(
			btn,
			str(entry["icon_category"]),
			str(entry["icon_id"])
		)

static func decorate_menu_button(btn: Button, entry: Dictionary, icon_size: int = ICON_SIZE_MENU) -> void:
	if btn == null:
		return
	var category: String = str(entry.get("icon_category", ""))
	var icon_id: String = str(entry.get("icon_id", ""))
	if category.is_empty() or icon_id.is_empty():
		return
	apply_texture_to_button(btn, category, icon_id, icon_size)
