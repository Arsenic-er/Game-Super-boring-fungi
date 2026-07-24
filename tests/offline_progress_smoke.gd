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
	game.save_path = "user://offline_progress_test_save.json"
	var test_save_path := ProjectSettings.globalize_path(game.save_path)
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(test_save_path)

	if not _check(is_equal_approx(game.OFFLINE_CAP_SECONDS, 7200.0), "Offline progress must be capped at two hours"):
		return
	game.bacteria.clear()
	for resource in game.resources:
		resource["alive"] = false
		resource["amount"] = 0.0
	var source: Dictionary = game.resources[0]
	source["pos"] = Vector2(30.0, 0.0)
	source["amount"] = 50.0
	source["initial_amount"] = 50.0
	source["alive"] = true
	game.feeders = [{
		"resource_id": int(source["id"]),
		"core_id": 0,
		"a": Vector2.ZERO,
		"b": source["pos"],
		"growth": 1.0,
		"phase": 0.0
	}]
	game.cores[0]["jobs"] = [{"remaining": 10.0, "total": 10.0}]
	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(180.0, 0.0), "barracks"))
	game.cores[barracks_id]["spore_jobs"] = [{"remaining": 10.0, "total": 10.0, "unit_type": "scout"}]
	game._spawn_expedition_spore(barracks_id, "scout")
	game._spawn_expedition_spore(barracks_id, "carrier")
	var carrier: Dictionary = game.expedition_units[1]
	carrier["pos"] = game.cores[barracks_id]["pos"]
	carrier["state"] = "returning"
	carrier["cargo_organic"] = 2.0
	carrier["cargo_mineral"] = 0.2
	var explored_before: int = game.explored_cells.size()
	var units_before: int = game.expedition_units.size()
	var organic_before: float = game.organic
	var mineral_before: float = game.mineral
	var source_before: float = float(source["amount"])
	game._apply_offline_progress(60.0, 60.0)
	if not _check(game.offline_report_open, "A one-minute absence should open the settlement report"):
		return
	if not _check(is_equal_approx(source_before - float(source["amount"]), 6.0) and is_equal_approx(float(game.offline_report["absorbed_organic"]), 6.0), "A mature feeder must consume exactly its real source amount during offline progress"):
		return
	if not _check(is_equal_approx(game.organic - organic_before, 8.0) and is_equal_approx(game.mineral - mineral_before, 0.2), "Offline balances must equal feeder absorption plus cargo actually returned home"):
		return
	if not _check(int(game.offline_report["dna_completed"]) == 1 and game.dna == 1, "Only queued DNA work should finish offline"):
		return
	if not _check(int(game.offline_report["units_built"]) == 1 and game.expedition_units.size() == units_before + 1, "Queued barracks production should finish offline"):
		return
	if not _check(int(game.offline_report["explored_cells"]) > 0 and game.explored_cells.size() > explored_before, "Scout spores should reveal real exploration cells offline"):
		return
	var paused_sim_time: float = game.sim_time
	game._process(1.0)
	if not _check(is_equal_approx(game.sim_time, paused_sim_time), "The simulation must pause while the offline report is open"):
		return
	game._close_offline_report()
	if not _check(not game.offline_report_open, "The report close action should resume access to the culture"):
		return

	game.feeders.clear()
	game.expedition_units.clear()
	for resource in game.resources:
		resource["alive"] = false
		resource["amount"] = 0.0
	game.cores[0]["jobs"] = []
	game.cores[barracks_id]["spore_jobs"] = []
	var cap_started := Time.get_ticks_msec()
	game._apply_offline_progress(game.OFFLINE_CAP_SECONDS, 172800.0)
	var cap_elapsed_ms := Time.get_ticks_msec() - cap_started
	if not _check(bool(game.offline_report["capped"]) and is_equal_approx(float(game.offline_report["settled_seconds"]), 7200.0), "A 48-hour absence must settle exactly two hours and mark the report as capped"):
		return
	if not _check(cap_elapsed_ms < 5000, "The worst-case two-hour settlement should finish within five seconds in headless tests"):
		return
	game._close_offline_report()

	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false
	game.save_path = "user://offline_progress_test_save.json"
	game.bacteria.clear()
	for resource in game.resources:
		resource["alive"] = false
		resource["amount"] = 0.0
	source = game.resources[0]
	source["pos"] = Vector2(30.0, 0.0)
	source["amount"] = 50.0
	source["initial_amount"] = 50.0
	source["alive"] = true
	game.feeders = [{
		"resource_id": int(source["id"]),
		"core_id": 0,
		"a": Vector2.ZERO,
		"b": source["pos"],
		"growth": 1.0,
		"phase": 0.0
	}]
	game._save_game()
	var save_file := FileAccess.open(game.save_path, FileAccess.READ)
	var save_data: Dictionary = JSON.parse_string(save_file.get_as_text())
	save_file.close()
	save_data["saved_at"] = Time.get_unix_time_from_system() - 60.0
	save_file = FileAccess.open(game.save_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(save_data))
	save_file.close()
	if not _check(game._load_game() and game.offline_report_open, "Loading a one-minute-old v0.18-compatible save should settle and report offline progress"):
		return
	var balance_after_first_load: float = game.organic
	game._close_offline_report()
	if not _check(game._load_game(), "The checkpointed save should remain loadable"):
		return
	if not _check(not game.offline_report_open and is_equal_approx(game.organic, balance_after_first_load), "Immediate reload after settlement must not grant the same offline resources twice"):
		return

	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(test_save_path)
	print("OFFLINE_PROGRESS_OK organic=", "%.3f" % game.organic, " cap_ms=", cap_elapsed_ms, " explored=", game.explored_cells.size())
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("OFFLINE_PROGRESS_FAIL: " + message)
	quit(1)
	return false
