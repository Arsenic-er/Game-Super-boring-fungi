extends SceneTree


const UILocalization = preload("res://scripts/ui_localization.gd")


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
	game.main_menu_active = true
	game.main_menu_page = "language"
	game.first_locale_prompt = true

	var expected_names: Array[String] = ["简体中文", "繁體中文", "English", "日本語", "Español", "Deutsch", "Русский"]
	if not _check(game._first_language_prompt_active() and game._main_menu_hint_text().is_empty() and game._splash_title_text().is_empty(), "first-run flow should emit no default-language title, subtitle, or bottom instruction text"):
		return
	if not _check(game._main_menu_labels() == expected_names and game._main_menu_labels().size() == UILocalization.LOCALES.size(), "first-run page should show exactly seven self-named language buttons"):
		return
	if not _check(String(game.LANGUAGE_EARTH_LOGO_PATH) == "res://assets/branding/language-earth-logo.png" and ResourceLoader.exists(game.LANGUAGE_EARTH_LOGO_PATH), "transparent pixel Earth logo should exist at the release asset path"):
		return
	if not _check(game.language_earth_logo is Texture2D and game.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Earth logo should load as a nearest-filtered texture"):
		return

	var reference_viewport := Vector2(970.0, 866.0)
	var reference_logo: Rect2 = game._first_language_logo_rect(reference_viewport)
	if not _check(reference_logo.size.is_equal_approx(Vector2(480.0, 180.0)), "970x866 should present the Earth logo at approximately 480x180"):
		return
	for viewport in [reference_viewport, Vector2(960.0, 540.0), Vector2(640.0, 360.0)]:
		var bounds := Rect2(Vector2.ZERO, viewport)
		var logo: Rect2 = game._first_language_logo_rect(viewport)
		if not _check(bounds.encloses(logo) and is_equal_approx(logo.size.x / logo.size.y, 8.0 / 3.0), "Earth logo should remain visible and preserve its layout aspect at %dx%d" % [int(viewport.x), int(viewport.y)]):
			return
		var previous := Rect2()
		for index in range(UILocalization.LOCALES.size()):
			var button: Rect2 = game._main_menu_button_rect(viewport, index)
			if not _check(bounds.encloses(button) and not button.intersects(logo) and (index == 0 or not button.intersects(previous)), "language button %d should fit below the logo at %dx%d" % [index, int(viewport.x), int(viewport.y)]):
				return
			previous = button

	var source_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	var main_source := source_file.get_as_text()
	source_file = null
	if not _check(not main_source.contains("first_language_hint") and not main_source.contains("\"选择语言\"") and not main_source.contains("\"请选择一种界面语言后继续\""), "first-run renderer should not contain or request default Chinese language prompts"):
		return
	var selected_locale := UILocalization.LOCALES[4]
	game._handle_main_menu_click(game._main_menu_button_rect(game.get_viewport_rect().size, 4).get_center())
	if not _check(game.settings_locale == selected_locale and not game.first_locale_prompt and game.main_menu_page == "main", "Earth logo must remain decorative and language buttons must retain input behavior"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.SETTINGS_PATH))
	print("FIRST_LANGUAGE_VISUAL_OK logo=480x180 nearest=true buttons=7 chrome_text=none input=preserved")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FIRST_LANGUAGE_VISUAL_FAIL: " + message)
	quit(1)
	return false
