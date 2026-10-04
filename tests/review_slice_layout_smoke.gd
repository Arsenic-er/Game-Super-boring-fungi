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
				game.queue_free()
				await process_frame
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("summary.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks": checks, "captures": captures, "scenes": 9, "locales": 7, "sizes": ["1280x720", "640x360"], "human_visual_review": false}))
	print("REVIEW_SLICE_LAYOUT_OK checks=%d scenes=9 locales=7 sizes=2 captures=%d human_visual_review=false" % [checks, captures])
	quit(0)


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failed = true
		printerr("REVIEW_SLICE_LAYOUT_FAIL: ", message)
		quit(1)
	return condition
