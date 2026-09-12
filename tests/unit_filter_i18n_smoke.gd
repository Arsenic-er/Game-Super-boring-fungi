extends SceneTree

const Localization = preload("res://scripts/rival_combat_localization.gd")
const FILTER_IDS := ["all", "forager", "carrier", "chelator", "scout", "lytic", "suppressor", "disperser", "piercer", "coil", "antifungal"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.set_process(false)
	game.autosave_enabled = false
	if not _check(game._unit_filter_ids() == FILTER_IDS, "short labels cover the actual 11 filter IDs in display order"):
		return
	for locale_id in Localization.LOCALES:
		game.settings_locale = locale_id
		if not _check((Localization.VALUES[locale_id] as Array).size() == Localization.KEYS.size(), "%s has aligned explicit key/value rows" % locale_id):
			return
		var seen := {}
		for filter_id in FILTER_IDS:
			var key := "filter_short_" + String(filter_id)
			var index := Localization.KEYS.find(key)
			if not _check(index >= 0, "%s exists in the stable-key table" % key):
				return
			var label: String = game._rt(key)
			if not _check(label == String(Localization.VALUES[locale_id][index]) and label.length() >= 1 and label.length() <= 2 and label == label.strip_edges(), "%s/%s has an explicit one- or two-character label" % [locale_id, filter_id]):
				return
			if not _check(not seen.has(label), "%s filter labels are mutually distinguishable: %s" % [locale_id, label]):
				return
			seen[label] = true
			for button_width in [22.0, 24.0, 26.0, 28.0]:
				var available: float = float(button_width) - 6.0
				var size: int = game._fit_font_size(label, available, game.UI_FONT_SIZE, 8)
				var measured: Vector2 = game.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
				if not _check(measured.x <= available + 0.01, "%s/%s fits an actual %.0f px filter with 3 px side padding" % [locale_id, filter_id, button_width]):
					return
			if filter_id != "all" and not _check(game._localized_unit_name(filter_id) != "unit_" + String(filter_id), "existing full unit name remains available"):
				return
			if locale_id == "ru":
				for char_index in range(label.length()):
					var codepoint := label.unicode_at(char_index)
					if not _check(codepoint >= 0x0400 and codepoint <= 0x04ff, "Russian short labels use Cyrillic rather than copied English or Chinese"):
						return
	if not _check(Localization.text("filter_short_all", "unknown") == "Al" and Localization.text("filter_short_carrier", "zh-Hant") == "載", "fallback and traditional-Chinese locale aliases still work"):
		return
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var draw_section := main_source.get_slice("func _draw_unit_filter_bar()", 1).get_slice("\nfunc ", 0)
	if not _check(draw_section.contains("filter_short_") and draw_section.contains("_rt(") and not draw_section.contains("short_names"), "actual filter drawing reads localized short keys, not a hard-coded Chinese dictionary"):
		return
	for player in game.pixel_audio.players:
		player.stop()
		player.stream = null
	game.pixel_audio.ambient_player.stop()
	game.pixel_audio.ambient_player.stream = null
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("UNIT_FILTER_I18N_OK locales=7 filters=11 labels=77 unique=true chars=1-2 widths=22+24+26+28 actual_draw=localized")
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("UNIT_FILTER_I18N_FAIL: " + message)
	quit(1)
	return false
