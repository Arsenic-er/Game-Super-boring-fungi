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
	game.save_path = "user://harvest_zone_smoke.json"

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2.ZERO, "barracks"))
	for unit_type in ["forager", "carrier", "chelator", "scout"]:
		game._spawn_expedition_spore(barracks_id, unit_type)
	if not _check(game.expedition_units.size() == 4, "four role samples should spawn"):
		return
	game.resources.clear()
	game.resource_grid.clear()
	game._add_resource(Vector2(-52.0, -8.0), 0, 1.0)
	game._add_resource(Vector2(58.0, 12.0), 0, 8.0)
	game._add_resource(Vector2(8.0, 54.0), 1, 2.0)
	game._add_resource(Vector2(220.0, 220.0), 0, 9.0)
	game.explored_cells.clear()
	game._reveal_exploration(Vector2.ZERO, 170.0)
	game.selected_expedition_ids = []
	for unit in game.expedition_units:
		game.selected_expedition_ids.append(int(unit["id"]))

	var camera_before: Vector2 = game.camera_center
	game._begin_harvest_zone_mode()
	var start_screen: Vector2 = game.world_to_screen(Vector2(-120.0, -120.0))
	var end_screen: Vector2 = game.world_to_screen(Vector2(120.0, 70.0))
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
	var carrier: Dictionary = game.expedition_units[1]
	var chelator: Dictionary = game.expedition_units[2]
	var scout: Dictionary = game.expedition_units[3]
	var zone: Rect2 = game._harvest_rect(forager)
	if not _check(game.mode == "normal" and not game.defense_zone_drawing and camera_before.is_equal_approx(game.camera_center), "harvest-mode right drag should assign without panning"):
		return
	if not _check(bool(forager["harvest_enabled"]) and bool(carrier["harvest_enabled"]) and bool(chelator["harvest_enabled"]) and not bool(scout["harvest_enabled"]), "only the three gathering roles should receive the zone"):
		return
	if not _check(zone.size.is_equal_approx(Vector2.ONE * zone.size.x) and (game._harvest_rect(carrier) as Rect2).is_equal_approx(zone), "all eligible units should share one square zone"):
		return
	if not _check(int(game._resource_by_id(int(forager["target_resource_id"]))["kind"]) == 0 and int(game._resource_by_id(int(chelator["target_resource_id"]))["kind"]) == 1, "roles should target their matching nutrient kind"):
		return
	if not _check(int(forager["target_resource_id"]) != int(carrier["target_resource_id"]), "organic gatherers should prefer unclaimed resources"):
		return
	if not _check(int(forager["target_resource_id"]) != 3 and int(carrier["target_resource_id"]) != 3, "resources outside the zone must be ignored"):
		return

	var original_zone := zone
	if not _check(game._assign_harvest_zone(Vector2(-450.0, -450.0), Vector2(450.0, 450.0)) == 0 and (game._harvest_rect(forager) as Rect2).is_equal_approx(original_zone), "an out-of-range zone should be rejected without replacing the old assignment"):
		return
	game.upgrade_open = true
	game.mode = "normal"
	game._begin_harvest_zone_mode()
	if not _check(game.mode == "normal", "modal panels should block harvest mode"):
		return
	game.upgrade_open = false

	var first_resource_id := int(forager["target_resource_id"])
	forager["pos"] = game._resource_by_id(first_resource_id)["pos"]
	forager["state"] = "gathering"
	game._update_expedition_gathering(forager, 100.0)
	if not _check(not bool(game._resource_by_id(first_resource_id)["alive"]) and String(forager["target_kind"]) == "resource" and int(forager["target_resource_id"]) != first_resource_id, "a depleted resource should chain into the next compatible point before returning"):
		return

	forager["cargo_organic"] = game._expedition_cargo_capacity(forager)
	game._acquire_harvest_target(forager)
	if not _check(String(forager["state"]) == "returning" and bool(forager["harvest_enabled"]), "full cargo should return without clearing the persistent zone"):
		return
	forager["pos"] = game.cores[barracks_id]["pos"]
	forager["search_cooldown"] = 0.0
	game._update_expedition_units(0.1, false)
	game._update_expedition_units(2.1, false)
	if not _check(float(forager["cargo_organic"]) < 0.0005 and bool(forager["harvest_enabled"]) and ["moving", "gathering"].has(String(forager["state"])), "after unloading, a gatherer should resume its zone"):
		return

	game.selected_expedition_ids = [int(forager["id"])]
	game._assign_defense_zone(Vector2(-80.0, -80.0), Vector2(80.0, 10.0))
	if not _check(bool(forager["defense_enabled"]) and not bool(forager["harvest_enabled"]), "setting defense should replace harvest"):
		return
	game._assign_harvest_zone(Vector2(-80.0, -80.0), Vector2(80.0, 20.0))
	if not _check(bool(forager["harvest_enabled"]) and not bool(forager["defense_enabled"]), "setting harvest should replace defense"):
		return
	forager["state"] = "repairing"
	game._issue_expedition_command(game.world_to_screen(Vector2(40.0, 40.0)))
	if not _check(bool(forager["harvest_enabled"]), "a rejected command must not clear a repairing unit's harvest zone"):
		return
	forager["state"] = "guarding"
	game._issue_expedition_command(game.world_to_screen(game._resource_by_id(2)["pos"]))
	if not _check(bool(forager["harvest_enabled"]), "an incompatible mineral order must be rejected without clearing an organic gatherer's zone"):
		return
	game._issue_expedition_command(game.world_to_screen(Vector2(40.0, 40.0)))
	if not _check(not bool(forager["harvest_enabled"]), "an accepted direct order should replace harvest"):
		return
	game._assign_harvest_zone(Vector2(-80.0, -80.0), Vector2(80.0, 20.0))
	game._order_selected_expedition_return()
	if not _check(not bool(forager["harvest_enabled"]), "manual return should clear persistent harvest"):
		return

	forager["state"] = "idle"
	forager["biomass"] = forager["max_biomass"]
	game._assign_harvest_zone(Vector2(-80.0, -80.0), Vector2(80.0, 20.0))
	forager["biomass"] = float(forager["max_biomass"]) * 0.20
	game._update_expedition_units(0.1, false)
	if not _check(bool(forager["harvest_enabled"]) and ["retreating", "repairing"].has(String(forager["state"])), "low biomass retreat should preserve harvest"):
		return
	forager["pos"] = game.cores[barracks_id]["pos"]
	game._update_expedition_units(0.1, false)
	game._update_expedition_repair(forager, 1000.0)
	forager["search_cooldown"] = 0.0
	game._update_expedition_units(2.1, false)
	if not _check(bool(forager["harvest_enabled"]) and ["moving", "gathering"].has(String(forager["state"])), "repaired gatherers should resume their saved zone"):
		return

	game._save_game()
	game.expedition_units.clear()
	if not _check(game._load_game() and game.expedition_units.size() == 4 and bool(game.expedition_units[0]["harvest_enabled"]), "harvest zones should round-trip through saves"):
		return
	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var malformed: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	var malformed_units: Array = malformed.get("expedition_units", [])
	malformed_units[0]["harvest_enabled"] = true
	malformed_units[0]["harvest_min_x"] = -1000.0
	malformed_units[0]["harvest_min_y"] = -1000.0
	malformed_units[0]["harvest_max_x"] = 1000.0
	malformed_units[0]["harvest_max_y"] = 1000.0
	malformed_units[1]["harvest_enabled"] = true
	malformed_units[1]["defense_enabled"] = true
	malformed_units[3]["harvest_enabled"] = true
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(malformed))
	file = null
	var malformed_loaded: bool = game._load_game()
	if not _check(malformed_loaded and not bool(game.expedition_units[0]["harvest_enabled"]) and not bool(game.expedition_units[1]["harvest_enabled"]) and not bool(game.expedition_units[1]["defense_enabled"]) and not bool(game.expedition_units[3]["harvest_enabled"]), "oversized, conflicting, and ineligible harvest assignments should be rejected"):
		return
	game._save_game()
	file = FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	for saved_unit in legacy.get("expedition_units", []):
		for key in ["harvest_enabled", "harvest_min_x", "harvest_min_y", "harvest_max_x", "harvest_max_y", "harvest_patrol_index"]:
			saved_unit.erase(key)
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game() and not bool(game.expedition_units[0]["harvest_enabled"]), "v0.33 saves should default to no harvest assignment"):
		return

	var offline_forager: Dictionary = game.expedition_units[0]
	offline_forager["state"] = "idle"
	offline_forager["biomass"] = offline_forager["max_biomass"]
	game.selected_expedition_ids = [int(offline_forager["id"])]
	for resource in game.resources:
		resource["alive"] = false
		resource["amount"] = 0.0
	game._add_resource(Vector2(32.0, 0.0), 0, 20.0)
	game._reveal_exploration(Vector2.ZERO, 180.0)
	game._assign_harvest_zone(Vector2(-80.0, -80.0), Vector2(80.0, 40.0))
	var organic_before := float(game.organic)
	game._apply_offline_progress(300.0)
	game.offline_report_open = false
	if not _check(float(game.organic) > organic_before and bool(offline_forager["harvest_enabled"]), "offline settlement should consume real zone resources and return cargo"):
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
	if not _check(not normal_camera_before.is_equal_approx(game.camera_center), "normal right drag should still pan the camera"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("HARVEST_ZONE_OK shape=square roles=3 split=soft chain=continuous save=compatible offline=active normal-pan=preserved")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("HARVEST_ZONE_FAIL: " + message)
	quit(1)
	return false
