extends SceneTree


const ChapterLocalization = preload("res://scripts/chapter_localization.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _check(ChapterLocalization.REPORT_KEYS.size() == 15, "report key count"):
		return
	var english: Array = ChapterLocalization.REPORT_VALUES["en"]
	for locale_id in ChapterLocalization.LOCALES:
		var row: Array = ChapterLocalization.REPORT_VALUES.get(locale_id, [])
		if not _check(row.size() == ChapterLocalization.REPORT_KEYS.size(), "%s report row length" % locale_id):
			return
		for index in range(row.size()):
			var value := String(row[index])
			if not _check(not value.strip_edges().is_empty(), "%s:%s nonempty" % [locale_id, ChapterLocalization.REPORT_KEYS[index]]):
				return
			if not _check(_placeholder_signature(value) == _placeholder_signature(String(english[index])), "%s:%s placeholders" % [locale_id, ChapterLocalization.REPORT_KEYS[index]]):
				return
			if not _check(ChapterLocalization.text(ChapterLocalization.REPORT_KEYS[index], locale_id) == value, "%s:%s lookup" % [locale_id, ChapterLocalization.REPORT_KEYS[index]]):
				return

	var game_script: Script = load("res://scripts/main.gd")
	if not _check(game_script != null, "main script loads"):
		return
	var game: Node = game_script.new()
	for viewport in [Vector2(1280, 720), Vector2(960, 540), Vector2(640, 360)]:
		var layout: Dictionary = game._chapter_report_layout(viewport)
		var panel: Rect2 = layout["panel"]
		var stats_bottom := float(layout["first_y"]) + float(layout["row_gap"]) * 4.0
		if not _check(stats_bottom + 6.0 < float(layout["notice_one_y"]), "%s stats before notices" % viewport):
			return
		var first_button: Rect2 = game._chapter_report_button_rect(viewport, 0)
		var button_local_y: float = first_button.position.y - panel.position.y
		if not _check(float(layout["notice_two_y"]) + 8.0 < button_local_y, "%s notices before buttons" % viewport):
			return
		for button_index in range(3):
			if not _check(panel.encloses(game._chapter_report_button_rect(viewport, button_index)), "%s button %d enclosed" % [viewport, button_index]):
				return

	print("CHAPTER_REPORT_I18N_OK locales=7 keys=15 layouts=1280+960+640 overlap=none")
	game.free()
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
	push_error("CHAPTER_REPORT_I18N_FAIL: " + message)
	quit(1)
	return false
