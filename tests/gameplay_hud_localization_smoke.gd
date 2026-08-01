extends SceneTree


const GameplayLocalization = preload("res://scripts/gameplay_localization.gd")
const PIXEL_FONT_PATH := "res://assets/fonts/fusion-bold/fusion-bold-pixel-12px-proportional-zh_hans.ttf"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_script: Script = load("res://scripts/main.gd")
	if not _check(game_script != null, "main script should load"):
		return
	var game: Node = game_script.new()
	var pixel_font: Font = load(PIXEL_FONT_PATH)
	game.fallback_font = pixel_font if pixel_font != null else ThemeDB.fallback_font

	var panel := Rect2(18.0, 16.0, 708.0, 48.0)
	var previous := Rect2()
	for index in range(4):
		var column: Rect2 = game._resource_column_rect(panel, index)
		if not _check(is_equal_approx(column.size.x, panel.size.x / 4.0), "resource columns should have equal widths"):
			return
		if not _check(panel.encloses(column), "resource columns should remain inside the resource bar"):
			return
		if index > 0 and not _check(is_equal_approx(previous.end.x, column.position.x), "resource columns should be contiguous"):
			return
		previous = column

	# The smallest supported window must keep the resource panel clear of the minimap.
	var compact_panel := Rect2(18.0, 16.0, 380.0, 48.0)
	var compact_minimap := Rect2(410.0, 18.0, 208.0, 176.0)
	if not _check(compact_panel.end.x < compact_minimap.position.x, "640 px resource panel should not overlap the minimap"):
		return

	var locales: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
	for locale_id in locales:
		game.settings_locale = locale_id
		var compact_resource_texts: Array[String] = [
			game._gt("hud_water_compact_fmt"),
			game._gt("hud_organic_compact_fmt") % 123.456,
			game._gt("hud_mineral_compact_fmt") % 78.901,
			game._gt("hud_dna_compact_fmt") % 999
		]
		for text_value in compact_resource_texts:
			var max_width := compact_panel.size.x / 4.0 - 21.0
			var minimum_width: float = game.fallback_font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			if not _check(_fits(game, text_value, max_width), "%s compact resource '%s' min8=%.1f max=%.1f" % [locale_id, text_value, minimum_width, max_width]):
				return
		var full_resource_texts: Array[String] = [game._gt("hud_water_fmt"), game._gt("hud_organic_fmt") % 123.456, game._gt("hud_mineral_fmt") % 78.901, game._gt("hud_dna_fmt") % 999]
		for text_value in full_resource_texts:
			if not _check(_fits(game, text_value, panel.size.x / 4.0 - 21.0), "%s full resource text should fit the normal panel" % locale_id):
				return

		var explore_text: String = game._gt("hud_explore_fmt") % [100.0, 99]
		if not _check(_fits(game, explore_text, 192.0), "%s minimap exploration line should fit" % locale_id):
			return
		if not _check(_fits(game, game._gt("hud_pause"), 40.0), "%s pause label should fit" % locale_id):
			return
		if not _check(_fits(game, game._gt("hud_upgrade"), 94.0), "%s upgrade label should fit" % locale_id):
			return
		if not _check(_fits(game, game._gt("hud_goals_ready_fmt") % 9, 98.0), "%s goals label should fit" % locale_id):
			return

	var source_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	if not _check(source_file != null, "main source should be readable"):
		return
	var source := source_file.get_as_text()
	for key in [
		"hud_water_fmt", "hud_organic_fmt", "hud_mineral_fmt", "hud_dna_fmt",
		"hud_water_compact_fmt", "hud_organic_compact_fmt", "hud_mineral_compact_fmt", "hud_dna_compact_fmt",
		"hud_explore_fmt", "hud_pause", "hud_upgrade", "hud_goals", "hud_goals_ready_fmt"
	]:
		if not _check(source.contains('"%s"' % key), "main HUD should reference %s from the gameplay catalog" % key):
			return

	print("GAMEPLAY_HUD_LOCALIZATION_OK locales=7 resources=4 equal_columns=true")
	game.free()
	quit(0)


func _fits(game: Node, text_value: String, max_width: float) -> bool:
	var font_size: int = game._fit_font_size(text_value, max_width)
	var width: float = game.fallback_font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return width <= max_width + 0.5


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("GAMEPLAY_HUD_LOCALIZATION_FAIL: " + message)
	quit(1)
	return false
