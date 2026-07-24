extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if packed == null:
		push_error("PERFORMANCE_FAIL: main scene did not load")
		quit(1)
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false
	while game.bacteria.size() < game.MAX_BACTERIA:
		var index: int = game.bacteria.size()
		var offset := Vector2(float(index % 21) * 4.0, float(index / 21) * 4.0)
		var bacterium: Dictionary = game._make_bacterium(Vector2(310.0, -130.0) + offset)
		bacterium["stored"] = 0.0
		bacterium["cooldown"] = 9999.0
		bacterium["seek_cooldown"] = 0.0
		game.bacteria.append(bacterium)
	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(300.0, -120.0), "barracks"))
	game.diet_levels["bacteria"] = 1
	for i in range(game.MAX_EXPEDITION_SPORES):
		game._spawn_expedition_spore(barracks_id, "scout" if i % 8 == 0 else "forager")
	var started := Time.get_ticks_usec()
	# 120次批量更新相当于约2秒的60×压力负载。
	for i in range(120):
		game._update_bacteria(1.0)
		game._update_expedition_units(1.0)
		game._update_core_hazards(1.0)
		if i % 12 == 0:
			game._discover_feeders()
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	if elapsed_ms > 3000.0:
		push_error("PERFORMANCE_FAIL: 420-bacteria accelerated simulation took %.1f ms" % elapsed_ms)
		quit(1)
		return
	game.camera_zoom = 0.018
	game.camera_center = Vector2.ZERO
	var render_started := Time.get_ticks_usec()
	game.queue_redraw()
	await process_frame
	await process_frame
	var render_ms := float(Time.get_ticks_usec() - render_started) / 1000.0
	if render_ms > 1000.0:
		push_error("PERFORMANCE_FAIL: full-dish fog render took %.1f ms" % render_ms)
		quit(1)
		return
	print("PERFORMANCE_OK bacteria=", game.bacteria.size(), " expedition=", game.expedition_units.size(), " explored=", game.explored_cells.size(), " updates=120 elapsed_ms=", "%.1f" % elapsed_ms, " fog_render_ms=", "%.1f" % render_ms)
	game.queue_free()
	quit(0)
