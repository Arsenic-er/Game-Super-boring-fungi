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
	game.autosave_enabled = false
	game.save_path = "user://session_flow_smoke.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.main_menu_has_save = false
	game.first_locale_prompt = false
	game.main_menu_page = "main"
	if not _check(game._main_menu_labels().size() == 3, "main menu without a save should have three actions"):
		return

	game._begin_new_culture()
	if not _check(game.game_started and not game.main_menu_active and FileAccess.file_exists(game.save_path) and game._main_menu_labels().size() == 4, "starting a culture should immediately create a save and expose continue plus new culture"):
		return

	# Esc closes an existing panel first; only the next Esc opens the pause layer.
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	game.upgrade_open = true
	game._unhandled_input(esc)
	if not _check(not game.upgrade_open and not game.pause_menu_open, "Esc should close upgrades before pausing"):
		return
	game._unhandled_input(esc)
	if not _check(game.pause_menu_open and game.pause_menu_page == "main", "a second Esc should open pause"):
		return

	var sim_before: float = game.sim_time
	var save_clock_before: float = game.save_clock
	var organic_before: float = game.organic
	game._process(10.0)
	if not _check(is_equal_approx(game.sim_time, sim_before) and is_equal_approx(game.save_clock, save_clock_before) and is_equal_approx(game.organic, organic_before), "pause should freeze simulation and autosave clocks"):
		return

	# Immediate save stays paused and gives local feedback.
	game.organic = 321.125
	game._handle_pause_menu_click(game._pause_menu_button_rect(Vector2(1280.0, 720.0), 1).get_center())
	if not _check(game.pause_menu_open and game.pause_menu_notice != "" and FileAccess.file_exists(game.save_path), "save-now should remain in the pause menu"):
		return

	# Return and resume must preserve the in-memory culture without offline settlement.
	game._handle_pause_menu_click(game._pause_menu_button_rect(Vector2(1280.0, 720.0), 3).get_center())
	if not _check(game.main_menu_active and game.game_started and is_equal_approx(game.organic, 321.125), "save-and-main-menu should preserve current state"):
		return
	game._start_game_from_menu()
	if not _check(not game.main_menu_active and is_equal_approx(game.organic, 321.125) and not game.offline_report_open, "continuing the current in-memory culture should not duplicate offline settlement"):
		return

	# Canceling overwrite leaves the culture untouched; confirming fully resets it.
	game.main_menu_active = true
	game.main_menu_page = "main"
	game._handle_main_menu_click(game._main_menu_button_rect(Vector2(1280.0, 720.0), 1).get_center())
	if not _check(game.main_menu_page == "new_confirm", "new culture should require confirmation when a save exists"):
		return
	game._handle_main_menu_click(game._main_menu_button_rect(Vector2(1280.0, 720.0), 1).get_center())
	if not _check(game.main_menu_page == "main" and is_equal_approx(game.organic, 321.125), "canceling overwrite should preserve the culture"):
		return
	game.main_menu_page = "new_confirm"
	game._handle_main_menu_click(game._main_menu_button_rect(Vector2(1280.0, 720.0), 0).get_center())
	if not _check(not game.main_menu_active and game.cores.size() == 1 and is_equal_approx(game.organic, 220.0) and game.chapter_task_index == 0 and game.enemy_fungi.size() == 1, "confirmed new culture should reset all first-chapter anchors"):
		return

	# Losing the last core must freeze all real-time clocks and expose recovery actions.
	game.autosave_enabled = true
	game.save_clock = 2.0
	game._damage_core(0, 1000.0, "测试压力")
	if not _check(game.game_over and is_equal_approx(game.sim_speed, 0.0), "last core death should enter game over"):
		return
	var dead_sim_time: float = game.sim_time
	var dead_save_clock: float = game.save_clock
	game._process(20.0)
	if not _check(is_equal_approx(game.sim_time, dead_sim_time) and is_equal_approx(game.save_clock, dead_save_clock), "game over must truly stop simulation and autosave"):
		return
	game._handle_game_over_click(game._game_over_button_rect(Vector2(1280.0, 720.0), 0).get_center())
	if not _check(game.pause_menu_open and game.pause_menu_page == "restart_confirm", "game over restart should use overwrite confirmation"):
		return
	game._handle_pause_menu_click(game._pause_menu_button_rect(Vector2(1280.0, 720.0), 1).get_center())
	if not _check(game.game_over and not game.pause_menu_open, "canceling failed-culture restart should return to game over"):
		return
	game._handle_game_over_click(game._game_over_button_rect(Vector2(1280.0, 720.0), 0).get_center())
	game._handle_pause_menu_click(game._pause_menu_button_rect(Vector2(1280.0, 720.0), 0).get_center())
	if not _check(not game.game_over and game.cores.size() == 1 and game._is_core_alive(0) and is_equal_approx(game.sim_speed, 1.0), "confirmed restart should create a playable culture"):
		return

	# Modal geometry must remain usable at the default and a smaller supported window.
	for viewport in [Vector2(1280.0, 720.0), Vector2(960.0, 540.0), Vector2(640.0, 360.0)]:
		game.main_menu_has_save = true
		game.main_menu_page = "main"
		var previous := Rect2()
		for i in range(game._main_menu_labels().size()):
			var rect: Rect2 = game._main_menu_button_rect(viewport, i)
			if not _check(Rect2(Vector2.ZERO, viewport).encloses(rect) and (i == 0 or not previous.intersects(rect)), "main menu buttons should fit without overlap"):
				return
			previous = rect
		game.pause_menu_page = "main"
		var panel: Rect2 = game._pause_menu_panel_rect(viewport)
		previous = Rect2()
		for i in range(game._pause_menu_labels().size()):
			var rect: Rect2 = game._pause_menu_button_rect(viewport, i)
			if not _check(panel.encloses(rect) and (i == 0 or not previous.intersects(rect)), "pause buttons should fit inside their panel without overlap"):
				return
			previous = rect
		var game_over_panel: Rect2 = game._game_over_panel_rect(viewport)
		if not _check(game_over_panel.encloses(game._game_over_button_rect(viewport, 0)) and game_over_panel.encloses(game._game_over_button_rect(viewport, 1)), "game-over actions should stay inside their panel"):
			return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("SESSION_FLOW_OK pause=frozen menu=complete overwrite=confirmed game_over=recoverable layouts=3")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("SESSION_FLOW_FAIL: " + message)
	quit(1)
	return false
