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
	_label_title.text = str(event_data.title)
	_label_modifier.text = EventSystem.active_modifier_summary()
	_label_desc.text = str(event_data.description)
	_label_timer.text = EventSystem.countdown_text()
	_label_schedule.text = "開催期間: %s" % EventSystem.schedule_text(event_data)

func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
