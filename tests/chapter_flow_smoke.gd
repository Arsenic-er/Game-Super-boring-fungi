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
	game.game_started = false
	game.autosave_enabled = false
	game.save_path = "user://chapter_flow_smoke.json"

	if not _check(game._chapter_tasks().size() == 9 and game.chapter_task_index == 0, "new culture should start a nine-step chapter chain"):
		return
	game.core_selected_once = true
	game._update_chapter_flow(false)
	if not _check(game.chapter_task_index == 1, "selecting the spore core should complete awakening"):
		return
	game.segments.append({"a": Vector2.ZERO, "b": Vector2(80.0, 0.0), "growth": 1.0, "core_id": 0, "curve": 0.0, "orphaned": false, "viability": 1.0})
	game._update_chapter_flow(false)
	game.lifetime_organic_absorbed = 1.0
	game._update_chapter_flow(false)
	game.lifetime_dna_produced = 1
	game._update_chapter_flow(false)
	game.cores.append(game._make_core(Vector2(80.0, 0.0)))
	game._update_chapter_flow(false)
	game.diet_order = ["plant"]
	game.diet_levels["plant"] = 1
	game._update_chapter_flow(false)
	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(120.0, 0.0), "barracks"))
	game._spawn_expedition_spore(barracks_id, "forager")
	game._update_chapter_flow(false)
	if not _check(game.chapter_task_index == 7 and game.lifetime_expedition_units_built == 1, "barracks plus one produced unit should complete the expedition task"):
		return

	var enemy: Dictionary = game.enemy_fungi[0]
	enemy["discovered"] = true
	game._update_chapter_flow(false)
	if not _check(game.chapter_task_index == 8, "discovering the rival should advance to the final task"):
		return

	# The basic forager provides a deliberately slow manual fallback even without fungi diet.
	var forager: Dictionary = game.expedition_units[0]
	forager["pos"] = enemy["pos"]
	forager["target_pos"] = enemy["pos"]
	forager["target_kind"] = "enemy_fungus"
	forager["target_enemy_id"] = int(enemy["id"])
	forager["state"] = "attacking_fungus"
	var biomass_before := float(enemy["biomass"])
	game._update_expedition_fungus_attack(forager, 1.0)
	if not _check(float(enemy["biomass"]) < biomass_before and game._diet_efficiency("fungi") == 0.0, "forager should slowly damage a rival without unlocking fungi-specialist units"):
		return

	# Threats may only be raised from enemy hyphae already inside explored cells.
	game.enemy_hyphae.clear()
	game.enemy_hyphae.append({"id": 999, "fungus_id": int(enemy["id"]), "a": Vector2(220.0, 0.0), "b": Vector2(200.0, 0.0), "growth": 1.0, "curve": 0.0, "viability": 1.0})
	game._update_enemy_threat()
	if not _check(game.enemy_threat_level == 2 and game.enemy_threat_pos == Vector2(200.0, 0.0), "visible enemy hypha should raise an imminent warning"):
		return
	game.explored_cells.clear()
	game.explored_cells[game._exploration_key(game._exploration_coords(Vector2.ZERO))] = true
	game.enemy_hyphae[0]["a"] = Vector2(620.0, 0.0)
	game.enemy_hyphae[0]["b"] = Vector2(600.0, 0.0)
	game._update_enemy_threat()
	if not _check(game.enemy_threat_level == 0, "unexplored enemy hypha should not leak through the warning HUD"):
		return

	enemy["biomass"] = 0.001
	game._damage_enemy_fungus(int(enemy["id"]), 1.0)
	game.game_started = true
	game._update_chapter_flow(false)
	if not _check(game.chapter_complete and game.chapter_report_open and game.chapter_task_index == 9, "defeating the rival should open the chapter report"):
		return
	var viewport := Vector2(1280.0, 720.0)
	if not _check(not game._chapter_report_button_rect(viewport, 0).intersects(game._chapter_report_button_rect(viewport, 1)) and not game._chapter_report_button_rect(viewport, 1).intersects(game._chapter_report_button_rect(viewport, 2)), "chapter report buttons should not overlap"):
		return
	game._close_chapter_report(false)
	if not _check(game.chapter_report_seen and not game.chapter_report_open, "continuing should persist that the report was seen"):
		return

	# Simulate a v0.22 save by removing all new chapter fields; completed behavior must be inferred.
	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	for key in ["chapter_task_index", "core_selected_once", "chapter_complete", "chapter_report_seen", "chapter_completed_at", "guidance_collapsed", "lifetime_expedition_units_built", "next_expedition_id", "sim_time"]:
		legacy.erase(key)
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	game.chapter_task_index = 0
	game.chapter_complete = false
	if not _check(game._load_game() and game.chapter_complete and game.chapter_task_index == 9 and game.core_selected_once, "legacy saves should infer completed chapter progress without regressions"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("CHAPTER_FLOW_OK tasks=9 fallback_attack=true fog_safe_warning=true report=true legacy=true")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CHAPTER_FLOW_FAIL: " + message)
	quit(1)
	return false
