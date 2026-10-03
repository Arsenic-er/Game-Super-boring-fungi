extends SceneTree

# These routes use the normal starting budget and paid game actions. Activating
# the mission ID below is scene-routing setup only; no currencies, upgrades,
# damage, objective counters or unit completion are injected during routes.
const STEP := 0.25
const DEADLINE := 45.0 * 60.0
const MISSIONS := {
	"substrate_race": "SubstrateRace",
	"lost_network": "LostNetwork",
	"toxic_frontier": "ToxicFrontier",
	"boundary_counterattack": "BoundaryCounterattack"
}
var game: Node
var failed := false
var checks := 0
var elapsed := 0.0
var mission_id := ""
var barracks_id := -1
var assigned := {}
var route_results := []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
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
	var wanted := OS.get_environment("FUNGI_MISSION_ROUTE")
	for id in MISSIONS:
		if not wanted.is_empty() and id != wanted:
			continue
		mission_id = id
		elapsed = 0.0
		assigned.clear()
		barracks_id = -1
		var scene = load("res://scenes/missions/%s.tscn" % MISSIONS[id]).instantiate()
		scene.runtime.ensure_defaults(game.INITIAL_WORLD_STATE)
		if not _check(game._start_new_culture(id, false, scene), "fresh independent scene initializes"):
			return
		game.campaign["active_mission"] = {"id": id, "attempt_id": 1}
		game.sim_speed = 1.0
		if not _check(scene.validate_definition() and scene.validate_mission_state(scene.runtime.data["mission_state"]), "authored scene and initial resumable mission state validate"):
			return
		if not _check(not scene.mission_ready(game) and game.organic == 220.0 and game.mineral == 24.0 and game.dna == 0 and game.diet_order.is_empty(), "normal economy starts without free completion or food specialization"):
			return
		match id:
			"substrate_race": _race()
			"lost_network": _rescue()
			"toxic_frontier": _toxin()
			"boundary_counterattack": _counterattack()
		if failed:
			return
		if not _check(game.active_world.mission_ready(game), "paid ordinary route meets all independent objectives"):
			return
		if not _check(game.diet_order.is_empty() and not game.developer_mode_enabled and game.goals_claimed.is_empty(), "no diet lock, developer grant, or extra long-term reward"):
			return
		var result := {"mission": id, "script_seconds": elapsed, "normal_route_not_player_average": true, "organic": game.organic, "mineral": game.mineral, "dna": game.dna, "dna_paid": game.lifetime_dna_produced, "units_built": game.lifetime_expedition_units_built, "units_lost": game.lifetime_expedition_units_lost, "objectives": scene.mission_status(game)}
		route_results.append(result)
		print("CHAPTER_EXPEDITION_ROUTE ", JSON.stringify(result))
	print("CHAPTER_EXPEDITIONS_NORMAL_OK routes=%d checks=%d" % [route_results.size(), checks])
	game.queue_free()
	await process_frame
	quit(0)


func _race() -> void:
	_extend(0, Vector2(220, -25))
	_extend(0, Vector2(-180, 150))
	_grow_all()
	_extend(0, Vector2(450, -180))
	_grow_all()
	_extend(0, Vector2(520, -180))
	_extend(0, Vector2(450, 210))
	_grow_all()
	_extend(0, Vector2(520, 210))
	_extend(0, Vector2(470, 275))
	while not _ready() and _can_tick():
		_tick()
	_check(game.lifetime_bacteria_births > 0 and not game.bacteria.is_empty(), "stationary rival bacteria genuinely absorb and divide; pacifist route leaves them alive")


func _rescue() -> void:
	_extend(0, Vector2(220, -25))
	_extend(0, Vector2(-180, 150))
	_grow_all()
	_extend(0, Vector2(420, -180))
	_extend(0, Vector2(435, 155))
	_grow_all()
	_check(game.active_world.mission_action(game), "player deliberately opens prepared rescue sample")
	_check(not game.active_world.mission_action(game), "rescue action is one-shot")
	_extend(0, Vector2(510, 170))
	game._repair_core(3)
	game._repair_core(3)
	game._repair_core(3)
	while not _ready() and _can_tick():
		_tick()
	_check(not bool(game.cores[1]["alive"]) and not bool(game.cores[2]["alive"]), "rescue transfers hypha ownership without reviving dead cores")


func _common_barracks() -> void:
	var branch := _extend(0, Vector2(220, -25))
	_extend(0, Vector2(-180, 150))
	_check(game._queue_dna(0, 2), "two DNA jobs paid normally")
	while game.dna < 2 and _can_tick():
		_tick()
	_build_barracks(branch)


func _toxin() -> void:
	_common_barracks()
	if failed:
		return
	_check(game._queue_dna(0, 2) and game._queue_dna(barracks_id, 2), "four additional DNA paid for chelator unlock")
	_extend(barracks_id, Vector2(440, 140))
	_grow_all()
	_extend(barracks_id, Vector2(550, 260))
	_grow_all()
	_check(game._queue_expedition_spores(barracks_id, "forager", 3, false), "three foragers are paid and enter production")
	var chelator_queued := false
	while not _ready() and _can_tick():
		if not chelator_queued and game.dna >= 4:
			game._purchase_barracks_unit("chelator")
			chelator_queued = game._queue_expedition_spores(barracks_id, "chelator", 1, false)
			_check(chelator_queued, "chelator purchased and built without special diet")
		for unit in game.expedition_units:
			var id := int(unit["id"])
			if assigned.has(id):
				continue
			var mineral := String(unit["unit_type"]) == "chelator"
			game.selected_expedition_ids = [id]
			var start := Vector2(640, 270) if mineral else Vector2(645, 125)
			var finish := Vector2(740, 370) if mineral else Vector2(755, 235)
			_check(game._assign_harvest_zone(start, finish) == 1, "normal safe-route harvest zone accepted")
			assigned[id] = true
		_tick()
	_check(int(game.active_world.runtime.data["mission_state"]["hazard_cycles"]) > 0, "mission toxin activates even with no bacteria diet")


func _counterattack() -> void:
	_common_barracks()
	if failed:
		return
	_extend(barracks_id, Vector2(490, 80))
	_grow_all()
	_extend(barracks_id, Vector2(675, -20))
	_extend(barracks_id, Vector2(490, 235))
	_grow_all()
	_check(game._queue_expedition_spores(barracks_id, "forager", 6, false), "six basic combat foragers paid normally")
	var command_clock := 0.0
	while not _ready() and _can_tick():
		command_clock -= STEP
		if command_clock <= 0.0:
			game.selected_expedition_ids.clear()
			for unit in game.expedition_units:
				if String(unit.get("state", "")) not in ["repairing", "retreating", "wounded"] and float(unit.get("biomass", 0.0)) > 5.0:
					game.selected_expedition_ids.append(int(unit["id"]))
			var target := Vector2(850, -20)
			for guard in game.enemy_guard_spores:
				if bool(guard.get("alive", false)):
					target = guard["pos"]
					break
			game._issue_expedition_command(game.world_to_screen(target))
			command_clock = 8.0
		_tick()
	_check(game.lifetime_enemy_fungi_defeated >= 1, "designated rival is defeated by normal combat")


func _ready() -> bool:
	return game.active_world.mission_ready(game)


func _can_tick() -> bool:
	if failed:
		return false
	if elapsed >= DEADLINE:
		_check(false, "normal route exceeded 45 simulated minutes: " + JSON.stringify(game.active_world.mission_status(game)))
		return false
	return true


func _tick() -> void:
	if failed:
		return
	game._process(STEP)
	elapsed += STEP
	_check(not game.game_over and not game.active_world.mission_failed(game) and game.organic >= 0.0 and game.mineral >= 0.0 and game.dna >= 0, "normal route remains alive and nonnegative")


func _grow_all() -> void:
	while _can_tick():
		var pending := false
		for segment in game.segments:
			if not bool(segment.get("orphaned", false)) and float(segment["growth"]) < 1.0:
				pending = true
		if not pending:
			return
		_tick()


func _extend(core_id: int, target: Vector2) -> int:
	if failed:
		return -1
	game.selected_core = core_id
	game.selected_tip_valid = false
	var before: int = game.segments.size()
	game._confirm_extension(target)
	_check(game.segments.size() == before + 1, "paid hypha extension created")
	return game.segments.size() - 1


func _build_barracks(segment_id: int) -> void:
	if failed:
		return
	var tip: Dictionary = game._tip_at(game.world_to_screen(game.segments[segment_id]["b"]))
	if not _check(not tip.is_empty(), "naturally matured tip selectable"):
		return
	game.selected_tip = tip["pos"]
	game.selected_tip_core = int(tip["core_id"])
	game.selected_tip_valid = true
	var count_before: int = game.cores.size()
	game._create_barracks_core()
	_check(game.cores.size() == count_before + 1, "barracks built with paid DNA and nutrients")
	barracks_id = game.cores.size() - 1


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if condition:
		return true
	if not failed:
		failed = true
		push_error("CHAPTER_EXPEDITION_FAIL %s %.3fs: %s" % [mission_id, elapsed, message])
		print("ROUTE_DIAGNOSTIC ", JSON.stringify({"objectives": game.active_world.mission_status(game), "organic": game.organic, "mineral": game.mineral, "dna": game.dna, "units": game.expedition_units, "state": game.active_world.runtime.data["mission_state"]}))
		quit(1)
	return false
