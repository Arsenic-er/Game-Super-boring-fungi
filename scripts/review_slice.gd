extends "res://scripts/main.gd"

# This entry scene is deliberately separate from the shipped campaign entry.
# It reuses the live game simulation and campaign scene transitions, but owns
# every persistence path and never opens normal/developer profiles.
const ReviewWords = preload("res://scripts/review_slice_localization.gd")
const ReviewCampaignController = preload("res://scripts/review_campaign_controller.gd")
const ReviewObjectives = preload("res://scripts/review_objectives.gd")
const REVIEW_SCHEMA := 1
const REVIEW_ROOT := "user://review-v1"
const REVIEW_HOME_SEED := 0xF00D47
const REVIEW_BUILD_INFO := "res://review_build_info.json"
const REVIEW_SPEEDS := [1.0, 5.0, 20.0]
var review_arguments: Array[String] = []
var review_mission_id := ""
var review_profile := "baseline"
var review_valid := false
var review_started := false
var review_open := true
var review_reset_confirm := false
var review_notice := ""
var review_initial_hash := ""
var review_initial_conditions: Dictionary = {}
var review_wall_seconds := 0.0
var review_speeds_used: Array = [1]
var review_speed := 1.0
var review_result: Dictionary = {}
var review_build: Dictionary = {"status": "development", "commit": "unreleased"}
var review_origin_build: Dictionary = {}
var review_loaded_build: Dictionary = {}
var review_requested_locale := ""
var review_error_detail := ""
var review_directory := ""
var review_panel: PanelContainer
var review_body: Label
var review_title: Label
var review_buttons: Dictionary = {}
var review_badge: Label
var review_scroll: ScrollContainer
var review_layer: CanvasLayer
var review_refresh_clock := 0.0
var review_home_restored := false
var review_last_outcome := ""


func _chapter_guidance_rect() -> Rect2:
	return ReviewObjectives.hud_rect(self, super._chapter_guidance_rect())


func _is_review_entry() -> bool:
	return true


func _ready() -> void:
	var arguments: Array = review_arguments if not review_arguments.is_empty() else Array(OS.get_cmdline_user_args())
	review_configure(arguments)
	# Base _ready asks about saves and settings; isolate before it can do so.
	autosave_enabled = false
	developer_mode_enabled = false
	super._ready()
	campaign_ui = ReviewCampaignController.new(self)
	campaign_ui._sync_selection()
	developer_mode_enabled = false
	developer_previous_save_path = ""
	splash_active = false
	main_menu_active = false
	first_locale_prompt = false
	game_started = false
	pause_menu_open = false
	if not review_requested_locale.is_empty():
		settings_locale = review_requested_locale
		_apply_settings()
	_review_load_build_info()
	_review_create_panel()
	_review_refresh_panel()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if review_valid:
		print("REVIEW_SLICE_READY mission=", review_mission_id, " slot=", save_path, " loaded_existing=false developer=false")
	else:
		print("REVIEW_SLICE_INVALID ", review_error_detail)
		if DisplayServer.get_name() == "headless":
			get_tree().quit(2)


func review_configure(arguments: Array) -> bool:
	review_valid = false
	review_error_detail = ""
	review_mission_id = ""
	review_requested_locale = ""
	var seen := {}
	for item in arguments:
		var value := String(item)
		if not value.begins_with("--review-"):
			continue
		var parts := value.split("=", true, 1)
		if parts.size() != 2 or seen.has(parts[0]):
			review_error_detail = "Missing value or duplicate option: " + value
			break
		seen[parts[0]] = true
		match parts[0]:
			"--review-mission": review_mission_id = parts[1]
			"--review-lang":
				if not UILocalization.LOCALES.has(parts[1]):
					review_error_detail = "Unknown locale"
					break
				review_requested_locale = parts[1]
			"--review-profile":
				if parts[1] != "baseline":
					review_error_detail = "Only the baseline paid profile is supported"
					break
			_:
				review_error_detail = "Unknown review option"
				break
	if not CampaignState.Catalog.is_implemented(review_mission_id):
		review_error_detail = "Unknown or missing mission ID"
	review_valid = review_error_detail.is_empty()
	review_directory = REVIEW_ROOT + "/" + (review_mission_id if review_valid else "invalid")
	save_path = review_directory + "/save.json"
	if review_valid and DirAccess.make_dir_recursive_absolute(review_directory) != OK:
		review_valid = false
		review_error_detail = "Cannot create isolated review directory"
	return review_valid


func _review_load_build_info() -> void:
	if FileAccess.file_exists(REVIEW_BUILD_INFO):
		var file := FileAccess.open(REVIEW_BUILD_INFO, FileAccess.READ)
		if file != null:
			var data = JSON.parse_string(file.get_as_text())
			if data is Dictionary:
				review_build = data.duplicate(true)


func _review_text(key: String) -> String:
	return ReviewWords.text(settings_locale, key)


func review_title_text() -> String:
	if not review_valid:
		return _review_text("title")
	return campaign_ui.chapter_text(review_mission_id + "_title")


func _review_create_panel() -> void:
	review_layer = CanvasLayer.new()
	review_layer.layer = 100
	add_child(review_layer)
	var root := Control.new()
	root.name = "ReviewOverlay"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	review_layer.add_child(root)
	review_panel = PanelContainer.new()
	review_panel.name = "ReviewPanel"
	root.add_child(review_panel)
	review_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	review_panel.offset_left = 16
	review_panel.offset_top = 16
	review_panel.offset_right = -16
	review_panel.offset_bottom = -16
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b1a26")
	style.border_color = Color("78c9a5")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	review_panel.add_theme_stylebox_override("panel", style)
	review_panel.add_theme_font_override("font", fallback_font)
	review_panel.add_theme_font_size_override("font_size", 16)
	var content := VBoxContainer.new()
	content.name = "ReviewContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	review_panel.add_child(content)
	review_title = Label.new()
	review_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	review_title.add_theme_font_size_override("font_size", 22)
	review_title.add_theme_color_override("font_color", Color("bcf4d3"))
	content.add_child(review_title)
	var actions := GridContainer.new()
	actions.name = "ReviewActions"
	actions.columns = 3
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	content.add_child(actions)
	_review_button(actions, "new", _review_new_clicked)
	_review_button(actions, "continue", review_continue)
	_review_button(actions, "play", review_return_to_play)
	_review_button(actions, "save", review_save)
	_review_button(actions, "report", review_export_report)
	_review_button(actions, "cancel", _review_cancel_reset)
	for speed in REVIEW_SPEEDS:
		var button := _review_button(actions, "speed_%d" % speed, review_set_speed.bind(speed))
		button.text = "%d×" % speed
	_review_button(actions, "quit", _review_quit)
	review_scroll = ScrollContainer.new()
	review_scroll.name = "ReviewScroll"
	review_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	review_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(review_scroll)
	review_body = Label.new()
	review_body.name = "ReviewReadout"
	review_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	review_body.add_theme_color_override("font_color", Color("d5e5e3"))
	review_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	review_scroll.add_child(review_body)
	review_badge = Label.new()
	review_badge.name = "ReviewBadge"
	review_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	review_badge.add_theme_font_override("font", fallback_font)
	review_badge.add_theme_font_size_override("font_size", 12)
	review_badge.add_theme_color_override("font_color", Color("c7e5b1"))
	root.add_child(review_badge)
	review_badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	review_badge.offset_left = -160
	review_badge.offset_right = 160
	review_badge.offset_top = -22
	review_badge.offset_bottom = -3
	review_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _review_button(parent: Control, key: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = "Review_" + key
	button.custom_minimum_size = Vector2(0, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(callback)
	button.mouse_entered.connect(func(): _play_sound("ui_hover"))
	parent.add_child(button)
	review_buttons[key] = button
	return button


func _review_refresh_panel() -> void:
	if review_panel == null:
		return
	review_panel.visible = review_open
	review_badge.visible = review_valid and review_started and not review_open
	review_badge.text = _review_text("badge") % ("%d" % review_speed)
	review_title.text = _review_text("title") + " — " + review_title_text()
	var paragraphs: Array[String] = []
	if not review_valid:
		paragraphs.append(_review_text("error") + "\n" + review_error_detail)
	else:
		var briefing := ReviewObjectives.briefing(self)
		if not briefing.is_empty():
			paragraphs.append(briefing)
		paragraphs.append(_review_text("intro"))
		paragraphs.append(_review_text("fixture"))
		paragraphs.append(_review_text("controls"))
		paragraphs.append(_review_text("no_timing"))
		paragraphs.append(_review_text("build") + ": " + String(review_build.get("commit", "development")).left(12) + " / " + String(review_build.get("sourcehash", "unreleased")).left(12))
		paragraphs.append(_review_text("scene") + ": " + review_mission_id + " / home " + str(REVIEW_HOME_SEED) + " / map " + str(review_map_seed()))
		paragraphs.append(_review_text("tier") + ": " + str(CampaignState.Catalog.mission(review_mission_id)["required_nest_level"]))
		paragraphs.append(_review_text("location") + ": " + ProjectSettings.globalize_path(save_path))
		if review_started:
			paragraphs.append(_review_text("initial") + ": " + review_initial_hash)
			paragraphs.append(_review_text("resources") + ": organic %.3f · mineral %.3f · DNA %d" % [organic, mineral, dna])
			paragraphs.append(_review_text("time") + ": %.3f / %.3f / %s" % [sim_time, review_wall_seconds, JSON.stringify(review_speeds_used)])
			if not _campaign_active():
				paragraphs.append(_review_text("finished"))
			paragraphs.append(_review_text("result") + ": " + _review_text("status_" + String(review_result.get("outcome", "unsettled"))))
		else:
			paragraphs.append(_review_text("paused"))
		if review_reset_confirm:
			paragraphs.append(_review_text("confirm"))
		if not review_notice.is_empty():
			paragraphs.append(review_notice)
	review_body.text = "\n\n".join(paragraphs)
	for key in review_buttons:
		var button: Button = review_buttons[key]
		if not String(key).begins_with("speed_"):
			button.text = _review_text("yes" if key == "new" and review_reset_confirm else key)
		button.disabled = not review_valid and key != "quit"
	review_buttons["continue"].disabled = not review_valid or not _has_recoverable_save()
	review_buttons["play"].disabled = not review_started
	review_buttons["save"].disabled = not review_started
	review_buttons["report"].disabled = not review_started
	review_buttons["cancel"].visible = review_reset_confirm


func _review_new_clicked() -> void:
	if not review_valid:
		return
	if not review_reset_confirm and (review_started or _has_recoverable_save()):
		review_reset_confirm = true
		_review_refresh_panel()
		return
	review_start_new()


func _review_cancel_reset() -> void:
	review_reset_confirm = false
	_review_refresh_panel()


func review_start_new() -> bool:
	if not review_valid:
		return false
	_play_sound("ui_confirm")
	autosave_enabled = false
	developer_mode_enabled = false
	review_started = false
	review_reset_confirm = false
	review_notice = ""
	review_result = {}
	review_home_restored = false
	review_origin_build = review_build.duplicate(true)
	review_loaded_build = review_build.duplicate(true)
	review_last_outcome = ""
	review_initial_conditions = {}
	review_wall_seconds = 0.0
	review_speeds_used = [1]
	review_speed = 1.0
	review_initial_hash = ""
	save_path = review_directory + "/save.json"
	if not _start_new_culture("home_nest"):
		review_notice = _review_text("save_failed")
		_review_refresh_panel()
		return false
	if not _complete_founder_spore_germination():
		review_notice = _review_text("save_failed")
		_review_refresh_panel()
		return false
	# The real germination routine creates the main core. This fixed review
	# fixture removes its ambient rival; all three trial scripts clear it too.
	enemy_fungi.clear()
	enemy_hyphae.clear()
	enemy_guard_spores.clear()
	enemy_fungi_initialized = true
	var entry := CampaignState.Catalog.mission(review_mission_id)
	campaign["nest_level"] = int(entry["required_nest_level"])
	campaign["materials"] = 0
	# Synthetic access flags never enter a normal slot and are disclosed in
	# every report. They are not earned victories or a progression test.
	var access_flags: Array[String] = []
	for earlier in CampaignState.Catalog.entries():
		if int(earlier["order"]) < int(entry["order"]):
			campaign["completed"][String(earlier["id"])] = true
			access_flags.append(String(earlier["id"]))
	campaign = CampaignState.sanitize(campaign)
	review_initial_conditions = {
		"fixture": "minimal_settled_home_v1", "profile": review_profile,
		"home_seed": REVIEW_HOME_SEED, "starting_organic": 220.0,
		"starting_mineral": 24.0, "starting_dna": 0,
		"prepared_cores": 1, "prepared_segments": 0, "prepared_units": 0,
		"required_nest_level": int(entry["required_nest_level"]),
		"synthetic_access_flags": access_flags,
		"earned_prior_victories": false, "branches": {"transport": 0, "resilience": 0, "defense": 0},
		"research_levels": 0, "unit_licenses": {"forager": true},
		"normal_costs": true, "developer_mode": false, "offline_gains": false,
		"tier_passives_apply_to_trials": true, "late_campaign_home_representative": false
	}
	review_initial_hash = review_fingerprint(super._capture_world_state())
	review_started = true
	game_started = true
	main_menu_active = false
	pause_menu_open = false
	campaign_ui.selected_mission_id = review_mission_id
	chapter_report_open = false
	offline_report_open = false
	campaign_ui.open = false
	autosave_enabled = true
	if not campaign_ui.start_mission(review_mission_id):
		review_started = false
		autosave_enabled = false
		review_notice = _review_text("save_failed")
		_review_refresh_panel()
		return false
	review_initial_conditions["mission_initial_entities"] = {
		"cores_total": cores.size(), "cores_alive": _living_core_count(),
		"segments": segments.size(), "units": expedition_units.size(),
		"bacteria": bacteria.size(), "enemy_cores": enemy_fungi.size(),
		"resource_particles": resources.size(), "map_seed": review_map_seed()
	}
	review_initial_hash = review_fingerprint(super._capture_world_state())
	if not _save_game():
		review_notice = _review_text("save_failed")
		_review_refresh_panel()
		return false
	review_open = true
	_review_refresh_panel()
	return true


func review_map_seed() -> int:
	var definition := WorldSceneCatalog.prepare(review_mission_id)
	if definition == null:
		return REVIEW_HOME_SEED
	var value := REVIEW_HOME_SEED
	if review_mission_id in ["first_supply", "remote_pantry"]:
		value = int(definition.MAP_SEED)
	elif review_mission_id in ["substrate_race", "lost_network", "toxic_frontier", "boundary_counterattack"]:
		value = int(definition.map_seed)
	definition.free()
	return value


func review_fingerprint(snapshot: Dictionary) -> String:
	var stable := snapshot.duplicate(true)
	stable.erase("saved_at")
	stable.erase("review_slice")
	return JSON.stringify(stable).sha256_text()


func review_return_to_play() -> bool:
	if not review_valid or not review_started:
		return false
	review_reset_confirm = false
	review_open = false
	review_panel.visible = false
	pause_menu_open = false
	main_menu_active = false
	sim_speed = review_speed
	_play_sound("ui_confirm")
	_review_refresh_panel()
	return true


func review_save() -> bool:
	if not review_started:
		return false
	var saved := _save_game()
	review_notice = _review_text("saved" if saved else "save_failed")
	_review_refresh_panel()
	return saved


func review_continue() -> bool:
	if not review_valid:
		return false
	developer_mode_enabled = false
	save_path = review_directory + "/save.json"
	if not _load_game(false):
		review_notice = _review_text("save_failed")
		_review_refresh_panel()
		return false
	review_started = true
	_review_clear_modals()
	autosave_enabled = true
	review_open = true
	review_reset_confirm = false
	review_notice = ""
	_review_refresh_panel()
	return true


func review_set_speed(speed: float) -> bool:
	if not review_valid or not REVIEW_SPEEDS.has(speed):
		return false
	review_speed = speed
	sim_speed = speed
	if not review_speeds_used.has(int(speed)):
		review_speeds_used.append(int(speed))
	_review_refresh_panel()
	return true


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		if review_open and review_started:
			review_return_to_play()
		else:
			review_open = true
			review_reset_confirm = false
			_review_refresh_panel()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if review_open or not review_valid or not review_started:
		return
	super._unhandled_input(event)
	_review_detect_settlement()


func _process(delta: float) -> void:
	developer_mode_enabled = false
	if not review_valid or review_open or not review_started:
		if pixel_audio != null:
			pixel_audio.update_context(false, true, game_over, camera_zoom)
		queue_redraw()
		return
	if _campaign_active() and not pause_menu_open and not campaign_ui.open and not upgrade_open and not goals_open and not chapter_report_open and not offline_report_open and not game_over:
		review_wall_seconds += maxf(0.0, delta)
	super._process(delta)
	if _campaign_active() and not bool(review_result.get("settled", false)):
		var outcome := "failure" if game_over else ("objectives_met" if _campaign_mission_ready() else "unsettled")
		if outcome != "unsettled" and review_last_outcome != outcome:
			review_last_outcome = outcome
			review_result = _review_result_snapshot(outcome, false)
			review_open = true
			_save_game()
			_review_refresh_panel()
	_review_detect_settlement()
	review_refresh_clock += delta
	if review_refresh_clock >= 0.4:
		review_refresh_clock = 0.0
		if review_badge != null:
			review_badge.text = _review_text("badge") % ("%d" % review_speed)


func _review_detect_settlement() -> void:
	if not review_started or _campaign_active() or review_home_restored or _world_scene_id() != "home_nest":
		return
	var last: Dictionary = campaign.get("last_result", {})
	if String(last.get("mission_id", "")) != review_mission_id:
		return
	# The transaction already saved the mission result with the restored home.
	# Release its UI once; later frames must neither re-save nor close home menus.
	review_home_restored = true
	_review_clear_modals()
	review_reset_confirm = false
	review_notice = ""
	review_open = false
	sim_speed = review_speed
	_review_refresh_panel()


func _review_clear_modals() -> void:
	game_started = true
	splash_active = false
	first_locale_prompt = false
	pause_menu_open = false
	pause_menu_page = "main"
	pause_menu_notice = ""
	main_menu_active = false
	chapter_report_open = false
	offline_report_open = false
	_reset_offline_settlement_state()
	upgrade_open = false
	goals_open = false
	show_status = false
	_close_barracks_production_menu()
	campaign_ui.reset_panel()
	campaign_ui.failure_presented = false
	campaign_ui._sync_selection()
	mode = "normal"
	dragging = false
	left_selecting = false
	defense_zone_drawing = false
	developer_placement_action = ""


func _review_result_snapshot(outcome: String, settled: bool) -> Dictionary:
	return {
		"outcome": outcome, "settled": settled, "sim_seconds": sim_time,
		"world_scene_id": _world_scene_id(),
		"active_wall_seconds": review_wall_seconds, "speeds_used": review_speeds_used.duplicate(),
		"organic": organic, "mineral": mineral, "dna": dna,
		"absorbed_organic": lifetime_organic_absorbed, "absorbed_mineral": lifetime_mineral_absorbed,
		"returned_organic": lifetime_expedition_organic_returned, "returned_mineral": lifetime_expedition_mineral_returned,
		"units_built": lifetime_expedition_units_built, "units_lost": lifetime_expedition_units_lost,
		"living_cores": _living_core_count(), "living_hypha_world": _chapter_living_hypha_length(),
		"enemy_cores_defeated": lifetime_enemy_fungi_defeated,
		"enemy_guards_defeated": lifetime_enemy_guards_defeated,
		"mission_state": world_runtime.data.get("mission_state", {}).duplicate(true),
		"objective_readout": review_objective_readout()
	}


func review_objective_readout() -> String:
	if _world_scene_id() != review_mission_id:
		return ""
	var rows: Array[Dictionary] = active_world.mission_status(self)
	if rows.is_empty():
		return campaign_ui.progress_text(false)
	var lines: Array[String] = []
	for row in rows:
		lines.append(campaign_ui.chapter_text(String(row["key"])) + ": %.3f / %.3f" % [float(row["current"]), float(row["target"])])
	return " · ".join(lines)


func _review_build_identity(value: Dictionary) -> String:
	return String(value.get("commit", "development")) + ":" + String(value.get("sourcehash", "unreleased"))


func _review_metadata() -> Dictionary:
	return {
		"schema": REVIEW_SCHEMA, "mission_id": review_mission_id, "profile": review_profile,
		"initial_fingerprint": review_initial_hash, "initial_conditions": review_initial_conditions.duplicate(true),
		"active_wall_seconds": review_wall_seconds, "speeds_used": review_speeds_used.duplicate(),
		"speed": review_speed, "result": review_result.duplicate(true),
		"source_build": review_build.duplicate(true), "source_build_origin": review_origin_build.duplicate(true),
		"loaded_build": review_loaded_build.duplicate(true), "not_campaign_progress": true
	}


func _capture_world_state() -> Dictionary:
	var state := super._capture_world_state()
	state["review_slice"] = _review_metadata()
	return state


func _parse_save_payload(payload: String) -> Dictionary:
	if not review_valid:
		return {}
	var parsed := super._parse_save_payload(payload)
	if parsed.is_empty():
		return {}
	var metadata = parsed.get("review_slice", null)
	if not metadata is Dictionary or metadata.get("schema", 0) != REVIEW_SCHEMA or metadata.get("mission_id", "") != review_mission_id or metadata.get("profile", "") != review_profile or metadata.get("not_campaign_progress", false) != true:
		return {}
	if not metadata.get("initial_fingerprint", null) is String or String(metadata["initial_fingerprint"]).length() != 64 or not metadata.get("initial_conditions", null) is Dictionary or not metadata.get("result", null) is Dictionary:
		return {}
	var wall = metadata.get("active_wall_seconds", null)
	if not _finite_save_number(wall) or float(wall) < 0.0 or not REVIEW_SPEEDS.has(metadata.get("speed", null)):
		return {}
	var speeds = metadata.get("speeds_used", null)
	if not speeds is Array or speeds.is_empty() or speeds.size() > 3:
		return {}
	for speed in speeds:
		if not REVIEW_SPEEDS.has(speed):
			return {}
	var active: Dictionary = parsed.get("campaign", {}).get("active_mission", {})
	if not active.is_empty() and active.get("id", "") != review_mission_id:
		return {}
	if bool(parsed.get("developer_session", true)):
		return {}
	return parsed


func _commit_world_and_campaign(world: Dictionary) -> bool:
	if not review_valid or not review_started or developer_mode_enabled:
		return false
	save_path = review_directory + "/save.json"
	if _campaign_active() and String(campaign["active_mission"].get("id", "")) != review_mission_id:
		return false
	var previous_result := review_result.duplicate(true)
	if not _campaign_active() and _world_scene_id() == review_mission_id:
		var last: Dictionary = campaign.get("last_result", {})
		if String(last.get("mission_id", "")) == review_mission_id:
			review_result = _review_result_snapshot(String(last.get("outcome", "unsettled")), true)
			review_result["campaign_result"] = last.duplicate(true)
	var isolated := world.duplicate(true)
	isolated["review_slice"] = _review_metadata()
	var saved := super._commit_world_and_campaign(isolated)
	if not saved:
		review_result = previous_result
	return saved


func _has_recoverable_save() -> bool:
	if not review_valid:
		return false
	save_path = review_directory + "/save.json"
	return super._has_recoverable_save()


func _load_game(_defer_offline: bool = false) -> bool:
	if not review_valid:
		return false
	save_path = review_directory + "/save.json"
	var inspected := SaveStore.inspect(save_path, Callable(self, "_parse_save_payload"))
	if inspected.is_empty():
		return false
	var metadata: Dictionary = inspected["data"]["review_slice"]
	if not super._load_game(false):
		return false
	review_initial_hash = String(metadata["initial_fingerprint"])
	review_initial_conditions = metadata["initial_conditions"].duplicate(true)
	review_wall_seconds = float(metadata["active_wall_seconds"])
	review_speeds_used = metadata["speeds_used"].duplicate()
	review_speed = float(metadata["speed"])
	review_result = metadata["result"].duplicate(true)
	review_home_restored = not _campaign_active() and _world_scene_id() == "home_nest"
	var origin = metadata.get("source_build_origin", metadata.get("source_build", {}))
	review_origin_build = origin.duplicate(true) if origin is Dictionary else {}
	var loaded = metadata.get("source_build", {})
	review_loaded_build = loaded.duplicate(true) if loaded is Dictionary else {}
	review_last_outcome = String(review_result.get("outcome", ""))
	sim_speed = review_speed
	return true


func _load_settings() -> void:
	developer_mode_enabled = false
	if not review_valid:
		return
	var file := FileAccess.open(review_directory + "/settings.json", FileAccess.READ)
	if file == null:
		return
	var value = JSON.parse_string(file.get_as_text())
	if not value is Dictionary:
		return
	settings_locale = UILocalization.normalize_locale(String(value.get("locale", "zh_CN")))
	settings_fullscreen = bool(value.get("fullscreen", false))
	settings_pixel_cursor = bool(value.get("pixel_cursor", true))
	for pair in [["master_volume", "settings_master_volume"], ["ui_volume", "settings_ui_volume"], ["world_volume", "settings_world_volume"], ["combat_volume", "settings_combat_volume"], ["ambient_volume", "settings_ambient_volume"]]:
		var amount = value.get(pair[0], get(pair[1]))
		if _finite_save_number(amount):
			set(pair[1], clampf(float(amount), 0.0, 1.0))


func _save_settings() -> void:
	if not review_valid:
		return
	var file := FileAccess.open(review_directory + "/settings.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"locale": settings_locale, "fullscreen": settings_fullscreen, "pixel_cursor": settings_pixel_cursor,
			"master_volume": settings_master_volume, "ui_volume": settings_ui_volume,
			"world_volume": settings_world_volume, "combat_volume": settings_combat_volume,
			"ambient_volume": settings_ambient_volume
		}))


func _prepare_world_scene(scene_id: String) -> Node2D:
	if scene_id != "home_nest" and (not review_valid or scene_id != review_mission_id):
		return null
	return super._prepare_world_scene(scene_id)


func _switch_developer_profile(_enabled: bool) -> void:
	developer_mode_enabled = false
	review_notice = _review_text("locked")
	review_open = true
	_review_refresh_panel()


func _enter_developer_mode() -> void:
	_switch_developer_profile(true)


func _exit_developer_mode() -> void:
	developer_mode_enabled = false
	save_path = review_directory + "/save.json"


func _settle_home_elapsed(_parsed: Dictionary, _deferred: bool) -> void:
	_reset_offline_settlement_state()


func _return_to_main_menu() -> void:
	if review_started:
		_save_game()
	main_menu_active = false
	pause_menu_open = false
	review_open = true
	_review_refresh_panel()


func _start_game_from_menu() -> void:
	review_return_to_play()


func _begin_new_culture() -> void:
	review_open = true
	review_reset_confirm = false
	_review_new_clicked()


func review_export_report() -> bool:
	if not review_valid or not review_started:
		return false
	var report := {
		"review_schema": REVIEW_SCHEMA, "exported_utc": Time.get_datetime_string_from_system(true),
		"build": review_build.duplicate(true), "mission_id": review_mission_id, "profile": review_profile,
		"source_build_origin": review_origin_build.duplicate(true), "loaded_build": review_loaded_build.duplicate(true),
		"has_build_change": _review_build_identity(review_origin_build) != _review_build_identity(review_build),
		"current_world_scene_id": _world_scene_id(),
		"scene_path": WorldSceneCatalog.PATHS[review_mission_id], "scene_revision": WorldSceneCatalog.REVISION,
		"initial_fingerprint": review_initial_hash, "initial_conditions": review_initial_conditions.duplicate(true),
		"save_path": ProjectSettings.globalize_path(save_path), "save_isolated": true,
		"normal_costs": not developer_mode_enabled, "offline_gains": false,
		"current": _review_result_snapshot("unsettled", false), "result": review_result.duplicate(true),
		"not_campaign_completion_proof": true, "not_player_timing_evidence": true
	}
	var path := review_directory + "/report.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		review_notice = _review_text("save_failed")
		_review_refresh_panel()
		return false
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	review_notice = _review_text("report_saved") + "\n" + ProjectSettings.globalize_path(path)
	_review_refresh_panel()
	return true


func _review_quit() -> void:
	if review_started:
		_save_game()
	get_tree().quit()
