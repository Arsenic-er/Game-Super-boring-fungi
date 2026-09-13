extends SceneTree

const CampaignState = preload("res://scripts/campaign_state.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const SLOT := "user://campaign_flow_smoke.json"
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
	game.save_path = SLOT
	game._start_new_culture()
	game.campaign = CampaignState.fresh()
	game.main_menu_active = false
	game.game_started = true
	if not _check(not game._campaign_start_mission(), "a mobile founder cannot leave for a mission"):
		return
	game._complete_founder_spore_germination()
	game.selected_core = -1
	game._damage_core(0, 7.125, "environment_pressure")
	if not _check(game._queue_dna(0, 2), "home preparation prepays two real DNA jobs"):
		return
	game._developer_spawn_resource(Vector2(37.0, 51.0), 1, 9.875)
	game.resources[0]["amount"] = 2.125
	game.absorb_clock = 0.375
	game.bacteria_update_clock = 0.125
	var home: Dictionary = game._capture_world_state()
	var detached: Dictionary = game._capture_world_state()
	detached["cores"][0]["jobs"][0]["remaining"] = 9999.0
	detached["resource_catalog"][0]["amount"] = 9999.0
	detached["structure_levels"]["branching"] = 4
	if not _check(_signature(game._capture_world_state()) == _signature(home), "capture detaches nested queues, resources and upgrades"):
		return
	if not _check(game._save_game(), "home checkpoint commits before departure"):
		return
	for locale_id in ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]:
		game.settings_locale = locale_id
		for viewport in [Vector2(1280, 720), Vector2(960, 540), Vector2(640, 360)]:
			var panel: Rect2 = game.campaign_ui.panel_rect(viewport)
			if not _check(Rect2(Vector2.ZERO, viewport).encloses(panel), "%s panel inside %s" % [locale_id, viewport]):
				return
			var previous := Rect2()
			for index in range(3):
				var button: Rect2 = game.campaign_ui.button_rect(viewport, index)
				if not _check(panel.encloses(button) and (index == 0 or not previous.intersects(button)), "%s button %d fits without overlap" % [locale_id, index]):
					return
				previous = button
	game.settings_locale = "en"
	var key := InputEventKey.new()
	key.keycode = KEY_J
	key.pressed = true
	game._unhandled_input(key)
	if not _check(game.campaign_ui.open, "J opens the campaign panel through the real input entry"):
		return
	if not _check(_click(game, 2) and not game.campaign_ui.open, "close button consumes its click and closes the panel"):
		return
	game.pause_menu_open = true
	if not _check(not game._campaign_start_mission(), "pause modal blocks departure"):
		return
	game.pause_menu_open = false
	game.offline_report_open = true
	if not _check(not game._campaign_start_mission(), "offline report blocks departure"):
		return
	game.offline_report_open = false
	if not _check(game._campaign_start_mission(), "settled home can enter first_supply"):
		return
	if not _check(game._campaign_active() and game.campaign["active_mission"]["id"] == "first_supply", "first supply has an active stable mission ID"):
		return
	if not _check(is_equal_approx(game.organic, 220.0) and is_equal_approx(game.mineral, 24.0) and game.dna == 0 and game.cores.size() == 1 and game.diet_order.is_empty() and game.enemy_fungi.is_empty(), "mission starts with its own resources and one healthy noncombat colony"):
		return
	if not _check(float(game.cores[0]["biomass"]) == 100.0 and (game.cores[0]["jobs"] as Array).is_empty(), "home damage and orders do not leak into mission"):
		return
	if not _check(_signature(game.campaign["home_world"]) == _signature(home) and not game.campaign["home_world"].has("campaign"), "home snapshot remains independent and is not recursively nested"):
		return
	var serial: int = game.campaign["serial"]
	if not _check(not game._campaign_start_mission() and int(game.campaign["serial"]) == serial, "cannot start a second mission inside an active mission"):
		return
	if not _check(not game._campaign_return("victory") and not game._campaign_return("failure") and not game._campaign_return("unknown"), "premature victory, false failure and unknown outcomes are rejected"):
		return
	game.campaign_ui.open = false
	# This route uses the actual mission map and starting stock. No resources,
	# counters, upgrade levels, feeder growth or outcomes are injected here.
	var paid := 0.0
	var origin: Vector2 = game.cores[0]["pos"]
	for offset in [Vector2(270, -40), Vector2(-210, 195), Vector2(0, -240)]:
		game.selected_core = 0
		game.selected_tip_valid = false
		var count_before: int = game.segments.size()
		var stock_before: float = game.organic
		game._confirm_extension(origin + offset)
		if not _check(game.segments.size() == count_before + 1 and game.organic < stock_before, "normal route pays for branch toward %s" % offset):
			return
		paid += stock_before - game.organic
	game.selected_core = -1
	var route_started := Time.get_ticks_msec()
	while not game._campaign_mission_ready() and game.sim_time < 3600.0:
		game._process(0.25)
		if Time.get_ticks_msec() - route_started > 30000:
			break
	if not _check(game._campaign_mission_ready() and not game.game_over, "actual paid growth and natural absorption can complete first_supply within 3600 simulated seconds / 30s wall budget"):
		print("CAMPAIGN_ROUTE_DIAGNOSTIC sim=%.3f organic=%.3f mineral=%.3f absorbed=%.3f/%.3f length=%.3f feeders=%d" % [game.sim_time, game.organic, game.mineral, game.lifetime_organic_absorbed, game.lifetime_mineral_absorbed, game._chapter_living_hypha_length(), game.feeders.size()])
		return
	if not _check(game.lifetime_organic_absorbed >= 360.0 and game.lifetime_mineral_absorbed >= 18.0 and game._chapter_living_hypha_length() >= 600.0, "completion came from actual income and mature living network, not starting stock"):
		return
	print("CAMPAIGN_REAL_ROUTE sim_seconds=%.3f paid_organic=%.3f absorbed_organic=%.3f absorbed_mineral=%.3f living_hypha=%.3f wall_ms=%d" % [game.sim_time, paid, game.lifetime_organic_absorbed, game.lifetime_mineral_absorbed, game._chapter_living_hypha_length(), Time.get_ticks_msec() - route_started])
	if not _check(game._campaign_return("victory") and not game._campaign_active(), "real completion returns to the persistent home"):
		return
	if not _check(not game.offline_settlement_active and _same_world(game._capture_world_state(), home), "short real mission restores home resources, damage, queues, map and RNG exactly"):
		return
	if not _check(int(game.campaign["materials"]) == 3 and bool(game.campaign["completed"].get("first_supply", false)), "first victory awards exactly three unique materials"):
		return
	if not _check(not game._campaign_return("victory") and int(game.campaign["materials"]) == 3, "double return cannot issue duplicate rewards"):
		return
	game.campaign_ui.open = true
	if not _check(_click(game, 1) and int(game.campaign["nest_level"]) == 2 and int(game.campaign["materials"]) == 0, "real panel upgrades the nest once using its three materials"):
		return
	if not _check(not game._campaign_upgrade() and _signature(game._capture_world_state()) == _signature(home), "maximum-level upgrade cannot spend DNA or home resources"):
		return
	game.campaign_ui.open = false
	if not _check(game._campaign_start_mission(), "completed supply mission can be replayed"):
		return
	_controlled_ready(game)
	game.dna = 77
	if not _check(game._campaign_return("victory") and int(game.campaign["materials"]) == 0 and _signature(game._capture_world_state()) == _signature(home), "controlled replay checks no repeat materials and no mission DNA transfer"):
		return
	game.campaign_ui.open = false
	if not _check(game._campaign_start_mission(), "third attempt is available for retreat input"):
		return
	game.campaign_ui.open = true
	if not _check(_click(game, 1) and game._campaign_active(), "retreat first requests confirmation"):
		return
	if not _check(_click(game, 1) and game._campaign_active(), "cancel keeps the same mission active"):
		return
	if not _check(_click(game, 1) and _click(game, 0) and not game._campaign_active(), "confirmed retreat returns without granting materials"):
		return
	if not _check(int(game.campaign["materials"]) == 0 and _signature(game._capture_world_state()) == _signature(home), "retreat does not change the home or reward balance"):
		return
	game.campaign_ui.open = false
	if not _check(game._campaign_start_mission(), "fourth attempt is available for real failure"):
		return
	game.campaign_ui.open = false
	game._damage_core(0, 10000.0, "environment_pressure")
	game._process(0.01)
	if not _check(game.game_over and game.campaign_ui.open, "all mission cores dying opens the return panel"):
		return
	if not _check(_click(game, 0) and not game._campaign_active() and not game.game_over, "failure button restores surviving home instead of ending the whole save"):
		return
	if not _check(_signature(game._capture_world_state()) == _signature(home) and int(game.campaign["materials"]) == 0, "failure preserves home and does not award materials"):
		return
	print("CAMPAIGN_FLOW_OK checks=%d normal_route=true outcomes=victory+retreat+failure reward=once upgrade=1-to-2 ui=7x3+mouse+J" % checks)
	SaveStore.remove_slot(SLOT)
	await _dispose(game)
	quit(0)

func _controlled_ready(game: Node) -> void:
	# Only repeated-reward boundaries use injected counters; the first victory above does not.
	game.lifetime_organic_absorbed = 360.0
	game.lifetime_mineral_absorbed = 18.0
	for target in [Vector2(240, 0), Vector2(-240, 0), Vector2(0, 240)]:
		game.selected_core = 0
		game.selected_tip_valid = false
		game._confirm_extension(target)
	game._update_growth(24.0)

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

func _click(game: Node, index: int) -> bool:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = game.campaign_ui.button_rect(game.get_viewport_rect().size, index).get_center()
	return game.campaign_ui.handle_input(event)

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
	push_error("CAMPAIGN_FLOW_FAIL: " + message)
	SaveStore.remove_slot(SLOT)
	quit(1)
	return false
