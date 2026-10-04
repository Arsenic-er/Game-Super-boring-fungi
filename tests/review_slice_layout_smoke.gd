extends SceneTree

# Geometry and optional real-render evidence for the actual review entry.
# No objective injection or gameplay-timing claim is made by this probe.
const ReviewScene = preload("res://scenes/ReviewSlice.tscn")
const Catalog = preload("res://scripts/campaign_mission_catalog.gd")
const Locales := ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
var checks := 0
var captures := 0
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var output := OS.get_environment("FUNGI_REVIEW_VISUAL_OUT")
	if not output.is_empty():
		if not _check(DisplayServer.get_name() != "headless", "captures require a real renderer"):
			return
		DirAccess.make_dir_recursive_absolute(output)
	for size in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = size
		root.content_scale_size = size
		for entry in Catalog.entries():
			for locale in Locales:
				var id: String = entry["id"]
				var game = ReviewScene.instantiate()
				game.review_arguments.assign(["--review-mission=" + id, "--review-lang=" + locale])
				root.add_child(game)
				game.set_process(false)
				await process_frame
				await process_frame
				await process_frame
				var panel: Control = game.review_panel
				var scroll: ScrollContainer = game.review_scroll
				var bounds := Rect2(Vector2.ZERO, Vector2(size))
				if not _check(game.review_valid and game.review_open and not game.review_started, "startup stays in the review lobby"):
					return
				if not _check(bounds.encloses(panel.get_global_rect()), "panel inside viewport: " + id + " " + locale):
					return
				if not _check(not game.review_body.text.is_empty() and game.review_body.size.x <= panel.size.x, "wrapped review text"):
					return
				if not _check(game.review_buttons.size() >= 9, "all review controls exist"):
					return
				for key in game.review_buttons:
					var button: Button = game.review_buttons[key]
					if not button.visible:
						continue
					if not _check(button.get_combined_minimum_size().x <= panel.size.x, "button can fit: " + key):
						return
				# The two entry actions should be directly visible at startup.
				for key in ["new", "continue"]:
					var button: Button = game.review_buttons[key]
					if not _check(bounds.encloses(button.get_global_rect()), "initial entry button visible: " + key):
						return
				if not _check(scroll.get_child_count() > 0, "scrollable audit body exists"):
					return
				var body := scroll.get_child(0) as Control
				if not _check(body != null and body.size.x <= scroll.size.x + 1.0, "no horizontal audit overflow"):
					return
				if not output.is_empty():
					await RenderingServer.frame_post_draw
					var path := output.path_join("%s_%s_%dx%d.png" % [id, locale, size.x, size.y])
					if not _check(root.get_texture().get_image().save_png(path) == OK, "capture stored"):
						return
					captures += 1
				if id == "first_supply":
					if not await _exercise_first_supply(game, bounds, locale, output):
						return
				game.queue_free()
				await process_frame
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("summary.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks": checks, "captures": captures, "scenes": 9, "locales": 7, "sizes": ["1280x720", "640x360"], "human_visual_review": false}))
	print("REVIEW_SLICE_LAYOUT_OK checks=%d scenes=9 locales=7 sizes=2 captures=%d human_visual_review=false" % [checks, captures])
	quit(0)

func _exercise_first_supply(game, bounds: Rect2, locale: String, output: String) -> bool:
	# Exercise the displayed controls, not only the unstarted review lobby.
	if not _check(game.review_body.text.begins_with(game._review_text("progress")), "goals precede audit metadata " + locale):
		return false
	game.review_buttons["new"].pressed.emit()
	if game.review_reset_confirm:
		game.review_buttons["new"].pressed.emit()
	if not _check(game._campaign_active() and game.review_started, "new button opens mission " + locale):
		return false
	game.review_buttons["play"].pressed.emit()
	await process_frame
	var guide: Rect2 = game._chapter_guidance_rect()
	if not _check(not game.review_open and not game.main_menu_active and bounds.encloses(guide), "live goals inside viewport " + locale):
		return false
	var lines: Array = game.campaign_ui.progress_hud_lines(guide)
	var goal_count := 0
	for line in lines:
		if line["role"] == "progress":
			goal_count += 1
		var width: float = game.fallback_font.get_string_size(line["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, line["size"]).x
		if not _check(width <= guide.size.x - 20.0 + 1.0 and float(line["position"].y) <= guide.size.y, "objective line fits " + locale):
			return false
	if not _check(goal_count == 3 and game.lifetime_organic_absorbed == 0.0 and game.lifetime_mineral_absorbed == 0.0, "three real subtasks, initial stock not progress"):
		return false
	if not await _capture_state(game, locale, output, "playing"):
		return false
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_J
	game._unhandled_input(key)
	if not _check(game.campaign_ui.open, "J opens actual mission objectives"):
		return false
	if not await _capture_state(game, locale, output, "objectives"):
		return false
	var retreat := InputEventMouseButton.new()
	retreat.button_index = MOUSE_BUTTON_LEFT
	retreat.pressed = false
	retreat.position = game.campaign_ui.button_rect(bounds.size, 1).get_center()
	game._unhandled_input(retreat)
	if not _check(game.campaign_ui.confirm_retreat, "return home asks confirmation"):
		return false
	retreat.position = game.campaign_ui.button_rect(bounds.size, 0).get_center()
	game._unhandled_input(retreat)
	await process_frame
	if not _check(game._world_scene_id() == "home_nest" and not game.main_menu_active and not game.review_open and not game.campaign_ui.open, "return reaches playable isolated home"):
		return false
	if not await _capture_state(game, locale, output, "home"):
		return false
	return true


func _capture_state(game, locale: String, output: String, state: String) -> bool:
	game.queue_redraw()
	await process_frame
	await process_frame
	if output.is_empty():
		return true
	await RenderingServer.frame_post_draw
	var path := output.path_join("first_supply_%s_%dx%d_%s.png" % [locale, root.size.x, root.size.y, state])
	if not _check(root.get_texture().get_image().save_png(path) == OK, "gameplay capture " + state):
		return false
	captures += 1
	return true



func _check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failed = true
		printerr("REVIEW_SLICE_LAYOUT_FAIL: ", message)
		quit(1)
	return condition
