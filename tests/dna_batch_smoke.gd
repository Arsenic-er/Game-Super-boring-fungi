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
	game.save_path = "user://dna_batch_smoke.json"
	game.selected_core = 0
	game.mode = "normal"
	game.menu_anim = 1.0

	if not _check(game._dna_batch_size_from_modifiers(false, false) == 1 and game._dna_batch_size_from_modifiers(true, false) == 5 and game._dna_batch_size_from_modifiers(false, true) == 10 and game._dna_batch_size_from_modifiers(true, true) == 10, "DNA modifiers should map click, Shift, Ctrl, and both keys to 1, 5, 10, and 10"):
		return
	if not _check(game._dna_batch_tooltip_title(0, 5) == "生产 5 DNA　本批总计 900.0 秒" and game._dna_batch_tooltip_cost(5).contains("有机营养 150.000") and game._dna_batch_tooltip_cost(5).contains("矿物离子 5.000") and game._dna_batch_tooltip_cost(10).contains("有机营养 300.000") and game._dna_batch_tooltip_cost(10).contains("矿物离子 10.000"), "tooltip copy should scale quantity, total time, and both nutrient costs"):
		return
	if not _check(game._dna_batch_tooltip_cost(1).contains("Shift：×5　Ctrl：×10"), "tooltip should teach both batch modifiers"):
		return

	var dna_button := _dna_button_pos(game)
	if not _check(dna_button.is_finite(), "DNA menu button should be available on a normal core"):
		return
	var jobs: Array = game.cores[0]["jobs"]
	jobs.clear()
	game.organic = 1000.0
	game.mineral = 100.0
	game._handle_left_click(dna_button, true, false)
	if not _check(jobs.size() == 5 and is_equal_approx(game.organic, 850.0) and is_equal_approx(game.mineral, 95.0), "a real Shift-click should atomically queue five DNA and charge five costs"):
		return
	var first_job: Dictionary = jobs[0]
	var second_job: Dictionary = jobs[1]
	first_job["remaining"] = 1.0
	if not _check(not is_equal_approx(float(second_job["remaining"]), 1.0), "batch jobs must use independent dictionaries"):
		return
	first_job["remaining"] = first_job["total"]
	var dna_before: int = game.dna
	var lifetime_before: int = game.lifetime_dna_produced
	game._update_dna_jobs(game._dna_job_duration(0) * 5.0)
	if not _check(jobs.is_empty() and game.dna == dna_before + 5 and game.lifetime_dna_produced == lifetime_before + 5, "one large simulation step should finish all five sequential jobs exactly once"):
		return

	game.organic = 1000.0
	game.mineral = 100.0
	game._handle_left_click(dna_button, false, true)
	if not _check(jobs.size() == 10 and is_equal_approx(game.organic, 700.0) and is_equal_approx(game.mineral, 90.0), "a real Ctrl-click should atomically queue ten DNA and charge ten costs"):
		return
	jobs.clear()
	game.organic = 1000.0
	game.mineral = 100.0
	game._handle_left_click(dna_button)
	if not _check(jobs.size() == 1 and is_equal_approx(game.organic, 970.0) and is_equal_approx(game.mineral, 99.0), "a normal click should remain backward-compatible and queue one DNA"):
		return

	jobs.clear()
	game.organic = 299.999
	game.mineral = 10.0
	var resources_before := Vector2(game.organic, game.mineral)
	if not _check(not game._queue_dna(0, 10) and jobs.is_empty() and Vector2(game.organic, game.mineral).is_equal_approx(resources_before), "an underfunded batch should fail atomically without partial jobs or costs"):
		return
	game.organic = 300.0
	game.mineral = 9.999
	resources_before = Vector2(game.organic, game.mineral)
	if not _check(not game._queue_dna(0, 10) and jobs.is_empty() and Vector2(game.organic, game.mineral).is_equal_approx(resources_before), "either missing nutrient should reject the whole batch"):
		return

	game.organic = 1000.0
	game.mineral = 100.0
	if not _check(game._queue_dna(0, 5), "funded batch should queue before save"):
		return
	game._save_game()
	if not _check(game._load_game() and (game.cores[0]["jobs"] as Array).size() == 5, "batch DNA jobs should survive a save round-trip"):
		return

	var source_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	var main_source := source_file.get_as_text()
	source_file = null
	if not _check(main_source.contains("被摄食时会释放少量毒素") and main_source.contains("_handle_left_click(event.position, event.shift_pressed, event.ctrl_pressed)"), "source should explain bacterial toxin backlash and preserve real click modifiers"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("DNA_BATCH_OK click=1 shift=5 ctrl=10 costs=scaled tooltip=dynamic queue=atomic save=compatible bacteria=explained")
	game.queue_free()
	quit(0)


func _dna_button_pos(game: Node) -> Vector2:
	for button in game._current_menu_buttons():
		if String(button.get("action", "")) == "dna":
			return button.get("pos", Vector2.INF)
	return Vector2.INF


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("DNA_BATCH_FAIL: " + message)
	quit(1)
	return false
