extends SceneTree

# Logic checks run only in an explicitly disposable server user-data directory.
# Synthetic victories below test lifecycle isolation, not mission playability.
const ReviewScene = preload("res://scenes/ReviewSlice.tscn")
const ReviewScript = preload("res://scripts/review_slice.gd")
const MainScript = preload("res://scripts/main.gd")
const Words = preload("res://scripts/review_slice_localization.gd")
const Catalog = preload("res://scripts/campaign_mission_catalog.gd")
const Store = preload("res://scripts/save_store.gd")
var checks := 0
var failed := false
var game: Node
var protected: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var data_home := OS.get_environment("XDG_DATA_HOME")
	if not _check(data_home.begins_with("/tmp/fungi-") or data_home.begins_with("/home/ubuntu/fungi/tmp/"), "disposable server user-data is required"):
		return
	for path in ["user://save.json", "user://save.developer.json", "user://settings.json"]:
		if not FileAccess.file_exists(path):
			var sentinel := FileAccess.open(path, FileAccess.WRITE)
			sentinel.store_string("REVIEW_PROTECTED_SENTINEL " + path)
			sentinel.close()
		protected[path] = FileAccess.get_sha256(path)
	var router := MainScript.new()
	if not _check(not router._is_review_entry() and not router._review_launch_requested([]) and not router._review_launch_requested(["--unrelated=1"]), "normal startup stays on campaign entry"):
		return
	for arguments in [["--review-mission=first_supply"], ["--review-mission=bad"], ["--review-lang=en"], ["--review-unknown=1"]]:
		if not _check(router._review_launch_requested(arguments), "all review options route before campaign initialization"):
			return
	router.free()
	for locale in Words.TEXTS:
		for key in Words.TEXTS["en"]:
			if not _check(Words.TEXTS[locale].has(key) and not String(Words.TEXTS[locale][key]).is_empty(), "review copy complete " + locale + "/" + key):
				return
	var invalid := ReviewScript.new()
	if not _check(invalid._is_review_entry(), "review superclass initialization cannot recurse into routing"):
		return
	for args in [[], ["--review-mission=../save"], ["--review-mission=not_real"], ["--review-mission=first_supply", "--review-mission=remote_pantry"], ["--review-mission=first_supply", "--review-lang=xx"], ["--review-mission=first_supply", "--review-profile=free"], ["--review-mission=first_supply", "--review-unknown=1"]]:
		if not _check(not invalid.review_configure(args) and not invalid._has_recoverable_save() and not invalid._commit_world_and_campaign({}), "invalid options never reach persistence"):
			return
	invalid.free()
	var previous_save := ""
	var previous_hash := ""
	for entry in Catalog.entries():
		var id := String(entry["id"])
		game = ReviewScene.instantiate()
		game.review_arguments.assign(["--review-mission=" + id, "--review-lang=zh_CN"])
		root.add_child(game)
		await process_frame
		game.set_process(false)
		_mute_fixture_audio()
		if not _check(game.review_valid and game.review_open and not game.review_started and not game.developer_mode_enabled, id + " opens paused without loading/overwriting"):
			return
		if not _check(game.save_path == "user://review-v1/" + id + "/save.json", id + " has its own slot"):
			return
		if not _check(game.review_start_new(), id + " uses real mission transition"):
			print("REVIEW_DIAG ", id, " notice=", game.review_notice, " scene=", game._world_scene_id(), " campaign=", JSON.stringify(game.campaign))
			return
		if not _check(game._world_scene_id() == id and game._campaign_active() and game.review_open, id + " active scene is independent and paused"):
			return
		var objectives: Array[Dictionary] = game.ReviewObjectives.rows(game)
		if not _check(not objectives.is_empty(), id + " has a live objective checklist"):
			return
		if id == "first_supply":
			var keys: Array = objectives.map(func(row): return row["key"])
			var targets: Array = objectives.map(func(row): return row["target"])
			if not _check(keys == ["campaign_goal_absorbed_organic", "campaign_goal_absorbed_mineral", "trial_network"] and targets == [360.0, 18.0, 600.0] and String(objectives[2]["text"]).contains("300"), "first supply has exactly its three real goals, 300 display length, no DNA/barracks tasks"):
				return
			if not _check(objectives.all(func(row): return is_zero_approx(float(row["current"]))) and game.organic == 220.0, "starting stock is not absorbed-goal progress"):
				return
		if not _check(game.organic == 220.0 and game.mineral == 24.0 and game.dna == 0 and game.expedition_units.is_empty() and game.diet_order.is_empty(), id + " no resources/units/research granted"):
			return
		if not _check(game.campaign["materials"] == 0 and game.campaign["nest_level"] == entry["required_nest_level"] and game.campaign["branches"] == {"transport": 0, "resilience": 0, "defense": 0}, id + " only disclosed access tier is synthetic"):
			return
		if not _check(not bool(game.campaign["completed"].get(id, false)), id + " current victory has not been fabricated"):
			return
		if not _check(game.barracks_unit_unlocks == {"forager": true, "carrier": false, "chelator": false, "scout": false}, id + " only ordinary initial license"):
			return
		if entry["kind"] == "nest_challenge":
			if not _check(game.cores.size() == 1 and game.segments.is_empty() and game.enemy_guard_spores.is_empty() and not game.active_world.mission_ready(game), id + " empty fixed home, manual waves, no prebuilt army"):
				return
			if not _check(game.active_world.manual_action_key(game) == "trial_start_wave", id + " manual wave available"):
				return
		if id == "lost_network":
			if not _check(game.review_initial_conditions["mission_initial_entities"]["cores_total"] == game.cores.size() and game.cores.size() > 1, "authored rescue entities disclosed separately from home fixture"):
				return
		var initial_hash: String = game.review_initial_hash
		if not _check(initial_hash.length() == 64 and game.review_start_new() and game.review_initial_hash == initial_hash, id + " reset reproduces same initial snapshot"):
			print("HASH_MISMATCH ", id, " ", initial_hash, " ", game.review_initial_hash)
			return
		game.review_buttons["new"].pressed.emit()
		if not _check(game.review_reset_confirm and game.review_initial_hash == initial_hash, id + " destructive reset requires second action"):
			return
		game.review_buttons["cancel"].pressed.emit()
		if not _check(not game.review_reset_confirm, id + " reset can be cancelled"):
			return
		if not _check(game.review_set_speed(20) and game.sim_speed == 20 and not game.developer_mode_enabled, id + " acceleration is separate from developer mode"):
			return
		var before_organic: float = game.organic
		var before_mineral: float = game.mineral
		if not _check(game._queue_dna(0, 1) and game.organic < before_organic and game.mineral < before_mineral, id + " accelerated DNA queue still pays real resources"):
			return
		var paid_organic: float = game.organic
		game._switch_developer_profile(true)
		if not _check(not game.developer_mode_enabled and game.organic == paid_organic and game.save_path == "user://review-v1/" + id + "/save.json", id + " cannot escape to free developer slot"):
			return
		var wrong_id := "remote_pantry" if id == "first_supply" else "first_supply"
		if not _check(game._prepare_world_scene(wrong_id) == null, id + " cannot prepare a different mission"):
			return
		if not _check(game.review_save(), id + " manually saves isolated envelope"):
			return
		var serialized := FileAccess.get_file_as_string(game.save_path)
		var parsed: Dictionary = JSON.parse_string(serialized)
		if not _check(not game._parse_save_payload(serialized).is_empty(), id + " isolated envelope validates"):
			return
		parsed["review_slice"]["mission_id"] = wrong_id
		if not _check(game._parse_save_payload(JSON.stringify(parsed)).is_empty(), id + " rejects foreign slice"):
			return
		game.organic = 999.0
		if not _check(game.review_continue() and is_equal_approx(game.organic, paid_organic) and game.sim_speed == 20.0, id + " resumes normal resources and recorded speed"):
			return
		var before_offline: float = game.organic
		game._settle_home_elapsed({"saved_at": 0}, false)
		if not _check(game.organic == before_offline and not game.offline_report_open and not game.offline_settlement_active, id + " no offline drift"):
			return
		if not _check(game.review_export_report(), id + " review report exported"):
			return
		var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.review_directory + "/report.json"))
		if not _check(report["mission_id"] == id and report["normal_costs"] and report["not_campaign_completion_proof"] and report["not_player_timing_evidence"] and report["initial_conditions"]["prepared_units"] == 0, id + " evidence is honest about fixture and timing"):
			return
		game.settings_master_volume = 0.23
		game._save_settings()
		if not _check(FileAccess.file_exists(game.review_directory + "/settings.json"), id + " settings isolated per slice"):
			return
		game.review_open = false
		game.campaign_ui.open = false
		game.pause_menu_open = false
		if id == "first_supply":
			var previous_result: Dictionary = game.review_result.duplicate(true)
			var previous_campaign: Dictionary = game.campaign.duplicate(true)
			if not _check(DirAccess.make_dir_absolute(game.save_path + ".tmp") == OK, "inject destination write failure"):
				return
			var failed_return: bool = game.campaign_ui.return_home("retreat")
			DirAccess.remove_absolute(game.save_path + ".tmp")
			if not _check(not failed_return and game.campaign == previous_campaign and game.review_result == previous_result and game._campaign_active() and not game.review_home_restored and game._world_scene_id() == id, "failed settlement restores review result and campaign"):
				return
		if not _check(game.campaign_ui.return_home("retreat"), id + " ordinary retreat transaction succeeds"):
			return
		if not _home_lifecycle(id, "retreat"):
			return
		if id == "first_supply":
			var original_build: Dictionary = game.review_origin_build.duplicate(true)
			game.review_build = {"commit": "different-test-commit", "sourcehash": "different-test-source"}
			if not _check(game.review_continue() and game.review_origin_build == original_build and game.review_export_report(), "loading preserves original run build"):
				return
			var changed_report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.review_directory + "/report.json"))
			if not _check(changed_report["has_build_change"] and changed_report["source_build_origin"] == original_build and changed_report["current_world_scene_id"] == "home_nest" and changed_report["result"]["world_scene_id"] == id, "report distinguishes original build, current home and mission result"):
				return
		for outcome in ["failure", "victory"]:
			if not _check(game.review_start_new() and game.review_result.is_empty() and not game.review_home_restored and game._world_scene_id() == id, id + " explicit reset clears old result before replay"):
				return
			game.review_return_to_play()
			if outcome == "failure":
				for core in game.cores:
					core["alive"] = false
					core["biomass"] = 0.0
				game.game_over = true
			elif not _complete_fixture(id):
				return
			if not _check(game.campaign_ui.return_home(outcome), id + " real return transaction succeeds for " + outcome):
				return
			if not _home_lifecycle(id, outcome):
				return
		if not previous_save.is_empty() and not _check(FileAccess.get_sha256(previous_save) == previous_hash, id + " did not modify preceding slice"):
			return
		previous_save = game.save_path
		previous_hash = FileAccess.get_sha256(previous_save)
		game.queue_free()
		await process_frame
		if not _protected_unchanged():
			return
	if not await _completion_then_failure():
		return
	print("REVIEW_SLICE_SMOKE_OK checks=", checks, " missions=9 home_outcomes=27 separate_slots=true playable_home=true normal_costs=true lifecycle_fixture_not_timing=true")
	quit(0)


func _home_lifecycle(mission_id: String, outcome: String) -> bool:
	var label := mission_id + "/" + outcome
	var result: Dictionary = game.review_result.duplicate(true)
	if not _check(game._world_scene_id() == "home_nest" and not game._campaign_active() and not game.review_open and not game.campaign_ui.open and not game.main_menu_active and not game.pause_menu_open and not game.game_over and game.game_started and game._living_core_count() == 1, label + " returns immediately to a live home, not a menu"):
		return false
	if not _check(result.get("settled", false) and result.get("outcome", "") == outcome and result.get("world_scene_id", "") == mission_id, label + " keeps the pre-return mission result"):
		return false
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	if not _check(saved["world_scene_id"] == "home_nest" and _same(saved["review_slice"]["result"], result) and saved["campaign"]["active_mission"].is_empty(), label + " home and result are committed together"):
		return false
	var disk_hash := FileAccess.get_sha256(game.save_path)
	var wall_seconds: float = game.review_wall_seconds
	var sim_seconds: float = game.sim_time
	game.review_set_speed(5)
	game._process(0.02)
	if not _check(game.sim_time > sim_seconds and game.review_wall_seconds == wall_seconds and _same(game.review_result, result), label + " home simulates without changing mission timing/result"):
		return false
	var organic: float = game.organic
	var mineral: float = game.mineral
	if not _check(game._queue_dna(0, 1) and game.organic < organic and game.mineral < mineral and not game.developer_mode_enabled, label + " home construction still pays ordinary costs"):
		return false
	_key(KEY_ESCAPE)
	if not _check(game.pause_menu_open, label + " home receives normal Esc input"):
		return false
	_key(KEY_ESCAPE)
	if not _check(not game.pause_menu_open, label + " normal pause menu closes"):
		return false
	_key(KEY_J)
	game._process(0.01)
	game._review_detect_settlement()
	if not _check(game.campaign_ui.open and not game.review_open and FileAccess.get_sha256(game.save_path) == disk_hash, label + " later frames preserve J and do not re-settle/re-save"):
		return false
	var wrong_id := "remote_pantry" if mission_id == "first_supply" else "first_supply"
	game.campaign_ui.selected_mission_id = wrong_id
	game.campaign_ui.show_panel()
	game.campaign_ui._page_selection(1)
	game.campaign_ui._page_selection(-1)
	if not _check(not game.campaign_ui.action_enabled(0) and game.campaign_ui.action_enabled(2), label + " settled J disables replay while Close remains enabled"):
		return false
	if not _check(game.campaign_ui._mission_choices() == [mission_id] and game.campaign_ui.selected_mission_id == mission_id and game.campaign_ui.selection_start == 0, label + " J cannot select another slice"):
		return false
	if not _check(not game.campaign_ui.start_mission(mission_id) and not game.campaign_ui.start_mission(wrong_id) and game.campaign_ui.notice == game._review_text("replay_locked") and not game._campaign_active() and _same(game.review_result, result), label + " replay requires explicit F8 reset"):
		return false
	_key(KEY_J)
	_key(KEY_F8)
	sim_seconds = game.sim_time
	game._process(0.05)
	if not _check(game.review_open and game.review_panel.visible and not game.review_buttons["play"].disabled and game.sim_time == sim_seconds, label + " F8 pauses home with an enabled return button"):
		return false
	_key(KEY_F8)
	game._process(0.02)
	if not _check(not game.review_open and game.sim_time > sim_seconds and _same(game.review_result, result) and FileAccess.get_sha256(game.save_path) == disk_hash, label + " F8 resumes home without re-saving"):
		return false
	if not _check(game.review_save(), label + " home progress saves to its isolated slot"):
		return false
	organic = game.organic
	mineral = game.mineral
	sim_seconds = game.sim_time
	game.organic = 999
	game.chapter_report_open = true
	game.offline_report_open = true
	if not _check(game.review_continue() and game.review_open and game._world_scene_id() == "home_nest" and is_equal_approx(game.organic, organic) and is_equal_approx(game.mineral, mineral) and is_equal_approx(game.sim_time, sim_seconds) and _same(game.review_result, result) and not game.chapter_report_open and not game.offline_report_open, label + " saved home reloads with costs/progress/result and clears stale modals"):
		return false
	game._settle_home_elapsed({"saved_at": 0}, false)
	if not _check(is_equal_approx(game.organic, organic) and not game.offline_settlement_active and not game.offline_report_open, label + " home reload cannot award offline gains"):
		return false
	game.review_buttons["play"].pressed.emit()
	if not _check(not game.review_open and game.review_return_to_play(), label + " Return to play resumes the saved home"):
		return false
	if not _check(game.review_export_report(), label + " settled report remains exportable"):
		return false
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.review_directory + "/report.json"))
	return _check(_same(report["result"], result) and report["current_world_scene_id"] == "home_nest" and report["mission_id"] == mission_id, label + " report distinguishes current home from original mission")


func _same(left: Variant, right: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(left)) == JSON.parse_string(JSON.stringify(right))


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	if code == KEY_F8:
		game._input(event)
	else:
		game._unhandled_input(event)


func _segment(a: Vector2, b: Vector2) -> Dictionary:
	return {"a": a, "b": b, "core_id": 0, "growth": 1.0, "curve": 0.0, "orphaned": false, "viability": 1.0}


func _complete_fixture(mission_id: String) -> bool:
	# Controlled objective fixtures test Return Home transactions, never pacing.
	var scene = game.active_world
	match mission_id:
		"first_supply":
			game.lifetime_organic_absorbed = scene.organic_required
			game.lifetime_mineral_absorbed = scene.mineral_required
			game.segments.append(_segment(Vector2.ZERO, Vector2(scene.hypha_world_required, 0)))
		"remote_pantry":
			game.lifetime_expedition_organic_returned = scene.organic_required
			game.lifetime_expedition_mineral_returned = scene.mineral_required
		"first_contact", "two_fronts", "stable_colony":
			while int(scene.runtime.data["mission_state"]["completed_waves"]) < scene.wave_sizes.size():
				var state: Dictionary = scene.runtime.data["mission_state"]
				if not bool(state["wave_active"]) and not _check(game.campaign_ui.advance_mission(), mission_id + " starts a real fixture wave"):
					return false
				for raider_id in state["raider_ids"].duplicate():
					if not _check(game._damage_enemy_guard(int(raider_id), 999.0), mission_id + " fixture records real raider death"):
						return false
				scene.mission_tick(game, 0.001)
			var state: Dictionary = scene.runtime.data["mission_state"]
			game.lifetime_organic_absorbed = float(state["organic_baseline"]) + scene.organic_required
			game.lifetime_mineral_absorbed = float(state["mineral_baseline"]) + scene.mineral_required
			if scene.hypha_world_required > 0:
				game.segments.append(_segment(game.cores[0]["pos"], game.cores[0]["pos"] + Vector2(scene.hypha_world_required, 0)))
		"substrate_race":
			for center in [Vector2(520, -180), Vector2(520, 210)]:
				game.segments.append(_segment(Vector2.ZERO, center))
			game.lifetime_organic_absorbed = scene.organic_required
			game.lifetime_mineral_absorbed = scene.mineral_required
		"lost_network":
			if not _check(game.campaign_ui.advance_mission(), "lost network starts the real rescue phase"):
				return false
			for center in [Vector2(420, -180), Vector2(510, 170)]:
				game.segments.append(_segment(Vector2.ZERO, center))
			game._update_orphaned_segments(0.001)
			scene.mission_tick(game, 0.001)
			game.cores[3]["biomass"] = game.cores[3]["max_biomass"] * 0.75
			game.lifetime_organic_absorbed = scene.organic_required
		"toxic_frontier":
			for i in range(2):
				game._spawn_expedition_spore(0, "forager", false)
				var unit: Dictionary = game.expedition_units[i]
				unit["pos"] = Vector2(700, 180)
				unit["cargo_organic"] = 1.0
			scene.mission_tick(game, 0.001)
			for unit in game.expedition_units:
				unit["pos"] = game._expedition_home_position(unit)
				game._deposit_expedition_cargo(unit)
			scene.mission_tick(game, 0.001)
			game.lifetime_expedition_organic_returned = scene.organic_required
			game.lifetime_expedition_mineral_returned = scene.mineral_required
		"boundary_counterattack":
			game._damage_enemy_fungus(int(scene.runtime.data["mission_state"]["target_enemy_id"]), 999.0)
			game.lifetime_organic_absorbed = scene.organic_required
	return _check(game._campaign_mission_ready(), mission_id + " fixture meets real victory predicate")


func _completion_then_failure() -> bool:
	game = ReviewScene.instantiate()
	game.review_arguments.assign(["--review-mission=first_supply"])
	root.add_child(game)
	await process_frame
	game.set_process(false)
	_mute_fixture_audio()
	if not _check(game.review_continue() and game._world_scene_id() == "home_nest" and game.review_result.get("outcome", "") == "victory" and game.review_return_to_play(), "fresh review instance continues saved playable home and original victory"):
		return false
	if not _check(not game.campaign_ui.start_mission("first_supply"), "fresh home instance retains replay guard"):
		return false
	if not _check(game.review_start_new(), "result lifecycle fixture starts"):
		return false
	# These values exercise reporting state transitions only. They are never an
	# audit-player option or evidence for the normal paid route.
	game.lifetime_organic_absorbed = 360
	game.lifetime_mineral_absorbed = 18
	var segment: Dictionary = {"a": Vector2.ZERO, "b": Vector2(601, 0), "core_id": 0, "growth": 1.0, "curve": 0.0, "orphaned": false, "viability": 1.0}
	game.segments.append(segment)
	game.review_return_to_play()
	game._process(0.0)
	if not _check(game.review_result.get("outcome", "") == "objectives_met" and game.review_open, "reaching objectives opens paused review"):
		return false
	game.review_return_to_play()
	game.game_over = true
	game._process(0.0)
	if not _check(game.review_result.get("outcome", "") == "failure" and game.review_open, "continued play can update provisional success to failure"):
		return false
	_mute_fixture_audio()
	game.queue_free()
	await process_frame
	# Let the dummy audio mixer release any in-flight playback references before
	# SceneTree exits. This is test teardown, not a gameplay audio workaround.
	await create_timer(0.06).timeout
	return _protected_unchanged()


func _mute_fixture_audio() -> void:
	game.pixel_audio.configure(0, 0, 0, 0, 0)
	game.pixel_audio.ambient_player.stop()
	for player in game.pixel_audio.players:
		player.stop()


func _protected_unchanged() -> bool:
	for path in protected:
		if not _check(FileAccess.get_sha256(path) == protected[path], "normal/developer/settings sentinel unchanged " + path):
			return false
	return true


func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failed = true
		push_error("REVIEW_SLICE_FAIL " + label)
		quit(1)
	return condition
