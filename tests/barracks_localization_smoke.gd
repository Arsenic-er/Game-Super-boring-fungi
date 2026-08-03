extends SceneTree


const BarracksLocalization = preload("res://scripts/barracks_localization.gd")
const PIXEL_FONT_PATH := "res://assets/fonts/fusion-bold/fusion-bold-pixel-12px-proportional-zh_hans.ttf"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected_locales: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
	if not _check(BarracksLocalization.LOCALES == expected_locales, "locale order should match the shell catalog"):
		return
	if not _check(BarracksLocalization.normalize_locale("zh-Hant-HK") == "zh_TW", "Traditional Chinese aliases should normalize"):
		return
	if not _check(BarracksLocalization.normalize_locale("unknown") == "en", "unknown locales should fall back to English"):
		return
	if not _check(BarracksLocalization.KEYS.size() >= 50, "barracks catalog should cover status, buttons, toasts, and special units"):
		return

	var english_values: Array = BarracksLocalization.VALUES["en"]
	for locale_id in expected_locales:
		var values: Array = BarracksLocalization.VALUES.get(locale_id, [])
		if not _check(values.size() == BarracksLocalization.KEYS.size(), "%s should have exactly the common key set" % locale_id):
			return
		for index in range(BarracksLocalization.KEYS.size()):
			var key := String(BarracksLocalization.KEYS[index])
			var translated := String(values[index])
			if not _check(not translated.strip_edges().is_empty(), "%s:%s should not be empty" % [locale_id, key]):
				return
			if not _check(_placeholder_signature(translated) == _placeholder_signature(String(english_values[index])), "%s:%s should preserve placeholder order and precision" % [locale_id, key]):
				return
			if not _check(BarracksLocalization.text(key, locale_id) == translated, "%s:%s should resolve directly" % [locale_id, key]):
				return

	var pixel_font: Font = load(PIXEL_FONT_PATH)
	if pixel_font == null:
		pixel_font = ThemeDB.fallback_font
	for locale_id in expected_locales:
		for unit_id in BarracksLocalization.UNIT_IDS:
			var short_key := "unit_%s_short" % unit_id
			var width := pixel_font.get_string_size(BarracksLocalization.text(short_key, locale_id), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			if not _check(width <= 20.0, "%s:%s should fit the 28 px production slot" % [locale_id, short_key]):
				return

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for required in [
		"BarracksLocalization", "_localized_barracks_unit_short", "directive_defense_short",
		"hover_suppressor_ready_fmt", "hover_disperser_range_fmt", "hover_antifungal_deployed_fmt",
		"SUPPRESSOR_ZONE_RADIUS / 2.0", "ANTIFUNGAL_ZONE_RADIUS / 2.0",
		"_fit_font_size(String(directive_labels[directive_index])", "viewport.x - 24.0"
	]:
		if not _check(main_source.contains(required), "main integration missing: %s" % required):
			return

	if not _check(BarracksLocalization.text("missing_barracks_key", "ru") == "missing_barracks_key", "unknown keys should remain visible"):
		return
	print("BARRACKS_LOCALIZATION_OK locales=7 keys=", BarracksLocalization.KEYS.size(), " units=10 directives=3")
	quit(0)


func _placeholder_signature(value: String) -> String:
	var matcher := RegEx.new()
	matcher.compile("%(?:\\.\\d+)?[sdf]")
	var tokens: PackedStringArray = []
	for result in matcher.search_all(value):
		tokens.append(result.get_string())
	return "|".join(tokens)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BARRACKS_LOCALIZATION_FAIL: " + message)
	quit(1)
	return false
