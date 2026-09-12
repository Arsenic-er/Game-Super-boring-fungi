extends SceneTree


# Mechanism fixture, not a normal-opening progression forecast: the barracks
# and finite deposits are prebuilt, but its one forager is paid for and produced
# normally. Cargo, unit position and transport state are never injected.
const STEP_SECONDS := 0.25
const MAX_CYCLE_SECONDS := 600.0
const ZONE_ORGANIC := 8.25
const ZONE_MIN := Vector2(60.0, -70.0)
const ZONE_MAX := Vector2(200.0, 70.0)
const HOLD_POINT := Vector2(-70.0, -70.0)
const ORGANIC_COST := 8.0
const MINERAL_COST := 0.25

var game: Node
var unit: Dictionary = {}
var elapsed_seconds := 0.0
var deposits: Array = []
var failed := false
var post_purchase_organic := 0.0
var post_purchase_mineral := 0.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var started_ms := Time.get_ticks_msec()
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.developer_mode_enabled = false
	game.autosave_enabled = false
	game.splash_active = false
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	game.sim_speed = 1.0
	_fixture()
	if not _check(not game.developer_mode_enabled and is_equal_approx(game.organic, 220.0) and is_equal_approx(game.mineral, 24.0) and game.dna == 0, "fixture retains normal starting balances without developer resources"):
		return
	if not _check(game._queue_expedition_spores(0, "forager", 1, false), "normal barracks production accepts one paid forager"):
		return
	post_purchase_organic = float(game.organic)
	post_purchase_mineral = float(game.mineral)
	if not _check(is_equal_approx(post_purchase_organic, 220.0 - ORGANIC_COST) and is_equal_approx(post_purchase_mineral, 24.0 - MINERAL_COST), "unit nutrients are deducted before production"):
		return
	while game.expedition_units.is_empty() and elapsed_seconds < 40.0 and not failed:
		_tick()
	if not _check(game.expedition_units.size() == 1 and elapsed_seconds >= game.EXPEDITION_SPORE_BUILD_SECONDS, "the forager emerges only after real queued production time"):
		return
	unit = game.expedition_units[0]
	var produced_at := elapsed_seconds
	game.selected_expedition_ids = [int(unit["id"])]
	if not _check(game._assign_harvest_zone(ZONE_MIN, ZONE_MAX) == 1, "the forager accepts its finite square harvest zone"):
		return
	var original_zone: Rect2 = game._harvest_rect(unit)
	if not _check(original_zone.is_equal_approx(Rect2(ZONE_MIN, ZONE_MAX - ZONE_MIN)), "the requested square is preserved"):
		return

	# First real full load: travel, gather across points, return, then unload.
	_wait_for_returned(3.0)
	if failed:
		return
	if not _check(deposits.size() == 1 and is_equal_approx(float(deposits[0]["amount"]), 3.0) and bool(unit.get("harvest_enabled", false)), "the first full load reaches home without clearing the zone"):
		return
	var after_first_trip := elapsed_seconds

	# Direct player orders override the persistent zone. They do not silently
	# resume it; the player explicitly reapplies the zone after holding position.
	game._issue_expedition_command(game.world_to_screen(HOLD_POINT))
	if not _check(not bool(unit.get("harvest_enabled", false)) and bool(unit.get("manual", false)), "a direct movement order replaces the harvest assignment"):
		return
	var hold_deadline := elapsed_seconds + 10.0
	while not game._unit_is_manual_hold(unit) and elapsed_seconds < hold_deadline and not failed:
		_tick()
	if not _check(game._unit_is_manual_hold(unit) and (unit["pos"] as Vector2).distance_to(HOLD_POINT) <= game.EXPEDITION_ARRIVAL_DISTANCE, "the unit reaches the player destination and holds naturally"):
		return
	var hold_position: Vector2 = unit["pos"]
	var hold_organic := float(game.organic)
	var hold_remaining := _remaining_zone_organic()
	var hold_until := elapsed_seconds + 20.0
	while elapsed_seconds < hold_until and not failed:
		_tick()
	if failed:
		return
	if not _check(game._unit_is_manual_hold(unit) and (unit["pos"] as Vector2).is_equal_approx(hold_position) and is_equal_approx(float(game.organic), hold_organic) and is_equal_approx(_remaining_zone_organic(), hold_remaining), "automatic harvesting cannot steal the manual hold or generate income during it"):
		return
	if not _check(game._assign_harvest_zone(ZONE_MIN, ZONE_MAX) == 1 and (game._harvest_rect(unit) as Rect2).is_equal_approx(original_zone), "explicitly restoring the zone resumes the collection route"):
		return
	var reassigned_at := elapsed_seconds

	# The second delivery must be followed by an automatic new trip, with no
	# teleport, cargo write, queue shortcut, or further command from the test.
	_wait_for_returned(6.0)
	if failed:
		return
	if not _check(deposits.size() == 2 and is_equal_approx(float(deposits[1]["amount"]), 3.0), "the restored route delivers another genuine full load"):
		return
	var departure_deadline := elapsed_seconds + 6.0
	while not _heading_to_zone_resource() and elapsed_seconds < departure_deadline and not failed:
		_tick()
	if not _check(_heading_to_zone_resource() and bool(unit.get("harvest_enabled", false)), "the persistent zone automatically sends the unloaded unit out again"):
		return
	var automatic_departure_at := elapsed_seconds
	_wait_for_returned(ZONE_ORGANIC)
	if failed:
		return
	if not _check(deposits.size() == 3 and is_equal_approx(float(deposits[2]["amount"]), 2.25), "the exhausted zone returns its partial final load instead of stranding it"):
		return
	var completed_at := elapsed_seconds
	var exhausted_balance := float(game.organic)
	var idle_until := elapsed_seconds + 60.0
	while elapsed_seconds < idle_until and not failed:
		_tick()
	if failed:
		return
	if not _check(is_equal_approx(float(game.organic), exhausted_balance) and deposits.size() == 3 and bool(unit.get("harvest_enabled", false)), "an exhausted zone grants no further income and remains assigned"):
		return
	if not _check(game.lifetime_expedition_units_built == 1 and game.expedition_units.size() == 1 and game.dna == 0 and game.goals_claimed.is_empty(), "the cycle creates no extra units, DNA or unclaimed goal income"):
		return
	if not _check(is_zero_approx(game.lifetime_organic_absorbed) and is_zero_approx(game.lifetime_mineral_absorbed), "all measured income comes from transported cargo, not passive feeders"):
		return
	for resource_id in range(3):
		var resource: Dictionary = game._resource_by_id(resource_id)
		if not _check(is_zero_approx(float(resource["amount"])) and not bool(resource["alive"]), "all eligible finite sources deplete naturally"):
			return
	var result := {
		"fixture": "prebuilt_barracks_finite_deposits", "produced_at_seconds": produced_at,
		"first_trip_at_seconds": after_first_trip, "zone_restored_at_seconds": reassigned_at,
		"automatic_departure_at_seconds": automatic_departure_at, "cycle_complete_at_seconds": completed_at,
		"deposits": deposits, "organic_returned": snappedf(game.lifetime_expedition_organic_returned, 0.001),
		"mineral_returned": snappedf(game.lifetime_expedition_mineral_returned, 0.001),
		"organic_balance": snappedf(game.organic, 0.001), "mineral_balance": snappedf(game.mineral, 0.001),
		"outside_organic_untouched": float(game.resources[4]["amount"]), "inside_mineral_untouched": float(game.resources[3]["amount"])
	}
	print("CHAPTER1_ECONOMY_CYCLE_SNAPSHOT ", JSON.stringify(result))
	print("CHAPTER1_ECONOMY_CYCLE_OK trips=3 cargo=3+3+2.25 manual_priority=true auto_redeparture=true finite_resources=true runtime_ms=", Time.get_ticks_msec() - started_ms)
	game.queue_free()
	await process_frame
	quit(0)


func _fixture() -> void:
	game.founder_spore = {}
	game.cores.clear()
	game.cores.append(game._make_core(Vector2.ZERO, "barracks"))
	game.segments.clear()
	game.feeders.clear()
	game.expedition_units.clear()
	game.bacteria.clear()
	game.enemy_fungi.clear()
	game.enemy_hyphae.clear()
	game.enemy_guard_spores.clear()
	game.ecology_events.clear()
	game.resources.clear()
	game.resource_grid.clear()
	game.resource_hotspots.clear()
	game._add_resource(Vector2(90.0, -25.0), 0, 0.60)
	game._add_resource(Vector2(145.0, 10.0), 0, 3.40)
	game._add_resource(Vector2(180.0, 45.0), 0, 4.25)
	game._add_resource(Vector2(110.0, 40.0), 1, 2.125)
	game._add_resource(Vector2(210.0, 90.0), 0, 5.0)
	game.explored_cells.clear()
	game._update_exploration(false)


func _remaining_zone_organic() -> float:
	var remaining := 0.0
	for resource_id in range(3):
		remaining += float(game.resources[resource_id]["amount"])
	return remaining


func _heading_to_zone_resource() -> bool:
	return String(unit.get("target_kind", "")) == "resource" and ["moving", "gathering"].has(String(unit.get("state", "")))


func _wait_for_returned(amount: float) -> void:
	while float(game.lifetime_expedition_organic_returned) < amount - 0.000001 and elapsed_seconds < MAX_CYCLE_SECONDS and not failed:
		_tick()
	_check(float(game.lifetime_expedition_organic_returned) >= amount - 0.000001, "the next delivery completes within the bounded route time")


func _tick() -> void:
	if failed:
		return
	var returned_before := float(game.lifetime_expedition_organic_returned)
	game._process(STEP_SECONDS)
	elapsed_seconds += STEP_SECONDS
	var returned := float(game.lifetime_expedition_organic_returned)
	if returned > returned_before + 0.000001:
		deposits.append({"amount": snappedf(returned - returned_before, 0.001), "at_seconds": elapsed_seconds})
		if not _check(not unit.is_empty() and (unit["pos"] as Vector2).distance_to(Vector2.ZERO) <= game.EXPEDITION_ARRIVAL_DISTANCE, "cargo is credited only after reaching the real home"):
			return
	var cargo := 0.0
	for expedition_unit in game.expedition_units:
		cargo += float(expedition_unit.get("cargo_organic", 0.0))
		if not _check(float(expedition_unit.get("cargo_organic", 0.0)) >= -0.000001 and float(expedition_unit.get("cargo_mineral", 0.0)) >= -0.000001, "cargo balances never go negative"):
			return
	if not _check(absf(_remaining_zone_organic() + cargo + returned - ZONE_ORGANIC) < 0.00001, "source plus in-transit cargo plus credited cargo is conserved at every step"):
		return
	if not _check(absf(float(game.organic) - post_purchase_organic - returned) < 0.00001 and is_equal_approx(float(game.mineral), post_purchase_mineral), "player balances change only by actual deliveries after the production payment"):
		return
	if not _check(is_equal_approx(float(game.resources[3]["amount"]), 2.125) and is_equal_approx(float(game.resources[4]["amount"]), 5.0) and is_zero_approx(game.lifetime_expedition_mineral_returned), "the forager ignores wrong-kind and out-of-zone resources throughout the route"):
		return
	_check(not game.game_over and game.dna == 0 and not game.developer_mode_enabled, "the isolated mechanism remains in normal paid mode")


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	failed = true
	push_error("CHAPTER1_ECONOMY_CYCLE_FAIL at %.2fs: %s" % [elapsed_seconds, message])
	quit(1)
	return false
