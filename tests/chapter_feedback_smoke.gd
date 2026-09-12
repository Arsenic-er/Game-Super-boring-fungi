extends SceneTree

const GameplayLocalization = preload("res://scripts/gameplay_localization.gd")
const ChapterLocalization = preload("res://scripts/chapter_localization.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.set_process(false)
	game.developer_mode_enabled = false
	game.autosave_enabled = false
	game.splash_active = false
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.main_menu_active = false
	game.game_started = true
	game.save_path = "user://chapter_feedback_smoke.json"
	for locale_id in GameplayLocalization.LOCALES:
		game.settings_locale = locale_id
		for key in ["stat_dna_idle", "toast_dna_ready", "toast_dna_queue_finished_fmt"]:
			if not _check((GameplayLocalization.TEXTS[locale_id] as Dictionary).has(key) and not game._gt(key).strip_edges().is_empty(), "explicit localized DNA feedback: %s/%s" % [locale_id, key]):
				return
		if not _check((ChapterLocalization.CHROME[locale_id] as Dictionary).has("review_report") and ChapterLocalization.text("report_continuation_notice", locale_id) != "report_continuation_notice", "report instructions in %s" % locale_id):
			return
		var jobs: Array = game.cores[0]["jobs"]
		jobs.clear()
		game.organic = 220.0
		game.mineral = 24.0
		var dna_before: int = game.dna
		if not _check(game._dna_queue_status_text(0) == game._gt("stat_dna_idle") and game._queue_dna(0, 2), "idle status and normally funded batch"):
			return
		var prepaid := Vector2(game.organic, game.mineral)
		if not _check(game._dna_queue_status_text(0) == game._gt("stat_dna_queue_fmt") % 2, "active status retains queue count"):
			return
		game._update_dna_jobs(game._dna_job_duration(0))
		if not _check(jobs.size() == 1 and game.toast_text == game._gt("toast_dna_ready"), "intermediate job is not falsely announced as a finished queue"):
			return
		game._update_dna_jobs(game._dna_job_duration(0))
		if not _check(jobs.is_empty() and game.dna == dna_before + 2 and game.toast_text == game._gt("toast_dna_queue_finished_fmt") % 1, "last job gives a localized core-specific next action"):
			return
		game.toast_text = "no repeated idle toast"
		game._update_dna_jobs(600.0)
		if not _check(game.toast_text == "no repeated idle toast" and game.dna == dna_before + 2 and Vector2(game.organic, game.mineral) == prepaid, "empty queues neither spam nor restart or spend nutrients"):
			return
		if not _check(game._queue_dna(0, 1), "fund offline queue normally"):
			return
		game.offline_simulating = true
		game.toast_text = "offline report owns feedback"
		game._update_dna_jobs(game._dna_job_duration(0))
		game.offline_simulating = false
		if not _check(game.dna == dna_before + 3 and game.toast_text == "offline report owns feedback", "offline completion updates economy without per-job popup noise"):
			return
		jobs.append(0.0)
		game._update_dna_jobs(0.01)
		if not _check(jobs.is_empty() and game.dna == dna_before + 4 and game.toast_text == game._gt("toast_dna_queue_finished_fmt") % 1, "legacy zero-duration head uses the same completion feedback"):
			return

	game.chapter_complete = true
	game.chapter_report_seen = true
	game.chapter_task_index = game._chapter_tasks().size()
	game.chapter_completed_at = 1234.5
	for collapsed in [false, true]:
		game.guidance_collapsed = collapsed
		for viewport in [Vector2i(1280, 720), Vector2i(640, 360)]:
			root.size = viewport
			await process_frame
			game.chapter_report_open = false
			var balance_before := Vector3(game.organic, game.mineral, game.dna)
			var rect: Rect2 = game._chapter_guidance_rect()
			if not _check(game._handle_chapter_guidance_click(rect.get_center()) and game.chapter_report_open and game.chapter_report_seen, "completed chapter card reopens the report at either layout size"):
				return
			if not _check(Vector3(game.organic, game.mineral, game.dna) == balance_before and is_equal_approx(game.chapter_completed_at, 1234.5), "reviewing the report does not pay rewards or reset completion time"):
				return
			game._close_chapter_report(false)
			if not _check(not game.chapter_report_open and game.chapter_report_seen and game.game_started and not game.main_menu_active, "report can close back into cultivation repeatedly"):
				return
	game.chapter_complete = false
	game.chapter_task_index = 0
	game.chapter_report_open = false
	game._handle_chapter_guidance_click(game._chapter_guidance_rect().get_center())
	if not _check(not game.chapter_report_open, "unfinished chapters cannot open a completion report"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	for player in game.pixel_audio.players:
		player.stop()
		player.stream = null
	game.pixel_audio.ambient_player.stop()
	game.pixel_audio.ambient_player.stream = null
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("CHAPTER_FEEDBACK_OK locales=7 dna=idle+queue-end+no-spam+offline-safe report=reopen+continue layouts=1280+640")
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CHAPTER_FEEDBACK_FAIL: " + message)
	quit(1)
	return false
