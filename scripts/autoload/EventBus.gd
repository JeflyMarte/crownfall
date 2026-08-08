extends Node

signal scene_changed(scene_name: String)
signal battle_started(room_index: int)
signal battle_finished(victory: bool)
signal weapon_obtained(weapon_id: String)
signal armor_obtained(armor_id: String)
signal accessory_obtained(accessory_id: String)
