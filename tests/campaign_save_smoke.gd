extends SceneTree

const CampaignState = preload("res://scripts/campaign_state.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const SLOT := "user://campaign_save_smoke.json"
const BAD_SLOT := "user://campaign_save_invalid_smoke.json"
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	SaveStore.remove_slot(SLOT)
	SaveStore.remove_slot(BAD_SLOT)
	_unblock()
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.splash_active = false
	game.autosave_enabled = false
	game.save_path = SLOT
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.campaign = CampaignState.fresh()
	game.main_menu_active = false
	game.game_started = true
	game._damage_core(0, 12.375, "environment_pressure")
	if not _check(game._queue_dna(0, 2) and game._save_game(), "prepare ordinary home with actual damage and prepaid DNA"):
		return
	var legacy := _read_json(SLOT)
	legacy.erase("campaign")
	legacy.erase("resource_catalog")
	legacy.erase("hotspot_catalog")
	legacy.erase("rng_seed")
	legacy.erase("rng_state")
	legacy.erase("simulation_clocks")
	legacy["chapter_complete"] = true
	legacy["core_selected_once"] = true
	legacy["chapter_completed_at"] = 50.0
	legacy["chapter_completed_rules_version"] = 1
	legacy["chapter_rules_version"] = 1
	legacy["goals_claimed"] = {"first_hypha": true}
	if not _check(_write_json(SLOT, legacy), "write genuine legacy-shaped world without any campaign fields"):
		return
	game._start_new_culture()
	if not _check(game._load_game(false) and not game._campaign_active() and int(game.campaign["nest_level"]) == 1 and int(game.campaign["materials"]) == 0, "legacy save gains an empty level-one campaign, not free materials or a task result"):
		return
	if not _check(game.chapter_complete and int(game.chapter_completed_rules_version) == 1 and bool(game.goals_claimed.get("first_hypha", false)), "legacy chapter completion and already-claimed goal remain earned"):
		return
	if not _check(is_equal_approx(game.organic, float(legacy["organic"])) and is_equal_approx(game.mineral, float(legacy["mineral"])) and game.dna == int(legacy["dna"]) and is_equal_approx(float(game.cores[0]["biomass"]), 87.625) and game.cores[0]["jobs"].size() == 2, "legacy migration preserves costs, damage and queued work"):
		return
	game.chapter_report_open = false
	game.offline_report_open = false
	game._developer_spawn_resource(Vector2(41.0, -63.0), 0, 17.625)
	game.resources.back()["amount"] = 9.125
	game.sim_time = 137.25
	game.absorb_clock = 0.375
	game.bacteria_update_clock = 0.125
	game.expedition_update_clock = 0.0625
	game.barracks_auto_clock = 0.25
	game.enemy_fungus_update_clock = 0.125
	game.enemy_guard_update_clock = 0.0625
	if not _check(game._save_game(), "write full home catalog before capture/restore check"):
		return
	var before_restore_bytes := _read_text(SLOT)
	var home: Dictionary = game._capture_world_state()
	if not _check(home.get("rng_seed", null) is String and home.get("rng_state", null) is String and home.get("simulation_clocks", null) is Dictionary, "snapshot exposes lossless random state and substep clocks"):
		return
	game.organic = 9999.0
	game.resources.clear()
	game.rng.seed = 123
	if not _check(game._restore_world_state(home) and _same_world(game._capture_world_state(), home), "pure restore recovers full custom resource catalog, queues, timing and RNG"):
		return
	if not _check(_read_text(SLOT) == before_restore_bytes and not game.offline_settlement_active and not game.offline_report_open, "pure restore neither writes disk nor starts offline settlement"):
		return
	game.campaign_ui.open = false
	if not _check(game._campaign_start_mission(), "mission departure commits a composite save"):
		return
	var departure: float = game.campaign["home_world"]["saved_at"]
	game.organic = 91.375
	game.mineral = 11.125
	game.dna = 19
	game.sim_time = 42.25
	game.selected_core = 0
	game.selected_tip_valid = false
	game._confirm_extension(Vector2(120, 0))
	game._update_growth(3.0)
	game._developer_spawn_resource(Vector2(77, 31), 1, 4.875)
	game.resources.back()["amount"] = 2.375
	if not _check(game._queue_dna(0, 1) and game._save_game(), "mission-in-progress saves its own partial construction, custom resource and prepaid job"):
		return
	var task_world: Dictionary = game._capture_world_state()
	var payload := _read_json(SLOT)
	if not _check(payload.has("campaign") and not payload["campaign"]["home_world"].has("campaign") and is_equal_approx(float(payload["campaign"]["home_world"]["saved_at"]), departure), "composite payload has one nonrecursive home snapshot with original departure timestamp"):
		return
	payload["saved_at"] = Time.get_unix_time_from_system() - 72.0 * 3600.0
	payload["campaign"]["home_world"]["saved_at"] = payload["saved_at"]
	if not _check(_write_json(SLOT, payload), "age both stored worlds by 72h for task resume test"):
		return
	game.organic = 1.0
	game.resources.clear()
	var load_started := Time.get_ticks_msec()
	if not _check(game._load_game(true), "72h-old task save reloads"):
		return
	if not _check(Time.get_ticks_msec() - load_started < 750 and game._campaign_active() and not game.offline_settlement_active and not game.offline_report_open, "task reload returns promptly and never runs offline combat/economy"):
		return
	if not _check(_same_world(game._capture_world_state(), task_world) and int(game.campaign["materials"]) == 0, "task state, DNA and resource depletion do not advance during offline absence"):
		return
	if not _check(_signature(game.campaign["home_world"]) == _signature(home), "resuming task does not settle or mutate the home snapshot"):
		return
	# A foreign nested profile must be rejected before it can enter this slot.
	var bad := payload.duplicate(true)
	bad["campaign"]["home_world"]["developer_session"] = true
	var before_bad: Dictionary = game._capture_world_state()
	var campaign_before_bad: Dictionary = game.campaign.duplicate(true)
	if not _check(game._parse_save_payload(JSON.stringify(bad)).is_empty() and _write_json(BAD_SLOT, bad), "normal validator rejects a developer home nested in a normal task"):
		return
	game.save_path = BAD_SLOT
	if not _check(not game._load_game(false) and _signature(game._capture_world_state()) == _signature(before_bad) and game.campaign == campaign_before_bad, "invalid nested profile cannot partially replace active task or home"):
		return
	game.save_path = SLOT
	# Finishing the task now settles the home's elapsed time exactly once, capped
	# at the unchanged 48h policy. The mission's 19 DNA is never transferred.
	game.campaign_ui.open = false
	if not _check(game._campaign_return("retreat") and not game._campaign_active(), "retreat restores old home and schedules its own offline settlement"):
		return
	var settlement_started := Time.get_ticks_msec()
	var frames := 0
	while game.offline_settlement_active and Time.get_ticks_msec() - settlement_started < 30000 and frames < 2400:
		game._pump_offline_progress()
		frames += 1
		await process_frame
	var settlement_elapsed := Time.get_ticks_msec() - settlement_started
	if not _check(not game.offline_settlement_active and game.offline_report_open and frames < 2400 and Time.get_ticks_msec() - settlement_started < 30000, "home settlement remains deferred and bounded by existing limits"):
		return
	if not _check(is_equal_approx(float(game.offline_report.get("settled_seconds", -1.0)), 48.0 * 3600.0) and bool(game.offline_report.get("capped", false)), "home report settles at most 48h from the original departure timestamp"):
		return
	if not _check(game.dna == int(home["dna"]) + 2 and (game.cores[0]["jobs"] as Array).is_empty() and int(game.campaign["materials"]) == 0, "only home's two prepaid jobs complete; task DNA and retreat materials do not transfer"):
		return
	var settled: Dictionary = game._capture_world_state()
	game.offline_report_open = false
	if not _check(game._load_game(true) and not game.offline_settlement_active and _same_world(game._capture_world_state(), settled), "immediate reload cannot repeat the home's offline settlement"):
		return
	game.offline_report_open = false
	game.chapter_report_open = false
	game.campaign_ui.open = false
	# The real SaveStore path is obstructed at its temporary-file location. This
	# exercises production commit failure without monkey-patching persistence.
	if not _check(game._save_game(), "checkpoint home before failed departure"):
		return
	var committed := _read_text(SLOT)
	var world_before: Dictionary = game._capture_world_state()
	var state_before: Dictionary = game.campaign.duplicate(true)
	if not _check(_block() and not game._campaign_start_mission(), "failed departure commit is reported"):
		return
	if not _check(_read_text(SLOT) == committed and _signature(game._capture_world_state()) == _signature(world_before) and game.campaign == state_before, "failed departure preserves prior disk bytes and both live states"):
		return
	_unblock()
	if not _check(game._campaign_start_mission(), "departure succeeds again after removing IO obstruction"):
		return
	game.lifetime_organic_absorbed = 360.0
	game.lifetime_mineral_absorbed = 18.0
	for target in [Vector2(240, 0), Vector2(-240, 0), Vector2(0, 240)]:
		game.selected_core = 0
		game.selected_tip_valid = false
		game._confirm_extension(target)
	game._update_growth(24.0)
	if not _check(game._campaign_mission_ready() and game._save_game(), "controlled ready fixture checkpoints before failed victory"):
		return
	committed = _read_text(SLOT)
	world_before = game._capture_world_state()
	state_before = game.campaign.duplicate(true)
	if not _check(_block() and not game._campaign_return("victory"), "failed reward/return commit is reported"):
		return
	if not _check(game._campaign_active() and _read_text(SLOT) == committed and _signature(game._capture_world_state()) == _signature(world_before) and game.campaign == state_before, "failed victory neither consumes the task nor grants materials"):
		return
	_unblock()
	if not _check(game._campaign_return("victory") and int(game.campaign["materials"]) == 3, "retry after IO failure awards the unique reward once"):
		return
	game.campaign_ui.open = false
	game.offline_report_open = false
	committed = _read_text(SLOT)
	world_before = game._capture_world_state()
	state_before = game.campaign.duplicate(true)
	if not _check(_block() and not game._campaign_upgrade(), "failed upgrade commit is reported"):
		return
	if not _check(_read_text(SLOT) == committed and _signature(game._capture_world_state()) == _signature(world_before) and game.campaign == state_before, "failed upgrade does not spend materials, DNA or home stock"):
		return
	_unblock()
	if not _check(game._campaign_upgrade() and game._load_game(true) and int(game.campaign["nest_level"]) == 2 and int(game.campaign["materials"]) == 0 and bool(game.campaign["completed"].get("first_supply", false)), "successful upgrade and reward ledger survive reload"):
		return
	print("CAMPAIGN_SAVE_OK checks=%d legacy=true catalog+RNG+clocks=preserved task_offline=frozen home_offline=48h-once nested_profile=rejected failed_commits=start+return+upgrade settlement_ms=%d frames=%d" % [checks, settlement_elapsed, frames])
	SaveStore.remove_slot(SLOT)
	SaveStore.remove_slot(BAD_SLOT)
	await _dispose(game)
	quit(0)

func _signature(world: Dictionary) -> Dictionary:
	var result := world.duplicate(true)
	result.erase("saved_at")
	result.erase("campaign")
	# Compare every world field at the same JSON precision used by SaveStore.
	# This preserves the exact persistence contract, including string RNG state.
	return JSON.parse_string(JSON.stringify(result)) as Dictionary

func _same_world(actual: Dictionary, expected: Dictionary) -> bool:
	var left := _signature(actual)
	var right := _signature(expected)
	if left == right:
		return true
	for key in right:
		if not left.has(key) or left[key] != right[key]:
			print("CAMPAIGN_WORLD_DIFF key=%s actual=%s expected=%s" % [key, JSON.stringify(left.get(key)).left(1600), JSON.stringify(right[key]).left(1600)])
	for key in left:
		if not right.has(key):
			print("CAMPAIGN_WORLD_DIFF unexpected=%s" % key)
	return false

func _block() -> bool:
	var path := ProjectSettings.globalize_path(SaveStore.temp_path(SLOT))
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.make_dir_absolute(path) == OK

func _unblock() -> void:
	var path := ProjectSettings.globalize_path(SaveStore.temp_path(SLOT))
	if DirAccess.dir_exists_absolute(path):
		DirAccess.remove_absolute(path)

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text

func _read_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(_read_text(path))
	return parsed if parsed is Dictionary else {}

func _write_json(path: String, payload: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var stored := file.store_string(JSON.stringify(payload))
	file.close()
	return stored

func _dispose(game: Node) -> void:
	for player in game.pixel_audio.players:
		player.stop()
		player.stream = null
	game.pixel_audio.ambient_player.stop()
	game.pixel_audio.ambient_player.stream = null
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout

func _check(condition: bool, message: String) -> bool:
	checks += 1
	if condition:
		return true
	push_error("CAMPAIGN_SAVE_FAIL: " + message)
	_unblock()
	SaveStore.remove_slot(SLOT)
	SaveStore.remove_slot(BAD_SLOT)
	quit(1)
	return false
