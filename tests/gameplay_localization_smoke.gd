extends SceneTree


const GameplayLocalization = preload("res://scripts/gameplay_localization.gd")
const PIXEL_FONT_PATH := "res://assets/fonts/fusion-bold/fusion-bold-pixel-12px-proportional-zh_hans.ttf"
const RADIAL_LABEL_MAX_WIDTH := 44.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected_locales: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
	if not _check(GameplayLocalization.LOCALES == expected_locales, "locale order should match the shell catalog"):
		return
	if not _check(GameplayLocalization.normalize_locale("zh-Hant-HK") == "zh_TW", "Traditional Chinese aliases should normalize to zh_TW"):
		return
	if not _check(GameplayLocalization.normalize_locale("zh-Hans-SG") == "zh_CN", "Simplified Chinese aliases should normalize to zh_CN"):
		return
	if not _check(GameplayLocalization.normalize_locale("es-MX") == "es" and GameplayLocalization.normalize_locale("de-DE") == "de", "regional aliases should normalize to their base locale"):
		return
	if not _check(GameplayLocalization.normalize_locale("unknown") == "en", "unknown locales should use the English fallback"):
		return

	var reference: Dictionary = GameplayLocalization.TEXTS.get("en", {})
	if not _check(reference.size() >= 100, "gameplay catalog should contain the complete v0.41 key set"):
		return
	var reference_keys := reference.keys()
	reference_keys.sort()
	for locale_id in expected_locales:
		var table: Dictionary = GameplayLocalization.TEXTS.get(locale_id, {})
		var locale_keys := table.keys()
		locale_keys.sort()
		if not _check(locale_keys == reference_keys, "%s should have exactly the English key set" % locale_id):
			return
		for key_value in reference_keys:
			var key := String(key_value)
			var translated := String(table.get(key, ""))
			if not _check(not translated.strip_edges().is_empty(), "%s:%s should not be empty" % [locale_id, key]):
				return
			if not _check(_placeholder_signature(translated) == _placeholder_signature(String(reference[key])), "%s:%s should preserve placeholder order and precision" % [locale_id, key]):
				return
			if not _check(GameplayLocalization.text(key, locale_id) == translated, "%s:%s should resolve directly" % [locale_id, key]):
				return

	if not _check(GameplayLocalization.text("hud_pause", "xx-YY") == String(reference["hud_pause"]), "unknown locale lookup should return English"):
		return
	if not _check(GameplayLocalization.text("missing_gameplay_key", "ru") == "missing_gameplay_key", "unknown keys should remain visible for debugging"):
		return

	var unit_keys: Array[String] = [
		"unit_forager", "unit_carrier", "unit_chelator", "unit_scout", "unit_lytic",
		"unit_suppressor", "unit_disperser", "unit_piercer", "unit_coil", "unit_antifungal"
	]
	var state_keys: Array[String] = [
		"state_idle", "state_moving", "state_gathering", "state_attack_bacteria",
		"state_attack_fungus", "state_attack_hypha", "state_attack_guard", "state_deploying",
		"state_deployed", "state_returning", "state_retreating", "state_repairing",
		"state_wounded", "state_guarding"
	]
	var hover_keys: Array[String] = [
		"hover_core_fmt", "hover_biomass_fmt", "hover_state_fmt", "hover_cargo_fmt",
		"hover_home_fmt", "hover_home_core_fmt", "hover_no_barracks",
		"hover_defense_zone_fmt", "hover_harvest_zone_fmt", "hover_purge_zone_fmt"
	]
	var bacteria_keys: Array[String] = [
		"bacteria_normal", "bacteria_bloom", "bacteria_behavior_normal", "bacteria_behavior_bloom",
		"bacteria_absorb_fmt", "bacteria_division_fmt", "bacteria_genome", "bacteria_toxin_1",
		"bacteria_toxin_2", "suppress_source_capsule", "suppress_source_core",
		"bacteria_suppressed_fmt"
	]
	if not _check(_contains_all(reference, unit_keys) and unit_keys.size() == 10, "all ten expedition unit names should be catalogued"):
		return
	if not _check(_contains_all(reference, state_keys) and state_keys.size() == 14, "all fourteen expedition states should be catalogued"):
		return
	if not _check(_contains_all(reference, hover_keys), "common expedition and core hover text should be catalogued"):
		return
	if not _check(_contains_all(reference, bacteria_keys), "bacteria hover text should be catalogued"):
		return

	var pixel_font: Font = load(PIXEL_FONT_PATH)
	if pixel_font == null:
		pixel_font = ThemeDB.fallback_font
	for locale_id in expected_locales:
		for key in GameplayLocalization.SHORT_KEYS:
			var label := GameplayLocalization.text(key, locale_id)
			var width := pixel_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var allow_id := "%s:%s" % [locale_id, key]
			var may_shrink := GameplayLocalization.SHORT_ALLOW_SHRINK.has(key) or GameplayLocalization.SHORT_ALLOW_SHRINK.has(allow_id)
			if not _check(width <= RADIAL_LABEL_MAX_WIDTH or may_shrink, "%s:%s is %.1f px; keep it <= %.1f px or mark it for main-script shrink" % [locale_id, key, width, RADIAL_LABEL_MAX_WIDTH]):
				return

	print("GAMEPLAY_LOCALIZATION_OK locales=7 keys=", reference.size(), " units=10 states=14 short_labels=", GameplayLocalization.SHORT_KEYS.size())
	quit(0)


func _placeholder_signature(value: String) -> String:
	var matcher := RegEx.new()
	matcher.compile("%(?:\\.\\d+)?[sdf]")
	var tokens: PackedStringArray = []
	for result in matcher.search_all(value):
		tokens.append(result.get_string())
	return "|".join(tokens)


func _contains_all(table: Dictionary, keys: Array[String]) -> bool:
	for key in keys:
		if not table.has(key):
			return false
	return true


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("GAMEPLAY_LOCALIZATION_FAIL: " + message)
	quit(1)
	return false
