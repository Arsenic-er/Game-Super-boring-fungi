extends SceneTree


const HORIZONS := [1200.0, 7200.0, 86400.0, 172800.0, 259200.0]
const PREPAID_JOBS := 600


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.splash_active = false
	game.autosave_enabled = false
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	game.founder_spore = {}
	if not _check(game._resource_by_id(-1).is_empty(), "a missing resource target must resolve to no resource"):
		return

	# A controlled throughput fixture, not a prediction of a new player's income:
	# one unupgraded core, two mature feeders, finite deposits and prepaid DNA.
	for absence in HORIZONS:
		_reset_fixture(game, 20000.0, 1000.0)
		game.organic = PREPAID_JOBS * game.DNA_ORGANIC_COST
		game.mineral = PREPAID_JOBS * game.DNA_MINERAL_COST
		for batch in range(PREPAID_JOBS / 10):
			if not _check(game._queue_dna(0, 10), "fixture must prepay every DNA job through the real queue"):
				return
		if not _check(is_zero_approx(game.organic) and is_zero_approx(game.mineral), "queued DNA must charge all nutrients up front"):
			return
		var started := Time.get_ticks_msec()
		game._apply_offline_progress(absence)
		var elapsed_ms := Time.get_ticks_msec() - started
		var settled := minf(absence, 172800.0)
		var expected_organic := minf(20000.0, settled * 0.100)
		var expected_mineral := minf(1000.0, settled * 0.030)
		var expected_dna := mini(PREPAID_JOBS, int(settled / 300.0))
		if not _check(is_equal_approx(game.sim_time, settled) and is_equal_approx(float(game.offline_report["settled_seconds"]), settled), "settlement must cover the requested horizon up to 48 hours"):
			return
		if not _check(bool(game.offline_report["capped"]) == (absence > 172800.0), "exactly 48 hours is not a truncated absence"):
			return
		if not _check(is_equal_approx(game.organic, expected_organic) and is_equal_approx(game.mineral, expected_mineral), "income must continue beyond two hours but stop at the finite deposit size"):
			return
		if not _check(is_equal_approx(game.organic + float(game.resources[0]["amount"]), 20000.0) and is_equal_approx(game.mineral + float(game.resources[1]["amount"]), 1000.0), "absorption must conserve both map resources"):
			return
		if not _check(game.dna == expected_dna and (game.cores[0]["jobs"] as Array).size() == PREPAID_JOBS - expected_dna, "only prepaid jobs may complete, with five minutes per base DNA"):
			return
		var expected_biomass := 50.0 + minf(settled, 7200.0) * 0.005
		if not _check(is_equal_approx(float(game.cores[0]["biomass"]), expected_biomass), "core health simulation must retain its existing two-hour window"):
			return
		if not _check(elapsed_ms < 5000, "controlled long-horizon settlement must finish within five seconds"):
			return
		print("OFFLINE_HORIZON absence_s=%.0f settled_s=%.0f organic=%.3f mineral=%.3f dna=%d elapsed_ms=%d" % [absence, settled, game.organic, game.mineral, game.dna, elapsed_ms])

	_reset_fixture(game, 1.25, 0.125)
	game._apply_offline_progress(259200.0)
	if not _check(is_equal_approx(game.organic, 1.25) and is_equal_approx(game.mineral, 0.125) and game.dna == 0, "scarce deposits must exhaust without generating free DNA"):
		return
	for resource in game.resources:
		if not _check(is_zero_approx(float(resource["amount"])) and not bool(resource["alive"]), "depleted resources must disappear at zero, never become negative"):
			return
	_reset_fixture(game, 10.0, 1.0)
	game._apply_offline_progress(29.0)
	if not _check(not game.offline_report_open and is_zero_approx(game.organic), "sub-threshold absence must not settle or open a report"):
		return
	print("OFFLINE_LONG_HORIZON_OK samples=5 cap_h=48 ecology_h=2 finite_resources=true prepaid_dna=true")
	game.queue_free()
	quit(0)


func _reset_fixture(game: Node, organic_supply: float, mineral_supply: float) -> void:
	game._reset_offline_settlement_state()
	game.cores.clear()
	game.cores.append(game._make_core(Vector2.ZERO))
	game.cores[0]["biomass"] = 50.0
	game.segments.clear()
	game.expedition_units.clear()
	game.bacteria.clear()
	game.enemy_fungi.clear()
	game.enemy_hyphae.clear()
	game.enemy_guard_spores.clear()
	game.ecology_events.clear()
	game.resources.clear()
	game._add_resource(Vector2(30.0, 0.0), 0, organic_supply)
	game._add_resource(Vector2(-30.0, 0.0), 1, mineral_supply)
	game._rebuild_resource_grid()
	game.feeders.clear()
	for resource in game.resources:
		game.feeders.append({"resource_id": int(resource["id"]), "core_id": 0, "a": Vector2.ZERO, "b": resource["pos"], "growth": 1.0, "phase": 0.0})
	game.organic = 0.0
	game.mineral = 0.0
	game.dna = 0
	game.sim_time = 0.0
	game.game_over = false


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("OFFLINE_LONG_HORIZON_FAIL: " + message)
	quit(1)
	return false
