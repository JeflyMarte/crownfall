class_name ScrollTouchHelper
extends RefCounted

## 実機タッチで ScrollContainer がドラッグできない問題の対策。
## 子の Button / STOP コントロールがドラッグを飲み込むため PASS に変え、deadzone を付ける。

const TOUCH_DEADZONE: int = 20
const _META_HOOKED: StringName = &"_cf_scroll_touch_hooked"
const _META_REFRESH_QUEUED: StringName = &"_cf_scroll_touch_refresh_queued"


## nest_inner_scrolls=false なら内側 ScrollContainer を別スクロールとして enable しない
## （キャラ装備タブの入れ子競合・実機でスクロールが重い／効かない対策）。
static func enable(scroll: ScrollContainer, nest_inner_scrolls: bool = true) -> void:
	if scroll == null:
		return
	if scroll.scroll_deadzone < TOUCH_DEADZONE:
		scroll.scroll_deadzone = TOUCH_DEADZONE
	scroll.set_meta(&"_cf_scroll_nest_inner", nest_inner_scrolls)
	_make_descendants_scroll_friendly(scroll, nest_inner_scrolls)
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
	## 直下だけでなく深い VBox／Grid（RosterGrid・PassiveList 等）への追加も拾う。
	_hook_subtree_mutations(scroll, scroll)


static func _hook_subtree_mutations(node: Node, scroll: ScrollContainer) -> void:
	if node == null or not is_instance_valid(node) or not is_instance_valid(scroll):
		return
	## 別スクロール境界は越えない（入れ子 Scroll は各自 enable）。
	if node is ScrollContainer and node != scroll:
		return
	if not node.child_entered_tree.is_connected(_on_content_child_entered.bind(scroll)):
		node.child_entered_tree.connect(_on_content_child_entered.bind(scroll))
	for child in node.get_children():
		_hook_subtree_mutations(child, scroll)


static func _on_content_child_entered(node: Node, scroll: ScrollContainer) -> void:
	## 追加された枝にもフックを伸ばし、孫以降の Button も PASS 化対象にする。
	_hook_subtree_mutations(node, scroll)
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
	var nest: bool = bool(scroll.get_meta(&"_cf_scroll_nest_inner", true))
	_make_descendants_scroll_friendly(scroll, nest)


static func _make_descendants_scroll_friendly(node: Node, nest_inner_scrolls: bool = true) -> void:
	for child in node.get_children():
		if child is ScrollContainer:
			if nest_inner_scrolls:
				enable(child as ScrollContainer, nest_inner_scrolls)
			else:
				## 内側はスクロール対象にせず、ボタンだけ PASS 化して外スクロールへ渡す。
				_make_descendants_scroll_friendly(child, false)
			continue
		if child is BaseButton:
			(child as BaseButton).mouse_filter = Control.MOUSE_FILTER_PASS
		elif child is Control:
			var c: Control = child as Control
			## 状態異常リンク等: meta で STOP 維持（一律 RichTextLabel→STOP は章カード名の
			## IGNORE 越しタップを潰すので禁止。StatusEffectLinkHelper が meta を付ける）。
			if bool(c.get_meta(&"_cf_keep_mouse_stop", false)):
				c.mouse_filter = Control.MOUSE_FILTER_STOP
			## カード等の STOP がドラッグを奪う。IGNORE はそのまま。
			elif c.mouse_filter == Control.MOUSE_FILTER_STOP:
				c.mouse_filter = Control.MOUSE_FILTER_PASS
		_make_descendants_scroll_friendly(child, nest_inner_scrolls)
