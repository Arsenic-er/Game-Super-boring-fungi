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
	game.save_path = "user://purge_zone_smoke.json"
	game.diet_levels["bacteria"] = 1
	game.diet_order = ["bacteria"]

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2.ZERO, "barracks"))
	var roles := ["forager", "lytic", "disperser", "carrier", "chelator", "scout", "suppressor", "piercer"]
	for unit_type in roles:
		game._spawn_expedition_spore(barracks_id, unit_type)
	if not _check(game.expedition_units.size() == roles.size(), "all role samples should spawn"):
		return
	game.bacteria.clear()
	for pos in [Vector2(-72.0, -48.0), Vector2(-18.0, -54.0), Vector2(52.0, 44.0), Vector2(58.0, 50.0), Vector2(64.0, 44.0), Vector2(52.0, 56.0), Vector2(64.0, 56.0), Vector2(220.0, 220.0)]:
		game.bacteria.append(game._make_bacterium(pos))
	game.explored_cells.clear()
	game.selected_expedition_ids.clear()
	for unit in game.expedition_units:
		game.selected_expedition_ids.append(int(unit["id"]))

	var camera_before: Vector2 = game.camera_center
	game._begin_purge_zone_mode()
	var start_screen: Vector2 = game.world_to_screen(Vector2(-120.0, -120.0))
	var end_screen: Vector2 = game.world_to_screen(Vector2(120.0, 60.0))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = start_screen
	game._unhandled_input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = end_screen
	motion.relative = end_screen - start_screen
	game._unhandled_input(motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	release.position = end_screen
	game._unhandled_input(release)
	var forager: Dictionary = game.expedition_units[0]
	var lytic: Dictionary = game.expedition_units[1]
	var disperser: Dictionary = game.expedition_units[2]
	var zone: Rect2 = game._purge_rect(forager)
	if not _check(game.mode == "normal" and not game.defense_zone_drawing and camera_before.is_equal_approx(game.camera_center), "purge right-drag should assign without camera panning"):
		return
	if not _check(zone.size.is_equal_approx(Vector2.ONE * zone.size.x), "purge zone should be square"):
		return
	for i in range(game.expedition_units.size()):
		var should_enable := i < 3
		if not _check(bool(game.expedition_units[i]["purge_enabled"]) == should_enable, "only forager, lytic, and disperser should receive purge orders"):
			return
	if not _check(String(forager["target_kind"]) == "purge_patrol" and String(lytic["target_kind"]) == "purge_patrol", "unexplored bacteria should not be acquired"):
		return

	game._reveal_exploration(Vector2.ZERO, 180.0)
	for unit in [forager, lytic, disperser]:
		unit["state"] = "guarding"
		unit["target_kind"] = ""
		game._acquire_purge_target(unit)
	if not _check(String(forager["target_kind"]) == "bacteria" and String(lytic["target_kind"]) == "bacteria" and not (forager["target_pos"] as Vector2).is_equal_approx(lytic["target_pos"]), "single-target hunters should split claims"):
		return
	if not _check((disperser["target_pos"] as Vector2).distance_to(Vector2(58.0, 50.0)) < 18.0, "disperser should prioritize the densest bacterial cluster"):
		return
	if not _check((forager["target_pos"] as Vector2).distance_to(Vector2(220.0, 220.0)) > 1.0, "bacteria outside the zone should be ignored"):
		return
	var edge_inside: Dictionary = game._make_bacterium(Vector2(115.0, 0.0))
	var edge_outside: Dictionary = game._make_bacterium(Vector2(130.0, 0.0))
	edge_inside["biomass"] = 0.200
	edge_outside["biomass"] = 0.200
	game.bacteria.append(edge_inside)
	game.bacteria.append(edge_outside)
	disperser["pos"] = edge_inside["pos"]
	disperser["target_pos"] = edge_inside["pos"]
	disperser["target_kind"] = "bacteria"
	disperser["state"] = "attacking"
	disperser["burst_cooldown"] = 0.0
	game._update_disperser_attack(disperser, 0.1)
	if not _check(float(edge_inside["biomass"]) < 0.200 and is_equal_approx(float(edge_outside["biomass"]), 0.200), "purge splash should respect the zone boundary"):
		return

	var old_target: Vector2 = lytic["target_pos"]
	var moved_count := 0
	for bacterium in game.bacteria:
		if (bacterium["pos"] as Vector2).distance_to(old_target) <= 18.0:
			bacterium["pos"] = zone.end + Vector2(40.0 + moved_count * 4.0, 40.0)
			moved_count += 1
	game._enforce_purge_zone(lytic)
	if not _check(String(lytic["target_kind"]) == "bacteria" and not (lytic["target_pos"] as Vector2).is_equal_approx(old_target), "an escaped target should be dropped and replaced"):
		return

	var kill_pos: Vector2 = lytic["target_pos"]
	var kill_index: int = game._nearest_bacterium_index(kill_pos, 2.0)
	game.bacteria[kill_index]["biomass"] = 0.010
	lytic["pos"] = kill_pos
	lytic["state"] = "attacking"
	game._update_expedition_attack(lytic, 1.0)
	if not _check(String(lytic["target_kind"]) == "bacteria" and String(lytic["state"]) == "moving", "a purge hunter should chain to another target after a partial load kill"):
		return

	lytic["cargo_organic"] = game._expedition_cargo_capacity(lytic)
	game._acquire_purge_target(lytic)
	if not _check(String(lytic["state"]) == "returning" and bool(lytic["purge_enabled"]), "full cargo should return without clearing purge"):
		return
	lytic["pos"] = game.cores[barracks_id]["pos"]
	lytic["search_cooldown"] = 0.0
	game._update_expedition_units(0.1, false)
	game._update_expedition_units(2.1, false)
	if not _check(float(lytic["cargo_organic"]) < 0.0005 and bool(lytic["purge_enabled"]) and ["moving", "attacking"].has(String(lytic["state"])), "after unloading, purge should resume"):
		return

	game.selected_expedition_ids = [int(forager["id"])]
	game._assign_harvest_zone(Vector2(-80.0, -80.0), Vector2(80.0, 20.0))
	if not _check(bool(forager["harvest_enabled"]) and not bool(forager["purge_enabled"]), "harvest should replace purge"):
		return
	game._assign_purge_zone(Vector2(-80.0, -80.0), Vector2(80.0, 20.0))
	if not _check(bool(forager["purge_enabled"]) and not bool(forager["harvest_enabled"]), "purge should replace harvest"):
		return
	game._assign_defense_zone(Vector2(-80.0, -80.0), Vector2(80.0, 20.0))
	if not _check(bool(forager["defense_enabled"]) and not bool(forager["purge_enabled"]), "defense should replace purge"):
		return
	game._assign_purge_zone(Vector2(-80.0, -80.0), Vector2(80.0, 20.0))
	forager["state"] = "repairing"
	game._issue_expedition_command(game.world_to_screen(Vector2(36.0, 30.0)))
	if not _check(bool(forager["purge_enabled"]), "a rejected command should preserve purge"):
		return
	forager["state"] = "guarding"
	game._issue_expedition_command(game.world_to_screen(Vector2(36.0, 30.0)))
	if not _check(not bool(forager["purge_enabled"]), "an accepted direct command should clear purge"):
		return
	game._assign_purge_zone(Vector2(-80.0, -80.0), Vector2(80.0, 20.0))
	game._clear_selected_persistent_orders()
	if not _check(not bool(forager["purge_enabled"]), "C-style clear should remove purge"):
		return
	game._assign_purge_zone(Vector2(-80.0, -80.0), Vector2(80.0, 20.0))
	game._order_selected_expedition_return()
	if not _check(not bool(forager["purge_enabled"]), "manual return should clear purge"):
		return

	forager["state"] = "idle"
	forager["biomass"] = forager["max_biomass"]
	game._assign_purge_zone(Vector2(-80.0, -80.0), Vector2(80.0, 20.0))
	forager["biomass"] = float(forager["max_biomass"]) * 0.20
	game._update_expedition_units(0.1, false)
	if not _check(bool(forager["purge_enabled"]) and ["retreating", "repairing"].has(String(forager["state"])), "low biomass retreat should preserve purge"):
		return
	forager["pos"] = game.cores[barracks_id]["pos"]
	game._update_expedition_units(0.1, false)
	game._update_expedition_repair(forager, 1000.0)
	forager["search_cooldown"] = 0.0
	game._update_expedition_units(2.1, false)
	if not _check(bool(forager["purge_enabled"]) and ["moving", "attacking"].has(String(forager["state"])), "repaired hunters should resume purge"):
		return

	game._save_game()
	game.expedition_units.clear()
	if not _check(game._load_game() and bool(game.expedition_units[0]["purge_enabled"]), "purge should round-trip through saves"):
		return
	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var malformed: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	var saved_units: Array = malformed.get("expedition_units", [])
	saved_units[0]["purge_enabled"] = true
	saved_units[0]["purge_min_x"] = -1000.0
	saved_units[0]["purge_min_y"] = -1000.0
	saved_units[0]["purge_max_x"] = 1000.0
	saved_units[0]["purge_max_y"] = 1000.0
	saved_units[1]["purge_enabled"] = true
	saved_units[1]["harvest_enabled"] = true
	saved_units[3]["purge_enabled"] = true
	saved_units[2]["state"] = "attacking"
	saved_units[2]["target_kind"] = ""
	saved_units[2]["target_x"] = 220.0
	saved_units[2]["target_y"] = 220.0
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(malformed))
	file = null
	if not _check(game._load_game() and not bool(game.expedition_units[0]["purge_enabled"]) and not bool(game.expedition_units[1]["purge_enabled"]) and not bool(game.expedition_units[1]["harvest_enabled"]) and not bool(game.expedition_units[3]["purge_enabled"]), "oversized, conflicting, and ineligible purge fields should be rejected"):
		return
	if not _check(String(game.expedition_units[2]["target_kind"]) != "" and (game.expedition_units[2]["target_pos"] as Vector2).distance_to(Vector2(220.0, 220.0)) > 1.0, "malformed purge attack state should be reacquired inside the zone"):
		return
	game._save_game()
	file = FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	for saved_unit in legacy.get("expedition_units", []):
		for key in ["purge_enabled", "purge_min_x", "purge_min_y", "purge_max_x", "purge_max_y", "purge_patrol_index"]:
			saved_unit.erase(key)
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game() and not bool(game.expedition_units[0]["purge_enabled"]), "v0.34 saves should default to no purge"):
		return

	var offline_hunter: Dictionary = game.expedition_units[0]
	offline_hunter["state"] = "idle"
	offline_hunter["biomass"] = offline_hunter["max_biomass"]
	game.selected_expedition_ids = [int(offline_hunter["id"])]
	game.bacteria.clear()
	for i in range(8):
		game.bacteria.append(game._make_bacterium(Vector2(-40.0 + i * 10.0, 10.0)))
	var event_bacterium: Dictionary = game._make_bacterium(Vector2(32.0, 32.0))
	event_bacterium["event_id"] = 999
	game.bacteria.append(event_bacterium)
	game._reveal_exploration(Vector2.ZERO, 180.0)
	game._assign_purge_zone(Vector2(-80.0, -80.0), Vector2(80.0, 20.0))
	var kills_before := int(game.lifetime_expedition_bacteria_killed)
	game._apply_offline_progress(650.0)
	game.offline_report_open = false
	var event_survived := false
	for bacterium in game.bacteria:
		if int(bacterium.get("event_id", -1)) == 999:
			event_survived = true
	if not _check(int(game.lifetime_expedition_bacteria_killed) > kills_before and event_survived, "offline purge should fight normal bacteria during the combat cap but ignore event strains"):
		return
	game.offline_simulating = true
	game.offline_expedition_combat_active = false
	var frozen_pos: Vector2 = offline_hunter["pos"]
	var frozen_state := String(offline_hunter["state"])
	var frozen_target: Vector2 = offline_hunter["target_pos"]
	game._update_expedition_units(5.0, false)
	game.offline_simulating = false
	if not _check((offline_hunter["pos"] as Vector2).is_equal_approx(frozen_pos) and String(offline_hunter["state"]) == frozen_state and (offline_hunter["target_pos"] as Vector2).is_equal_approx(frozen_target), "purge units should freeze after the offline combat cap"):
		return

	var normal_camera_before: Vector2 = game.camera_center
	var pan_press := InputEventMouseButton.new()
	pan_press.button_index = MOUSE_BUTTON_RIGHT
	pan_press.pressed = true
	pan_press.position = Vector2(300.0, 300.0)
	game._unhandled_input(pan_press)
	var pan_motion := InputEventMouseMotion.new()
	pan_motion.position = Vector2(330.0, 300.0)
	pan_motion.relative = Vector2(30.0, 0.0)
	game._unhandled_input(pan_motion)
	var pan_release := InputEventMouseButton.new()
	pan_release.button_index = MOUSE_BUTTON_RIGHT
	pan_release.pressed = false
	pan_release.position = Vector2(330.0, 300.0)
	game._unhandled_input(pan_release)
	if not _check(not normal_camera_before.is_equal_approx(game.camera_center), "normal right drag should still pan"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("PURGE_ZONE_OK shape=square roles=3 split=soft disperser=density chain=continuous save=compatible offline=capped")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("PURGE_ZONE_FAIL: " + message)
	quit(1)
	return false
