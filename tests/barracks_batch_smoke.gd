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
	game.save_path = "user://barracks_batch_smoke.json"
	for unit_id in game.BARRACK_UNIT_IDS:
		game.barracks_unit_unlocks[unit_id] = true
	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(100.0, 0.0), "barracks"))

	if not _check(game._expedition_batch_size_from_modifiers(false, false) == 1 and game._expedition_batch_size_from_modifiers(true, false) == 5 and game._expedition_batch_size_from_modifiers(false, true) == 10 and game._expedition_batch_size_from_modifiers(true, true) == 10, "expedition modifiers should map normal, Shift, Ctrl, and both to 1, 5, 10, and 10"):
		return
	var quote: Dictionary = game._barracks_unit_batch_quote("carrier", 5)
	if not _check(int(quote["amount"]) == 5 and is_equal_approx(float(quote["organic"]), 70.0) and is_equal_approx(float(quote["mineral"]), 2.5) and is_equal_approx(float(quote["build_seconds_each"]), 50.0), "batch quote should scale both costs while retaining per-unit build time"):
		return

	game.organic = 1000.0
	game.mineral = 100.0
	if not _check(game._queue_expedition_spores(barracks_id, "carrier", 5), "funded Shift-sized batch should queue"):
		return
	var jobs: Array = game.cores[barracks_id]["spore_jobs"]
	if not _check(jobs.size() == 5 and is_equal_approx(game.organic, 930.0) and is_equal_approx(game.mineral, 97.5), "five carrier spores should charge exactly five costs"):
		return
	if not _check(jobs.all(func(job): return String(job["unit_type"]) == "carrier" and not bool(job["automatic"])), "every batch job should preserve its explicit unit type and manual flag"):
		return
	jobs[0]["remaining"] = 1.0
	if not _check(not is_equal_approx(float(jobs[1]["remaining"]), 1.0), "batch jobs should be independent dictionaries"):
		return

	jobs.clear()
	game.organic = 69.999
	game.mineral = 100.0
	var resources_before := Vector2(game.organic, game.mineral)
	if not _check(not game._queue_expedition_spores(barracks_id, "carrier", 5) and jobs.is_empty() and Vector2(game.organic, game.mineral).is_equal_approx(resources_before), "underfunded batches should fail without partial costs or jobs"):
		return
	game.organic = 1000.0
	game.mineral = 100.0
	if not _check(game._queue_expedition_spores(barracks_id, "forager", 5) and game._queue_expedition_spores(barracks_id, "forager", 1), "queue setup should create six jobs"):
		return
	resources_before = Vector2(game.organic, game.mineral)
	if not _check(not game._queue_expedition_spores(barracks_id, "carrier", 5) and jobs.size() == 6 and Vector2(game.organic, game.mineral).is_equal_approx(resources_before), "a batch that does not fit the local queue should fail atomically"):
		return

	jobs.clear()
	game.expedition_units.clear()
	for _index in range(game.MAX_EXPEDITION_SPORES - 4):
		game._spawn_expedition_spore(barracks_id, "forager")
	resources_before = Vector2(game.organic, game.mineral)
	if not _check(not game._queue_expedition_spores(barracks_id, "carrier", 5) and jobs.is_empty() and Vector2(game.organic, game.mineral).is_equal_approx(resources_before), "a batch that crosses the global unit cap should fail atomically"):
		return

	game.expedition_units.clear()
	game.organic = 1000.0
	game.mineral = 100.0
	if not _check(game._queue_expedition_spores(barracks_id, "scout", 10) and jobs.size() == 10 and is_equal_approx(game.organic, 940.0) and is_equal_approx(game.mineral, 96.0), "Ctrl-sized batch should fill an empty queue and charge ten scout costs"):
		return
	game._save_game()
	jobs.clear()
	if not _check(game._load_game(), "save containing a ten-unit batch should load"):
		return
	jobs = game.cores[barracks_id]["spore_jobs"]
	if not _check(jobs.size() == 10 and jobs.all(func(job): return String(job["unit_type"]) == "scout"), "all batch jobs should survive save sanitization and load"):
		return
	game._update_barracks_jobs(240.0)
	if not _check(jobs.is_empty() and game.expedition_units.size() == 10, "one large step should finish all ten sequential scout jobs exactly once"):
		return

	game.expedition_units.clear()
	jobs.clear()
	game.cores[barracks_id]["auto_replenish"] = true
	game.cores[barracks_id]["auto_replenish_unit"] = "carrier"
	game.cores[barracks_id]["auto_replenish_target"] = 4
	game._update_auto_replenishment()
	if not _check(jobs.size() == 1 and String(jobs[0]["unit_type"]) == "carrier" and bool(jobs[0]["automatic"]), "auto replenishment should remain a silent single-unit caller of the atomic API"):
		return
	jobs.clear()
	game.cores[barracks_id]["auto_replenish"] = false
	game.organic = 1000.0
	game.mineral = 100.0
	resources_before = Vector2(game.organic, game.mineral)
	if not _check(not game._queue_expedition_spores(barracks_id, "lytic", 5) and jobs.is_empty() and Vector2(game.organic, game.mineral).is_equal_approx(resources_before), "locked specialist batches should fail without side effects"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("BARRACKS_BATCH_OK modifiers=1/5/10 queue=atomic resources=atomic cap=atomic save=10 auto=compatible")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BARRACKS_BATCH_FAIL: " + message)
	quit(1)
	return false
