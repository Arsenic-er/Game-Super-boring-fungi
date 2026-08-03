extends SceneTree


const UpgradeLocalization = preload("res://scripts/upgrade_localization.gd")
const PIXEL_FONT_PATH := "res://assets/fonts/fusion-bold/fusion-bold-pixel-12px-proportional-zh_hans.ttf"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
	if not _check(UpgradeLocalization.LOCALES == expected, "locale order must match the other catalogs"):
		return
	if not _check(UpgradeLocalization.normalize_locale("zh-Hant-HK") == "zh_TW", "Traditional Chinese alias"):
		return
	if not _check(UpgradeLocalization.normalize_locale("zh-Hans-SG") == "zh_CN", "Simplified Chinese alias"):
		return
	if not _check(UpgradeLocalization.normalize_locale("es-MX") == "es" and UpgradeLocalization.normalize_locale("de-DE") == "de", "regional aliases"):
		return
	if not _check(UpgradeLocalization.normalize_locale("unknown") == "en", "unknown locale must fall back to English"):
		return

	var reference: Dictionary = UpgradeLocalization.TEXTS.get("en", {})
	if not _check(reference.size() >= 120, "catalog should cover the upgrade shell and all upgrade cards"):
		return
	var keys := reference.keys()
	keys.sort()
	for locale_id in expected:
		var table: Dictionary = UpgradeLocalization.TEXTS.get(locale_id, {})
		var locale_keys := table.keys()
		locale_keys.sort()
		if not _check(locale_keys == keys, "%s must have exactly the English key set" % locale_id):
			return
		for key_value in keys:
			var key := String(key_value)
			var value := String(table.get(key, ""))
			if not _check(not value.strip_edges().is_empty(), "%s:%s must not be empty" % [locale_id, key]):
				return
			if not _check(_placeholder_signature(value) == _placeholder_signature(String(reference[key])), "%s:%s must preserve placeholder order and precision" % [locale_id, key]):
				return

	var required: Array[String] = [
		"title", "tab_self", "tab_diet", "tab_structure", "tab_barracks", "tab_environment",
		"node_level_fmt", "node_action_fmt", "survival_title", "survival_wall_effect_fmt",
		"diet_animal_name", "diet_bacteria_target", "diet_special", "diet_units_tab",
		"component_trap_name", "component_antibiotic_effect_fmt", "unit_lytic_desc",
		"barracks_mastered", "scout_stats_fmt", "structure_branching_name", "structure_growth_fmt",
		"toast_diet_need_fmt", "toast_unlock_need_fmt", "toast_structure_need_fmt"
	]
	for key in required:
		if not _check(reference.has(key), "missing required upgrade key: " + key):
			return

	if not _check(UpgradeLocalization.text("title", "xx-YY") == String(reference["title"]), "unknown locale lookup must use English"):
		return
	if not _check(UpgradeLocalization.text("missing_upgrade_key", "ru") == "missing_upgrade_key", "unknown keys remain visible"):
		return

	var font: Font = load(PIXEL_FONT_PATH)
	if font == null:
		font = ThemeDB.fallback_font
	var button_keys: Array[String] = ["maxed", "maxed_short", "locked", "mastered"]
	for locale_id in expected:
		for key in button_keys:
			var label := UpgradeLocalization.text(key, locale_id)
			if not _check(font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x <= 120.0, "%s:%s cannot fit even at the supported 8 px minimum" % [locale_id, key]):
				return

	print("UPGRADE_LOCALIZATION_OK locales=7 keys=", reference.size())
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
	push_error("UPGRADE_LOCALIZATION_FAIL: " + message)
	quit(1)
	return false
