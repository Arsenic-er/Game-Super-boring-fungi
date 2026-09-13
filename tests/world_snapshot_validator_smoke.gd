extends SceneTree

const Validator = preload("res://scripts/world_snapshot_validator.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const SLOT := "user://world_snapshot_validator_smoke.json"
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_check(Validator.validate({}), "missing optional fields remain valid")
	var legacy := {"cores": [{"x": 0, "y": 0, "jobs": [180.0, 90.5, {"remaining": 12.0}]}], "segments": [{"ax": 0, "ay": 0, "bx": 240, "by": 0}], "fungal_incursion": {"phase": "locked", "has_pos": false, "x": null, "y": null}}
	_check(Validator.validate(legacy), "old numeric DNA queue and unused incursion position survive")
	var current := _current()
	_check(Validator.validate(current), "current full snapshot shapes accepted")
	_check(Validator.validate(JSON.parse_string(JSON.stringify(current))), "current shapes survive JSON number conversion")
	var before := current.duplicate(true)
	Validator.validate(current)
	_check(current == before, "validation never mutates snapshot")
	for field in Validator.ENTITY_NUMBERS:
		_check(not Validator.validate({field: [null]}), field + " rejects null record")
		_check(not Validator.validate({field: [42]}), field + " rejects scalar record")
		_check(not Validator.validate({field: {}}), field + " rejects non-array container")
		_check(Validator.validate({field: [{}]}), field + " permits old record fields handled by restore defaults")
	for value in [NAN, INF, -INF, 1e39, -32768.01, "100", null, true]:
		_check(not Validator.validate({"cores": [{"x": value}]}), "core rejects invalid/overflow coordinate")
		_check(not Validator.validate({"segments": [{"by": value}]}), "segment rejects invalid/overflow coordinate")
		_check(not Validator.validate({"expedition_units": [{"target_y": value}]}), "unit target rejects invalid/overflow coordinate")
		_check(not Validator.validate({"camera_x": value}), "camera rejects invalid/overflow coordinate")
	_check(Validator.validate({"cores": [{"x": 32768.0, "y": -32768.0}]}), "permissive legacy world boundary retained")
	for value in [NAN, INF, "2", null, [], {}]:
		_check(not Validator.validate({"lifetime_organic_absorbed": value}), "optional statistics must remain finite numeric")
		_check(not Validator.validate({"cores": [{"biomass": value}]}), "biomass cannot poison live restoration")
		_check(not Validator.validate({"cores": [{"jobs": [{"remaining": value}]}]}), "DNA job requires finite duration")
		_check(not Validator.validate({"cores": [{"spore_jobs": [{"remaining": value}]}]}), "spore job requires finite duration")
	for value in [null, {}, "jobs", [null], ["90"], [NAN], [[]]]:
		_check(not Validator.validate({"cores": [{"jobs": value}]}), "malformed DNA job shape rejected")
	_check(not Validator.validate({"cores": [{"spore_jobs": [90.0]}]}), "spore jobs have never used legacy numeric format")
	_check(not Validator.validate({"cores": [{"spore_jobs": [{"unit_type": []}]}]}), "job unit type must be text")
	for field in Validator.NUMERIC_CONFIGS + Validator.FLAG_CONFIGS:
		_check(not Validator.validate({field: []}), field + " requires dictionary")
		_check(not Validator.validate({field: {"level": NAN}}), field + " rejects nonfinite values")
		_check(not Validator.validate({field: {"level": {}}}), field + " rejects nested coercions")
	for field in ["diet_order", "discovered_hotspots", "explored_cells"]:
		_check(not Validator.validate({field: {}}), field + " requires array")
		_check(not Validator.validate({field: [null]}), field + " rejects null element")
	_check(not Validator.validate({"fungal_incursion": {"has_pos": true, "x": null}}), "active incursion coordinate is validated")
	_check(not Validator.validate({"founder_spore": []}), "founder requires dictionary")
	_check(not Validator.validate({"rng_state": "invalid"}) and not Validator.validate({"rng_seed": 123}), "bad optional RNG state cannot silently reset sequence")
	var resources: Array = []
	for i in range(3147):
		resources.append({"x": float(i), "y": -float(i), "kind": 0, "initial_amount": 20.0, "amount": 1.25, "phase": 0.1})
	_check(Validator.validate({"resource_catalog": resources, "hotspot_catalog": []}), "full ordinary resource count accepted without truncation")
	if not failures.is_empty():
		for message in failures:
			push_error("WORLD_SNAPSHOT_VALIDATOR_FAIL: " + message)
		quit(1)
		return
	call_deferred("_run_integration")


func _run_integration() -> void:
	SaveStore.remove_slot(SLOT)
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.autosave_enabled = false
	game.splash_active = false
	game.save_path = SLOT
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.main_menu_active = false
	game.game_started = true
	game._damage_core(0, 7.125, "environment_pressure")
	_check(game._save_game() and game._save_game(), "real main commits two valid isolated checkpoints")
	var home: Dictionary = game._capture_world_state()
	var bad: Dictionary = home.duplicate(true)
	bad["cores"] = [null]
	_check(game._parse_save_payload(JSON.stringify(bad)).is_empty(), "real parser rejects null core before restore")
	_check(_write_json(SLOT, bad), "write controlled malformed primary in isolated slot")
	var inspected := SaveStore.inspect(SLOT, Callable(game, "_parse_save_payload"))
	_check(inspected.get("path", "") == SaveStore.backup_path(SLOT), "invalid core primary selects known-good backup")
	_check(game._load_game(true), "real loader restores the backup instead of partially applying null core")
	_check(game.cores.size() == 1 and is_equal_approx(float(game.cores[0]["biomass"]), 92.875) and is_equal_approx(game.organic, float(home["organic"])), "backup preserves original colony and stock")
	game.offline_report_open = false
	game.chapter_report_open = false
	_check(game._campaign_start_mission() and game._save_game(), "create and back up a real active mission envelope")
	var envelope: Dictionary = game._capture_world_state()
	envelope["campaign"] = game.campaign.duplicate(true)
	if envelope["campaign"].get("home_world", {}).is_empty():
		_check(false, "mission must contain a restorable home")
	else:
		var healthy_campaign: Dictionary = game.campaign.duplicate(true)
		envelope["campaign"]["home_world"]["cores"] = [null]
		_check(game._parse_save_payload(JSON.stringify(envelope)).is_empty(), "real parser also rejects null core in archived home")
		_check(_write_json(SLOT, envelope), "write controlled malformed nested home")
		inspected = SaveStore.inspect(SLOT, Callable(game, "_parse_save_payload"))
		_check(inspected.get("path", "") == SaveStore.backup_path(SLOT), "invalid nested home selects valid composite backup")
		_check(game._load_game(true) and game._campaign_active(), "backup reload keeps the active mission rather than treating it as home")
		_check(int(game.campaign.get("serial", -1)) == int(healthy_campaign["serial"]) and int(game.campaign.get("materials", -1)) == int(healthy_campaign["materials"]), "nested fallback preserves attempt identity and reward ledger")
		var restored_home: Dictionary = game.campaign.get("home_world", {})
		_check((restored_home.get("cores", []) as Array).size() == 1 and is_equal_approx(float(restored_home.get("organic", -1.0)), float(home["organic"])), "nested fallback retains original home snapshot")
	_test_guard_restore(game)
	SaveStore.remove_slot(SLOT)
	for player in game.pixel_audio.players:
		player.stop()
	game.pixel_audio.ambient_player.stop()
	game.queue_free()
	await process_frame
	await process_frame
	if not failures.is_empty():
		for message in failures:
			push_error("WORLD_SNAPSHOT_VALIDATOR_FAIL: " + message)
		quit(1)
		return
	print("WORLD_SNAPSHOT_VALIDATOR_OK checks=%d legacy=true bad_entities=true jobs=true finite_coordinates=true configs=true full_catalog=true parser+backup=top+nested guard_pursuit=preserved missing_target=patrol" % checks)
	quit(0)


func _test_guard_restore(game: Node) -> void:
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game._spawn_initial_enemy_fungus()
	game._spawn_expedition_spore(0, "forager")
	if game.enemy_guard_spores.is_empty() or game.expedition_units.is_empty():
		_check(false, "ordinary factories create a real guard and expedition unit")
		return
	var guard_id: int = game.enemy_guard_spores[0]["id"]
	var unit_id: int = game.expedition_units[0]["id"]
	for pursuit in ["chasing", "attacking"]:
		var guard: Dictionary = game.enemy_guard_spores[game._enemy_guard_index_by_id(guard_id)]
		var unit: Dictionary = game.expedition_units[game._expedition_unit_index_by_id(unit_id)]
		unit["pos"] = (guard["pos"] as Vector2) + Vector2(70.0 if pursuit == "chasing" else 1.0, 0.0)
		unit["target_pos"] = unit["pos"]
		guard["target_unit_id"] = -1
		game._update_enemy_guard_spores(0.01)
		_check(guard["state"] == pursuit and int(guard["target_unit_id"]) == unit_id, "real guard AI acquires its " + pursuit + " target")
		var world: Dictionary = game._capture_world_state()
		_check(Validator.validate(world) and not game._parse_save_payload(JSON.stringify(world)).is_empty(), "normal pursuit snapshot passes helper and main parser")
		_check(game._restore_world_state(world), "restore actual " + pursuit + " snapshot")
		var loaded_guard: Dictionary = game.enemy_guard_spores[game._enemy_guard_index_by_id(guard_id)]
		_check(loaded_guard["state"] == pursuit and int(loaded_guard["target_unit_id"]) == unit_id, pursuit + " and live target ID survive capture/restore")
		var missing := world.duplicate(true)
		missing["expedition_units"] = []
		_check(game._restore_world_state(missing), "restore after pursuit target is absent")
		loaded_guard = game.enemy_guard_spores[game._enemy_guard_index_by_id(guard_id)]
		_check(loaded_guard["state"] == "patrol" and int(loaded_guard["target_unit_id"]) == -1, "missing pursuit target safely returns to patrol")
		var dead := world.duplicate(true)
		dead["expedition_units"][0]["biomass"] = 0.0
		_check(game._restore_world_state(dead), "restore snapshot with defeated target")
		loaded_guard = game.enemy_guard_spores[game._enemy_guard_index_by_id(guard_id)]
		_check(loaded_guard["state"] == "patrol" and int(loaded_guard["target_unit_id"]) == -1, "defeated pursuit target safely returns to patrol")
		game._restore_world_state(world)


func _write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var stored := file.store_string(JSON.stringify(data))
	file.close()
	return stored


func _current() -> Dictionary:
	return {
		"cores": [{"x": 120.0, "y": -30.0, "kind": "barracks", "biomass": 99.125, "jobs": [{"remaining": 80.5, "total": 180.0}], "spore_jobs": [{"remaining": 14.0, "total": 20.0, "unit_type": "forager", "automatic": false}]}],
		"segments": [{"ax": 0.0, "ay": 0.0, "bx": 240.0, "by": 0.0, "growth": 0.5, "core_id": 0}],
		"diet_levels": {"bacteria": 1}, "structure_levels": {"branching": 4}, "barracks_unit_unlocks": {"forager": true, "carrier": false},
		"goals_claimed": {"first_hypha": true}, "diet_order": ["bacteria"], "discovered_hotspots": ["anomaly_0_0_0"], "explored_cells": [0, 12],
		"founder_spore": {"active": false, "state": "settled", "x": 0.0, "y": 0.0, "energy": 0.0},
		"fungal_incursion": {"phase": "warning", "has_pos": true, "x": 16000.0, "y": -800.0, "remaining": 30.0, "enemy_id": -1},
		"lifetime_organic_absorbed": 1200.125, "simulation_clocks": {"absorb_clock": 0.125}, "rng_seed": "-9223372036854775808", "rng_state": "9223372036854775807"
	}


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
