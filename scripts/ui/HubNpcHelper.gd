class_name HubNpcHelper
extends RefCounted

## 拠点 NPC 最小台詞（P3-LORE-003）。`world/08_SeekersGuild §14` に基づく1行表示。

const HINT_BY_ENTRY: Dictionary = {
	"codex": {"npc": "ニーナ", "line": "新しい発見があるなら、図鑑の空白を埋めてくれ。"},
}

const SCENE_TO_ENTRY: Dictionary = {
	"res://scenes/codex/CodexScene.tscn": "codex",
}

static func queue_hint(entry_id: String) -> void:
	var hint: Dictionary = HINT_BY_ENTRY.get(entry_id, {})
	if hint.is_empty():
		return
	GameState.hub_npc_hint = hint.duplicate()

static func queue_hint_for_scene(scene_path: String) -> void:
	var entry_id: String = str(SCENE_TO_ENTRY.get(scene_path, ""))
	if entry_id.is_empty():
		return
	queue_hint(entry_id)

static func format_hint(hint: Dictionary) -> String:
	if hint.is_empty():
		return ""
	var npc: String = str(hint.get("npc", ""))
	var line: String = str(hint.get("line", ""))
	if npc.is_empty() or line.is_empty():
		return ""
	return "【%s】「%s」" % [npc, line]

static func consume_hint() -> Dictionary:
	var hint: Dictionary = GameState.hub_npc_hint.duplicate()
	GameState.hub_npc_hint = {}
	return hint

static func show_pending_banner(scene_root: Control) -> void:
	if scene_root == null:
		return
	var existing: Node = scene_root.get_node_or_null("HubNpcBanner")
	if existing != null:
		existing.queue_free()
	var hint: Dictionary = consume_hint()
	if hint.is_empty():
		return
	var banner := PanelContainer.new()
	banner.name = "HubNpcBanner"
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banner.offset_left = 12.0
	banner.offset_top = 92.0
	banner.offset_right = -12.0
	banner.offset_bottom = 132.0
	var label := Label.new()
	label.text = format_hint(hint)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(label, UiTypography.COLOR_SUB)
	banner.add_child(label)
	scene_root.add_child(banner)
