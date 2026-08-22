extends SceneTree


const SAVE_PATH := "user://founder_spore_smoke.json"
var assertions := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_save()
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game.main_menu_active = false
	game.game_started = true
	game.developer_mode_enabled = false
	game.autosave_enabled = false
	game.save_path = SAVE_PATH
	game._start_new_culture()

	if not _check(game.cores.is_empty() and game._founder_spore_active() and not game.game_over, "normal new culture should begin with one founder and zero cores"):
		return
	if not _check(String(game.founder_spore["state"]) == "idle" and is_equal_approx(float(game.founder_spore["energy"]), 100.0), "founder should start idle with 100 energy"):
		return
	if not _check(game.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and game.founder_spore_textures.size() == 3, "founder frames should use nearest filtering"):
		return
	for texture in game.founder_spore_textures:
		if not _check(texture != null and texture.get_size() == Vector2(48, 32), "each founder frame should be a native 48x32 texture"):
			return
	var idle_pos: Vector2 = game.founder_spore["pos"]
	var idle_energy := float(game.founder_spore["energy"])
	game._update_founder_spore(0.65)
	if not _check(int(game.founder_spore["visual_frame"]) == game.FounderSporeVisualFrame.LONG, "idle founder should slowly stretch to LONG"):
		return
	game._update_founder_spore(0.60)
	if not _check(int(game.founder_spore["visual_frame"]) == game.FounderSporeVisualFrame.REST, "idle founder should relax to REST between stretches"):
		return
	game._update_founder_spore(0.60)
	if not _check(int(game.founder_spore["visual_frame"]) == game.FounderSporeVisualFrame.SHORT, "idle founder should contract to SHORT"):
		return
	game._update_founder_spore(0.60)
	if not _check(int(game.founder_spore["visual_frame"]) == game.FounderSporeVisualFrame.REST and (game.founder_spore["pos"] as Vector2).is_equal_approx(idle_pos) and is_equal_approx(float(game.founder_spore["energy"]), idle_energy), "idle cycle should return to REST without moving or consuming energy"):
		return

	if not _check(game._issue_founder_spore_move(Vector2(1000, 0)), "right-click movement API should accept a finite target"):
		return
	game._update_founder_spore(0.20)
	if not _check(is_equal_approx(float(game.founder_spore["pos"].x), 9.0) and int(game.founder_spore["visual_frame"]) == game.FounderSporeVisualFrame.LONG, "first pulse should move nine units in LONG frame"):
		return
	game._update_founder_spore(0.25)
	if not _check(is_equal_approx(float(game.founder_spore["pos"].x), 20.25) and int(game.founder_spore["visual_frame"]) == game.FounderSporeVisualFrame.SHORT, "second pulse should use the SHORT frame"):
		return
	game._update_founder_spore(0.35)
	var rest_pos: Vector2 = game.founder_spore["pos"]
	if not _check(is_equal_approx(rest_pos.x, 36.0) and int(game.founder_spore["visual_frame"]) == game.FounderSporeVisualFrame.REST and is_equal_approx(float(game.founder_spore["energy"]), 99.0), "0.8 active seconds should travel 36 units and consume one energy"):
		return
	game._update_founder_spore(0.39)
	if not _check((game.founder_spore["pos"] as Vector2).is_equal_approx(rest_pos), "REST window should not move or consume energy"):
		return

	game._save_game()
	var saved_pos: Vector2 = game.founder_spore["pos"]
	var saved_energy := float(game.founder_spore["energy"])
	game.founder_spore = {}
	game.cores.clear()
	if not _check(game._load_game(false), "founder save should load"):
		return
	if not _check(game._founder_spore_active() and game.cores.is_empty() and not game.game_over and not game.offline_report_open, "loaded founder should remain a live pre-core state without offline settlement"):
		return
	if not _check((game.founder_spore["pos"] as Vector2).is_equal_approx(saved_pos) and is_equal_approx(float(game.founder_spore["energy"]), saved_energy) and String(game.founder_spore["state"]) == "idle", "load should restore founder position and energy but clear its movement order"):
		return

	var germination_pos: Vector2 = game.founder_spore["pos"]
	game._handle_left_click(game.world_to_screen(germination_pos))
	if not _check(bool(game.founder_spore["selected"]), "clicking the founder should select it"):
		return
	game._handle_left_click(game._founder_germination_button_rect().get_center())
	if not _check(String(game.founder_spore["state"]) == "germinating", "GERMINATE button should begin founder conversion"):
		return
	game._update_founder_spore(2.49)
	if not _check(game._founder_spore_active() and game.cores.is_empty(), "germination must not create a partial core before 2.5 seconds"):
		return
	game._update_founder_spore(0.01)
	if not _check(not game._founder_spore_active() and game.cores.size() == 1 and not game.game_over, "germination should atomically convert founder into exactly one core"):
		return
	if not _check((game.cores[0]["pos"] as Vector2).is_equal_approx(germination_pos) and is_equal_approx(float(game.cores[0]["biomass"]), 100.0), "new core should inherit founder position and full biomass"):
		return

	game._save_game()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	legacy.erase("founder_spore")
	file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	game.cores.clear()
	game.founder_spore = _make_fake_founder()
	if not _check(game._load_game(false) and not game._founder_spore_active() and game.cores.size() == 1, "legacy v1 save without founder field should load as an already settled culture"):
		return

	_remove_save()
	print("FOUNDER_SPORE_OK assertions=%d movement=30avg frames=nearest germination=2.5 save=v1" % assertions)
	game.queue_free()
	quit(0)


func _make_fake_founder() -> Dictionary:
	return {"active": true, "state": "idle", "pos": Vector2.ZERO, "energy": 100.0}


func _remove_save() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _check(condition: bool, message: String) -> bool:
	assertions += 1
	if condition:
		return true
	push_error("FOUNDER_SPORE_FAIL[%d]: %s" % [assertions, message])
	quit(1)
	return false
