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
	game.save_path = "user://defense_zone_smoke.json"
	game.diet_levels["fungi"] = 1
	game.diet_order = ["fungi"]
	game.diet_unit_unlocks["piercer"] = true

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(24.0, 0.0), "barracks"))
	game.organic = 1000.0
	game.mineral = 100.0
	game._spawn_expedition_spore(barracks_id, "forager")
	game._spawn_expedition_spore(barracks_id, "piercer")
	if not _check(game.expedition_units.size() == 2, "two eligible defenders should spawn"):
		return
	game.selected_expedition_ids = [int(game.expedition_units[0]["id"]), int(game.expedition_units[1]["id"])]

	var camera_before: Vector2 = game.camera_center
	game._begin_defense_zone_mode()
	var start_screen: Vector2 = game.world_to_screen(Vector2(-120.0, -120.0))
	var end_screen: Vector2 = game.world_to_screen(Vector2(160.0, 80.0))
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
	var first: Dictionary = game.expedition_units[0]
	var second: Dictionary = game.expedition_units[1]
	var zone: Rect2 = game._defense_rect(first)
	if not _check(game.mode == "normal" and not game.defense_zone_drawing and camera_before.is_equal_approx(game.camera_center), "defense-mode right drag should assign without panning the camera"):
		return
	if not _check(bool(first["defense_enabled"]) and bool(second["defense_enabled"]) and zone.size.is_equal_approx(Vector2.ONE * zone.size.x) and zone.size.x >= game.DEFENSE_ZONE_MIN_SIDE and (game._defense_rect(second) as Rect2).is_equal_approx(zone), "selected units should share one normalized square defense zone"):
		return
	var original_zone := zone
	if not _check(game._assign_defense_zone(Vector2(-450.0, -450.0), Vector2(450.0, 450.0)) == 0 and (game._defense_rect(first) as Rect2).is_equal_approx(original_zone), "a defense square whose corners exceed operating range should be rejected without replacing the old order"):
		return
	game.upgrade_open = true
	game.mode = "normal"
	game._begin_defense_zone_mode()
	if not _check(game.mode == "normal", "modal panels should block entering defense drawing mode"):
		return
	game.upgrade_open = false
	game.selected_expedition_ids = [int(first["id"])]
	first["state"] = "repairing"
	game._issue_expedition_command(game.world_to_screen(zone.get_center() + Vector2(90.0, 90.0)))
	if not _check(bool(first["defense_enabled"]), "a rejected command must not silently clear a repairing unit's persistent defense"):
		return
	first["state"] = "guarding"
	first["target_kind"] = ""
	game.selected_expedition_ids = [int(first["id"]), int(second["id"])]

	var enemy: Dictionary = game.enemy_fungi[0]
	enemy["pos"] = zone.get_center() + Vector2(36.0, 0.0)
	enemy["alive"] = true
	enemy["biomass"] = enemy["max_biomass"]
	var guard: Dictionary = game.enemy_guard_spores[0]
	guard["pos"] = zone.get_center() + Vector2(12.0, 0.0)
	guard["alive"] = true
	game._reveal_exploration(zone.get_center(), zone.size.x)
	first["state"] = "guarding"
	first["target_kind"] = ""
	game._acquire_defense_target(first)
	if not _check(String(first["target_kind"]) == "enemy_guard" and int(first["target_enemy_guard_id"]) == int(guard["id"]), "defenders should prioritize a visible guard inside the zone"):
		return

	guard["pos"] = zone.end + Vector2(40.0, 40.0)
	game._enforce_defense_zone(first)
	if not _check(String(first["target_kind"]) == "defense_patrol" and zone.grow(0.1).has_point(first["target_pos"]), "a guard leaving the zone should be dropped immediately and the defender should return"):
		return
	first["state"] = "guarding"
	first["target_kind"] = ""
	game._acquire_defense_target(first)
	if not _check(String(first["target_kind"]) == "enemy_fungus" and int(first["target_enemy_id"]) == int(enemy["id"]), "the rival core should be acquired after no in-zone guard remains"):
		return

	enemy["pos"] = zone.end + Vector2(80.0, 80.0)
	first["state"] = "guarding"
	first["target_kind"] = ""
	game._acquire_defense_target(first)
	if not _check(String(first["target_kind"]) == "defense_patrol", "targets outside the zone must never be acquired"):
		return

	first["biomass"] = float(first["max_biomass"]) * 0.20
	first["state"] = "guarding"
	first["target_kind"] = ""
	game._update_expedition_units(0.1, false)
	if not _check(["retreating", "repairing"].has(String(first["state"])), "low biomass retreat must override persistent defense"):
		return

	var frozen_second_pos: Vector2 = second["pos"]
	var frozen_second_state := String(second["state"])
	var frozen_second_target := String(second["target_kind"])
	var frozen_second_target_pos: Vector2 = second["target_pos"]
	var frozen_second_biomass := float(second["biomass"])
	game.ecology_events = [{"id": 9001, "type": "toxin", "pos": second["pos"], "radius": game.ECOLOGY_TOXIN_ZONE_RADIUS, "phase": "active", "remaining": game.ECOLOGY_TOXIN_ACTIVE_SECONDS, "anchor_core_id": barracks_id, "spawned": 0, "control_progress": 0.0, "contained": false}]
	game._apply_offline_progress(game.OFFLINE_MIN_SECONDS)
	game.offline_report_open = false
	if not _check((second["pos"] as Vector2).is_equal_approx(frozen_second_pos) and String(second["state"]) == frozen_second_state and String(second["target_kind"]) == frozen_second_target and (second["target_pos"] as Vector2).is_equal_approx(frozen_second_target_pos) and float(second["biomass"]) < frozen_second_biomass, "offline settlement should freeze defense movement and commands without granting toxin immunity"):
		return

	first["biomass"] = first["max_biomass"]
	first["state"] = "guarding"
	first["target_kind"] = ""
	game._save_game()
	game.expedition_units.clear()
	if not _check(game._load_game() and game.expedition_units.size() == 2 and bool(game.expedition_units[0]["defense_enabled"]), "defense zones should round-trip through saves"):
		return
	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var malformed: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	var malformed_units: Array = malformed.get("expedition_units", [])
	malformed_units[0]["defense_enabled"] = true
	malformed_units[0]["defense_min_x"] = -1000.0
	malformed_units[0]["defense_min_y"] = -1000.0
	malformed_units[0]["defense_max_x"] = 1000.0
	malformed_units[0]["defense_max_y"] = 1000.0
	malformed_units[1]["unit_type"] = "carrier"
	malformed_units[1]["defense_enabled"] = true
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(malformed))
	file = null
	if not _check(game._load_game() and not bool(game.expedition_units[0]["defense_enabled"]) and not bool(game.expedition_units[1]["defense_enabled"]), "malformed oversized and ineligible-unit defense assignments should be rejected on load"):
		return
	game._save_game()
	file = FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	for saved_unit in legacy.get("expedition_units", []):
		for key in ["defense_enabled", "defense_min_x", "defense_min_y", "defense_max_x", "defense_max_y", "defense_patrol_index"]:
			saved_unit.erase(key)
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game() and not bool(game.expedition_units[0]["defense_enabled"]) and not bool(game.expedition_units[1]["defense_enabled"]), "v0.32 saves should default to no defense assignment"):
		return

	game.selected_expedition_ids = [int(game.expedition_units[0]["id"])]
	game._assign_defense_zone(Vector2(-80.0, -80.0), Vector2(80.0, 30.0))
	game._clear_selected_defense_zones()
	if not _check(not bool(game.expedition_units[0]["defense_enabled"]), "the clear command should cancel the selected defense zone"):
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
	if not _check(not normal_camera_before.is_equal_approx(game.camera_center), "normal-mode right drag should still pan the camera"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("DEFENSE_ZONE_OK shape=square input=right-drag priority=guard leash=bounded save=compatible offline=frozen normal-pan=preserved")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("DEFENSE_ZONE_FAIL: " + message)
	quit(1)
	return false
