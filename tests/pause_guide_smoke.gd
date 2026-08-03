extends SceneTree


const GuideLocalization = preload("res://scripts/guide_localization.gd")
const GUIDE_PATHS := [
	"res://assets/guide/guide_germination.png",
	"res://assets/guide/guide_resources_dna.png",
	"res://assets/guide/guide_evolution.png",
	"res://assets/guide/guide_barracks_command.png",
	"res://assets/guide/guide_exploration_goals.png",
	"res://assets/guide/guide_survival_failure.png"
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var reference: Dictionary = GuideLocalization.TEXTS["en"]
	if not _check(GuideLocalization.LOCALES.size() == 7 and GuideLocalization.PAGE_IDS.size() == 6, "guide should expose seven locales and six stable pages"):
		return
	for locale_id in GuideLocalization.LOCALES:
		var table: Dictionary = GuideLocalization.TEXTS.get(locale_id, {})
		if not _check(table.size() == reference.size(), "%s should contain the complete guide catalog" % locale_id):
			return
		for key in reference.keys():
			if not _check(String(table.get(key, "")) != "", "%s:%s should not be empty" % [locale_id, key]):
				return
		for page_id in GuideLocalization.PAGE_IDS:
			var page := GuideLocalization.page(page_id, locale_id)
			if not _check(String(page["title"]) != "" and String(page["body"]).count("\n") == 2 and String(page["hint"]) != "", "%s:%s should have a title, three short paragraphs, and a hint" % [locale_id, page_id]):
				return

	for path_value in GUIDE_PATHS:
		var imported_texture: Texture2D = ResourceLoader.load(path_value)
		if not _check(imported_texture != null and imported_texture.get_width() == 256 and imported_texture.get_height() == 256, "%s should be an imported 256x256 texture" % path_value):
			return

	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game.autosave_enabled = false
	game.main_menu_active = false
	game.game_started = true
	if not _check(game.guide_textures.size() == 6, "the game should create all six guide textures"):
		return
	for texture in game.guide_textures:
		if not _check(texture != null and texture.get_width() == 256 and texture.get_height() == 256, "runtime guide textures should preserve their source size"):
			return
	game.pause_menu_open = true
	game.pause_menu_page = "main"
	game.settings_locale = "en"
	if not _check(game._pause_menu_labels().size() == 6 and game._pause_menu_labels()[5] == GuideLocalization.text("menu_guide", "en"), "guide should append to the pause menu without moving existing actions"):
		return

	game._handle_pause_menu_click(game._pause_menu_button_rect(Vector2(1280.0, 720.0), 5).get_center())
	if not _check(game.pause_menu_open and game.pause_menu_page == "guide" and game.pause_guide_page == 0, "guide action should open page one while staying paused"):
		return
	game._handle_pause_menu_click(game._pause_menu_button_rect(Vector2(1280.0, 720.0), 1).get_center())
	if not _check(game.pause_guide_page == 1, "Next should advance the guide"):
		return
	game._handle_pause_menu_click(game._pause_menu_button_rect(Vector2(1280.0, 720.0), 0).get_center())
	game._handle_pause_menu_click(game._pause_menu_button_rect(Vector2(1280.0, 720.0), 0).get_center())
	if not _check(game.pause_guide_page == GuideLocalization.PAGE_IDS.size() - 1, "Previous should wrap from the first page to the last"):
		return

	var home := InputEventKey.new()
	home.keycode = KEY_HOME
	home.pressed = true
	game._unhandled_input(home)
	if not _check(game.pause_guide_page == 0, "Home should jump to the first guide page"):
		return
	var end := InputEventKey.new()
	end.keycode = KEY_END
	end.pressed = true
	game._unhandled_input(end)
	if not _check(game.pause_guide_page == GuideLocalization.PAGE_IDS.size() - 1, "End should jump to the final guide page"):
		return
	var right := InputEventKey.new()
	right.keycode = KEY_RIGHT
	right.pressed = true
	game._unhandled_input(right)
	if not _check(game.pause_guide_page == 0, "Right should wrap after the final page"):
		return

	for locale_id in GuideLocalization.LOCALES:
		game.settings_locale = locale_id
		for viewport in [Vector2(1280.0, 720.0), Vector2(960.0, 540.0), Vector2(640.0, 360.0)]:
			game.pause_menu_page = "guide"
			var panel: Rect2 = game._pause_menu_panel_rect(viewport)
			var content: Rect2 = game._pause_guide_content_rect(panel)
			var text_rect: Rect2 = game._pause_guide_text_rect(panel)
			var image_rect: Rect2 = game._pause_guide_image_rect(panel)
			if not _check(Rect2(Vector2.ZERO, viewport).encloses(panel) and panel.encloses(content) and content.encloses(text_rect) and content.encloses(image_rect), "%s guide regions should fit at %dx%d" % [locale_id, int(viewport.x), int(viewport.y)]):
				return
			if not _check(not text_rect.intersects(image_rect) and image_rect.size.x >= 200.0 and is_equal_approx(image_rect.size.x, image_rect.size.y), "%s guide should preserve a readable square illustration at %dx%d" % [locale_id, int(viewport.x), int(viewport.y)]):
				return
			var previous := Rect2()
			for button_index in range(3):
				var button: Rect2 = game._pause_menu_button_rect(viewport, button_index)
				if not _check(panel.encloses(button) and (button_index == 0 or not previous.intersects(button)), "%s guide navigation should fit at %dx%d" % [locale_id, int(viewport.x), int(viewport.y)]):
					return
				previous = button

	game.settings_locale = "en"
	game.pause_menu_page = "guide"
	game.pause_guide_page = 0
	var sim_before: float = game.sim_time
	var organic_before: float = game.organic
	game._process(10.0)
	if not _check(is_equal_approx(game.sim_time, sim_before) and is_equal_approx(game.organic, organic_before), "the guide should keep the simulation frozen"):
		return
	if not _check(game._audio_hover_target_at(game._pause_menu_button_rect(game.get_viewport_rect().size, 1).get_center()) == "pause_1", "guide navigation should use the existing hover-audio target"):
		return

	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	game._unhandled_input(esc)
	if not _check(game.pause_menu_open and game.pause_menu_page == "main", "Esc should return from the guide to the pause menu"):
		return
	game._unhandled_input(esc)
	if not _check(not game.pause_menu_open, "a second Esc should resume the culture"):
		return

	print("PAUSE_GUIDE_OK locales=7 pages=6 textures=6 layouts=3 navigation=mouse+keyboard pause=frozen")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("PAUSE_GUIDE_FAIL: " + message)
	quit(1)
	return false
