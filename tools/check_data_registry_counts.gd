extends SceneTree

## Usage: godot --headless --path . -s tools/check_data_registry_counts.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await create_timer(0.15).timeout
	var reg: Node = root.get_node_or_null("DataRegistry")
	if reg == null:
		push_error("DataRegistry autoload missing")
		quit(1)
		return
	var dungeons: Array = reg.call("get_all_dungeon_data")
	var helpers: Array = reg.call("get_all_gacha_helper_data")
	var main_n: int = 0
	for x in dungeons:
		if x != null and str(x.route_type) == "main":
			main_n += 1
	var featured: int = 0
	for x in helpers:
		if x != null and int(x.rarity) >= 3:
			featured += 1
	print("DUNGEONS=%d MAIN=%d HELPERS=%d FEATURED_ELIGIBLE=%d" % [
		dungeons.size(), main_n, helpers.size(), featured
	])
	quit(0 if dungeons.size() > 0 and helpers.size() > 0 else 1)
