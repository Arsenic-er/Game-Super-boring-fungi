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
const PROBE_TIMEOUT_MS := 240000

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
	await _resize(Vector2i(640, 360))
	for locale in Words.LOCALES:
		game.settings_locale = locale
		game.campaign_ui.reset_panel()
		if not await _capture("compact_progress_" + locale, "mission-partial-compact"):
			await _finish(false, failure)
			return
	await _resize(Vector2i(1280, 720))
	game.lifetime_organic_absorbed = 360.0
	game.lifetime_mineral_absorbed = 18.0
	if not game._campaign_mission_ready():
		await _finish(false, "Ready-state rendering fixture did not satisfy the real predicate")
		return
	for locale in ["zh_CN", "en"]:
		game.settings_locale = locale
		game.campaign_ui.reset_panel()
		if not await _capture("mission_ready_hud_" + locale, "mission-ready-hud"):
			await _finish(false, failure)
			return
		game.campaign_ui.show_panel()
		if not await _capture("mission_ready_" + locale, "mission-ready-counters-fixture"):
			await _finish(false, failure)
			return

	await _resize(Vector2i(640, 360))
	for locale in Words.LOCALES:
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

	if not await _capture_remote_pantry():
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
	if not await _capture_chapter_roster():
		await _finish(false, failure)
		return
	if not await _capture_developer_campaign():
		await _finish(false, failure)
		return
	await _finish(true, "")


func _capture_remote_pantry() -> bool:
	await _resize(Vector2i(640, 360))
	for locale in Words.LOCALES:
		game.settings_locale = locale
		game.campaign_ui.show_panel()
		if not await _capture("pantry_selection_640_" + locale, "two-mission-selector"):
			return false
	game.campaign_ui.reset_panel()
	if not game._campaign_start_mission("remote_pantry"):
		failure = "Remote pantry fixture departure failed"
		return false
	# Explicit display-only partial cargo; the economic route has a separate test.
	game.lifetime_expedition_organic_returned = 12.345
	game.lifetime_expedition_mineral_returned = 0.125
	for size in [Vector2i(1280, 720), Vector2i(640, 360)]:
		await _resize(size)
		for locale in Words.LOCALES:
			game.settings_locale = locale
			game.campaign_ui.reset_panel()
			if not await _capture("pantry_hud_%d_%s" % [size.x, locale], "transport-counter-display-fixture"):
				return false
			game.campaign_ui.show_panel()
			if not await _capture("pantry_panel_%d_%s" % [size.x, locale], "transport-counter-display-fixture"):
				return false
	game.campaign_ui.reset_panel()
	if not game._campaign_return("retreat"):
		failure = "Remote pantry fixture retreat failed"
		return false
	if not await _finish_home_settlement():
		return false
	await _resize(Vector2i(1280, 720))
	return true


func _capture_chapter_roster() -> bool:
	# Explicit display fixture: unlock the roster to exercise every real selector.
	# No claim of earned mission rewards or economic progression is made here.
	game.campaign_ui.reset_panel()
	game.developer_mode_enabled = false
	game.pause_menu_open = false
	game.chapter_report_open = false
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.main_menu_active = false
	game.game_started = true
	game.campaign["nest_level"] = 4
	game.campaign["materials"] = 9
	for entry in game.campaign_ui.Catalog.entries():
		if entry["id"] != "stable_colony":
			game.campaign["completed"][entry["id"]] = true
	if not await _capture_home_pages():
		return false
	# Exercise actual branch hit targets and transactions on the isolated slot.
	game.campaign_ui.show_panel()
	var viewport: Vector2 = game.get_viewport_rect().size
	for index in range(3):
		var id: String = ["transport", "resilience", "defense"][index]
		_click(game.campaign_ui.branch_rect(viewport, index).get_center())
		if int(game.campaign["branches"][id]) != 1:
			failure = "A home construction branch is not reachable by its displayed control: " + id
			return false
	for size in [Vector2i(1280, 720), Vector2i(640, 360)]:
		await _resize(size)
		for locale in Words.LOCALES:
			game.settings_locale = locale
			game.campaign_ui.show_panel()
			if not await _capture("chapter_branches_%d_%s" % [size.x, locale], "three-real-purchases-on-unlocked-display-fixture"):
				return false
	for entry in game.campaign_ui.Catalog.entries():
		var id: String = entry["id"]
		if id in ["first_supply", "remote_pantry"]:
			continue
		game.campaign_ui.reset_panel()
		if not game._campaign_start_mission(id):
			failure = "New mission display fixture cannot enter its independent scene: " + id
			return false
		if not await _capture_new_mission(id, "initial"):
			return false
		if entry["kind"] == "nest_challenge":
			# A genuine persisted JSON restore must retain the preparation action.
			var snapshot: Dictionary = JSON.parse_string(JSON.stringify(game._capture_world_state()))
			if not game._restore_world_state(snapshot):
				failure = "Trial preparation restore failed: " + id
				return false
			game.campaign_ui.show_panel()
			var key: String = game.campaign_ui._phase_action_key()
			if key != "trial_start_wave":
				failure = "Trial start control missing after JSON restore: " + id
				return false
			_click(game.campaign_ui.phase_action_rect(game.get_viewport_rect().size).get_center())
			if game.enemy_guard_spores.is_empty() or not bool(game.world_runtime.data.get("mission_state", {}).get("wave_active", false)):
				failure = "Displayed trial stage button did not start a real wave: " + id
				return false
			if not await _capture_new_mission(id, "wave"):
				return false
		game.campaign_ui.reset_panel()
		if not game._campaign_return("retreat") or not await _finish_home_settlement():
			failure = "New mission render fixture cannot return home: " + id
			return false
	# Chapter completion is an explicit display-only fixture, not a fabricated win.
	game.campaign["completed"]["stable_colony"] = true
	for size in [Vector2i(1280, 720), Vector2i(640, 360)]:
		await _resize(size)
		for locale in Words.LOCALES:
			game.settings_locale = locale
			game.campaign_ui.show_panel()
			if not game.campaign_ui.paragraphs().has(game.campaign_ui.chapter_text("chapter_end")):
				failure = "Completed chapter story is absent from the real panel"
				return false
			if not await _capture("chapter_complete_%d_%s" % [size.x, locale], "completed-ledger-display-fixture"):
				return false
	return true


func _capture_home_pages() -> bool:
	for size in [Vector2i(1280, 720), Vector2i(640, 360)]:
		await _resize(size)
		for locale in Words.LOCALES:
			game.settings_locale = locale
			game.campaign_ui.show_panel()
			# Navigate using actual hit targets, including backwards from the
			# recommended final mission to the first page.
			var viewport: Vector2 = game.get_viewport_rect().size
			for _step in range(5):
				_click(game.campaign_ui.page_rect(viewport, -1).get_center())
			var reached: Array[String] = []
			var choices: Array[String] = game.campaign_ui._mission_choices()
			for page in range(5):
				if game.campaign_ui.selection_start != page * 2:
					failure = "Roster page navigation failed"
					return false
				for index in range(mini(2, choices.size() - page * 2)):
					var expected: String = choices[page * 2 + index]
					_click(game.campaign_ui.selection_rect(viewport, index).get_center())
					if game.campaign_ui.selected_mission_id != expected:
						failure = "Roster mission not reachable by displayed selection: " + expected
						return false
					reached.append(expected)
				if not await _capture("chapter_home_page%d_%d_%s" % [page + 1, size.x, locale], "nine-mission-real-click-selector"):
					return false
				_click(game.campaign_ui.page_rect(viewport, 1).get_center())
			if reached != choices or game.campaign_ui.selection_start != 8:
				failure = "Not all nine missions are reachable, or final page exceeds bounds"
				return false
	return true


func _capture_new_mission(id: String, phase: String) -> bool:
	for size in [Vector2i(1280, 720), Vector2i(640, 360)]:
		await _resize(size)
		for locale in Words.LOCALES:
			game.settings_locale = locale
			game.campaign_ui.reset_panel()
			if not await _capture("chapter_%s_%s_hud_%d_%s" % [id, phase, size.x, locale], "new-independent-mission-" + phase):
				return false
			game.campaign_ui.show_panel()
			if not await _capture("chapter_%s_%s_panel_%d_%s" % [id, phase, size.x, locale], "new-independent-mission-" + phase):
				return false
			if not _scroll_to_mission_goals():
				return false
			if not await _capture("chapter_%s_%s_goals_%d_%s" % [id, phase, size.x, locale], "new-independent-mission-goals-" + phase):
				return false
			if not _check_scroll_reachability():
				return false
	return true


func _scroll_to_mission_goals() -> bool:
	var ui = game.campaign_ui
	var viewport: Vector2 = game.get_viewport_rect().size
	var body: Dictionary = ui.panel_body_layout(viewport)
	var target := 0
	var found := false
	for paragraph in ui.paragraphs():
		if paragraph == ui.progress_text():
			found = true
			break
		target += game._wrap_guide_text(paragraph, body["width"], body["font_size"]).size() + 1
	if not found:
		failure = "Mission progress paragraph cannot be reached"
		return false
	var target_scroll := mini(target, int(body["max_scroll"]))
	while ui.scroll < target_scroll:
		_scroll_down()
	ui.scroll = clampi(ui.scroll, 0, int(body["max_scroll"]))
	if target < ui.scroll or target >= ui.scroll + int(body["visible"]):
		# Wheel moves by two lines. One upward key event still uses the real
		# handler; visible ranges overlap at normal and compact sizes.
		var event := InputEventKey.new()
		event.pressed = true
		event.keycode = KEY_UP
		ui.handle_input(event)
		ui.scroll = clampi(ui.scroll, 0, int(body["max_scroll"]))
	if target < ui.scroll or target >= ui.scroll + int(body["visible"]):
		failure = "Mission progress text is not within the scrolled visible range"
		return false
	return true


func _check_scroll_reachability() -> bool:
	var ui = game.campaign_ui
	var body: Dictionary = ui.panel_body_layout(game.get_viewport_rect().size)
	for _step in range(int(body["max_scroll"]) / 2 + 3):
		_scroll_down()
	ui.scroll = clampi(ui.scroll, 0, int(body["max_scroll"]))
	if ui.scroll != int(body["max_scroll"]) or ui.scroll + int(body["visible"]) < body["lines"].size():
		failure = "Campaign body cannot scroll to its final lines"
		return false
	return true


func _scroll_down() -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	event.position = game.campaign_ui.panel_rect(game.get_viewport_rect().size).get_center()
	event.pressed = true
	game.campaign_ui.handle_input(event)


func _click(position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = false
	game.campaign_ui.handle_input(event)


func _validate_campaign_layout(viewport: Vector2) -> Dictionary:
	var ui = game.campaign_ui
	var controls: Array[Rect2] = []
	var labels_checked := 0
	var body_lines_checked := 0
	if ui.open:
		var panel: Rect2 = ui.panel_rect(viewport)
		var bounds := Rect2(Vector2.ZERO, viewport)
		if not bounds.grow(0.5).encloses(panel):
			return {"ok": false, "error": "Campaign panel exceeds viewport"}
		var width := panel.size.x - 40.0
		for label in [
			[ui.text("title"), width, 18, 12],
			[ui.text("nest", {"level": game.campaign.nest_level, "materials": game.campaign.materials}), width, 12, 9]
		]:
			if not _label_fits(label[0], label[1], label[2], label[3]):
				return {"ok": false, "error": "Panel header text overflows: " + label[0]}
			labels_checked += 1
		if not game._campaign_active():
			for direction in [-1, 1]:
				controls.append(ui.page_rect(viewport, direction))
			var choices: Array[String] = ui._mission_choices()
			for index in range(mini(2, choices.size() - ui.selection_start)):
				var rect: Rect2 = ui.selection_rect(viewport, index)
				controls.append(rect)
				var label: String = ui.chapter_text(choices[ui.selection_start + index] + "_title")
				if not _label_fits(label, rect.size.x - 16, 12, 8):
					return {"ok": false, "error": "Mission selection text overflows: " + label}
				labels_checked += 1
			for index in range(3):
				var rect: Rect2 = ui.branch_rect(viewport, index)
				controls.append(rect)
				var id: String = ["transport", "resilience", "defense"][index]
				var label: String = ui.chapter_text("branch_buy", {"branch": ui.chapter_text("branch_" + id), "level": game.campaign["branches"][id], "cost": 2})
				if not _label_fits(label, rect.size.x - 16, 12, 7):
					return {"ok": false, "error": "Construction branch text overflows: " + label}
				labels_checked += 1
		elif not ui.confirm_retreat and not ui._phase_action_key().is_empty():
			var rect: Rect2 = ui.phase_action_rect(viewport)
			controls.append(rect)
			var label: String = ui.chapter_text(ui._phase_action_key())
			if not _label_fits(label, rect.size.x - 16, 12, 7):
				return {"ok": false, "error": "Mission stage action text overflows: " + label}
			labels_checked += 1
		var actions: Array[String] = ui.action_labels()
		for index in range(3):
			var rect: Rect2 = ui.button_rect(viewport, index)
			controls.append(rect)
			if not _label_fits(actions[index], rect.size.x - 16, 12, 7):
				return {"ok": false, "error": "Campaign action text overflows: " + actions[index]}
			labels_checked += 1
		for first in range(controls.size()):
			if not panel.grow(0.5).encloses(controls[first]):
				return {"ok": false, "error": "Campaign control exceeds panel"}
			for second in range(first + 1, controls.size()):
				if controls[first].intersects(controls[second]):
					return {"ok": false, "error": "Campaign controls overlap"}
		var body: Dictionary = ui.panel_body_layout(viewport)
		ui.scroll = clampi(ui.scroll, 0, int(body["max_scroll"]))
		for value in body["lines"]:
			if game.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, int(body["font_size"])).x > float(body["width"]) + 0.5:
				return {"ok": false, "error": "Wrapped campaign body line overflows: " + value}
			body_lines_checked += 1
		for index in range(mini(int(body["visible"]), body["lines"].size() - ui.scroll)):
			var baseline: float = panel.position.y + float(body["first_baseline"]) + index * int(body["line_height"])
			var ascent: float = game.fallback_font.get_ascent(int(body["font_size"]))
			var descent: float = game.fallback_font.get_descent(int(body["font_size"]))
			var text_rect := Rect2(Vector2(panel.position.x + 20, baseline - ascent), Vector2(float(body["width"]), ascent + descent))
			if not panel.grow(0.5).encloses(text_rect):
				return {"ok": false, "error": "Body text exceeds panel vertically"}
			for rect in controls:
				if text_rect.intersects(rect):
					return {"ok": false, "error": "Campaign body text overlaps a control"}
	elif game._campaign_active() and not game.pause_menu_open:
		var rect: Rect2 = game._chapter_guidance_rect()
		for line in ui.progress_hud_lines(rect):
			var measured: Vector2 = game.fallback_font.get_string_size(line["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, int(line["size"]))
			var pos: Vector2 = line["position"]
			if pos.x + measured.x > rect.size.x - 9.5 or pos.y + game.fallback_font.get_descent(int(line["size"])) > rect.size.y + 0.5 or pos.y - game.fallback_font.get_ascent(int(line["size"])) < -0.5:
				return {"ok": false, "error": "Mission HUD text overflows: " + String(line["text"])}
			labels_checked += 1
	return {"ok": true, "controls": controls.size(), "labels": labels_checked, "wrapped_lines": body_lines_checked}


func _label_fits(value: String, width: float, preferred: int, minimum: int) -> bool:
	var size: int = game._fit_font_size(value, width, preferred, minimum)
	return game.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width + 0.5


func _capture_developer_campaign() -> bool:
	# Keep every actual save on the fixture path. Temporarily selecting the exact
	# developer path below enables realistic read-only button rendering only.
	game.campaign_ui.reset_panel()
	game.developer_mode_enabled = true
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.main_menu_active = false
	game.game_started = true
	for phase in ["home", "mission"]:
		if phase == "mission":
			game.pause_menu_open = false
			game.campaign_ui.reset_panel()
			if not game._campaign_start_mission():
				failure = "Developer render mission failed on its isolated fixture path"
				return false
		game._open_developer_tools()
		game.developer_page = 3
		for size in [Vector2i(1280, 720), Vector2i(640, 360)]:
			await _resize(size)
			for locale in Words.LOCALES:
				game.settings_locale = locale
				# In the mission show the real disabled-home-edit explanation.
				game.last_mouse = game._developer_button_rects(Vector2(size))[1].get_center() if phase == "mission" else Vector2(-1, -1)
				var fixture_path: String = game.save_path
				game.save_path = game.DEVELOPER_SAVE_PATH
				var captured := await _capture("developer_" + phase + "_" + str(size.x) + "_" + locale, "developer-ui-render-only")
				game.save_path = fixture_path
				if not captured:
					return false
	# The return action only opens a confirmation; no save or settlement occurs.
	var fixture_path: String = game.save_path
	game.save_path = game.DEVELOPER_SAVE_PATH
	var confirmed: bool = game.campaign_ui.developer_apply_action("campaign_return")
	game.save_path = fixture_path
	if not confirmed or not game.campaign_ui.confirm_retreat or not game._campaign_active():
		failure = "Developer return must only open the existing confirmation"
		return false
	for locale in ["zh_CN", "en"]:
		game.settings_locale = locale
		if not await _capture("developer_return_confirm_" + locale, "developer-return-not-settled"):
			return false
	return true


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
		failure = "Render probe exceeded its 240-second bound"
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
	var layout := _validate_campaign_layout(viewport)
	if not bool(layout["ok"]):
		failure = label + ": " + String(layout["error"])
		return false
	var item: Dictionary = {
		"label": label, "locale": game.settings_locale, "fixture": fixture,
		"viewport": [viewport.x, viewport.y], "window": [window.size.x, window.size.y],
		"rendered": false, "panel_open": game.campaign_ui.open,
		"scroll": game.campaign_ui.scroll, "mission_active": game._campaign_active(),
		"mission_ready": game._campaign_mission_ready(), "game_over": game.game_over,
		"nest_level": game.campaign.nest_level,
		"world_scene_id": game._world_scene_id(), "layout": layout,
		"selection_start": game.campaign_ui.selection_start,
		"phase_action": game.campaign_ui._phase_action_key(),
		"labels": game.campaign_ui.action_labels(),
		"enabled": [game.campaign_ui.action_enabled(0), game.campaign_ui.action_enabled(1), game.campaign_ui.action_enabled(2)]
	}
	if game.pause_menu_open and game.pause_menu_page == "developer":
		item["developer_status"] = game.campaign_ui.developer_status_text()
		item["developer_hint"] = game._developer_campaign_hint(viewport)
		item["developer_actions"] = []
		for action in game.campaign_ui.DEVELOPER_ACTIONS:
			item["developer_actions"].append({
				"id": action, "label": game._developer_action_label(action),
				"disabled_reason": game.campaign_ui.developer_action_reason(action)})
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
