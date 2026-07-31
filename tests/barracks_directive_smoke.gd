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
	game.save_path = "user://barracks_directive_smoke.json"
	game.organic = 5000.0
	game.mineral = 500.0
	game.diet_levels["bacteria"] = 1
	game.diet_levels["fungi"] = 1
	game.diet_order = ["bacteria", "fungi"]
	game.barracks_unit_unlocks["carrier"] = true
	game.diet_unit_unlocks["lytic"] = true
	game.diet_unit_unlocks["piercer"] = true

	var first_barracks: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(24.0, 0.0), "barracks"))
	var second_barracks: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(620.0, 0.0), "barracks"))
	game._spawn_expedition_spore(first_barracks, "forager")
	game._spawn_expedition_spore(first_barracks, "carrier")
	game._spawn_expedition_spore(second_barracks, "forager")
	var first_forager: Dictionary = game.expedition_units[0]
	var first_carrier: Dictionary = game.expedition_units[1]
	var other_forager: Dictionary = game.expedition_units[2]
	game.resources.clear()
	game.resource_grid.clear()
	game._add_resource(Vector2(54.0, 18.0), 0, 100.0)
	game._reveal_exploration(Vector2.ZERO, 220.0)

	game.cores[first_barracks]["production_unit"] = "carrier"
	if not _check(game._assign_barracks_directive(first_barracks, "purge", Vector2(-80.0, -80.0), Vector2(80.0, 20.0)) == 0 and not game.barracks_directive_ever_set and not game._goal_complete("barracks_directive"), "a rejected directive must not complete the teaching goal"):
		return

	game.selected_core = first_barracks
	game.show_status = true
	game.cores[first_barracks]["production_unit"] = "forager"
	var camera_before: Vector2 = game.camera_center
	if not _check(game._begin_barracks_directive_mode("harvest"), "harvest directive mode should open for foragers"):
		return
	var start_screen: Vector2 = game.world_to_screen(Vector2(-100.0, -100.0))
	var end_screen: Vector2 = game.world_to_screen(Vector2(100.0, 40.0))
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
	var harvest_zone: Rect2 = game._barracks_directive_rect(game.cores[first_barracks])
	if not _check(game.barracks_directive_ever_set and game._goal_complete("barracks_directive") and game._goal_progress_text("barracks_directive") == "1 / 1", "the first saved directive should permanently complete the teaching goal"):
		return

	if not _check(game.mode == "normal" and camera_before.is_equal_approx(game.camera_center) and harvest_zone.size.is_equal_approx(Vector2.ONE * harvest_zone.size.x), "right drag should save a square directive without panning"):
		return
	if not _check(bool(first_forager["harvest_enabled"]) and not bool(first_carrier["harvest_enabled"]) and not bool(other_forager["harvest_enabled"]), "only matching home and unit type should be assigned"):
		return
	if not _check(game._status_panel_rect().encloses(game._barracks_directive_button_rect(3)), "all directive buttons should remain inside the rounded status panel"):
		return

	game._spawn_expedition_spore(first_barracks, "forager", false)
	var manual_forager: Dictionary = game.expedition_units.back()
	if not _check(not bool(manual_forager["harvest_enabled"]), "manual production should not inherit a directive"):
		return
	game.cores[first_barracks]["rally_enabled"] = true
	game.cores[first_barracks]["rally_point"] = Vector2(120.0, 0.0)
	game._spawn_expedition_spore(first_barracks, "forager", true)
	var replacement_forager: Dictionary = game.expedition_units.back()
	if not _check(bool(replacement_forager["harvest_enabled"]) and String(replacement_forager["target_kind"]) != "ground", "automatic replacement should inherit the directive before rally"):
		return
	game._spawn_expedition_spore(second_barracks, "forager", true)
	if not _check(not bool(game.expedition_units.back()["harvest_enabled"]), "another barracks must not inherit the first barracks directive"):
		return

	game.cores[first_barracks]["production_unit"] = "forager"
	game._assign_barracks_directive(first_barracks, "defense", Vector2(-90.0, -90.0), Vector2(90.0, 30.0))
	if not _check(bool(first_forager["defense_enabled"]) and not bool(first_forager["harvest_enabled"]), "replacing a directive should preserve three-way exclusivity"):
		return
	var defense_zone: Rect2 = game._barracks_directive_rect(game.cores[first_barracks])
	game.cores[first_barracks]["production_unit"] = "carrier"
	if not _check(game._assign_barracks_directive(first_barracks, "purge", Vector2(-80.0, -80.0), Vector2(80.0, 20.0)) == 0 and String(game.cores[first_barracks]["directive_type"]) == "defense" and game._barracks_directive_rect(game.cores[first_barracks]).is_equal_approx(defense_zone), "an incompatible new directive must not overwrite the old template"):
		return

	game.bacteria.clear()
	for i in range(8):
		game.bacteria.append(game._make_bacterium(Vector2(-42.0 + i * 12.0, 28.0)))
	game._reveal_exploration(Vector2.ZERO, 220.0)
	game._spawn_expedition_spore(first_barracks, "lytic")
	var resident_lytic: Dictionary = game.expedition_units.back()
	game._spawn_expedition_spore(second_barracks, "lytic")
	var foreign_lytic: Dictionary = game.expedition_units.back()
	game.cores[first_barracks]["production_unit"] = "lytic"
	game.cores[first_barracks]["auto_replenish"] = false
	game._assign_barracks_directive(first_barracks, "purge", Vector2(-90.0, -90.0), Vector2(90.0, 20.0))
	if not _check(bool(resident_lytic["purge_enabled"]) and not bool(foreign_lytic["purge_enabled"]), "purge directive should remain isolated by home barracks"):
		return
	game._spawn_expedition_spore(first_barracks, "lytic", false)
	if not _check(not bool(game.expedition_units.back()["purge_enabled"]), "manual specialist production should remain unassigned"):
		return
	game._spawn_expedition_spore(first_barracks, "lytic", true)
	if not _check(bool(game.expedition_units.back()["purge_enabled"]), "automatic specialist replacement should inherit purge"):
		return
	game._spawn_expedition_spore(second_barracks, "piercer")
	var resident_piercer: Dictionary = game.expedition_units.back()
	var resident_piercer_id := int(resident_piercer["id"])
	game.cores[second_barracks]["production_unit"] = "piercer"
	game._assign_barracks_directive(second_barracks, "defense", Vector2(500.0, -90.0), Vector2(680.0, 20.0))
	if not _check(bool(resident_piercer["defense_enabled"]), "fungi specialist should receive its barracks defense directive"):
		return
	var resident_lytic_id := int(resident_lytic["id"])
	game.diet_levels["bacteria"] = 0
	game.diet_levels["fungi"] = 0
	if not _check(bool(game.cores[first_barracks]["directive_enabled"]) and not game._barracks_directive_valid(first_barracks, true) and game._barracks_directive_valid(first_barracks, false), "diet loss should pause rather than erase a compatible template"):
		return
	game._update_expedition_units(0.1, false)
	if not _check(bool(resident_lytic["purge_enabled"]) and String(resident_lytic["target_kind"]) != "bacteria" and bool(resident_piercer["defense_enabled"]) and String(resident_piercer["target_kind"]) != "enemy_fungus", "diet loss should pause existing specialist zones without erasing them"):
		return
	game._spawn_expedition_spore(first_barracks, "lytic", true)
	if not _check(not bool(game.expedition_units.back()["purge_enabled"]), "paused directives must not assign inactive diet units"):
		return
	game._save_game()
	if not _check(game._load_game(), "a save made while specialist diets are inactive should load"):
		return
	var loaded_lytic: Dictionary = {}
	var loaded_piercer: Dictionary = {}
	for unit in game.expedition_units:
		if int(unit["id"]) == resident_lytic_id:
			loaded_lytic = unit
		elif int(unit["id"]) == resident_piercer_id:
			loaded_piercer = unit
	if not _check(not loaded_lytic.is_empty() and bool(loaded_lytic["purge_enabled"]) and not loaded_piercer.is_empty() and bool(loaded_piercer["defense_enabled"]), "paused specialist zones should survive a save round-trip"):
		return
	game.diet_levels["bacteria"] = 1
	game.diet_levels["fungi"] = 1
	game._update_expedition_units(2.1, false)
	if not _check(bool(loaded_lytic["purge_enabled"]) and ["bacteria", "purge_patrol"].has(String(loaded_lytic["target_kind"])) and bool(loaded_piercer["defense_enabled"]) and ["enemy_guard", "enemy_fungus", "defense_patrol"].has(String(loaded_piercer["target_kind"])), "restored diets should resume existing barracks cohorts without new replacements"):
		return

	game.cores[first_barracks]["auto_replenish"] = true
	game.cores[first_barracks]["auto_replenish_unit"] = "lytic"
	game.cores[first_barracks]["auto_replenish_target"] = 12
	var queued_before: int = (game.cores[first_barracks].get("spore_jobs", []) as Array).size()
	game._update_auto_replenishment()
	var jobs: Array = game.cores[first_barracks].get("spore_jobs", [])
	if not _check(jobs.size() == queued_before + 1 and bool((jobs.back() as Dictionary).get("automatic", false)), "auto replenishment should queue an explicitly automatic job"):
		return
	(jobs[0] as Dictionary)["remaining"] = 0.0
	var built_before: int = game.expedition_units.size()
	game._update_barracks_jobs(0.1)
	if not _check(game.expedition_units.size() == built_before + 1 and bool(game.expedition_units.back()["purge_enabled"]), "completed automatic jobs should create an assigned replacement"):
		return

	game._save_game()
	if not _check(game._load_game() and bool(game.cores[first_barracks]["directive_enabled"]) and String(game.cores[first_barracks]["directive_type"]) == "purge" and String(game.cores[first_barracks]["directive_unit"]) == "lytic" and game.barracks_directive_ever_set, "directive and its completed teaching goal should round-trip through saves"):
		return
	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var malformed: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	var legacy_valid: Dictionary = malformed.duplicate(true)
	legacy_valid.erase("barracks_directive_ever_set")
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy_valid))
	file = null
	if not _check(game._load_game() and game.barracks_directive_ever_set, "v0.36 saves should infer teaching-goal completion from a valid saved directive"):
		return
	game._save_game()
	file = FileAccess.open(game.save_path, FileAccess.READ)
	malformed = JSON.parse_string(file.get_as_text())
	file = null
	malformed.erase("barracks_directive_ever_set")

	var saved_cores: Array = malformed.get("cores", [])
	for saved_core in saved_cores:
		saved_core["directive_enabled"] = false
	saved_cores[first_barracks]["directive_enabled"] = true
	saved_cores[first_barracks]["directive_min_x"] = -1000.0
	saved_cores[first_barracks]["directive_min_y"] = -1000.0
	saved_cores[first_barracks]["directive_max_x"] = 1000.0
	saved_cores[first_barracks]["directive_max_y"] = 1000.0
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(malformed))
	file = null
	if not _check(game._load_game() and not bool(game.cores[first_barracks]["directive_enabled"]) and not game.barracks_directive_ever_set and not game._goal_complete("barracks_directive"), "oversized malformed directives must be rejected before legacy teaching-goal inference"):
		return
	game._save_game()
	file = FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	for saved_core in legacy.get("cores", []):
		for key in ["directive_enabled", "directive_type", "directive_unit", "directive_min_x", "directive_min_y", "directive_max_x", "directive_max_y"]:
			saved_core.erase(key)
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game() and not bool(game.cores[first_barracks]["directive_enabled"]), "v0.35 saves should default to no barracks directive"):
		return

	game.cores[first_barracks]["auto_replenish"] = false
	game.cores[first_barracks]["production_unit"] = "forager"
	game._assign_barracks_directive(first_barracks, "harvest", Vector2(-90.0, -90.0), Vector2(90.0, 20.0))
	game.cores[first_barracks]["spore_jobs"] = [{"remaining": 1.0, "total": 1.0, "unit_type": "forager", "automatic": true}]
	var offline_ids := {}
	for unit in game.expedition_units:
		offline_ids[int(unit["id"])] = true
	game._apply_offline_progress(game.OFFLINE_MIN_SECONDS)
	game.offline_report_open = false
	var offline_inherited := false
	for unit in game.expedition_units:
		if not offline_ids.has(int(unit["id"])) and int(unit["home_core_id"]) == first_barracks and String(unit["unit_type"]) == "forager" and bool(unit["harvest_enabled"]):
			offline_inherited = true
	if not _check(offline_inherited, "offline-completed automatic jobs should inherit the saved directive"):
		return

	var cleared: int = int(game._clear_barracks_directive(first_barracks, false))
	if not _check(not bool(game.cores[first_barracks]["directive_enabled"]) and cleared > 0 and game.barracks_directive_ever_set and game._goal_complete("barracks_directive"), "explicit template clearing should release matching units without regressing the teaching goal"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("BARRACKS_DIRECTIVE_OK square=drag isolated=home automatic=inherits manual=free diet=pause-resume save=compatible offline=inherits")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BARRACKS_DIRECTIVE_FAIL: " + message)
	quit(1)
	return false
