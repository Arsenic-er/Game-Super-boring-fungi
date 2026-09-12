extends SceneTree


# Controlled post-victory mechanism fixture, not a normal progression route.
# Only population/capacity and event states are varied; real event activation,
# save/load, offline settlement, warnings and enemy creation perform the work.
const SAVE_PATH := "user://sporefall_capacity_delay_smoke.json"
var game: Node
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		if not _check(not FileAccess.file_exists(SAVE_PATH + suffix), "test slot must be isolated and unused"):
			return
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.autosave_enabled = false
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.splash_active = false
	game.main_menu_active = false
	game.game_started = true
	game.save_path = SAVE_PATH
	game.cores.append(game._make_core(Vector2(180.0, 0.0), "barracks"))
	game.enemy_fungi.clear()
	game.enemy_hyphae.clear()
	game.enemy_guard_spores.clear()
	game.chapter_complete = true
	game.chapter_task_index = 11
	game.chapter_completed_rules_version = 2
	game.chapter_report_open = false
	game.lifetime_enemy_fungi_defeated = 1
	game.fungal_incursion = {"phase": "cooldown", "remaining": 1000.0, "pos": Vector2.INF, "wave": 0, "enemy_id": -1}
	game.ecology_events.clear()
	var initial_rewards := _reward_counters()
	if not _check(not game._ecology_blocks_fungal_incursion(), "no ecology event never blocks"):
		return
	_set_population(game.MAX_BACTERIA)
	game.ecology_events = [_bloom_warning()]
	var warning: Dictionary = game.ecology_events[0]
	if not _check(not game._activate_ecology_event(warning) and String(warning["phase"]) == "warning" and is_equal_approx(float(warning["remaining"]), 30.0) and int(warning["spawned"]) == 0, "full bloom keeps its original thirty-second capacity retry, without spawning"):
		return
	if not _check(not game._ecology_blocks_fungal_incursion(), "capacity-delayed bloom is not an active danger"):
		return
	game._update_fungal_incursion(10.0)
	if not _check(is_equal_approx(float(game.fungal_incursion["remaining"]), 990.0), "full-population warning allows the ordinary cooldown to advance"):
		return
	_set_population(game.MAX_BACTERIA - game.ECOLOGY_BLOOM_SPAWN_COUNT + 1)
	if not _check(not game._ecology_blocks_fungal_incursion(), "fifteen free slots still mean a capacity wait"):
		return
	_set_population(game.MAX_BACTERIA - game.ECOLOGY_BLOOM_SPAWN_COUNT)
	if not _check(game._ecology_blocks_fungal_incursion(), "exactly sixteen free slots restore the ecology block"):
		return
	if not _check_paused("restored capacity blocks immediately before bloom activation"):
		return
	_set_population(game.MAX_BACTERIA)
	for event_spec in [["bloom", "active"], ["toxin", "warning"], ["toxin", "active"]]:
		game.ecology_events[0]["type"] = event_spec[0]
		game.ecology_events[0]["phase"] = event_spec[1]
		if not _check(game._ecology_blocks_fungal_incursion(), "%s/%s stays an ecology block even at full population" % event_spec) or not _check_paused("actual or approaching hazard pauses the cooldown"):
			return
	game.ecology_events = [_bloom_warning()]
	game.cores[1]["kind"] = "normal"
	if not _check_paused("no living barracks still pauses despite the capacity-wait exception"):
		return
	game.cores[1]["kind"] = "barracks"
	if not _check(_reward_counters() == initial_rewards, "waiting and capacity checks do not invent event completion or rewards"):
		return

	# Existing saves have only the bloom warning, not an explicit delayed flag.
	# Round-trip the real save while omitting optional newer event fields.
	game.fungal_incursion["remaining"] = 0.25
	if not _roundtrip_old_warning("cooldown"):
		return
	var phase_before := String(game.fungal_incursion["phase"])
	var remaining_before := float(game.fungal_incursion["remaining"])
	var enemies_before: int = game.enemy_fungi.size()
	game._apply_offline_progress(120.0, 120.0)
	game._close_offline_report()
	if not _check(String(game.fungal_incursion["phase"]) == phase_before and is_equal_approx(float(game.fungal_incursion["remaining"]), remaining_before) and game.enemy_fungi.size() == enemies_before, "offline settlement does not advance or start a new incursion despite the exception"):
		return
	if not _check(_reward_counters() == initial_rewards, "offline capacity waiting cannot count a contained ecology event or defeated wave"):
		return

	_set_population(game.MAX_BACTERIA)
	game.ecology_events = [_bloom_warning()]
	var wave_balances := Vector3(game.organic, game.mineral, game.dna)
	game._update_fungal_incursion(3600.0)
	if not _check(String(game.fungal_incursion["phase"]) == "warning" and is_equal_approx(float(game.fungal_incursion["remaining"]), game.FUNGAL_INCURSION_WARNING_SECONDS) and game._living_enemy_fungus_count() == 0, "large cooldown delta starts the full warning rather than skipping directly to an enemy"):
		return
	if not _roundtrip_old_warning("warning"):
		return
	for viewport in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = viewport
		game.queue_redraw()
		await process_frame
		if not _check(not game._ecology_blocks_fungal_incursion() and game._fungal_incursion_hud_visible(), "warning HUD has the same unpaused capacity-delay predicate"):
			return
	game._update_fungal_incursion(game.FUNGAL_INCURSION_WARNING_SECONDS - 0.25)
	if not _check(String(game.fungal_incursion["phase"]) == "warning" and is_equal_approx(float(game.fungal_incursion["remaining"]), 0.25) and game._living_enemy_fungus_count() == 0, "the whole ninety-second prewarning is preserved"):
		return
	_set_population(game.MAX_BACTERIA - game.ECOLOGY_BLOOM_SPAWN_COUNT)
	if not _check_paused("capacity restored during the landing warning pauses its remaining time"):
		return
	_set_population(game.MAX_BACTERIA)
	game._update_fungal_incursion(0.5)
	if not _check(String(game.fungal_incursion["phase"]) == "active" and game._living_enemy_fungus_count() == 1, "continued capacity wait finally allows exactly one ordinary wave to land"):
		return
	var index: int = game._enemy_fungus_index_by_id(int(game.fungal_incursion["enemy_id"]))
	var enemy: Dictionary = game.enemy_fungi[index]
	if not _check(String(enemy["source"]) == "incursion" and int(enemy["wave"]) == 1 and is_equal_approx(float(enemy["max_biomass"]), 30.0) and is_equal_approx(float(enemy["attack_multiplier"]), 0.75), "the original first-wave strength remains unchanged"):
		return
	game._update_fungal_incursion(9999.0)
	if not _check(game._living_enemy_fungus_count() == 1 and _reward_counters() == initial_rewards and Vector3(game.organic, game.mineral, game.dna).is_equal_approx(wave_balances), "active-wave updates neither duplicate enemies nor invent completion rewards"):
		return
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(SAVE_PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))
	for player in game.pixel_audio.players:
		player.stop()
		player.stream = null
	game.pixel_audio.ambient_player.stop()
	game.pixel_audio.ambient_player.stream = null
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("SPOREFALL_CAPACITY_DELAY_OK checks=%d fixture=controlled boundary=405/404 warning=90 retry=30 old-save=true offline-no-new=true no-free-reward=true" % checks)
	quit(0)


func _bloom_warning() -> Dictionary:
	return {"id": 999, "type": "bloom", "phase": "warning", "pos": Vector2(-1500.0, -1500.0), "radius": game.ECOLOGY_BLOOM_RADIUS, "remaining": 30.0, "anchor_core_id": 0, "spawned": 0, "control_progress": 0.0, "controlled_by_suppressor": false}


func _set_population(count: int) -> void:
	while game.bacteria.size() > count:
		game.bacteria.pop_back()
	while game.bacteria.size() < count:
		game.bacteria.append(game._make_bacterium(Vector2(-1600.0, -1600.0)))


func _check_paused(message: String) -> bool:
	var before := float(game.fungal_incursion["remaining"])
	game._update_fungal_incursion(60.0)
	return _check(is_equal_approx(float(game.fungal_incursion["remaining"]), before), message)


func _reward_counters() -> Array:
	return [game.lifetime_ecology_events_contained, game.lifetime_suppressed_blooms_contained, game.lifetime_fungal_incursions_defeated, game.lifetime_enemy_fungi_defeated, game.goals_claimed.duplicate(true)]


func _roundtrip_old_warning(expected_incursion_phase: String) -> bool:
	game._save_game()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not _check(file != null, "real fixture save exists"):
		return false
	var saved: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	for event in saved["ecology_events"]:
		for key in ["spawned", "control_progress", "controlled_by_suppressor"]:
			event.erase(key)
	saved["saved_at"] = Time.get_unix_time_from_system()
	file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(saved))
	file = null
	if not _check(game._load_game(false), "ordinary save reader accepts the older warning representation"):
		return false
	return _check(game.bacteria.size() == game.MAX_BACTERIA and String(game._current_ecology_event().get("phase", "")) == "warning" and not game._ecology_blocks_fungal_incursion() and String(game.fungal_incursion["phase"]) == expected_incursion_phase, "loaded full-capacity warning needs no new persisted delay flag")


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if condition:
		return true
	push_error("SPOREFALL_CAPACITY_DELAY_FAIL: " + message)
	quit(1)
	return false
