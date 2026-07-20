class_name HubLayoutHelper
extends RefCounted

## 拠点系画面（720×1280）のコンテンツ幅・余白計算 SSOT。
## 固定 720px 幅で子要素を組むと実ビューポートからはみ出すため、必ず本ヘルパ経由で幅を求める。
##
## セーフエリア chrome は実機（iOS/Android）のみ。Mac ではシーン設計座標を尊重する。

const _SafeAreaHelper := preload("res://scripts/ui/SafeAreaHelper.gd")

const CONTENT_MARGIN_H: float = 12.0
const _HEADER_FALLBACK_H: float = 50.0
const _META_SAFE_DEFERRED: StringName = &"_cf_safe_area_deferred"
const _META_SAFE_SIZE_CONNECTED: StringName = &"_cf_safe_area_size_connected"
const _META_HEADER_DESIGN_H: StringName = &"_cf_header_design_h"
const _META_BODY_BASE_TOP: StringName = &"_cf_body_base_top"
const _META_BODY_BASE_BOTTOM: StringName = &"_cf_body_base_bottom"

## BaseScene HubView 設計値（scenes/base/BaseScene.tscn）。
const HUB_TOP_BAR_H: float = 88.0
const HUB_LEFT_MENU_DESIGN_TOP: float = 96.0
const HUB_DAILY_H: float = 236.0
const HUB_STRIP_H: float = 80.0
const HUB_STACK_GAP: float = 8.0

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
	return -(NavUiTokens.BOTTOM_NAV_HEIGHT + footer_height)

static func bottom_nav_total_height() -> float:
	## デスクトップはシーン設計（ナビ本体のみ）。実機のみ Home Indicator 分を足す。
	if not _SafeAreaHelper.should_apply_chrome():
		return NavUiTokens.BOTTOM_NAV_HEIGHT
	return NavUiTokens.BOTTOM_NAV_HEIGHT + _SafeAreaHelper.bottom_inset()

static func apply_horizontal_insets(scroll: ScrollContainer) -> void:
	if scroll == null:
		return
	scroll.offset_left = CONTENT_MARGIN_H
	scroll.offset_right = -CONTENT_MARGIN_H
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED


## BottomNav / MainColumn|HubView / 直下 Header にセーフエリアを適用。
## Mac（simulate OFF）では何もしない — シーンの絶対座標を壊さない。
static func apply_chrome_safe_area(root: Control) -> void:
	if root == null:
		return
	if not _SafeAreaHelper.should_apply_chrome():
		return
	_apply_chrome_safe_area_impl(root)
	if not root.get_meta(_META_SAFE_DEFERRED, false):
		root.set_meta(_META_SAFE_DEFERRED, true)
		_schedule_safe_area_reapply(root)
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
	if not _SafeAreaHelper.should_apply_chrome():
		return
	_apply_chrome_safe_area_impl(root)
	var tree: SceneTree = root.get_tree()
	if tree == null:
		return
	var timer: SceneTreeTimer = tree.create_timer(0.05)
	timer.timeout.connect(_reapply_safe_area_once_delayed.bind(root), CONNECT_ONE_SHOT)


static func _reapply_safe_area_once_delayed(root: Control) -> void:
	if is_instance_valid(root) and _SafeAreaHelper.should_apply_chrome():
		_apply_chrome_safe_area_impl(root)


static func _on_root_viewport_size_changed(root: Control) -> void:
	if is_instance_valid(root) and _SafeAreaHelper.should_apply_chrome():
		_apply_chrome_safe_area_impl(root)


static func _apply_chrome_safe_area_impl(root: Control) -> void:
	var top: float = _SafeAreaHelper.top_inset()
	var bottom: float = _SafeAreaHelper.bottom_inset()
	var nav_h: float = bottom_nav_total_height()
	var bottom_nav: Control = root.get_node_or_null("BottomNav") as Control
	if bottom_nav != null:
		bottom_nav.offset_top = -nav_h
		bottom_nav.offset_bottom = 0.0
		var row: Control = bottom_nav.get_node_or_null("NavRow") as Control
		if row != null and bottom > 0.5:
			row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			row.offset_bottom = -bottom
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
	var root_header: Control = root.get_node_or_null("Header") as Control
	if main != null and root_header == null:
		main.offset_top = top
		main.offset_bottom = -(nav_h + reserved_above_nav)
	elif main != null and root_header != null:
		main.offset_bottom = -(nav_h + reserved_above_nav)
	var hub: Control = root.get_node_or_null("HubView") as Control
	if hub != null:
		hub.offset_bottom = -nav_h
	var top_bar: Control = root.get_node_or_null("HubView/TopBar") as Control
	if top_bar != null:
		var bar_h2: float = _design_height(top_bar, HUB_TOP_BAR_H)
		top_bar.offset_top = top
		top_bar.offset_bottom = top + bar_h2
	## Hub ホーム: TopBar だけ下げると左メニュー／隊長名が重なる。日課は絶対Yのままだと下ナビに侵食。
	layout_hub_home_content(root)
	if root_header != null:
		_shift_root_header_and_body(root, root_header, top)


## 実機のみ。左メニューを TopBar に追従させ、日課・通貨帯を HubView 下端に積む。
## Mac（should_apply_chrome=false）では呼ばれても何もしない。
static func layout_hub_home_content(root: Control) -> void:
	if root == null or not _SafeAreaHelper.should_apply_chrome():
		return
	var hub: Control = root.get_node_or_null("HubView") as Control
	if hub == null:
		return
	var top: float = _SafeAreaHelper.top_inset()
	var left: Control = hub.get_node_or_null("LeftMenuPanel") as Control
	if left != null:
		left.anchor_top = 0.0
		left.anchor_bottom = 0.0
		left.offset_top = top + HUB_LEFT_MENU_DESIGN_TOP
		_fit_hub_left_menu_height(left)
	_stack_hub_bottom_panels(hub)


static func _fit_hub_left_menu_height(left: Control) -> void:
	if left == null:
		return
	var scroll: ScrollContainer = left.get_node_or_null("MenuScroll") as ScrollContainer
	if scroll != null:
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbox: VBoxContainer = left.get_node_or_null("MenuScroll/MenuVBox") as VBoxContainer
	var content_h: float = 0.0
	if vbox != null:
		## size.y 禁止（空パネル化の再発防止）。最小サイズのみ。
		content_h = vbox.get_combined_minimum_size().y
	if content_h < 1.0:
		var design_h: float = absf(left.offset_bottom - left.offset_top)
		content_h = design_h if design_h > 1.0 else 484.0
	else:
		content_h += 20.0
	left.offset_bottom = left.offset_top + content_h


static func _stack_hub_bottom_panels(hub: Control) -> void:
	if hub == null:
		return
	var daily: Control = hub.get_node_or_null("DailyMissionPanel") as Control
	var strip: Control = hub.get_node_or_null("CurrencyStrip") as Control
	if daily != null:
		daily.anchor_left = 0.0
		daily.anchor_right = 1.0
		daily.anchor_top = 1.0
		daily.anchor_bottom = 1.0
		daily.offset_left = CONTENT_MARGIN_H
		daily.offset_right = -CONTENT_MARGIN_H
		daily.offset_top = -(HUB_DAILY_H + HUB_STACK_GAP)
		daily.offset_bottom = -HUB_STACK_GAP
	if strip != null:
		strip.anchor_left = 0.0
		strip.anchor_right = 1.0
		strip.anchor_top = 1.0
		strip.anchor_bottom = 1.0
		strip.offset_left = CONTENT_MARGIN_H
		strip.offset_right = -CONTENT_MARGIN_H
		strip.offset_top = -(HUB_DAILY_H + HUB_STACK_GAP * 2.0 + HUB_STRIP_H)
		strip.offset_bottom = -(HUB_DAILY_H + HUB_STACK_GAP * 2.0)


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
		if c.anchor_top > 0.05:
			continue
		if (
			c.anchor_bottom >= 0.999
			and c.offset_top <= 1.0
			and absf(c.offset_bottom) <= 1.0
		):
			continue
		var base_top: float = float(c.get_meta(_META_BODY_BASE_TOP, c.offset_top))
		if not c.has_meta(_META_BODY_BASE_TOP):
			c.set_meta(_META_BODY_BASE_TOP, base_top)
		if base_top < 8.0:
			continue
		c.offset_top = base_top + top
		if c.anchor_bottom < 0.05:
			var base_bottom: float = float(c.get_meta(_META_BODY_BASE_BOTTOM, c.offset_bottom))
			if not c.has_meta(_META_BODY_BASE_BOTTOM):
				c.set_meta(_META_BODY_BASE_BOTTOM, base_bottom)
			c.offset_bottom = base_bottom + top


static func _main_window() -> Window:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_window()
