extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"

@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _label_modifier: Label = $MainScroll/MainVBox/ModifierPanel/ModifierVBox/LabelModifier
@onready var _label_desc: Label = $MainScroll/MainVBox/LabelDesc
@onready var _label_timer: Label = $MainScroll/MainVBox/LabelTimer
@onready var _label_schedule: Label = $MainScroll/MainVBox/LabelSchedule

func _ready() -> void:
	UiTypography.apply_screen_title(_label_title)
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.HOME)
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	$MainScroll/MainVBox/ModifierPanel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	EventSystem.event_updated.connect(_refresh)
	_refresh()

func _refresh() -> void:
	var event_data: Resource = EventSystem.get_active_event()
	if event_data == null:
		SceneRouter.change_scene(HOME_SCENE)
		return
	_label_title.text = "✦ 今週の野外 ✦"
	_label_modifier.text = EventSystem.active_modifier_summary()
	_label_desc.text = str(event_data.description)
	if EventSystem.is_featured_biome_week():
		var biome_id: String = EventSystem.get_featured_biome_id()
		if not biome_id.is_empty():
			var biome: Resource = DataRegistry.get_dungeon_data(biome_id)
			if biome != null:
				_label_desc.text = "%s\n\n注目区域: %s" % [
					str(event_data.description),
					str(biome.display_name),
				]
	_label_timer.text = EventSystem.countdown_text()
	_label_schedule.text = "開催期間: %s" % EventSystem.schedule_text(event_data)

func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
