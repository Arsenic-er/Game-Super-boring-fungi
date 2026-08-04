extends SceneTree


const NORMAL_SAVE_PATH := "user://v047_developer_mode_normal.json"
const EXPECTED_METHODS := [
	"_enter_developer_mode",
	"_exit_developer_mode",
	"_developer_save_path",
	"_developer_grant_resources",
	"_developer_panel_rect",
	"_developer_button_rects",
]

var assertion_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_save(NORMAL_SAVE_PATH)
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game.autosave_enabled = false
	game.save_path = NORMAL_SAVE_PATH

	var missing: Array[String] = []
	for method_name in EXPECTED_METHODS:
		if not game.has_method(method_name):
			missing.append(method_name)
	if not _check(missing.is_empty(), "developer API missing: %s" % ", ".join(missing)):
		return

	# Establish a normal save with a recognizable payload. Developer mode must never
	# overwrite it, even when its own slot is saved repeatedly.
	game._begin_new_culture()
	game.organic = 431.125
	game.mineral = 27.375
	game.dna = 19
	game._save_game()
	if not _check(FileAccess.file_exists(NORMAL_SAVE_PATH), "normal save should exist before entering developer mode"):
		return
	var normal_before := _read_save(NORMAL_SAVE_PATH)

	game.call("_enter_developer_mode")
	if not _check(bool(game.get("developer_mode_enabled")), "developer mode should become active"):
		return
	var developer_save_path := String(game.call("_developer_save_path"))
	if not _check(not developer_save_path.is_empty() and developer_save_path.begins_with("user://") and developer_save_path != NORMAL_SAVE_PATH and String(game.save_path) == developer_save_path, "developer mode should switch to a distinct user save slot"):
		return
	_remove_save(developer_save_path)

	var organic_before := float(game.organic)
	var mineral_before := float(game.mineral)
	var dna_before := int(game.dna)
	game.call("_developer_grant_resources", 1234.5, 89.125, 77)
	if not _check(is_equal_approx(float(game.organic), organic_before + 1234.5), "free grant should add the requested organic nutrient"):
		return
	if not _check(is_equal_approx(float(game.mineral), mineral_before + 89.125), "free grant should add the requested mineral ions"):
		return
	if not _check(int(game.dna) == dna_before + 77, "free grant should add the requested DNA"):
		return
	game._save_game()
	if not _check(FileAccess.file_exists(developer_save_path), "developer mode should save into its own slot"):
		return
	if not _check(_read_save(NORMAL_SAVE_PATH) == normal_before, "developer resource changes and saves must not mutate the normal slot"):
		return

	# Compact-layout contract: the complete developer panel remains operable at the
	# project's smallest supported 16:9 viewport.
	var viewport := Vector2(640.0, 360.0)
	var viewport_rect := Rect2(Vector2.ZERO, viewport)
	var panel: Rect2 = game.call("_developer_panel_rect", viewport)
	var button_rects: Array = game.call("_developer_button_rects", viewport)
	if not _check(viewport_rect.encloses(panel) and panel.size.x > 0.0 and panel.size.y > 0.0, "640x360 developer panel should stay inside the viewport"):
		return
	if not _check(not button_rects.is_empty(), "developer panel should expose at least one action"):
		return
	var buttons_fit := true
	var buttons_are_usable := true
	var buttons_do_not_overlap := true
	for index in range(button_rects.size()):
		var rect: Rect2 = button_rects[index]
		buttons_fit = buttons_fit and panel.encloses(rect) and viewport_rect.encloses(rect)
		buttons_are_usable = buttons_are_usable and rect.size.x >= 38.0 and rect.size.y >= 22.0
		for other_index in range(index):
			buttons_do_not_overlap = buttons_do_not_overlap and not rect.intersects(button_rects[other_index] as Rect2)
	if not _check(buttons_fit, "every developer action should fit inside the 640x360 panel"):
		return
	if not _check(buttons_are_usable, "developer actions should retain usable pixel hit targets at 640x360"):
		return
	if not _check(buttons_do_not_overlap, "developer actions should not overlap at 640x360"):
		return

	game.call("_exit_developer_mode")
	if not _check(not bool(game.get("developer_mode_enabled")), "developer mode should become inactive"):
		return
	if not _check(String(game.save_path) == NORMAL_SAVE_PATH, "leaving developer mode should restore the normal save path"):
		return
	if not _check(_read_save(NORMAL_SAVE_PATH) == normal_before, "leaving developer mode should preserve the untouched normal save"):
		return

	_remove_save(NORMAL_SAVE_PATH)
	_remove_save(developer_save_path)
	print("V047_DEVELOPER_MODE_OK assertions=%d save=isolated resources=free layout=640x360" % assertion_count)
	game.queue_free()
	quit(0)


func _read_save(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _remove_save(path: String) -> void:
	if not path.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, message: String) -> bool:
	assertion_count += 1
	if condition:
		return true
	push_error("V047_DEVELOPER_MODE_FAIL[%d]: %s" % [assertion_count, message])
	quit(1)
	return false
