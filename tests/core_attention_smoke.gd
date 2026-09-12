extends SceneTree

const Events = preload("res://scripts/world_event_localization.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.autosave_enabled = false
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.splash_active = false
	game.main_menu_active = false
	game.game_started = true
	game.cores.append(game._make_core(Vector2(200, 0), "barracks"))
	if not _check(game._core_attention_id() == -1, "healthy, safe cores do not create warnings"):
		return
	game.cores[1]["toxin_pressure"] = 0.01
	if not _check(game._core_attention_id() == 1, "toxin pressure gives notice before major biomass loss"):
		return
	game._damage_core(0, 49.999, "environment_pressure")
	game.cores[1]["toxin_pressure"] = 0.0
	if not _check(game._core_attention_id() == -1, "safe biomass just above half does not trip the low threshold"):
		return
	game._damage_core(0, 0.001, "environment_pressure")
	if not _check(game._core_attention_id() == 0, "half biomass is visible even without current toxin pressure"):
		return
	game._damage_core(1, 70.0, "environment_pressure")
	if not _check(game._core_attention_id() == 1, "the lowest living biomass fraction takes priority"):
		return
	game.enemy_threat_level = 3
	game.enemy_threat_pos = Vector2(400, 0)
	game._reveal_exploration(game.enemy_threat_pos, 100.0)
	var balance := Vector3(game.organic, game.mineral, game.dna)
	var health := Vector2(game.cores[0]["biomass"], game.cores[1]["biomass"])
	for locale_id in Events.LOCALES:
		game.settings_locale = locale_id
		for key in ["core_pressure_title_fmt", "core_low_title_fmt", "core_attention_locate", "core_attention_located"]:
			if not _check(Events.KEYS.has(key) and Events.VALUES[locale_id].size() == Events.KEYS.size() and not game._et(key).strip_edges().is_empty() and game._et(key) != key, "explicit seven-language warning " + locale_id + "/" + key):
				return
		var formatted: String = game._et("core_low_title_fmt") % [2, 30.0]
		if not _check(not formatted.is_empty(), "core number and biomass placeholders are valid"):
			return
		for viewport in [Vector2i(1280, 720), Vector2i(640, 360)]:
			root.size = viewport
			await process_frame
			game.selected_core = -1
			game.mode = "normal"
			var card: Rect2 = game._enemy_threat_hud_rect()
			if not _check(game._handle_enemy_threat_click(card.get_center()) and game.selected_core == 1 and game.show_status and game.camera_center.is_equal_approx(Vector2(200, 0)), "warning click locates the endangered core and opens its status"):
				return
			if not _check(Vector3(game.organic, game.mineral, game.dna) == balance and Vector2(game.cores[0]["biomass"], game.cores[1]["biomass"]) == health, "locating a warning never auto-purchases repair or changes biomass"):
				return
			game.toast_text = "no repeated warning toast"
			for i in range(30):
				game._core_attention_id()
			if not _check(game.toast_text == "no repeated warning toast", "passive warning queries do not spam"):
				return
			game.queue_redraw()
			await process_frame
	game._damage_core(1, 100.0, "environment_pressure")
	if not _check(game._core_attention_id() == 0, "dead cores leave the warning selection immediately"):
		return
	game._repair_core(0)
	game.bacteria.clear()
	game.ecology_events.clear()
	game._update_core_hazards(10000.0)
	if not _check(game._core_attention_id() == -1, "real paid reserve plus passive recovery removes the low-biomass warning"):
		return
	if not _check(game._handle_enemy_threat_click(game._enemy_threat_hud_rect().get_center()) and game.camera_center.is_equal_approx(game.enemy_threat_pos), "existing rival-front warning becomes accessible again after recovery"):
		return
	game.enemy_threat_level = 0
	game.enemy_threat_pos = Vector2.INF
	if not _check(not game._handle_enemy_threat_click(game._enemy_threat_hud_rect().get_center()), "an empty warning slot does not intercept world clicks"):
		return
	for player in game.pixel_audio.players:
		player.stop()
		player.stream = null
	game.pixel_audio.ambient_player.stop()
	game.pixel_audio.ambient_player.stream = null
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("CORE_ATTENTION_OK locales=7 early-toxin=true low-health=true locate=true no-autospend=true recovered-rival-warning=true")
	quit(0)

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CORE_ATTENTION_FAIL: " + message)
	quit(1)
	return false
