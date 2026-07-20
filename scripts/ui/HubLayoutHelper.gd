class_name HubLayoutHelper
extends RefCounted

## 拠点系画面（720×1280）のコンテンツ幅・余白計算 SSOT。
## 固定 720px 幅で子要素を組むと実ビューポートからはみ出すため、必ず本ヘルパ経由で幅を求める。

const CONTENT_MARGIN_H: float = 12.0

static func viewport_width(fallback: float = NavUiTokens.VIEWPORT_WIDTH) -> float:
	var root: Window = _main_window()
	if root != null and root.size.x > 1.0:
		return root.size.x
	return fallback

static func content_width(viewport_width: float) -> float:
	return maxf(0.0, viewport_width - CONTENT_MARGIN_H * 2.0)

## ScrollContainer に左右 inset を付けたあと、その実幅をそのまま使う。
static func scroll_content_width(scroll: Control) -> float:
	if scroll != null and scroll.size.x > 1.0:
		return scroll.size.x
	return content_width(viewport_width())

static func column_width(
	content_width: float,
	columns: int,
	separation: int = 0
) -> int:
	if columns <= 0:
		return 0
	var gaps: float = float(separation) * float(columns - 1)
	return int(floor((content_width - gaps) / float(columns)))

static func stack_bottom_offset(footer_height: float = 0.0) -> float:
	return -(NavUiTokens.BOTTOM_NAV_HEIGHT + SafeAreaHelper.bottom_inset() + footer_height)

static func apply_horizontal_insets(scroll: ScrollContainer) -> void:
	if scroll == null:
		return
	scroll.offset_left = CONTENT_MARGIN_H
	scroll.offset_right = -CONTENT_MARGIN_H
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

static func _main_window() -> Window:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_window()
