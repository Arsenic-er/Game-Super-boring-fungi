extends SceneTree


const DeveloperLocalization = preload("res://scripts/developer_localization.gd")
const EXPECTED_LOCALES: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
const EXPECTED_PAGE_IDS: Array[String] = ["colony", "world", "progress"]
const REQUIRED_OFFLINE_KEYS: Array[String] = ["offline_settlement_title", "offline_settlement_progress_fmt"]

var assertion_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _check(DeveloperLocalization.LOCALES == EXPECTED_LOCALES, "developer locale order should match the seven interface locales"):
		return
	var reference: Dictionary = DeveloperLocalization.TEXTS.get("en", {})
	if not _check(reference.size() >= 83, "developer localization should expose the original 81 keys plus two offline-settlement keys"):
		return
	for required_key in REQUIRED_OFFLINE_KEYS:
		if not _check(reference.has(required_key) and not String(reference.get(required_key, "")).strip_edges().is_empty(), "English developer table should contain %s" % required_key):
			return
	if not _check(DeveloperLocalization.PAGE_IDS == EXPECTED_PAGE_IDS, "developer pages should remain colony, world, progress"):
		return

	var all_action_ids: Array[String] = []
	for page_id in DeveloperLocalization.PAGE_IDS:
		var page_actions: Array[String] = DeveloperLocalization.page_actions(page_id)
		if not _check(not page_actions.is_empty(), "%s page should expose developer actions" % page_id):
			return
		all_action_ids.append_array(page_actions)
	if not _check(all_action_ids.size() == 30, "three developer pages should expose all 30 actions"):
		return
	if not _check(_unique_count(all_action_ids) == all_action_ids.size(), "developer action IDs should be unique across pages"):
		return

	var reference_keys := _sorted_keys(reference)
	for locale_id in EXPECTED_LOCALES:
		var table: Dictionary = DeveloperLocalization.TEXTS.get(locale_id, {})
		if not _check(table.size() == reference.size(), "%s should contain every developer translation key" % locale_id):
			return
		if not _check(_sorted_keys(table) == reference_keys, "%s developer keys should exactly match English" % locale_id):
			return
		for key in reference_keys:
			var translated := String(table.get(key, ""))
			if not _check(not translated.strip_edges().is_empty(), "%s:%s should not be empty" % [locale_id, key]):
				return
			if not _check(_format_signature(translated) == _format_signature(String(reference[key])), "%s:%s should preserve format placeholders" % [locale_id, key]):
				return
		for page_id in DeveloperLocalization.PAGE_IDS:
			if not _check(not DeveloperLocalization.page_title(page_id, locale_id).strip_edges().is_empty() and not DeveloperLocalization.page_description(page_id, locale_id).strip_edges().is_empty(), "%s:%s page title and description should be non-empty" % [locale_id, page_id]):
				return
		for action_id in all_action_ids:
			if not _check(not DeveloperLocalization.action_label(action_id, locale_id).strip_edges().is_empty(), "%s:%s action label should be non-empty" % [locale_id, action_id]):
				return

	print("DEVELOPER_LOCALIZATION_OK locales=7 keys=%d pages=3 actions=30 assertions=%d placeholders=stable" % [reference.size(), assertion_count])
	quit(0)


func _sorted_keys(table: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key in table.keys():
		result.append(String(key))
	result.sort()
	return result


func _unique_count(values: Array[String]) -> int:
	var unique := {}
	for value in values:
		unique[value] = true
	return unique.size()


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


func _check(condition: bool, message: String) -> bool:
	assertion_count += 1
	if condition:
		return true
	push_error("DEVELOPER_LOCALIZATION_FAIL[%d]: %s" % [assertion_count, message])
	quit(1)
	return false
