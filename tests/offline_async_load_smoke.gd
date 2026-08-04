extends SceneTree


const TEST_SAVE_PATH := "user://v047_offline_async_load_smoke.json"
const BACTERIA_COUNT := 420
const FEEDER_COUNT := 28
const ABSENCE_SECONDS := 8400.0
const LOAD_RETURN_BUDGET_MS := 750
const SETTLEMENT_BUDGET_MS := 30000
const MAX_PUMP_FRAMES := 2400

var assertion_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_save()
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game.autosave_enabled = false
	game.save_path = TEST_SAVE_PATH
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	if not _check(is_equal_approx(float(game.OFFLINE_CAP_SECONDS), 7200.0), "offline settlement cap should remain two hours"):
		return

	# Build a deliberately dense but valid save through the real factories and
	# serializer: 420 bacteria, 28 mature feeder hyphae and one active scout.
	game.bacteria.clear()
	for index in range(BACTERIA_COUNT):
		var column := index % 28
		var row := index / 28
		var bacterium: Dictionary = game._make_bacterium(Vector2(-210.0 + float(column) * 15.0, -105.0 + float(row) * 15.0))
		bacterium["stored"] = 0.0
		bacterium["cooldown"] = 100000.0
		bacterium["seek_cooldown"] = float(index % 7) * 0.1
		game.bacteria.append(bacterium)

	game.feeders.clear()
	for resource in game.resources:
		resource["amount"] = 0.0
		resource["alive"] = false
	for index in range(FEEDER_COUNT):
		var resource: Dictionary = game.resources[index]
		resource["amount"] = maxf(20.0, float(resource.get("initial_amount", 20.0)))
		resource["initial_amount"] = float(resource["amount"])
		resource["alive"] = true
		game.feeders.append({
			"resource_id": int(resource["id"]),
			"core_id": 0,
			"a": game.cores[0]["pos"],
			"b": resource["pos"],
			"growth": 1.0,
			"phase": float(index) * 0.17,
		})

	game.expedition_units.clear()
	game.barracks_unit_unlocks["scout"] = true
	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(180.0, 0.0), "barracks"))
	game._spawn_expedition_spore(barracks_id, "scout")
	var scout: Dictionary = game.expedition_units[0]
	scout["state"] = "moving"
	scout["target_kind"] = "ground"
	scout["target_pos"] = Vector2(1200.0, -460.0)
	scout["manual"] = true
	scout["command_until"] = game.sim_time + ABSENCE_SECONDS
	if not _check(game.bacteria.size() == BACTERIA_COUNT and game.feeders.size() == FEEDER_COUNT and game.expedition_units.size() == 1 and String(scout.get("state", "")) == "moving", "fixture should contain 420 bacteria, 28 feeders and one active expedition unit"):
		return

	game._save_game()
	if not _check(FileAccess.file_exists(TEST_SAVE_PATH), "real serializer should create the fixture save"):
		return
	var save_data := _read_json()
	if not _check(save_data is Dictionary and (save_data.get("bacteria", []) as Array).size() == BACTERIA_COUNT and (save_data.get("feeders", []) as Array).size() == FEEDER_COUNT and (save_data.get("expedition_units", []) as Array).size() == 1, "serialized fixture should retain all dense entities"):
		return
	var stale_saved_at := Time.get_unix_time_from_system() - ABSENCE_SECONDS
	save_data["saved_at"] = stale_saved_at
	if not _check(_write_json(save_data), "fixture timestamp should be rewritable"):
		return
	if not _check(Time.get_unix_time_from_system() - float(_read_json().get("saved_at", 0.0)) > float(game.OFFLINE_CAP_SECONDS), "fixture should be older than the two-hour cap"):
		return

	# Contract: true requests asynchronous offline settlement. Hydration may parse
	# the save now, but the expensive simulation must be pumped by later frames.
	var total_started_ms := Time.get_ticks_msec()
	var load_started_ms := Time.get_ticks_msec()
	var loaded: bool = bool(game.call("_load_game", true))
	var load_return_ms := Time.get_ticks_msec() - load_started_ms
	if not _check(loaded, "_load_game(true) should accept and hydrate the dense save"):
		return
	if not _check(load_return_ms <= LOAD_RETURN_BUDGET_MS, "_load_game(true) should return quickly instead of settling two hours synchronously"):
		return
	if not _check(bool(game.get("offline_settlement_active")), "asynchronous settlement should be active immediately after load returns"):
		return
	if not _check(game.bacteria.size() == BACTERIA_COUNT and game.feeders.size() == FEEDER_COUNT and game.expedition_units.size() == 1, "entities should be hydrated before the asynchronous pump begins"):
		return
	var previous_progress: float = float(game.get("offline_settlement_progress"))
	if not _check(previous_progress >= 0.0 and previous_progress < 1.0, "initial asynchronous progress should be a normalized incomplete fraction"):
		return

	var pump_frames := 0
	var progress_monotonic := true
	var saw_intermediate_progress := false
	while bool(game.get("offline_settlement_active")) and pump_frames < MAX_PUMP_FRAMES and Time.get_ticks_msec() - total_started_ms <= SETTLEMENT_BUDGET_MS:
		await process_frame
		pump_frames += 1
		var progress: float = float(game.get("offline_settlement_progress"))
		progress_monotonic = progress_monotonic and progress + 0.000001 >= previous_progress and progress <= 1.000001
		saw_intermediate_progress = saw_intermediate_progress or (progress > 0.000001 and progress < 0.999999)
		previous_progress = progress
	if not _check(pump_frames >= 2, "dense offline settlement should be distributed across multiple rendered frames"):
		return
	if not _check(saw_intermediate_progress, "the frame pump should expose at least one intermediate progress value"):
		return
	if not _check(progress_monotonic, "offline settlement progress should never move backwards"):
		return
	if not _check(not bool(game.get("offline_settlement_active")), "offline settlement should complete within the CI frame budget"):
		return
	var total_elapsed_ms := Time.get_ticks_msec() - total_started_ms
	if not _check(total_elapsed_ms <= SETTLEMENT_BUDGET_MS and pump_frames < MAX_PUMP_FRAMES, "dense two-hour settlement should finish within the CI wall-time budget"):
		return
	if not _check(float(game.get("offline_settlement_progress")) >= 0.999999, "completed settlement should publish progress 1.0"):
		return

	if not _check(game.offline_report_open and not game.offline_report.is_empty(), "completion should open a populated offline report"):
		return
	if not _check(bool(game.offline_report.get("capped", false)) and is_equal_approx(float(game.offline_report.get("settled_seconds", 0.0)), float(game.OFFLINE_CAP_SECONDS)) and float(game.offline_report.get("actual_seconds", 0.0)) > float(game.OFFLINE_CAP_SECONDS), "report should record a capped absence longer than two hours"):
		return
	var settled_save := _read_json()
	if not _check(float(settled_save.get("saved_at", 0.0)) > stale_saved_at + float(game.OFFLINE_CAP_SECONDS) and is_equal_approx(float(settled_save.get("organic", -1.0)), float(game.organic)) and is_equal_approx(float(settled_save.get("mineral", -1.0)), float(game.mineral)) and int(settled_save.get("dna", -1)) == int(game.dna), "completion should checkpoint the settled balances and a fresh timestamp"):
		return

	# A second immediate load must see the refreshed checkpoint, skip the pump and
	# preserve both balances and lifetime counters exactly.
	game._close_offline_report()
	var snapshot := {
		"organic": float(game.organic),
		"mineral": float(game.mineral),
		"dna": int(game.dna),
		"births": int(game.lifetime_bacteria_births),
		"consumed": int(game.lifetime_bacteria_consumed),
		"returned_organic": float(game.lifetime_expedition_organic_returned),
		"returned_mineral": float(game.lifetime_expedition_mineral_returned),
	}
	var reload_started_ms := Time.get_ticks_msec()
	var reloaded: bool = bool(game.call("_load_game", true))
	var reload_return_ms := Time.get_ticks_msec() - reload_started_ms
	if not _check(reloaded and reload_return_ms <= LOAD_RETURN_BUDGET_MS, "immediate asynchronous reload should return quickly"):
		return
	for unused in range(3):
		await process_frame
	if not _check(not bool(game.get("offline_settlement_active")) and not game.offline_report_open, "immediate reload should not start or report another settlement"):
		return
	if not _check(is_equal_approx(float(game.organic), float(snapshot["organic"])) and is_equal_approx(float(game.mineral), float(snapshot["mineral"])) and int(game.dna) == int(snapshot["dna"]), "immediate reload should not duplicate offline balances"):
		return
	if not _check(int(game.lifetime_bacteria_births) == int(snapshot["births"]) and int(game.lifetime_bacteria_consumed) == int(snapshot["consumed"]) and is_equal_approx(float(game.lifetime_expedition_organic_returned), float(snapshot["returned_organic"])) and is_equal_approx(float(game.lifetime_expedition_mineral_returned), float(snapshot["returned_mineral"])), "immediate reload should not duplicate lifetime settlement counters"):
		return

	_remove_save()
	print("V047_OFFLINE_ASYNC_LOAD_OK assertions=%d load_ms=%d total_ms=%d pump_frames=%d bacteria=%d feeders=%d" % [assertion_count, load_return_ms, total_elapsed_ms, pump_frames, BACTERIA_COUNT, FEEDER_COUNT])
	game.queue_free()
	quit(0)


func _read_json() -> Dictionary:
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _write_json(data: Dictionary) -> bool:
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	return true


func _remove_save() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))


func _check(condition: bool, message: String) -> bool:
	assertion_count += 1
	if condition:
		return true
	push_error("V047_OFFLINE_ASYNC_LOAD_FAIL[%d]: %s" % [assertion_count, message])
	_remove_save()
	quit(1)
	return false
