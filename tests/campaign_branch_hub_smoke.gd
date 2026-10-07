extends SceneTree

const State = preload("res://scripts/campaign_state.gd")
const Catalog = preload("res://scripts/campaign_mission_catalog.gd")
const Words = preload("res://scripts/campaign_branch_localization.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const SLOT := "user://campaign_branch_hub_smoke.json"
var checks := 0
var captures := 0


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
	game.main_menu_active = false
	game.game_started = true
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.settings_locale = "en"
	if not _localization_ok(game):
		return
	var ui = game.campaign_ui
	_fixture(game, "early")
	ui.show_panel()
	if not _check(ui.board_missions() == ["remote_pantry", "lost_network", "substrate_race"], "first opening a level-two nest displays all three independent routes together"):
		return
	for id in ui.board_missions():
		if not _check(Catalog.is_unlocked(game.campaign, id), "all early cards are independently open: " + id):
			return
	var original: Dictionary = game.campaign.duplicate(true)
	_key(ui, KEY_3)
	if not _check(ui.mission_id() == "substrate_race", "number keys choose a branch, not a different stage"):
		return
	ui.reset_panel()
	ui.show_panel()
	if not _check(ui.mission_id() == "substrate_race", "reopening keeps the player's branch selection"):
		return
	ui.selection_initialized = false
	_key(ui, KEY_2)
	ui.reset_panel()
	ui.show_panel()
	if not _check(ui.mission_id() == "lost_network", "a user choice on an automatically opened post-return board survives reopening"):
		return
	_key(ui, KEY_3)
	_key(ui, KEY_T)
	if not _check(ui.mission_id() == "first_contact" and not ui.action_enabled(0), "story challenge is a separate keyboard target and remains locked before two first wins"):
		return
	_key(ui, KEY_RIGHT)
	if not _check(ui.board_missions() == ["toxic_frontier", "boundary_counterattack"], "right key opens the two-route frontier board"):
		return
	var clicked: Vector2 = ui.selection_rect(game.get_viewport_rect().size, 1).get_center()
	_click(ui, clicked)
	if not _check(ui.mission_id() == "boundary_counterattack" and not ui.action_enabled(0), "locked routes are inspectable with mouse but cannot launch"):
		return
	if not _check(game.campaign == original, "navigation never changes progress, rewards or branch currency"):
		return
	_key(ui, KEY_ESCAPE)
	if not _check(not ui.open, "escape closes the board"):
		return
	_key(ui, KEY_J)
	if not _check(ui.open and ui.mission_id() == "boundary_counterattack", "J reopens the same choice"):
		return
	ui.reset_campaign_selection()
	ui.show_panel()
	if not _check(ui.board_missions().size() == 3, "explicit reload reset restores the appropriate stage"):
		return
	_fixture(game, "ready")
	ui.show_panel()
	if not _check(ui.board_missions().size() == 3 and ui.board_group()["story"] == "first_contact" and Catalog.is_unlocked(game.campaign, "first_contact"), "two first wins unlock the distinct story entry"):
		return
	if not _check(ui.mission_status_text("substrate_race") == ui.chapter_text("branch_optional") and ui.mission_status_text("remote_pantry") == ui.chapter_text("branch_replay"), "unpicked route and completed replay remain distinct"):
		return
	_click(ui, ui.story_rect(game.get_viewport_rect().size).get_center())
	if not _check(ui.mission_id() == "first_contact" and ui.action_enabled(0), "mouse selects the unlocked story entry"):
		return
	_fixture(game, "advanced")
	ui.show_panel()
	var common: int = game.campaign.materials
	if not _check(ui.purchase_branch("transport") and State.branch_level(game.campaign, "transport") == 1 and game.campaign.materials == common and State.tissue_balance(game.campaign, "transport") == 2, "real branch purchase uses a matching tissue, never nest building material"):
		return
	for fixture in ["early", "ready", "advanced", "upgraded"]:
		_fixture(game, fixture)
		ui.show_panel()
		var ledger: Dictionary = game.campaign.duplicate(true)
		for locale in Words.LOCALES:
			game.settings_locale = locale
			for viewport in [Vector2(640, 360), Vector2(1280, 720)]:
				root.size = Vector2i(viewport)
				game.layout_viewport_override = viewport
				if not _layout_ok(game, viewport):
					return
				if not _action_labels_ok(game, viewport):
					return
				game.queue_redraw()
				await process_frame
				if not OS.get_environment("FUNGI_BRANCH_CAPTURE_DIR").is_empty():
					if DisplayServer.get_name() == "headless":
						if not _check(false, "capture requires a real renderer"):
							return
					await RenderingServer.frame_post_draw
					var directory := OS.get_environment("FUNGI_BRANCH_CAPTURE_DIR")
					DirAccess.make_dir_recursive_absolute(directory)
					var path := directory.path_join("%s-%s-%dx%d.png" % [fixture, locale, int(viewport.x), int(viewport.y)])
					if not _check(root.get_texture().get_image().save_png(path) == OK, "renderer captures " + path):
						return
					captures += 1
		if not _check(game.campaign == ledger, "all localized layout/draw queries are read-only: " + fixture):
			return
	# The isolated review override must not expose any of the other eight maps.
	var ReviewUI = load("res://scripts/review_campaign_controller.gd")
	var review_game: Node = load("res://scenes/ReviewSlice.tscn").instantiate()
	for id in ["remote_pantry", "two_fronts", "stable_colony"]:
		review_game.review_mission_id = id
		var isolated = ReviewUI.new(review_game)
		isolated._sync_selection()
		if not _check(isolated._board_groups().size() == 1 and isolated.board_missions() == [id] and String(isolated.board_group()["story"]).is_empty(), "review override keeps exactly one mission: " + id):
			return
	review_game.free()
	for runner in [game]:
		for player in runner.pixel_audio.players:
			player.stop()
			player.stream = null
		runner.pixel_audio.ambient_player.stop()
		runner.pixel_audio.ambient_player.stream = null
		runner.queue_free()
	await process_frame
	SaveStore.remove_slot(SLOT)
	print("CAMPAIGN_BRANCH_HUB_OK checks=%d locales=7 layouts=56 captures=%d choices=3+2 story=separate mouse=pass keyboard=pass review-isolated=true" % [checks, captures])
	quit(0)


func _fixture(game: Node, name: String) -> void:
	game.campaign = State.fresh()
	game.campaign.nest_level = 2 if name in ["early", "ready"] else 3
	game.campaign.materials = 6
	game.campaign.completed = {"first_supply": true}
	game.campaign.tissues = {"transport": 3, "resilience": 3, "defense": 3}
	if name in ["ready", "advanced", "upgraded"]:
		game.campaign.completed.merge({"remote_pantry": true, "lost_network": true})
	if name in ["advanced", "upgraded"]:
		game.campaign.completed["first_contact"] = true
	if name == "upgraded":
		game.campaign.branches = {"transport": 2, "resilience": 1, "defense": 1}
	game.campaign_ui.reset_campaign_selection()
	game.pause_menu_open = false
	game.offline_settlement_active = false
	game.offline_report_open = false
	game.chapter_report_open = false
	game.main_menu_active = false
	game.game_over = false


func _key(ui, code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	ui.handle_input(event)


func _click(ui, position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = position
	ui.handle_input(event)


func _layout_ok(game: Node, viewport: Vector2) -> bool:
	var ui = game.campaign_ui
	var panel: Rect2 = ui.panel_rect(viewport)
	var rects: Array[Rect2] = []
	for index in ui._board_groups().size():
		rects.append(ui.stage_rect(viewport, index))
	for index in ui.board_missions().size():
		rects.append(ui.selection_rect(viewport, index))
	rects.append(ui.story_rect(viewport))
	for index in 3:
		rects.append(ui.branch_rect(viewport, index))
		rects.append(ui.button_rect(viewport, index))
	for i in rects.size():
		if not _check(panel.encloses(rects[i]), "control stays inside panel: " + str(rects[i])):
			return false
		for j in range(i + 1, rects.size()):
			if not _check(not rects[i].intersects(rects[j]), "click targets never overlap"):
				return false
	var body: Dictionary = ui.panel_body_layout(viewport)
	var body_bottom: float = float(body["first_baseline"]) + (int(body["visible"]) - 1) * int(body["line_height"]) + game.fallback_font.get_descent(int(body["font_size"]))
	if not _check(body_bottom < ui.button_rect(viewport, 0).position.y - panel.position.y, "scrollable detail text ends before action buttons"):
		return false
	for index in ui.board_missions().size():
		var id: String = ui.board_missions()[index]
		var rect: Rect2 = ui.selection_rect(viewport, index)
		for label in [ui._title_for(id), ui.chapter_text(id + "_role"), ui.card_reward_text(id), ui.mission_status_text(id)]:
			if not _fits(game, label, rect.size.x - 16):
				return false
	for index in 3:
		for label in ui.branch_button_lines(State.BRANCH_IDS[index]):
			if not _fits(game, label, ui.branch_rect(viewport, index).size.x - 16):
				return false
	for index in 3:
		if not _fits(game, ui.action_labels()[index], ui.button_rect(viewport, index).size.x - 16):
			return false
	return _fits(game, ui.board_rule_text(), panel.size.x - 40)


func _fits(game: Node, label: String, width: float) -> bool:
	var size: int = game._fit_font_size(label, width, 14, 7)
	return _check(game.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width + 0.01, "pixel text fits without clipping: " + game.settings_locale + " / " + label)


func _action_labels_ok(game: Node, viewport: Vector2) -> bool:
	var ui = game.campaign_ui
	var active: Dictionary = game.campaign.active_mission
	var selected: String = ui.selected_mission_id
	var confirmation: bool = ui.confirm_retreat
	var dead: bool = game.game_over
	ui.selected_mission_id = "first_supply"
	for mode in ["replay", "victory", "failure", "confirmation"]:
		game.campaign.active_mission = {} if mode == "replay" else {"id": "first_contact"}
		game.game_over = mode == "failure"
		ui.confirm_retreat = mode == "confirmation"
		for index in 3:
			if not _fits(game, ui.action_labels()[index], ui.button_rect(viewport, index).size.x - 16):
				return false
	game.campaign.active_mission = active
	ui.selected_mission_id = selected
	ui.confirm_retreat = confirmation
	game.game_over = dead
	return true


func _localization_ok(game: Node) -> bool:
	var values := {"done": 2, "need": 2, "total": 3, "mission": "Test", "amount": 1, "level": 2, "balance": 1, "branch": "Test", "reward": "3 + 1", "cost": 1}
	var expression := RegEx.new()
	expression.compile("\\{[a-z_]+\\}")
	for locale in Words.LOCALES:
		if not _check(Words.TEXTS[locale].size() == Words.KEYS.size(), locale + " explicitly translates every key"):
			return false
		for key in Words.KEYS:
			var value: String = Words.text(locale, key, values)
			if not _check(not value.is_empty() and not value.contains("{") and Words.TEXTS[locale].has(key), locale + "/" + key + " formats without fallback or missing placeholders"):
				return false
			var expected: Array[String] = []
			var actual: Array[String] = []
			for item in expression.search_all(Words.TEXTS["en"][key]):
				expected.append(item.get_string())
			for item in expression.search_all(Words.TEXTS[locale][key]):
				actual.append(item.get_string())
			expected.sort()
			actual.sort()
			if not _check(actual == expected, locale + "/" + key + " preserves English placeholder set"):
				return false
			for index in value.length():
				if not _check(game.fallback_font.has_char(value.unicode_at(index)), locale + "/" + key + " has a bundled pixel-font glyph"):
					return false
	return true


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if condition:
		return true
	push_error("CAMPAIGN_BRANCH_HUB_FAIL: " + message)
	quit(1)
	return false
