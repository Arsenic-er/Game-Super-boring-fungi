extends SceneTree

const GoalLocalization = preload("res://scripts/goal_localization.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var expected_locales: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
	var expected_ids: Array[String] = [
		"first_hypha", "mineral_trace", "second_core", "network_1mm", "primary_diet",
		"bacterial_bloom", "first_bacterium", "bacteria_control", "first_structure",
		"bacteria_specialist", "culture_survey", "expedition_supply", "expedition_control",
		"barracks_directive", "ecology_response", "suppression_field", "disperser_burst",
		"rival_colony", "rival_guard", "hypha_severing", "antifungal_lockdown", "sporefall_guard"
	]
	if not _check(GoalLocalization.LOCALES == expected_locales and GoalLocalization.GOAL_IDS == expected_ids, "catalog must preserve all 22 stable goal IDs and seven locales"):
		return
	if not _check(GoalLocalization.normalize_locale("zh-Hant-HK") == "zh_TW" and GoalLocalization.normalize_locale("es-MX") == "es" and GoalLocalization.normalize_locale("unknown") == "en", "locale aliases and fallback should be stable"):
		return
	for locale_id in expected_locales:
		for goal_id in expected_ids:
			for field in ["title", "desc"]:
				var key := "goal_%s_%s" % [goal_id, field]
				var value := GoalLocalization.text(key, locale_id)
				if not _check(not value.strip_edges().is_empty() and value != key, "%s:%s must be translated" % [locale_id, key]):
					return
		for key in GoalLocalization.TEXTS:
			var value := GoalLocalization.text(String(key), locale_id)
			var english := GoalLocalization.text(String(key), "en")
			if not _check(not value.strip_edges().is_empty() and _signature(value) == _signature(english), "%s:%s must preserve placeholders" % [locale_id, key]):
				return
		for reward in [{"dna": 2}, {"organic": 3.0}, {"mineral": 4.0}, {"dna": 1, "organic": 2.0}, {"dna": 1, "mineral": 2.0}, {"organic": 2.0, "mineral": 3.0}, {"dna": 1, "organic": 2.0, "mineral": 3.0}]:
			if not _check(not GoalLocalization.reward_text(reward, locale_id).is_empty(), "%s reward combinations must render" % locale_id):
				return

	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false
	for locale_id in expected_locales:
		game.settings_locale = locale_id
		var definitions: Array = game._goal_definitions()
		var ids: Array[String] = []
		for goal in definitions:
			var goal_id := String(goal["id"])
			ids.append(goal_id)
			if not _check(String(goal["title"]) == GoalLocalization.text("goal_%s_title" % goal_id, locale_id) and String(goal["desc"]) == GoalLocalization.text("goal_%s_desc" % goal_id, locale_id), "%s definitions must resolve from keys" % locale_id):
				return
			if not _check(String(goal["reward_text"]) == GoalLocalization.reward_text(goal["reward"], locale_id), "%s rewards must derive from numeric reward data" % locale_id):
				return
		if not _check(ids == expected_ids, "%s must not localize or reorder IDs" % locale_id):
			return
		if not _check(not game._goal_progress_text("culture_survey").is_empty() and not game._goal_progress_text("expedition_supply").is_empty(), "%s progress text must resolve" % locale_id):
			return

	var small_panel: Rect2 = game._goals_panel_rect(Vector2(640.0, 360.0))
	if not _check(small_panel.size.x > 0.0 and small_panel.size.y > 0.0 and game._fit_font_size(GoalLocalization.text("panel_subtitle", "ru"), 80.0) >= 8, "640x360 goal layout must remain bounded and shrink long copy"):
		return
	game.settings_locale = "en"
	game.goals_claimed = {"first_hypha": true}
	game.tracked_goal_id = "sporefall_guard"
	game.save_path = "user://goal_localization_smoke.json"
	game._save_game()
	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var saved: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	if not _check(saved.get("tracked_goal_id", "") == "sporefall_guard" and bool(saved.get("goals_claimed", {}).get("first_hypha", false)) and not saved.has("goal_definitions"), "save data must contain stable IDs, never localized definitions"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("GOAL_LOCALIZATION_OK locales=7 goals=22 rewards=numeric save=stable_ids small=640x360")
	game.queue_free()
	quit(0)

func _signature(value: String) -> String:
	var matcher := RegEx.new()
	matcher.compile("%(?:0?\\d+)?(?:\\.\\d+)?[sdf]")
	var tokens: PackedStringArray = []
	for result in matcher.search_all(value): tokens.append(result.get_string())
	return "|".join(tokens)

func _check(condition: bool, message: String) -> bool:
	if condition: return true
	push_error("GOAL_LOCALIZATION_FAIL: " + message)
	quit(1)
	return false
