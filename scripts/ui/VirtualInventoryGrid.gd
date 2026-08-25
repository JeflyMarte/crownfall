class_name VirtualInventoryGrid
extends RefCounted

## 装備所持一覧の仮想グリッド。見えている行＋バッファだけセルを生成する。

enum BindMode { INNER_SCROLL, OUTER_SCROLL }

const DEFAULT_BUFFER_ROWS: int = 2

var columns: int = 6
var cell_size: Vector2 = Vector2(64, 64)
var h_separation: int = 4
var v_separation: int = 4
var buffer_rows: int = DEFAULT_BUFFER_ROWS

var _scroll: ScrollContainer = null
var _host: Control = null
var _mode: BindMode = BindMode.INNER_SCROLL
var _entries: Array = []
var _cells: Dictionary = {}
var _empty_hint: Control = null
var _make_cell: Callable = Callable()
var _on_cell_unbind: Callable = Callable()
var _make_empty: Callable = Callable()
var _scroll_bar: VScrollBar = null
var _empty_message: String = ""


func bind(
	scroll: ScrollContainer,
	host: Control,
	mode: BindMode,
	make_cell: Callable,
	make_empty: Callable = Callable(),
	on_cell_unbind: Callable = Callable()
) -> void:
	unbind()
	_scroll = scroll
	_host = host
	_mode = mode
	_make_cell = make_cell
	_make_empty = make_empty
	_on_cell_unbind = on_cell_unbind
	_connect_scroll()


func unbind() -> void:
	_disconnect_scroll()
	clear()
	_scroll = null
	_host = null
	_make_cell = Callable()
	_make_empty = Callable()
	_on_cell_unbind = Callable()


func set_entries(entries: Array, empty_message: String = "") -> void:
	_entries = entries.duplicate()
	_empty_message = empty_message
	_update_host_min_size()
	refresh(true)


func clear() -> void:
	_entries.clear()
	_clear_cells()
	_hide_empty()
	if _host != null:
		_host.custom_minimum_size = Vector2.ZERO


func refresh(_force: bool = false) -> void:
	if _host == null or _scroll == null:
		return
	if _entries.is_empty():
		_clear_cells()
		_show_empty()
		return
	_hide_empty()
	var index_range: Vector2i = _visible_index_range()
	if index_range.x < 0:
		_clear_cells()
		return
	_sync_cells(index_range.x, index_range.y)


func get_cell(index: int) -> Control:
	return _cells.get(index) as Control


func entry_count() -> int:
	return _entries.size()


func content_height() -> float:
	return _content_height()


func content_width() -> float:
	return _content_width()


func _connect_scroll() -> void:
	if _scroll == null:
		return
	var bar: VScrollBar = _scroll.get_v_scroll_bar()
	if bar != null:
		_scroll_bar = bar
		if not bar.value_changed.is_connected(_on_scroll_value_changed):
			bar.value_changed.connect(_on_scroll_value_changed)
	if not _scroll.resized.is_connected(_on_scroll_resized):
		_scroll.resized.connect(_on_scroll_resized)
	if _host != null and not _host.resized.is_connected(_on_scroll_resized):
		_host.resized.connect(_on_scroll_resized)


func _disconnect_scroll() -> void:
	if _scroll_bar != null and is_instance_valid(_scroll_bar):
		if _scroll_bar.value_changed.is_connected(_on_scroll_value_changed):
			_scroll_bar.value_changed.disconnect(_on_scroll_value_changed)
	_scroll_bar = null
	if _scroll != null and is_instance_valid(_scroll):
		if _scroll.resized.is_connected(_on_scroll_resized):
			_scroll.resized.disconnect(_on_scroll_resized)
	if _host != null and is_instance_valid(_host):
		if _host.resized.is_connected(_on_scroll_resized):
			_host.resized.disconnect(_on_scroll_resized)


func _on_scroll_value_changed(_value: float) -> void:
	refresh(false)


func _on_scroll_resized() -> void:
	refresh(false)


func _row_stride() -> float:
	return cell_size.y + float(v_separation)


func _col_stride() -> float:
	return cell_size.x + float(h_separation)


func _total_rows() -> int:
	if _entries.is_empty():
		return 0
	return int(ceil(float(_entries.size()) / float(maxi(1, columns))))


func _content_height() -> float:
	var rows: int = _total_rows()
	if rows <= 0:
		return 0.0
	return cell_size.y * float(rows) + float(v_separation * maxi(0, rows - 1))


func _content_width() -> float:
	var cols: int = maxi(1, columns)
	return cell_size.x * float(cols) + float(h_separation * maxi(0, cols - 1))


func _update_host_min_size() -> void:
	if _host == null:
		return
	_host.custom_minimum_size = Vector2(_content_width(), _content_height())


func _host_offset_in_scroll_content() -> float:
	if _scroll == null or _host == null:
		return 0.0
	var content: Control = _scroll.get_child(0) as Control
	if content == null:
		return 0.0
	return _host.global_position.y - content.global_position.y


func _visible_row_range() -> Vector2i:
	if _scroll == null or _entries.is_empty():
		return Vector2i(-1, -1)
	var row_h: float = _row_stride()
	if row_h <= 0.0:
		return Vector2i(-1, -1)
	var total_rows: int = _total_rows()
	if total_rows <= 0:
		return Vector2i(-1, -1)
	var scroll_top: float = float(_scroll.scroll_vertical)
	var scroll_bottom: float = scroll_top + _scroll.size.y
	var visible_top: float = scroll_top
	var visible_bottom: float = scroll_bottom
	if _mode == BindMode.OUTER_SCROLL:
		var host_y: float = _host_offset_in_scroll_content()
		visible_top = maxf(0.0, scroll_top - host_y)
		visible_bottom = minf(_content_height(), scroll_bottom - host_y)
		if visible_bottom <= 0.0 or visible_top >= _content_height():
			return Vector2i(-1, -1)
	var first_row: int = maxi(0, int(floor(visible_top / row_h)) - buffer_rows)
	var last_row: int = mini(
		total_rows - 1,
		int(ceil(visible_bottom / row_h)) + buffer_rows
	)
	return Vector2i(first_row, last_row)


func _visible_index_range() -> Vector2i:
	var row_range: Vector2i = _visible_row_range()
	if row_range.x < 0:
		return Vector2i(-1, -1)
	var start_index: int = row_range.x * columns
	var end_index: int = mini(_entries.size() - 1, (row_range.y + 1) * columns - 1)
	if start_index >= _entries.size():
		return Vector2i(-1, -1)
	return Vector2i(start_index, maxi(start_index, end_index))


func _sync_cells(start_index: int, end_index: int) -> void:
	var to_remove: Array[int] = []
	for raw_idx in _cells.keys():
		var idx: int = int(raw_idx)
		if idx < start_index or idx > end_index:
			to_remove.append(idx)
	for idx in to_remove:
		_unbind_cell(idx)
	for idx in range(start_index, end_index + 1):
		if idx < 0 or idx >= _entries.size():
			continue
		if _cells.has(idx):
			continue
		var entry: Dictionary = _entries[idx] as Dictionary
		if entry.is_empty():
			continue
		if not _make_cell.is_valid():
			continue
		var cell: Control = _make_cell.call(entry, idx) as Control
		if cell == null:
			continue
		_position_cell(cell, idx)
		_host.add_child(cell)
		_cells[idx] = cell


func _position_cell(cell: Control, index: int) -> void:
	var row: int = int(index / columns)
	var col: int = index % columns
	cell.set_anchors_preset(Control.PRESET_TOP_LEFT)
	cell.position = Vector2(float(col) * _col_stride(), float(row) * _row_stride())
	cell.custom_minimum_size = cell_size
	cell.size = cell_size


func _unbind_cell(index: int) -> void:
	if not _cells.has(index):
		return
	var cell: Control = _cells[index] as Control
	if cell == null:
		_cells.erase(index)
		return
	if _on_cell_unbind.is_valid() and index >= 0 and index < _entries.size():
		var entry: Dictionary = _entries[index] as Dictionary
		_on_cell_unbind.call(entry, index, cell)
	if is_instance_valid(_host) and cell.get_parent() == _host:
		_host.remove_child(cell)
	cell.queue_free()
	_cells.erase(index)


func _clear_cells() -> void:
	var indices: Array = _cells.keys()
	indices.sort()
	for raw_idx in indices:
		_unbind_cell(int(raw_idx))


func _show_empty() -> void:
	if _host == null:
		return
	_clear_cells()
	if _empty_hint != null and is_instance_valid(_empty_hint):
		_empty_hint.visible = true
		_apply_empty_host_min_size()
		return
	if not _make_empty.is_valid():
		return
	_empty_hint = _make_empty.call(_empty_message) as Control
	if _empty_hint == null:
		return
	_host.add_child(_empty_hint)
	_apply_empty_host_min_size()


func _apply_empty_host_min_size() -> void:
	if _host == null:
		return
	var width: float = _content_width()
	if width < cell_size.x:
		width = cell_size.x * float(maxi(1, columns))
	var height: float = cell_size.y
	if _empty_hint != null and is_instance_valid(_empty_hint):
		height = maxf(height, _empty_hint.get_combined_minimum_size().y)
	_host.custom_minimum_size = Vector2(width, height)


func _hide_empty() -> void:
	if _empty_hint != null and is_instance_valid(_empty_hint):
		_empty_hint.visible = false
