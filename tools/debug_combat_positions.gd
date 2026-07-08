extends SceneTree

## 戦闘中スプライトと HP バーの座標をダンプ（Cursor デバッグ用）。
## 実行: godot --path . -s tools/debug_combat_positions.gd

func _init() -> void:
	call_deferred("_run")

func _wait_frames(n: int) -> void:
	for _i in n:
		await process_frame

func _run() -> void:
	var gs: Node = root.get_node("/root/GameState")
	gs.set("current_dungeon_id", "mourngate")
	change_scene_to_file("res://scenes/dungeon/DungeonScene.tscn")
	# 潜入イントロ + 最初の戦闘まで待機
	for _attempt in 120:
		await _wait_frames(10)
		var scene: Node = current_scene
		if scene == null:
			continue
		var cc: Node = scene.get_node_or_null("CombatController")
		if cc != null and bool(cc.get("is_in_combat")):
			_dump_positions(scene as Node)
			quit(0)
			return
	push_error("[debug_combat_positions] combat not reached in time")
	quit(1)

func _dump_positions(scene: Node) -> void:
	print("=== combat position dump ===")
	var bf: Control = scene.get_node("MainVBox/BattlefieldArea")
	var host: Node2D = bf.get_node_or_null("CombatSprites")
	print("BattlefieldArea rect: pos=%s size=%s global=%s" % [bf.position, bf.size, bf.get_global_rect()])
	if host != null:
		print("CombatSprites global_pos=%s" % host.global_position)
	for i in 4:
		var spr: AnimatedSprite2D = host.get_node_or_null("ChrSprite%d" % i) if host != null else null
		if spr == null:
			spr = scene.get_node_or_null("ChrSprite%d" % i)
		if spr == null or not spr.visible:
			continue
		var bar: ProgressBar = scene.get_node("HpBarChr%d" % i)
		var spr_global: Vector2 = spr.global_position
		var bar_center: Vector2 = Vector2(
			(bar.offset_left + bar.offset_right) * 0.5,
			(bar.offset_top + bar.offset_bottom) * 0.5
		)
		var delta: Vector2 = bar_center - spr_global
		print(
			"Chr%d local=%s global=%s | bar_center=%s delta(bar-global)=%s visible=%s"
			% [i, spr.position, spr_global, bar_center, delta, bar.visible]
		)
	var enemy: AnimatedSprite2D = null
	if host != null:
		enemy = host.get_node_or_null("EnemySprite") as AnimatedSprite2D
	if enemy == null:
		enemy = scene.get_node_or_null("EnemySprite") as AnimatedSprite2D
	if enemy != null and enemy.visible:
		var ebar: ProgressBar = scene.get_node("HpBarEnemy")
		var e_global: Vector2 = enemy.global_position
		var e_bar_center: Vector2 = Vector2(
			(ebar.offset_left + ebar.offset_right) * 0.5,
			(ebar.offset_top + ebar.offset_bottom) * 0.5
		)
		print(
			"Enemy local=%s global=%s | bar_center=%s delta=%s"
			% [enemy.position, e_global, e_bar_center, e_bar_center - e_global]
		)
