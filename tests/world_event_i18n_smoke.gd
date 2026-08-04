extends SceneTree


const ChapterLocalization = preload("res://scripts/chapter_localization.gd")
const WorldEventLocalization = preload("res://scripts/world_event_localization.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_script: Script = load("res://scripts/main.gd")
	if not _check(game_script != null, "main script should load"):
		return
	var game: Node = game_script.new()

	for locale_id in WorldEventLocalization.LOCALES:
		game.settings_locale = locale_id
		var tasks: Array = game._chapter_tasks()
		if not _check(tasks.size() == 9 and String(tasks[0]["id"]) == "wake_spore" and String(tasks[8]["id"]) == "clear_rival", "%s chapter stable IDs" % locale_id):
			return
		if not _check(String(tasks[0]["title"]) == String(ChapterLocalization.tasks(locale_id)[0]["title"]), "%s chapter copy lookup" % locale_id):
			return
		if not _check(game._ecology_event_name("bloom") == WorldEventLocalization.text("ecology_name_bloom", locale_id), "%s bloom name" % locale_id):
			return
		if not _check(game._ecology_event_name("toxin") == WorldEventLocalization.text("ecology_name_toxin", locale_id), "%s toxin name" % locale_id):
			return
		if not _check(game._ecology_event_name("future_event") == "future_event", "%s unknown event stable fallback" % locale_id):
			return
		if not _check(game._format_duration(45.0) == WorldEventLocalization.text("duration_seconds_fmt", locale_id) % 45, "%s duration seconds" % locale_id):
			return
		if not _check(game._format_duration(120.0) == WorldEventLocalization.text("duration_minutes_fmt", locale_id) % 2, "%s duration minutes" % locale_id):
			return

		game._show_fungal_incursion_warning()
		if not _check(game.toast_text == WorldEventLocalization.text("sporefall_warning_toast_fmt", locale_id) % roundi(game.FUNGAL_INCURSION_WARNING_SECONDS), "%s sporefall warning toast" % locale_id):
			return
		game._show_fungal_incursion_active(2)
		if not _check(game.toast_text == WorldEventLocalization.text("sporefall_active_toast_fmt", locale_id) % 2, "%s sporefall active toast" % locale_id):
			return

		game.bacteria.clear()
		var bloom := {"id": 40, "type": "bloom", "phase": "warning", "pos": Vector2.ZERO, "radius": game.ECOLOGY_BLOOM_RADIUS, "remaining": 0.0, "spawned": 0, "control_progress": 0.0}
		if not _check(game._activate_ecology_event(bloom), "%s bloom activates" % locale_id):
			return
		if not _check(String(bloom["phase"]) == "active", "%s bloom keeps stable active phase" % locale_id):
			return
		if not _check(game.ecology_banner_title == WorldEventLocalization.text("ecology_bloom_active_title", locale_id), "%s bloom banner title" % locale_id):
			return
		var bloom_detail := WorldEventLocalization.text("ecology_bloom_active_detail_fmt", locale_id) % [game.ECOLOGY_BLOOM_SPAWN_COUNT, 3, roundi(game.BLOOM_CONTAINMENT_HOLD_SECONDS)]
		if not _check(game.ecology_banner_detail == bloom_detail, "%s bloom banner detail" % locale_id):
			return

		var toxin := {"id": 41, "type": "toxin", "phase": "warning", "pos": Vector2.ZERO, "radius": game.ECOLOGY_TOXIN_ZONE_RADIUS, "remaining": 0.0}
		if not _check(game._activate_ecology_event(toxin), "%s toxin activates" % locale_id):
			return
		if not _check(String(toxin["phase"]) == "active" and game.ecology_banner_title == WorldEventLocalization.text("ecology_toxin_active_title", locale_id), "%s toxin stable phase and title" % locale_id):
			return

	game.settings_locale = "en"
	game.organic = 0.0
	game.mineral = 0.0
	game.dna = 0
	game.lifetime_fungal_incursions_defeated = 2
	game.fungal_incursion = {"phase": "active", "remaining": 0.0, "pos": Vector2.ZERO, "wave": 3, "enemy_id": 77}
	game._complete_fungal_incursion(77)
	if not _check(game.toast_text == WorldEventLocalization.text("sporefall_defeated_dna_fmt", "en") % [3, 21.0, 1.0, 1], "wave three localized reward toast"):
		return
	if not _check(String(game.fungal_incursion["phase"]) == "cooldown" and game.dna == 1, "reward keeps stable phase and values"):
		return

	print("WORLD_EVENT_I18N_OK locales=7 chapter=9 ecology=2 sporefall=3 duration=localized stable_ids=true")
	game.free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("WORLD_EVENT_I18N_FAIL: " + message)
	quit(1)
	return false
