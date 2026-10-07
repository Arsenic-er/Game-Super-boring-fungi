extends SceneTree

const AuditScript = preload("res://scripts/campaign_audit.gd")
const MainScript = preload("res://scripts/main.gd")
const Presets = preload("res://scripts/campaign_audit_presets.gd")
const State = preload("res://scripts/campaign_state.gd")
var checks := 0
var failed := false
var game: Node
var protected: Dictionary = {}


class FailingAudit:
	extends AuditScript
	var reject_commit := false
	var reject_load := false
	func _commit_world_and_campaign(world: Dictionary) -> bool:
		return false if reject_commit else super._commit_world_and_campaign(world)
	func _load_game(defer_offline: bool = false) -> bool:
		if reject_load:
			organic = 111.0
			campaign["materials"] = 9
			return false
		return super._load_game(defer_offline)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _check(OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/fungi-") or OS.get_environment("XDG_DATA_HOME").begins_with("/home/ubuntu/fungi/tmp/"), "requires isolated disposable server data"):
		return
	var protected_paths: Array[String] = ["user://save.json", "user://save.developer.json", "user://settings.json"]
	for mission in State.Catalog.entries():
		for filename in ["save.json", "save.json.bak", "save.json.tmp", "settings.json"]:
			protected_paths.append("user://review-v1/" + String(mission["id"]) + "/" + filename)
	for path in protected_paths:
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string("CAMPAIGN_AUDIT_PROTECTED " + path)
		file.close()
		protected[path] = FileAccess.get_sha256(path)
	var parser := AuditScript.new()
	for args in [[], ["--audit-stage=early_choice"], ["--audit-hub=1"], ["--audit-hub", "--audit-hub"], ["--audit-hub", "--audit-stage=../save"], ["--audit-hub", "--audit-stage=bad"], ["--audit-hub", "--audit-unknown=1"], ["--audit-hub", "--audit-lang=xx"], ["--audit-hub", "--audit-lang=en", "--audit-lang=zh_CN"], ["--audit-hub", "--review-mission=first_supply"], ["--audit-hub", "--review-unknown"], ["--audit-hub", "--audit-stage"]]:
		if not _check(not parser.audit_configure(args) and not parser._has_recoverable_save() and not parser._commit_world_and_campaign({}), "invalid arguments cannot persist " + str(args)):
			return
	for id in Presets.IDS:
		if not _check(parser.audit_configure(["--audit-hub", "--audit-stage=" + id, "--audit-lang=en"]) and parser.save_path == "user://campaign-audit-v1/" + id + "/save.json", "whitelisted isolated stage " + id):
			return
	parser.free()
	game = FailingAudit.new()
	game.audit_arguments.assign(["--audit-hub", "--audit-lang=zh_CN"])
	root.add_child(game)
	await process_frame
	game.set_process(false)
	if game.pixel_audio != null:
		game.pixel_audio.queue_free()
		game.pixel_audio = null
	if not _check(game.audit_valid and game.audit_open and not game.audit_started and not game.developer_mode_enabled and not FileAccess.file_exists(game.save_path), "startup does not load or overwrite"):
		return
	var stage_hashes := {}
	for id in Presets.IDS:
		if game.audit_stage_id != id:
			var old_path: String = game.save_path
			if not _check(game.audit_switch_stage(id) and not game.audit_started and game.audit_open, "switch selects without loading " + id):
				return
			stage_hashes[old_path] = FileAccess.get_sha256(old_path)
		if not _check(game.audit_start_new(), "fresh synthetic fixture " + id):
			print("AUDIT_DIAG ", game.audit_notice, " campaign=", JSON.stringify(game.campaign), " path=", game.save_path)
			return
		if not _check(game._world_scene_id() == "home_nest" and not game._campaign_active() and game.cores.size() == 2 and game.segments.size() == 4 and game.expedition_units.size() == 8, "prepared home " + id):
			return
		if not _check(game.organic == 220.0 and game.mineral == 24.0 and game.dna == 0 and game.campaign["branches"] == {"transport": 0, "resilience": 0, "defense": 0}, "fixture resources are finite and upgrades remain zero"):
			return
		var payload := FileAccess.get_file_as_string(game.save_path)
		var normal := MainScript.new()
		var normal_rejects := normal._parse_save_payload(payload).is_empty()
		normal.free()
		if not _check(normal_rejects, "normal campaign rejects copied audit envelope"):
			return
		var saved = JSON.parse_string(payload)
		if not _check(not game._parse_save_payload(payload).is_empty() and saved["campaign_audit"]["stage_id"] == id and saved["campaign_audit"]["is_synthetic_fixture"] == true, "metadata parses only its stage"):
			return
		for alteration in ["normal", "review", "developer", "foreign", "malformed_campaign", "bad_speed"]:
			var foreign: Dictionary = saved.duplicate(true)
			match alteration:
				"normal": foreign.erase("campaign_audit")
				"review": foreign["review_slice"] = {}
				"developer": foreign["developer_session"] = true
				"foreign": foreign["campaign_audit"]["stage_id"] = "early_choice" if id != "early_choice" else "early_one"
				"malformed_campaign": foreign["campaign"] = []
				"bad_speed": foreign["campaign_audit"]["speed"] = 999.0
			if not _check(game._parse_save_payload(JSON.stringify(foreign)).is_empty(), "foreign or invalid save refused " + alteration):
				return
		for path in stage_hashes:
			if not _check(FileAccess.get_sha256(path) == stage_hashes[path], "other stages untouched " + path):
				return
		if not _check(game.audit_export_report() and FileAccess.file_exists(game.audit_directory + "/report.json"), "report exported per stage"):
			return
		var disk_hash := FileAccess.get_sha256(game.save_path)
		if not _check(not game.audit_start_new() and game.audit_reset_confirm and FileAccess.get_sha256(game.save_path) == disk_hash, "reset requires confirmation"):
			return
		game._audit_cancel_reset()
		var snapshot: Dictionary = game._capture_world_state()
		var before_campaign: Dictionary = game.campaign.duplicate(true)
		var before_metadata: Dictionary = game._audit_metadata()
		game.reject_commit = true
		if not _check(not game.audit_start_new(true), "reset failure detected"):
			return
		if not _check(game.campaign == before_campaign and game._audit_metadata() == before_metadata and game.audit_fingerprint(game._capture_world_state()) == game.audit_fingerprint(snapshot) and FileAccess.get_sha256(game.save_path) == disk_hash, "failed reset restores world, ledger, metadata and disk"):
			var restored: Dictionary = game._capture_world_state()
			for key in snapshot:
				if key != "saved_at" and JSON.stringify(snapshot[key]) != JSON.stringify(restored.get(key)):
					print("AUDIT_ROLLBACK_FIELD ", key, " before=", str(snapshot[key]).left(150), " after=", str(restored.get(key)).left(150))
			print("AUDIT_ROLLBACK_DIAG campaign=", game.campaign == before_campaign, " metadata=", game._audit_metadata() == before_metadata, " fingerprint=", game.audit_fingerprint(game._capture_world_state()) == game.audit_fingerprint(snapshot))
			return
		var target_id := "early_one" if id == "early_choice" else "early_choice"
		var old_slot: String = game.save_path
		if not _check(not game.audit_switch_stage(target_id) and game.audit_stage_id == id and game.save_path == old_slot and game._audit_metadata() == before_metadata and game.campaign == before_campaign, "failed switch retains active profile and state"):
			return
		game.audit_open = false
		game._audit_quit()
		if not _check(game.audit_open and game.audit_started and not game.audit_notice.is_empty(), "failed close stays paused with visible error"):
			return
		game.reject_commit = false
		if not _check(game.audit_start_new(true), "confirmed reset succeeds"):
			return
		var original_organic: float = game.organic
		var original_mineral: float = game.mineral
		if not _check(game._queue_dna(int(game.campaign["main_core_id"]), 1) and game.organic == original_organic - 30.0 and game.mineral == original_mineral - 1.0, "real paid DNA cost is unchanged"):
			return
		if not _check(game.audit_set_speed(20.0) and not game.audit_set_speed(99.0) and game.audit_save(), "approved test speeds persist"):
			return
		var paid_organic: float = game.organic
		game.organic = 9999.0
		if not _check(game.audit_continue() and game.organic == paid_organic and game.audit_speed == 20.0, "continue restores this stage without fixture or reward injection"):
			return
		var before_load: Dictionary = game._capture_world_state()
		var before_load_campaign: Dictionary = game.campaign.duplicate(true)
		var before_load_metadata: Dictionary = game._audit_metadata()
		game.reject_load = true
		if not _check(not game.audit_continue() and game.campaign == before_load_campaign and game._audit_metadata() == before_load_metadata and game.audit_fingerprint(game._capture_world_state()) == game.audit_fingerprint(before_load), "failed partial load restores current world and ledger"):
			return
		game.reject_load = false
		game._enter_developer_mode()
		if not _check(not game.developer_mode_enabled and game.save_path == old_slot, "developer mode blocked without profile switch"):
			return
		game._settle_home_elapsed({"saved_at": 0}, false)
		if not _check(not game.offline_settlement_active and game.organic == paid_organic, "offline grants remain disabled"):
			return
		game.audit_open = true
		var before_time: float = game.sim_time
		game._process(1.0)
		if not _check(game.sim_time == before_time, "audit panel pauses simulation"):
			return
		var key := InputEventKey.new()
		key.pressed = true
		key.keycode = KEY_F8
		game._input(key)
		if not _check(not game.audit_open, "F8 returns to play"):
			return
		game._input(key)
		if not _check(game.audit_open, "F8 reopens pause panel"):
			return
		game._return_to_main_menu()
		if not _check(game.audit_open and not game.main_menu_active, "main-menu return retains audit launcher"):
			return
	if not _check(game.audit_switch_stage("early_choice") and game.audit_continue(), "prior stage can be resumed anytime"):
		return
	game.audit_return_to_play()
	game.campaign_ui.open = false
	var home_campaign: Dictionary = game.campaign.duplicate(true)
	var home_organic: float = game.organic
	for id in ["remote_pantry", "lost_network", "substrate_race"]:
		if not _check(game.campaign_ui.start_mission(id) and game._world_scene_id() == id and game._campaign_active(), "full hub starts any unlocked branch " + id):
			return
		if not _check(game.sim_speed == game.audit_speed and game.sim_speed == 20.0, "depart preserves selected audit speed"):
			return
		if not _check(not game._parse_save_payload(FileAccess.get_file_as_string(game.save_path)).is_empty(), "active mission and archived home metadata validate"):
			return
		if not _check(game.audit_continue() and game._world_scene_id() == id, "active branch reload retains scene"):
			return
		game.audit_return_to_play()
		if not _check(game.campaign_ui.return_home("retreat") and game._world_scene_id() == "home_nest" and not game._campaign_active(), "returns to playable isolated home"):
			return
		if not _check(game.organic == home_organic and game.campaign["materials"] == home_campaign["materials"] and game.campaign["completed"] == home_campaign["completed"], "retreat adds no rewards and restores home stock"):
			return
		if not _check(game.sim_speed == game.audit_speed and game.sim_speed == 20.0, "home return preserves selected audit speed"):
			return
		game.campaign_ui.open = false
	# Controlled outcome injection proves settlement and carryover wiring only,
	# not a paid mission win, balance, or player completion time.
	if not _check(game.campaign_ui.start_mission("remote_pantry"), "reward-path branch starts"):
		return
	game.lifetime_expedition_organic_returned = 36.0
	game.lifetime_expedition_mineral_returned = 4.0
	if not _check(game.campaign_ui.return_home("victory") and game.campaign["materials"] == 3 and game.campaign["tissues"]["transport"] == 1, "real controller settles one first-victory reward"):
		return
	if not _check(game.campaign_ui.purchase_branch("transport") and game.campaign["tissues"]["transport"] == 0 and game.campaign["branches"]["transport"] == 1, "earned tissue buys persistent home upgrade"):
		return
	if not _check(game.audit_continue() and game.campaign["materials"] == 3 and game.campaign["branches"]["transport"] == 1, "settlement and purchased upgrade survive reload"):
		return
	game.audit_return_to_play()
	if not _check(game.campaign_ui.start_mission("lost_network") and is_equal_approx(game._campaign_nest_multiplier("transport"), 1.15), "home upgrade carries into another independent branch"):
		return
	if not _check(game.campaign_ui.return_home("retreat"), "upgraded expedition returns home"):
		return
	if not _check(game.campaign_ui.start_mission("remote_pantry"), "completed branch can be replayed"):
		return
	game.lifetime_expedition_organic_returned = 36.0
	game.lifetime_expedition_mineral_returned = 4.0
	if not _check(game.campaign_ui.return_home("victory") and game.campaign["materials"] == 3 and game.campaign["tissues"]["transport"] == 0, "replay victory never duplicates first-victory payout"):
		return
	if not _check(not game.campaign_ui.return_home("victory"), "settlement cannot repeat once home"):
		return
	if not await _layout_checks():
		return
	for path in protected:
		if not _check(FileAccess.get_sha256(path) == protected[path], "normal/developer/review profiles untouched " + path):
			return
	game.queue_free()
	await process_frame
	print("CAMPAIGN_AUDIT_OK checks=%d stages=8 normal_costs=true isolated=true" % checks)
	quit(0)


func _layout_checks() -> bool:
	var output := OS.get_environment("FUNGI_AUDIT_VISUAL_OUT")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
	for size in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = size
		root.content_scale_size = size
		for locale in ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]:
			game.settings_locale = locale
			game.audit_open = true
			game._audit_refresh_panel()
			await process_frame
			await process_frame
			await process_frame
			var bounds := Rect2(Vector2.ZERO, Vector2(size))
			if not _check(bounds.encloses(game.audit_panel.get_global_rect()), "audit panel fits " + locale + str(size)):
				return false
			for key in ["new", "continue", "play", "save"]:
				if not _check(bounds.encloses(game.audit_buttons[key].get_global_rect()), "primary controls visible " + key + locale):
					return false
			var body: Control = game.audit_scroll.get_child(0)
			if not _check(body.size.x <= game.audit_scroll.size.x + 1.0, "no horizontal overflow " + locale):
				return false
			if not output.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				if not _check(root.get_texture().get_image().save_png(output.path_join("audit_%s_%dx%d.png" % [locale, size.x, size.y])) == OK, "render capture saved"):
					return false
	return true


func _check(condition: bool, description: String) -> bool:
	checks += 1
	if condition:
		return true
	failed = true
	push_error("CAMPAIGN_AUDIT_FAIL " + description)
	quit(1)
	return false
