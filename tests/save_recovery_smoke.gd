extends SceneTree


const TEST_SAVE_PATH := "user://save_recovery_smoke.json"
const SaveStore = preload("res://scripts/save_store.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveStore.remove_slot(TEST_SAVE_PATH)
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game.autosave_enabled = false
	game.save_path = TEST_SAVE_PATH
	game._start_new_culture()
	if game._founder_spore_active():
		game._complete_founder_spore_germination()
	game.main_menu_active = false
	game.game_started = true

	game.organic = 111.0
	if not _check(game._save_game() and FileAccess.file_exists(TEST_SAVE_PATH) and not FileAccess.file_exists(SaveStore.backup_path(TEST_SAVE_PATH)), "the first commit must create a valid primary without requiring a backup"):
		return
	game.organic = 222.0
	if not _check(game._save_game() and FileAccess.file_exists(SaveStore.backup_path(TEST_SAVE_PATH)), "the second commit must preserve the previous generation as backup"):
		return
	var backup_data := _read_json(SaveStore.backup_path(TEST_SAVE_PATH))
	if not _check(is_equal_approx(float(backup_data.get("organic", -1.0)), 111.0), "backup must contain the exact previous committed culture"):
		return

	var temporary_data := _read_json(TEST_SAVE_PATH)
	temporary_data["organic"] = 333.0
	temporary_data["saved_at"] = float(temporary_data.get("saved_at", 0.0)) + 1000.0
	if not _check(_write_json(SaveStore.temp_path(TEST_SAVE_PATH), temporary_data), "a valid interrupted temporary save should be writable for the fixture"):
		return
	game.organic = 999.0
	if not _check(game._load_game(false) and is_equal_approx(float(game.organic), 222.0), "a valid primary must win over a newer uncommitted temporary file"):
		return

	if not _check(_write_text(TEST_SAVE_PATH, "{corrupt primary"), "primary corruption fixture should be writable"):
		return
	game.organic = 999.0
	if not _check(game._load_game(false) and is_equal_approx(float(game.organic), 333.0), "a corrupt primary must recover from the newest valid temporary generation"):
		return
	var repaired_data := _read_json(TEST_SAVE_PATH)
	if not _check(is_equal_approx(float(repaired_data.get("organic", -1.0)), 333.0) and not FileAccess.file_exists(SaveStore.temp_path(TEST_SAVE_PATH)), "temporary recovery must repair primary and clear the commit file"):
		return

	if not _check(_write_text(TEST_SAVE_PATH, "{corrupt again") and _write_text(SaveStore.temp_path(TEST_SAVE_PATH), "[]"), "backup recovery corruption fixtures should be writable"):
		return
	game.organic = 999.0
	if not _check(game._load_game(false) and is_equal_approx(float(game.organic), 111.0), "when primary and temporary are invalid, the previous valid backup must load"):
		return

	if not _check(_write_text(TEST_SAVE_PATH, "invalid") and _write_text(SaveStore.temp_path(TEST_SAVE_PATH), "invalid") and _write_text(SaveStore.backup_path(TEST_SAVE_PATH), "invalid"), "total corruption fixtures should be writable"):
		return
	game.organic = 777.0
	if not _check(not game._load_game(false) and is_equal_approx(float(game.organic), 777.0), "if all generations are invalid, loading must fail before mutating live game state"):
		return

	SaveStore.remove_slot(TEST_SAVE_PATH)
	print("SAVE_RECOVERY_OK primary_preferred=true temp_recovered=true backup_recovered=true total_corruption_safe=true")
	game.queue_free()
	quit(0)


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func _write_json(path: String, data: Dictionary) -> bool:
	return _write_text(path, JSON.stringify(data))


func _write_text(path: String, payload: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var stored := file.store_string(payload)
	file.close()
	return stored


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("SAVE_RECOVERY_FAIL: " + message)
	SaveStore.remove_slot(TEST_SAVE_PATH)
	quit(1)
	return false
