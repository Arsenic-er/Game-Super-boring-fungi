extends SceneTree


const WorldEventLocalization = preload("res://scripts/world_event_localization.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected_locales: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
	if not _check(WorldEventLocalization.LOCALES == expected_locales, "locale order"):
		return
	var unique_keys := {}
	for key in WorldEventLocalization.KEYS:
		unique_keys[key] = true
	if not _check(unique_keys.size() == WorldEventLocalization.KEYS.size(), "keys must be unique"):
		return
	if not _check(WorldEventLocalization.KEYS.size() >= 36, "catalog covers ecology, sporefall and threat"):
		return
	var english: Array = WorldEventLocalization.VALUES["en"]
	if not _check(english.size() == WorldEventLocalization.KEYS.size(), "English value count"):
		return
	for locale_id in expected_locales:
		var values: Array = WorldEventLocalization.VALUES.get(locale_id, [])
		if not _check(values.size() == WorldEventLocalization.KEYS.size(), "%s value count" % locale_id):
			return
		for index in range(values.size()):
			var value := String(values[index])
			if not _check(not value.strip_edges().is_empty(), "%s:%s nonempty" % [locale_id, WorldEventLocalization.KEYS[index]]):
				return
			if not _check(_placeholder_signature(value) == _placeholder_signature(String(english[index])), "%s:%s placeholder parity" % [locale_id, WorldEventLocalization.KEYS[index]]):
				return

	if not _check(WorldEventLocalization.normalize_locale("zh-Hant-HK") == "zh_TW", "Traditional alias"):
		return
	if not _check(WorldEventLocalization.normalize_locale("de-AT") == "de", "regional alias"):
		return
	if not _check(WorldEventLocalization.normalize_locale("unknown") == "en", "fallback locale"):
		return
	if not _check(WorldEventLocalization.text("ecology_name_bloom", "en") == "Local bacterial bloom", "English ecology lookup"):
		return
	if not _check(WorldEventLocalization.text("sporefall_warning_toast_fmt", "ru").contains("%d"), "Russian sporefall placeholder"):
		return

	print("WORLD_EVENT_LOCALIZATION_OK locales=7 keys=", WorldEventLocalization.KEYS.size(), " stable_phases=true")
	quit(0)


func _placeholder_signature(value: String) -> String:
	var matcher := RegEx.new()
	matcher.compile("%(?:0?\\d+)?(?:\\.\\d+)?[sdf]")
	var tokens: PackedStringArray = []
	for result in matcher.search_all(value):
		tokens.append(result.get_string())
	return "|".join(tokens)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("WORLD_EVENT_LOCALIZATION_FAIL: " + message)
	quit(1)
	return false
