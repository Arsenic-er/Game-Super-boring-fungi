extends SceneTree

# Normal paid route on the actual independent map. The small readiness fixtures
# run first, then a fresh scene removes every injected fixture value.
# Script completion time is NOT an estimate of average player completion time.
const SCENE := preload("res://scenes/missions/RemotePantry.tscn")
const STEP := 0.25
const DEADLINE := 40.0 * 60.0
const ORGANIC_START := Vector2(580, -140)
const ORGANIC_END := Vector2(720, 0)
const MINERAL_START := Vector2(565, 215)
const MINERAL_END := Vector2(675, 325)

var game: Node
var failed := false
var checks := 0
var elapsed := 0.0
var spent := {"organic": 0.0, "mineral": 0.0, "dna": 0}
var milestones := {}
var assigned := {}
var barracks_id := -1
var chelator_queued := false
var paid_dna := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var started := Time.get_ticks_msec()
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.developer_mode_enabled = false
	game.autosave_enabled = false
	game.splash_active = false
	game.main_menu_active = false
	game.game_started = true
	if not _fresh_scene():
		return
	if not _check(game.active_world.scene_file_path == "res://scenes/missions/RemotePantry.tscn" and game.active_world.validate_definition() and game.active_world.goal_targets() == {"organic": 36.0, "mineral": 4.0, "length_world": 0.0}, "independent PackedScene supplies cargo-only goals"):
		return
	if not _check(game.resources.size() == 86 and game.cores.size() == 1 and game.organic == 220.0 and game.mineral == 24.0 and game.dna == 0 and game._available_barracks_units() == ["forager"], "normal starting stock, one core and no free technologies or units"):
		return
	var initial_map := _map_signature()
	if not _check(game._distance_to_colony(Vector2(650, -70)) > game.EXPEDITION_OPERATING_RADIUS and game._distance_to_colony(Vector2(620, 270)) > game.EXPEDITION_OPERATING_RADIUS, "far patches require a real extended supply network"):
		return
	# Counting/validation fixtures are isolated from the economic route below.
	game.organic = 10000.0
	game.mineral = 10000.0
	game.lifetime_organic_absorbed = 10000.0
	game.lifetime_mineral_absorbed = 10000.0
	if not _check(not game.active_world.mission_ready(game), "stock and hypha uptake cannot masquerade as transported cargo"):
		return
	game.lifetime_expedition_organic_returned = 36.0
	game.lifetime_expedition_mineral_returned = 3.999
	if not _check(not game.active_world.mission_ready(game), "both actual-return targets must be reached"):
		return
	game.lifetime_expedition_mineral_returned = 4.0
	if not _check(game.active_world.mission_ready(game), "exact returned-cargo thresholds count"):
		return
	game.game_over = true
	if not _check(not game.active_world.mission_ready(game), "game-over state cannot claim cargo victory"):
		return
	game.game_over = false
	game.cores[0]["alive"] = false
	if not _check(not game.active_world.mission_ready(game), "a living core is required"):
		return
	game.cores[0]["alive"] = true
	game.active_world.organic_required = NAN
	if not _check(not game.active_world.validate_definition() and not game.active_world.mission_ready(game), "nonfinite mission definitions cannot produce readiness"):
		return
	if not _fresh_scene() or not _check(_map_signature() == initial_map, "fresh mission regenerates the deterministic map and removes all fixture data"):
		return

	# Reach visible starter nutrients by paid growth. The organic tip becomes
	# the barracks; its own new branch supports both distant transport zones.
	var organic_segment := _extend(0, Vector2(230, -25))
	_extend(0, Vector2(-195, 150))
	if failed or not _queue_dna(0, 2):
		return
	while game.dna < 2 and elapsed < DEADLINE and not failed:
		_tick()
	if failed:
		return
	milestones["first_two_dna"] = elapsed
	if not _build_barracks(organic_segment):
		return
	milestones["barracks"] = elapsed
	if not _queue_dna(0, 2) or not _queue_dna(barracks_id, 2):
		return
	var transport_segment := _extend(barracks_id, Vector2(500, -50))
	while not failed and float(game.segments[transport_segment]["growth"]) < 1.0 and elapsed < DEADLINE:
		_tick()
	# Harvest zones, including their corners, must fit the normal operating
	# radius. A second paid relay branch supports the separate mineral route.
	_extend(barracks_id, Vector2(500, 170))
	if failed:
		return
	var before := _balances()
	if not _check(game._queue_expedition_spores(barracks_id, "forager", 3, false), "three paid basic foragers enter the normal production queue"):
		return
	_record_spend(before)

	while not game.active_world.mission_ready(game) and elapsed < DEADLINE and not failed:
		if not chelator_queued and game.dna >= 4:
			before = _balances()
			game._purchase_barracks_unit("chelator")
			_record_spend(before)
			if not _check(bool(game.barracks_unit_unlocks.get("chelator", false)), "normal four-DNA shop purchase unlocks mineral collection without a food specialization"):
				return
			milestones["chelator_unlocked"] = elapsed
			before = _balances()
			chelator_queued = game._queue_expedition_spores(barracks_id, "chelator", 1, false)
			_record_spend(before)
			if not _check(chelator_queued, "one chelator is paid for and queued normally"):
				return
		for unit in game.expedition_units:
			var unit_id := int(unit["id"])
			if assigned.has(unit_id):
				continue
			game.selected_expedition_ids = [unit_id]
			var mineral_unit := String(unit["unit_type"]) == "chelator"
			var count: int = game._assign_harvest_zone(MINERAL_START if mineral_unit else ORGANIC_START, MINERAL_END if mineral_unit else ORGANIC_END)
			if not _check(count == 1, "a naturally produced unit accepts its resource-type harvest zone"):
				return
			assigned[unit_id] = true
		_tick()
		if Time.get_ticks_msec() - started > 45000:
			break
	if failed:
		return
	if not _check(game.active_world.mission_ready(game), "normal paid route finishes inside 40 simulated minutes / 45 seconds wall budget"):
		print("REMOTE_PANTRY_DIAGNOSTIC ", JSON.stringify(_snapshot()))
		return
	if not _check(paid_dna == 6 and game.lifetime_dna_produced == 6 and game.dna == 0 and game.lifetime_expedition_units_built == 4 and game.goals_claimed.is_empty() and game.diet_order.is_empty(), "route used six paid DNA, four paid units and no goal rewards or diet gate"):
		return
	if not _check(game.bacteria.is_empty() and game.enemy_fungi.is_empty() and game.enemy_guard_spores.is_empty() and game.ecology_events.is_empty() and not game.active_world.allows_ecology_events(), "quiet logistics mission has no hidden enemy or ecology spawns"):
		return
	if not _check(absf(game.organic - (220.0 + game.lifetime_organic_absorbed + game.lifetime_expedition_organic_returned - float(spent["organic"]))) < 0.001 and absf(game.mineral - (24.0 + game.lifetime_mineral_absorbed + game.lifetime_expedition_mineral_returned - float(spent["mineral"]))) < 0.001 and game.dna == paid_dna - int(spent["dna"]), "all nutrients and DNA conserve actual income minus paid actions"):
		return
	print("REMOTE_PANTRY_ROUTE ", JSON.stringify(_snapshot()))
	print("REMOTE_PANTRY_OK checks=%d scripted_route_not_player_average=true wall_ms=%d" % [checks, Time.get_ticks_msec() - started])
	game.queue_free()
	await process_frame
	quit(0)


func _fresh_scene() -> bool:
	var scene: Node2D = SCENE.instantiate()
	scene.runtime.ensure_defaults(game.INITIAL_WORLD_STATE)
	return _check(game._start_new_culture("remote_pantry", false, scene), "new scene starts through the common normal-game initializer")


func _map_signature() -> Array:
	var result := []
	for resource in game.resources:
		result.append([resource["id"], resource["pos"], resource["kind"], resource["amount"]])
	return result


func _tick() -> void:
	if failed:
		return
	game._process(STEP)
	elapsed += STEP
	_check(not game.game_over and not game.developer_mode_enabled and is_finite(game.organic) and is_finite(game.mineral) and game.organic >= 0.0 and game.mineral >= 0.0 and game.dna >= 0, "normal paid simulation remains alive and nonnegative")


func _extend(core_id: int, target: Vector2) -> int:
	game.selected_core = core_id
	game.selected_tip_valid = false
	var before := _balances()
	var count_before: int = game.segments.size()
	game._confirm_extension(target)
	_record_spend(before)
	_check(game.segments.size() == count_before + 1, "normal nutrient payment creates a growing hypha")
	return game.segments.size() - 1


func _build_barracks(segment_id: int) -> bool:
	var tip: Dictionary = game._tip_at(game.world_to_screen(game.segments[segment_id]["b"]))
	if not _check(not tip.is_empty() and float(game.segments[segment_id]["growth"]) >= 1.0, "barracks placement uses a naturally matured selectable tip"):
		return false
	game.selected_tip = tip["pos"]
	game.selected_tip_core = int(tip["core_id"])
	game.selected_tip_valid = true
	var before := _balances()
	var count_before: int = game.cores.size()
	game._create_barracks_core()
	_record_spend(before)
	if not _check(game.cores.size() == count_before + 1, "barracks construction pays real nutrients and two DNA"):
		return false
	barracks_id = game.cores.size() - 1
	return true


func _queue_dna(core_id: int, amount: int) -> bool:
	var before := _balances()
	var accepted: bool = game._queue_dna(core_id, amount)
	_record_spend(before)
	if not _check(accepted, "DNA jobs pay nutrients and use real queue durations"):
		return false
	paid_dna += amount
	return true


func _balances() -> Dictionary:
	return {"organic": float(game.organic), "mineral": float(game.mineral), "dna": int(game.dna)}


func _record_spend(before: Dictionary) -> void:
	spent["organic"] += float(before["organic"]) - float(game.organic)
	spent["mineral"] += float(before["mineral"]) - float(game.mineral)
	spent["dna"] += int(before["dna"]) - int(game.dna)


func _snapshot() -> Dictionary:
	return {"script_seconds": elapsed, "simulation_seconds": game.sim_time, "organic": game.organic, "mineral": game.mineral, "dna": game.dna, "returned_organic": game.lifetime_expedition_organic_returned, "returned_mineral": game.lifetime_expedition_mineral_returned, "absorbed_organic": game.lifetime_organic_absorbed, "absorbed_mineral": game.lifetime_mineral_absorbed, "paid": spent, "milestones_seconds": milestones, "unit_count": game.expedition_units.size()}


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if condition:
		return true
	failed = true
	push_error("REMOTE_PANTRY_FAIL at %.3fs: %s" % [elapsed, message])
	quit(1)
	return false
