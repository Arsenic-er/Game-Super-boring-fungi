extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
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
	game.save_path = "user://goal_tracker_smoke.json"

	if not _check(game.tracked_goal_id == "first_hypha" and game._goal_definitions().size() == 22, "new cultures should track the first of 22 goals"):
		return
	var source_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	var main_source := source_file.get_as_text()
	source_file = null
	if not _check(not main_source.contains("???"), "goal tracker source must not contain encoding-loss question runs"):
		return
	for goal in game._goal_definitions():
		if not _check(not String(goal["title"]).contains("?") and not String(goal["desc"]).contains("?") and not String(goal["reward_text"]).contains("?"), "goal copy must remain valid UTF-8"):
			return

	for viewport in [Vector2(1280.0, 720.0), Vector2(800.0, 600.0)]:
		var tracker: Rect2 = game._goal_tracker_hud_rect(viewport)
		var synthetic_minimap := Rect2(viewport.x - 230.0, 18.0, 208.0, 176.0)
		if not _check(tracker.position.x >= 150.0 and tracker.end.x <= synthetic_minimap.position.x - 12.0 and tracker.position.y == 116.0 and tracker.end.y <= 148.0, "tracker should stay between the goals button, minimap, and status panel"):
			return

	var panel: Rect2 = game._goals_panel_rect(game.get_viewport_rect().size)
	for row in range(game.GOALS_PER_PAGE):
		if not _check(not game._goal_track_button_rect(panel, row).intersects(game._goal_button_rect(panel, row)), "track and claim hitboxes must remain separate"):
			return

	game.goals_open = true
	game.goal_page = 4
	var organic_before: float = game.organic
	var mineral_before: float = game.mineral
	var dna_before: int = game.dna
	game._handle_goals_click(game._goal_track_button_rect(panel, 1).get_center())
	if not _check(game.tracked_goal_id == "sporefall_guard" and is_equal_approx(game.organic, organic_before) and is_equal_approx(game.mineral, mineral_before) and game.dna == dna_before and not bool(game.goals_claimed.get("sporefall_guard", false)), "tracking a goal must not claim it or change resources"):
		return
	var ghost_hover: String = game._audio_hover_target_at(game._goal_track_button_rect(panel, 4).get_center())
	if not _check(ghost_hover == "", "empty rows on the last goals page must not emit hover targets"):
		return

	game.goals_open = false
	game.goal_page = 0
	game._handle_left_click(game._goal_tracker_hud_rect(game.get_viewport_rect().size).get_center())
	if not _check(game.goals_open and game.goal_page == 4, "clicking the HUD tracker should open the tracked goal page"):
		return
	game._handle_goals_click(game._goal_track_button_rect(panel, 1).get_center())
	if not _check(game.tracked_goal_id == "", "the explicit cancel button should clear tracking"):
		return
	game._save_game()
	if not _check(game._load_game() and game.tracked_goal_id == "", "an explicitly empty tracker should survive a save round-trip"):
		return

	game.lifetime_expedition_organic_returned = 10.0
	game.lifetime_expedition_mineral_returned = 0.25
	if not _check(is_equal_approx(game._goal_progress_fraction("expedition_supply"), 0.5), "multi-resource progress should use the limiting requirement"):
		return
	game.lifetime_expedition_organic_returned = 100.0
	game.lifetime_expedition_mineral_returned = 5.0
	game.lifetime_mineral_absorbed = 100.0
	if not _check(is_equal_approx(game._goal_progress_fraction("expedition_supply"), 1.0) and is_equal_approx(game._goal_progress_fraction("mineral_trace"), 1.0), "goal progress fractions should clamp at one"):
		return

	game.lifetime_bacteria_births = 25
	game.tracked_goal_id = "sporefall_guard"
	var nontracked_dna: int = game.dna
	game._claim_goal("bacterial_bloom")
	if not _check(game.tracked_goal_id == "sporefall_guard" and bool(game.goals_claimed.get("bacterial_bloom", false)) and game.dna == nontracked_dna, "claiming a non-tracked mineral goal should not change the tracker"):
		return

	game.barracks_directive_ever_set = false
	game.goals_claimed.erase("barracks_directive")
	game._set_tracked_goal("barracks_directive")
	game.toast_time = 0.0
	game.goals_open = false
	game.upgrade_open = false
	game.offline_simulating = false
	game.offline_report_open = false
	game._update_tracked_goal_notification()
	if not _check(not game.tracked_goal_completion_notified, "incomplete goals should not raise completion notifications"):
		return
	game.barracks_directive_ever_set = true
	game._update_tracked_goal_notification()
	if not _check(game.tracked_goal_completion_notified and not bool(game.goals_claimed.get("barracks_directive", false)), "completion should notify once without auto-claiming"):
		return
	var reward_dna: int = game.dna
	var reward_mineral: float = game.mineral
	game._claim_goal("barracks_directive")
	var recommended_after_claim: String = game.tracked_goal_id
	if not _check(game.dna == reward_dna + 2 and is_equal_approx(game.mineral, reward_mineral + 1.0) and recommended_after_claim != "" and not bool(game.goals_claimed.get(recommended_after_claim, false)), "claim should award once and recommend an unclaimed next goal"):
		return
	game._claim_goal("barracks_directive")
	if not _check(game.dna == reward_dna + 2 and is_equal_approx(game.mineral, reward_mineral + 1.0), "a claimed goal must never award twice"):
		return

	game.tracked_goal_id = "sporefall_guard"
	game.tracked_goal_completion_notified = false
	game._save_game()
	if not _check(game._load_game() and game.tracked_goal_id == "sporefall_guard", "a valid tracked goal should survive a save round-trip"):
		return

	var save_data := _read_save(game.save_path)
	save_data.erase("tracked_goal_id")
	save_data.erase("tracked_goal_completion_notified")
	_write_save(game.save_path, save_data)
	if not _check(game._load_game() and game.tracked_goal_id != "" and game._goal_index(game.tracked_goal_id) >= 0, "v0.36 saves should receive a valid recommended goal"):
		return

	save_data = _read_save(game.save_path)
	save_data["tracked_goal_id"] = "future_removed_goal"
	save_data["tracked_goal_completion_notified"] = false
	_write_save(game.save_path, save_data)
	if not _check(game._load_game() and game.tracked_goal_id != "future_removed_goal" and game._goal_index(game.tracked_goal_id) >= 0, "unknown tracked IDs should normalize to a valid recommendation"):
		return

	game.lifetime_fungal_incursions_defeated = 0
	game.tracked_goal_id = "sporefall_guard"
	game.tracked_goal_completion_notified = false
	game._save_game()
	save_data = _read_save(game.save_path)
	save_data["tracked_goal_completion_notified"] = true
	_write_save(game.save_path, save_data)
	if not _check(game._load_game() and game.tracked_goal_id == "sporefall_guard" and not game.tracked_goal_completion_notified, "an incomplete loaded goal must not inherit a stale completion notification"):
		return

	game.goals_claimed = {}
	for goal in game._goal_definitions():
		game.goals_claimed[String(goal["id"])] = true
	if not _check(game._all_goals_claimed() and game._recommended_goal_id() == "", "all claimed goals should produce the completed empty state"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("GOAL_TRACKER_OK hud=responsive tracking=isolated claim=once recommendation=valid save=migrated utf8=clean")
	game.queue_free()
	quit(0)


func _read_save(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	return parsed


func _write_save(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file = null


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("GOAL_TRACKER_FAIL: " + message)
	quit(1)
	return false
