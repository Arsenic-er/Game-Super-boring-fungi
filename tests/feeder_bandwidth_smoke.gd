extends SceneTree


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
	game._start_new_culture()
	if game._founder_spore_active():
		game._complete_founder_spore_germination()
	game.autosave_enabled = false
	game.main_menu_active = false
	game.game_started = true

	_prepare_fixture(game, 1, 6, 6, 0)
	var organic_before := float(game.organic)
	var mineral_before := float(game.mineral)
	game._update_feeders(10.0)
	if not _check(is_equal_approx(float(game.organic) - organic_before, 4.5) and is_equal_approx(float(game.mineral) - mineral_before, 1.2), "one core must cap mature feeders at 0.450 organic and 0.120 mineral per second"):
		return

	_prepare_fixture(game, 2, 6, 6, 0)
	organic_before = float(game.organic)
	mineral_before = float(game.mineral)
	game._update_feeders(10.0)
	if not _check(is_equal_approx(float(game.organic) - organic_before, 9.0) and is_equal_approx(float(game.mineral) - mineral_before, 2.4), "two independent cores must provide two independent feeder bandwidth pools"):
		return

	_prepare_fixture(game, 1, 6, 6, 5)
	organic_before = float(game.organic)
	mineral_before = float(game.mineral)
	game._update_feeders(10.0)
	if not _check(is_equal_approx(float(game.organic) - organic_before, 5.85) and is_equal_approx(float(game.mineral) - mineral_before, 1.56), "node level five must add exactly 30 percent feeder bandwidth"):
		return

	_prepare_fixture(game, 1, 6, 6, 0)
	game.resources[0]["amount"] = 0.05
	organic_before = float(game.organic)
	game._update_feeders(10.0)
	var total_taken := float(game.organic) - organic_before
	var first_taken := 0.05 - float(game.resources[0]["amount"])
	if not _check(is_equal_approx(total_taken, 4.5) and first_taken > 0.0 and first_taken <= 0.05, "proportional sharing must honor a nearly depleted source without wasting the core budget"):
		return

	print("FEEDER_BANDWIDTH_OK one_core=4.500/1.200 two_cores=9.000/2.400 node5=5.850/1.560")
	game.queue_free()
	quit(0)


func _prepare_fixture(game: Node, core_count: int, organic_feeders_per_core: int, mineral_feeders_per_core: int, node_level: int) -> void:
	game.feeders.clear()
	game.cores.clear()
	for core_index in range(core_count):
		var core: Dictionary = game._make_core(Vector2(float(core_index) * 180.0, 0.0), "normal")
		core["feeder_range_level"] = node_level
		game.cores.append(core)
	for resource in game.resources:
		resource["alive"] = false
		resource["amount"] = 0.0
	var resource_index := 0
	for core_index in range(core_count):
		for kind in [0, 1]:
			var count := organic_feeders_per_core if kind == 0 else mineral_feeders_per_core
			for feeder_index in range(count):
				var resource: Dictionary = game.resources[resource_index]
				resource["kind"] = kind
				resource["amount"] = 20.0
				resource["initial_amount"] = 20.0
				resource["alive"] = true
				resource["pos"] = Vector2(30.0 + float(feeder_index) * 4.0, float(core_index * 80 + kind * 24))
				game.feeders.append({
					"resource_id": int(resource["id"]),
					"core_id": core_index,
					"a": game.cores[core_index]["pos"],
					"b": resource["pos"],
					"growth": 1.0,
					"phase": 0.0,
				})
				resource_index += 1


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FEEDER_BANDWIDTH_FAIL: " + message)
	quit(1)
	return false
