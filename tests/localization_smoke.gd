extends SceneTree


const UILocalization = preload("res://scripts/ui_localization.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected_locales: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
	var expected_names: Array[String] = ["简体中文", "繁體中文", "English", "日本語", "Español", "Deutsch", "Русский"]
	if not _check(UILocalization.LOCALES == expected_locales, "locale order should be zh_CN, zh_TW, en, ja, es, de, ru"):
		return
	for index in range(expected_locales.size()):
		if not _check(UILocalization.locale_name(expected_locales[index]) == expected_names[index], "locale self-name mismatch for %s" % expected_locales[index]):
			return
	if not _check(UILocalization.normalize_locale("zh-Hant-HK") == "zh_TW" and UILocalization.normalize_locale("es-MX") == "es" and UILocalization.normalize_locale("unknown") == "zh_CN", "locale aliases and invalid values should normalize safely"):
		return

	var reference: Dictionary = UILocalization.TEXTS["en"]
	if not _check(reference.size() >= 45, "shell localization should expose the complete key set"):
		return
	for locale_id in expected_locales:
		var table: Dictionary = UILocalization.TEXTS.get(locale_id, {})
		if not _check(table.size() == reference.size(), "%s should contain every shell translation key" % locale_id):
			return
		for key in reference.keys():
			var translated := String(table.get(key, ""))
			if not _check(translated != "", "%s:%s should not be empty" % [locale_id, key]):
				return
			if not _check(_format_signature(translated) == _format_signature(String(reference[key])), "%s:%s should preserve format placeholders" % [locale_id, key]):
				return

	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game.autosave_enabled = false
	game.first_locale_prompt = false

	if not _check(game._should_prompt_for_locale(false, false), "a fresh install without settings or save should show the language prompt"):
		return
	if not _check(not game._should_prompt_for_locale(true, false), "legacy settings should prevent a forced language prompt"):
		return
	if not _check(not game._should_prompt_for_locale(false, true), "an existing save should prevent a forced language prompt even when settings are missing"):
		return

	game.main_menu_page = "settings"
	game.pause_menu_page = "settings"
	if not _check(game._main_menu_labels().size() == 10 and game._pause_menu_labels().size() == 9, "main settings should add the developer switch while pause settings keep the nine regular actions"):
		return
	game.main_menu_page = "language"
	game.pause_menu_page = "language"
	if not _check(game._main_menu_labels().size() == 8 and game._pause_menu_labels().size() == 8, "language pages should expose seven locales plus Back"):
		return
	for index in range(7):
		if not _check(game._main_menu_labels()[index] == expected_names[index], "main language page should keep the canonical self-name order"):
			return
	game.first_locale_prompt = true
	if not _check(game._main_menu_labels().size() == 7 and game._pause_menu_labels().size() == 8, "first-run language page should be modal while pause language keeps Back"):
		return
	for viewport in [Vector2(1280.0, 720.0), Vector2(960.0, 540.0), Vector2(640.0, 360.0)]:
		if not _check(_main_layout_valid(game, viewport), "first-run language page should fit at %dx%d" % [int(viewport.x), int(viewport.y)]):
			return
	game.first_locale_prompt = false

	for locale_id in expected_locales:
		game.settings_locale = locale_id
		game.main_menu_page = "settings"
		game.pause_menu_page = "settings"
		if not _check(game._main_menu_labels().size() == 10 and game._pause_menu_labels().size() == 9, "%s settings should keep main=10 and pause=9 button counts" % locale_id):
			return
		for viewport in [Vector2(1280.0, 720.0), Vector2(960.0, 540.0), Vector2(640.0, 360.0)]:
			if not _check(_main_layout_valid(game, viewport) and _pause_layout_valid(game, viewport), "%s settings should fit at %dx%d" % [locale_id, int(viewport.x), int(viewport.y)]):
				return
		game.main_menu_page = "language"
		game.pause_menu_page = "language"
		for viewport in [Vector2(1280.0, 720.0), Vector2(960.0, 540.0), Vector2(640.0, 360.0)]:
			if not _check(_main_layout_valid(game, viewport) and _pause_layout_valid(game, viewport), "%s language page should fit at %dx%d" % [locale_id, int(viewport.x), int(viewport.y)]):
				return

	var settings_path := "user://settings.json"
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"fullscreen": false, "pixel_cursor": true}))
	file = null
	game.settings_locale = "ru"
	game._load_settings()
	if not _check(game.settings_locale == "zh_CN", "legacy settings without locale should default to Simplified Chinese"):
		return
	game._set_ui_locale("de-DE")
	game.settings_locale = "zh_CN"
	game._load_settings()
	if not _check(game.settings_locale == "de", "selected locale should save and reload"):
		return
	file = FileAccess.open(settings_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"locale": "invalid-locale"}))
	file = null
	game._load_settings()
	if not _check(game.settings_locale == "zh_CN", "invalid saved locale should fall back safely"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
	game.settings_locale = "zh_CN"
	game.first_locale_prompt = true
	game.main_menu_page = "language"
	game._handle_main_menu_click(game._main_menu_button_rect(game.get_viewport_rect().size, 0).get_center())
	if not _check(not game.first_locale_prompt and game.main_menu_page == "main" and FileAccess.file_exists(settings_path), "choosing the default locale on first run should persist and continue"):
		return
	game.settings_locale = "ru"
	game._load_settings()
	if not _check(game.settings_locale == "zh_CN", "the unchanged default locale should be written during first-run confirmation"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))

	game.main_menu_page = "language"
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	game.first_locale_prompt = true
	game._unhandled_input(esc)
	if not _check(game.main_menu_page == "language" and game.first_locale_prompt, "Esc should not dismiss the first-run language page"):
		return
	game.first_locale_prompt = false
	game._unhandled_input(esc)
	if not _check(game.main_menu_page == "settings", "Esc should return from main language page to settings"):
		return
	game.main_menu_active = false
	game.game_started = true
	game.pause_menu_open = true
	game.pause_menu_page = "language"
	game._unhandled_input(esc)
	if not _check(game.pause_menu_open and game.pause_menu_page == "settings", "Esc should return from pause language page to pause settings"):
		return

	print("LOCALIZATION_OK locales=7 keys=", reference.size(), " settings=main10/pause9 language_page=8 first_run=modal layouts=3 legacy=compatible")
	game.queue_free()
	quit(0)


func _format_signature(value: String) -> String:
	var signature := ""
	var index := 0
	while index < value.length():
		if value[index] == "%" and index + 1 < value.length():
			var marker := value[index + 1]
			if marker == "%":
				index += 2
				continue
			if marker == "s" or marker == "d" or marker == "f":
				signature += "%" + marker
		index += 1
	return signature


func _main_layout_valid(game: Node, viewport: Vector2) -> bool:
	var previous := Rect2()
	for index in range(game._main_menu_labels().size()):
		var rect: Rect2 = game._main_menu_button_rect(viewport, index)
		if not Rect2(Vector2.ZERO, viewport).encloses(rect) or (index > 0 and previous.intersects(rect)):
			return false
		previous = rect
	return true


func _pause_layout_valid(game: Node, viewport: Vector2) -> bool:
	var panel: Rect2 = game._pause_menu_panel_rect(viewport)
	var previous := Rect2()
	for index in range(game._pause_menu_labels().size()):
		var rect: Rect2 = game._pause_menu_button_rect(viewport, index)
		if not panel.encloses(rect) or (index > 0 and previous.intersects(rect)):
			return false
		previous = rect
	return true


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("LOCALIZATION_FAIL: " + message)
	quit(1)
	return false
