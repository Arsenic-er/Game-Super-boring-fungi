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
	game.layout_viewport_override = Vector2(640.0, 360.0)
	game.organic = 10000.0
	game.mineral = 1000.0
	for unit_id in game.BARRACK_UNIT_IDS:
		game.barracks_unit_unlocks[unit_id] = true
	game.diet_levels["bacteria"] = 1
	game.diet_levels["fungi"] = 1
	for unit_id in game.diet_unit_unlocks.keys():
		game.diet_unit_unlocks[unit_id] = true
	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2.ZERO, "barracks"))
	game.selected_core = barracks_id
	game.mode = "normal"
	game.menu_anim = 1.0

	var barracks_buttons: Array = game._current_menu_buttons()
	var actions: Array = []
	for button in barracks_buttons:
		actions.append(String(button["action"]))
	if not _check(actions.has("queue_spore") and not actions.has("cycle_spore_unit") and barracks_buttons.size() == 5, "barracks radial menu should keep Produce and remove Switch"):
		return
	game._apply_menu_action("queue_spore")
	if not _check(game.barracks_production_open and game.barracks_production_core_id == barracks_id, "Produce should open the square production menu"):
		return
	var panel: Rect2 = game._barracks_production_panel_rect()
	if not _check(is_equal_approx(panel.size.x, panel.size.y) and panel.size.y <= 336.01, "production panel should be square and fit a 640x360 test viewport"):
		return
	var cards: Array = game._barracks_production_card_rects()
	if not _check(cards.size() == 10 and String(cards[0]["unit_type"]) == "forager" and String(cards[9]["unit_type"]) == "antifungal", "cards should list all unlocked spores from basic to advanced"):
		return
	for index in range(cards.size()):
		if not _check(panel.encloses(cards[index]["rect"]), "every spore card should remain inside the square panel"):
			return

	var jobs: Array = game.cores[barracks_id]["spore_jobs"]
	var carrier_card: Dictionary = cards[1]
	var organic_before: float = game.organic
	var mineral_before: float = game.mineral
	if not _check(game._handle_barracks_production_click((carrier_card["rect"] as Rect2).get_center(), true, false), "Shift-click should be handled by the production menu"):
		return
	if not _check(jobs.size() == 5 and String(jobs[0]["unit_type"]) == "carrier" and String(jobs[4]["unit_type"]) == "carrier", "Shift-click should queue five selected spores"):
		return
	if not _check(is_equal_approx(game.organic, organic_before - game.UNIT_ORGANIC_COSTS["carrier"] * 5.0) and is_equal_approx(game.mineral, mineral_before - game.UNIT_MINERAL_COSTS["carrier"] * 5.0), "Shift-click should charge the displayed five-unit total"):
		return
	jobs.clear()
	organic_before = game.organic
	mineral_before = game.mineral
	var scout_card: Dictionary = cards[3]
	game._handle_barracks_production_click((scout_card["rect"] as Rect2).get_center(), false, true)
	if not _check(jobs.size() == 10 and String(jobs[0]["unit_type"]) == "scout" and String(game.cores[barracks_id]["production_unit"]) == "scout", "Ctrl-click should atomically queue ten chosen spores and remember the type"):
		return
	if not _check(is_equal_approx(game.organic, organic_before - game.UNIT_ORGANIC_COSTS["scout"] * 10.0) and is_equal_approx(game.mineral, mineral_before - game.UNIT_MINERAL_COSTS["scout"] * 10.0), "Ctrl-click should charge the displayed ten-unit total"):
		return
	jobs.clear()
	game.developer_mode_enabled = true
	organic_before = game.organic
	mineral_before = game.mineral
	game._handle_barracks_production_click((cards[0]["rect"] as Rect2).get_center(), false, false)
	if not _check(jobs.size() == 1 and is_equal_approx(game.organic, organic_before) and is_equal_approx(game.mineral, mineral_before), "developer mode should use the same menu without consuming resources"):
		return
	game._close_barracks_production_menu()
	if not _check(not game.barracks_production_open and game.barracks_production_core_id == -1, "production menu should close cleanly"):
		return
	game._open_barracks_production_menu(barracks_id)
	var outside := panel.position - Vector2(8.0, 8.0)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = outside
	press.pressed = true
	game._unhandled_input(press)
	if not _check(game.barracks_production_open and not game.left_selecting, "modal production menu should consume map press and prevent box selection"):
		return
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = outside
	release.pressed = false
	game._unhandled_input(release)
	if not _check(not game.barracks_production_open and game.selected_core == barracks_id and not game.left_selecting, "outside click should close the menu without reaching map selection"):
		return

	print("BARRACKS_PRODUCTION_MENU_OK square=1 cards=10 shift=5 ctrl=10 costs=scaled developer=free modal=blocked")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BARRACKS_PRODUCTION_MENU_FAIL: " + message)
	quit(1)
	return false
