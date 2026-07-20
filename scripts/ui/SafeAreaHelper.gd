class_name SafeAreaHelper
extends RefCounted

## iPhone 等のセーフエリアを、720×1280（aspect=keep）ビューポート座標へ変換する。
## レターボックスで足りない分だけ、UI を内側へ退避させる（P3-UI-SAFE-001）。

const _META_BASE: StringName = &"_safe_area_base_offsets"
const _META_TITLE_MARGINS: StringName = &"_safe_area_title_base_margins"

## 背景は全面のまま、操作 UI を載せるホスト。
const _CONTENT_HOST_NAMES: Array[String] = [
	"HubView",
	"MenuGridView",
	"MainVBox",
	"MainColumn",
	"ContentRoot",
	"RootVBox",
	"CenterRoot",
]
## 画面上部クローム（TopBar / Header）。HubView 内 TopBar は HubView inset に任せる。
const _TOP_CHROME_NAMES: Array[String] = [
	"Header",
	"TopBar",
	"MainColumn/Header",
]


## left, top, right, bottom（ビューポート px）。レターボックス外は 0。
static func viewport_insets(viewport: Viewport = null) -> Vector4:
	var vp: Viewport = viewport
	if vp == null:
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		if tree == null or tree.root == null:
			return Vector4.ZERO
		vp = tree.root.get_viewport()
	if vp == null:
		return Vector4.ZERO

	var win: Window = vp.get_window()
	if win == null:
		return Vector4.ZERO
	var window_size: Vector2 = Vector2(win.size)
	if window_size.x < 2.0 or window_size.y < 2.0:
		return Vector4.ZERO

	var safe_screen: Rect2i = DisplayServer.get_display_safe_area()
	if safe_screen.size.x <= 0 or safe_screen.size.y <= 0:
		return Vector4.ZERO

	var base: Vector2 = Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 720)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 1280))
	)
	if base.x < 1.0 or base.y < 1.0:
		return Vector4.ZERO

	## aspect=keep 相当のレターボックス配置（window 座標系）。
	var scale: float = minf(window_size.x / base.x, window_size.y / base.y)
	if scale <= 0.0:
		return Vector4.ZERO
	var drawn: Vector2 = base * scale
	var letter: Vector2 = (window_size - drawn) * 0.5

	var win_pos: Vector2i = DisplayServer.window_get_position()
	var safe_in_window: Rect2 = Rect2(
		Vector2(safe_screen.position) - Vector2(win_pos),
		Vector2(safe_screen.size)
	)
	## セーフ矩形がウィンドウとほぼ無関係な場合は無視（ヘッドレス等）。
	if not Rect2(Vector2.ZERO, window_size).intersects(safe_in_window):
		return Vector4.ZERO

	var unsafe_top: float = maxf(0.0, safe_in_window.position.y)
	var unsafe_left: float = maxf(0.0, safe_in_window.position.x)
	var unsafe_bottom: float = maxf(0.0, window_size.y - safe_in_window.end.y)
	var unsafe_right: float = maxf(0.0, window_size.x - safe_in_window.end.x)

	var top_into_game: float = maxf(0.0, unsafe_top - letter.y)
	var bottom_into_game: float = maxf(0.0, unsafe_bottom - letter.y)
	var left_into_game: float = maxf(0.0, unsafe_left - letter.x)
	var right_into_game: float = maxf(0.0, unsafe_right - letter.x)

	return Vector4(
		left_into_game / scale,
		top_into_game / scale,
		right_into_game / scale,
		bottom_into_game / scale
	)


static func bottom_inset(viewport: Viewport = null) -> float:
	return viewport_insets(viewport).w


static func top_inset(viewport: Viewport = null) -> float:
	return viewport_insets(viewport).y


## シーンルートに対し、BottomNav / コンテンツホストへ inset を適用。
static func apply_scene_chrome(root: Node) -> void:
	if root == null:
		return
	var vp: Viewport = root.get_viewport()
	var inset: Vector4 = viewport_insets(vp)
	var bottom_nav: Control = root.get_node_or_null("BottomNav") as Control
	if bottom_nav != null:
		_apply_bottom_nav(bottom_nav, inset)
	for host_name: String in _CONTENT_HOST_NAMES:
		var host: Control = root.get_node_or_null(host_name) as Control
		if host != null:
			_apply_content_host(host, inset)
	for top_name: String in _TOP_CHROME_NAMES:
		var top: Control = root.get_node_or_null(top_name) as Control
		if top != null:
			_apply_top_chrome(top, inset)
	## タイトル等：MarginContainer に追加余白。
	_apply_margin_containers(root, inset)


static func _apply_top_chrome(chrome: Control, inset: Vector4) -> void:
	var base: Vector4 = _ensure_base_offsets(chrome)
	chrome.offset_left = base.x + inset.x
	chrome.offset_top = base.y + inset.y
	chrome.offset_right = base.z - inset.z
	## 高さ維持（底辺も同量下げない／上げないで top だけ押し下げ）
	chrome.offset_bottom = base.w + inset.y


static func _apply_bottom_nav(nav: Control, inset: Vector4) -> void:
	var base: Vector4 = _ensure_base_offsets(nav)
	## 高さは維持したまま、底辺をセーフ内へ持ち上げる。
	nav.offset_left = base.x + inset.x
	nav.offset_right = base.z - inset.z
	nav.offset_bottom = base.w - inset.w
	nav.offset_top = base.y - inset.w


static func _apply_content_host(host: Control, inset: Vector4) -> void:
	var base: Vector4 = _ensure_base_offsets(host)
	host.offset_left = base.x + inset.x
	host.offset_top = base.y + inset.y
	host.offset_right = base.z - inset.z
	host.offset_bottom = base.w - inset.w


static func _apply_margin_containers(root: Node, inset: Vector4) -> void:
	if inset == Vector4.ZERO:
		## ゼロでもタイトル基準余白へ戻す必要があるので走査は続ける。
		pass
	for child in root.get_children():
		var margin: MarginContainer = child as MarginContainer
		if margin == null:
			continue
		if not margin.has_meta(_META_TITLE_MARGINS):
			margin.set_meta(
				_META_TITLE_MARGINS,
				Vector4(
					float(margin.get_theme_constant("margin_left")),
					float(margin.get_theme_constant("margin_top")),
					float(margin.get_theme_constant("margin_right")),
					float(margin.get_theme_constant("margin_bottom"))
				)
			)
		var base: Vector4 = margin.get_meta(_META_TITLE_MARGINS)
		margin.add_theme_constant_override("margin_left", int(round(base.x + inset.x)))
		margin.add_theme_constant_override("margin_top", int(round(base.y + inset.y)))
		margin.add_theme_constant_override("margin_right", int(round(base.z + inset.z)))
		margin.add_theme_constant_override("margin_bottom", int(round(base.w + inset.w)))


static func _ensure_base_offsets(ctrl: Control) -> Vector4:
	if not ctrl.has_meta(_META_BASE):
		ctrl.set_meta(
			_META_BASE,
			Vector4(ctrl.offset_left, ctrl.offset_top, ctrl.offset_right, ctrl.offset_bottom)
		)
	return ctrl.get_meta(_META_BASE)
