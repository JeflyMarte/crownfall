class_name SafeAreaHelper
extends RefCounted

## iPhone ノッチ / Dynamic Island / Home Indicator 向け inset。
## stretch=canvas_items+expand 時は DisplayServer 座標をビューポートへ換算する。
##
## Mac ではセーフエリアが常に「画面全体」(inset=0) のため、未対策だと
## エディタでは正しいのに実機だけ上バー侵食、という不一致が起きる。
## デスクトップでは iPhone 相当 inset をシミュレートして開発時に揃える。

## 720 幅論理 px 目安（Dynamic Island 機の top / Home Indicator）。
const _IOS_TOP_FALLBACK: float = 54.0
const _IOS_BOTTOM_FALLBACK: float = 24.0

## ProjectSettings で true にすると Mac でも iPhone 相当 inset をシミュレート。
## 既定は false（Mac ではシーン設計座標を壊さない）。
const SETTINGS_SIMULATE: StringName = &"crownfall/ui/simulate_mobile_safe_area"


static func top_inset() -> float:
	return _insets().y


static func bottom_inset() -> float:
	return _insets().w


static func left_inset() -> float:
	return _insets().x


static func right_inset() -> float:
	return _insets().z


## 実機（または明示的な Mac シミュレーション）で chrome を動かすか。
static func should_apply_chrome() -> bool:
	if not _needs_mobile_insets():
		return false
	var insets: Vector4 = _insets()
	return insets.y > 0.5 or insets.w > 0.5 or insets.x > 0.5 or insets.z > 0.5


## Vector4(left, top, right, bottom) in viewport pixels.
static func _insets() -> Vector4:
	var win: Window = _main_window()
	if win == null:
		return _platform_fallback(Vector4.ZERO)
	var vp_ctrl: Viewport = win.get_viewport()
	if vp_ctrl == null:
		vp_ctrl = win
	var viewport_full: Rect2 = vp_ctrl.get_visible_rect()
	if viewport_full.size.x <= 1.0 or viewport_full.size.y <= 1.0:
		viewport_full = Rect2(Vector2.ZERO, Vector2(win.size))
	if viewport_full.size.x <= 1.0 or viewport_full.size.y <= 1.0:
		return _platform_fallback(Vector4.ZERO)

	## 1) DisplayServer セーフ矩形 → ビューポート最終変換で換算（stretch 対応）
	var screen_safe := Rect2(DisplayServer.get_display_safe_area())
	if screen_safe.size.x > 1.0 and screen_safe.size.y > 1.0:
		var xf: Transform2D = vp_ctrl.get_final_transform()
		var viewport_safe: Rect2 = xf.affine_inverse() * screen_safe
		var out := Vector4(
			maxf(0.0, viewport_safe.position.x - viewport_full.position.x),
			maxf(0.0, viewport_safe.position.y - viewport_full.position.y),
			maxf(0.0, viewport_full.end.x - viewport_safe.end.x),
			maxf(0.0, viewport_full.end.y - viewport_safe.end.y)
		)
		## 画面全体とほぼ同じ＝inset 無し扱いはフォールバックへ。
		if out.y > 0.5 or out.w > 0.5 or out.x > 0.5 or out.z > 0.5:
			return _platform_fallback(out)

	## 2) Window マージン（実装がある環境向け）
	if win.has_method("get_safe_area_margins"):
		var m: Variant = win.call("get_safe_area_margins")
		if m is Vector4i or m is Vector4:
			var win_size: Vector2 = Vector2(win.size)
			if win_size.x > 1.0 and win_size.y > 1.0:
				var sx: float = viewport_full.size.x / win_size.x
				var sy: float = viewport_full.size.y / win_size.y
				var out2 := Vector4(
					maxf(0.0, float(m.x) * sx),
					maxf(0.0, float(m.y) * sy),
					maxf(0.0, float(m.z) * sx),
					maxf(0.0, float(m.w) * sy)
				)
				if out2.y > 0.5 or out2.w > 0.5:
					return _platform_fallback(out2)

	return _platform_fallback(Vector4.ZERO)


static func _platform_fallback(computed: Vector4) -> Vector4:
	var out := computed
	## 実機: API が 0 のときの最低保証。
	## デスクトップ: 常に iPhone 相当をシミュレート（Mac と実機の見た目を揃える）。
	if not _needs_mobile_insets():
		return out
	if out.y < 0.5:
		out.y = _IOS_TOP_FALLBACK
	if out.w < 0.5:
		out.w = _IOS_BOTTOM_FALLBACK
	return out


static func _needs_mobile_insets() -> bool:
	var os_name: String = OS.get_name()
	if os_name == "iOS" or os_name == "Android":
		return true
	## macOS / Windows / Linux — 明示 ON のときだけシミュレート（既定 OFF）。
	if ProjectSettings.has_setting(SETTINGS_SIMULATE):
		return bool(ProjectSettings.get_setting(SETTINGS_SIMULATE))
	return false


static func _main_window() -> Window:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_window()
