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
	game.save_path = "user://exploration_rewards_test_save.json"
	var test_save_path := ProjectSettings.globalize_path(game.save_path)
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(test_save_path)

	var initial_discoveries: int = game._discovered_hotspot_count()
	if not _check(initial_discoveries >= 1 and game.discovery_banner_time > 0.0, "The starting reveal should record the nearby anomalous culture region"):
		return
	if not _check(game._sync_hotspot_discoveries(true) == 0 and game._discovered_hotspot_count() == initial_discoveries, "A discovered hotspot must never be recorded twice"):
		return
	for hotspot in game.resource_hotspots:
		if not bool(hotspot.get("anomalous", false)):
			continue
		game._reveal_exploration(hotspot["pos"], 1.0)
		game._sync_hotspot_discoveries(true)
		if game._discovered_hotspot_count() >= 3:
			break
	if not _check(game._discovered_hotspot_count() >= 3 and game._goal_complete("culture_survey"), "Three recorded anomalies should complete the culture survey goal"):
		return
	game.dna = 20
	game._claim_goal("culture_survey")
	if not _check(game.dna == 22 and bool(game.goals_claimed["culture_survey"]), "The survey goal should grant its one-time DNA reward"):
		return
	var dna_after_survey: int = game.dna
	game._claim_goal("culture_survey")
	if not _check(game.dna == dna_after_survey, "Claiming the same exploration reward twice must not change resources"):
		return
	var marked_hotspot: Dictionary = {}
	for hotspot in game.resource_hotspots:
		if game.discovered_hotspots.has(String(hotspot.get("id", ""))):
			marked_hotspot = hotspot
			break
	var discoveries_before_depletion: int = game._discovered_hotspot_count()
	for resource in game.resources:
		if not marked_hotspot.is_empty() and (resource["pos"] as Vector2).distance_to(marked_hotspot["pos"]) <= float(marked_hotspot["radius"]):
			resource["alive"] = false
	if not _check(game._discovered_hotspot_count() == discoveries_before_depletion and game.discovered_hotspots.has(String(marked_hotspot.get("id", ""))), "A recorded minimap discovery should remain after its local resources are depleted"):
		return

	game._purchase_barracks_unit("scout")
	var base_speed: float = game._scout_move_speed()
	var base_vision: float = game._scout_reveal_radius()
	game.upgrade_open = true
	game.upgrade_tab = 3
	var upgrade_panel: Rect2 = game._upgrade_panel_rect(game.get_viewport_rect().size)
	game._handle_upgrade_click(game._scout_upgrade_button_rect(upgrade_panel, "vision").get_center())
	game._handle_upgrade_click(game._scout_upgrade_button_rect(upgrade_panel, "speed").get_center())
	game.upgrade_open = false
	if not _check(int(game.scout_upgrade_levels["vision"]) == 1 and int(game.scout_upgrade_levels["speed"]) == 1 and game._scout_reveal_radius() > base_vision and game._scout_move_speed() > base_speed, "Independent scout upgrades should increase vision and movement speed"):
		return
	var moving_scout := {"unit_type": "scout", "pos": Vector2.ZERO}
	game._move_expedition_unit(moving_scout, Vector2(1000.0, 0.0), 1.0)
	if not _check(is_equal_approx(float((moving_scout["pos"] as Vector2).x), game._scout_move_speed()), "Scout movement should use the upgraded speed"):
		return

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(240.0, 0.0), "barracks"))
	game._spawn_expedition_spore(barracks_id, "carrier")
	var expedition: Dictionary = game.expedition_units[0]
	expedition["pos"] = game.cores[barracks_id]["pos"]
	expedition["state"] = "returning"
	expedition["cargo_organic"] = 8.7
	expedition["cargo_mineral"] = 0.3
	game._update_expedition_units(0.1)
	if not _check(is_equal_approx(game.lifetime_expedition_organic_returned, 8.7) and is_equal_approx(game.lifetime_expedition_mineral_returned, 0.3), "The first carrier return should record only its real cargo"):
		return
	expedition["state"] = "returning"
	expedition["cargo_organic"] = 1.3
	expedition["cargo_mineral"] = 0.2
	game._update_expedition_units(0.1)
	if not _check(is_equal_approx(game.lifetime_expedition_organic_returned, 10.0) and is_equal_approx(game.lifetime_expedition_mineral_returned, 0.5) and game._goal_complete("expedition_supply"), "Returning units should advance the expedition supply goal exactly when cargo reaches home"):
		return
	game._update_expedition_units(0.1)
	if not _check(is_equal_approx(game.lifetime_expedition_organic_returned, 10.0) and is_equal_approx(game.lifetime_expedition_mineral_returned, 0.5), "Delivered cargo must not be counted again"):
		return
	game._claim_goal("expedition_supply")
	if not _check(bool(game.goals_claimed["expedition_supply"]), "The completed supply goal should be claimable"):
		return

	expedition["unit_type"] = "forager"
	game.diet_levels["bacteria"] = 5
	for i in range(10):
		var prey: Dictionary = game._make_bacterium(expedition["pos"])
		prey["biomass"] = 1.0
		game.bacteria.clear()
		game.bacteria.append(prey)
		expedition["target_pos"] = expedition["pos"]
		expedition["state"] = "attacking"
		game._update_expedition_attack(expedition, 20.0)
	if not _check(game.lifetime_expedition_bacteria_killed == 10 and game._goal_complete("expedition_control"), "Ten expedition kills should complete the active suppression goal"):
		return
	game._claim_goal("expedition_control")
	if not _check(bool(game.goals_claimed["expedition_control"]), "The suppression reward should be claimable once"):
		return

	var saved_discoveries: int = game._discovered_hotspot_count()
	var saved_dna: int = game.dna
	game._save_game()
	game.discovered_hotspots.clear()
	game.scout_upgrade_levels["vision"] = 0
	game.scout_upgrade_levels["speed"] = 0
	game.lifetime_expedition_organic_returned = 0.0
	game.lifetime_expedition_mineral_returned = 0.0
	game.lifetime_expedition_bacteria_killed = 0
	if not _check(game._load_game(), "The v0.18 exploration save should load"):
		return
	if not _check(game._discovered_hotspot_count() == saved_discoveries and int(game.scout_upgrade_levels["vision"]) == 1 and int(game.scout_upgrade_levels["speed"]) == 1 and game.lifetime_expedition_bacteria_killed == 10 and game.dna == saved_dna, "Discoveries, scout upgrades, expedition counters, and rewards should survive save/load"):
		return

	var saved_file := FileAccess.open(game.save_path, FileAccess.READ)
	var legacy_data: Dictionary = JSON.parse_string(saved_file.get_as_text())
	saved_file.close()
	for new_key in ["discovered_hotspots", "scout_upgrade_levels", "lifetime_expedition_organic_returned", "lifetime_expedition_mineral_returned", "lifetime_expedition_bacteria_killed"]:
		legacy_data.erase(new_key)
	saved_file = FileAccess.open(game.save_path, FileAccess.WRITE)
	saved_file.store_string(JSON.stringify(legacy_data))
	saved_file.close()
	game.discovered_hotspots.clear()
	game.scout_upgrade_levels["vision"] = 4
	game.scout_upgrade_levels["speed"] = 4
	game.lifetime_expedition_organic_returned = 99.0
	game.lifetime_expedition_mineral_returned = 99.0
	game.lifetime_expedition_bacteria_killed = 99
	if not _check(game._load_game(), "A v0.17-style save without v0.18 fields should remain loadable"):
		return
	if not _check(game._discovered_hotspot_count() >= 1 and int(game.scout_upgrade_levels["vision"]) == 0 and int(game.scout_upgrade_levels["speed"]) == 0 and game.lifetime_expedition_bacteria_killed == 0, "Legacy saves should rebuild discovered markers and default new progression counters safely"):
		return

	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(test_save_path)
	print("EXPLORATION_REWARDS_OK discoveries=", game._discovered_hotspot_count(), " speed=", "%.1f" % game._scout_move_speed(), " vision=", "%.1f" % game._scout_reveal_radius(), " kills=", game.lifetime_expedition_bacteria_killed)
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("EXPLORATION_REWARDS_FAIL: " + message)
	quit(1)
	return false
