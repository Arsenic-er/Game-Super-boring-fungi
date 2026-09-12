extends "res://tests/chapter1_opening_progression_smoke.gd"


# Diagnostic, intentionally outside the default smoke suite. The normal opening
# is followed by no new player orders, not an optimal two-hour progression plan.
const SESSION_SECONDS := 2.0 * 60.0 * 60.0


func _after_opening() -> bool:
	var started_ms := Time.get_ticks_msec()
	var next_snapshot := elapsed_seconds
	var minimum_organic := float(game.organic)
	var minimum_mineral := float(game.mineral)
	while elapsed_seconds < SESSION_SECONDS and not game.game_over:
		if elapsed_seconds >= next_snapshot:
			_snapshot()
			next_snapshot += 20.0 * 60.0
		game._process(STEP_SECONDS)
		elapsed_seconds += STEP_SECONDS
		minimum_organic = minf(minimum_organic, float(game.organic))
		minimum_mineral = minf(minimum_mineral, float(game.mineral))
		if not _check(is_finite(game.organic) and is_finite(game.mineral) and game.organic >= -0.000001 and game.mineral >= -0.000001 and game.dna >= 0, "idle follow-up keeps finite nonnegative balances"):
			return false
	_snapshot()
	print("CHAPTER1_LONG_SESSION_PROBE_OK ", JSON.stringify({
		"policy": "paid_opening_then_no_player_orders", "elapsed_seconds": elapsed_seconds,
		"world_seconds": game.sim_time, "game_over": game.game_over,
		"minimum_organic": snappedf(minimum_organic, 0.001),
		"minimum_mineral": snappedf(minimum_mineral, 0.001),
		"runtime_ms": Time.get_ticks_msec() - started_ms
	}))
	return true


func _snapshot() -> void:
	var queued := 0
	var living_health: Array = []
	for core_id in range(game.cores.size()):
		if game._is_core_alive(core_id):
			queued += (game.cores[core_id].get("jobs", []) as Array).size()
			living_health.append(snappedf(float(game.cores[core_id]["biomass"]), 0.001))
	var remaining := {"organic": 0.0, "mineral": 0.0}
	for deposit in game.resources:
		var key := "organic" if int(deposit["kind"]) == 0 else "mineral"
		remaining[key] += float(deposit["amount"])
	var states := {}
	for unit in game.expedition_units:
		var state := String(unit.get("state", "unknown"))
		states[state] = int(states.get(state, 0)) + 1
	print("CHAPTER1_LONG_SESSION_SNAPSHOT ", JSON.stringify({
		"elapsed_seconds": elapsed_seconds, "world_seconds": game.sim_time,
		"organic": snappedf(game.organic, 0.001), "mineral": snappedf(game.mineral, 0.001),
		"dna": game.dna, "dna_queued": queued, "dna_produced": game.lifetime_dna_produced,
		"returned_organic": snappedf(game.lifetime_expedition_organic_returned, 0.001),
		"returned_mineral": snappedf(game.lifetime_expedition_mineral_returned, 0.001),
		"absorbed_organic": snappedf(game.lifetime_organic_absorbed, 0.001),
		"absorbed_mineral": snappedf(game.lifetime_mineral_absorbed, 0.001),
		"living_core_health": living_health, "unit_states": states,
		"bacteria": game.bacteria.size(), "chapter_task_index": game.chapter_task_index,
		"chapter_complete": game.chapter_complete, "report_open": game.chapter_report_open,
		"game_over": game.game_over, "remaining_map_resources": remaining
	}))
