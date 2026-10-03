extends SceneTree

# Explicit integrity/transaction fixtures. Unlocks and death frames below are
# synthetic and do not measure normal-resource gameplay or completion time.
const State = preload("res://scripts/campaign_state.gd")
const Catalog = preload("res://scripts/campaign_mission_catalog.gd")
const WorldCatalog = preload("res://scripts/worlds/world_scene_catalog.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const SLOT := "user://campaign_snapshot_integrity_smoke.json"
const MISSIONS := ["first_contact", "two_fronts", "stable_colony", "lost_network", "boundary_counterattack"]
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveStore.remove_slot(SLOT)
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.splash_active = false
	game.autosave_enabled = false
	game.developer_mode_enabled = false
	game.save_path = SLOT
	game.game_started = true
	for mission_id in MISSIONS:
		if not _exercise(game, mission_id):
			SaveStore.remove_slot(SLOT)
			game.queue_free()
			await process_frame
			quit(1)
			return
	SaveStore.remove_slot(SLOT)
	game.queue_free()
	await process_frame
	print("CAMPAIGN_SNAPSHOT_INTEGRITY_OK checks=%d scenes=5 missing_entities=rejected valid_dead_entities=accepted backup=recovered total_corruption=memory_unchanged" % checks)
	quit(0)


func _exercise(game: Node, mission_id: String) -> bool:
	SaveStore.remove_slot(SLOT)
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.campaign = State.fresh()
	game.campaign["nest_level"] = 4
	for entry in Catalog.entries():
		game.campaign["completed"][entry["id"]] = true
	game.main_menu_active = false
	game.pause_menu_open = false
	game.offline_report_open = false
	game.chapter_report_open = false
	game.campaign_ui.open = false
	if not _check(game._campaign_start_mission(mission_id), mission_id + " enters its actual independent scene through the real controller"):
		return false
	var is_trial := mission_id in ["first_contact", "two_fronts", "stable_colony"]
	if is_trial and not _check(game.active_world.mission_action(game), mission_id + " creates a real active enemy wave"):
		return false
	if not _check(game._save_game() and game._save_game(), mission_id + " commits complete primary and backup generations"):
		return false
	var good: Dictionary = _read_json(SLOT)
	var canonical: Dictionary = good.duplicate(true)
	if not _check(not game._parse_save_payload(JSON.stringify(good)).is_empty() and WorldCatalog.valid_mission_snapshot(good, mission_id) and good == canonical, mission_id + " validates complete JSON state without mutating it"):
		return false

	var dead: Dictionary = good.duplicate(true)
	if is_trial:
		# Failure can be captured before mission_tick prunes a freshly dead guard.
		dead["game_over"] = true
		dead["enemy_guard_spores"][0]["alive"] = false
		dead["enemy_guard_spores"][0]["biomass"] = 0.0
	elif mission_id == "lost_network":
		dead["game_over"] = true
		dead["cores"][3]["alive"] = false
		dead["cores"][3]["biomass"] = 0.0
	else:
		dead["enemy_fungi"][0]["alive"] = false
		dead["enemy_fungi"][0]["biomass"] = 0.0
	if not _check(not game._parse_save_payload(JSON.stringify(dead)).is_empty(), mission_id + " accepts an existing defeated target in a legitimate failure or victory frame"):
		return false
	if not _check(_write_json(SLOT, dead) and game._load_game(true), mission_id + " loads the legitimate defeated-target frame"):
		return false
	var target_still_dead := false
	if is_trial:
		var guard_id: int = int(dead["enemy_guard_spores"][0]["id"])
		var index: int = game._enemy_guard_index_by_id(guard_id)
		target_still_dead = index >= 0 and not bool(game.enemy_guard_spores[index]["alive"]) and float(game.enemy_guard_spores[index]["biomass"]) <= 0.0005 and game.game_over
	elif mission_id == "lost_network":
		target_still_dead = game.cores.size() > 3 and not game._is_core_alive(3) and game.game_over
	else:
		var index: int = game._enemy_fungus_index_by_id(int(dead["mission_state"]["target_enemy_id"]))
		target_still_dead = index >= 0 and not bool(game.enemy_fungi[index]["alive"]) and float(game.enemy_fungi[index]["biomass"]) <= 0.0005
	if not _check(target_still_dead and game._save_game(), mission_id + " preserves the defeated target without revival and can save it again"):
		return false
	if not _check(not game._parse_save_payload(JSON.stringify(_read_json(SLOT))).is_empty() and game._load_game(true), mission_id + " defeated-target checkpoint survives another parser/load cycle"):
		return false
	if not _check(_write_json(SLOT, good) and game._load_game(true) and game._save_game() and game._save_game(), mission_id + " restores complete living generations for independent corruption probes"):
		return false
	var bad: Dictionary = good.duplicate(true)
	if is_trial:
		bad["enemy_guard_spores"].remove_at(0)
	elif mission_id == "lost_network":
		bad["cores"].resize(3)
	else:
		bad["enemy_fungi"].clear()
	if not _check(game._valid_saved_world(bad) and game.active_world.validate_mission_state(bad["mission_state"]), mission_id + " missing target fixture remains generically valid and exposes cross-record integrity only"):
		return false
	if not _check(not WorldCatalog.valid_mission_snapshot(bad, mission_id) and game._parse_save_payload(JSON.stringify(bad)).is_empty(), mission_id + " rejects the missing mission target before any restore"):
		return false
	if is_trial or mission_id == "boundary_counterattack":
		var wrong_id: Dictionary = good.duplicate(true)
		var field := "enemy_guard_spores" if is_trial else "enemy_fungi"
		wrong_id[field][0]["id"] = 123456789
		if not _check(game._parse_save_payload(JSON.stringify(wrong_id)).is_empty(), mission_id + " unrelated entity cannot substitute for the referenced target ID"):
			return false
		if not _check(game.active_world.SNAPSHOT_WORLD_HALF == game.WORLD_HALF and game.active_world.SNAPSHOT_MAX_GUARDS == game.MAX_ENEMY_GUARD_SPORES, mission_id + " snapshot limits remain pinned to Main restore constants without cyclic preload"):
			return false
		var outside: Dictionary = good.duplicate(true)
		outside[field][0]["x"] = 12000.0
		outside[field][0]["y"] = 12000.0
		if not _check(game._valid_saved_world(outside) and game._parse_save_payload(JSON.stringify(outside)).is_empty(), mission_id + " rejects a referenced point inside the coordinate square but outside the actual restore circle"):
			return false
		var truncated: Dictionary = good.duplicate(true)
		var referenced: Dictionary = truncated[field].pop_front()
		var cap: int = game.MAX_ENEMY_GUARD_SPORES if is_trial else 3
		while truncated[field].size() < cap:
			var filler := referenced.duplicate(true)
			filler["id"] = 100000 + truncated[field].size()
			truncated[field].append(filler)
		truncated[field].append(referenced)
		if not _check(game._valid_saved_world(truncated) and game._parse_save_payload(JSON.stringify(truncated)).is_empty(), mission_id + " rejects a referenced entity beyond the restore quantity cap"):
			return false
	if not _check(_write_json(SLOT, bad), mission_id + " writes malformed primary only into the isolated test slot"):
		return false
	var inspected := SaveStore.inspect(SLOT, Callable(game, "_parse_save_payload"))
	if not _check(inspected.get("path", "") == SaveStore.backup_path(SLOT), mission_id + " selects the complete backup rather than damaged primary"):
		return false
	game.organic = 1.125
	var expected_world := _signature(good)
	var expected_campaign: Dictionary = good["campaign"].duplicate(true)
	if not _check(game._load_game(true), mission_id + " real loader recovers a complete backup"):
		return false
	if not _check(game._world_scene_id() == mission_id and _signature(game._capture_world_state()) == expected_world and JSON.parse_string(JSON.stringify(game.campaign)) == expected_campaign, mission_id + " recovery preserves mission state, entities, archived home and reward ledger"):
		return false
	if not _check(not game._parse_save_payload(JSON.stringify(_read_json(SLOT))).is_empty(), mission_id + " recovery repairs primary with a complete snapshot"):
		return false

	# When every generation is incomplete, no part of the running scene or
	# campaign may be applied, reset, respawned, charged or awarded.
	if not _check(_write_json(SLOT, bad) and _write_json(SaveStore.backup_path(SLOT), bad) and _write_json(SaveStore.temp_path(SLOT), bad), mission_id + " damages all isolated generations for atomic refusal"):
		return false
	var before: Dictionary = _signature(game._capture_world_state())
	var ledger: Dictionary = game.campaign.duplicate(true)
	var world_instance: int = game.active_world.get_instance_id()
	var runtime_instance: int = game.world_runtime.get_instance_id()
	if not _check(not game._load_game(true), mission_id + " total corruption refuses load"):
		return false
	if not _check(game.active_world.get_instance_id() == world_instance and game.world_runtime.get_instance_id() == runtime_instance and _signature(game._capture_world_state()) == before and game.campaign == ledger, mission_id + " refused load preserves exact running world, runtime and ledger"):
		return false
	return true


func _signature(world: Dictionary) -> Dictionary:
	var clean := world.duplicate(true)
	clean.erase("saved_at")
	clean.erase("campaign")
	return JSON.parse_string(JSON.stringify(clean)) as Dictionary


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var result = JSON.parse_string(file.get_as_text())
	file.close()
	return result if result is Dictionary else {}


func _write_json(path: String, payload: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var stored := file.store_string(JSON.stringify(payload))
	file.close()
	return stored


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		push_error("CAMPAIGN_SNAPSHOT_INTEGRITY_FAIL: " + message)
	return condition
