extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "Main scene must load"):
		return
	var game: Node = packed.instantiate()
	if not _check(game.get_script() != null, "Main script must parse and attach to the scene"):
		return
	root.add_child(game)
	await process_frame
	if not _check(game.splash_active and game.splash_logo != null and game.cursor_texture != null, "Splash logo and green pixel cursor should load when the game starts"):
		return
	game.splash_active = false
	if not _check(game.main_menu_active and not game.game_started and game.cores.is_empty(), "Splash should lead to a paused main menu without loading or creating a culture"):
		return
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false
	if not _check(game.cores.size() == 1, "Starting a new culture should create exactly one spore core"):
		return
	if not _check(game._is_world_explored(Vector2.ZERO) and not game._is_world_explored(Vector2(8000.0, 8000.0)), "A new culture should reveal its starting area while distant regions remain under fog"):
		return
	if not _check(game.WORLD_HALF >= 16000.0 and game.camera_zoom <= 0.65, "Micro world should be enlarged and start with a wider camera"):
		return
	for resource in game.resources:
		if not _check((resource["pos"] as Vector2).length() <= game.WORLD_HALF, "Every resource must stay inside the circular culture dish"):
			return
	game._zoom_at(game.get_viewport_rect().size * 0.5, 0.0001)
	if not _check(is_equal_approx(game.camera_zoom, 0.018), "Camera should zoom out far enough to show the complete culture dish"):
		return
	game.camera_zoom = 0.65
	if not _check(game.selected_core == -1, "Core menu must be closed when the chapter opens"):
		return
	if not _check(game.resource_hotspots.size() >= 20, "World should contain clustered resource regions"):
		return
	if not _check(game.bacteria.size() >= 40 and game.bacteria.size() <= game.MAX_BACTERIA, "Culture dish should start with sparse stationary bacterial colonies"):
		return
	var first_bacterium_pos: Vector2 = game.bacteria[0]["pos"]
	game._update_bacteria(1.0)
	if not _check((game.bacteria[0]["pos"] as Vector2).is_equal_approx(first_bacterium_pos), "Bacteria must remain stationary while absorbing nutrition"):
		return
	var anomaly_count := 0
	for resource in game.resources:
		if int(resource["kind"]) == 0 and (resource["pos"] as Vector2).distance_to(Vector2(360.0, -90.0)) <= 118.0:
			anomaly_count += 1
	if not _check(anomaly_count >= 70, "Organic anomaly should be visibly denser than the background"):
		return
	game.cores.clear()
	game.cores.append(game._make_core(Vector2.ZERO))
	game.segments.clear()
	game.organic = 220.0
	game.mineral = 24.0
	game.dna = 0
	game.selected_core = 0
	game.selected_tip_valid = false
	game.menu_anim = 0.0
	game._process(0.25)
	if not _check(game.menu_anim > 0.0, "Core menu should animate open after selection"):
		return
	var menu_buttons: Array = game._current_menu_buttons()
	if not _check(menu_buttons.size() == 6 and String(menu_buttons[0]["tooltip_cost"]).contains("1.000") and String(menu_buttons[5]["action"]) == "barracks_mode", "Core menu should expose barracks construction alongside its normal actions"):
		return
	var range_before: float = game._feeder_range_for_core(0)
	var dna_duration_before: float = game._dna_job_duration(0)
	game._upgrade_feeder_range(0)
	if not _check(int(game.cores[0]["feeder_range_level"]) == 1 and is_equal_approx(game.organic, 175.0), "First range upgrade should cost 45 organic nutrition"):
		return
	if not _check(is_equal_approx(game._feeder_range_for_core(0), range_before + 24.0), "Range upgrade should add 12 micrometers"):
		return
	if not _check(is_equal_approx(dna_duration_before, 180.0) and is_equal_approx(game._dna_job_duration(0), 180.0 / 1.15), "Base DNA time should be 180 seconds and node upgrade should add 15 percent speed"):
		return
	game.upgrade_open = false
	game._handle_left_click(game._upgrade_hud_rect().get_center())
	if not _check(game.upgrade_open and game.upgrade_core_id == 0, "HUD upgrade button should open the upgrade interface"):
		return
	var upgrade_panel: Rect2 = game._upgrade_panel_rect(game.get_viewport_rect().size)
	var tabs: Array = game._upgrade_tab_rects(upgrade_panel)
	game._handle_upgrade_click((tabs[1] as Rect2).get_center())
	if not _check(game.upgrade_tab == 1, "Upgrade interface should switch between category tabs"):
		return
	game._handle_upgrade_click(game._upgrade_close_rect(upgrade_panel).get_center())
	if not _check(not game.upgrade_open, "Upgrade interface close button should work"):
		return
	game.selected_core = 0

	var organic_before: float = game.organic
	game._confirm_extension(Vector2(176.0, 0.0))
	if not _check(game.segments.size() == 1, "Extension should create one hypha segment"):
		return
	if not _check(game.organic < organic_before, "Extension should consume organic nutrition"):
		return
	if not _check(int(game.segments[0]["core_id"]) == 0, "Extension belongs to the selected core"):
		return
	var before_first_goal: float = game.organic
	game._claim_goal("first_hypha")
	if not _check(is_equal_approx(game.organic, before_first_goal + 25.0) and bool(game.goals_claimed.get("first_hypha", false)), "First hypha goal should reward organic nutrition"):
		return

	game._update_growth(24.0)
	if not _check(is_equal_approx(float(game.segments[0]["growth"]), 1.0), "Hypha should finish after its growth duration"):
		return
	game.selected_core = 0
	game._apply_menu_action("barracks_mode")
	if not _check(game.mode == "place_barracks" and not game.selected_tip_valid, "Core barracks button should enter highlighted tip placement mode"):
		return
	game.mode = "normal"

	game.resources.clear()
	game.feeders.clear()
	game.resources.append({
		"id": 0,
		"pos": Vector2(100.0, 0.0),
		"kind": 0,
		"amount": 15.0,
		"initial_amount": 15.0,
		"alive": true,
		"phase": 0.0
	})
	game.resources.append({
		"id": 1,
		"pos": Vector2(108.0, 8.0),
		"kind": 1,
		"amount": 3.0,
		"initial_amount": 3.0,
		"alive": true,
		"phase": 0.0
	})
	var before_absorb: float = game.organic
	var before_mineral: float = game.mineral
	game._discover_feeders()
	if not _check(game.feeders.size() == 2, "One discovery cycle should reserve feeders for both organic and mineral resources"):
		return
	if not _check(is_equal_approx(game.organic, before_absorb), "Discovering nutrition must not absorb it instantly"):
		return
	for feeder in game.feeders:
		feeder["growth"] = 1.0
	game._update_feeders(10.0)
	if not _check(is_equal_approx(game.organic, before_absorb + 1.0), "Organic absorption should advance at 0.100 per second"):
		return
	if not _check(is_equal_approx(game.mineral, before_mineral + 0.3), "Mineral absorption should advance at 0.030 per second"):
		return
	if not _check(bool(game.resources[0]["alive"]) and is_equal_approx(float(game.resources[0]["amount"]), 14.0), "Resource pixel must remain while partially depleted"):
		return
	game._update_feeders(140.0)
	if not _check(not bool(game.resources[0]["alive"]) and is_equal_approx(game.organic, before_absorb + 15.0), "A 15-point resource should take 150 seconds to deplete"):
		return
	if not _check(not bool(game.resources[1]["alive"]) and game.feeders.is_empty(), "Depleted mineral connections should be removed from the feeder cap"):
		return
	var mineral_before_goal: float = game.mineral
	game._claim_goal("mineral_trace")
	if not _check(is_equal_approx(game.mineral, mineral_before_goal + 5.0), "Mineral goal should grant a mineral reward"):
		return

	game.dna = 4000
	game._purchase_diet("animal")
	if not _check(game.dna == 3997 and int(game.diet_levels["animal"]) == 1 and is_equal_approx(game._diet_efficiency("animal"), 0.20), "First diet should cost 3 DNA and start at 20 percent efficiency"):
		return
	game._purchase_diet("plant")
	game._purchase_diet("bacteria")
	game._purchase_diet("fungi")
	if not _check(game.dna == 667 and game.diet_order.size() == 4, "Additional diet unlock costs should increase tenfold: 30, 300, 3000"):
		return
	game._purchase_diet("animal")
	if not _check(game.dna == 665 and int(game.diet_levels["animal"]) == 2 and is_equal_approx(game._diet_efficiency("animal"), 0.40), "Diet efficiency should upgrade independently after unlock"):
		return
	game._claim_goal("primary_diet")
	if not _check(game.dna == 668, "Primary diet goal should grant a DNA reward"):
		return
	game.upgrade_open = true
	game.upgrade_tab = 1
	var diet_panel: Rect2 = game._upgrade_panel_rect(game.get_viewport_rect().size)
	game._handle_upgrade_click(game._diet_components_button_rect(diet_panel, 2).get_center())
	if not _check(game.diet_detail_id == "bacteria", "Unlocked bacteria diet should open its dedicated component page"):
		return
	game._handle_upgrade_click(game._bacteria_components_back_rect(diet_panel).get_center())
	if not _check(game.diet_detail_id == "", "Bacteria component page should return to the diet overview"):
		return
	game.upgrade_open = false

	game.resources.clear()
	game.bacteria.clear()
	var test_bacterium: Dictionary = game._make_bacterium(Vector2(1000.0, 1000.0))
	test_bacterium["stored"] = 0.0
	test_bacterium["cooldown"] = 100.0
	test_bacterium["resource_id"] = -1
	game.bacteria.append(test_bacterium)
	game.resources.append({
		"id": 0, "pos": Vector2(1000.0, 1000.0), "kind": 0,
		"amount": 10.0, "initial_amount": 10.0, "alive": true, "phase": 0.0
	})
	game._rebuild_resource_grid()
	game._update_bacteria(20.0)
	if not _check(is_equal_approx(float(game.resources[0]["amount"]), 9.9) and is_equal_approx(float(game.bacteria[0]["stored"]), 0.1), "One bacterium should absorb organic nutrition at 0.005 per second, one twentieth of the initial fungus"):
		return
	if not _check((game.bacteria[0]["pos"] as Vector2).is_equal_approx(Vector2(1000.0, 1000.0)), "Bacterial nutrition uptake must not move the bacterium"):
		return
	game.bacteria[0]["stored"] = game.BACTERIA_DIVISION_NUTRIENT
	game.bacteria[0]["cooldown"] = 0.0
	game._update_bacteria(0.01)
	if not _check(game.bacteria.size() == 2 and (game.bacteria[1]["pos"] as Vector2).distance_to(game.bacteria[0]["pos"]) <= 24.1, "Fed bacteria should divide locally without movement"):
		return
	game.resources.clear()
	game.bacteria.clear()
	var prey: Dictionary = game._make_bacterium(Vector2.ZERO)
	prey["stored"] = 0.0
	prey["biomass"] = 1.0
	game.bacteria.append(prey)
	var before_predation: float = game.organic
	game._update_bacteria(10.0)
	if not _check(is_equal_approx(float(game.bacteria[0]["biomass"]), 0.9) and is_equal_approx(game.organic, before_predation + 0.1), "Unlocked bacteria diet should digest stationary bacteria on hypha contact at its current efficiency"):
		return

	game._purchase_bacteria_component("trap")
	game._purchase_bacteria_component("enzymes")
	game._purchase_bacteria_component("antibiotic")
	if not _check(game.dna == 656 and int(game.bacteria_components["trap"]) == 1 and int(game.bacteria_components["enzymes"]) == 1 and int(game.bacteria_components["antibiotic"]) == 1, "First bacteria components should cost 3, 4, and 5 DNA independently"):
		return
	if not _check(is_equal_approx(game._bacteria_capture_radius(), 30.0) and is_equal_approx(game._bacteria_digestion_multiplier(), 1.35) and is_equal_approx(game._antibiotic_bacteria_multiplier(), 0.75), "Bacteria components should change capture, digestion, and suppression effects"):
		return
	game.resources.clear()
	game.bacteria.clear()
	var suppressed_bacterium: Dictionary = game._make_bacterium(Vector2(50.0, 0.0))
	suppressed_bacterium["stored"] = 0.0
	suppressed_bacterium["cooldown"] = 100.0
	suppressed_bacterium["contact_cooldown"] = 0.0
	game.bacteria.append(suppressed_bacterium)
	game.resources.append({
		"id": 0, "pos": Vector2(50.0, 0.0), "kind": 0,
		"amount": 10.0, "initial_amount": 10.0, "alive": true, "phase": 0.0
	})
	game._rebuild_resource_grid()
	game._update_bacteria(20.0)
	if not _check(bool(game.bacteria[0]["suppressed"]) and is_equal_approx(float(game.bacteria[0]["stored"]), 0.075), "Level-one antibiotics should reduce nearby bacterial absorption to 75 percent"):
		return

	game._purchase_structure("branching")
	game._purchase_structure("elongation")
	game._purchase_structure("feeders")
	game._purchase_structure("growth")
	if not _check(game.dna == 648, "First level of each structure component should cost 2 DNA"):
		return
	if not _check(is_equal_approx(game._hypha_capacity_for_core(0), 2250.0), "Branching should add 25 percent hypha capacity per level"):
		return
	if not _check(is_equal_approx(game._max_segment_length(), 322.0), "Elongation should add 15 percent maximum segment length per level"):
		return
	if not _check(game._active_feeder_capacity() == 60, "Absorption network should add 12 active feeder slots per level"):
		return
	if not _check(is_equal_approx(game._hypha_growth_seconds(), 20.0), "Growth metabolism should increase main hypha growth speed by 20 percent per level"):
		return
	game.segments[0]["growth"] = 0.0
	game._update_growth(20.0)
	if not _check(is_equal_approx(float(game.segments[0]["growth"]), 1.0), "Level-one growth metabolism should finish a hypha in 20 seconds"):
		return
	game.lifetime_bacteria_births = 25
	game.lifetime_bacteria_consumed = 25
	game.bacteria_components["trap"] = 3
	if not _check(game._goal_definitions().size() == 22 and game._goal_complete("bacterial_bloom") and game._goal_complete("bacteria_control") and game._goal_complete("first_structure") and game._goal_complete("bacteria_specialist") and game._goal_progress_text("barracks_directive") == "0 / 1" and game._goal_progress_text("suppression_field") == "0 / 1" and game._goal_progress_text("disperser_burst") == "0 / 8" and game._goal_progress_text("rival_colony") == "0 / 1" and game._goal_progress_text("rival_guard") == "0 / 5" and game._goal_progress_text("hypha_severing") == "0 / 3" and game._goal_progress_text("antifungal_lockdown") == "0 / 1" and game._goal_progress_text("sporefall_guard") == "0 / 3", "Long-term goals should include bacteria ecology, evolution, exploration, supply, automation, suppression, event-response, rival-fungus, antifungal-lockdown, and recurring-sporefall goals"):
		return
	var before_specialist_mineral: float = game.mineral
	game._claim_goal("bacteria_specialist")
	if not _check(game.dna == 652 and is_equal_approx(game.mineral, before_specialist_mineral + 2.0), "Bacteria specialist goal should grant a mixed DNA and mineral reward"):
		return
	game.goals_open = true
	game.goal_page = 0
	var goals_panel: Rect2 = game._goals_panel_rect(game.get_viewport_rect().size)
	game._handle_goals_click(game._goal_next_rect(goals_panel).get_center())
	if not _check(game.goal_page == 1, "Long-term goals panel should navigate to its ecology page"):
		return
	game._handle_goals_click(game._goal_next_rect(goals_panel).get_center())
	if not _check(game.goal_page == 2, "Long-term goals panel should navigate to its exploration and expedition page"):
		return
	game._handle_goals_click(game._goal_prev_rect(goals_panel).get_center())
	game._handle_goals_click(game._goal_prev_rect(goals_panel).get_center())
	if not _check(game.goal_page == 0, "Long-term goals panel should navigate back to its first page"):
		return
	game.goals_open = false

	game.organic = 100.0
	game.mineral = 10.0
	game.dna = 0
	game._queue_dna(0)
	if not _check((game.cores[0]["jobs"] as Array).size() == 1, "DNA work must queue on a spore core"):
		return
	if not _check(is_equal_approx(game.organic, 70.0), "DNA work consumes 30 organic nutrition"):
		return
	if not _check(is_equal_approx(game.mineral, 9.0), "DNA work consumes one mineral"):
		return
	var queued_duration: float = game._dna_job_duration(0)
	game._update_dna_jobs(queued_duration - 1.0)
	if not _check(game.dna == 0, "DNA must not finish before the slowed 180-second-derived duration"):
		return
	game._update_dna_jobs(1.1)
	if not _check(game.dna == 1, "Completed core work should grant one DNA"):
		return
	if not _check((game.cores[0]["jobs"] as Array).is_empty(), "Completed DNA job leaves the queue"):
		return

	game.bacteria.clear()
	var toxin_bacterium: Dictionary = game._make_bacterium(Vector2.ZERO)
	toxin_bacterium["biomass"] = 1.0
	toxin_bacterium["suppressed"] = false
	game.bacteria.append(toxin_bacterium)
	var biomass_before_toxin: float = game.cores[0]["biomass"]
	game._update_core_hazards(10.0)
	if not _check(is_equal_approx(float(game.cores[0]["biomass"]), biomass_before_toxin - 0.04) and is_equal_approx(float(game.cores[0]["toxin_pressure"]), 0.004), "One nearby bacterium should apply gradual fractional toxin damage at 0.004 biomass per second"):
		return
	game.cores[0]["biomass"] = 60.0
	game.organic = 100.0
	game._repair_core(0)
	if not _check(is_equal_approx(float(game.cores[0]["biomass"]), 60.0) and is_equal_approx(float(game.cores[0]["repair_reserve"]), 20.0) and is_equal_approx(game.organic, 90.0), "Core repair should exchange 10 organic nutrition for a 20-point gradual repair reserve"):
		return
	game.bacteria.clear()
	game._update_core_hazards(100.0)
	if not _check(is_equal_approx(float(game.cores[0]["biomass"]), 68.5) and is_equal_approx(float(game.cores[0]["repair_reserve"]), 12.0), "Core biomass should recover fractionally through 0.080 repair and 0.005 passive recovery per second"):
		return
	game.dna = 100
	game._purchase_survival("wall")
	game._purchase_survival("detox")
	game._purchase_survival("repair")
	game._purchase_survival("storage")
	if not _check(game.dna == 92 and is_equal_approx(float(game.cores[0]["max_biomass"]), 125.0) and is_equal_approx(float(game.cores[0]["biomass"]), 93.5), "First survival shop levels should cost 2 DNA each and wall thickening should add 25 biomass to living cores"):
		return
	if not _check(is_equal_approx(game._toxin_damage_multiplier(), 0.85) and is_equal_approx(game._passive_recovery_rate(), 0.00625) and is_equal_approx(game._repair_recovery_rate(), 0.096) and is_equal_approx(game._repair_reserve_purchase_amount(), 25.0), "Survival shop upgrades should modify toxin, passive repair, reserve release, and reserve purchase values"):
		return
	game._purchase_barracks_unit("carrier")
	game._purchase_barracks_unit("chelator")
	game._purchase_barracks_unit("scout")
	game._purchase_diet_unit("bacteria", "lytic")
	if not _check(bool(game.barracks_unit_unlocks["carrier"]) and bool(game.barracks_unit_unlocks["chelator"]) and bool(game.barracks_unit_unlocks["scout"]) and bool(game.diet_unit_unlocks["lytic"]) and game._available_barracks_units().has("scout") and game._available_barracks_units().has("lytic"), "Barracks and bacteria diet shops should unlock scout and specialist units into the production list"):
		return
	var detox_test_bacterium: Dictionary = game._make_bacterium(Vector2.ZERO)
	detox_test_bacterium["suppressed"] = false
	game.bacteria.append(detox_test_bacterium)
	game._update_core_hazards(1.0)
	if not _check(is_equal_approx(float(game.cores[0]["toxin_pressure"]), 0.0034), "Level-one detox metabolism should reduce 0.004 toxin pressure by 15 percent"):
		return
	game.bacteria.clear()

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(420.0, 0.0), "barracks"))
	game.organic = 100.0
	game.mineral = 10.0
	game.expedition_units.clear()
	game._queue_expedition_spore(barracks_id)
	if not _check((game.cores[barracks_id]["spore_jobs"] as Array).size() == 1 and is_equal_approx(game.organic, 92.0) and is_equal_approx(game.mineral, 9.75), "Barracks should queue one expedition spore for 8 organic and 0.250 mineral"):
		return
	game._update_barracks_jobs(30.1)
	if not _check(game.expedition_units.size() == 1 and (game.cores[barracks_id]["spore_jobs"] as Array).is_empty(), "Barracks production should spawn one expedition spore after 30 seconds"):
		return
	var expedition: Dictionary = game.expedition_units[0]
	var expedition_screen: Vector2 = game.world_to_screen(expedition["pos"])
	game._select_expedition_box(expedition_screen - Vector2(16.0, 16.0), expedition_screen + Vector2(16.0, 16.0))
	if not _check(game.selected_expedition_ids.size() == 1, "Left-drag rectangular selection should select expedition spores"):
		return
	game._select_expedition_box(expedition_screen + Vector2(16.0, 16.0), expedition_screen - Vector2(16.0, 16.0))
	if not _check(game.selected_expedition_ids.size() == 1, "Rectangular selection should work while dragging in any direction"):
		return
	var order_target := Vector2(500.0, 80.0)
	game._issue_expedition_command(game.world_to_screen(order_target))
	if not _check(bool(expedition["manual"]) and String(expedition["state"]) == "moving" and (expedition["target_pos"] as Vector2).is_equal_approx(order_target), "Right click should issue a manual movement order to selected spores"):
		return
	game._issue_expedition_command(game.world_to_screen(Vector2(8000.0, 8000.0)))
	if not _check(game._distance_to_colony(expedition["target_pos"]) <= game.EXPEDITION_OPERATING_RADIUS + 0.01, "Manual orders should stay within the mother colony operating radius"):
		return
	game.resources.clear()
	game.resources.append({
		"id": 0, "pos": expedition["pos"], "kind": 0,
		"amount": 5.0, "initial_amount": 5.0, "alive": true, "phase": 0.0
	})
	game._rebuild_resource_grid()
	expedition["target_resource_id"] = 0
	expedition["state"] = "gathering"
	expedition["cargo_organic"] = 0.0
	game._update_expedition_gathering(expedition, 25.0)
	if not _check(is_equal_approx(float(expedition["cargo_organic"]), 1.0) and is_equal_approx(float(game.resources[0]["amount"]), 4.0), "Expedition spores should gather organic nutrition gradually at 0.040 per second"):
		return
	game.bacteria.clear()
	var expedition_prey: Dictionary = game._make_bacterium(expedition["pos"])
	expedition_prey["biomass"] = 1.0
	game.bacteria.append(expedition_prey)
	expedition["target_pos"] = expedition["pos"]
	expedition["state"] = "attacking"
	expedition["cargo_organic"] = 0.0
	game._update_expedition_attack(expedition, 5.0)
	if not _check(float(game.bacteria[0]["biomass"]) < 1.0 and float(expedition["cargo_organic"]) > 0.0, "Expedition spores should attack bacteria and carry converted biomass home"):
		return
	game._spawn_expedition_spore(barracks_id, "chelator")
	var chelator: Dictionary = game.expedition_units[1]
	game.resources.clear()
	game.resources.append({"id": 0, "pos": chelator["pos"], "kind": 1, "amount": 2.0, "initial_amount": 2.0, "alive": true, "phase": 0.0})
	chelator["target_resource_id"] = 0
	chelator["state"] = "gathering"
	game._update_expedition_gathering(chelator, 10.0)
	if not _check(is_equal_approx(float(chelator["cargo_mineral"]), 0.18), "Chelator spores should gather mineral ions instead of organic nutrition"):
		return
	game._spawn_expedition_spore(barracks_id, "scout")
	var scout: Dictionary = game.expedition_units[2]
	scout["pos"] = Vector2(2600.0, 0.0)
	game.explored_cells.clear()
	game._reveal_exploration(Vector2.ZERO, game.CORE_REVEAL_RADIUS)
	if not _check(not game._is_world_explored(scout["pos"]), "A remote scout position should begin hidden in the prepared fog test"):
		return
	game._update_exploration()
	if not _check(game._is_world_explored(scout["pos"]) and game.SCOUT_REVEAL_RADIUS > game.UNIT_REVEAL_RADIUS, "Scout spores should reveal a wider region around their current position"):
		return
	game.selected_expedition_ids = [int(scout["id"])]
	game._issue_expedition_command(game.world_to_screen(Vector2(8000.0, 0.0)))
	if not _check(game._distance_to_colony(scout["target_pos"]) <= game.SCOUT_OPERATING_RADIUS + 0.01 and game._distance_to_colony(scout["target_pos"]) > game.EXPEDITION_OPERATING_RADIUS, "Scout orders should use the extended exploration operating radius"):
		return
	game.selected_expedition_ids = [int(expedition["id"]), int(scout["id"])]
	game._issue_expedition_command(game.world_to_screen(Vector2(8000.0, 0.0)))
	if not _check(game._distance_to_colony(expedition["target_pos"]) <= game.EXPEDITION_OPERATING_RADIUS + 0.01 and game._distance_to_colony(scout["target_pos"]) > game.EXPEDITION_OPERATING_RADIUS and game._distance_to_colony(scout["target_pos"]) <= game.SCOUT_OPERATING_RADIUS + 0.01, "Mixed selections must clamp normal and scout units to their own operating radii"):
		return
	game.expedition_units.clear()
	game.selected_expedition_ids.clear()
	game.cores.remove_at(barracks_id)
	game.resources.clear()
	game.bacteria.clear()

	game.cores.append(game._make_core(Vector2(1000.0, 0.0)))
	game._damage_core(0, 1000.0, "test pressure")
	if not _check(not bool(game.cores[0]["alive"]) and bool(game.segments[0]["orphaned"]) and not game.game_over, "A dead core should orphan its linked hyphae while another living core prevents total failure"):
		return
	game._update_orphaned_segments(90.0)
	if not _check(is_equal_approx(float(game.segments[0]["viability"]), 0.5), "Unrescued hyphae should lose half their viability after 90 seconds"):
		return
	game.segments.append({
		"a": Vector2(1000.0, 0.0), "b": Vector2(100.0, 0.0), "growth": 1.0,
		"core_id": 1, "curve": 0.0, "orphaned": false, "viability": 1.0
	})
	game._update_orphaned_segments(1.0)
	if not _check(not bool(game.segments[0]["orphaned"]) and int(game.segments[0]["core_id"]) == 1 and is_equal_approx(float(game.segments[0]["viability"]), 1.0), "A living core network touching orphaned hyphae should rescue the whole linked network"):
		return
	game._damage_core(1, 1000.0, "test pressure")
	if not _check(game.game_over and game._living_core_count() == 0 and is_equal_approx(game.sim_speed, 0.0), "Losing every spore core should pause the simulation and trigger failure"):
		return

	print("SMOKE_OK segments=", game.segments.size(), " organic=", game.organic, " mineral=", game.mineral, " dna=", game.dna)
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("SMOKE_FAIL: " + message)
	quit(1)
	return false
