extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.splash_active = false
	game.autosave_enabled = false
	game._start_new_culture()
	game.founder_spore = {}
	game.cores.clear()
	game.cores.append(game._make_core(Vector2.ZERO, "barracks"))
	game.segments.clear()
	game.feeders.clear()
	game.bacteria.clear()
	game.enemy_fungi.clear()
	game.enemy_hyphae.clear()
	game.enemy_guard_spores.clear()
	game.ecology_events.clear()
	game.resources.clear()
	game._rebuild_resource_grid()
	game._spawn_expedition_spore(0, "forager")
	var unit: Dictionary = game.expedition_units[0]
	unit["pos"] = Vector2.ZERO
	unit["search_cooldown"] = 0.0
	game._update_exploration(false)
	game.offline_simulating = true
	game.offline_expedition_combat_active = false
	game.offline_expedition_toxin_active = false
	game._update_expedition_units(10.0, false)
	if not _check(unit.has("offline_idle_explored_count") and String(unit["state"]) == "idle", "a failed empty-world search may become quiescent"):
		return
	game._update_expedition_units(10.0, false)
	if not _check(is_zero_approx(float(unit["search_cooldown"])), "cached idle work must remain ready to search after settlement"):
		return
	game._reveal_exploration(Vector2(1500.0, 0.0), 300.0)
	game._update_expedition_units(10.0, false)
	if not _check(int(unit["offline_idle_explored_count"]) == game.explored_cells.size() and float(unit["search_cooldown"]) > 0.0, "new exploration must invalidate and refresh an idle search"):
		return
	unit["state"] = "moving"
	unit["manual"] = true
	unit["target_kind"] = "ground"
	unit["target_pos"] = Vector2(40.0, 0.0)
	game._update_expedition_units(10.0, false)
	if not _check((unit["pos"] as Vector2).distance_to(Vector2(40.0, 0.0)) <= game.EXPEDITION_ARRIVAL_DISTANCE and not unit.has("offline_idle_explored_count"), "manual movement must bypass and clear stale idle caching"):
		return
	unit["state"] = "idle"
	unit["manual"] = false
	unit["search_cooldown"] = 0.0
	game._update_exploration(false)
	game._update_expedition_units(10.0, false)
	game._add_resource(Vector2(50.0, 0.0), 0, 5.0)
	game._rebuild_resource_grid()
	game._update_expedition_units(10.0, false)
	if not _check(String(unit["state"]) == "moving" and String(unit["target_kind"]) == "resource" and not unit.has("offline_idle_explored_count"), "a nonempty resource index must immediately disable the empty-world fast path"):
		return
	unit["offline_idle_explored_count"] = game.explored_cells.size()
	game._reset_offline_settlement_state()
	if not _check(not unit.has("offline_idle_explored_count") and not game.offline_simulating, "settlement reset must discard transient idle state"):
		return
	print("OFFLINE_IDLE_TAIL_OK search=true exploration_invalidates=true manual_orders=true resources_invalidate=true reset=true")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("OFFLINE_IDLE_TAIL_FAIL: " + message)
	quit(1)
	return false
