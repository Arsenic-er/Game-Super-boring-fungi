extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene loads"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false
	game.layout_viewport_override = Vector2(640, 360)
	var viewport := Vector2(640, 360)

	var resource_panel: Rect2 = game._resource_bar_rect()
	var minimap: Rect2 = game._minimap_rect()
	var filters: Array = game._unit_filter_rects()
	if not _check(filters.size() == 11, "all eleven unit filters remain visible"):
		return
	for index in range(filters.size()):
		var filter_rect: Rect2 = filters[index]["rect"]
		if not _check(Rect2(Vector2.ZERO, viewport).encloses(filter_rect), "filter %d stays inside viewport" % index):
			return
		if not _check(not filter_rect.intersects(resource_panel) and not filter_rect.intersects(minimap), "filter %d avoids resource bar and minimap" % index):
			return
		if index > 0 and not _check(not filter_rect.intersects(filters[index - 1]["rect"] as Rect2), "adjacent filters do not overlap"):
			return

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(120.0, 0.0), "barracks"))
	game.selected_core = barracks_id
	game.show_status = true
	var status_panel: Rect2 = game._status_panel_rect()
	if not _check(Rect2(Vector2.ZERO, viewport).encloses(status_panel), "compact barracks panel stays inside viewport"):
		return
	if not _check(status_panel.end.x < minimap.position.x and status_panel.position.y >= (filters.back()["rect"] as Rect2).end.y, "compact barracks panel avoids minimap and filter row"):
		return
	for button in [game._barracks_auto_button_rect(), game._barracks_target_button_rect(), game._barracks_rally_button_rect()]:
		if not _check(status_panel.encloses(button), "compact barracks action stays in panel"):
			return
	for index in range(4):
		if not _check(status_panel.encloses(game._barracks_directive_button_rect(index)), "compact directive %d stays in panel" % index):
			return

	game.ecology_events = [{
		"id": 77, "type": "bloom", "pos": Vector2(200.0, 0.0), "radius": game.ECOLOGY_BLOOM_RADIUS,
		"phase": "warning", "remaining": 45.0, "anchor_core_id": 0, "spawned": 0
	}]
	game.chapter_complete = true
	game.lifetime_enemy_fungi_defeated = 1
	game.fungal_incursion = {"phase": "warning", "remaining": 45.0, "pos": Vector2(760.0, 120.0), "wave": 1, "enemy_id": -1}
	game.enemy_threat_level = 2
	game.enemy_threat_pos = Vector2(480.0, 80.0)
	var right_cards: Array[Rect2] = [game._ecology_event_hud_rect(), game._fungal_incursion_hud_rect(), game._chapter_guidance_rect(), game._enemy_threat_hud_rect()]
	for index in range(right_cards.size()):
		var card: Rect2 = right_cards[index]
		if not _check(Rect2(Vector2.ZERO, viewport).encloses(card), "right HUD card %d stays inside 640x360" % index):
			return
		if not _check(card.position.x >= status_panel.end.x and is_equal_approx(card.position.x, minimap.position.x), "right HUD card %d stays right of compact barracks" % index):
			return
		if index > 0 and not _check(not card.intersects(right_cards[index - 1]), "right HUD cards %d and %d do not overlap" % [index - 1, index]):
			return

	game._spawn_expedition_spore(barracks_id, "forager")
	game.selected_core = -1
	game.show_status = false
	game.selected_expedition_ids = [int(game.expedition_units[0]["id"])]
	var selection_panel: Rect2 = game._selection_status_rect(viewport)
	if not _check(Rect2(Vector2.ZERO, viewport).encloses(selection_panel) and selection_panel.end.x < minimap.position.x, "compact selection panel stays left of right HUD stack"):
		return
	for card in right_cards:
		if not _check(not selection_panel.intersects(card), "compact selection panel avoids every visible right HUD card"):
			return
	for index in range(4):
		var order_button: Rect2 = game._defense_zone_button_rect(viewport, index)
		if not _check(selection_panel.encloses(order_button), "persistent-order button %d stays in selection panel" % index):
			return
	if not _check(game._audio_hover_target_at(game._defense_zone_button_rect(viewport, 3).get_center()) == "persistent_order_3", "clear-order button receives hover audio target"):
		return

	for locale_id in ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]:
		game.settings_locale = locale_id
		game.selected_expedition_ids.clear()
		var before: int = game.pixel_audio.cue_count("ui_error")
		game.pixel_audio.last_play_ms["ui_error"] = -1000000
		game._begin_harvest_zone_mode()
		if not _check(game.toast_text == game._rt("toast_harvest_select"), "%s harvest error is localized" % locale_id):
			return
		if not _check(game.pixel_audio.cue_count("ui_error") == before + 1, "%s harvest error emits one accepted cue" % locale_id):
			return
		game.pixel_audio.last_play_ms["ui_error"] = -1000000

	game.selected_core = barracks_id
	game.show_status = true
	for locale_id in ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]:
		game.settings_locale = locale_id
		game.queue_redraw()
		await process_frame
		await process_frame

	print("COMPACT_HUD_OK viewport=640x360 filters=11 barracks=operable selection=left right_cards=4 i18n=7 audio=single")
	game.free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("COMPACT_HUD_FAIL: " + message)
	quit(1)
	return false
