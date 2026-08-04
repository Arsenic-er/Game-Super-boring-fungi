extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game.autosave_enabled = false
	var audio: Node = game.pixel_audio
	if not _check(audio != null and audio.cue_streams.size() >= 30 and audio.players.size() == 12, "pixel laboratory audio manager should build its cue library and bounded voice pool"):
		return
	var click_stream: AudioStreamWAV = audio.cue_streams["ui_click"]
	var ambient_stream: AudioStreamWAV = audio.ambient_player.stream
	if not _check(click_stream.data.size() > 1000 and ambient_stream.data.size() > 100000 and ambient_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "procedural effects and seamless ambient loop should contain PCM audio"):
		return

	var click_before: int = audio.cue_count("ui_click")
	if not _check(game._play_sound("ui_click", 1.0, true) and audio.cue_count("ui_click") == click_before + 1, "interactive cue should enter the playback pool"):
		return
	var absorb_before: int = audio.cue_count("organic_absorb")
	game._play_sound("organic_absorb")
	game._play_sound("organic_absorb")
	if not _check(audio.cue_count("organic_absorb") == absorb_before + 1, "continuous absorption cues should be wall-clock rate limited"):
		return
	game.offline_simulating = true
	var command_before: int = audio.cue_count("command")
	game._play_sound("command", 1.0, true)
	if not _check(audio.cue_count("command") == command_before, "offline simulation should suppress all event playback"):
		return
	game.offline_simulating = false

	game.settings_master_volume = 0.0
	game._apply_settings()
	if not _check(not game._play_sound("ui_confirm", 1.0, true), "zero master volume should mute one-shot audio"):
		return
	game.settings_master_volume = 0.80
	game._apply_settings()
	game._start_new_culture()
	game.selected_core = 0
	var growth_before: int = audio.cue_count("hypha_grow")
	game._confirm_extension(Vector2(100.0, 0.0))
	if not _check(audio.cue_count("hypha_grow") == growth_before + 1, "successful hypha interaction should emit its growth cue"):
		return
	var dna_before: int = audio.cue_count("dna_queue")
	game._queue_dna(0)
	if not _check(audio.cue_count("dna_queue") == dna_before + 1, "manual DNA production should emit its queue cue"):
		return
	game.organic = 0.0
	var error_before: int = audio.cue_count("ui_error")
	game._queue_dna(0)
	if not _check(audio.cue_count("ui_error") == error_before + 1, "invalid resource interaction should emit a rate-limited error cue"):
		return

	game.main_menu_page = "settings"
	game.pause_menu_page = "settings"
	if not _check(game._main_menu_labels().size() == 10 and game._pause_menu_labels().size() == 9, "main settings should add the developer switch while pause settings keep language and five audio channels"):
		return
	for viewport in [Vector2(1280.0, 720.0), Vector2(960.0, 540.0), Vector2(640.0, 360.0)]:
		var settings_header := Rect2(Vector2.ZERO, Vector2(viewport.x, 78.0))
		if not _check(not settings_header.intersects(game._main_menu_button_rect(viewport, 0)), "settings controls must stay clear of the compact settings header"):
			return
		var previous := Rect2()
		for index in range(game._main_menu_labels().size()):
			var rect: Rect2 = game._main_menu_button_rect(viewport, index)
			if not _check(Rect2(Vector2.ZERO, viewport).encloses(rect) and (index == 0 or not previous.intersects(rect)), "audio settings must fit the main menu without overlap"):
				return
			previous = rect
		var panel: Rect2 = game._pause_menu_panel_rect(viewport)
		previous = Rect2()
		for index in range(game._pause_menu_labels().size()):
			var rect: Rect2 = game._pause_menu_button_rect(viewport, index)
			if not _check(panel.encloses(rect) and (index == 0 or not previous.intersects(rect)), "audio settings must fit the pause panel without overlap"):
				return
			previous = rect

	var settings_path := "user://settings.json"
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"fullscreen": false, "pixel_cursor": true}))
	file = null
	game.settings_master_volume = 0.0
	game.settings_ui_volume = 0.0
	game.settings_world_volume = 0.0
	game.settings_combat_volume = 0.0
	game.settings_ambient_volume = 0.0
	game._load_settings()
	if not _check(is_equal_approx(game.settings_master_volume, 0.80) and is_equal_approx(game.settings_ui_volume, 0.75) and is_equal_approx(game.settings_world_volume, 0.65) and is_equal_approx(game.settings_combat_volume, 0.70) and is_equal_approx(game.settings_ambient_volume, 0.35), "v0.30 settings should receive safe audio defaults"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
	print("AUDIO_SYSTEM_OK cues=", audio.cue_streams.size(), " voices=", audio.players.size(), " ambient_seconds=32 settings=main10/pause9 audio_channels=5 interactions=hooked legacy=compatible offline=silent")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("AUDIO_SYSTEM_FAIL: " + message)
	quit(1)
	return false
