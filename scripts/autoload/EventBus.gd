extends Node

signal scene_changed(scene_name: String)
signal battle_started(room_index: int)
signal battle_finished(victory: bool)
signal weapon_obtained(weapon_id: String)
