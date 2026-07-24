extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "Main scene must load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false
	game.save_path = "user://fog_exploration_test_save.json"
	var test_save_path := ProjectSettings.globalize_path(game.save_path)
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(test_save_path)

	if not _check(game._is_world_explored(Vector2.ZERO), "The first spore core must reveal the starting cells"):
		return
	if not _check(not game._is_world_explored(Vector2(9000.0, -7000.0)), "Distant resource regions must begin hidden"):
		return
	if not _check(game._explored_fraction() > 0.0 and game._explored_fraction() < 0.10, "Initial exploration should cover only a small portion of the dish"):
		return

	game.dna = 20
	game._purchase_barracks_unit("scout")
	if not _check(game.dna == 15 and bool(game.barracks_unit_unlocks["scout"]), "Scout spores should unlock for 5 DNA"):
		return
	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(320.0, 0.0), "barracks"))
	game.cores[barracks_id]["production_unit"] = "scout"
	game.organic = 100.0
	game.mineral = 10.0
	game._queue_expedition_spore(barracks_id)
	var jobs: Array = game.cores[barracks_id]["spore_jobs"]
	if not _check(jobs.size() == 1 and is_equal_approx(float(jobs[0]["total"]), 24.0) and is_equal_approx(game.organic, 94.0) and is_equal_approx(game.mineral, 9.6), "Scout production should use its 24-second, 6-organic, 0.400-mineral recipe"):
		return
	game._update_barracks_jobs(24.1)
	if not _check(game.expedition_units.size() == 1 and String(game.expedition_units[0]["unit_type"]) == "scout", "A completed scout job should spawn the scout unit"):
		return

	var scout: Dictionary = game.expedition_units[0]
	game.explored_cells.clear()
	game._reveal_exploration(Vector2.ZERO, game.CORE_REVEAL_RADIUS)
	scout["pos"] = Vector2(320.0, 0.0)
	scout["state"] = "idle"
	scout["manual"] = false
	game._acquire_expedition_target(scout)
	if not _check(String(scout["state"]) == "moving" and String(scout["target_kind"]) == "ground", "An idle scout should automatically seek a nearby unexplored cell"):
		return
	var target: Vector2 = scout["target_pos"]
	if not _check(not game._is_world_explored(target) and game._distance_to_colony(target) <= game.SCOUT_OPERATING_RADIUS + 0.01, "Automatic scout targets must be hidden and remain within colony range"):
		return
	scout["pos"] = target
	game._update_exploration()
	if not _check(game._is_world_explored(target), "Moving a scout into fog should permanently reveal that area"):
		return

	var saved_cells: int = game.explored_cells.size()
	game._save_game()
	game.explored_cells.clear()
	if not _check(game._load_game(), "The exploration save should load"):
		return
	if not _check(game.explored_cells.size() == saved_cells and game._is_world_explored(target), "Explored cells should survive a save/load round trip"):
		return

	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(test_save_path)
	print("FOG_EXPLORATION_OK cells=", game.explored_cells.size(), " explored_percent=", "%.2f" % (game._explored_fraction() * 100.0), " scout_target=", target)
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FOG_EXPLORATION_FAIL: " + message)
	quit(1)
	return false
