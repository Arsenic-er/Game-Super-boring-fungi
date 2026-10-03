extends SceneTree

# Integration/transaction fixtures, not a gameplay-duration forecast.
# The separate remote_pantry_smoke exercises the fully paid natural route.
const State = preload("res://scripts/campaign_state.gd")
const Catalog = preload("res://scripts/campaign_mission_catalog.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const SLOT := "user://remote_pantry_campaign_smoke.json"
const MISSION := "remote_pantry"
const LOCALES := ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_unblock()
	SaveStore.remove_slot(SLOT)
	var game: Node = await _new_runner()
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.campaign = State.fresh()
	game._ensure_campaign_main_core()
	game.campaign_ui.show_panel()
	var locked_world: Dictionary = _signature(game._capture_world_state())
	var locked_ledger: Dictionary = game.campaign.duplicate(true)
	if not _check(_select(game, 1) and game.campaign_ui.mission_id() == MISSION and not game.campaign_ui.action_enabled(0), "locked second mission can be inspected but its launch button is disabled"):
		return
	if not _check(_action(game, 0) and not game._campaign_start_mission(MISSION) and not game._campaign_active() and game.campaign == locked_ledger and _signature(game._capture_world_state()) == locked_world, "both UI launch and direct launch reject a locked second mission without mutation"):
		return
	for locale_id in LOCALES:
		game.settings_locale = locale_id
		if not _check(game.campaign_ui.paragraphs().has(game.campaign_ui.chapter_text("mission_locked")), locale_id + " explains the lock"):
			return
		for viewport in [Vector2(1280, 720), Vector2(960, 540), Vector2(640, 360)]:
			var panel: Rect2 = game.campaign_ui.panel_rect(viewport)
			var first: Rect2 = game.campaign_ui.selection_rect(viewport, 0)
			var second: Rect2 = game.campaign_ui.selection_rect(viewport, 1)
			if not _check(panel.encloses(first) and panel.encloses(second) and not first.intersects(second), locale_id + " keeps both mission selection cards inside the panel without overlap"):
				return
			for index in range(3):
				var action: Rect2 = game.campaign_ui.button_rect(viewport, index)
				if not _check(not first.intersects(action) and not second.intersects(action), locale_id + " selection cards do not overlap action buttons"):
					return
	game.settings_locale = "en"
	game.campaign_ui.reset_panel()

	# A version-1, level-2 save from before the second mission was implemented.
	# All nonzero values are intentional inheritance-boundary fixtures.
	game.campaign.nest_level = 2
	game.campaign.completed = {"first_supply": true}
	game.organic = 321.125
	game.mineral = 43.5
	game.dna = 37
	game.barracks_unit_unlocks = {"forager": true, "carrier": true, "chelator": true, "scout": false}
	game.diet_unit_unlocks["lytic"] = true
	game.diet_unit_unlocks["piercer"] = true
	game.diet_order = ["bacteria", "fungi"]
	game.diet_levels["bacteria"] = 2
	game.diet_levels["fungi"] = 2
	for levels in [game.bacteria_components, game.structure_levels, game.survival_levels, game.scout_upgrade_levels]:
		for key in levels:
			levels[key] = 1
	game.cores[0]["feeder_range_level"] = 2
	game.cores.append(game._make_core(Vector2(150, 0), "barracks"))
	game._spawn_expedition_spore(1, "forager")
	if not _check(game._queue_dna(0, 1) and game._save_game(), "old home fixture saves real queued work, stocks, licenses, levels and an existing unit"):
		return
	await _dispose(game)
	game = await _new_runner()
	if not _check(game._load_game(true) and int(game.campaign.nest_level) == 2 and bool(game.campaign.completed.get("first_supply", false)) and Catalog.is_unlocked(game.campaign, MISSION) and State.can_begin(game.campaign, MISSION), "old level-2 first-clear save automatically unlocks the new mission"):
		return
	if not _check(await _finish_settlement(game), "loading the existing home finishes any bounded offline settlement"):
		return
	_close_modals(game)
	var home: Dictionary = game._capture_world_state()
	var home_signature := _signature(home)
	var ledger: Dictionary = game.campaign.duplicate(true)
	var disk := _read_text()
	var home_id: int = game.active_world.get_instance_id()
	var runtime_id: int = game.world_runtime.get_instance_id()
	if not _check(_block() and not game._campaign_start_mission(MISSION), "real write failure rejects second-mission departure"):
		return
	if not _check(game.active_world.get_instance_id() == home_id and game.world_runtime.get_instance_id() == runtime_id and game.campaign == ledger and _signature(game._capture_world_state()) == home_signature and _read_text() == disk, "failed departure preserves the exact home instances, ledger, world and committed bytes"):
		return
	_unblock()
	game.campaign_ui.show_panel()
	if not _check(_select(game, 0) and game.campaign_ui.mission_id() == "first_supply" and _select(game, 1) and game.campaign_ui.selected_mission_id == MISSION and game.campaign_ui.action_enabled(0), "real two-card input switches between first and second missions"):
		return
	if not _check(_action(game, 0) and game._campaign_active() and game.campaign.active_mission.id == MISSION and game._world_scene_id() == MISSION and game.active_world.scene_file_path == "res://scenes/missions/RemotePantry.tscn", "selected second mission launches its actual independent PackedScene"):
		return
	if not _check(_signature(game.campaign.home_world) == home_signature and game.organic == 220.0 and game.mineral == 24.0 and game.dna == 0 and game.cores.size() == 1 and game.expedition_units.is_empty() and (game.cores[0]["jobs"] as Array).is_empty(), "home stocks, DNA, units, buildings and prepaid orders do not leak into the mission"):
		return
	if not _check(game.barracks_unit_unlocks == {"forager": true, "carrier": true, "chelator": true, "scout": false} and bool(game.diet_unit_unlocks["lytic"]) and bool(game.diet_unit_unlocks["piercer"]), "only owned boolean unit licenses cross the boundary"):
		return
	for levels in [game.diet_levels, game.diet_investments, game.bacteria_components, game.structure_levels, game.survival_levels, game.scout_upgrade_levels]:
		if not _check(_all_zero(levels), "every diet and enhancement level or investment starts at zero"):
			return
	if not _check(game.diet_order.is_empty() and int(game.cores[0]["feeder_range_level"]) == 0 and not game._available_barracks_units().has("lytic") and not game._available_barracks_units().has("piercer"), "diet order and node upgrades do not carry; special licenses do not bypass mission-local diet activation"):
		return
	if not _check(game.campaign_ui.progress_hint_key() == "hint_barracks", "second mission starts with its own barracks instruction"):
		return
	# Create a valid integration fixture to exercise production guards and hints.
	game.cores.append(game._make_core(Vector2(150, 0), "barracks"))
	if not _check(not game._queue_expedition_spores(1, "lytic", 1, false) and not game._queue_expedition_spores(1, "piercer", 1, false), "real production entry rejects inherited special units while diets remain inactive"):
		return
	game.barracks_unit_unlocks["chelator"] = false
	if not _check(game.campaign_ui.progress_hint_key() == "hint_chelator", "mineral-license hint replaces the first mission's hypha hint"):
		return
	game.barracks_unit_unlocks["chelator"] = true
	if not _check(game.campaign_ui.progress_hint_key() == "hint_transport_organic", "transport-organic hint follows a usable barracks"):
		return
	game.lifetime_expedition_organic_returned = 36.0
	if not _check(game.campaign_ui.progress_hint_key() == "hint_transport_mineral", "mineral delivery becomes the remaining goal"):
		return
	game.lifetime_expedition_organic_returned = 7.125
	game.lifetime_expedition_mineral_returned = 1.375
	game.organic = 10000.0
	game.mineral = 10000.0
	game.lifetime_organic_absorbed = 10000.0
	game.lifetime_mineral_absorbed = 10000.0
	if not _check(not game._campaign_mission_ready() and not game._campaign_return("victory"), "large stocks and passive uptake cannot finish incomplete transport goals"):
		return
	for locale_id in LOCALES:
		game.settings_locale = locale_id
		var expected: String = game.campaign_ui.chapter_text("transport_progress", {"organic": "7.125", "organic_goal": "36", "mineral": "1.375", "mineral_goal": "4"})
		var progress: String = game.campaign_ui.progress_text()
		if not _check(progress == expected and progress.contains("7.125/36") and progress.contains("1.375/4") and not progress.contains("10000") and game.campaign_ui.mission_title() == game.campaign_ui.chapter_text("remote_pantry_title"), locale_id + " progress has exactly the two transported-resource metrics and the second mission title"):
			return
		var lines: Array = game.campaign_ui.progress_hud_lines(Rect2(0, 0, 440, 120))
		var correct_hint := false
		for line in lines:
			if line["role"] == "hint":
				correct_hint = line["text"] == game.campaign_ui.chapter_text("hint_transport_organic")
		if not _check(correct_hint, locale_id + " HUD resolves the second-mission hint instead of the first mission's copy"):
			return
	game.settings_locale = "en"
	game._spawn_expedition_spore(1, "forager")
	game._spawn_expedition_spore(1, "chelator")
	game.resources[0]["amount"] = 0.0
	game.resources[0]["alive"] = false
	game.sim_time = 123.25
	if not _check(game._save_game(), "second mission saves depleted resources, transported counters and its own units"):
		return
	var task_signature := _signature(game._capture_world_state())
	var payload: Dictionary = JSON.parse_string(_read_text())
	if not _check(payload["world_scene_id"] == MISSION and payload["campaign"]["active_mission"]["id"] == MISSION and payload["campaign"]["home_world"]["world_scene_id"] == "home_nest", "composite save records both distinct scene identities"):
		return
	payload["saved_at"] = Time.get_unix_time_from_system() - 72.0 * 3600.0
	if not _check(_write_json(payload), "age only the active-task save by seventy-two hours"):
		return
	await _dispose(game)
	game = await _new_runner()
	if not _check(game._load_game(true) and game._world_scene_id() == MISSION and game.campaign_ui.mission_id() == MISSION and _signature(game._capture_world_state()) == task_signature, "fresh runner restores the same second task and cargo counters"):
		return
	await process_frame
	if not _check(not game.offline_settlement_active and not game.offline_report_open and _signature(game._capture_world_state()) == task_signature and _signature(game.campaign.home_world) == home_signature, "an old active task does not gain offline cargo or mutate the archived home"):
		return
	_close_modals(game)
	game.lifetime_expedition_organic_returned = 36.0
	game.lifetime_expedition_mineral_returned = 4.0
	if not _check(game._campaign_mission_ready() and game._save_game(), "controlled returned-cargo completion checkpoints before a transactional return"):
		return
	var task_id: int = game.active_world.get_instance_id()
	runtime_id = game.world_runtime.get_instance_id()
	task_signature = _signature(game._capture_world_state())
	ledger = game.campaign.duplicate(true)
	disk = _read_text()
	if not _check(_block() and not game._campaign_return("victory"), "real disk failure blocks second-mission victory settlement"):
		return
	if not _check(game.active_world.get_instance_id() == task_id and game.world_runtime.get_instance_id() == runtime_id and _signature(game._capture_world_state()) == task_signature and game.campaign == ledger and _read_text() == disk, "failed settlement preserves the live task, ledger, cargo, and committed save"):
		return
	_unblock()
	if not _check(game._campaign_return("victory") and await _finish_settlement(game), "successful retry returns to the persistent home"):
		return
	if not _check(game._world_scene_id() == "home_nest" and _signature(game._capture_world_state()) == home_signature and int(game.campaign.materials) == 3 and bool(game.campaign.completed.get(MISSION, false)) and int(game.campaign.last_result.reward.materials) == 3 and not game._campaign_return("victory"), "first victory restores the exact home and awards three materials exactly once"):
		return
	_close_modals(game)
	if not _check(game._campaign_start_mission(MISSION), "completed second mission can be replayed"):
		return
	game.lifetime_expedition_organic_returned = 36.0
	game.lifetime_expedition_mineral_returned = 4.0
	if not _check(game._campaign_return("victory") and await _finish_settlement(game) and int(game.campaign.materials) == 3 and int(game.campaign.last_result.reward.materials) == 0, "replay completes but awards no repeat materials"):
		return
	for outcome in ["retreat", "failure"]:
		_close_modals(game)
		if not _check(game._campaign_start_mission(MISSION), outcome + " can start an independent second-mission attempt"):
			return
		game.organic = 17.25
		if outcome == "failure":
			for core_id in range(game.cores.size()):
				game._damage_core(core_id, 10000.0, "environment_pressure")
			game._process(0.01)
			if not _check(game.game_over and game._living_core_count() == 0, "actual loss of every mission core triggers failure"):
				return
		if not _check(game._campaign_return(outcome) and await _finish_settlement(game) and game._world_scene_id() == "home_nest" and not game.game_over and _signature(game._capture_world_state()) == home_signature and int(game.campaign.materials) == 3 and game.campaign.last_result.outcome == outcome, outcome + " restores home without leaking mission resources, damage or rewards"):
			return
	print("REMOTE_PANTRY_CAMPAIGN_OK checks=%d lock=ui+api legacy=level2 selection=two-cards licenses=bool-only levels=reset save=task-frozen reward=once rollback=departure+return locales=7" % checks)
	SaveStore.remove_slot(SLOT)
	await _dispose(game)
	quit(0)


func _new_runner() -> Node:
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.developer_mode_enabled = false
	game.splash_active = false
	game.autosave_enabled = false
	game.save_path = SLOT
	game.main_menu_active = false
	game.game_started = true
	return game


func _close_modals(game: Node) -> void:
	game.main_menu_active = false
	game.pause_menu_open = false
	game.offline_report_open = false
	game.chapter_report_open = false
	game.upgrade_open = false
	game.goals_open = false
	game.barracks_production_open = false
	game.campaign_ui.reset_panel()


func _select(game: Node, index: int) -> bool:
	return _click(game, game.campaign_ui.selection_rect(game.get_viewport_rect().size, index).get_center())


func _action(game: Node, index: int) -> bool:
	return _click(game, game.campaign_ui.button_rect(game.get_viewport_rect().size, index).get_center())


func _click(game: Node, position: Vector2) -> bool:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = position
	return game.campaign_ui.handle_input(event)


func _all_zero(levels: Dictionary) -> bool:
	for value in levels.values():
		if int(value) != 0:
			return false
	return true


func _signature(world: Dictionary) -> Dictionary:
	var clean := world.duplicate(true)
	clean.erase("saved_at")
	clean.erase("campaign")
	return JSON.parse_string(JSON.stringify(clean)) as Dictionary


func _finish_settlement(game: Node) -> bool:
	var started := Time.get_ticks_msec()
	var frames := 0
	while game.offline_settlement_active and Time.get_ticks_msec() - started < 30000 and frames < 2400:
		game._pump_offline_progress()
		frames += 1
		await process_frame
	return not game.offline_settlement_active and Time.get_ticks_msec() - started < 30000


func _block() -> bool:
	var path := ProjectSettings.globalize_path(SaveStore.temp_path(SLOT))
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.make_dir_absolute(path) == OK


func _unblock() -> void:
	var path := ProjectSettings.globalize_path(SaveStore.temp_path(SLOT))
	if DirAccess.dir_exists_absolute(path):
		DirAccess.remove_absolute(path)


func _read_text() -> String:
	var file := FileAccess.open(SLOT, FileAccess.READ)
	if file == null:
		return ""
	var result := file.get_as_text()
	file.close()
	return result


func _write_json(payload: Dictionary) -> bool:
	var file := FileAccess.open(SLOT, FileAccess.WRITE)
	if file == null:
		return false
	var stored := file.store_string(JSON.stringify(payload))
	file.close()
	return stored


func _dispose(game: Node) -> void:
	game.queue_free()
	await process_frame


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if condition:
		return true
	push_error("REMOTE_PANTRY_CAMPAIGN_FAIL: " + message)
	quit(1)
	return false
