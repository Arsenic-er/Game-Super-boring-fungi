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
	game.barracks_unit_unlocks["scout"] = true
	game.scout_upgrade_levels["vision"] = 2
	game.scout_upgrade_levels["speed"] = 1
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
	game.goal_page = 2
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
	game.organic = 1000.0
	game.mineral = 100.0
	game.cores[barracks_id]["production_unit"] = "scout"
	game._queue_expedition_spore(barracks_id)
	game.cores[barracks_id]["auto_replenish"] = true
	game.cores[barracks_id]["auto_replenish_unit"] = "scout"
	game.cores[barracks_id]["rally_enabled"] = true
	game.cores[barracks_id]["rally_point"] = Vector2(220.0, 70.0)
	game.selected_core = barracks_id
	game.show_status = true
	game.queue_redraw()
	await process_frame
	await process_frame
	var status_panel: Rect2 = game._status_panel_rect()
	if status_panel.size.y < 400.0 or not status_panel.encloses(game._barracks_auto_button_rect()) or not status_panel.encloses(game._barracks_rally_button_rect()):
		push_error("UPGRADE_UI_FAIL: expanded barracks panel must contain queue and command buttons")
		quit(1)
		return
	if status_panel.intersects(game._upgrade_hud_rect()) or status_panel.intersects(game._goals_hud_rect()):
		push_error("UPGRADE_UI_FAIL: barracks status panel must not cover global upgrade or goals buttons")
		quit(1)
		return
	var filter_rects: Array = game._unit_filter_rects()
	if filter_rects.size() != 6 or (filter_rects.back()["rect"] as Rect2).end.x >= game._minimap_rect().position.x:
		push_error("UPGRADE_UI_FAIL: six unit filters should fit between the resource bar and minimap")
		quit(1)
		return
	game.show_status = false
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
	game.ecology_events = [{
		"id": 1,
		"type": "bloom",
		"pos": Vector2(220.0, -80.0),
		"radius": game.ECOLOGY_BLOOM_RADIUS,
		"phase": "warning",
		"remaining": 31.0,
		"anchor_core_id": 0,
		"spawned": 0
	}]
	game.ecology_banner_title = "生态预警：局部细菌暴发"
	game.ecology_banner_detail = "准备裂菌孢子、抗生素或修复储备。"
	game.ecology_banner_time = 5.0
	game.queue_redraw()
	await process_frame
	await process_frame
	var ecology_hud: Rect2 = game._ecology_event_hud_rect()
	if ecology_hud.position.y <= game._minimap_rect().end.y:
		push_error("UPGRADE_UI_FAIL: ecology event card must remain below the minimap")
		quit(1)
		return
	game._handle_left_click(ecology_hud.get_center())
	if not game.camera_center.is_equal_approx(Vector2(220.0, -80.0)):
		push_error("UPGRADE_UI_FAIL: clicking the ecology event card should focus its world position")
		quit(1)
		return
	game.ecology_events.clear()
	game.ecology_banner_time = 0.0
	game.offline_report = {
		"actual_seconds": 10800.0,
		"settled_seconds": 7200.0,
		"capped": true,
		"absorbed_organic": 12.345,
		"absorbed_mineral": 0.678,
		"returned_organic": 4.5,
		"returned_mineral": 0.25,
		"organic_delta": 16.845,
		"mineral_delta": 0.928,
		"dna_completed": 2,
		"units_built": 3,
		"explored_cells": 8,
		"explored_percent": 0.21,
		"hotspots": 1,
		"bacteria_births": 2,
		"bacteria_consumed": 4,
		"biomass_delta": -0.125,
		"living_cores_before": 2,
		"living_cores_after": 2
	}
	game.offline_report_open = true
	game.queue_redraw()
	await process_frame
	await process_frame
	var report_panel: Rect2 = game._offline_report_panel_rect(game.get_viewport_rect().size)
	var report_button: Rect2 = game._offline_report_button_rect(game.get_viewport_rect().size)
	if not report_panel.encloses(report_button):
		push_error("UPGRADE_UI_FAIL: offline report button must stay inside its modal panel")
		quit(1)
		return
	game._close_offline_report()
	var panel: Rect2 = game._upgrade_panel_rect(game.get_viewport_rect().size)
	if panel.size.x < 700.0 or panel.size.y < 450.0:
		push_error("UPGRADE_UI_FAIL: panel is unexpectedly small")
		quit(1)
		return
	print("UPGRADE_UI_OK panel=", panel, " tabs=5 barracks_queue=rendered rally=rendered filters=6 discovery_banner=rendered ecology_event=rendered offline_report=rendered goal_pages=3 expedition_units=2 dish_zoom=", game.camera_zoom)
	game.queue_free()
	quit(0)
