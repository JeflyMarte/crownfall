extends Control

## 章クリア後の部隊員加入会話（P3-JOIN-001）。
## 左立ち絵 / 右吹き出し / 下に次へ・スキップ。

const _Content := preload("res://scripts/roster/RosterJoinContent.gd")
const _RosterJoin := preload("res://scripts/roster/RosterJoin.gd")
const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")

var _lines: Array[String] = []
var _line_idx: int = 0
var _speaker_lbl: Label
var _bubble: Label
var _portrait: TextureRect
var _next_btn: Button


func _ready() -> void:
	var adv_id: String = GameState.pending_roster_join_id
	if adv_id.is_empty():
		SceneRouter.change_scene(_RosterJoin.HOME_SCENE)
		return
	_lines.clear()
	_lines.append(_Content.NINA_BRIDGE)
	for line: String in _Content.get_lines(adv_id):
		_lines.append(line)
	_build_ui(adv_id)
	_refresh_line()


func _build_ui(adventurer_id: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_IntroUiAssets.add_full_bg(self, _IntroUiAssets.BG_NAME, Color(0.05, 0.06, 0.09, 1.0))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var title := Label.new()
	title.text = "隊員加入"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_display(title, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD)
	header.add_child(title)

	var skip_btn := Button.new()
	skip_btn.text = "スキップ"
	skip_btn.custom_minimum_size = Vector2(120, 44)
	UiTypography.apply_button(skip_btn)
	skip_btn.pressed.connect(_finish)
	header.add_child(skip_btn)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	root.add_child(row)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(280, 400)
	_portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var portrait_path: String = _Content.get_portrait_path(adventurer_id)
	var tex: Texture2D = _IntroUiAssets.load_tex(portrait_path)
	if tex == null:
		var def: Variant = GameState.find_base_roster_def(adventurer_id)
		var job_id: String = str(def["job"]) if def is Dictionary else ""
		tex = IconPaths.get_icon_texture(job_id, "chr")
	_portrait.texture = tex
	row.add_child(_portrait)

	var bubble_col := VBoxContainer.new()
	bubble_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble_col.add_theme_constant_override("separation", 12)
	row.add_child(bubble_col)

	_speaker_lbl = Label.new()
	UiTypography.apply_display(_speaker_lbl, 20, UiTypography.COLOR_GOLD)
	bubble_col.add_child(_speaker_lbl)

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.11, 0.16, 0.94)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.62, 0.52, 0.35)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	bubble_col.add_child(panel)

	_bubble = Label.new()
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(_bubble, 22)
	panel.add_child(_bubble)

	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(0, 52)
	UiTypography.apply_button(_next_btn)
	_next_btn.pressed.connect(_on_next)
	root.add_child(_next_btn)


func _refresh_line() -> void:
	if _line_idx < 0 or _line_idx >= _lines.size():
		_finish()
		return
	var speaker: String = "記録官 ニーナ" if _line_idx == 0 else _Content.display_name_for(GameState.pending_roster_join_id)
	_speaker_lbl.text = speaker
	_bubble.text = _lines[_line_idx]
	var last: bool = _line_idx >= _lines.size() - 1
	_next_btn.text = "合流する" if last else "次へ"


func _on_next() -> void:
	_line_idx += 1
	if _line_idx >= _lines.size():
		_finish()
		return
	_refresh_line()


func _finish() -> void:
	_RosterJoin.commit_pending_join()
	SaveManager.save_game()
	SceneRouter.change_scene(_RosterJoin.HOME_SCENE)
