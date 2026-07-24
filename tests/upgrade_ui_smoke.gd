extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if packed == null:
		push_error("UPGRADE_UI_FAIL: main scene did not load")
		quit(1)
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	if not game.splash_active or game.splash_logo == null:
		push_error("UPGRADE_UI_FAIL: splash logo did not load")
		quit(1)
		return
	game.splash_time = 0.45
	game.queue_redraw()
	await process_frame
	await process_frame
	game.splash_time = 2.45
	game.queue_redraw()
	await process_frame
	await process_frame
	game.splash_active = false
	game._start_new_culture()
	game.main_menu_active = true
	game.main_menu_page = "main"
	game.queue_redraw()
	await process_frame
	await process_frame
	game.main_menu_page = "settings"
	game.queue_redraw()
	await process_frame
	await process_frame
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false
	game.upgrade_open = true
	game.upgrade_core_id = 0
	for tab in range(5):
		game.upgrade_tab = tab
		game.queue_redraw()
		await process_frame
		await process_frame
	game.diet_levels["bacteria"] = 1
	game.diet_order.append("bacteria")
	game.upgrade_tab = 1
	game.diet_detail_id = "bacteria"
	game.diet_detail_tab = 0
	game.queue_redraw()
	await process_frame
	await process_frame
	game.diet_detail_tab = 1
	game.queue_redraw()
	await process_frame
	await process_frame
	game.diet_levels["fungi"] = 1
	game.diet_detail_id = "fungi"
	game.queue_redraw()
	await process_frame
	await process_frame
	game.upgrade_open = false
	game.goals_open = true
	game.goal_page = 0
	game.queue_redraw()
	await process_frame
	await process_frame
	game.goal_page = 1
	game.queue_redraw()
	await process_frame
	await process_frame
	game.goals_open = false
	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(120.0, 0.0), "barracks"))
	game._spawn_expedition_spore(barracks_id)
	game.barracks_unit_unlocks["scout"] = true
	game._spawn_expedition_spore(barracks_id, "scout")
	game.selected_expedition_ids = [int(game.expedition_units[0]["id"]), int(game.expedition_units[1]["id"])]
	game._issue_expedition_command(game.world_to_screen(Vector2(180.0, 80.0)))
	game.left_selecting = true
	game.left_dragged = true
	game.selection_start = game.world_to_screen(Vector2(120.0, 0.0)) - Vector2(34.0, 24.0)
	game.selection_current = game.selection_start + Vector2(68.0, 48.0)
	game.queue_redraw()
	await process_frame
	await process_frame
	game.left_selecting = false
	game.left_dragged = false
	game.selected_core = 0
	game.mode = "place_barracks"
	game.queue_redraw()
	await process_frame
	await process_frame
	game.mode = "normal"
	game.game_over = true
	game.queue_redraw()
	await process_frame
	await process_frame
	game.game_over = false
	game.camera_zoom = 0.018
	game.camera_center = Vector2.ZERO
	game.queue_redraw()
	await process_frame
	await process_frame
	var panel: Rect2 = game._upgrade_panel_rect(game.get_viewport_rect().size)
	if panel.size.x < 700.0 or panel.size.y < 450.0:
		push_error("UPGRADE_UI_FAIL: panel is unexpectedly small")
		quit(1)
		return
	print("UPGRADE_UI_OK panel=", panel, " tabs=5 barracks_and_diet_units=rendered fog_and_scout=rendered goal_pages=2 expedition_units=2 dish_zoom=", game.camera_zoom)
	game.queue_free()
	quit(0)
