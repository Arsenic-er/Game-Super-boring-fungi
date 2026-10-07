extends "res://scripts/main.gd"

# Synthetic checkpoints have independent profiles. Once entered, every task,
# cost, first-victory reward and home return uses the ordinary campaign runtime.
const AuditPresets = preload("res://scripts/campaign_audit_presets.gd")
const AuditWords = preload("res://scripts/campaign_audit_localization.gd")
const AUDIT_SCHEMA := 1
const AUDIT_ROOT := "user://campaign-audit-v1"
const AUDIT_SPEEDS := [1.0, 5.0, 20.0]
const AUDIT_BUILD_INFO := "res://review_build_info.json"
var audit_arguments: Array[String] = []
var audit_valid := false
var audit_stage_id := "early_choice"
var audit_requested_locale := ""
var audit_directory := ""
var audit_error := ""
var audit_started := false
var audit_open := true
var audit_reset_confirm := false
var audit_notice := ""
var audit_speed := 1.0
var audit_speeds_used: Array = [1]
var audit_wall_seconds := 0.0
var audit_initial_conditions: Dictionary = {}
var audit_initial_hash := ""
var audit_build: Dictionary = {"status": "development", "commit": "unreleased"}
var audit_origin_build: Dictionary = {}
var audit_loaded_build: Dictionary = {}
var audit_panel: PanelContainer
var audit_title: Label
var audit_body: Label
var audit_badge: Label
var audit_buttons: Dictionary = {}
var audit_stage_buttons: Dictionary = {}
var audit_scroll: ScrollContainer
var audit_grid: GridContainer


func _is_review_entry() -> bool:
	return true


func _settings_file_exists() -> bool:
	return audit_valid and FileAccess.file_exists(audit_directory + "/settings.json")


func audit_configure(arguments: Array) -> bool:
	audit_valid = false
	audit_error = ""
	audit_stage_id = "early_choice"
	audit_requested_locale = ""
	var seen := {}
	for item in arguments:
		var option := String(item)
		if option.begins_with("--review"):
			audit_error = "Review and campaign-audit arguments cannot be combined"
			break
		if not option.begins_with("--audit"):
			continue
		var parts := option.split("=", true, 1)
		var key := String(parts[0])
		if seen.has(key):
			audit_error = "Duplicate audit option"
			break
		seen[key] = true
		match key:
			"--audit-hub":
				if parts.size() != 1:
					audit_error = "The audit-hub switch takes no value"
			"--audit-stage":
				if parts.size() != 2 or AuditPresets.preset(parts[1]).is_empty():
					audit_error = "Unknown audit stage"
				else:
					audit_stage_id = parts[1]
			"--audit-lang":
				if parts.size() != 2 or not UILocalization.LOCALES.has(parts[1]):
					audit_error = "Unknown audit language"
				else:
					audit_requested_locale = parts[1]
			_:
				audit_error = "Unknown audit option"
		if not audit_error.is_empty():
			break
	if not seen.has("--audit-hub"):
		audit_error = "The audit-hub switch is required"
	audit_valid = audit_error.is_empty()
	audit_directory = AUDIT_ROOT + "/" + (audit_stage_id if audit_valid else "invalid")
	save_path = audit_directory + "/save.json"
	return audit_valid


func _ready() -> void:
	var arguments: Array = audit_arguments if not audit_arguments.is_empty() else Array(OS.get_cmdline_user_args())
	if not audit_configure(arguments):
		hide()
		set_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		push_error("CAMPAIGN_AUDIT_INVALID " + audit_error)
		get_tree().quit(2)
		return
	autosave_enabled = false
	developer_mode_enabled = false
	super._ready()
	developer_previous_save_path = ""
	_audit_clear_modals()
	game_started = false
	if not audit_requested_locale.is_empty():
		settings_locale = audit_requested_locale
		_apply_settings()
	_audit_load_build()
	_audit_create_panel()
	_audit_refresh_panel()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("CAMPAIGN_AUDIT_READY stage=", audit_stage_id, " slot=", save_path, " loaded_existing=false synthetic=true developer=false")


func _audit_load_build() -> void:
	var file := FileAccess.open(AUDIT_BUILD_INFO, FileAccess.READ)
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			audit_build = parsed.duplicate(true)


func _audit_text(key: String, values: Dictionary = {}) -> String:
	return AuditWords.text(settings_locale, key, values)


func _audit_create_panel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var overlay := Control.new()
	overlay.name = "CampaignAuditOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	audit_panel = PanelContainer.new()
	audit_panel.name = "CampaignAuditPanel"
	overlay.add_child(audit_panel)
	audit_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	audit_panel.offset_left = 12
	audit_panel.offset_top = 12
	audit_panel.offset_right = -12
	audit_panel.offset_bottom = -12
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b1a26")
	style.border_color = Color("78c9a5")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	audit_panel.add_theme_stylebox_override("panel", style)
	audit_panel.add_theme_font_override("font", fallback_font)
	audit_panel.add_theme_font_size_override("font_size", 14)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	audit_panel.add_child(content)
	audit_title = Label.new()
	audit_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	audit_title.add_theme_color_override("font_color", Color("bcf4d3"))
	audit_title.add_theme_font_size_override("font_size", 18)
	content.add_child(audit_title)
	var actions := GridContainer.new()
	actions.name = "CampaignAuditActions"
	actions.columns = 4
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 4)
	content.add_child(actions)
	_audit_add_button(actions, "new", _audit_new_clicked)
	_audit_add_button(actions, "continue", audit_continue)
	_audit_add_button(actions, "play", audit_return_to_play)
	_audit_add_button(actions, "save", audit_save)
	_audit_add_button(actions, "report", audit_export_report)
	for speed in AUDIT_SPEEDS:
		var button := _audit_add_button(actions, "speed_%d" % speed, audit_set_speed.bind(speed))
		button.text = "%d×" % speed
	_audit_add_button(actions, "cancel", _audit_cancel_reset)
	_audit_add_button(actions, "quit", _audit_quit)
	audit_scroll = ScrollContainer.new()
	audit_scroll.name = "CampaignAuditScroll"
	audit_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	audit_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(audit_scroll)
	var scroll_body := VBoxContainer.new()
	scroll_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_body.add_theme_constant_override("separation", 10)
	audit_scroll.add_child(scroll_body)
	audit_grid = GridContainer.new()
	audit_grid.name = "CampaignAuditStages"
	audit_grid.columns = 2
	audit_grid.add_theme_constant_override("h_separation", 6)
	audit_grid.add_theme_constant_override("v_separation", 6)
	scroll_body.add_child(audit_grid)
	for entry in AuditPresets.entries():
		var stage_id := String(entry["id"])
		var button := Button.new()
		button.name = "AuditStage_" + stage_id
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(audit_switch_stage.bind(stage_id))
		audit_grid.add_child(button)
		audit_stage_buttons[stage_id] = button
	audit_body = Label.new()
	audit_body.name = "CampaignAuditReadout"
	audit_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	audit_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	audit_body.add_theme_color_override("font_color", Color("d5e5e3"))
	scroll_body.add_child(audit_body)
	audit_badge = Label.new()
	audit_badge.name = "CampaignAuditBadge"
	audit_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	audit_badge.add_theme_font_override("font", fallback_font)
	audit_badge.add_theme_font_size_override("font_size", 12)
	audit_badge.add_theme_color_override("font_color", Color("f3d391"))
	overlay.add_child(audit_badge)
	audit_badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	audit_badge.offset_left = -260
	audit_badge.offset_right = 260
	audit_badge.offset_top = -23
	audit_badge.offset_bottom = -3
	audit_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _audit_add_button(parent: Control, key: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = "Audit_" + key
	button.custom_minimum_size = Vector2(0, 36)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(callback)
	parent.add_child(button)
	audit_buttons[key] = button
	return button


func _audit_refresh_panel() -> void:
	if audit_panel == null:
		return
	audit_panel.visible = audit_open
	audit_badge.visible = audit_started and not audit_open
	audit_badge.text = _audit_text("badge", {"speed": "%d" % audit_speed})
	var preset := AuditPresets.preset(audit_stage_id)
	var stage_title := _audit_text(String(preset["title_key"]))
	audit_title.text = _audit_text("title") + " — " + stage_title
	for entry in AuditPresets.entries():
		var id := String(entry["id"])
		var button: Button = audit_stage_buttons[id]
		button.text = ("● " if id == audit_stage_id else "") + _audit_text(String(entry["title_key"]))
		button.tooltip_text = _audit_text(String(entry["description_key"]))
	var lines: Array[String] = [_audit_text(String(preset["description_key"])), _audit_text("intro"), _audit_text("fixture"), _audit_text("controls")]
	if not audit_notice.is_empty():
		lines.push_front(audit_notice)
	if audit_reset_confirm:
		lines.push_front(_audit_text("confirm"))
	if audit_started:
		lines.append(_audit_text("resources", {"organic": "%.3f" % organic, "mineral": "%.3f" % mineral, "dna": str(dna)}))
		lines.append(_audit_text("time", {"sim": "%.3f" % sim_time, "wall": "%.3f" % audit_wall_seconds, "speeds": JSON.stringify(audit_speeds_used)}))
	else:
		lines.append(_audit_text("paused"))
	lines.append(_audit_text("build", {"commit": String(audit_build.get("source_commit", audit_build.get("commit", "development"))).left(12), "status": String(audit_build.get("build_id", audit_build.get("status", "development")))}))
	lines.append(_audit_text("location", {"path": ProjectSettings.globalize_path(save_path)}))
	audit_body.text = "\n\n".join(lines)
	for key in audit_buttons:
		var button: Button = audit_buttons[key]
		if not String(key).begins_with("speed_"):
			button.text = _audit_text("yes" if key == "new" and audit_reset_confirm else key)
		button.disabled = false
	audit_buttons["continue"].disabled = not _has_recoverable_save()
	for key in ["play", "save", "report"]:
		audit_buttons[key].disabled = not audit_started
	audit_buttons["cancel"].visible = audit_reset_confirm


func _audit_new_clicked() -> void:
	if not audit_valid:
		return
	if not audit_reset_confirm and (audit_started or _has_recoverable_save()):
		audit_reset_confirm = true
		_audit_refresh_panel()
		return
	audit_start_new(audit_reset_confirm)


func _audit_cancel_reset() -> void:
	audit_reset_confirm = false
	_audit_refresh_panel()


func _audit_snapshot_session() -> Dictionary:
	return {
		"world": super._capture_world_state(), "campaign": campaign.duplicate(true),
		"metadata": _audit_metadata(), "started": audit_started,
		"autosave": autosave_enabled, "game_started": game_started,
		"game_speed": sim_speed, "open": audit_open, "confirm": audit_reset_confirm
	}


func _audit_restore_session(before: Dictionary) -> void:
	campaign = before["campaign"].duplicate(true)
	_restore_world_state(before["world"])
	_audit_restore_metadata(before["metadata"])
	audit_started = bool(before["started"])
	autosave_enabled = bool(before["autosave"])
	game_started = bool(before["game_started"])
	sim_speed = float(before["game_speed"])
	# Loading normally repairs tutorial hints; a failed reset is not a load.
	# Restore those transient-in-save fields exactly with the prior world.
	chapter_task_index = int(before["world"].get("chapter_task_index", 0))
	core_selected_once = bool(before["world"].get("core_selected_once", false))
	audit_open = bool(before["open"])
	audit_reset_confirm = bool(before["confirm"])
	_audit_clear_modals()
	game_started = bool(before["game_started"])


func audit_start_new(confirmed: bool = false) -> bool:
	if not audit_valid:
		return false
	if (audit_started or _has_recoverable_save()) and not confirmed:
		audit_reset_confirm = true
		_audit_refresh_panel()
		return false
	var before := _audit_snapshot_session()
	autosave_enabled = false
	developer_mode_enabled = false
	audit_started = false
	audit_initial_conditions = {}
	audit_initial_hash = ""
	audit_wall_seconds = 0.0
	audit_speed = 1.0
	audit_speeds_used = [1]
	audit_origin_build = audit_build.duplicate(true)
	audit_loaded_build = audit_build.duplicate(true)
	var success := _start_new_culture("home_nest") and _complete_founder_spore_germination()
	if success:
		var applied: Dictionary = AuditPresets.apply(self, audit_stage_id)
		success = bool(applied.get("ok", false))
		audit_initial_conditions = applied.get("initial_conditions", {}).duplicate(true)
	if success:
		audit_initial_hash = audit_fingerprint(super._capture_world_state())
		audit_started = true
		success = _save_game()
	if not success:
		_audit_restore_session(before)
		audit_notice = _audit_text("save_failed")
		_audit_refresh_panel()
		return false
	_audit_clear_modals()
	audit_reset_confirm = false
	audit_notice = ""
	audit_open = true
	autosave_enabled = true
	_audit_refresh_panel()
	return true


func audit_switch_stage(stage_id: String) -> bool:
	if not audit_valid or AuditPresets.preset(stage_id).is_empty():
		return false
	if stage_id == audit_stage_id:
		return true
	# No profile or metadata changes until the current live session is durable.
	if audit_started and not _save_game():
		audit_notice = _audit_text("save_failed")
		_audit_refresh_panel()
		return false
	audit_stage_id = stage_id
	audit_directory = AUDIT_ROOT + "/" + stage_id
	save_path = audit_directory + "/save.json"
	autosave_enabled = false
	audit_started = false
	audit_open = true
	audit_reset_confirm = false
	audit_notice = ""
	audit_initial_conditions = {}
	audit_initial_hash = ""
	audit_wall_seconds = 0.0
	audit_speed = 1.0
	audit_speeds_used = [1]
	audit_origin_build = {}
	audit_loaded_build = {}
	_audit_clear_modals()
	game_started = false
	_load_settings()
	if not audit_requested_locale.is_empty():
		settings_locale = audit_requested_locale
	_apply_settings()
	_audit_refresh_panel()
	return true


func audit_continue() -> bool:
	if not audit_valid:
		return false
	var before := _audit_snapshot_session()
	if not _load_game(false):
		_audit_restore_session(before)
		audit_notice = _audit_text("save_failed")
		_audit_refresh_panel()
		return false
	audit_started = true
	autosave_enabled = true
	_audit_clear_modals()
	audit_open = true
	audit_reset_confirm = false
	audit_notice = ""
	_audit_refresh_panel()
	return true


func audit_return_to_play() -> bool:
	if not audit_valid or not audit_started:
		return false
	audit_open = false
	audit_reset_confirm = false
	pause_menu_open = false
	main_menu_active = false
	sim_speed = audit_speed
	_audit_refresh_panel()
	return true


func audit_save() -> bool:
	if not audit_valid or not audit_started:
		return false
	var saved := _save_game()
	audit_notice = _audit_text("saved" if saved else "save_failed")
	_audit_refresh_panel()
	return saved


func audit_set_speed(speed: float) -> bool:
	if not audit_valid or not AUDIT_SPEEDS.has(speed):
		return false
	audit_speed = speed
	sim_speed = speed
	if not audit_speeds_used.has(int(speed)):
		audit_speeds_used.append(int(speed))
	_audit_refresh_panel()
	return true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_audit_quit()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		if audit_open and audit_started:
			audit_return_to_play()
		else:
			audit_open = true
			audit_reset_confirm = false
			_audit_refresh_panel()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not audit_valid or audit_open or not audit_started:
		return
	super._unhandled_input(event)


func _draw() -> void:
	# A rejected exported entry never ran base initialization or loaded fonts.
	if audit_valid and fallback_font != null:
		super._draw()


func _process(delta: float) -> void:
	developer_mode_enabled = false
	if not audit_valid or audit_open or not audit_started:
		if pixel_audio != null:
			pixel_audio.update_context(false, true, game_over, camera_zoom)
		queue_redraw()
		return
	if not pause_menu_open and not campaign_ui.open and not upgrade_open and not goals_open and not chapter_report_open and not offline_report_open and not game_over:
		audit_wall_seconds += maxf(0.0, delta)
	if not game_over:
		sim_speed = audit_speed
	super._process(delta)
	if audit_badge != null:
		audit_badge.text = _audit_text("badge", {"speed": "%d" % audit_speed})


func _audit_clear_modals() -> void:
	game_started = true
	splash_active = false
	first_locale_prompt = false
	main_menu_active = false
	pause_menu_open = false
	pause_menu_page = "main"
	pause_menu_notice = ""
	chapter_report_open = false
	offline_report_open = false
	_reset_offline_settlement_state()
	upgrade_open = false
	goals_open = false
	show_status = false
	_close_barracks_production_menu()
	if campaign_ui != null:
		campaign_ui.reset_panel()
		campaign_ui.failure_presented = false
		campaign_ui._sync_selection()
	mode = "normal"
	dragging = false
	left_selecting = false
	defense_zone_drawing = false
	developer_placement_action = ""


func audit_fingerprint(snapshot: Dictionary) -> String:
	var stable := snapshot.duplicate(true)
	stable.erase("saved_at")
	stable.erase("campaign_audit")
	return JSON.stringify(stable).sha256_text()


func _audit_metadata() -> Dictionary:
	return {
		"schema": AUDIT_SCHEMA, "stage_id": audit_stage_id,
		"preset_id": AuditPresets.preset(audit_stage_id).get("preset_id", audit_stage_id),
		"is_synthetic_fixture": true, "normal_costs": true, "offline_gains": false,
		"initial_conditions": audit_initial_conditions.duplicate(true),
		"initial_fingerprint": audit_initial_hash, "active_wall_seconds": audit_wall_seconds,
		"speed": audit_speed, "speeds_used": audit_speeds_used.duplicate(),
		"source_build": audit_build.duplicate(true), "source_build_origin": audit_origin_build.duplicate(true),
		"loaded_build": audit_loaded_build.duplicate(true),
		"not_campaign_completion_proof": true, "not_player_timing_evidence": true
	}


func _capture_world_state() -> Dictionary:
	var data := super._capture_world_state()
	data["campaign_audit"] = _audit_metadata()
	return data


func _audit_valid_metadata(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var preset := AuditPresets.preset(audit_stage_id)
	if value.get("schema", 0) != AUDIT_SCHEMA or value.get("stage_id", "") != audit_stage_id or value.get("preset_id", "") != preset.get("preset_id", audit_stage_id):
		return false
	if value.get("is_synthetic_fixture", null) != true or value.get("normal_costs", null) != true or value.get("offline_gains", null) != false:
		return false
	if not value.get("initial_conditions", null) is Dictionary or not value.get("initial_fingerprint", null) is String or String(value["initial_fingerprint"]).length() != 64:
		return false
	if not _finite_save_number(value.get("active_wall_seconds", null)) or float(value["active_wall_seconds"]) < 0.0 or not AUDIT_SPEEDS.has(value.get("speed", null)):
		return false
	var speeds = value.get("speeds_used", null)
	if not speeds is Array or speeds.is_empty() or speeds.size() > AUDIT_SPEEDS.size():
		return false
	for speed in speeds:
		if not AUDIT_SPEEDS.has(speed):
			return false
	for key in ["source_build", "source_build_origin", "loaded_build"]:
		if not value.get(key, null) is Dictionary:
			return false
	return true


func _parse_save_payload(payload: String) -> Dictionary:
	if not audit_valid:
		return {}
	# Reject foreign profiles before handing any world data to the base parser.
	var envelope = JSON.parse_string(payload)
	if not envelope is Dictionary or envelope.has("review_slice") or envelope.get("developer_session", null) != false or not _audit_valid_metadata(envelope.get("campaign_audit", null)):
		return {}
	var ledger = envelope.get("campaign", null)
	if not ledger is Dictionary:
		return {}
	var home = ledger.get("home_world", {})
	if home is Dictionary and not home.is_empty():
		if home.has("review_slice") or home.get("developer_session", null) != false or not _audit_valid_metadata(home.get("campaign_audit", null)):
			return {}
	return super._parse_save_payload(payload)


func _commit_world_and_campaign(world: Dictionary) -> bool:
	if not audit_valid or not audit_started or developer_mode_enabled:
		return false
	save_path = audit_directory + "/save.json"
	if DirAccess.make_dir_recursive_absolute(audit_directory) != OK:
		return false
	var data := world.duplicate(true)
	data["campaign_audit"] = _audit_metadata()
	return super._commit_world_and_campaign(data)


func _has_recoverable_save() -> bool:
	if not audit_valid:
		return false
	save_path = audit_directory + "/save.json"
	return super._has_recoverable_save()


func _audit_restore_metadata(data: Dictionary, loading: bool = false) -> void:
	audit_initial_conditions = data.get("initial_conditions", {}).duplicate(true)
	audit_initial_hash = String(data.get("initial_fingerprint", ""))
	audit_wall_seconds = float(data.get("active_wall_seconds", 0.0))
	audit_speed = float(data.get("speed", 1.0))
	audit_speeds_used = data.get("speeds_used", [1]).duplicate()
	audit_origin_build = data.get("source_build_origin", {}).duplicate(true)
	audit_loaded_build = data.get("source_build" if loading else "loaded_build", {}).duplicate(true)


func _load_game(_defer_offline: bool = false) -> bool:
	if not audit_valid:
		return false
	save_path = audit_directory + "/save.json"
	var inspected := SaveStore.inspect(save_path, Callable(self, "_parse_save_payload"))
	if inspected.is_empty():
		return false
	if not super._load_game(false):
		return false
	_audit_restore_metadata(inspected["data"]["campaign_audit"], true)
	sim_speed = audit_speed
	return true


func _load_settings() -> void:
	developer_mode_enabled = false
	if not audit_valid:
		return
	var file := FileAccess.open(audit_directory + "/settings.json", FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return
	settings_locale = UILocalization.normalize_locale(String(data.get("locale", "zh_CN")))
	settings_fullscreen = bool(data.get("fullscreen", false))
	settings_pixel_cursor = bool(data.get("pixel_cursor", true))
	for pair in [["master_volume", "settings_master_volume"], ["ui_volume", "settings_ui_volume"], ["world_volume", "settings_world_volume"], ["combat_volume", "settings_combat_volume"], ["ambient_volume", "settings_ambient_volume"]]:
		var amount = data.get(pair[0], get(pair[1]))
		if _finite_save_number(amount):
			set(pair[1], clampf(float(amount), 0.0, 1.0))


func _save_settings() -> void:
	if not audit_valid or DirAccess.make_dir_recursive_absolute(audit_directory) != OK:
		return
	var file := FileAccess.open(audit_directory + "/settings.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"locale": settings_locale, "fullscreen": settings_fullscreen, "pixel_cursor": settings_pixel_cursor,
			"master_volume": settings_master_volume, "ui_volume": settings_ui_volume,
			"world_volume": settings_world_volume, "combat_volume": settings_combat_volume,
			"ambient_volume": settings_ambient_volume
		}))


func _switch_developer_profile(_enabled: bool) -> void:
	developer_mode_enabled = false
	audit_notice = _audit_text("locked")
	audit_open = true
	_audit_refresh_panel()


func _enter_developer_mode() -> void:
	_switch_developer_profile(true)


func _exit_developer_mode() -> void:
	developer_mode_enabled = false
	save_path = audit_directory + "/save.json"


func _start_new_culture(scene_id: String = "home_nest", retain_previous: bool = false, prepared_world: Node2D = null) -> bool:
	var started := super._start_new_culture(scene_id, retain_previous, prepared_world)
	if started:
		sim_speed = audit_speed
	return started


func _settle_home_elapsed(_parsed: Dictionary, _deferred: bool) -> void:
	_reset_offline_settlement_state()
	sim_speed = 0.0 if game_over else audit_speed


func _return_to_main_menu() -> void:
	if audit_started and not _save_game():
		audit_notice = _audit_text("save_failed")
	main_menu_active = false
	pause_menu_open = false
	audit_open = true
	_audit_refresh_panel()


func _start_game_from_menu() -> void:
	audit_return_to_play()


func _begin_new_culture() -> void:
	audit_open = true
	audit_reset_confirm = false
	_audit_new_clicked()


func audit_export_report() -> bool:
	if not audit_valid or not audit_started:
		return false
	var report := _audit_metadata()
	report["exported_utc"] = Time.get_datetime_string_from_system(true)
	report["current_world_scene_id"] = _world_scene_id()
	report["save_path"] = ProjectSettings.globalize_path(save_path)
	report["save_isolated"] = true
	report["campaign"] = campaign.duplicate(true)
	report["campaign"].erase("home_world")
	report["current"] = {
		"organic": organic, "mineral": mineral, "dna": dna, "sim_seconds": sim_time,
		"living_cores": _living_core_count(), "units": expedition_units.size(),
		"mission_state": world_runtime.data.get("mission_state", {}).duplicate(true)
	}
	var path := audit_directory + "/report.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		audit_notice = _audit_text("save_failed")
		_audit_refresh_panel()
		return false
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	audit_notice = _audit_text("report_saved", {"path": ProjectSettings.globalize_path(path)})
	_audit_refresh_panel()
	return true


func _audit_quit() -> void:
	if audit_started and not _save_game():
		audit_open = true
		audit_notice = _audit_text("save_failed")
		_audit_refresh_panel()
		return
	get_tree().quit()
