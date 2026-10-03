extends SceneTree

const State = preload("res://scripts/campaign_state.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const Words = preload("res://scripts/developer_localization.gd")
const NORMAL := "user://developer_campaign_normal_smoke.json"
const WRONG := "user://developer_campaign_wrong_smoke.json"
const ACTIONS := ["campaign_nest_down", "campaign_nest_up", "campaign_material_down", "campaign_material_up", "campaign_start", "campaign_return"]
const EDITS := ["campaign_nest_down", "campaign_nest_up", "campaign_material_down", "campaign_material_up"]

var game: Node
var checks := 0
var owns_slots := false
var blocked := false
var normal_bytes := ""
var developer_path := ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.splash_active = false
	game.autosave_enabled = false
	developer_path = String(game.DEVELOPER_SAVE_PATH)
	for slot in [NORMAL, WRONG, developer_path]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			if not _check(not FileAccess.file_exists(slot + suffix) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(slot + suffix)), "isolated HOME required; never overwrite an existing slot: " + slot + suffix):
				return
	owns_slots = true
	game.developer_mode_enabled = false
	game.save_path = NORMAL
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.main_menu_active = false
	game.game_started = true
	game.organic = 431.125
	if not _check(game._save_game(), "normal checkpoint exists before all developer actions"):
		return
	normal_bytes = _read(NORMAL)
	var original: Dictionary = game.campaign.duplicate(true)
	for action in ACTIONS:
		if not _check(not game.campaign_ui.developer_action_reason(action).is_empty() and not game.campaign_ui.developer_apply_action(action) and game.campaign == original and _read(NORMAL) == normal_bytes, action + " cannot alter normal state or disk"):
			return
	game._enter_developer_mode()
	game.save_path = WRONG
	for action in ACTIONS:
		if not _check(game.campaign_ui.developer_action_reason(action) == "campaign_dev_only" and not game.campaign_ui.developer_apply_action(action) and game.campaign == original and not FileAccess.file_exists(WRONG), action + " rejects a wrong path even with developer mode enabled"):
			return
	game.save_path = developer_path
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	# Developer home normally starts germinated; explicitly test a mobile founder.
	game.cores.clear()
	game.founder_spore = game._make_founder_spore(Vector2.ZERO)
	_open_dev()
	for action in EDITS + ["campaign_start"]:
		if not _check(game.campaign_ui.developer_action_reason(action) == "campaign_settle_first" and not game.campaign_ui.developer_apply_action(action), action + " requires a germinated live home"):
			return
	game._complete_founder_spore_germination()
	game.campaign.serial = 17
	if not _check(game._save_game(), "developer checkpoint uses its strict isolated path"):
		return
	var main_core: int = game.campaign.main_core_id
	if not _limits_and_persistence(main_core) or not _layout("home") or not _transaction_and_mission(main_core):
		return
	if not _check(_read(NORMAL) == normal_bytes and not FileAccess.file_exists(WRONG), "all edits, failures, reloads and return preserve normal bytes and wrong path"):
		return
	_cleanup()
	for player in game.pixel_audio.players:
		player.stop()
		player.stream = null
	game.pixel_audio.ambient_player.stop()
	game.pixel_audio.ambient_player.stream = null
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("DEVELOPER_CAMPAIGN_OK checks=%d isolation=normal+path bounds=1-%d+0-%d rollback=edit+departure return=confirmed locales=7 viewports=2" % [checks, State.MAX_NEST_LEVEL, State.MAX_MATERIALS])
	quit(0)

func _limits_and_persistence(main_core: int) -> bool:
	for action in ["campaign_nest_down", "campaign_material_down"]:
		if not _unchanged_rejection(action, "campaign_limit"):
			return false
	if not _check(game.campaign_ui.developer_apply_action("campaign_nest_up") and game.campaign.nest_level == 2 and bool(game.campaign.completed.get(State.MISSION_ID, false)), "raising the nest to two uses sanitize's permanent first-win flag"):
		return false
	if not _unchanged_rejection("campaign_nest_up", "campaign_limit"):
		return false
	if not _check(game.campaign_ui.developer_apply_action("campaign_nest_down") and game.campaign.nest_level == 1 and bool(game.campaign.completed.get(State.MISSION_ID, false)), "downgrade preserves the unique-reward flag"):
		return false
	for value in range(1, State.MAX_MATERIALS + 1):
		if not _check(game.campaign_ui.developer_apply_action("campaign_material_up") and game.campaign.materials == value, "materials rise one step and autosave: %d" % value):
			return false
	if not _unchanged_rejection("campaign_material_up", "campaign_limit"):
		return false
	for value in range(State.MAX_MATERIALS - 1, -1, -1):
		if not _check(game.campaign_ui.developer_apply_action("campaign_material_down") and game.campaign.materials == value, "materials fall one step and autosave: %d" % value):
			return false
	if not _unchanged_rejection("campaign_material_down", "campaign_limit"):
		return false
	var persisted: Dictionary = game.campaign.duplicate(true)
	if not _check(game._load_game(true) and game.campaign == persisted and int(game.campaign.serial) == 17 and int(game.campaign.main_core_id) == main_core, "real developer reload retains all edits, serial, main core and reward ledger"):
		return false
	_open_dev()
	game.campaign_ui.busy = true
	if not _unchanged_rejection("campaign_material_up", "campaign_busy"):
		return false
	game.campaign_ui.busy = false
	game.offline_report_open = true
	if not _unchanged_rejection("campaign_material_up", "campaign_busy"):
		return false
	game.offline_report_open = false
	game.pause_menu_page = "settings"
	if not _unchanged_rejection("campaign_material_up", "campaign_busy"):
		return false
	game.pause_menu_page = "developer"
	return _unchanged_rejection("campaign_return", "campaign_not_in_mission")

func _transaction_and_mission(main_core: int) -> bool:
	_open_dev()
	var before: Dictionary = game.campaign.duplicate(true)
	var world: Dictionary = _signature(game._capture_world_state())
	var disk := _read(developer_path)
	if not _check(_block() and not game.campaign_ui.developer_apply_action("campaign_material_up"), "a real temporary-path directory prevents the edit commit"):
		return false
	if not _check(game.campaign == before and _signature(game._capture_world_state()) == world and _read(developer_path) == disk and game.campaign_ui.notice == game.campaign_ui.text("save_failed"), "failed edit restores memory and disk, and exposes save failure"):
		return false
	if not _check(game._developer_campaign_hint(Vector2(640, 360)) == game.campaign_ui.text("save_failed"), "save failure is visible inside the developer panel"):
		return false
	if not _layout("save_failure"):
		return false
	_unblock()
	if not _check(game.campaign_ui.developer_apply_action("campaign_material_up") and game.campaign.materials == 1 and game.campaign_ui.notice.is_empty(), "successful retry saves once and clears the stale save error"):
		return false
	if not _check(game._developer_campaign_hint(Vector2(640, 360)) != game.campaign_ui.text("save_failed"), "retry removes the save failure from the panel hint"):
		return false
	if not _check(game.campaign_ui.developer_apply_action("campaign_material_down"), "return materials to zero before mission"):
		return false
	before = game.campaign.duplicate(true)
	world = _signature(game._capture_world_state())
	disk = _read(developer_path)
	var old_scene = game.active_world
	var old_runtime = game.world_runtime
	if not _check(_block() and not game.campaign_ui.developer_apply_action("campaign_start"), "real departure commit failure reaches the existing transaction"):
		return false
	if not _check(game.active_world == old_scene and game.world_runtime == old_runtime and _signature(game._capture_world_state()) == world and game.campaign == before and _read(developer_path) == disk, "failed departure retains the original scene, runtime, campaign and disk"):
		return false
	if not _check(game.pause_menu_open and game.pause_menu_page == "developer" and game.developer_page == Words.PAGE_IDS.find("campaign") and not game.campaign_ui.open and game.campaign_ui.notice == game.campaign_ui.text("save_failed"), "failed departure restores the fourth developer page and visible error"):
		return false
	_unblock()
	if not _check(game.campaign_ui.developer_apply_action("campaign_start") and game._campaign_active() and game._world_scene_id() == State.MISSION_ID and game.active_world != old_scene, "developer departure starts the real independent FirstSupply scene"):
		return false
	if not _check(game.developer_page == Words.PAGE_IDS.find("campaign"), "successful departure preserves the fourth developer page for F10"):
		return false
	if not _check(int(game.campaign.serial) == 18 and int(game.campaign.main_core_id) == main_core and int(game.campaign.materials) == 0, "departure preserves main core and materials and advances only the attempt serial"):
		return false
	var home: Dictionary = game.campaign.home_world.duplicate(true)
	if not _check(bool(home.get("developer_session", false)) and not home.has("campaign") and home.get("world_scene_id", "") == "home_nest", "active mission archives a nonrecursive developer home"):
		return false
	var active: Dictionary = game.campaign.duplicate(true)
	var reloaded: bool = game._load_game(true)
	if not _check(reloaded and game._campaign_active() and _persisted(game.campaign) == _persisted(active) and _persisted(game.campaign.home_world) == _persisted(home), "real mission reload preserves every campaign and home field at the exact SaveStore JSON precision"):
		return false
	if not _check(int(game.campaign.serial) == 18 and int(game.campaign.active_mission.attempt_id) == 18 and game.campaign.active_mission.id == State.MISSION_ID and int(game.campaign.materials) == 0 and int(game.campaign.main_core_id) == main_core and bool(game.campaign.completed.get(State.MISSION_ID, false)), "reload retains exact attempt identity, material count, main core and permanent reward flag"):
		return false
	active = game.campaign.duplicate(true)
	home = game.campaign.home_world.duplicate(true)
	_open_dev()
	for action in EDITS:
		if not _unchanged_rejection(action, "campaign_home_only"):
			return false
	if not _unchanged_rejection("campaign_start", "campaign_in_mission") or not _layout("mission"):
		return false
	# Exercise only a detached state-machine copy: never inject a live victory.
	var detached: Dictionary = game.campaign.duplicate(true)
	var settlement: Dictionary = State.settle(detached, "victory")
	game.pause_menu_open = false
	game.pause_menu_page = "main"
	game.campaign_ui.reset_panel()
	if not _check(bool(settlement.get("ok", false)) and int(settlement.reward.materials) == 0 and game.campaign == active and not game._campaign_mission_ready() and not game._campaign_return("victory"), "a downgraded completed ledger cannot grant a second first-win reward or permit live premature victory without a modal guard"):
		return false
	_open_dev()
	disk = _read(developer_path)
	if not _check(game.campaign_ui.developer_apply_action("campaign_return") and game.campaign_ui.open and game.campaign_ui.confirm_retreat and not game.pause_menu_open, "developer return opens the existing confirmation panel"):
		return false
	if not _check(game._campaign_active() and game.campaign == active and game.campaign.home_world == home and _read(developer_path) == disk, "opening return confirmation neither settles nor grants or saves a reward"):
		return false
	game.campaign_ui.activate(1)
	if not _check(game._campaign_active() and not game.campaign_ui.confirm_retreat and game.campaign == active and _read(developer_path) == disk, "cancel keeps the mission and its saved home untouched"):
		return false
	game.campaign_ui.reset_panel()
	_open_dev()
	if not _check(game.campaign_ui.developer_apply_action("campaign_return"), "return can be requested again after cancellation"):
		return false
	game.campaign_ui.activate(0)
	return _check(not game._campaign_active() and game._world_scene_id() == "home_nest" and game.campaign.last_result.outcome == "retreat" and int(game.campaign.last_result.reward.materials) == 0 and int(game.campaign.materials) == 0 and bool(game.campaign.completed.get(State.MISSION_ID, false)), "explicit confirmation uses ordinary no-reward retreat and preserves the reward ledger")

func _layout(context: String) -> bool:
	var old_locale: String = game.settings_locale
	var old_mouse: Vector2 = game.last_mouse
	var old_page: int = game.developer_page
	var old_notice: String = game.campaign_ui.notice
	for locale in Words.LOCALES:
		game.settings_locale = locale
		if context == "save_failure":
			game.campaign_ui.notice = game.campaign_ui.text("save_failed")
		for viewport in [Vector2(640, 360), Vector2(1280, 720)]:
			for page_index in range(Words.PAGE_IDS.size()):
				game.developer_page = page_index
				var page_id: String = Words.PAGE_IDS[page_index]
				var panel: Rect2 = game._developer_panel_rect(viewport)
				var rects: Array = game._developer_button_rects(viewport)
				var actions: Array[String] = Words.page_actions(page_id)
				if not _check(Rect2(Vector2.ZERO, viewport).encloses(panel) and rects.size() == actions.size(), context + ":" + locale + " complete page fits " + page_id):
					return false
				var all_rects: Array[Rect2] = []
				for index in range(rects.size()):
					var rect: Rect2 = rects[index]
					if not _check(panel.encloses(rect) and rect.size.y >= 22.0 and rect.position.y >= panel.position.y + (94.0 if page_id == "campaign" else 76.0), "usable action stays below page headers"):
						return false
					all_rects.append(rect)
					if not _fits(game._developer_action_label(actions[index]), rect.size.x - 12.0, 11, 7, "button " + locale + ":" + actions[index]):
						return false
					if page_id == "campaign":
						game.last_mouse = rect.get_center()
						var reason: String = game.campaign_ui.developer_action_reason(actions[index])
						var hint: String = game._developer_campaign_hint(viewport)
						var expected: String = game.campaign_ui.notice if not game.campaign_ui.notice.is_empty() else (game._dt(reason) if not reason.is_empty() else Words.page_description("campaign", locale))
						if not _check(hint == expected, "real hover hint explains disabled actions unless a save error takes priority"):
							return false
						if not _fits(hint, panel.size.x - 36.0, 10, 7, "actual hint " + locale):
							return false
				for index in range(3):
					var nav: Rect2 = game._developer_navigation_rect(viewport, index)
					if not _check(panel.encloses(nav), "navigation fits inside developer panel"):
						return false
					all_rects.append(nav)
				for index in range(all_rects.size()):
					for other in range(index):
						if not _check(not all_rects[index].intersects(all_rects[other]), "developer actions and navigation never overlap"):
							return false
				if page_id == "campaign":
					if not _fits(game.campaign_ui.developer_status_text(), panel.size.x - 36.0, 10, 7, "status " + locale):
						return false
					var page_label: String = game._dt("page_label_fmt") % [page_index + 1, Words.PAGE_IDS.size(), Words.page_title(page_id, locale)]
					if not _fits(page_label, panel.size.x - 36.0, 11, 8, "page label " + locale):
						return false
	game.settings_locale = old_locale
	game.campaign_ui.notice = old_notice
	game.last_mouse = old_mouse
	game.developer_page = old_page
	return true

func _fits(value: String, width: float, preferred: int, minimum: int, label: String) -> bool:
	var size: int = game._fit_font_size(value, width, preferred, minimum)
	var measured: Vector2 = game.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	return _check(not value.is_empty() and size >= minimum and size <= preferred and measured.x <= width + 0.01, label + " font stays within its actual draw width")

func _open_dev() -> void:
	game.campaign_ui.reset_panel()
	game._open_developer_tools()
	game.developer_page = Words.PAGE_IDS.find("campaign")
	game.last_mouse = Vector2(-100, -100)

func _unchanged_rejection(action: String, reason: String) -> bool:
	var before: Dictionary = game.campaign.duplicate(true)
	var disk := _read(developer_path)
	return _check(game.campaign_ui.developer_action_reason(action) == reason and not game.campaign_ui.developer_apply_action(action) and game.campaign == before and _read(developer_path) == disk, action + " rejects without changing campaign or disk: " + reason)

func _persisted(value: Dictionary) -> Dictionary:
	# Compare complete nested data at the same precision as real save serialization.
	return JSON.parse_string(JSON.stringify(value)) as Dictionary

func _signature(world: Dictionary) -> Dictionary:
	var result := world.duplicate(true)
	result.erase("saved_at")
	result.erase("campaign")
	return result

func _block() -> bool:
	var path := ProjectSettings.globalize_path(SaveStore.temp_path(developer_path))
	if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
		return false
	blocked = DirAccess.make_dir_absolute(path) == OK
	return blocked

func _unblock() -> void:
	if blocked:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.temp_path(developer_path)))
		blocked = false

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var content := file.get_as_text()
	file.close()
	return content

func _cleanup() -> void:
	_unblock()
	if owns_slots:
		for slot in [NORMAL, WRONG, developer_path]:
			SaveStore.remove_slot(slot)

func _check(condition: bool, message: String) -> bool:
	checks += 1
	if condition:
		return true
	push_error("DEVELOPER_CAMPAIGN_FAIL: " + message)
	_cleanup()
	quit(1)
	return false
