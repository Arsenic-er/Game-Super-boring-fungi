extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false
	game.save_path = "user://barracks_command_smoke.json"
	game.organic = 10000.0
	game.mineral = 1000.0
	for unit_id in game.BARRACK_UNIT_IDS:
		game.barracks_unit_unlocks[unit_id] = true
	game.diet_levels["bacteria"] = 1
	game.diet_unit_unlocks["lytic"] = true

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(100.0, 0.0), "barracks"))
	for unit_type in ["forager", "carrier", "scout"]:
		game.cores[barracks_id]["production_unit"] = unit_type
		if not _check(game._queue_expedition_spore(barracks_id), "mixed production job should enter the queue"):
			return
	var jobs: Array = game.cores[barracks_id]["spore_jobs"]
	if not _check(jobs.size() == 3 and String(jobs[0]["unit_type"]) == "forager" and String(jobs[1]["unit_type"]) == "carrier" and String(jobs[2]["unit_type"]) == "scout", "mixed queue should preserve order and unit type"):
		return
	game._update_barracks_jobs(200.0)
	if not _check(game.expedition_units.size() == 3 and String(game.expedition_units[0]["unit_type"]) == "forager" and String(game.expedition_units[2]["unit_type"]) == "scout", "queued units should finish in order"):
		return

	var requested_rally := Vector2(1000.0, 0.0)
	game._set_barracks_rally(barracks_id, requested_rally)
	var rally: Vector2 = game.cores[barracks_id]["rally_point"]
	if not _check(is_equal_approx(rally.distance_to(game.cores[barracks_id]["pos"]), game.BARRACKS_RALLY_RADIUS), "rally point should be clamped to the safe operating radius"):
		return
	game._spawn_expedition_spore(barracks_id, "forager")
	var rallied_unit: Dictionary = game.expedition_units.back()
	if not _check(String(rallied_unit["state"]) == "moving" and bool(rallied_unit["manual"]) and (rallied_unit["target_pos"] as Vector2).is_equal_approx(rally), "new unit should automatically move toward the rally point"):
		return
	game._update_expedition_units(20.0, false)
	if not _check(String(game.expedition_units.back()["state"]) == "guarding", "rallied unit should guard after reaching its destination"):
		return

	game.cores[barracks_id]["spore_jobs"] = []
	game.expedition_units.clear()
	game.cores[barracks_id]["production_unit"] = "carrier"
	game._toggle_barracks_auto(barracks_id)
	for i in range(5):
		game._update_auto_replenishment()
	jobs = game.cores[barracks_id]["spore_jobs"]
	if not _check(jobs.size() == 4 and String(jobs[0]["unit_type"]) == "carrier" and game._barracks_unit_count(barracks_id, "carrier", true) == 4, "auto replenish should fill only the locked unit type to its target"):
		return
	game._update_auto_replenishment()
	if not _check((game.cores[barracks_id]["spore_jobs"] as Array).size() == 4, "auto replenish should not duplicate orders beyond its target"):
		return
	game.cores[barracks_id]["production_unit"] = "scout"
	game._cycle_barracks_unit(barracks_id)
	if not _check(String(game.cores[barracks_id]["auto_replenish_unit"]) == "carrier", "cycling manual production should not silently change the auto replenish unit"):
		return
	game.cores[barracks_id]["spore_jobs"] = []
	game.expedition_units.clear()
	game.organic = 0.0
	game.mineral = 0.0
	game._update_auto_replenishment()
	if not _check((game.cores[barracks_id]["spore_jobs"] as Array).is_empty() and game.organic >= 0.0 and game.mineral >= 0.0, "resource-starved auto replenish should wait silently without creating debt"):
		return
	game.cores[barracks_id]["auto_replenish"] = false
	game.organic = 10000.0
	game.mineral = 1000.0
	for i in range(game.MAX_EXPEDITION_SPORES):
		game._spawn_expedition_spore(barracks_id, "forager")
	if not _check(not game._queue_expedition_spore(barracks_id) and game.expedition_units.size() == game.MAX_EXPEDITION_SPORES and (game.cores[barracks_id]["spore_jobs"] as Array).is_empty(), "active plus queued expedition units should never exceed the global cap"):
		return

	game.cores[barracks_id]["spore_jobs"] = []
	game.expedition_units.clear()
	game._spawn_expedition_spore(barracks_id, "forager")
	game._spawn_expedition_spore(barracks_id, "scout")
	game.expedition_units[0]["pos"] = Vector2(80.0, 20.0)
	game.expedition_units[1]["pos"] = Vector2(120.0, 20.0)
	game._select_units_by_filter("scout")
	if not _check(game.selected_expedition_ids.size() == 1 and int(game.selected_expedition_ids[0]) == int(game.expedition_units[1]["id"]), "scout filter should select only scout units"):
		return
	game.unit_selection_filter = "forager"
	var top_left: Vector2 = game.world_to_screen(Vector2(60.0, 0.0))
	var bottom_right: Vector2 = game.world_to_screen(Vector2(140.0, 40.0))
	game._select_expedition_box(bottom_right, top_left)
	if not _check(game.selected_expedition_ids.size() == 1 and int(game.selected_expedition_ids[0]) == int(game.expedition_units[0]["id"]), "reverse drag selection should respect the active unit filter"):
		return

	game.cores[barracks_id]["rally_enabled"] = true
	game.cores[barracks_id]["rally_point"] = Vector2(180.0, 30.0)
	game.cores[barracks_id]["auto_replenish"] = true
	game.cores[barracks_id]["auto_replenish_unit"] = "scout"
	game.cores[barracks_id]["auto_replenish_target"] = 8
	game._save_game()
	game.cores[barracks_id]["rally_enabled"] = false
	game.cores[barracks_id]["auto_replenish"] = false
	if not _check(game._load_game(), "new barracks save should load"):
		return
	if not _check(bool(game.cores[barracks_id]["rally_enabled"]) and (game.cores[barracks_id]["rally_point"] as Vector2).is_equal_approx(Vector2(180.0, 30.0)), "rally state should survive save and load"):
		return
	if not _check(bool(game.cores[barracks_id]["auto_replenish"]) and String(game.cores[barracks_id]["auto_replenish_unit"]) == "scout" and int(game.cores[barracks_id]["auto_replenish_target"]) == 8, "auto replenish settings should survive save and load"):
		return

	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	for core_item in legacy["cores"]:
		core_item.erase("rally_enabled")
		core_item.erase("rally_x")
		core_item.erase("rally_y")
		core_item.erase("auto_replenish")
		core_item.erase("auto_replenish_unit")
		core_item.erase("auto_replenish_target")
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game(), "v0.20-style save without new barracks fields should load"):
		return
	if not _check(not bool(game.cores[barracks_id]["rally_enabled"]) and not bool(game.cores[barracks_id]["auto_replenish"]) and int(game.cores[barracks_id]["auto_replenish_target"]) == 4, "legacy save should receive safe disabled defaults"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("BARRACKS_COMMAND_OK queue=3 rally_radius=", game.BARRACKS_RALLY_RADIUS, " filters=11 save=compatible")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BARRACKS_COMMAND_FAIL: " + message)
	quit(1)
	return false
