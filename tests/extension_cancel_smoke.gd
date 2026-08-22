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
	game.main_menu_active = false
	game.game_started = true
	game.pause_menu_open = false
	game.mode = "extend"
	game.selected_core = 0
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = Vector2(420.0, 360.0)
	game._unhandled_input(press)
	if not _check(game.mode == "extend" and game.dragging, "right press should begin the existing pan gesture without confirming growth"):
		return
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	release.position = press.position
	game._unhandled_input(release)
	if not _check(game.mode == "normal" and not game.dragging, "a right click must cancel extension adjustment"):
		return
	if not _check(game.selected_core == 0, "cancelling extension must preserve the selected source core"):
		return

	game.mode = "extend"
	game._unhandled_input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = press.position + Vector2(18.0, 0.0)
	motion.relative = Vector2(18.0, 0.0)
	game._unhandled_input(motion)
	release.position = motion.position
	game._unhandled_input(release)
	if not _check(game.mode == "extend", "right-drag camera panning must keep the extension preview active"):
		return
	print("EXTENSION_CANCEL_OK click=cancel drag=pan selection=preserved")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("EXTENSION_CANCEL_FAIL: " + message)
	quit(1)
	return false
