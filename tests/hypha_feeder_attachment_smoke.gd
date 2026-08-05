extends SceneTree


var assertion_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game.autosave_enabled = false
	game._enter_developer_mode()

	game.cores.clear()
	game.cores.append(game._make_core(Vector2.ZERO))
	game.segments.clear()
	var trunk := {
		"a": Vector2.ZERO,
		"b": Vector2(240.0, 20.0),
		"growth": 0.46,
		"core_id": 0,
		"curve": -0.34,
		"orphaned": false,
		"viability": 1.0
	}
	game.segments.append(trunk)

	var visible_points: PackedVector2Array = game._curved_points_grown(trunk["a"], trunk["b"], trunk["curve"], trunk["growth"])
	game.resources.clear()
	game.feeders.clear()
	game._add_resource(visible_points[3] + Vector2(12.0, -8.0), 0, 8.0)
	# A moving trunk is not yet a stable branch junction. Discovery waits for
	# maturation so the stored child origin can never be stranded by animation.
	game._discover_feeders()
	if not _check(game.feeders.is_empty(), "a growing trunk should not spawn a detachable feeder"):
		return

	trunk["growth"] = 1.0
	var mature_points: PackedVector2Array = game._curved_points_grown(trunk["a"], trunk["b"], trunk["curve"], trunk["growth"])
	game._discover_feeders()
	if not _check(game.feeders.size() == 1, "nearby organic nutrition should create one feeder"):
		return
	var stored_origin: Vector2 = game.feeders[0]["a"]
	if not _check(_distance_to_polyline(stored_origin, mature_points) < 0.001, "stored feeder origin should be on the curved main hypha"):
		return
	var straight_chord_distance := stored_origin.distance_to(Geometry2D.get_closest_point_to_segment(stored_origin, trunk["a"], trunk["b"]))
	if not _check(straight_chord_distance > 1.0, "regression setup should prove the origin came from the curve, not its straight chord"):
		return

	print("HYPHA_FEEDER_ATTACHMENT_OK:%d" % assertion_count)
	game.queue_free()
	await process_frame
	quit(0)


func _distance_to_polyline(point: Vector2, points: PackedVector2Array) -> float:
	var best := INF
	for index in range(points.size() - 1):
		best = minf(best, point.distance_to(Geometry2D.get_closest_point_to_segment(point, points[index], points[index + 1])))
	return best


func _check(condition: bool, message: String) -> bool:
	assertion_count += 1
	if condition:
		return true
	push_error("HYPHA_FEEDER_ATTACHMENT_FAIL: %s" % message)
	quit(1)
	return false
