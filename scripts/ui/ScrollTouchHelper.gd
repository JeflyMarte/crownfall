class_name ScrollTouchHelper
extends RefCounted

## 実機タッチで ScrollContainer がドラッグできない問題の対策。
## 子の Button / STOP コントロールがドラッグを飲み込むため PASS に変え、deadzone を付ける。

const TOUCH_DEADZONE: int = 20
const _META_HOOKED: StringName = &"_cf_scroll_touch_hooked"
const _META_REFRESH_QUEUED: StringName = &"_cf_scroll_touch_refresh_queued"


static func enable(scroll: ScrollContainer) -> void:
	if scroll == null:
		return
	if scroll.scroll_deadzone < TOUCH_DEADZONE:
		scroll.scroll_deadzone = TOUCH_DEADZONE
	_make_descendants_scroll_friendly(scroll)
	_hook_content_mutations(scroll)


static func enable_in_subtree(root: Node) -> void:
	if root == null:
		return
	if root is ScrollContainer:
		enable(root as ScrollContainer)
	for child in root.get_children():
		enable_in_subtree(child)


static func _hook_content_mutations(scroll: ScrollContainer) -> void:
	if scroll.get_meta(_META_HOOKED, false):
		return
	scroll.set_meta(_META_HOOKED, true)
	## 直下のコンテンツ（VBox 等）へ項目が追加されたら再 PASS 化。
	for child in scroll.get_children():
		if child is Node and not child.child_entered_tree.is_connected(_on_content_child_entered.bind(scroll)):
			child.child_entered_tree.connect(_on_content_child_entered.bind(scroll))


static func _on_content_child_entered(_node: Node, scroll: ScrollContainer) -> void:
	_queue_refresh(scroll)


static func _queue_refresh(scroll: ScrollContainer) -> void:
	if not is_instance_valid(scroll):
		return
	if scroll.get_meta(_META_REFRESH_QUEUED, false):
		return
	scroll.set_meta(_META_REFRESH_QUEUED, true)
	## process_frame + CONNECT_ONE_SHOT は、refresh 中に再 queue すると
	## ONE_SHOT 解除前に同じ Callable を再 connect して ERROR→実機強制終了の原因になる。
	## call_deferred なら同一フレーム内の再入場でも衝突しない。
	_refresh_once.call_deferred(scroll)


static func _refresh_once(scroll: ScrollContainer) -> void:
	if not is_instance_valid(scroll):
		return
	scroll.set_meta(_META_REFRESH_QUEUED, false)
	_make_descendants_scroll_friendly(scroll)


static func _make_descendants_scroll_friendly(node: Node) -> void:
	for child in node.get_children():
		if child is ScrollContainer:
			enable(child as ScrollContainer)
			continue
		if child is BaseButton:
			(child as BaseButton).mouse_filter = Control.MOUSE_FILTER_PASS
		elif child is Control:
			var c: Control = child as Control
			## カード等の STOP がドラッグを奪う。IGNORE はそのまま。
			if c.mouse_filter == Control.MOUSE_FILTER_STOP:
				c.mouse_filter = Control.MOUSE_FILTER_PASS
		_make_descendants_scroll_friendly(child)
