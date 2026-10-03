extends SceneTree

# Transaction and lifecycle coverage uses explicitly controlled progress fixtures.
# This is not an economic pacing test or a substitute for the real-combat routes.
const Campaign = preload("res://scripts/campaign_state.gd")
const Catalog = preload("res://scripts/campaign_mission_catalog.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const SLOT := "user://campaign_full_integration_smoke.json"
const IDS := ["first_supply", "remote_pantry", "first_contact", "substrate_race", "lost_network", "two_fronts", "toxic_frontier", "boundary_counterattack", "stable_colony"]
const TRIALS := ["first_contact", "two_fronts", "stable_colony"]
var game: Node
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_unblock_save()
	SaveStore.remove_slot(SLOT)
	game = await _runner()
	if not _prepare_home():
		return
	for index in range(IDS.size()):
		if not await _mission_roundtrip(IDS[index]):
			return
		if index in [0, 2, 5]:
			_clear_modals()
			var before: int = game.campaign["materials"]
			var old_level: int = game.campaign["nest_level"]
			var cost: int = Campaign.upgrade_cost(game.campaign)
			if not _check(game._campaign_upgrade() and game.campaign["nest_level"] == old_level + 1 and game.campaign["materials"] == before - cost, "real controller commits the required nest upgrade after " + IDS[index]):
				return
	if not _check(game.campaign["nest_level"] == 4 and game.campaign["materials"] == 12 and Campaign.chapter_completed(game.campaign) and game.campaign["completed"].size() == 9, "the actual nine-scene campaign ends at level four with 12 optional materials"):
		return
	_clear_modals()
	if not _failed_branch_purchase("transport"):
		return
	for branch_id in Campaign.BRANCH_IDS:
		for level in range(1, 3):
			if not _check(game.campaign_ui.purchase_branch(branch_id) and Campaign.branch_level(game.campaign, branch_id) == level, "real UI transaction purchases " + branch_id + " level " + str(level)):
				return
	if not _check(game.campaign["materials"] == 0 and game._save_game(), "all six optional purchases spend exactly 12 and save"):
		return
	var final_home: Dictionary = game._capture_world_state()
	var final_campaign: Dictionary = game.campaign.duplicate(true)
	if not _check(game._load_game(true) and not game.offline_settlement_active and _same(game.campaign, final_campaign), "level four, chapter completion and branches survive a real load"):
		return
	if not _check(_signature(game._capture_world_state()) == _signature(final_home), "loading completed progression does not alter the home"):
		return
	if not await _buff_scope_and_trial_rollback():
		return
	if not _mission_failure_ui():
		return
	print("CAMPAIGN_FULL_INTEGRATION_OK checks=%d scenes=9 fresh-runner-loads=9 first-rewards=27 nest=4 branches=3x2 trial-clone=true ownerless-save=true rollback=true trial-offline-double-credit=false fixtures-not-economic-routes=true" % checks)
	SaveStore.remove_slot(SLOT)
	await _dispose()
	quit(0)


func _prepare_home() -> bool:
	if not _check(game._start_new_culture() and game._founder_spore_active(), "fixture begins in a normal home scene"):
		return false
	game._complete_founder_spore_germination()
	game.campaign = Campaign.fresh()
	game._ensure_campaign_main_core()
	# Distinctive home-only state makes accidental stock/technology copying visible.
	game.organic = 987.125
	game.mineral = 123.375
	game.dna = 17
	game.cores[0]["pos"] = Vector2(-120, 70)
	game.cores[0]["biomass"] = 82.125
	game.cores.append(game._make_core(Vector2(130, 70), "barracks"))
	game.segments = [_segment(Vector2(-120, 70), Vector2(130, 70), 0)]
	game._spawn_expedition_spore(1, "forager", false)
	game._spawn_expedition_spore(1, "forager", false)
	game.expedition_units[0]["biomass"] = 1.125
	game.barracks_unit_unlocks["carrier"] = true
	game.barracks_unit_unlocks["chelator"] = true
	game.diet_unit_unlocks["lytic"] = true
	game.diet_order = ["bacteria"]
	game.diet_levels["bacteria"] = 2
	game.diet_investments["bacteria"] = game._legacy_diet_investment("bacteria", 0)
	game.survival_levels["repair"] = 2
	game.scout_upgrade_levels["vision"] = 1
	game.lifetime_organic_absorbed = 100.25
	game.lifetime_mineral_absorbed = 10.125
	game.enemy_fungi.clear()
	game.enemy_hyphae.clear()
	game.enemy_guard_spores.clear()
	game.ecology_events.clear()
	game.enemy_fungi_initialized = true
	game._update_exploration(false)
	game.core_selected_once = true
	game.chapter_task_index = game._infer_chapter_task_index()
	return _check(game._queue_dna(0, 1) and game._save_game(), "home saves distinctive damage, units, levels, resources and prepaid work")


func _mission_roundtrip(mission_id: String) -> bool:
	_clear_modals()
	var is_trial := TRIALS.has(mission_id)
	var home: Dictionary = game._capture_world_state()
	var old_campaign: Dictionary = game.campaign.duplicate(true)
	var home_scene_id: int = game.active_world.get_instance_id()
	if is_trial and not _failed_trial_departure(mission_id):
		return false
	if not _check(game._campaign_start_mission(mission_id) and game._world_scene_id() == mission_id and game.campaign["active_mission"]["id"] == mission_id, "real departure selects independent scene " + mission_id):
		return false
	if not _check(not is_instance_id_valid(home_scene_id) and _signature(game.campaign["home_world"]) == _signature(home), "departure archives exactly the home and releases its former scene"):
		return false
	if is_trial:
		var clone: Dictionary = game._capture_world_state()
		for field in ["cores", "segments", "expedition_units", "organic", "mineral", "dna", "diet_levels", "diet_order", "survival_levels", "scout_upgrade_levels", "resource_catalog", "rng_state"]:
			if not _check(_same(clone[field], home[field]), mission_id + " clones actual home field " + field):
				return false
		if not _check(game.enemy_guard_spores.is_empty() and not game._campaign_mission_ready(), "trial preparation does not spawn attackers or award a victory"):
			return false
		if not _failed_phase_action(mission_id):
			return false
		if not _check(game.campaign_ui.advance_mission() and game.enemy_guard_spores.size() > 0, "manual action transaction starts the trial's first real wave"):
			return false
		for guard in game.enemy_guard_spores:
			if not _check(int(guard["fungus_id"]) == -1 and game.active_world.handles_enemy_guard(int(guard["id"])), "trial owns each ownerless guard through saved wave identity"):
				return false
	else:
		if not _check(game.organic != home["organic"] and game.mineral != home["mineral"] and game.dna == 0 and game.expedition_units.is_empty(), "expedition uses its own stocks and no home troops"):
			return false
		if not _check(game.diet_order.is_empty() and game.diet_levels["bacteria"] == 0 and game.survival_levels["repair"] == 0 and game.scout_upgrade_levels["vision"] == 0, "expedition does not inherit physiological or reinforcement levels"):
			return false
		if not _check(game.barracks_unit_unlocks["carrier"] and game.barracks_unit_unlocks["chelator"] and game.diet_unit_unlocks["lytic"] and not game._available_barracks_units().has("lytic"), "unit licenses inherit but inactive diet still gates specialists"):
			return false
		for branch_id in Campaign.BRANCH_IDS:
			if not _check(is_equal_approx(game._campaign_nest_multiplier(branch_id), 1.0), "nest bonuses do not apply in " + mission_id):
				return false
		if mission_id == "lost_network":
			if not _failed_phase_action(mission_id):
				return false
			if not _check(game.campaign_ui.advance_mission(), "real action transaction starts the sealed-network rescue"):
				return false
	# Mark runtime changes and age the saved mission to prove that loading it
	# never simulates offline mission progress or regenerates the authored map.
	game.organic = 91.375
	game.mineral = 11.125
	game.dna = 19
	game.resources[0]["amount"] = 0.0
	game.resources[0]["alive"] = false
	game.sim_time = 42.25
	if not _check(game._save_game(), mission_id + " saves in-progress state"):
		return false
	var mission: Dictionary = game._capture_world_state()
	var payload := _read_json()
	payload["saved_at"] = Time.get_unix_time_from_system() - 72.0 * 3600.0
	if is_trial:
		payload["campaign"]["home_world"]["saved_at"] = payload["saved_at"]
	if not _check(_write_json(payload), "write aged but valid test-slot envelope"):
		return false
	var disk_before: String = FileAccess.get_file_as_string(SLOT)
	var guard_count: int = game.enemy_guard_spores.size()
	await _dispose()
	game = await _runner()
	if not _check(game._load_game(true) and game._world_scene_id() == mission_id and game._campaign_active(), "fresh Main loads " + mission_id + " through production SaveStore"):
		return false
	var loaded_world: Dictionary = _signature(game._capture_world_state())
	var expected_mission: Dictionary = _signature(mission)
	if loaded_world != expected_mission:
		for key in expected_mission:
			if not _same(expected_mission[key], loaded_world.get(key)):
				print("CAMPAIGN_INTEGRATION_LOAD_DIFF mission=", mission_id, " key=", key, " expected=", JSON.stringify(expected_mission[key]).substr(0, 800), " actual=", JSON.stringify(loaded_world.get(key)).substr(0, 800))
	if not _check(not game.offline_settlement_active and not game.offline_report_open and loaded_world == expected_mission, "72h task load exactly preserves mission state and never runs offline work: " + mission_id):
		return false
	if not _check(FileAccess.get_file_as_string(SLOT) == disk_before and _signature(game.campaign["home_world"]) == _signature(home), "task load neither rewrites the save nor advances archived home"):
		return false
	if is_trial:
		if not _check(game.enemy_guard_spores.size() == guard_count and guard_count > 0, "fresh load retains all ownerless trial raiders"):
			return false
		var guard_snapshot: Array = game._capture_world_state()["enemy_guard_spores"]
		game._update_enemy_guard_spores(0.25)
		if not _check(_same(game._capture_world_state()["enemy_guard_spores"], guard_snapshot), "legacy guard AI does not decay or delete trial raiders"):
			return false
	if not _complete_fixture(mission_id):
		return false
	if not _check(game._campaign_mission_ready() and game._save_game(), "controlled objective fixture completes and checkpoints " + mission_id):
		return false
	if not _check(game._load_game(true) and game._campaign_mission_ready(), "ready mission remains ready after a production save/load"):
		return false
	_clear_modals()
	# Non-trial home accounting is tested extensively elsewhere. Keep this
	# transaction fixture below its offline threshold; trials retain the 72h age.
	if not is_trial:
		game.campaign["home_world"]["saved_at"] = Time.get_unix_time_from_system()
	if not _check(game._campaign_return("victory") and game._world_scene_id() == "home_nest" and not game._campaign_active(), "real successful return restores HomeNest"):
		return false
	var restored: Dictionary = _signature(game._capture_world_state())
	var expected_home: Dictionary = _signature(home)
	if restored != expected_home:
		for key in expected_home:
			if not _same(expected_home[key], restored.get(key)):
				print("CAMPAIGN_INTEGRATION_DIFF mission=", mission_id, " key=", key, " expected=", JSON.stringify(expected_home[key]).substr(0, 240), " actual=", JSON.stringify(restored.get(key)).substr(0, 240))
	if not _check(not game.offline_settlement_active and not game.offline_report_open and restored == expected_home, "only reward ledger changes; archived home stock, damage, units, jobs and map restore exactly"):
		return false
	if not _check(game.campaign["materials"] == int(old_campaign["materials"]) + 3 and game.campaign["completed"].get(mission_id, false) and game.campaign["last_result"]["mission_id"] == mission_id, "first victory records exactly three materials for the correct mission"):
		return false
	var settled_world: Dictionary = game._capture_world_state()
	var settled_campaign: Dictionary = game.campaign.duplicate(true)
	_clear_modals()
	if not _check(not game._campaign_return("victory") and game.campaign == settled_campaign, "duplicate return cannot duplicate first-win materials"):
		return false
	if not _check(game._load_game(true) and not game.offline_settlement_active and not game.offline_report_open and _signature(game._capture_world_state()) == _signature(settled_world) and _same(game.campaign, settled_campaign), "immediate reload cannot add a second offline settlement or reward"):
		return false
	return true


func _complete_fixture(mission_id: String) -> bool:
	# These explicit state fixtures exercise transaction predicates, not pacing.
	var scene = game.active_world
	match mission_id:
		"first_supply":
			game.lifetime_organic_absorbed = scene.organic_required
			game.lifetime_mineral_absorbed = scene.mineral_required
			game.segments.append(_segment(Vector2.ZERO, Vector2(scene.hypha_world_required, 0), 0))
		"remote_pantry":
			game.lifetime_expedition_organic_returned = scene.organic_required
			game.lifetime_expedition_mineral_returned = scene.mineral_required
		"first_contact", "two_fronts", "stable_colony":
			while int(scene.runtime.data["mission_state"]["completed_waves"]) < scene.wave_sizes.size():
				var state: Dictionary = scene.runtime.data["mission_state"]
				if not bool(state["wave_active"]):
					_clear_modals()
					if not _check(game.campaign_ui.advance_mission(), "manual next wave can start only after previous wave is defeated"):
						return false
				var ids: Array = state["raider_ids"].duplicate()
				for id in ids:
					if not _check(game._damage_enemy_guard(int(id), 999.0), "controlled combat fixture records a real raider death"):
						return false
				scene.mission_tick(game, 0.001)
			var state: Dictionary = scene.runtime.data["mission_state"]
			game.lifetime_organic_absorbed = float(state["organic_baseline"]) + scene.organic_required
			game.lifetime_mineral_absorbed = float(state["mineral_baseline"]) + scene.mineral_required
			if scene.hypha_world_required > 0.0:
				game.segments.append(_segment(game.cores[0]["pos"], game.cores[0]["pos"] + Vector2(scene.hypha_world_required, 0), 0))
		"substrate_race":
			for center in [Vector2(520, -180), Vector2(520, 210)]:
				game.segments.append(_segment(Vector2.ZERO, center, 0))
			game.lifetime_organic_absorbed = scene.organic_required
			game.lifetime_mineral_absorbed = scene.mineral_required
		"lost_network":
			for center in [Vector2(420, -180), Vector2(510, 170)]:
				game.segments.append(_segment(Vector2.ZERO, center, 0))
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
		_: return _check(false, "unknown controlled objective fixture")
	return _check(scene.validate_mission_state(scene.runtime.data["mission_state"]) and game._campaign_mission_ready(), "fixture meets validated objectives without altering campaign completion flags")


func _buff_scope_and_trial_rollback() -> bool:
	_clear_modals()
	var home: Dictionary = game._capture_world_state()
	for branch_id in Campaign.BRANCH_IDS:
		if not _check(is_equal_approx(game._campaign_nest_multiplier(branch_id), 1.4), "level four plus two branch levels gives 40% at home: " + branch_id):
			return false
	if not _check(is_equal_approx(game._expedition_cargo_capacity({"unit_type": "carrier"}), 9.0 * 1.4) and is_equal_approx(game._passive_recovery_rate(), game.CORE_PASSIVE_RECOVERY_RATE * 1.5 * 1.4), "home bonuses affect real capacity and passive recovery hooks"):
		return false
	if not _check(game._campaign_start_mission("first_supply"), "completed first expedition remains replayable"):
		return false
	for branch_id in Campaign.BRANCH_IDS:
		if not _check(Campaign.branch_level(game.campaign, branch_id) == 2 and game._campaign_nest_multiplier(branch_id) == 1.0, "persistent branch ledger exists but grants no expedition effect"):
			return false
	if not _check(game._expedition_cargo_capacity({"unit_type": "carrier"}) == 9.0 and is_equal_approx(game._passive_recovery_rate(), game.CORE_PASSIVE_RECOVERY_RATE), "expedition actual hooks exclude home reinforcement and branch levels"):
		return false
	game.campaign["home_world"]["saved_at"] = Time.get_unix_time_from_system()
	if not _check(game._campaign_return("retreat") and _signature(game._capture_world_state()) == _signature(home), "expedition retreat restores the buffed home without importing expedition stock"):
		return false
	for mission_id in TRIALS:
		for outcome in ["retreat", "failure", "victory"]:
			_clear_modals()
			var before: Dictionary = game._capture_world_state()
			var ledger: Dictionary = game.campaign.duplicate(true)
			if not _check(game._campaign_start_mission(mission_id), mission_id + " replay starts for " + outcome + " rollback"):
				return false
			for branch_id in Campaign.BRANCH_IDS:
				if not _check(is_equal_approx(game._campaign_nest_multiplier(branch_id), 1.4), "home branch bonus remains effective in actual trial clone"):
					return false
			if not _check(game.campaign_ui.advance_mission(), "trial replay starts a real raider wave"):
				return false
			var guard: Dictionary = game.enemy_guard_spores[0]
			var unit: Dictionary = game.expedition_units[0]
			unit["pos"] = guard["pos"]
			unit["target_enemy_guard_id"] = guard["id"]
			var health_before: float = guard["biomass"]
			game._update_expedition_guard_attack(unit, 1.0)
			if not _check(is_equal_approx(health_before - float(guard["biomass"]), 0.025 * 1.4), "real basic-forager guard damage includes the defense branch and level-four bonus"):
				return false
			game.organic = 0.125
			game.mineral = 0.125
			game.dna = 99
			game.cores[0]["biomass"] = 1.125
			game.campaign["home_world"]["saved_at"] = Time.get_unix_time_from_system() - 72.0 * 3600.0
			if outcome == "failure":
				game.game_over = true
			elif outcome == "victory" and not _complete_fixture(mission_id):
				return false
			_clear_modals()
			if not _check(game._campaign_return(outcome), "trial allows " + outcome + " through real controller"):
				return false
			if not _check(not game.offline_settlement_active and not game.offline_report_open and _signature(game._capture_world_state()) == _signature(before), "trial " + outcome + " restores exact prebattle state without 72h extra offline income"):
				return false
			if not _check(game.campaign["materials"] == ledger["materials"] and game.campaign["branches"] == ledger["branches"] and Campaign.chapter_completed(game.campaign), "trial " + outcome + " changes neither earned materials nor permanent branches/completion"):
				return false
	return true


func _failed_phase_action(mission_id: String) -> bool:
	var before: Dictionary = _signature(game._capture_world_state())
	var ledger: Dictionary = game.campaign.duplicate(true)
	var disk := FileAccess.get_file_as_string(SLOT)
	if not _check(_block_save(), "obstruct the actual phase-action temporary save"):
		return false
	if not _check(not game.campaign_ui.advance_mission(), mission_id + " reports a real phase-action save failure"):
		return false
	if not _check(_signature(game._capture_world_state()) == before and _same(game.campaign, ledger) and FileAccess.get_file_as_string(SLOT) == disk, mission_id + " failed phase action rolls back wave/rescue state, entity arrays, RNG, ledger and committed bytes"):
		return false
	if not _check(game.campaign_ui.notice == game.campaign_ui.text("save_failed"), "failed phase action reports the localized persistence error"):
		return false
	_unblock_save()
	_clear_modals()
	return true


func _failed_branch_purchase(branch_id: String) -> bool:
	var before: Dictionary = _signature(game._capture_world_state())
	var ledger: Dictionary = game.campaign.duplicate(true)
	var disk := FileAccess.get_file_as_string(SLOT)
	if not _check(Campaign.can_purchase_branch(game.campaign, branch_id) and _block_save(), "branch is affordable before blocking its real save"):
		return false
	if not _check(not game.campaign_ui.purchase_branch(branch_id), "branch purchase reports a real commit failure"):
		return false
	if not _check(game.campaign == ledger and _signature(game._capture_world_state()) == before and FileAccess.get_file_as_string(SLOT) == disk, "failed branch purchase restores material balance and level without changing buffs, world or disk"):
		return false
	_unblock_save()
	_clear_modals()
	return true


func _failed_trial_departure(mission_id: String) -> bool:
	var before: Dictionary = _signature(game._capture_world_state())
	var ledger: Dictionary = game.campaign.duplicate(true)
	var disk := FileAccess.get_file_as_string(SLOT)
	var scene_id: int = game.active_world.get_instance_id()
	var runtime_id: int = game.world_runtime.get_instance_id()
	if not _check(_block_save(), "obstruct the trial departure temporary save"):
		return false
	if not _check(not game._campaign_start_mission(mission_id), mission_id + " reports a real clone-departure save failure"):
		return false
	if not _check(game.active_world.get_instance_id() == scene_id and game.world_runtime.get_instance_id() == runtime_id, "failed clone departure retains the original home scene and runtime objects"):
		return false
	if not _check(game.campaign == ledger and _signature(game._capture_world_state()) == before and FileAccess.get_file_as_string(SLOT) == disk, "failed clone departure restores original world, RNG, economy, progression and disk"):
		return false
	_unblock_save()
	_clear_modals()
	return true



func _mission_failure_ui() -> bool:
	_clear_modals()
	var home: Dictionary = game._capture_world_state()
	if not _check(game._campaign_start_mission("lost_network"), "failure UI fixture departs for the rescue mission"):
		return false
	_clear_modals()
	var ledger: Dictionary = game.campaign.duplicate(true)
	var disk := FileAccess.get_file_as_string(SLOT)
	var scene_id: int = game.active_world.get_instance_id()
	var relay_id: int = game.world_runtime.data["mission_state"]["relay_id"]
	game._damage_core(relay_id, 999.0, "environment_pressure")
	if not _check(not game._is_core_alive(relay_id) and game._is_core_alive(0) and game._living_core_count() > 0 and not game.game_over, "only the mission-critical relay dies while the expedition's main core survives"):
		return false
	game.sim_speed = 1.0
	game._process(0.001)
	if not _check(game.game_over and game.active_world.mission_failed(game) and game._is_core_alive(0), "normal Main processing recognizes a failed objective despite a surviving core"):
		return false
	if not _check(game.campaign_ui.progress_hint_key() == "mission_failed_hint", "failed rescue uses the objective-failure HUD hint rather than an all-cores-dead claim"):
		return false
	var hud: Array = game.campaign_ui.progress_hud_lines(Rect2(0, 0, 208, 110))
	var has_failure_hint := false
	for line in hud:
		has_failure_hint = has_failure_hint or line["text"] == game.campaign_ui.chapter_text("mission_failed_hint")
	if not _check(has_failure_hint and game.campaign_ui.chapter_text("mission_failed_hint").contains("[J]"), "the actual HUD resolves the localized failure shortcut"):
		return false
	game._process(0.001)
	if not _check(game.campaign_ui.open and game.campaign_ui.failure_presented, "the failed mission presents its return panel once"):
		return false
	game.campaign_ui.open = false
	var failed_world: Dictionary = _signature(game._capture_world_state())
	var viewport: Vector2 = game.get_viewport_rect().size
	game._handle_game_over_click(game._game_over_button_rect(viewport, 0).get_center())
	if not _check(game.campaign_ui.open and not game.pause_menu_open and game._campaign_active() and game.active_world.get_instance_id() == scene_id, "game-over primary button opens the return panel without a new culture or restart confirmation"):
		return false
	if not _check(game.campaign == ledger and _signature(game._capture_world_state()) == failed_world and FileAccess.get_file_as_string(SLOT) == disk, "opening the failure panel changes neither checkpoint, progression, failed world nor saved mission"):
		return false
	if not _check(game.campaign_ui.return_home("failure") and _signature(game._capture_world_state()) == _signature(home), "failed critical objective still restores the exact archived home"):
		return false
	if not _check(not game.game_over and Campaign.chapter_completed(game.campaign) and game.campaign["materials"] == ledger["materials"], "failure returns without inventing a reward or damaging completed chapter progression"):
		return false
	return true


func _block_save() -> bool:
	var path := ProjectSettings.globalize_path(SaveStore.temp_path(SLOT))
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.make_dir_absolute(path) == OK


func _unblock_save() -> void:
	var path := ProjectSettings.globalize_path(SaveStore.temp_path(SLOT))
	if DirAccess.dir_exists_absolute(path):
		DirAccess.remove_absolute(path)


func _segment(a: Vector2, b: Vector2, core_id: int) -> Dictionary:
	return {"a": a, "b": b, "core_id": core_id, "growth": 1.0, "curve": 0.0, "orphaned": false, "viability": 1.0}


func _runner() -> Node:
	var runner: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(runner)
	await process_frame
	runner.set_process(false)
	runner.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	runner.pixel_audio.ambient_player.stop()
	runner.splash_active = false
	runner.autosave_enabled = false
	runner.developer_mode_enabled = false
	runner.save_path = SLOT
	runner.main_menu_active = false
	runner.game_started = true
	return runner


func _clear_modals() -> void:
	game.campaign_ui.reset_panel()
	game.main_menu_active = false
	game.pause_menu_open = false
	game.upgrade_open = false
	game.goals_open = false
	game.barracks_production_open = false
	game.chapter_report_open = false
	game.offline_report_open = false


func _signature(world: Dictionary) -> Dictionary:
	var copy := world.duplicate(true)
	copy.erase("saved_at")
	copy.erase("campaign")
	return JSON.parse_string(JSON.stringify(copy))


func _same(left: Variant, right: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(left)) == JSON.parse_string(JSON.stringify(right))


func _read_json() -> Dictionary:
	var payload = JSON.parse_string(FileAccess.get_file_as_string(SLOT))
	return payload if payload is Dictionary else {}


func _write_json(payload: Dictionary) -> bool:
	var file := FileAccess.open(SLOT, FileAccess.WRITE)
	if file == null:
		return false
	var written := file.store_string(JSON.stringify(payload))
	file.close()
	return written


func _dispose() -> void:
	for player in game.pixel_audio.players:
		player.stop()
		player.stream = null
	game.pixel_audio.ambient_player.stop()
	game.pixel_audio.ambient_player.stream = null
	game.queue_free()
	await process_frame


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if condition:
		return true
	push_error("CAMPAIGN_FULL_INTEGRATION_FAIL: " + message)
	_unblock_save()
	quit(1)
	return false
