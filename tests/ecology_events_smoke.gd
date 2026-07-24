extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "Main scene must load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false
	game.save_path = "user://ecology_events_test_save.json"
	var test_save_path := ProjectSettings.globalize_path(game.save_path)
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(test_save_path)
	game.bacteria.clear()

	game.ecology_event_countdown = 0.0
	game._update_ecology_events(1.0)
	if not _check(game.ecology_events.is_empty(), "Ecology events must remain disabled before bacterial feeding is unlocked"):
		return
	game.diet_levels["bacteria"] = 1
	game.diet_order.append("bacteria")
	game._update_ecology_events(1.0)
	if not _check(game.ecology_events.size() == 1 and String(game.ecology_events[0]["type"]) == "bloom" and String(game.ecology_events[0]["phase"]) == "warning", "The first unlocked ecology event should begin as a bacterial-bloom warning"):
		return
	var bloom: Dictionary = game.ecology_events[0]
	var bloom_id := int(bloom["id"])
	var biomass_before_warning := float(game.cores[0]["biomass"])
	game._update_core_hazards(10.0)
	if not _check(game.bacteria.is_empty() and is_equal_approx(float(game.cores[0]["biomass"]), biomass_before_warning), "A warning phase must not spawn bacteria or damage cores"):
		return
	var event_count_before: int = game.ecology_events.size()
	game._begin_ecology_event()
	if not _check(game.ecology_events.size() == event_count_before, "Only one ecology event may exist at a time"):
		return
	while game.bacteria.size() < game.MAX_BACTERIA - game.ECOLOGY_BLOOM_SPAWN_COUNT + 1:
		game.bacteria.append(game._make_bacterium(Vector2(5000.0 + game.bacteria.size(), 5000.0)))
	bloom["remaining"] = 0.0
	game._update_ecology_events(0.1)
	if not _check(String(bloom["phase"]) == "warning" and game._count_event_bacteria(bloom_id) == 0, "A bloom should remain in warning when fewer than sixteen population slots are available"):
		return
	game.bacteria.pop_back()
	bloom["remaining"] = 0.0
	game._update_ecology_events(0.1)
	if not _check(String(bloom["phase"]) == "active" and game._count_event_bacteria(bloom_id) == game.ECOLOGY_BLOOM_SPAWN_COUNT and game.bacteria.size() == game.MAX_BACTERIA, "Freeing the sixteenth slot should activate a full sixteen-bacterium bloom without exceeding the cap"):
		return
	var event_only: Array = []
	for bacterium in game.bacteria:
		if int(bacterium.get("event_id", -1)) == bloom_id:
			event_only.append(bacterium)
	game.bacteria = event_only
	var parent: Dictionary = game.bacteria[0]
	parent["stored"] = game.BACTERIA_DIVISION_NUTRIENT
	parent["cooldown"] = 0.0
	game._update_bacteria(0.25)
	if not _check(game._count_event_bacteria(bloom_id) >= game.ECOLOGY_BLOOM_SPAWN_COUNT + 1, "Bloom descendants should inherit the ecology event identifier"):
		return
	var kept: Array = []
	for bacterium in game.bacteria:
		if int(bacterium.get("event_id", -1)) == bloom_id and kept.size() < 3:
			kept.append(bacterium)
	game.bacteria = kept
	game._update_ecology_events(0.1)
	if not _check(game.ecology_events.is_empty() and game.lifetime_ecology_events_contained == 1 and game._goal_complete("ecology_response"), "Reducing a bloom to three tagged bacteria should contain it exactly once"):
		return
	game.dna = 0
	game.mineral = 0.0
	game._claim_goal("ecology_response")
	game._claim_goal("ecology_response")
	if not _check(game.dna == 2 and is_equal_approx(game.mineral, 2.0), "The ecology-response reward must grant DNA and mineral only once"):
		return

	game.bacteria.clear()
	game.ecology_event_countdown = 0.0
	game._update_ecology_events(0.1)
	if not _check(game.ecology_events.size() == 1 and String(game.ecology_events[0]["type"]) == "toxin", "The second ecology event should alternate to a toxin-zone warning"):
		return
	var toxin_event: Dictionary = game.ecology_events[0]
	toxin_event["remaining"] = 0.0
	game._update_ecology_events(0.1)
	if not _check(String(toxin_event["phase"]) == "active" and game.bacteria.is_empty(), "A toxin zone should activate without spawning a hidden bacterial army"):
		return
	var anchor_id := int(toxin_event["anchor_core_id"])
	var anchor_pos: Vector2 = game.cores[anchor_id]["pos"]
	game.bacteria_components["antibiotic"] = 0
	var full_toxin_rate: float = game._ecology_toxin_damage_rate_at(anchor_pos)
	game.bacteria_components["antibiotic"] = 3
	var mitigated_toxin_rate: float = game._ecology_toxin_damage_rate_at(anchor_pos)
	if not _check(is_equal_approx(full_toxin_rate, game.ECOLOGY_TOXIN_DAMAGE_RATE) and is_equal_approx(mitigated_toxin_rate, game.ECOLOGY_TOXIN_DAMAGE_RATE * 0.25), "Antibiotic levels should reduce toxin-zone damage monotonically to one quarter"):
		return
	game.bacteria_components["antibiotic"] = 0
	game.cores[anchor_id]["biomass"] = game.cores[anchor_id]["max_biomass"]
	var toxin_biomass_before := float(game.cores[anchor_id]["biomass"])
	game._update_core_hazards(10.0)
	if not _check(is_equal_approx(toxin_biomass_before - float(game.cores[anchor_id]["biomass"]), game.ECOLOGY_TOXIN_DAMAGE_RATE * 10.0), "Ten seconds inside a toxin zone should apply its exact bounded damage"):
		return
	toxin_event["remaining"] = 0.0
	game._update_ecology_events(0.1)
	if not _check(game.ecology_events.is_empty() and game.lifetime_ecology_events_contained == 2, "Surviving a toxin zone should resolve the second event"):
		return

	game.ecology_event_countdown = 0.0
	game._update_ecology_events(0.1)
	var saved_event: Dictionary = game.ecology_events[0]
	saved_event["remaining"] = 0.0
	game._update_ecology_events(0.1)
	saved_event["remaining"] = 23.0
	var offline_barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(saved_event["pos"], "barracks"))
	game._spawn_expedition_spore(offline_barracks_id, "forager")
	var offline_unit: Dictionary = game.expedition_units.back()
	offline_unit["pos"] = saved_event["pos"]
	offline_unit["state"] = "attacking"
	offline_unit["target_pos"] = game.bacteria[0]["pos"]
	for resource in game.resources:
		resource["alive"] = false
		resource["amount"] = 0.0
	for core in game.cores:
		core["biomass"] = core["max_biomass"]
	var event_timer_before_offline := float(saved_event["remaining"])
	var event_population_before_offline: int = game._count_event_bacteria(int(saved_event["id"]))
	var core_biomass_before_offline := float(game.cores[0]["biomass"])
	var cargo_before_offline := float(offline_unit["cargo_organic"])
	var kills_before_offline: int = game.lifetime_expedition_bacteria_killed
	game._apply_offline_progress(60.0, 60.0)
	if not _check(is_equal_approx(float(saved_event["remaining"]), event_timer_before_offline) and game._count_event_bacteria(int(saved_event["id"])) == event_population_before_offline and is_equal_approx(float(offline_unit["cargo_organic"]), cargo_before_offline) and game.lifetime_expedition_bacteria_killed == kills_before_offline and is_equal_approx(float(game.cores[0]["biomass"]), core_biomass_before_offline), "Offline freeze mismatch timer %.3f/%.3f population %d/%d cargo %.3f/%.3f kills %d/%d biomass %.3f/%.3f" % [float(saved_event["remaining"]), event_timer_before_offline, game._count_event_bacteria(int(saved_event["id"])), event_population_before_offline, float(offline_unit["cargo_organic"]), cargo_before_offline, game.lifetime_expedition_bacteria_killed, kills_before_offline, float(game.cores[0]["biomass"]), core_biomass_before_offline]):
		return
	game._close_offline_report()

	game._save_game()
	var saved_type := String(saved_event["type"])
	game.ecology_events.clear()
	game.lifetime_ecology_events_seen = 0
	game.lifetime_ecology_events_contained = 0
	if not _check(game._load_game() and game.ecology_events.size() == 1 and String(game.ecology_events[0]["type"]) == saved_type and game.lifetime_ecology_events_contained == 2, "Ecology event phase and lifetime counters should survive save/load"):
		return
	var save_file := FileAccess.open(game.save_path, FileAccess.READ)
	var legacy_data: Dictionary = JSON.parse_string(save_file.get_as_text())
	save_file.close()
	for key in ["ecology_events", "ecology_event_countdown", "next_ecology_event_id", "lifetime_ecology_events_seen", "lifetime_ecology_events_contained"]:
		legacy_data.erase(key)
	for item in legacy_data.get("bacteria", []):
		item.erase("event_id")
		item.erase("strain")
	save_file = FileAccess.open(game.save_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(legacy_data))
	save_file.close()
	game.ecology_events = [{"id": 99}]
	game.lifetime_ecology_events_seen = 99
	game.lifetime_ecology_events_contained = 99
	if not _check(game._load_game(), "A v0.19 save without ecology-event fields should remain loadable"):
		return
	if not _check(game.ecology_events.is_empty() and game.lifetime_ecology_events_seen == 0 and game.lifetime_ecology_events_contained == 0 and is_equal_approx(game.ecology_event_countdown, game.ECOLOGY_FIRST_EVENT_MAX), "Legacy saves should default ecology-event state safely"):
		return

	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(test_save_path)
	print("ECOLOGY_EVENTS_OK resolved=", game.lifetime_ecology_events_contained, " countdown=", "%.1f" % game.ecology_event_countdown, " bacteria=", game.bacteria.size())
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("ECOLOGY_EVENTS_FAIL: " + message)
	quit(1)
	return false
