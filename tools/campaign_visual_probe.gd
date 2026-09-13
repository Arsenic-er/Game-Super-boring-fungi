extends Node

# Render-only fixtures, never evidence for mission reachability, timings or balance.
# The real Main scene and campaign controller draw every captured interface.
# Completing germination, maturing hyphae, absorption counters and death below are
# deliberate fixture setup. Any save written by real campaign actions is isolated.
# FUNGI_VISUAL_OUT must name an absolute output directory. --validate-only checks
# the same fixtures without claiming that the headless driver rendered any pixels.
const MainScene: PackedScene = preload("res://scenes/Main.tscn")
const Words = preload("res://scripts/campaign_localization.gd")
const FRAME_TIMEOUT_MS := 5000
const PROBE_TIMEOUT_MS := 120000

var game: Node
var output_dir := ""
var fixture_save_dir := ""
var validate_only := false
var captures: Array[Dictionary] = []
var started_ms := 0
var frame_drawn := false
var finishing := false
var failure := ""
@onready var window: Window = get_tree().root


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	output_dir = OS.get_environment("FUNGI_VISUAL_OUT").replace("\\", "/")
	validate_only = OS.get_cmdline_user_args().has("--validate-only")
	if output_dir.is_empty() or not output_dir.is_absolute_path():
		await _finish(false, "FUNGI_VISUAL_OUT must be an absolute directory")
		return
	if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		await _finish(false, "Cannot create FUNGI_VISUAL_OUT")
		return
	fixture_save_dir = output_dir.path_join("fixture-save-%s-%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	if DirAccess.make_dir_recursive_absolute(fixture_save_dir) != OK:
		await _finish(false, "Cannot create isolated fixture save directory")
		return
	print("CAMPAIGN_VISUAL_PROBE_START mode=%s output=%s" % ["validate-only" if validate_only else "render", output_dir])
	print("CAMPAIGN_VISUAL_FIXTURE not-economic-evidence=true isolated-save=" + fixture_save_dir)
	game = MainScene.instantiate()
	# Assign before _ready inspects saves, then restore after settings are read in
	# case the user's saved developer preference temporarily selects its own path.
	game.save_path = fixture_save_dir.path_join("campaign-visual.json")
	game.autosave_enabled = false
	window.add_child(game)
	game.set_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	game.developer_mode_enabled = false
	game.save_path = fixture_save_dir.path_join("campaign-visual.json")
	game.autosave_enabled = false
	game.settings_fullscreen = false
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if game.pixel_audio != null:
		game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.splash_active = false
	game.first_locale_prompt = false
	game.main_menu_active = false
	game.pause_menu_open = false
	game.game_started = true
	game.selected_core = -1
	game.selected_tip_valid = false
	game.camera_center = Vector2.ZERO
	game.camera_zoom = 0.9
	await _resize(Vector2i(1280, 720))
	game.campaign_ui.show_panel()
	for locale in Words.LOCALES:
		game.settings_locale = locale
		game.campaign_ui.scroll = 0
		if not await _capture("home_" + locale, "home-initial"):
			await _finish(false, failure)
			return

	game.campaign_ui.reset_panel()
	if not game._campaign_start_mission():
		await _finish(false, "Real campaign start failed in isolated fixture")
		return
	# Real paid extension commands construct the geometry; maturation and totals
	# are explicitly injected for display, not simulated economic progression.
	game.selected_core = 0
	for target in [Vector2(250, -50), Vector2(-180, 170), Vector2(180, 190)]:
		game._confirm_extension(target)
	for segment in game.segments:
		segment["growth"] = 1.0
	game._update_exploration(false)
	game.selected_core = -1
	game.selected_tip_valid = false
	game.lifetime_organic_absorbed = 180.125
	game.lifetime_mineral_absorbed = 7.875
	for locale in ["zh_CN", "en"]:
		game.settings_locale = locale
		game.campaign_ui.reset_panel()
		if not await _capture("mission_hud_" + locale, "mission-partial-counters-fixture"):
			await _finish(false, failure)
			return
		game.campaign_ui.show_panel()
		if not await _capture("mission_panel_" + locale, "mission-partial-counters-fixture"):
			await _finish(false, failure)
			return
	game.lifetime_organic_absorbed = 360.0
	game.lifetime_mineral_absorbed = 18.0
	if not game._campaign_mission_ready():
		await _finish(false, "Ready-state rendering fixture did not satisfy the real predicate")
		return
	for locale in ["zh_CN", "en"]:
		game.settings_locale = locale
		game.campaign_ui.show_panel()
		if not await _capture("mission_ready_" + locale, "mission-ready-counters-fixture"):
			await _finish(false, failure)
			return

	await _resize(Vector2i(640, 360))
	for locale in ["es", "ru"]:
		game.settings_locale = locale
		game.campaign_ui.reset_panel()
		if not await _capture("compact_hud_" + locale, "mission-ready-compact"):
			await _finish(false, failure)
			return
		game.campaign_ui.show_panel()
		if not await _capture("compact_panel_top_" + locale, "mission-ready-compact"):
			await _finish(false, failure)
			return
		# Use the real wheel handler to reach the bottom; draw_panel clamps the
		# scroll offset. Fixed action buttons must stay visible and interactive.
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		wheel.position = game.campaign_ui.panel_rect(game.get_viewport_rect().size).get_center()
		for _index in range(40):
			game.campaign_ui.handle_input(wheel)
		game.last_mouse = game.campaign_ui.button_rect(game.get_viewport_rect().size, 0).get_center()
		if not await _capture("compact_panel_bottom_" + locale, "mission-ready-compact-scrolled"):
			await _finish(false, failure)
			return
		game.campaign_ui.activate(1)
		game.last_mouse = game.campaign_ui.button_rect(game.get_viewport_rect().size, 0).get_center()
		if not game.campaign_ui.confirm_retreat or not await _capture("compact_retreat_confirm_" + locale, "retreat-confirmation"):
			await _finish(false, failure if not failure.is_empty() else "Retreat confirmation did not open")
			return
		game.campaign_ui.activate(1)

	await _resize(Vector2i(1280, 720))
	game.campaign_ui.reset_panel()
	if not game._campaign_return("victory"):
		await _finish(false, "Real return action failed in isolated render fixture")
		return
	if not await _finish_home_settlement():
		await _finish(false, failure)
		return
	for locale in ["zh_CN", "en"]:
		game.settings_locale = locale
		game.campaign_ui.show_panel()
		if not await _capture("home_reward_" + locale, "reward-from-injected-ready-fixture"):
			await _finish(false, failure)
			return
	if not game._campaign_upgrade():
		await _finish(false, "Nest upgrade failed in isolated render fixture")
		return
	for locale in Words.LOCALES:
		game.settings_locale = locale
		game.campaign_ui.show_panel()
		if not await _capture("home_level2_story_" + locale, "nest-level2-from-fixture-reward"):
			await _finish(false, failure)
			return

	game.campaign_ui.reset_panel()
	if not game._campaign_start_mission():
		await _finish(false, "Retry mission start failed in isolated fixture")
		return
	# Death is an explicit rendering fixture; there is no fabricated combat proof.
	for core in game.cores:
		core["biomass"] = 0.0
		core["alive"] = false
	game.game_over = true
	game._process(0.0)
	for locale in ["zh_CN", "en"]:
		game.settings_locale = locale
		game.campaign_ui.show_panel()
		if not await _capture("mission_failed_" + locale, "dead-colony-fixture"):
			await _finish(false, failure)
			return
	game.campaign_ui.activate(2)
	game._process(0.0)
	if game.campaign_ui.open:
		await _finish(false, "Failure panel reopened after its Close button")
		return
	if not await _capture("mission_failed_closed_en", "dead-colony-panel-dismissed"):
		await _finish(false, failure)
		return
	await _finish(true, "")


func _resize(size: Vector2i) -> void:
	window.content_scale_size = size
	window.size = size
	await get_tree().process_frame
	await get_tree().process_frame


func _finish_home_settlement() -> bool:
	# Rendering may itself take enough wall time to trigger the real home-return
	# settlement. Finish only this tiny isolated interval, never a normal save.
	var deadline := Time.get_ticks_msec() + 10000
	while game.offline_settlement_active and Time.get_ticks_msec() < deadline:
		game._pump_offline_progress()
		await get_tree().process_frame
	if game.offline_settlement_active:
		failure = "Isolated home return did not finish within 10 seconds"
		return false
	if game.offline_report_open:
		game._close_offline_report()
	return true


func _capture(label: String, fixture: String) -> bool:
	if Time.get_ticks_msec() - started_ms > PROBE_TIMEOUT_MS:
		failure = "Render probe exceeded its 120-second bound"
		return false
	game.toast_time = 0.0
	game.discovery_banner_time = 0.0
	game.ecology_banner_time = 0.0
	game.queue_redraw()
	await get_tree().process_frame
	var viewport: Vector2 = game.get_viewport_rect().size
	if not viewport.is_equal_approx(Vector2(window.content_scale_size)):
		failure = "Requested layout size differs from actual viewport: " + str(viewport)
		return false
	var item: Dictionary = {
		"label": label, "locale": game.settings_locale, "fixture": fixture,
		"viewport": [viewport.x, viewport.y], "window": [window.size.x, window.size.y],
		"rendered": false, "panel_open": game.campaign_ui.open,
		"scroll": game.campaign_ui.scroll, "mission_active": game._campaign_active(),
		"mission_ready": game._campaign_mission_ready(), "game_over": game.game_over,
		"nest_level": game.campaign.nest_level,
		"labels": game.campaign_ui.action_labels(),
		"enabled": [game.campaign_ui.action_enabled(0), game.campaign_ui.action_enabled(1), game.campaign_ui.action_enabled(2)]
	}
	if validate_only:
		captures.append(item)
		print("CAMPAIGN_FIXTURE_VALIDATED " + label + " viewport=" + str(viewport))
		return true
	if DisplayServer.get_name() == "headless":
		failure = "Use a real rendering driver for PNG capture, or --validate-only"
		return false
	# Subscribe BEFORE force_draw: hidden windows may not draw spontaneously, and
	# force_draw can emit the signal synchronously. Waiting afterward can miss it.
	frame_drawn = false
	RenderingServer.frame_post_draw.connect(_frame_finished, CONNECT_ONE_SHOT)
	RenderingServer.force_draw(false)
	var deadline := Time.get_ticks_msec() + FRAME_TIMEOUT_MS
	while not frame_drawn and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if not frame_drawn:
		if RenderingServer.frame_post_draw.is_connected(_frame_finished):
			RenderingServer.frame_post_draw.disconnect(_frame_finished)
		failure = "No frame_post_draw within 5 seconds: " + label
		return false
	var rendered := window.get_texture().get_image()
	if rendered == null or rendered.is_empty():
		failure = "No rendered pixels: " + label
		return false
	if rendered.get_size() != window.size:
		failure = "Captured pixel dimensions differ from requested window: " + label
		return false
	if rendered.save_png(output_dir.path_join(label + ".png")) != OK:
		failure = "Could not save PNG: " + label
		return false
	item["rendered"] = true
	item["pixels"] = [rendered.get_width(), rendered.get_height()]
	item["scroll"] = game.campaign_ui.scroll
	captures.append(item)
	print("CAMPAIGN_RENDER_CAPTURE " + label + " pixels=" + str(rendered.get_size()) + " viewport=" + str(viewport))
	return true


func _frame_finished() -> void:
	frame_drawn = true


func _finish(ok: bool, reason: String) -> void:
	if finishing:
		return
	finishing = true
	if RenderingServer.frame_post_draw.is_connected(_frame_finished):
		RenderingServer.frame_post_draw.disconnect(_frame_finished)
	if is_instance_valid(game):
		game.autosave_enabled = false
		game.game_started = false
		if game.pixel_audio != null:
			for player in game.pixel_audio.players:
				player.stop()
				player.stream = null
			if game.pixel_audio.ambient_player != null:
				game.pixel_audio.ambient_player.stop()
				game.pixel_audio.ambient_player.stream = null
		game.queue_free()
		await get_tree().process_frame
		await get_tree().create_timer(0.25).timeout
	if not output_dir.is_empty() and DirAccess.dir_exists_absolute(output_dir):
		var manifest := FileAccess.open(output_dir.path_join("campaign-capture-manifest.json"), FileAccess.WRITE)
		if manifest != null:
			manifest.store_string(JSON.stringify({
				"ok": ok, "mode": "validate-only" if validate_only else "render", "failure": reason,
				"not_economic_evidence": true, "fixture_save_dir": fixture_save_dir,
				"fixture_notes": "Germination, mature hyphae, absorption totals and colony death are explicit display fixtures. Do not use these saves as normal gameplay evidence.",
				"captures": captures
			}, "  "))
			manifest.close()
		else:
			ok = false
			reason = "Cannot write capture manifest"
	if ok:
		print(("CAMPAIGN_VISUAL_PROBE_VALIDATED" if validate_only else "CAMPAIGN_VISUAL_PROBE_OK") + " captures=" + str(captures.size()) + " renderer=" + RenderingServer.get_current_rendering_method())
	else:
		push_error("CAMPAIGN_VISUAL_PROBE_FAIL " + reason)
	get_tree().quit(0 if ok else 1)
