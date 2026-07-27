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
	game.bacteria.clear()
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
	game.diet_levels["fungi"] = 1
	game.diet_unit_unlocks["suppressor"] = true
	game.diet_unit_unlocks["disperser"] = true
	game.diet_unit_unlocks["antifungal"] = true
	game.scout_upgrade_levels["vision"] = game.MAX_SCOUT_UPGRADE_LEVEL
	game.scout_upgrade_levels["speed"] = game.MAX_SCOUT_UPGRADE_LEVEL
	for i in range(game.MAX_EXPEDITION_SPORES):
		var unit_type := "suppressor" if i < 16 else ("antifungal" if i < 32 else "disperser")
		game._spawn_expedition_spore(barracks_id, unit_type)
		var deployed: Dictionary = game.expedition_units.back()
		if unit_type == "disperser":
			deployed["state"] = "attacking"
			deployed["target_kind"] = "bacteria"
			deployed["target_pos"] = Vector2(350.0, -92.0)
			deployed["pos"] = Vector2(278.0, -92.0)
			deployed["burst_cooldown"] = 0.0
		else:
			deployed["state"] = "deployed"
			deployed["deploy_progress"] = game._deploy_seconds_for_unit(unit_type)
			# Keep persistent zones far from the colony while measuring synchronized AoE bursts.
			deployed["pos"] = Vector2(-4200.0 + float(i % 16) * 45.0, 3000.0 + float(i / 16) * 45.0)
	game.ecology_events = [{
		"id": 1,
		"type": "toxin",
		"pos": Vector2(300.0, -120.0),
		"radius": game.ECOLOGY_TOXIN_ZONE_RADIUS,
		"phase": "active",
		"remaining": 9999.0,
		"anchor_core_id": barracks_id,
		"spawned": 0
	}]
	var enemy: Dictionary = game.enemy_fungi[0]
	enemy["state_time"] = 9999.0
	while game.enemy_hyphae.size() < game.ENEMY_FUNGUS_MAX_SEGMENTS * 3:
		var hypha_index: int = game.enemy_hyphae.size()
		var start: Vector2 = enemy["pos"]
		var angle := float(hypha_index) * 0.43
		game.enemy_hyphae.append({
			"id": game.next_enemy_hypha_id,
			"fungus_id": int(enemy["id"]),
			"a": start,
			"b": start + Vector2.from_angle(angle) * game.ENEMY_FUNGUS_SEGMENT_LENGTH,
			"growth": 1.0,
			"curve": 0.05,
			"viability": 1.0
		})
		game.next_enemy_hypha_id += 1
	game.enemy_guard_spores.clear()
	while game.enemy_guard_spores.size() < game.MAX_ENEMY_GUARD_SPORES:
		var guard_index: int = game.enemy_guard_spores.size()
		var guard: Dictionary = game._make_enemy_guard(int(enemy["id"]), (enemy["pos"] as Vector2) + Vector2.from_angle(float(guard_index) * 0.41) * 80.0)
		game.enemy_guard_spores.append(guard)
		game.next_enemy_guard_id += 1
	var started := Time.get_ticks_usec()
	# 120次批量更新相当于约2秒的60×压力负载。
	for i in range(120):
		game._update_bacteria(1.0)
		game._update_expedition_units(1.0)
		game._update_ecology_events(1.0)
		game._update_enemy_fungi(1.0)
		game._update_enemy_guard_spores(1.0)
		game._update_core_hazards(1.0)
		if i % 12 == 0:
			game._discover_feeders()
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	if game.lifetime_disperser_best_hit < 400:
		push_error("PERFORMANCE_FAIL: synchronized dispersers did not execute the intended dense AoE scan (best=%d)" % game.lifetime_disperser_best_hit)
		quit(1)
		return
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
	print("PERFORMANCE_OK bacteria=", game.bacteria.size(), " suppressor_zones=16 antifungal_zones=16 disperser_bursts=32 best_aoe_hit=", game.lifetime_disperser_best_hit, " enemy_hyphae=", game.enemy_hyphae.size(), " enemy_guards=", game.enemy_guard_spores.size(), " ecology_event=1 explored=", game.explored_cells.size(), " updates=120 elapsed_ms=", "%.1f" % elapsed_ms, " fog_render_ms=", "%.1f" % render_ms)
	game.queue_free()
	quit(0)
