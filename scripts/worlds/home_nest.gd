extends "res://scripts/worlds/culture_world.gd"


func generate_map(game) -> void:
	game.resources.clear()
	game.resource_grid.clear()
	game.bacteria.clear()
	game.resource_hotspots.clear()
	game.water_motes.clear()
	game.substrate_marks.clear()
	# Keep the original call and RNG order: old resource IDs remain stable.
	for _index in range(320):
		game._add_resource(game._random_world_point(80.0), 0, game.rng.randf_range(7.0, 16.0))
	for _index in range(64):
		game._add_resource(game._random_world_point(80.0), 1, game.rng.randf_range(2.0, 5.0))
	for _index in range(48):
		var center: Vector2 = game._random_world_point(380.0)
		game._scatter_cluster(center, game.rng.randi_range(24, 46), game.rng.randf_range(65.0, 145.0), 0, 8.0, 21.0, false)
	for _index in range(26):
		var center: Vector2 = game._random_world_point(380.0)
		game._scatter_cluster(center, game.rng.randi_range(8, 16), game.rng.randf_range(38.0, 82.0), 1, 2.0, 6.0, false)
	var anomaly_specs := [
		[Vector2(360, -90), 0, 88, 118.0],
		[Vector2(-300, 320), 1, 30, 72.0],
		[Vector2(-4200, 3100), 0, 104, 165.0],
		[Vector2(6400, -5100), 0, 92, 142.0],
		[Vector2(10500, 7600), 0, 116, 178.0],
		[Vector2(-11800, -6800), 0, 96, 150.0],
		[Vector2(5200, 4800), 1, 38, 88.0],
		[Vector2(-7600, 9200), 1, 34, 82.0],
		[Vector2(11200, -9800), 1, 42, 96.0]
	]
	for spec in anomaly_specs:
		game._scatter_cluster(spec[0], int(spec[2]), float(spec[3]), int(spec[1]), 12.0 if int(spec[1]) == 0 else 3.0, 30.0 if int(spec[1]) == 0 else 8.0, true)
	# The v0.21 append remains after every pre-existing resource.
	game._scatter_cluster(Vector2(2200.0, -1050.0), 36, 96.0, 0, 8.0, 18.0, false)
	game._seed_bacteria()
	game._generate_substrate()


func initialize_colony(game) -> void:
	game.founder_spore = game._make_founder_spore(Vector2.ZERO)
	if game.developer_mode_enabled:
		game._complete_founder_spore_germination()
	else:
		game._update_exploration()


func allows_ecology_events() -> bool:
	return true


func allows_legacy_chapter() -> bool:
	return true


func validate_definition() -> bool:
	return super.validate_definition() and scene_id == "home_nest"
