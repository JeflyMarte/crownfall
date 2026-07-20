class_name HubLayoutHelper
extends RefCounted

## 拠点系画面（720×1280）のコンテンツ幅・余白計算 SSOT。
## 固定 720px 幅で子要素を組むと実ビューポートからはみ出すため、必ず本ヘルパ経由で幅を求める。

const CONTENT_MARGIN_H: float = 12.0
const _HEADER_FALLBACK_H: float = 50.0
const _META_SAFE_DEFERRED: StringName = &"_cf_safe_area_deferred"
const _META_SAFE_SIZE_CONNECTED: StringName = &"_cf_safe_area_size_connected"
const _META_HEADER_DESIGN_H: StringName = &"_cf_header_design_h"
const _META_BODY_BASE_TOP: StringName = &"_cf_body_base_top"
const _META_BODY_BASE_BOTTOM: StringName = &"_cf_body_base_bottom"

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

static func bottom_nav_total_height() -> float:
	return NavUiTokens.BOTTOM_NAV_HEIGHT + SafeAreaHelper.bottom_inset()

## BottomNav / MainColumn|HubView / 直下 Header にセーフエリアを適用。
## VBox 内 Header の offset は触らない。ルート直下 Header の下にある本文も一緒に下げる。
static func apply_chrome_safe_area(root: Control) -> void:
	if root == null:
		return
	_apply_chrome_safe_area_impl(root)
	## 実機は初フレームで inset=0 のことがあるため、遅延再適用。
	if not root.get_meta(_META_SAFE_DEFERRED, false):
		root.set_meta(_META_SAFE_DEFERRED, true)
		_schedule_safe_area_reapply(root)
	## 回転・リサイズでも追従。
	if not root.get_meta(_META_SAFE_SIZE_CONNECTED, false):
		root.set_meta(_META_SAFE_SIZE_CONNECTED, true)
		var vp: Viewport = root.get_viewport()
		if vp != null:
			var cb := _on_root_viewport_size_changed.bind(root)
			if not vp.size_changed.is_connected(cb):
				vp.size_changed.connect(cb)


static func _schedule_safe_area_reapply(root: Control) -> void:
	var tree: SceneTree = root.get_tree()
	if tree == null:
		return
	tree.process_frame.connect(_reapply_safe_area_once.bind(root), CONNECT_ONE_SHOT)


static func _reapply_safe_area_once(root: Control) -> void:
	if not is_instance_valid(root):
		return
	_apply_chrome_safe_area_impl(root)
	var tree: SceneTree = root.get_tree()
	if tree == null:
		return
	var timer: SceneTreeTimer = tree.create_timer(0.05)
	timer.timeout.connect(_reapply_safe_area_once_delayed.bind(root), CONNECT_ONE_SHOT)


static func _reapply_safe_area_once_delayed(root: Control) -> void:
	if is_instance_valid(root):
		_apply_chrome_safe_area_impl(root)


static func _on_root_viewport_size_changed(root: Control) -> void:
	if is_instance_valid(root):
		_apply_chrome_safe_area_impl(root)


static func _apply_chrome_safe_area_impl(root: Control) -> void:
	var top: float = SafeAreaHelper.top_inset()
	var bottom: float = SafeAreaHelper.bottom_inset()
	var nav_h: float = bottom_nav_total_height()
	var bottom_nav: Control = root.get_node_or_null("BottomNav") as Control
	if bottom_nav != null:
		bottom_nav.offset_top = -nav_h
		bottom_nav.offset_bottom = 0.0
		var row: Control = bottom_nav.get_node_or_null("NavRow") as Control
		if row != null and bottom > 0.5:
			row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			row.offset_bottom = -bottom
	## FooterPanel / SummonActionBar など下ナビ直上の帯を維持する。
	var reserved_above_nav: float = 0.0
	var footer: Control = root.get_node_or_null("FooterPanel") as Control
	if footer != null:
		var footer_h: float = absf(footer.offset_bottom - footer.offset_top)
		if footer_h < 1.0:
			footer_h = 84.0
		reserved_above_nav = footer_h
		footer.offset_bottom = -nav_h
		footer.offset_top = -(nav_h + footer_h)
	var summon_bar: Control = root.get_node_or_null("SummonActionBar") as Control
	if summon_bar != null:
		var bar_h: float = _design_height(summon_bar, 208.0)
		reserved_above_nav += bar_h
		summon_bar.offset_bottom = -nav_h
		summon_bar.offset_top = -(nav_h + bar_h)
	var main: Control = root.get_node_or_null("MainColumn") as Control
	## DungeonSelect 等: Header が MainColumn 内 → MainColumn 全体を下げる。
	## ルート直下 Header がある画面は _shift_root_header_and_body で扱う。
	var root_header: Control = root.get_node_or_null("Header") as Control
	if main != null and root_header == null:
		main.offset_top = top
		main.offset_bottom = -(nav_h + reserved_above_nav)
	elif main != null and root_header != null:
		## 下端だけナビ分を確保（上端は body シフト側）。
		main.offset_bottom = -(nav_h + reserved_above_nav)
	var hub: Control = root.get_node_or_null("HubView") as Control
	if hub != null:
		hub.offset_bottom = -nav_h
	var top_bar: Control = root.get_node_or_null("HubView/TopBar") as Control
	if top_bar != null:
		var bar_h: float = _design_height(top_bar, 88.0)
		top_bar.offset_top = top
		top_bar.offset_bottom = top + bar_h
	if root_header != null:
		_shift_root_header_and_body(root, root_header, top)


static func _design_height(ctrl: Control, fallback: float) -> float:
	if ctrl == null:
		return fallback
	if ctrl.has_meta(_META_HEADER_DESIGN_H):
		return float(ctrl.get_meta(_META_HEADER_DESIGN_H))
	var h: float = absf(ctrl.offset_bottom - ctrl.offset_top)
	if h < 1.0:
		h = ctrl.get_combined_minimum_size().y
	if h < 1.0:
		h = ctrl.size.y
	if h < 1.0:
		h = fallback
	ctrl.set_meta(_META_HEADER_DESIGN_H, h)
	return h


static func _shift_root_header_and_body(root: Control, header: Control, top: float) -> void:
	var header_h: float = _design_height(header, _HEADER_FALLBACK_H)
	header.offset_top = top
	header.offset_bottom = top + header_h
	## ルート直下の上端アンカー本文を同じ top inset で下降。
	## 鍛冶の ModeTabs / CategoryRow / MainSplit のようにヘッダー直下以外も含む。
	for child in root.get_children():
		if child == header or not (child is Control):
			continue
		var c: Control = child as Control
		var n: String = str(c.name)
		if (
			n == "BottomNav"
			or n == "BgTexture"
			or n == "Bg"
			or n == "BgOverlay"
			or n == "FxLayer"
			or n == "FooterPanel"
			or n.begins_with("Hub")
		):
			continue
		## 下端基準のパネル（CraftablePanel 等）は触らない。
		if c.anchor_top > 0.05:
			continue
		## フルブリード背景は触らない。
		if (
			c.anchor_bottom >= 0.999
			and c.offset_top <= 1.0
			and absf(c.offset_bottom) <= 1.0
		):
			continue
		var base_top: float = float(c.get_meta(_META_BODY_BASE_TOP, c.offset_top))
		if not c.has_meta(_META_BODY_BASE_TOP):
			c.set_meta(_META_BODY_BASE_TOP, base_top)
		## offset_top≈0 の装飾・全面オーバーレイは除外（本文は通常 40+）。
		if base_top < 8.0:
			continue
		c.offset_top = base_top + top
		## 上端固定の帯（ModeTabs / CategoryRow）は下端も同じだけ下げる。
		if c.anchor_bottom < 0.05:
			var base_bottom: float = float(c.get_meta(_META_BODY_BASE_BOTTOM, c.offset_bottom))
			if not c.has_meta(_META_BODY_BASE_BOTTOM):
				c.set_meta(_META_BODY_BASE_BOTTOM, base_bottom)
			c.offset_bottom = base_bottom + top


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
