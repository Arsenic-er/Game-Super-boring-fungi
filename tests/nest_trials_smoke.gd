extends SceneTree

# These routes construct and produce ordinary units with paid actions, then use
# real movement and the normal forager guard-attack code. No direct enemy damage,
# enemy deletion, victory-counter injection or developer resources are used.
const STEP := 0.25
const TRIALS := ["first_contact", "two_fronts", "stable_colony"]
var game: Node
var failed := false
var checks := 0
var elapsed := 0.0
var barracks := -1
var overlapping_guard_commands := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.splash_active = false
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false
	game.developer_mode_enabled = false
	for id in TRIALS:
		if not _prepare_paid_colony():
			return
		var scene = load("res://scenes/missions/%s.tscn" % {"first_contact": "FirstContact", "two_fronts": "TwoFronts", "stable_colony": "StableColony"}[id]).instantiate()
		# Transfer the paid fixture's living world into the independent trial.
		# Actual checkpoint cloning/rollback is covered by campaign integration.
		scene.runtime = game.world_runtime
		if not _check(game._activate_world_scene(scene), "independent trial scene activates"):
			return
		scene.initialize_trial(game)
		var before: Dictionary = scene.runtime.data["mission_state"].duplicate(true)
		if not _check(scene.validate_definition() and scene.validate_mission_state(before), "initial trial state validates"):
			return
		var malformed := before.duplicate(true)
		malformed["wave_index"] = 99
		if not _check(not scene.validate_mission_state(malformed), "out-of-range wave cannot load"):
			return
		malformed = before.duplicate(true)
		malformed["organic_baseline"] = NAN
		if not _check(not scene.validate_mission_state(malformed), "nonfinite supply baseline cannot load"):
			return
		scene.initialize_trial(game)
		if not _check(scene.runtime.data["mission_state"] == before, "initialization is idempotent"):
			return
		scene.mission_tick(game, 600.0)
		if not _check(game.enemy_guard_spores.is_empty() and not scene.mission_ready(game) and scene.manual_action_key(game) == "trial_start_wave", "idle preparation neither spawns waves nor wins"):
			return
		var combat_started := elapsed
		var wall_started := Time.get_ticks_msec()
		while not scene.mission_ready(game) and elapsed - combat_started < 3600.0 and not failed:
			var state: Dictionary = scene.runtime.data["mission_state"]
			if not bool(state["wave_active"]) and int(state["wave_index"]) < scene.wave_sizes.size():
				if not _check(scene.mission_action(game), "player explicitly starts next wave"):
					return
				if not _check(not scene.mission_action(game) and scene.manual_action_key(game).is_empty(), "a running wave cannot spawn twice"):
					return
				if not _check(scene.validate_mission_state(scene.runtime.data["mission_state"]), "active state validates"):
					return
				var duplicate: Dictionary = scene.runtime.data["mission_state"].duplicate(true)
				duplicate["raider_ids"].append(duplicate["raider_ids"][0])
				if not _check(not scene.validate_mission_state(duplicate), "duplicate live guard IDs cannot load"):
					return
				var saved: Dictionary = JSON.parse_string(JSON.stringify(game._capture_world_state()))
				var guard_count: int = game.enemy_guard_spores.size()
				if not _check(game._restore_world_state(saved), "mid-wave snapshot restores through normal world loading"):
					return
				scene = game.active_world
				if not _check(game.enemy_guard_spores.size() == guard_count and scene.validate_mission_state(scene.runtime.data["mission_state"]), "ownerless raiders and wave state survive JSON round trip"):
					print("NEST_TRIAL_RESTORE_DIAGNOSTIC ", JSON.stringify(_diagnostic(scene)), " saved_guards=", guard_count, " handle=", scene.handles_enemy_guard(1))
					return
				var guard_biomass: float = game.enemy_guard_spores[0]["biomass"]
				game._update_enemy_guard_spores(STEP)
				if not _check(game.enemy_guard_spores.size() == guard_count and game.enemy_guard_spores[0]["biomass"] == guard_biomass, "legacy AI cannot orphan or decay trial raiders"):
					return
			_assign_combat()
			_tick()
			scene.mission_tick(game, STEP)
			if not _check(not game.game_over and game._living_core_count() > 0, "normal colony survives actual incoming attacks"):
				return
			if Time.get_ticks_msec() - wall_started > 45000:
				break
		if not _check(scene.mission_ready(game), "all real battles and supply/network objectives complete inside route budget"):
			print("NEST_TRIAL_DIAGNOSTIC ", id, " ", JSON.stringify(_diagnostic(scene)))
			return
		var total := 0
		for size in scene.wave_sizes:
			total += size
		if not _check(game.enemy_guard_spores.is_empty() and game.lifetime_enemy_guards_defeated == total and scene.validate_mission_state(scene.runtime.data["mission_state"]), "every raider was defeated through actual combat"):
			return
		if not _check(not game.developer_mode_enabled and game.diet_order.is_empty() and game.lifetime_expedition_units_built == 8 and game.goals_claimed.is_empty(), "eight paid basic foragers, no specialized diet or reward injections"):
			return
		if not _check(scene.manual_action_key(game).is_empty() and not scene.mission_action(game), "finished trials cannot produce extra waves"):
			return
		game.game_over = true
		if not _check(scene.mission_failed(game) and not scene.mission_ready(game), "failure excludes simultaneous victory"):
			return
		game.game_over = false
		print("NEST_TRIAL_ROUTE ", id, " ", JSON.stringify(_diagnostic(scene)))
	if not _check(overlapping_guard_commands > 0, "actual route includes guard targeting while it overlaps a friendly barracks"):
		return
	if not _undefended_contract():
		return
	print("NEST_TRIALS_OK checks=%d paid_basic_foragers=8 real_combat=true scripted_route_not_player_average=true" % checks)
	game.queue_free()
	await process_frame
	quit(0)


func _prepare_paid_colony() -> bool:
	elapsed = 0.0
	barracks = -1
	if not _check(game._start_new_culture("first_supply"), "deterministic paid colony fixture begins with normal stock"):
		return false
	game.sim_speed = 1.0
	var east := _extend(0, Vector2(230, -25))
	_extend(0, Vector2(-195, 150))
	if failed or not _check(game._queue_dna(0, 2), "two DNA paid from starting nutrients"):
		return false
	while game.dna < 2 and elapsed < 1800.0:
		_tick()
	if not _check(game.dna == 2 and float(game.segments[east]["growth"]) >= 1.0, "paid DNA and natural growth finish"):
		return false
	var tip: Dictionary = game._tip_at(game.world_to_screen(game.segments[east]["b"]))
	if not _check(not tip.is_empty(), "mature hypha tip is selectable"):
		return false
	game.selected_tip = tip["pos"]
	game.selected_tip_core = int(tip["core_id"])
	game.selected_tip_valid = true
	var before: int = game.cores.size()
	game._create_barracks_core()
	if not _check(game.cores.size() == before + 1 and game.dna == 0, "barracks pays construction nutrients and DNA"):
		return false
	barracks = game.cores.size() - 1
	_extend(barracks, Vector2(460, 70))
	while game.organic < 64.0 and elapsed < 2400.0:
		_tick()
	if not _check(game._queue_expedition_spores(barracks, "forager", 8, false), "eight basic foragers are paid and queued normally"):
		return false
	while game.expedition_units.size() < 8 and elapsed < 3000.0:
		_tick()
	return _check(game.expedition_units.size() == 8 and game._chapter_living_hypha_length() >= 600.0, "paid colony has eight naturally produced units and mature network")


func _extend(core_id: int, target: Vector2) -> int:
	game.selected_core = core_id
	game.selected_tip_valid = false
	var before: int = game.segments.size()
	game._confirm_extension(target)
	_check(game.segments.size() == before + 1, "normal paid hypha extension")
	return game.segments.size() - 1


func _assign_combat() -> void:
	for guard in game.enemy_guard_spores:
		var position: Vector2 = guard["pos"]
		if not game._is_world_explored(position) or game._distance_to_colony(position) > game.EXPEDITION_OPERATING_RADIUS:
			continue
		var ids: Array[int] = []
		for unit in game.expedition_units:
			if bool(unit.get("lost", false)) or String(unit.get("state", "")) in ["retreating", "repairing", "wounded"] or float(unit["biomass"]) <= float(unit["max_biomass"]) * 0.31:
				continue
			if int(unit.get("target_enemy_guard_id", -1)) != int(guard["id"]):
				ids.append(int(unit["id"]))
		if not ids.is_empty():
			game.selected_expedition_ids = ids
			game._issue_expedition_command(game.world_to_screen(position))
			var core_hit: int = game._core_at(game.world_to_screen(position))
			if core_hit >= 0 and String(game.cores[core_hit].get("kind", "")) == "barracks":
				var unit_index: int = game._expedition_unit_index_by_id(ids[0])
				_check(unit_index >= 0 and String(game.expedition_units[unit_index]["target_kind"]) == "enemy_guard" and int(game.expedition_units[unit_index]["target_enemy_guard_id"]) == int(guard["id"]), "right click attacks a guard overlapping a friendly barracks")
				overlapping_guard_commands += 1
		break


func _undefended_contract() -> bool:
	# A separate unfortified fixture tests damage/failure without changing or
	# speeding up any of the completed paid combat routes above.
	if not _check(game._start_new_culture("first_supply"), "unfortified failure fixture starts normally"):
		return false
	var scene = load("res://scenes/missions/FirstContact.tscn").instantiate()
	scene.runtime = game.world_runtime
	game._activate_world_scene(scene)
	scene.initialize_trial(game)
	if not _check(scene.mission_action(game), "unfortified player can knowingly start a wave"):
		return false
	var initial: float = game.cores[0]["biomass"]
	for _step in range(80):
		scene.mission_tick(game, 1.0)
	if not _check(float(game.cores[0]["biomass"]) < initial and float(game.cores[0]["biomass"]) > initial - 2.0, "incoming spores move to the nest and apply slow fractional core damage"):
		return false
	for _step in range(4000):
		if scene.mission_failed(game):
			break
		scene.mission_tick(game, 1.0)
	return _check(scene.mission_failed(game) and not scene.mission_ready(game) and not scene.mission_action(game) and game.lifetime_enemy_guards_defeated == 0, "unopposed attackers eventually destroy the colony instead of timing out into victory")


func _tick() -> void:
	game._process(STEP)
	elapsed += STEP


func _diagnostic(scene) -> Dictionary:
	var units: Array = []
	for unit in game.expedition_units:
		units.append({"id": unit["id"], "pos": str(unit["pos"]), "state": unit["state"], "target": unit.get("target_enemy_guard_id"), "health": unit["biomass"]})
	return {"seconds": elapsed, "state": scene.runtime.data["mission_state"], "status": scene.mission_status(game), "units": game.expedition_units.size(), "guards": game.enemy_guard_spores.size(), "guard_data": game.enemy_guard_spores, "unit_data": units, "killed": game.lifetime_enemy_guards_defeated, "organic": game.organic, "mineral": game.mineral}


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if condition:
		return true
	failed = true
	push_error("NEST_TRIALS_FAIL: " + message)
	quit(1)
	return false
