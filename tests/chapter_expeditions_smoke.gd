extends SceneTree

# Deliberately injected fixtures test validation and objective boundaries.
# Economic playability is tested separately by chapter_expeditions_normal_route.
const SnapshotValidator = preload("res://scripts/world_snapshot_validator.gd")
const NAMES := ["SubstrateRace", "LostNetwork", "ToxicFrontier", "BoundaryCounterattack"]
const IDS := ["substrate_race", "lost_network", "toxic_frontier", "boundary_counterattack"]
var game: Node
var failed := false
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.autosave_enabled = false
	game.developer_mode_enabled = false
	game.splash_active = false
	game.main_menu_active = false
	for i in range(IDS.size()):
		_fresh(i)
		var scene = game.active_world
		var state: Dictionary = scene.runtime.data["mission_state"]
		_check(scene.validate_definition() and scene.validate_mission_state(state), "every independent authored scene has valid initial state")
		_check(scene.validate_mission_state(JSON.parse_string(JSON.stringify(state))), "mission state survives JSON round trip")
		_check(not scene.validate_mission_state({}), "missing mission state cannot reset a mission in progress")
		var fog_before: Dictionary = game.explored_cells.duplicate(true)
		var markers: Array[Dictionary] = scene.mission_markers(game)
		var notes: Array[Dictionary] = scene.mission_notes(game)
		_check(not notes.is_empty(), "every expedition supplies player-facing mission guidance")
		_check(markers.size() == (2 if i == 0 else (3 if i == 1 else 0)), "contested and rescue objectives expose all authored locations")
		for marker in markers:
			_check(marker["pos"] is Vector2 and marker["pos"].is_finite() and float(marker["radius"]) > 0.0 and not String(marker["key"]).is_empty(), "objective marker has a finite position and visible boundary")
		_check(game.explored_cells == fog_before, "intelligence markers do not reveal resources or enemies through fog")
		var corrupt := state.duplicate(true)
		corrupt["mission_id"] = "remote_pantry"
		_check(not scene.validate_mission_state(corrupt), "cross-mission state rejected")
		corrupt = state.duplicate(true)
		corrupt["started"] = 1
		_check(not scene.validate_mission_state(corrupt), "wrong flag types rejected")
		game.organic = 100000.0
		game.mineral = 100000.0
		_check(not scene.mission_ready(game), "stock balance is not mission objective progress")
		var signature := _signature()
		_fresh(i)
		_check(signature == _signature(), "each map is deterministic")

	_fresh(0)
	var scene = game.active_world
	game.lifetime_organic_absorbed = scene.organic_required
	game.lifetime_mineral_absorbed = scene.mineral_required
	_check(not scene.mission_ready(game), "uptake alone cannot win contested-region mission")
	for center in [Vector2(520, -180), Vector2(520, 210)]:
		game.segments.append(_segment(Vector2.ZERO, center, 0, false))
	_check(scene.mission_ready(game), "two real mature connected branches plus actual uptake qualify")
	game.segments[0]["orphaned"] = true
	_check(not scene.mission_ready(game), "orphaned network does not control contested resource zone")

	_fresh(1)
	scene = game.active_world
	_check(scene.manual_action_key(game) == "campaign_action_begin_rescue", "rescue is deliberately started after preparation")
	_check(scene.mission_notes(game)[0]["values"]["minutes"] == 15, "preparation warning explicitly tells the player the rescue window")
	_check(scene.mission_action(game) and not scene.mission_action(game), "sealed networks open only once")
	_check(scene.mission_notes(game)[0]["values"]["seconds"] == 900, "active rescue exposes remaining seconds outside victory objectives")
	game.segments.append(_segment(Vector2.ZERO, Vector2(420, -180), 0, false))
	game.segments.append(_segment(Vector2.ZERO, Vector2(510, 170), 0, false))
	game._update_orphaned_segments(0.25)
	scene.mission_tick(game, 0.25)
	_check(scene.runtime.data["mission_state"]["rescued"] == [1, 1], "normal reconnect code transfers both orphan networks")
	_check(not game.cores[1]["alive"] and not game.cores[2]["alive"], "dead cores are never resurrected")
	_check(scene.mission_notes(game)[0]["key"] == "campaign_note_rescue_recovered", "rescued network guidance switches to relay recovery")
	_check(not scene.mission_ready(game), "rescue alone cannot skip recovery and supply goals")
	game.cores[3]["biomass"] = 75.0
	game.lifetime_organic_absorbed = scene.organic_required
	_check(scene.mission_ready(game), "rescue/recovery/supply jointly complete")
	game._kill_core(3, "environment_pressure")
	_check(scene.mission_failed(game) and not scene.mission_ready(game), "losing the designated living relay fails only this task")
	_fresh(1)
	scene = game.active_world
	scene.mission_action(game)
	game.segments.clear()
	scene.mission_tick(game, 0.25)
	_check(scene.mission_failed(game), "decayed unrescued network cannot be reported rescued")
	var corrupt: Dictionary = scene.runtime.data["mission_state"].duplicate(true)
	corrupt["rescued"] = [1, 1, 1]
	_check(not scene.validate_mission_state(corrupt), "invalid rescue ledger size rejected")

	_fresh(2)
	scene = game.active_world
	scene.mission_tick(game, 180.0)
	_check(game.ecology_events.size() == 1 and game.ecology_events[0]["phase"] == "warning" and game._ecology_toxin_damage_rate_at(Vector2(530, -100)) == 0.0, "toxin begins with a harmless visible warning")
	scene.mission_tick(game, 60.0)
	_check(game.diet_order.is_empty() and game._ecology_toxin_damage_rate_at(Vector2(530, -100)) > 0.0, "mission toxin damages without requiring bacterial food specialization")
	_check(game._ecology_toxin_damage_rate_at(Vector2(700, 180)) == 0.0, "authored southern route is outside contamination")
	var state: Dictionary = scene.runtime.data["mission_state"]
	_check(scene.validate_mission_state(JSON.parse_string(JSON.stringify(state))), "active hazard state survives JSON")
	game.cores.append(game._make_core(Vector2(220, -25), "barracks"))
	game._spawn_expedition_spore(1, "forager", false)
	var unit: Dictionary = game.expedition_units[0]
	unit["pos"] = Vector2(400, 180)
	unit["cargo_organic"] = 1.0
	scene._track_cargo_returns(game)
	scene.runtime.data["mission_state"] = JSON.parse_string(JSON.stringify(state))
	state = scene.runtime.data["mission_state"]
	unit["pos"] = Vector2(220, -25)
	unit["cargo_organic"] = 0.0
	scene._track_cargo_returns(game)
	_check(state["returned_ids"].size() == 1, "one distinct carrying unit returning home qualifies without a hidden x-coordinate gate")
	scene._track_cargo_returns(game)
	_check(state["returned_ids"].size() == 1, "repeated idle frame never double counts return")
	game._spawn_expedition_spore(1, "forager", false)
	game.expedition_units[1]["pos"] = Vector2(700, 180)
	scene._track_cargo_returns(game)
	game.expedition_units[1]["pos"] = Vector2(220, -25)
	scene._track_cargo_returns(game)
	_check(state["returned_ids"].size() == 1, "empty scouting trip is not cargo extraction")
	corrupt = state.duplicate(true)
	corrupt["returned_ids"] = [999]
	_check(not scene.validate_mission_state(corrupt), "return credit without visited unit rejected")
	corrupt = state.duplicate(true)
	corrupt["hazard_clock"] = NAN
	_check(not scene.validate_mission_state(corrupt), "nonfinite hazard clocks rejected")
	state["visited_ids"] = range(1, 67)
	scene._track_cargo_returns(game)
	_check(state["visited_ids"].size() <= 3 and state["previous_ids"].size() <= 64 and state["returned_ids"].size() <= 2, "replacement collector ledger is pruned to live units and needed completion proofs")
	_check(scene.validate_mission_state(state) and SnapshotValidator.validate({"mission_state": state}), "mission and generic JSON validators agree on bounded ledger size")
	scene.mission_tick(game, 240.0)
	_check(game.ecology_events.is_empty(), "toxin expires rather than producing permanent invisible damage")

	_fresh(3)
	scene = game.active_world
	game.lifetime_enemy_fungi_defeated = 100
	game.lifetime_organic_absorbed = scene.organic_required
	_check(not scene.mission_ready(game), "global kill count cannot replace the designated target")
	game._damage_enemy_fungus(int(game.enemy_fungi[0]["id"]), 100.0)
	_check(scene.mission_ready(game), "designated target death and actual supply qualify")
	game.game_over = true
	_check(not scene.mission_ready(game), "game-over state cannot claim mission completion")
	if failed:
		return
	print("CHAPTER_EXPEDITIONS_SMOKE_OK checks=%d fixture_tests_not_normal_routes=true" % checks)
	game.queue_free()
	await process_frame
	quit(0)


func _fresh(index: int) -> void:
	var scene = load("res://scenes/missions/%s.tscn" % NAMES[index]).instantiate()
	scene.runtime.ensure_defaults(game.INITIAL_WORLD_STATE)
	_check(game._start_new_culture(IDS[index], false, scene), "fresh independent test scene")


func _signature() -> Array:
	var result := []
	for resource in game.resources:
		result.append([resource["id"], resource["pos"], resource["kind"], resource["amount"]])
	return result


func _segment(a: Vector2, b: Vector2, core_id: int, orphaned: bool) -> Dictionary:
	return {"a": a, "b": b, "core_id": core_id, "growth": 1.0, "curve": 0.0, "orphaned": orphaned, "viability": 1.0}


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if condition:
		return true
	failed = true
	push_error("CHAPTER_EXPEDITIONS_SMOKE_FAIL: " + message)
	quit(1)
	return false
