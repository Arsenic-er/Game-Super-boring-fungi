extends SceneTree

const Localization = preload("res://scripts/gameplay_localization.gd")
const FEEDBACK_KEYS := ["uptake_active", "uptake_growing", "uptake_unlinked", "uptake_summary_fmt", "uptake_detail_fmt", "uptake_expand_hint", "uptake_growing_hint", "work_repairing", "work_wounded", "work_returning", "work_retreating", "work_hold", "work_harvest_empty", "work_harvest_patrol", "work_idle_gatherer", "work_gathering", "work_selection_hint"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.set_process(false)
	game.developer_mode_enabled = false
	game.autosave_enabled = false
	game.splash_active = false
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.main_menu_active = false
	game.game_started = true
	game.cores[0]["kind"] = "barracks"
	game.cores[0]["pos"] = Vector2.ZERO
	game.resources = [
		{"id": 0, "kind": 0, "alive": true, "amount": 3.0, "initial_amount": 3.0, "pos": Vector2(50, 0), "phase": 0.0},
		{"id": 1, "kind": 1, "alive": true, "amount": 2.0, "initial_amount": 2.0, "pos": Vector2(60, 10), "phase": 0.0}]
	game._rebuild_resource_grid()
	game._reveal_exploration(Vector2.ZERO, 500.0)
	game.feeders = [
		{"core_id": 0, "resource_id": 0, "growth": 1.0, "a": Vector2.ZERO, "b": Vector2(50, 0), "phase": 0.0},
		{"core_id": 0, "resource_id": 1, "growth": 0.5, "a": Vector2.ZERO, "b": Vector2(60, 10), "phase": 0.0}]
	if not _check(game._core_uptake_states(0) == ["uptake_active", "uptake_growing"], "organic and mineral have independent connection states"):
		return
	game.feeders.append({"core_id": 0, "resource_id": 0, "growth": 0.2})
	game.feeders.append({"core_id": 99, "resource_id": 1, "growth": 1.0})
	game.feeders.append({"core_id": 0, "resource_id": 999, "growth": 1.0})
	if not _check(game._core_uptake_states(0) == ["uptake_active", "uptake_growing"], "growing/other-core/invalid links do not override a working feeder"):
		return
	game.resources[0]["amount"] = 0.0005
	game.resources[1]["alive"] = false
	if not _check(game._core_uptake_states(0) == ["uptake_unlinked", "uptake_unlinked"], "exhausted or dead deposits are not reported as working"):
		return
	game.resources[0]["amount"] = 3.0
	game.resources[1]["alive"] = true
	game.cores[0]["alive"] = false
	if not _check(game._core_uptake_states(0) == ["uptake_unlinked", "uptake_unlinked"] and game._core_uptake_states(-1) == ["uptake_unlinked", "uptake_unlinked"], "dead and absent cores cannot absorb"):
		return
	game.cores[0]["alive"] = true
	# Remove deliberately malformed links before exercising real draw paths.
	game.feeders.resize(2)
	game._spawn_expedition_spore(0, "forager")
	var unit: Dictionary = game.expedition_units[0]
	unit["pos"] = Vector2.ZERO
	unit["harvest_enabled"] = true
	unit["harvest_min"] = Vector2(-100, -100)
	unit["harvest_max"] = Vector2(100, 100)
	unit["cargo_organic"] = 0.0
	unit["cargo_mineral"] = 0.0
	game._acquire_harvest_target(unit)
	if not _check(not bool(unit.get("harvest_search_empty", true)) and unit["target_kind"] == "resource", "real successful search clears the no-target hint"):
		return
	game.resources[0]["alive"] = false
	game._acquire_harvest_target(unit)
	if not _check(bool(unit.get("harvest_search_empty", false)) and unit["target_kind"] == "harvest_patrol", "no eligible organic target records a local search result, ignoring minerals"):
		return
	game.resources[0]["alive"] = true
	game._acquire_harvest_target(unit)
	if not _check(not bool(unit["harvest_search_empty"]), "new eligible target removes the stale empty-search result"):
		return
	game.explored_cells.clear()
	game._acquire_harvest_target(unit)
	if not _check(bool(unit["harvest_search_empty"]), "hidden resources are unavailable, not globally depleted"):
		return
	game._reveal_exploration(Vector2.ZERO, 500.0)
	unit["pos"] = Vector2(500, 0)
	game._enforce_harvest_zone(unit)
	if not _check(not unit.has("harvest_search_empty") and unit["target_kind"] == "harvest_patrol", "travel back into the zone must not claim an empty search"):
		return
	unit["pos"] = Vector2.ZERO
	game._clear_unit_harvest(unit)
	var balance := Vector3(game.organic, game.mineral, game.dna)
	game.toast_text = "feedback must not spam"
	for locale_id in Localization.LOCALES:
		game.settings_locale = locale_id
		for key in FEEDBACK_KEYS:
			if not _check((Localization.TEXTS[locale_id] as Dictionary).has(key) and not game._gt(key).strip_edges().is_empty(), "explicit feedback translation: %s/%s" % [locale_id, key]):
				return
		for state in ["repairing", "wounded", "returning", "retreating", "gathering"]:
			unit["state"] = state
			unit["harvest_search_empty"] = true
			if not _check(game._expedition_work_hint(unit) == game._gt("work_" + state), "actual transport and repair states take priority over stale search feedback"):
				return
		game._set_expedition_hold(unit, Vector2.ZERO)
		if not _check(game._expedition_work_hint(unit) == game._gt("work_hold"), "manual hold is not automatic search"):
			return
		unit["manual"] = false
		unit["state"] = "idle"
		if not _check(game._expedition_work_hint(unit) == game._gt("work_idle_gatherer"), "no persistent area is valid automatic gathering"):
			return
		unit["harvest_enabled"] = true
		unit["target_kind"] = "harvest_patrol"
		unit["state"] = "moving"
		unit["harvest_search_empty"] = true
		if not _check(game._expedition_work_hint(unit) == game._gt("work_harvest_empty"), "failed-search hint is localized"):
			return
		unit.erase("harvest_search_empty")
		if not _check(game._expedition_work_hint(unit) == game._gt("work_harvest_patrol"), "newly loaded or travelling patrol does not falsely claim depletion"):
			return
		game._clear_unit_harvest(unit)
		game.offline_simulating = true
		for i in range(25):
			game._core_uptake_summary(0)
			game._expedition_work_hint(unit)
		game.offline_simulating = false
		if not _check(game.toast_text == "feedback must not spam" and Vector3(game.organic, game.mineral, game.dna) == balance, "feedback never spends, orders, or emits online/offline toasts"):
			return
		game.lifetime_organic_absorbed = 500.0 - 0.00000000001
		game.lifetime_mineral_absorbed = 25.0 - 0.00000000001
		game.lifetime_expedition_organic_returned = 5.99999999999996
		if not _check(game._chapter_supply_ready() and game._chapter_task_detail({"id": "secure_supply"}) == game._ct("supply_progress_fmt") % [500.0, 500.0, 25.0, 25.0, 6.0, 6.0], "floating delivery totals and display share the same microscopic tolerance"):
			return
		game.lifetime_expedition_organic_returned = 5.999
		if not _check(not game._chapter_supply_ready() and game._chapter_bounded_progress(1999.999, 2000.0) < 2000.0 and game._chapter_bounded_progress(2000.0 - 0.0000000001, 2000.0) == 2000.0, "display-scale shortfalls still fail; only float noise is normalized"):
			return
		for viewport in [Vector2i(1280, 720), Vector2i(640, 360)]:
			root.size = viewport
			game.selected_core = 0
			game.show_status = true
			game.selected_expedition_ids.clear()
			game.last_mouse = game.world_to_screen(Vector2.ZERO)
			game.queue_redraw()
			await process_frame
			game.show_status = false
			game.selected_core = -1
			game.selected_expedition_ids = [int(unit["id"])]
			var panel: Rect2 = game._selection_status_rect(Vector2(viewport))
			var button: Rect2 = game._defense_zone_button_rect(Vector2(viewport), 0)
			if not _check(button.position.y >= panel.position.y + 74.0 and button.end.y <= panel.end.y, "work hint occupies its own row above selection buttons"):
				return
			game.queue_redraw()
			await process_frame
	for player in game.pixel_audio.players:
		player.stop()
		player.stream = null
	game.pixel_audio.ambient_player.stop()
	game.pixel_audio.ambient_player.stream = null
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("RESOURCE_FEEDBACK_OK locales=7 uptake=per-kind+live-links work=search+patrol+hold+repair+delivery no-spam=true layouts=1280+640 float-boundary=true")
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("RESOURCE_FEEDBACK_FAIL: " + message)
	quit(1)
	return false
