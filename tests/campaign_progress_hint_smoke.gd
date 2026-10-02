extends SceneTree

# Controlled HUD-state fixtures, not a substitute for the real economic route.
const CampaignState = preload("res://scripts/campaign_state.gd")
const Words = preload("res://scripts/campaign_localization.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const SLOT := "user://campaign_progress_hint_smoke.json"
var checks := 0
var segment: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveStore.remove_slot(SLOT)
	var game: Node = await _runner()
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.campaign = CampaignState.fresh()
	if not _check(game._campaign_start_mission(), "fixture enters the real independent mission"):
		return
	game.selected_core = 0
	game.selected_tip_valid = false
	game._confirm_extension(game.cores[0]["pos"] + Vector2(200, 0))
	if not _check(game.segments.size() == 1, "fixture has a real paid segment template"):
		return
	segment = game.segments[0].duplicate(true)
	_fixture(game, "ready")
	game.lifetime_organic_absorbed = 359.9999
	if not _check(not game._campaign_mission_ready() and game.campaign_ui.progress_text().contains("359.999/360"), "unmet 359.9999 uptake must not round into a visible 360.000/360 completion"):
		return
	if not _check(game.campaign_ui.has_method("progress_hint_key") and game.campaign_ui.has_method("progress_hud_lines"), "HUD exposes live status and the same measured lines used for drawing"):
		return
	if not _check(game.campaign_ui._progress_number(game._chapter_bounded_progress(599.999999999, 600.0) / 2.0, 300.0, true) == "300", "shared normalization renders epsilon-complete world length as 300 micrometres"):
		return
	for state in ["extend", "organic", "mineral", "grow", "ready", "dead"]:
		_fixture(game, state)
		if not _check(game.campaign_ui.progress_hint_key() == "hint_" + state, "current mission selects " + state):
			return
		if not _check(game._campaign_mission_ready() == (state == "ready"), "HUD ready state agrees with authoritative predicate for " + state):
			return
		if not _check(game._save_game(), "checkpoint controlled " + state + " fixture"):
			return
		var world: Dictionary = _signature(game._capture_world_state())
		var ledger: Dictionary = game.campaign.duplicate(true)
		var saved := FileAccess.get_file_as_string(SLOT)
		var modal := [game.campaign_ui.open, game.campaign_ui.confirm_retreat, game.campaign_ui.busy, game.campaign_ui.notice, game.offline_settlement_active, game.chapter_report_open]
		for locale in Words.LOCALES:
			game.settings_locale = locale
			for viewport in [Vector2(640, 360), Vector2(1280, 720)]:
				game.layout_viewport_override = viewport
				var rect: Rect2 = game._chapter_guidance_rect()
				if not _check(rect.size == (Vector2(208, 34) if viewport.x == 640 else Vector2(300, 112)), "existing HUD dimensions stay unchanged"):
					return
				if not _check(_layout_ok(game, rect, state), "%s/%s has complete non-overlapping font metrics at %s" % [locale, state, viewport]):
					return
				game.queue_redraw()
				await process_frame
		if not _check(_signature(game._capture_world_state()) == world and game.campaign == ledger and FileAccess.get_file_as_string(SLOT) == saved and modal == [game.campaign_ui.open, game.campaign_ui.confirm_retreat, game.campaign_ui.busy, game.campaign_ui.notice, game.offline_settlement_active, game.chapter_report_open], "HUD queries and draw frames have no world, reward, save or modal side effects for " + state):
			return
	game.settings_locale = "en"
	_fixture(game, "ready")
	for loss in ["orphaned", "viability", "growth", "alive"]:
		_fixture(game, "ready")
		match loss:
			"orphaned": game.segments[0]["orphaned"] = true
			"viability": game.segments[0]["viability"] = 0.0
			"growth": game.segments[0]["growth"] = 0.99
			"alive": game.cores[0]["alive"] = false
		if not _check(not game._campaign_mission_ready() and game.campaign_ui.progress_hint_key() != "hint_ready", "readiness and HUD immediately revoke after losing " + loss):
			return
	_fixture(game, "ready")
	game.organic = 99999.0
	game.mineral = 99999.0
	game.lifetime_organic_absorbed = 0.0
	game.lifetime_mineral_absorbed = 0.0
	if not _check(game.campaign_ui.progress_hint_key() == "hint_organic" and not game._campaign_mission_ready(), "stockpiles do not substitute for actual uptake"):
		return
	_fixture(game, "ready")
	game.active_world.organic_required = 721.0
	if not _check(game.campaign_ui.progress_hint_key() == "hint_organic" and game.campaign_ui.progress_text().contains("721"), "live scene goals drive hint and progress"):
		return
	game.active_world.organic_required = 360.0
	game.active_world.mineral_required = 19.0
	if not _check(game.campaign_ui.progress_hint_key() == "hint_mineral", "mineral target is read from the live scene"):
		return
	game.active_world.mineral_required = 18.0
	game.active_world.hypha_world_required = 800.0
	if not _check(game.campaign_ui.progress_hint_key() == "hint_grow", "mature length target is read from the live scene"):
		return
	game.active_world.hypha_world_required = 600.0
	_fixture(game, "ready")
	game.lifetime_organic_absorbed -= 0.000000005
	game.lifetime_mineral_absorbed -= 0.000000005
	game.segments[0]["b"] -= Vector2(0.000000005, 0)
	if not _check(game.campaign_ui.progress_hint_key() == "hint_ready" and game.campaign_ui.progress_text().contains("300/300"), "all three thresholds share authoritative floating-point normalization"):
		return
	game.segments[0]["b"] -= Vector2(0.001, 0)
	if not _check(game.campaign_ui.progress_hint_key() == "hint_grow" and game.campaign_ui.progress_text().contains("299/300"), "outside tolerance a short network is not rounded into completion"):
		return
	_fixture(game, "ready")
	game.guidance_collapsed = true
	if not _check(_layout_ok(game, game._chapter_guidance_rect(), "ready"), "collapsed regular HUD retains complete ready action and numbers"):
		return
	game.guidance_collapsed = false
	if not _check(game._save_game(), "ready mission saves without automatically settling"):
		return
	# Compare at SaveStore's JSON precision, including nested timestamps and numbers.
	var ledger: Dictionary = JSON.parse_string(JSON.stringify(game.campaign))
	var saved := FileAccess.get_file_as_string(SLOT)
	await _dispose(game)
	game = await _runner()
	if not _check(game._load_game(true) and game._campaign_active() and game._campaign_mission_ready() and game.campaign_ui.progress_hint_key() == "hint_ready", "fresh runner reloads ready hint from mission state"):
		return
	if not _check(JSON.parse_string(JSON.stringify(game.campaign)) == ledger and int(game.campaign.materials) == 0 and FileAccess.get_file_as_string(SLOT) == saved and not game.campaign_ui.open and not game.offline_settlement_active, "loading and querying ready hint do not award, return, save or force a modal"):
		return
	var key := InputEventKey.new()
	key.keycode = KEY_J
	key.pressed = true
	game._unhandled_input(key)
	if not _check(game.campaign_ui.open and game._campaign_active() and int(game.campaign.materials) == 0, "J still only opens the existing settlement panel"):
		return
	game.campaign_ui.reset_panel()
	game.segments[0]["viability"] = 0.0
	if not _check(not game._campaign_mission_ready() and game.campaign_ui.progress_hint_key() != "hint_ready", "loaded ready hint is not latched after network death"):
		return
	print("CAMPAIGN_PROGRESS_HINT_OK checks=%d states=6 locales=7 layouts=640x360+1280x720 epsilon=shared live-revocation=true save-load=ready side-effects=none" % checks)
	SaveStore.remove_slot(SLOT)
	await _dispose(game)
	quit(0)


func _fixture(game: Node, state: String) -> void:
	game.game_over = false
	game.cores[0]["alive"] = true
	game.segments = [segment.duplicate(true)]
	game.segments[0]["a"] = Vector2.ZERO
	game.segments[0]["b"] = Vector2(600, 0)
	game.segments[0]["growth"] = 1.0
	game.segments[0]["viability"] = 1.0
	game.segments[0]["orphaned"] = false
	game.lifetime_organic_absorbed = 360.0
	game.lifetime_mineral_absorbed = 18.0
	match state:
		"extend":
			game.segments.clear()
			game.lifetime_organic_absorbed = 0.0
			game.lifetime_mineral_absorbed = 0.0
		"organic":
			game.lifetime_organic_absorbed = 0.125
			game.lifetime_mineral_absorbed = 0.0
		"mineral": game.lifetime_mineral_absorbed = 0.125
		"grow": game.segments[0]["growth"] = 0.5
		"dead":
			game.game_over = true
			game.cores[0]["alive"] = false


func _layout_ok(game: Node, rect: Rect2, state: String) -> bool:
	var lines: Array = game.campaign_ui.progress_hud_lines(rect)
	var hint_found := false
	var progress_found := false
	var last_bottom := 0.0
	for line in lines:
		var value := String(line["text"])
		var size := int(line["size"])
		var baseline: Vector2 = line["position"]
		var measured: Vector2 = game.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		var top: float = baseline.y - game.fallback_font.get_ascent(size)
		var bottom: float = baseline.y + game.fallback_font.get_descent(size)
		if value.is_empty() or size < 7 or measured.x > rect.size.x - baseline.x * 2 + 0.01 or top < last_bottom - 0.01 or bottom > rect.size.y - 1:
			print("HINT_LAYOUT_DIAGNOSTIC locale=%s state=%s rect=%s line=%s width=%.3f top=%.3f bottom=%.3f previous=%.3f" % [game.settings_locale, state, rect.size, line, measured.x, top, bottom, last_bottom])
			return false
		last_bottom = bottom
		if line["role"] == "hint":
			hint_found = value == Words.text(game.settings_locale, "hint_" + state)
			if state in ["ready", "dead"] and not value.contains("[J]"):
				return false
		if line["role"] == "progress":
			progress_found = true
	if rect.size.y <= 60:
		return lines.size() == 2 and hint_found and progress_found
	return lines.size() >= 3 and lines[0]["text"] == Words.text(game.settings_locale, "mission_title") and hint_found and progress_found


func _runner() -> Node:
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
	game.settings_locale = "en"
	return game


func _signature(world: Dictionary) -> Dictionary:
	var result := world.duplicate(true)
	result.erase("saved_at")
	result.erase("campaign")
	return JSON.parse_string(JSON.stringify(result)) as Dictionary


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
	push_error("CAMPAIGN_PROGRESS_HINT_FAIL: " + message)
	quit(1)
	return false
