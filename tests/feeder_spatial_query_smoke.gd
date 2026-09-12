extends SceneTree

var game: Node
var comparisons := 0
var bounded_queries := 0
var maximum_bounded_query_usec := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.set_process(false)
	game.autosave_enabled = false
	game.splash_active = false
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.main_menu_active = false
	game.game_started = true
	if not _check(game.has_method("_feeder_candidate_resource_ids"), "spatial candidate method exists"):
		return
	var world_count: int = game.resources.size()
	var local_candidates: Array = game._feeder_candidate_resource_ids()
	if not _check(local_candidates.size() < world_count, "normal map broad phase excludes remote deposits") or not _compare("seeded normal map", 8):
		return
	# The initial spawn may have no nearby deposits. Also test an occupied real
	# generated hotspot so normal-map equivalence is not eight empty comparisons.
	var densest_resource_id := 0
	var largest_cell_size := 0
	for cell_ids in game.resource_grid.values():
		if cell_ids.size() > largest_cell_size:
			largest_cell_size = cell_ids.size()
			densest_resource_id = int(cell_ids[0])
	var hotspot: Vector2 = game._resource_by_id(densest_resource_id)["pos"]
	game.cores[0]["pos"] = hotspot
	game.segments.append(_segment(hotspot, hotspot + Vector2(260, 40), 0, 0.13, 1.0))
	game.feeders.clear()
	var hotspot_candidates: Array = game._feeder_candidate_resource_ids()
	if not _check(not hotspot_candidates.is_empty() and hotspot_candidates.size() < world_count, "real occupied hotspot has nonempty bounded candidates") or not _compare("generated resource hotspot with mature curved trunk", 8) or not _check(not game.feeders.is_empty(), "normal-map comparison builds actual feeder connections"):
		return
	_reset_fixture()
	game.resources = [_resource(0, Vector2(10, 0), 0), _resource(1, Vector2(12, 0), 0), _resource(2, Vector2(55, 0), 1), _resource(3, Vector2(60, 0), 1)]
	game._rebuild_resource_grid()
	if not _compare("reserve both nutrient kinds") or not _check(int(game.feeders[0]["resource_id"]) == 0 and int(game.feeders[1]["resource_id"]) == 2, "mineral retains its reserved slot despite nearer organic"):
		return
	if not _compare("already connected deposits are skipped", 2):
		return
	_reset_fixture()
	for index in range(12):
		game.resources.append(_resource(index, Vector2(30, 0) if index % 2 == 0 else Vector2(-30, 0), int(index % 3 == 0)))
	game._rebuild_resource_grid()
	if not _compare("equal-distance original array-order ties", 7):
		return
	_reset_fixture()
	game.cores[0]["pos"] = Vector2(128, 128)
	game.cores.append(game._make_core(Vector2(-128, -128)))
	game.resources = [_resource(0, Vector2(200, 128), 0), _resource(1, Vector2(200.01, 128), 1), _resource(2, Vector2(-200, -128), 1), _resource(3, Vector2(-200.01, -128), 0)]
	game._rebuild_resource_grid()
	if not _compare("positive and negative grid/range boundaries", 3) or not _check(game.feeders.size() == 2, "exact radius is included, 0.01 beyond it is excluded"):
		return
	_reset_fixture()
	game.segments = [_segment(Vector2.ZERO, Vector2(800, 0), 0, 0.8, 0.5)]
	var curve_points: PackedVector2Array = game._curved_points_grown(Vector2.ZERO, Vector2(800, 0), 0.8, 1.0)
	var apex: Vector2 = curve_points[4]
	game.resources = [_resource(0, apex + Vector2(0, 5), 0), _resource(1, apex + Vector2(0, -6), 1), _resource(2, Vector2(810, 4), 0)]
	game._rebuild_resource_grid()
	if not _compare("unfinished curved trunk is not a feeder source") or not _check(game.feeders.is_empty(), "immature distant branch cannot absorb"):
		return
	game._update_growth(game._hypha_growth_seconds())
	if not _compare("mature curved apex outside endpoint rectangle", 2) or not _check(game.feeders.size() == 3, "mature curved source discovers apex and endpoint resources"):
		return
	game.feeders.clear()
	game.segments[0]["viability"] = 0.0
	if not _compare("existing discovery intentionally does not add a viability filter"):
		return
	game.feeders.clear()
	game.segments[0]["orphaned"] = true
	if not _compare("orphan flag excludes a branch even with a living owner") or not _check(game.feeders.is_empty(), "orphan-only source is excluded"):
		return
	game.segments[0]["orphaned"] = false
	game.segments[0]["viability"] = 1.0
	game.cores.append(game._make_core(Vector2(1500, 0)))
	game._damage_core(0, 1000.0, "bacteria_toxin")
	if not _compare("real core loss orphans trunk and removes its source") or not _check(game.feeders.is_empty(), "dead-owner and orphan source stay excluded"):
		return
	_reset_fixture()
	game.cores.append(game._make_core(Vector2(200, 0)))
	game.cores[1]["feeder_range_level"] = 5
	game.resources = [_resource(0, Vector2(80, 0), 0), _resource(1, Vector2(120, 0), 1), _resource(2, Vector2(240, 0), 0), _resource(3, Vector2(200, 140), 1)]
	game._rebuild_resource_grid()
	if not _compare("unequal core ranges retain nearest-owner rule", 3):
		return
	for feeder in game.feeders:
		if not _check(int(feeder["resource_id"]) != 0, "closer low-range owner still blocks fallback to farther high-range core as before"):
			return
	game.cores[0]["feeder_range_level"] = 1
	if not _compare("range upgrade takes effect without rebuilding the resource index"):
		return
	_reset_fixture()
	game.resources = [_resource(10, Vector2(10, 0), 0), _resource(42, Vector2(20, 0), 1), _resource(91, Vector2(30, 0), 0), _resource(150, Vector2(40, 0), 1)]
	game._rebuild_resource_grid()
	# Duplicate broad-phase entries must not create duplicate selected resources.
	(game.resource_grid[game._resource_cell(Vector2(10, 0))] as Array).append(10)
	if not _compare("sparse ascending IDs with duplicated grid membership", 3) or not _check(game.feeders.size() == 4, "sparse IDs resolve by identity, not array index"):
		return
	_reset_fixture()
	game._developer_spawn_resource(Vector2(20, 0), 0, 4.0)
	if not _compare("developer adds organic without index rebuild"):
		return
	game._developer_spawn_resource(Vector2(-20, 0), 1, 3.0)
	if not _compare("developer adds mineral after previous query") or not _check(game.feeders.size() == 2, "new resources appear immediately without stale candidate cache"):
		return
	game.resources[0]["amount"] = 0.0005
	game.resources[1]["alive"] = false
	game.feeders.clear()
	if not _compare("depleted and inactive resources are filtered"):
		return
	game._prune_depleted_resource_grid()
	if not _compare("offline-pruned resource index"):
		return
	_reset_fixture()
	game.resources = [_resource(0, Vector2(300, 301), 0), _resource(1, Vector2(600, 596), 1), _resource(2, Vector2(-500, 200), 0), _resource(3, Vector2(1000, -1000), 1)]
	game._rebuild_resource_grid()
	game.segments = [_segment(Vector2.ZERO, Vector2(100000000, 100000000), 0, 0.0, 1.0)]
	if not _bounded_fallback(Rect2(Vector2.ZERO, Vector2(100000000, 100000000)), "huge finite diagonal") or not _compare("huge finite diagonal uses bounded index fallback with old exact choices", 3) or not _check(game.feeders.size() == 2, "huge finite source still selects only the two deposits actually near its line"):
		return
	if not _bounded_fallback(Rect2(Vector2(100000000, 100000000), Vector2(-100000000, -100000000)), "negative-size huge rectangle normalizes safely"):
		return
	if not _bounded_fallback(Rect2(Vector2(1.0e20, -1.0e20), Vector2.ONE), "tiny rectangle beyond safe integer cell coordinates"):
		return
	game.segments.clear()
	game.feeders.clear()
	game.cores[0]["pos"] = Vector2(1.0e13, -1.0e13)
	if not _compare("far finite core avoids integer overflow and retains old no-target result") or not _check(game.feeders.is_empty(), "fallback does not connect distant deposits outside exact range"):
		return
	# Non-finite geometry has no meaningful exact-source comparison. Only the
	# broad phase must terminate and conservatively return the existing index.
	for invalid_bounds in [Rect2(Vector2(INF, 0), Vector2.ONE), Rect2(Vector2(NAN, 0), Vector2.ONE), Rect2(Vector2.ZERO, Vector2(INF, 1)), Rect2(Vector2.ZERO, Vector2(NAN, 1))]:
		if not _bounded_fallback(invalid_bounds, "non-finite rectangle"):
			return
	_reset_fixture()
	game.resources = [_resource(0, Vector2(10, 0), 0), _resource(1, Vector2(11, 0), 1)]
	game._rebuild_resource_grid()
	for index in range(game._active_feeder_capacity() - 1):
		game.feeders.append({"resource_id": 1000 + index, "core_id": 0, "a": Vector2.ZERO, "b": Vector2.ZERO, "growth": 0.0, "phase": 0.0})
	if not _compare("single remaining capacity retains organic-first reservation") or not _check(game.feeders.size() == game._active_feeder_capacity() and int(game.feeders.back()["resource_id"]) == 0, "last slot selection remains unchanged"):
		return
	if not _compare("full feeder capacity produces no additions"):
		return
	# Even legacy/non-monotonic sparse IDs retain original array-order ties.
	_reset_fixture()
	game.resources = [_resource(91, Vector2(20, 0), 0), _resource(10, Vector2(-20, 0), 0), _resource(42, Vector2(0, 20), 1)]
	game._rebuild_resource_grid()
	if not _compare("non-monotonic sparse IDs preserve old equal-distance order", 2) or not _check(int(game.feeders[0]["resource_id"]) == 91, "fallback retains original array order rather than numeric ID order"):
		return
	game.feeders.clear()
	for player in game.pixel_audio.players:
		player.stop()
		player.stream = null
	game.pixel_audio.ambient_player.stop()
	game.pixel_audio.ambient_player.stream = null
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("FEEDER_SPATIAL_QUERY_OK comparisons=%d baseline=5d9e6cc world_resources=%d initial_candidates=%d hotspot_candidates=%d bounded_queries=%d max_bounded_query_usec=%d order+source+range+curves+growth+death+sparse+developer+capacity=equivalent" % [comparisons, world_count, local_candidates.size(), hotspot_candidates.size(), bounded_queries, maximum_bounded_query_usec])
	quit(0)


func _reset_fixture() -> void:
	game.cores = [game._make_core(Vector2.ZERO)]
	game.segments.clear()
	game.feeders.clear()
	game.resources.clear()
	game.resource_grid.clear()
	game.structure_levels["feeders"] = 0
	game.game_over = false


func _resource(id: int, pos: Vector2, kind: int) -> Dictionary:
	return {"id": id, "pos": pos, "kind": kind, "amount": 2.0, "initial_amount": 2.0, "alive": true, "phase": 0.0}


func _segment(a: Vector2, b: Vector2, core_id: int, curve: float, growth: float) -> Dictionary:
	return {"a": a, "b": b, "core_id": core_id, "curve": curve, "growth": growth, "orphaned": false, "viability": 1.0}


func _compare(label: String, passes: int = 1) -> bool:
	for pass_index in range(passes):
		var rng_state: int = game.rng.state
		var expected := _reference_discover()
		game.rng.state = rng_state
		game._discover_feeders()
		comparisons += 1
		if not _check(game.feeders == expected, "%s pass=%d: complete ordered feeder dictionaries (resource ID, source position/owner, growth, phase) must match old full scan" % [label, pass_index]):
			return false
	return true


func _bounded_fallback(bounds: Rect2, label: String) -> bool:
	var cells := {}
	var started := Time.get_ticks_usec()
	game._add_feeder_query_cells(bounds, cells)
	var elapsed := Time.get_ticks_usec() - started
	bounded_queries += 1
	maximum_bounded_query_usec = maxi(maximum_bounded_query_usec, elapsed)
	if not _check(elapsed <= 250000, "%s: broad phase must return within 250 ms, not iterate rectangle area (elapsed_usec=%d)" % [label, elapsed]):
		return false
	if not _check(cells.size() == game.resource_grid.size(), "%s: fallback size is bounded by the existing index" % label):
		return false
	for cell in game.resource_grid:
		if not _check(cells.has(cell), "%s: conservative fallback retains every indexed cell" % label):
			return false
	return true


func _reference_discover() -> Array:
	# Verbatim algorithm from main.gd at 5d9e6cc, with only game prefixes and
	# result-array plumbing. Intentionally scans resources, never the new grid query.
	var result: Array = game.feeders.duplicate(true)
	if result.size() >= game._active_feeder_capacity():
		return result
	var connected := {}
	for feeder in result:
		connected[int(feeder["resource_id"])] = true
	var organic_candidates: Array = []
	var mineral_candidates: Array = []
	for resource in game.resources:
		if not bool(resource["alive"]) or float(resource["amount"]) <= 0.0005:
			continue
		var resource_id := int(resource["id"])
		if connected.has(resource_id):
			continue
		var p: Vector2 = resource["pos"]
		var source: Dictionary = game._nearest_colony_source(p, true)
		var core_id := int(source["core_id"])
		if core_id < 0:
			continue
		var distance := float(source["distance"])
		if distance <= game._feeder_range_for_core(core_id):
			var candidate := {"resource_id": resource_id, "a": source["point"], "b": p, "distance": distance, "core_id": core_id, "kind": int(resource["kind"])}
			if int(resource["kind"]) == 0:
				organic_candidates.append(candidate)
			else:
				mineral_candidates.append(candidate)
	organic_candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["distance"]) < float(right["distance"]))
	mineral_candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["distance"]) < float(right["distance"]))
	var selected: Array = []
	if not organic_candidates.is_empty():
		selected.append(organic_candidates.pop_front())
	if not mineral_candidates.is_empty():
		selected.append(mineral_candidates.pop_front())
	var remaining_candidates := organic_candidates + mineral_candidates
	remaining_candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["distance"]) < float(right["distance"]))
	while selected.size() < game.FEEDERS_PER_DISCOVERY and not remaining_candidates.is_empty():
		selected.append(remaining_candidates.pop_front())
	var count := mini(selected.size(), game._active_feeder_capacity() - result.size())
	for i in range(count):
		var candidate: Dictionary = selected[i]
		result.append({"resource_id": int(candidate["resource_id"]), "a": candidate["a"], "b": candidate["b"], "core_id": int(candidate["core_id"]), "growth": 0.0, "phase": game.rng.randf_range(0.0, TAU)})
	return result


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FEEDER_SPATIAL_QUERY_FAIL: " + message)
	quit(1)
	return false
