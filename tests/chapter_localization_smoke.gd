extends SceneTree


const ChapterLocalization = preload("res://scripts/chapter_localization.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected_locales: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
	var expected_tasks: Array[String] = [
		"wake_spore", "first_germination", "absorption_network", "record_dna", "expand_colony",
		"diet_strategy", "organize_expedition", "discover_rival", "clear_rival"
	]
	if not _check(ChapterLocalization.LOCALES == expected_locales, "locale order"):
		return
	if not _check(ChapterLocalization.TASK_IDS == expected_tasks, "stable task order"):
		return
	var unique_tasks := {}
	for task_id in ChapterLocalization.TASK_IDS:
		unique_tasks[task_id] = true
	if not _check(unique_tasks.size() == 9, "task IDs must be unique"):
		return

	var reference_keys := (ChapterLocalization.CHROME["en"] as Dictionary).keys()
	reference_keys.sort()
	for locale_id in expected_locales:
		var table: Dictionary = ChapterLocalization.CHROME.get(locale_id, {})
		var keys := table.keys()
		keys.sort()
		if not _check(keys == reference_keys, "%s chrome key parity" % locale_id):
			return
		for key_value in keys:
			var key := String(key_value)
			var value := String(table[key])
			if not _check(not value.strip_edges().is_empty(), "%s:%s nonempty" % [locale_id, key]):
				return
			if not _check(_placeholder_signature(value) == _placeholder_signature(String(ChapterLocalization.CHROME["en"][key])), "%s:%s placeholder parity" % [locale_id, key]):
				return
		var tasks := ChapterLocalization.tasks(locale_id)
		if not _check(tasks.size() == 9, "%s task count" % locale_id):
			return
		for index in range(tasks.size()):
			var task: Dictionary = tasks[index]
			if not _check(String(task["id"]) == expected_tasks[index], "%s stable task id %d" % [locale_id, index]):
				return
			for field in ["title", "detail", "hint"]:
				if not _check(not String(task[field]).strip_edges().is_empty(), "%s task %d %s nonempty" % [locale_id, index, field]):
					return

	if not _check(ChapterLocalization.normalize_locale("zh-Hant-HK") == "zh_TW", "Traditional alias"):
		return
	if not _check(ChapterLocalization.normalize_locale("zh-Hans-SG") == "zh_CN", "Simplified alias"):
		return
	if not _check(ChapterLocalization.normalize_locale("es-MX") == "es", "regional alias"):
		return
	if not _check(ChapterLocalization.normalize_locale("unknown") == "en", "fallback locale"):
		return
	if not _check(String(ChapterLocalization.tasks("zh_CN")[0]["title"]) == "唤醒孢子", "Simplified compatibility start"):
		return
	if not _check(String(ChapterLocalization.tasks("zh_CN")[8]["title"]) == "清除竞争菌落", "Simplified compatibility end"):
		return

	print("CHAPTER_LOCALIZATION_OK locales=7 tasks=9 chrome=7 stable_ids=true")
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
	push_error("CHAPTER_LOCALIZATION_FAIL: " + message)
	quit(1)
	return false
