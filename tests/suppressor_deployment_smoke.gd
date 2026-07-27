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
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false
	game.save_path = "user://suppressor_deployment_smoke.json"
	game.dna = 10

	game._purchase_diet_unit("bacteria", "suppressor")
	if not _check(not bool(game.diet_unit_unlocks["suppressor"]) and game.dna == 10, "suppressor should remain unavailable without bacteria diet"):
		return
	game.diet_levels["bacteria"] = 1
	game.diet_order = ["bacteria"]
	game._purchase_diet_unit("bacteria", "suppressor")
	if not _check(bool(game.diet_unit_unlocks["suppressor"]) and game.dna == 5 and game._available_barracks_units().has("suppressor"), "bacteria diet should unlock suppressor for five DNA"):
		return
	if not _check(is_equal_approx(float(game.UNIT_ORGANIC_COSTS["suppressor"]), 11.0) and is_equal_approx(float(game.UNIT_MINERAL_COSTS["suppressor"]), 0.75) and is_equal_approx(float(game.UNIT_BUILD_SECONDS["suppressor"]), 38.0), "suppressor production balance should match v0.28"):
		return

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(100.0, 0.0), "barracks"))
	game._spawn_expedition_spore(barracks_id, "suppressor")
	var suppressor: Dictionary = game.expedition_units.back()
	suppressor["pos"] = Vector2(120.0, 0.0)
	game._spawn_expedition_spore(barracks_id, "forager")
	var forager: Dictionary = game.expedition_units.back()
	forager["pos"] = Vector2(120.0, 6.0)
	game.bacteria = [game._make_bacterium(Vector2(150.0, 0.0))]
	game._reveal_exploration(Vector2(150.0, 0.0), 220.0)
	game.camera_center = Vector2(150.0, 0.0)
	game.camera_zoom = 1.0
	game.selected_expedition_ids = [int(suppressor["id"]), int(forager["id"])]
	game._issue_expedition_command(game.world_to_screen(Vector2(150.0, 0.0)))
	if not _check(String(suppressor["target_kind"]) == "deploy_zone" and String(forager["target_kind"]) == "bacteria", "mixed right-click should deploy suppressor while combat units keep their normal target"):
		return

	game._update_expedition_units(1.0, false)
	if not _check(String(suppressor["state"]) == "deploying" and is_zero_approx(float(suppressor["deploy_progress"])), "suppressor should begin unfolding after reaching its target"):
		return
	game._update_expedition_units(3.9, false)
	if not _check(String(suppressor["state"]) == "deploying", "deployment should not finish before four seconds"):
		return
	game._update_expedition_units(0.1, false)
	if not _check(String(suppressor["state"]) == "deployed" and is_equal_approx(float(suppressor["deploy_progress"]), 4.0), "deployment should finish at four seconds"):
		return

	game.bacteria = [game._make_bacterium(Vector2(160.0, 0.0)), game._make_bacterium(Vector2(360.0, 0.0))]
	for bacterium in game.bacteria:
		bacterium["contact_cooldown"] = 0.0
	game.bacteria_components["antibiotic"] = 0
	game._update_bacteria(0.25)
	if not _check(is_equal_approx(float(game.bacteria[0]["suppression_multiplier"]), 0.30) and is_equal_approx(float(game.bacteria[1]["suppression_multiplier"]), 1.0), "deployed zone should suppress only bacteria inside its radius"):
		return
	game.bacteria_components["antibiotic"] = 1
	game.bacteria[0]["contact_cooldown"] = 0.0
	game._update_bacteria(0.25)
	if not _check(is_equal_approx(float(game.bacteria[0]["suppression_multiplier"]), 0.30), "zone and level-one antibiotics should take the stronger effect without multiplying"):
		return
	game.bacteria_components["antibiotic"] = 3
	game.bacteria[0]["contact_cooldown"] = 0.0
	game._update_bacteria(0.25)
	if not _check(is_equal_approx(float(game.bacteria[0]["suppression_multiplier"]), 0.25), "level-three antibiotics should remain stronger than the deployed zone"):
		return
	game.bacteria[0]["cooldown"] = 10.0
	game.bacteria[0]["contact_cooldown"] = 999.0
	game._update_bacteria(1.0)
	if not _check(is_equal_approx(float(game.bacteria[0]["cooldown"]), 9.75), "the actual division cooldown should use the stronger 0.25 antibiotic multiplier"):
		return

	game.bacteria_components["antibiotic"] = 0
	game.selected_expedition_ids = [int(suppressor["id"])]
	game._issue_expedition_command(game.world_to_screen(Vector2(250.0, 0.0)))
	game.bacteria[0]["contact_cooldown"] = 999.0
	game._update_bacteria(0.1)
	if not _check(String(suppressor["state"]) == "moving" and is_zero_approx(float(suppressor["deploy_progress"])) and is_equal_approx(game._suppressor_multiplier_at(Vector2(160.0, 0.0)), 1.0) and not bool(game.bacteria[0]["suppressed_by_deployment"]), "redeployment should collapse the old zone immediately without waiting for the contact cache"):
		return
	game._update_expedition_units(4.0, false)
	game._update_expedition_units(4.0, false)
	if not _check(String(suppressor["state"]) == "deployed" and is_equal_approx(game._suppressor_multiplier_at(Vector2(250.0, 0.0)), 0.30), "suppressor should unfold again at its new position"):
		return

	game.bacteria_components["antibiotic"] = 0
	game.bacteria.clear()
	for i in range(10):
		var event_bacterium: Dictionary = game._make_bacterium(Vector2(250.0, 0.0) + Vector2.from_angle(float(i)) * 20.0)
		event_bacterium["event_id"] = 77
		event_bacterium["contact_cooldown"] = 0.0
		game.bacteria.append(event_bacterium)
	game.ecology_events = [{"id": 77, "type": "bloom", "pos": Vector2(250.0, 0.0), "radius": 110.0, "phase": "active", "remaining": 120.0, "anchor_core_id": 0, "spawned": 10, "control_progress": 0.0, "controlled_by_suppressor": false}]
	game._update_bacteria(0.25)
	game._update_ecology_events(6.0)
	if not _check(is_equal_approx(float(game.ecology_events[0]["control_progress"]), 6.0), "continuous field coverage should accumulate containment progress"):
		return
	for i in range(4):
		game.bacteria[i]["pos"] = Vector2(600.0 + float(i) * 12.0, 0.0)
		game.bacteria[i]["contact_cooldown"] = 0.0
	game._update_bacteria(0.25)
	game._update_ecology_events(0.1)
	if not _check(is_zero_approx(float(game.ecology_events[0]["control_progress"])), "losing coverage of more than three bloom bacteria should reset the hold"):
		return
	for i in range(4):
		game.bacteria[i]["pos"] = Vector2(250.0 + float(i) * 4.0, 0.0)
		game.bacteria[i]["contact_cooldown"] = 0.0
	game._update_bacteria(0.25)
	game._update_ecology_events(11.9)
	if not _check(game.ecology_events.size() == 1 and is_equal_approx(float(game.ecology_events[0]["control_progress"]), 11.9), "suppressed bloom should require the full twelve-second hold"):
		return
	game.selected_expedition_ids = [int(suppressor["id"])]
	game._issue_expedition_command(game.world_to_screen(Vector2(400.0, 0.0)))
	game._update_ecology_events(0.1)
	if not _check(game.ecology_events.size() == 1 and is_zero_approx(float(game.ecology_events[0]["control_progress"])), "collecting a suppressor at 11.9 seconds should immediately break containment"):
		return
	suppressor["pos"] = Vector2(250.0, 0.0)
	suppressor["state"] = "deployed"
	suppressor["deploy_progress"] = 4.0
	game._update_ecology_events(11.9)
	game._update_ecology_events(0.1)
	if not _check(game.ecology_events.is_empty() and game.lifetime_suppressed_blooms_contained == 1 and game._goal_complete("suppression_field"), "twelve seconds of coverage should contain the bloom and complete the specialist goal"):
		return
	game._damage_expedition_unit(suppressor, 9.0, "deployment test")
	if not _check(String(suppressor["state"]) == "retreating" and is_zero_approx(float(suppressor["deploy_progress"])), "a critically damaged deployed suppressor should collapse and retreat for repair"):
		return

	suppressor["state"] = "deployed"
	suppressor["deploy_progress"] = 4.0
	suppressor["biomass"] = suppressor["max_biomass"]
	game._save_game()
	if not _check(game._load_game(), "suppressor state should load"):
		return
	var loaded_suppressor: Dictionary = game.expedition_units[0]
	if not _check(String(loaded_suppressor["state"]) == "deployed" and is_equal_approx(float(loaded_suppressor["deploy_progress"]), 4.0) and game.lifetime_suppressed_blooms_contained == 1, "deployed state, progress, and specialist result should round-trip"):
		return
	game.bacteria.clear()
	for i in range(6):
		var saved_event_bacterium: Dictionary = game._make_bacterium(Vector2(250.0 + float(i), 0.0))
		saved_event_bacterium["event_id"] = 88
		game.bacteria.append(saved_event_bacterium)
	game.ecology_events = [{"id": 88, "type": "bloom", "pos": Vector2(250.0, 0.0), "radius": 110.0, "phase": "active", "remaining": 60.0, "anchor_core_id": 0, "spawned": 6, "control_progress": 6.0, "controlled_by_suppressor": false}]
	game._save_game()
	if not _check(game._load_game(), "active suppressor containment should load"):
		return
	game._update_ecology_events(0.1)
	if not _check(game.ecology_events.size() == 1 and is_equal_approx(float(game.ecology_events[0]["control_progress"]), 6.1), "loaded containment progress should continue from live zone geometry instead of resetting"):
		return

	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	legacy.erase("lifetime_suppressed_blooms_contained")
	for event in legacy.get("ecology_events", []):
		event.erase("control_progress")
		event.erase("controlled_by_suppressor")
	var legacy_unlocks: Dictionary = legacy.get("diet_unit_unlocks", {})
	legacy_unlocks.erase("suppressor")
	legacy["diet_unit_unlocks"] = legacy_unlocks
	var legacy_units: Array = []
	for unit in legacy["expedition_units"]:
		if String(unit.get("unit_type", "forager")) != "suppressor":
			unit.erase("deploy_progress")
			legacy_units.append(unit)
	legacy["expedition_units"] = legacy_units
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game() and game.lifetime_suppressed_blooms_contained == 0 and not bool(game.diet_unit_unlocks["suppressor"]), "v0.27 saves should default new suppressor fields safely"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("SUPPRESSOR_DEPLOYMENT_OK unlock=true deploy=4 radius=140 multiplier=0.30 bloom=12 save=compatible")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("SUPPRESSOR_DEPLOYMENT_FAIL: " + message)
	quit(1)
	return false
