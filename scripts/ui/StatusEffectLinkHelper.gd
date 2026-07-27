class_name StatusEffectLinkHelper
extends RefCounted

## スキル／装備説明文中の状態異常名をリンク化し、タップで効果を表示する。

## RichText の [url] 内 [color] は効かないことがあるため、外側に [color] を置く。
const LINK_COLOR: Color = UiTypography.COLOR_GOLD
const _POPUP_NAME: String = "StatusEffectPopupOverlay"

## display_name 以外の表記ゆれ → status id
const EXTRA_ALIASES: Dictionary = {
	"激励": "empower",
	"小さな激励": "empower_minor",
	"相棒鼓舞": "empower_pet",
	"重呪": "major_curse",
	"防御低下": "armor_break",
	"防御ダウン": "armor_break",
	"防御Down": "armor_break",
}


## 状態異常の効果説明（プレイヤー向け短文）。
static func effect_summary(status_id: String) -> String:
	var data: Resource = DataRegistry.get_status_effect(status_id)
	if data == null:
		return ""
	var parts: PackedStringArray = PackedStringArray()
	var out_m: float = float(data.outgoing_damage_multiplier)
	if not is_equal_approx(out_m, 1.0):
		var pct: int = int(round((out_m - 1.0) * 100.0))
		parts.append("与ダメ %+d%%" % pct)
	var in_m: float = float(data.incoming_damage_multiplier)
	if not is_equal_approx(in_m, 1.0):
		var pct_in: int = int(round((in_m - 1.0) * 100.0))
		parts.append("被ダメ %+d%%" % pct_in)
	var def_r: float = float(data.defense_reduction) if "defense_reduction" in data else 0.0
	if def_r > 0.001:
		parts.append("相手の防御 −%d%%" % int(round(def_r * 100.0)))
	var skip: float = float(data.skip_action_chance)
	if skip > 0.001:
		if skip >= 0.999:
			parts.append("行動不能")
		else:
			parts.append("行動スキップ 約%d%%" % int(round(skip * 100.0)))
	var interval: float = float(data.interval_multiplier)
	if interval > 1.001:
		parts.append("行動待ちが長くなる")
	var dot_flat: int = int(data.dot_flat)
	var dot_pct: float = float(data.dot_percent_of_attack)
	if dot_flat > 0 or dot_pct > 0.001:
		## P3-UX-STATUS-LEGEND-001: 「刻」はプレイヤー向けに使わない。
		if dot_pct > 0.001:
			parts.append("1秒ごとにダメージが続く")
		else:
			parts.append("1秒ごとにダメージ（%d）" % dot_flat)
	var ticks: int = int(data.duration_ticks)
	if ticks > 0:
		parts.append("しばらく続く")
	var stacks: int = int(data.max_stacks)
	if stacks > 1:
		parts.append("最大 %d 重ね" % stacks)
	if parts.is_empty():
		return "戦闘中に一時的にかかる効果。"
	return "・".join(parts)


## 戦闘右上レジェンド用の主効果1行（P3-UX-STATUS-LEGEND-001）。
static func effect_one_line(status_id: String) -> String:
	var data: Resource = DataRegistry.get_status_effect(status_id)
	if data == null:
		return ""
	var dot_flat: int = int(data.dot_flat)
	var dot_pct: float = float(data.dot_percent_of_attack)
	if dot_flat > 0 or dot_pct > 0.001:
		return "1秒ごとにダメージ"
	var skip: float = float(data.skip_action_chance)
	if skip >= 0.999:
		return "行動不能"
	if skip > 0.001:
		return "行動スキップ 約%d%%" % int(round(skip * 100.0))
	var def_r: float = float(data.defense_reduction) if "defense_reduction" in data else 0.0
	if def_r > 0.001:
		return "相手の防御 −%d%%" % int(round(def_r * 100.0))
	var out_m: float = float(data.outgoing_damage_multiplier)
	if not is_equal_approx(out_m, 1.0):
		return "与ダメ %+d%%" % int(round((out_m - 1.0) * 100.0))
	var in_m: float = float(data.incoming_damage_multiplier)
	if not is_equal_approx(in_m, 1.0):
		return "被ダメ %+d%%" % int(round((in_m - 1.0) * 100.0))
	var interval: float = float(data.interval_multiplier)
	if interval > 1.001:
		return "行動が遅くなる"
	return "一時的な効果"


static func display_name_for(status_id: String) -> String:
	var data: Resource = DataRegistry.get_status_effect(status_id)
	if data != null and str(data.display_name) != "":
		return str(data.display_name)
	return status_id


## プレーン文 → BBCode（状態異常名を url=status:id リンクに）。
static func linkify_bbcode(text: String) -> String:
	if text.is_empty():
		return ""
	var aliases: Array[Dictionary] = _alias_entries()
	if aliases.is_empty():
		return _escape_bbcode(text)
	var out: String = ""
	var i: int = 0
	var n: int = text.length()
	while i < n:
		var matched: bool = false
		for entry: Dictionary in aliases:
			var alias: String = str(entry.get("alias", ""))
			var sid: String = str(entry.get("id", ""))
			if alias.is_empty() or sid.is_empty():
				continue
			var alen: int = alias.length()
			if i + alen > n:
				continue
			if text.substr(i, alen) != alias:
				continue
			out += "[color=#%s][url=status:%s]%s[/url][/color]" % [
				LINK_COLOR.to_html(false),
				sid,
				_escape_bbcode(alias),
			]
			i += alen
			matched = true
			break
		if not matched:
			out += _escape_bbcode(text.substr(i, 1))
			i += 1
	return out


static func make_linked_richtext(
	text: String,
	font_size: int,
	color: Color,
	meta_host: Node
) -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.meta_underlined = true
	rtl.mouse_filter = Control.MOUSE_FILTER_STOP
	## ScrollTouchHelper の PASS 化対象外（状態異常リンクのタップを維持）。
	rtl.set_meta(&"_cf_keep_mouse_stop", true)
	UiTypography.apply_log_rich(rtl, font_size, color)
	## 既定色は本文。リンクは BBCode [color=金] で上書き。
	rtl.parse_bbcode(linkify_bbcode(text))
	var host: Node = meta_host
	rtl.meta_clicked.connect(func(meta: Variant) -> void:
		_on_meta_clicked(host, meta)
	)
	return rtl


static func _on_meta_clicked(host: Node, meta: Variant) -> void:
	var key: String = str(meta)
	if not key.begins_with("status:"):
		return
	var status_id: String = key.substr("status:".length())
	if status_id.is_empty():
		return
	show_effect_popup(host, status_id)


static func show_effect_popup(host: Node, status_id: String) -> void:
	if host == null or not is_instance_valid(host):
		return
	var summary: String = effect_summary(status_id)
	if summary.is_empty():
		return
	var title: String = display_name_for(status_id)
	## 既存ポップを閉じる。
	var existing: Node = host.get_node_or_null(_POPUP_NAME)
	if existing != null:
		existing.queue_free()
	var overlay := Control.new()
	overlay.name = _POPUP_NAME
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 120
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			overlay.queue_free()
		elif event is InputEventScreenTouch and event.pressed:
			overlay.queue_free()
	)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = Vector2(420, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08, 0.96)
	style.border_color = LINK_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var title_l := Label.new()
	title_l.text = title
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(title_l, UiTypography.SIZE_BODY_SMALL, LINK_COLOR)
	vb.add_child(title_l)
	var body_l := Label.new()
	body_l.text = summary
	body_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(body_l, UiTypography.SIZE_BODY_SMALL)
	vb.add_child(body_l)
	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void: overlay.queue_free())
	UiTypography.apply_button(close_btn, false)
	vb.add_child(close_btn)
	host.add_child(overlay)
	host.move_child(overlay, host.get_child_count() - 1)
	AudioManager.play_sfx("ui_click", 0.85, 0.0)


static func _alias_entries() -> Array[Dictionary]:
	var by_alias: Dictionary = {}
	for status_id: String in _all_status_ids():
		var data: Resource = DataRegistry.get_status_effect(status_id)
		if data == null:
			continue
		var dname: String = str(data.display_name).strip_edges()
		if not dname.is_empty():
			by_alias[dname] = status_id
		by_alias[status_id] = status_id
	for alias_v in EXTRA_ALIASES.keys():
		by_alias[str(alias_v)] = str(EXTRA_ALIASES[alias_v])
	var entries: Array[Dictionary] = []
	for alias_v in by_alias.keys():
		entries.append({"alias": str(alias_v), "id": str(by_alias[alias_v])})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("alias", "")).length() > str(b.get("alias", "")).length()
	)
	return entries


static func _all_status_ids() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(Constants.RESOURCE_STATUS_EFFECTS_PATH)
	if dir == null:
		return out
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			out.append(fname.get_basename())
		fname = dir.get_next()
	dir.list_dir_end()
	return out


static func _escape_bbcode(text: String) -> String:
	return text.replace("[", "［").replace("]", "］")
