extends SceneTree


const RivalCombatLocalization = preload("res://scripts/rival_combat_localization.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected_locales: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
	if not _check(RivalCombatLocalization.LOCALES == expected_locales, "locale order"):
		return
	if not _check(RivalCombatLocalization.KEYS.size() == 76, "key count"):
		return
	var unique_keys := {}
	for key in RivalCombatLocalization.KEYS:
		unique_keys[key] = true
	if not _check(unique_keys.size() == RivalCombatLocalization.KEYS.size(), "keys unique"):
		return
	var unique_reasons := {}
	for reason_id in RivalCombatLocalization.REASON_IDS:
		unique_reasons[reason_id] = true
		if not _check(not String(reason_id).contains(" "), "stable reason token %s" % reason_id):
			return
	if not _check(unique_reasons.size() == 13, "reason IDs unique"):
		return
	var english: Array = RivalCombatLocalization.VALUES["en"]
	for locale_id in expected_locales:
		var row: Array = RivalCombatLocalization.VALUES.get(locale_id, [])
		if not _check(row.size() == RivalCombatLocalization.KEYS.size(), "%s row length" % locale_id):
			return
		for index in range(row.size()):
			var value := String(row[index])
			if not _check(not value.strip_edges().is_empty(), "%s:%s nonempty" % [locale_id, RivalCombatLocalization.KEYS[index]]):
				return
			if not _check(_placeholder_signature(value) == _placeholder_signature(String(english[index])), "%s:%s placeholders" % [locale_id, RivalCombatLocalization.KEYS[index]]):
				return
	for reason_id in RivalCombatLocalization.REASON_IDS:
		if not _check(RivalCombatLocalization.text("reason_%s" % reason_id, "en") != "reason_%s" % reason_id, "reason display %s" % reason_id):
			return
	if not _check(RivalCombatLocalization.normalize_locale("zh-Hant-HK") == "zh_TW", "Traditional alias"):
		return
	if not _check(RivalCombatLocalization.normalize_locale("es-MX") == "es", "regional alias"):
		return
	if not _check(RivalCombatLocalization.text("missing_key", "ru") == "missing_key", "unknown key fallback"):
		return
	print("RIVAL_COMBAT_LOCALIZATION_OK locales=7 keys=76 reasons=13 stable_ids=true")
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
	push_error("RIVAL_COMBAT_LOCALIZATION_FAIL: " + message)
	quit(1)
	return false
