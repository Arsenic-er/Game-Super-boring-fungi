extends SceneTree

# Lifecycle/transaction fixtures, not an economic-duration benchmark. The
# existing campaign_flow_smoke keeps its real paid-extension/absorption route.
const CampaignState = preload("res://scripts/campaign_state.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const SLOT := "user://campaign_scene_smoke.json"
const BAD_SLOT := "user://campaign_scene_invalid_smoke.json"
const HOME_SCENE := "res://scenes/worlds/HomeNest.tscn"
const TASK_SCENE := "res://scenes/missions/FirstSupply.tscn"
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_unblock()
	SaveStore.remove_slot(SLOT)
	SaveStore.remove_slot(BAD_SLOT)
	var game: Node = await _new_runner()
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.campaign = CampaignState.fresh()
	game._ensure_campaign_main_core()
	game._damage_core(0, 7.125, "environment_pressure")
	if not _check(game._queue_dna(0, 2) and game._save_game(), "prepare a damaged home with two prepaid jobs"):
		return
	if not _check(_scene_ok(game, "home_nest", HOME_SCENE), "Main actually hosts one HomeNest PackedScene"):
		return
	var main_id: int = game.get_instance_id()
	var audio_id: int = game.pixel_audio.get_instance_id()
	var ui_id: int = game.campaign_ui.get_instance_id()
	var home_id: int = game.active_world.get_instance_id()
	var runtime_id: int = game.world_runtime.get_instance_id()
	if not _check(game.world_runtime == game.active_world.runtime and game.rng == game.active_world.runtime.rng and game.world_runtime.data.size() == game.INITIAL_WORLD_STATE.size(), "active scene owns all world fields and simulation RNG"):
		return
	var original_resources: Array = game.resources
	game.resources = original_resources.duplicate(true)
	if not _check(is_same(game.resources, game.active_world.runtime.data["resources"]), "whole-array Main assignment updates scene runtime"):
		return
	game.active_world.runtime.data["resources"] = original_resources
	game.active_world.runtime.data["organic"] = 147.625
	if not _check(is_same(game.resources, original_resources) and game.organic == 147.625, "scene runtime rebinding and scalar writes are reflected by Main"):
		return
	if not _check(game._save_game(), "checkpoint proxied home state"):
		return
	var disk := _read_text(SLOT)
	var unused_home: Node2D = game._prepare_world_scene("home_nest")
	var unused_task: Node2D = game._prepare_world_scene("first_supply")
	if not _check(unused_home != null and unused_task != null and unused_home.scene_file_path == HOME_SCENE and unused_task.scene_file_path == TASK_SCENE and unused_home.runtime != unused_task.runtime, "both definitions instantiate different PackedScenes and runtimes"):
		return
	root.add_child(unused_home)
	root.add_child(unused_task)
	await process_frame
	if not _check(unused_home.runtime.data["resources"].is_empty() and unused_task.runtime.data["resources"].is_empty() and _read_text(SLOT) == disk, "scene _ready/frame do not independently generate maps or write saves"):
		return
	unused_home.free()
	unused_task.free()
	var home: Dictionary = game._capture_world_state()
	var ledger: Dictionary = game.campaign.duplicate(true)
	if not _check(_block() and not game._campaign_start_mission(), "real temporary-file write failure rejects departure"):
		return
	if not _check(_scene_ok(game, "home_nest", HOME_SCENE) and game.active_world.get_instance_id() == home_id and game.world_runtime.get_instance_id() == runtime_id, "failed departure retains identical home Node and runtime objects"):
		return
	if not _check(_signature(game._capture_world_state()) == _signature(home) and game.campaign == ledger and _read_text(SLOT) == disk, "failed departure changes neither world, ledger nor committed bytes"):
		return
	_unblock()
	game.campaign_ui.open = false
	if not _check(game._campaign_start_mission() and _scene_ok(game, "first_supply", TASK_SCENE), "successful departure attaches FirstSupply"):
		return
	if not _check(not is_instance_id_valid(home_id) and not is_instance_id_valid(runtime_id) and game.get_instance_id() == main_id and game.pixel_audio.get_instance_id() == audio_id and game.campaign_ui.get_instance_id() == ui_id, "success frees previous world/runtime but retains Main, audio and UI"):
		return
	if not _check(game.resources.size() == 143 and game.organic == 220.0 and game.mineral == 24.0 and game.dna == 0 and game.cores.size() == 1 and game.bacteria.is_empty() and game.enemy_fungi.is_empty(), "scene initialization preserves the independent supply-map contract"):
		return
	if not _check(game.active_world.goal_targets() == {"organic": 360.0, "mineral": 18.0, "length_world": 600.0}, "mission scene exposes original three goals"):
		return
	# Intentionally controlled readiness: this proves rules delegate to the
	# active instance, not that players reached these values economically.
	game.lifetime_organic_absorbed = 360.0
	game.lifetime_mineral_absorbed = 18.0
	for target in [Vector2(240, 0), Vector2(-240, 0), Vector2(0, 240)]:
		game.selected_core = 0
		game.selected_tip_valid = false
		game._confirm_extension(target)
	game._update_growth(24.0)
	if not _check(game._campaign_mission_ready(), "controlled lifecycle fixture meets original task goals"):
		return
	var original_progress: String = game.campaign_ui.progress_text()
	game.active_world.organic_required = 721.0
	if not _check(not game._campaign_mission_ready() and game._campaign_goal_targets()["organic"] == 721.0 and game.campaign_ui.mission_values()["organic"] == "721" and game.campaign_ui.progress_text() != original_progress and game.campaign_ui.progress_text().contains("721"), "changing active scene goal changes readiness and visible goal text"):
		return
	game.active_world.organic_required = 360.0
	if not _check(game._campaign_mission_ready() and game.campaign_ui.progress_text() == original_progress, "restoring scene goal restores readiness and HUD values"):
		return
	game.resources[0]["amount"] = 0.0
	game.resources[0]["alive"] = false
	game.resources[1]["amount"] = 2.125
	game._developer_spawn_resource(Vector2(77, 31), 1, 4.875)
	game.resources.back()["amount"] = 2.375
	game.sim_time = 42.25
	game.absorb_clock = 0.375
	game.organic = 91.375
	game.mineral = 11.125
	game.dna = 19
	if not _check(game._queue_dna(0, 1) and game._save_game(), "save task depletion, custom resource, clocks and prepaid work"):
		return
	var mission: Dictionary = game._capture_world_state()
	var payload := _read_json(SLOT)
	if not _check(payload["world_scene_id"] == "first_supply" and int(payload["world_scene_revision"]) == 1 and payload["campaign"]["home_world"]["world_scene_id"] == "home_nest", "composite save records the correct two scene identities"):
		return
	payload["saved_at"] = Time.get_unix_time_from_system() - 72.0 * 3600.0
	if not _check(_write_json(SLOT, payload), "age active task without changing archived-home timestamp"):
		return
	var task_id: int = game.active_world.get_instance_id()
	await _dispose(game)
	if not _check(not is_instance_id_valid(task_id), "disposing old Main frees its task scene"):
		return
	game = await _new_runner()
	var load_started := Time.get_ticks_msec()
	if not _check(game._load_game(true) and Time.get_ticks_msec() - load_started < 750, "fresh Main loads a task scene within unchanged 750ms threshold"):
		return
	if not _check(_scene_ok(game, "first_supply", TASK_SCENE) and _signature(game._capture_world_state()) == _signature(mission), "fresh process-equivalent runner restores exact task catalog and state"):
		return
	await process_frame
	if not _check(_signature(game._capture_world_state()) == _signature(mission) and game.resources.size() == 144 and not game.resources[0]["alive"] and not game.offline_settlement_active and not game.offline_report_open, "next frame cannot regenerate depleted resources or advance 72h task economy"):
		return
	if not _check(_signature(game.campaign["home_world"]) == _signature(home), "task load leaves archived home frozen and unpolluted"):
		return
	# Current pre-scene saves contain full catalogs but no scene metadata.
	var legacy_task := payload.duplicate(true)
	_erase_scene_metadata(legacy_task)
	_erase_scene_metadata(legacy_task["campaign"]["home_world"])
	if not _check(_write_json(SLOT, legacy_task) and game._load_game(true) and _scene_ok(game, "first_supply", TASK_SCENE) and _signature(game._capture_world_state()) == _signature(mission), "pre-scene active task migrates by campaign identity without resource reset"):
		return
	var invalid_cases: Array[Dictionary] = []
	var bad := payload.duplicate(true)
	bad["world_scene_id"] = "res://scenes/Main.tscn"
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad["world_scene_revision"] = 999
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad["world_scene_id"] = "home_nest"
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad["campaign"]["home_world"]["world_scene_id"] = "first_supply"
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad["campaign"]["home_world"]["world_scene_revision"] = 999
	invalid_cases.append(bad)
	var state_before: Dictionary = game.campaign.duplicate(true)
	task_id = game.active_world.get_instance_id()
	for index in range(invalid_cases.size()):
		if not _check(game._parse_save_payload(JSON.stringify(invalid_cases[index])).is_empty() and _write_json(BAD_SLOT, invalid_cases[index]), "invalid scene envelope %d is rejected by validator" % index):
			return
		game.save_path = BAD_SLOT
		if not _check(not game._load_game(false) and game.active_world.get_instance_id() == task_id and game.campaign == state_before and _signature(game._capture_world_state()) == _signature(mission), "invalid scene envelope %d cannot partly replace the live task" % index):
			return
	game.save_path = SLOT
	game.campaign_ui.open = false
	if not _check(game._save_game(), "checkpoint migrated active task"):
		return
	disk = _read_text(SLOT)
	state_before = game.campaign.duplicate(true)
	runtime_id = game.world_runtime.get_instance_id()
	if not _check(_block() and not game._campaign_return("victory"), "real write failure rejects ready-task victory return"):
		return
	if not _check(_scene_ok(game, "first_supply", TASK_SCENE) and game.active_world.get_instance_id() == task_id and game.world_runtime.get_instance_id() == runtime_id and game.campaign == state_before and _read_text(SLOT) == disk and _signature(game._capture_world_state()) == _signature(mission), "failed victory keeps identical task objects, depletion, ledger and disk"):
		return
	if not _check(not game._campaign_return("retreat") and game.active_world.get_instance_id() == task_id and game.campaign == state_before and _read_text(SLOT) == disk, "failed retreat also keeps the same task instead of a detached home"):
		return
	_unblock()
	if not _check(game._campaign_return("victory") and _scene_ok(game, "home_nest", HOME_SCENE) and not is_instance_id_valid(task_id), "retry victory restores a real HomeNest and destroys departed task"):
		return
	if not _check(await _finish_settlement(game), "home-only offline settlement remains bounded by 30 seconds"):
		return
	if not _check(int(game.campaign["materials"]) == 3 and not game._campaign_return("victory") and game.dna != 19 and game.resources.size() == (home["resource_catalog"] as Array).size(), "home restored with unique reward and without task stock/catalog"):
		return
	game.offline_report_open = false
	game.chapter_report_open = false
	game.campaign_ui.open = false
	if not _check(game._save_game(), "checkpoint returned home for legacy-scene migration"):
		return
	var legacy_home := _read_json(SLOT)
	_erase_scene_metadata(legacy_home)
	if not _check(_write_json(SLOT, legacy_home) and game._load_game(true) and _scene_ok(game, "home_nest", HOME_SCENE), "pre-scene inactive campaign save infers HomeNest"):
		return
	game.offline_report_open = false
	game.chapter_report_open = false
	game.campaign_ui.open = false
	for outcome in ["retreat", "failure"]:
		if not _check(game._campaign_start_mission(), "enter fresh independent task for " + outcome):
			return
		task_id = game.active_world.get_instance_id()
		if outcome == "failure":
			game._damage_core(0, 10000.0, "environment_pressure")
			game._process(0.01)
			if not _check(game.game_over, "failure fixture uses actual core damage and game-over update"):
				return
		if not _check(game._campaign_return(outcome) and _scene_ok(game, "home_nest", HOME_SCENE) and not is_instance_id_valid(task_id), outcome + " restores HomeNest and destroys only the task world"):
			return
		if not _check(await _finish_settlement(game), outcome + " settlement remains bounded"):
			return
		game.offline_report_open = false
		game.chapter_report_open = false
		game.campaign_ui.open = false
		if not _check(int(game.campaign["materials"]) == 3 and not game.game_over, outcome + " grants no duplicate reward and does not kill archived home"):
			return
	var bytes_before_restore := _read_text(SLOT)
	var restored_home: Dictionary = game._capture_world_state()
	home_id = game.active_world.get_instance_id()
	if not _check(game._restore_world_state(restored_home) and _scene_ok(game, "home_nest", HOME_SCENE) and not is_instance_id_valid(home_id) and _signature(game._capture_world_state()) == _signature(restored_home), "pure restore uses a fresh matching HomeNest without changing world data"):
		return
	await process_frame
	if not _check(_read_text(SLOT) == bytes_before_restore and not game.offline_settlement_active and not game.offline_report_open and _signature(game._capture_world_state()) == _signature(restored_home), "pure scene restore remains IO-free, offline-free and stable after a frame"):
		return
	print("CAMPAIGN_SCENE_OK checks=%d PackedScene=home+task runtime=owned proxies=array+scalar goals=active-scene load=depletion-preserved legacy=home+task rollback=same-instance returns=victory+retreat+failure" % checks)
	SaveStore.remove_slot(SLOT)
	SaveStore.remove_slot(BAD_SLOT)
	await _dispose(game)
	quit(0)

func _new_runner() -> Node:
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.splash_active = false
	game.autosave_enabled = false
	game.save_path = SLOT
	game.main_menu_active = false
	game.game_started = true
	return game

func _scene_ok(game: Node, id: String, path: String) -> bool:
	return is_instance_valid(game.active_world) and is_instance_valid(game.world_host) and game.world_host.get_child_count() == 1 and game.world_host.get_child(0) == game.active_world and game.active_world.get_parent() == game.world_host and game._world_scene_id() == id and game.active_world.scene_file_path == path and game.world_runtime == game.active_world.runtime and game.world_host.process_mode == Node.PROCESS_MODE_DISABLED

func _finish_settlement(game: Node) -> bool:
	var started := Time.get_ticks_msec()
	var frames := 0
	while game.offline_settlement_active and Time.get_ticks_msec() - started < 30000 and frames < 2400:
		game._pump_offline_progress()
		frames += 1
		await process_frame
	return not game.offline_settlement_active and Time.get_ticks_msec() - started < 30000 and frames < 2400

func _signature(world: Dictionary) -> Dictionary:
	var value := world.duplicate(true)
	value.erase("saved_at")
	value.erase("campaign")
	return JSON.parse_string(JSON.stringify(value)) as Dictionary

func _erase_scene_metadata(payload: Dictionary) -> void:
	payload.erase("world_scene_id")
	payload.erase("world_scene_revision")

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
	var value := file.get_as_text()
	file.close()
	return value

func _read_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(_read_text(path))
	return parsed if parsed is Dictionary else {}

func _write_json(path: String, payload: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var written := file.store_string(JSON.stringify(payload))
	file.close()
	return written

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
	push_error("CAMPAIGN_SCENE_FAIL: " + message)
	_unblock()
	SaveStore.remove_slot(SLOT)
	SaveStore.remove_slot(BAD_SLOT)
	quit(1)
	return false
