extends RefCounted

const State = preload("res://scripts/campaign_state.gd")
const Words = preload("res://scripts/campaign_localization.gd")
const ChapterWords = preload("res://scripts/campaign_chapter_localization.gd")
const StoryWords = preload("res://scripts/campaign_story_localization.gd")
const BranchWords = preload("res://scripts/campaign_branch_localization.gd")
const Catalog = preload("res://scripts/campaign_mission_catalog.gd")
const DEVELOPER_ACTIONS := [
	"campaign_nest_down", "campaign_nest_up", "campaign_material_down",
	"campaign_material_up", "campaign_start", "campaign_return"
]

var g
var open := false
var confirm_retreat := false
var scroll := 0
var busy := false
var notice := ""
var failure_presented := false
var selected_mission_id := State.MISSION_ID
var selection_start := 0
var selection_initialized := false


func _init(game) -> void:
	g = game


func text(key: String, values: Dictionary = {}) -> String:
	return Words.text(g.settings_locale, key, values)


func chapter_text(key: String, values: Dictionary = {}) -> String:
	if BranchWords.KEYS.has(key):
		return BranchWords.text(g.settings_locale, key, values)
	return ChapterWords.text(g.settings_locale, key, values) if ChapterWords.KEYS.has(key) else StoryWords.text(g.settings_locale, key, values)


func mission_id() -> String:
	if g._campaign_active():
		return String(g.campaign["active_mission"]["id"])
	return selected_mission_id if Catalog.is_implemented(selected_mission_id) else State.MISSION_ID


func mission_title() -> String:
	return text("mission_title") if mission_id() == State.MISSION_ID else chapter_text(mission_id() + "_title")


func mission_description() -> String:
	return text("mission_desc", mission_values()) if mission_id() == State.MISSION_ID else chapter_text(mission_id() + "_desc", mission_values())


func _board_groups() -> Array[Dictionary]:
	var choices := _mission_choices()
	if choices.size() == 1:
		return [{"stage": 0, "missions": choices.duplicate(), "story": ""}]
	var groups: Array[Dictionary] = []
	var authored := [
		{"stage": 0, "missions": ["first_supply"], "story": ""},
		{"stage": 1, "missions": ["remote_pantry", "lost_network", "substrate_race"], "story": "first_contact"},
		{"stage": 2, "missions": ["toxic_frontier", "boundary_counterattack"], "story": "two_fronts"},
		{"stage": 3, "missions": ["stable_colony"], "story": ""}
	]
	for source in authored:
		var cards: Array[String] = []
		for id in source["missions"]:
			if choices.has(id):
				cards.append(id)
		var story := String(source["story"]) if choices.has(source["story"]) else ""
		if not cards.is_empty() or not story.is_empty():
			groups.append({"stage": source["stage"], "missions": cards, "story": story})
	return groups


func board_group() -> Dictionary:
	var groups := _board_groups()
	if groups.is_empty():
		return {"stage": 0, "missions": [], "story": ""}
	return groups[clampi(selection_start, 0, groups.size() - 1)]


func board_missions() -> Array[String]:
	var result: Array[String] = []
	result.assign(board_group()["missions"])
	return result


func board_layout(viewport: Vector2) -> Dictionary:
	var compact := panel_rect(viewport).size.y < 500.0
	return {"compact": compact, "tabs_y": 50.0 if compact else 62.0,
		"tabs_h": 22.0 if compact else 28.0, "rule_y": 86.0 if compact else 108.0,
		"cards_y": 92.0 if compact else 116.0, "cards_h": 62.0 if compact else 96.0,
		"story_y": 160.0 if compact else 220.0, "story_h": 30.0 if compact else 40.0,
		"branches_y": 196.0 if compact else 270.0, "branches_h": 36.0 if compact else 44.0,
		"detail_y": 249.0 if compact else 336.0}


func stage_rect(viewport: Vector2, index: int) -> Rect2:
	var panel := panel_rect(viewport)
	var layout := board_layout(viewport)
	var count := maxi(1, _board_groups().size())
	var width := (panel.size.x - 40.0 - (count - 1) * 6.0) / count
	return Rect2(panel.position + Vector2(20 + index * (width + 6), layout["tabs_y"]), Vector2(width, layout["tabs_h"]))


func selection_rect(viewport: Vector2, index: int) -> Rect2:
	var panel := panel_rect(viewport)
	var layout := board_layout(viewport)
	var count := maxi(1, board_missions().size())
	var width := (panel.size.x - 40.0 - (count - 1) * 8.0) / count
	return Rect2(panel.position + Vector2(20 + index * (width + 8), layout["cards_y"]), Vector2(width, layout["cards_h"]))


func story_rect(viewport: Vector2) -> Rect2:
	var panel := panel_rect(viewport)
	var layout := board_layout(viewport)
	return Rect2(panel.position + Vector2(20, layout["story_y"]), Vector2(panel.size.x - 40, layout["story_h"]))


func branch_rect(viewport: Vector2, index: int) -> Rect2:
	var panel := panel_rect(viewport)
	var layout := board_layout(viewport)
	var width := (panel.size.x - 56.0) / 3.0
	return Rect2(panel.position + Vector2(20 + index * (width + 8), layout["branches_y"]), Vector2(width, layout["branches_h"]))


func phase_action_rect(viewport: Vector2) -> Rect2:
	var panel := panel_rect(viewport)
	return Rect2(panel.position + Vector2(20, 82), Vector2(panel.size.x - 40, 30))


func _sync_selection() -> void:
	var groups := _board_groups()
	for index in groups.size():
		if groups[index]["missions"].has(selected_mission_id) or groups[index]["story"] == selected_mission_id:
			selection_start = index
			return
	selection_start = 0


func _select_mission(id: String) -> void:
	if not _mission_choices().has(id):
		return
	selection_initialized = true
	selected_mission_id = id
	scroll = 0
	g._play_sound("ui_confirm")
	g.queue_redraw()


func _select_stage(index: int) -> void:
	var groups := _board_groups()
	if index < 0 or index >= groups.size():
		return
	selection_initialized = true
	selection_start = index
	var group: Dictionary = groups[index]
	if not group["missions"].has(selected_mission_id) and group["story"] != selected_mission_id:
		var ids: Array = group["missions"].duplicate()
		if not String(group["story"]).is_empty():
			ids.append(group["story"])
		var chosen := String(ids[0])
		for id in ids:
			if Catalog.is_unlocked(g.campaign, id) and not bool(g.campaign.get("completed", {}).get(id, false)):
				chosen = id
				break
		_select_mission(chosen)
	else:
		scroll = 0
		g.queue_redraw()


func _page_selection(direction: int) -> void:
	_select_stage(clampi(selection_start + direction, 0, maxi(0, _board_groups().size() - 1)))


func _mission_choices() -> Array[String]:
	var choices: Array[String] = []
	for entry in Catalog.entries():
		if bool(entry["implemented"]):
			choices.append(String(entry["id"]))
	return choices

func reset_campaign_selection() -> void:
	selection_initialized = false
	selected_mission_id = State.MISSION_ID
	selection_start = 0


func reset_panel() -> void:
	open = false
	confirm_retreat = false
	scroll = 0
	notice = ""


func show_panel() -> void:
	if busy or g.offline_settlement_active:
		return
	g._ensure_campaign_main_core()
	g.upgrade_open = false
	g.goals_open = false
	g.show_status = false
	g._close_barracks_production_menu()
	g.mode = "normal"
	g.dragging = false
	g.left_selecting = false
	g.defense_zone_drawing = false
	g.developer_placement_action = ""
	if not g._campaign_active():
		if not selection_initialized or not _mission_choices().has(selected_mission_id):
			selected_mission_id = State.recommended_mission_id(g.campaign)
			selection_initialized = true
		_sync_selection()
	open = true
	confirm_retreat = false
	scroll = 0
	g._play_sound("panel_open")
	g.queue_redraw()


func hud_rect() -> Rect2:
	return Rect2(18, 156, 180, 32)


func panel_rect(viewport: Vector2) -> Rect2:
	var size := Vector2(minf(1000.0, viewport.x - 32.0), minf(740.0, viewport.y - 32.0))
	return Rect2((viewport - size) * 0.5, size)


func button_rect(viewport: Vector2, index: int) -> Rect2:
	var panel := panel_rect(viewport)
	if panel.size.y < 500.0:
		var width := (panel.size.x - 56.0) / 3.0
		return Rect2(panel.position + Vector2(20 + index * (width + 8), panel.size.y - 46), Vector2(width, 30))
	return Rect2(panel.position + Vector2(20, panel.size.y - 126.0 + index * 36.0), Vector2(panel.size.x - 40.0, 30))


func handle_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_J:
		if open:
			reset_panel()
			g._play_sound("panel_close")
		else:
			show_panel()
		return true
	if not open:
		return false
	if event is InputEventMouseMotion:
		g.last_mouse = event.position
		var hovered := ""
		var viewport: Vector2 = g.get_viewport_rect().size
		for index in range(3):
			if button_rect(viewport, index).has_point(event.position):
				hovered = "campaign_%d" % index
		if not g._campaign_active():
			for index in range(3):
				if branch_rect(viewport, index).has_point(event.position):
					hovered = "campaign_branch_%d" % index
			for index in _board_groups().size():
				if stage_rect(viewport, index).has_point(event.position):
					hovered = "campaign_stage_%d" % index
			for index in board_missions().size():
				if selection_rect(viewport, index).has_point(event.position):
					hovered = "campaign_choice_" + board_missions()[index]
			if not String(board_group()["story"]).is_empty() and story_rect(viewport).has_point(event.position):
				hovered = "campaign_story"
		elif not confirm_retreat and not _phase_action_key().is_empty() and phase_action_rect(viewport).has_point(event.position):
			hovered = "campaign_phase"
		if g.audio_hover_target != hovered:
			g.audio_hover_target = hovered
			if not hovered.is_empty():
				g._play_sound("ui_hover", 0.65)
	elif event is InputEventMouseButton:
		g.last_mouse = event.position
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
			scroll = maxi(0, scroll + (2 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -2))
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var viewport: Vector2 = g.get_viewport_rect().size
			if not g._campaign_active():
				for index in _board_groups().size():
					if stage_rect(viewport, index).has_point(event.position):
						_select_stage(index)
						return true
				var choices := board_missions()
				for index in choices.size():
					if selection_rect(viewport, index).has_point(event.position):
						_select_mission(choices[index])
						return true
				if not String(board_group()["story"]).is_empty() and story_rect(viewport).has_point(event.position):
					_select_mission(board_group()["story"])
					return true
				for index in range(3):
					if branch_rect(viewport, index).has_point(event.position):
						purchase_branch(State.BRANCH_IDS[index])
						return true
			elif not confirm_retreat and not _phase_action_key().is_empty() and phase_action_rect(viewport).has_point(event.position):
				advance_mission()
				return true
			for index in range(3):
				if button_rect(viewport, index).has_point(event.position):
					activate(index)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if confirm_retreat:
				confirm_retreat = false
			else:
				reset_panel()
			g._play_sound("ui_cancel")
		elif event.keycode in [KEY_LEFT, KEY_RIGHT] and not g._campaign_active():
			_page_selection(-1 if event.keycode == KEY_LEFT else 1)
		elif event.keycode in [KEY_1, KEY_2, KEY_3] and not g._campaign_active():
			var index: int = event.keycode - KEY_1
			if index < board_missions().size():
				_select_mission(board_missions()[index])
		elif event.keycode == KEY_T and not g._campaign_active() and not String(board_group()["story"]).is_empty():
			_select_mission(board_group()["story"])
		elif event.keycode in [KEY_DOWN, KEY_PAGEDOWN]:
			scroll += 2
		elif event.keycode in [KEY_UP, KEY_PAGEUP]:
			scroll = maxi(0, scroll - 2)
		elif event.keycode == KEY_F5:
			if not g._save_game():
				notice = text("save_failed")
			elif notice == text("save_failed"):
				notice = ""
	g.queue_redraw()
	return true


func other_modal_active() -> bool:
	return g.main_menu_active or g.pause_menu_open or g.offline_settlement_active or g.offline_report_open or g.chapter_report_open or g.upgrade_open or g.goals_open or g.barracks_production_open


func start_mission(requested_id: String = State.MISSION_ID) -> bool:
	if busy or other_modal_active() or g._campaign_active() or g.game_over or g._founder_spore_active() or g._living_core_count() <= 0:
		return false
	if not State.can_begin(g.campaign, requested_id):
		return false
	busy = true
	var incoming_world: Node2D = g._prepare_world_scene(requested_id)
	if incoming_world == null:
		busy = false
		notice = text("save_failed")
		return false
	var previous_world: Node2D = g.active_world
	g._ensure_campaign_main_core()
	var home: Dictionary = g._capture_world_state()
	var previous: Dictionary = g.campaign.duplicate(true)
	var next: Dictionary = previous.duplicate(true)
	if not State.begin(next, home, Time.get_unix_time_from_system(), {}, requested_id):
		incoming_world.free()
		busy = false
		return false
	# Never call _begin_new_culture: it writes a new save before the envelope exists.
	if not g._start_new_culture(requested_id, true, incoming_world):
		busy = false
		return false
	g.campaign = next
	if _is_trial(requested_id):
		var trial_snapshot := home.duplicate(true)
		trial_snapshot["world_scene_id"] = requested_id
		trial_snapshot["mission_state"] = {}
		if not g._restore_world_state(trial_snapshot, incoming_world):
			g.campaign = previous
			g._activate_world_scene(previous_world)
			busy = false
			notice = text("save_failed")
			return false
		g.active_world.initialize_trial(g)
	else:
		_inherit_unit_licenses(home)
	g.game_started = true
	g.main_menu_active = false
	if not g._save_game():
		g.campaign = previous
		g._activate_world_scene(previous_world)
		notice = text("save_failed")
		open = true
		busy = false
		return false
	if is_instance_valid(previous_world):
		previous_world.free()
	busy = false
	open = false
	g._play_sound("core_build")
	g.toast(mission_title(), 5.0, "info")
	g.queue_redraw()
	return true


func _inherit_unit_licenses(home: Dictionary) -> void:
	# Only boolean production licenses cross the boundary, never upgrade levels.
	# Diet-specific units remain unusable until that diet is researched locally.
	var basic: Variant = home.get("barracks_unit_unlocks", {})
	if basic is Dictionary:
		for unit_id in g.BARRACK_UNIT_IDS:
			if typeof(basic.get(unit_id, null)) == TYPE_BOOL and basic[unit_id]:
				g.barracks_unit_unlocks[unit_id] = true
	var special: Variant = home.get("diet_unit_unlocks", {})
	if special is Dictionary:
		for unit_id in g.diet_unit_unlocks:
			if typeof(special.get(unit_id, null)) == TYPE_BOOL and special[unit_id]:
				g.diet_unit_unlocks[unit_id] = true
	# All currently available evolution options remain in the mission shop.
	# Their levels and diet activation are paid again with mission-local DNA.


func return_home(outcome: String) -> bool:
	if busy or other_modal_active() or not g._campaign_active():
		return false
	if outcome == "victory" and not g._campaign_mission_ready():
		return false
	if outcome == "failure" and not g.game_over:
		return false
	if outcome not in ["victory", "failure", "retreat"]:
		return false
	var incoming_home: Node2D = g._prepare_world_scene("home_nest")
	if incoming_home == null:
		notice = text("save_failed")
		return false
	busy = true
	var previous: Dictionary = g.campaign.duplicate(true)
	var result: Dictionary = State.settle(g.campaign, outcome)
	if not bool(result.get("ok", false)):
		incoming_home.free()
		g.campaign = previous
		busy = false
		return false
	var home: Dictionary = result["home_world"]
	if _is_trial(String(result["mission_id"])):
		# A home-clone challenge must not also generate a second offline economy.
		home["saved_at"] = Time.get_unix_time_from_system()
	# Commit reward and restored home atomically, retaining the departure timestamp.
	# A crash now reloads this one envelope and settles the unprocessed home interval.
	if not g._commit_world_and_campaign(home):
		incoming_home.free()
		g.campaign = previous
		notice = text("save_failed")
		busy = false
		return false
	g._restore_world_state(home, incoming_home)
	g.sim_speed = 0.0 if g.game_over else 1.0
	g._ensure_campaign_main_core()
	g._settle_home_elapsed(home, true)
	if not g.offline_settlement_active:
		g._save_game()
	busy = false
	selected_mission_id = State.recommended_mission_id(g.campaign)
	selection_initialized = true
	_sync_selection()
	open = true
	confirm_retreat = false
	g._play_sound("goal" if outcome == "victory" else "ui_cancel")
	g.queue_redraw()
	return true


func upgrade_nest() -> bool:
	if busy or other_modal_active() or g._campaign_active() or g.game_over or g._living_core_count() <= 0:
		return false
	var previous: Dictionary = g.campaign.duplicate(true)
	if not State.upgrade(g.campaign):
		return false
	if not g._save_game():
		g.campaign = previous
		notice = text("save_failed")
		return false
	if notice == text("save_failed"):
		notice = ""
	scroll = 0
	selected_mission_id = State.recommended_mission_id(g.campaign)
	selection_initialized = true
	_sync_selection()
	g._play_sound("upgrade")
	g.queue_redraw()
	return true


func _is_trial(id: String) -> bool:
	return Catalog.mission(id).get("kind", "") == "nest_challenge"


func _phase_action_key() -> String:
	return g.active_world.manual_action_key(g) if g._campaign_active() else ""


func purchase_branch(branch_id: String) -> bool:
	if busy or other_modal_active() or g._campaign_active() or g.game_over:
		return false
	var previous: Dictionary = g.campaign.duplicate(true)
	if not State.purchase_branch(g.campaign, branch_id):
		g._play_sound("ui_error")
		return false
	if not g._save_game():
		g.campaign = previous
		notice = text("save_failed")
		return false
	notice = ""
	g._play_sound("upgrade")
	g.queue_redraw()
	return true


func advance_mission() -> bool:
	if busy or other_modal_active() or not g._campaign_active() or g.game_over:
		return false
	var before: Dictionary = g._capture_world_state()
	if not g.active_world.mission_action(g):
		return false
	if not g._save_game():
		g._restore_world_state(before)
		notice = text("save_failed")
		open = true
		return false
	open = false
	g._play_sound("warning")
	g.queue_redraw()
	return true


func developer_action_reason(action_id: String) -> String:
	# A mode flag alone is insufficient: never write these edits to a normal slot.
	if not g.developer_mode_enabled or g.save_path != g.DEVELOPER_SAVE_PATH:
		return "campaign_dev_only"
	if not DEVELOPER_ACTIONS.has(action_id):
		return "campaign_busy"
	if busy or open or not g.game_started or g.splash_active or g.main_menu_active or g.offline_settlement_active or g.offline_report_open or g.chapter_report_open or g.upgrade_open or g.goals_open or g.barracks_production_open:
		return "campaign_busy"
	if g.pause_menu_open and g.pause_menu_page != "developer":
		return "campaign_busy"
	var active: bool = g._campaign_active()
	if action_id == "campaign_return":
		return "" if active else "campaign_not_in_mission"
	if active:
		return "campaign_in_mission" if action_id == "campaign_start" else "campaign_home_only"
	if g.game_over or g._founder_spore_active() or g._living_core_count() <= 0:
		return "campaign_settle_first"
	match action_id:
		"campaign_nest_down":
			return "campaign_limit" if int(g.campaign.nest_level) <= 1 else ""
		"campaign_nest_up":
			return "campaign_limit" if int(g.campaign.nest_level) >= State.MAX_NEST_LEVEL else ""
		"campaign_material_down":
			return "campaign_limit" if int(g.campaign.materials) <= 0 else ""
		"campaign_material_up":
			return "campaign_limit" if int(g.campaign.materials) >= State.MAX_MATERIALS else ""
		"campaign_start":
			return "" if State.can_begin(g.campaign) else "campaign_limit"
	return "campaign_busy"


func developer_status_text() -> String:
	var world_label: String = g._dt("campaign_mission" if g._campaign_active() else "campaign_home")
	return (g._dt("campaign_status_fmt") % [world_label, int(g.campaign.nest_level), int(g.campaign.materials)]).format({"nest_cap": State.MAX_NEST_LEVEL, "material_cap": State.MAX_MATERIALS})


func developer_apply_action(action_id: String) -> bool:
	if not developer_action_reason(action_id).is_empty():
		return false
	if action_id in ["campaign_start", "campaign_return"]:
		# Only release this developer pause page. All unrelated modal guards remain.
		var was_paused: bool = g.pause_menu_open
		var previous_page: String = g.pause_menu_page
		var previous_developer_page: int = g.developer_page
		g.pause_menu_open = false
		g.pause_menu_page = "main"
		if action_id == "campaign_return":
			show_panel()
			confirm_retreat = true
			scroll = 0
			return true
		if start_mission():
			g.developer_page = previous_developer_page
			return true
		# Scene initialization can reset the page index even when the save rolls back.
		g.pause_menu_open = was_paused
		g.pause_menu_page = previous_page
		g.developer_page = previous_developer_page
		open = false
		g.queue_redraw()
		return false
	var previous: Dictionary = g.campaign.duplicate(true)
	var next: Dictionary = previous.duplicate(true)
	match action_id:
		"campaign_nest_down": next.nest_level = int(next.nest_level) - 1
		"campaign_nest_up": next.nest_level = int(next.nest_level) + 1
		"campaign_material_down": next.materials = int(next.materials) - 1
		"campaign_material_up": next.materials = int(next.materials) + 1
	# Level two implies the first-win flag. Lowering the level cannot restore it.
	g.campaign = State.sanitize(next)
	if not g._save_game():
		g.campaign = previous
		notice = text("save_failed")
		g.queue_redraw()
		return false
	if notice == text("save_failed"):
		notice = ""
	g._play_sound("upgrade")
	g.queue_redraw()
	return true


func action_labels() -> Array[String]:
	if confirm_retreat:
		return [text("confirm"), text("cancel"), text("close")]
	if g._campaign_active():
		return [text("return_fail") if g.game_over else text("return_win"), text("retreat"), text("close")]
	var upgrade_label := chapter_text("upgrade_cost", {"level": int(g.campaign.nest_level) + 1, "cost": State.upgrade_cost(g.campaign)}) if int(g.campaign.nest_level) < State.MAX_NEST_LEVEL else chapter_text("nest_max")
	return [text("retry") if g.campaign.get("completed", {}).get(mission_id(), false) else text("start"), upgrade_label, text("close")]


func action_enabled(index: int) -> bool:
	if index == 2 or confirm_retreat:
		return true
	if g._campaign_active():
		return index == 1 or g.game_over or g._campaign_mission_ready()
	if index == 0:
		return State.can_begin(g.campaign, mission_id()) and not g._founder_spore_active() and not g.game_over and g._living_core_count() > 0
	return State.can_upgrade(g.campaign) and not g.game_over


func activate(index: int) -> void:
	if not action_enabled(index):
		g._play_sound("ui_error")
		return
	g._play_sound("ui_confirm")
	if index == 2:
		reset_panel()
	elif confirm_retreat:
		if index == 0:
			return_home("retreat")
		else:
			confirm_retreat = false
	elif g._campaign_active():
		if index == 0:
			return_home("failure" if g.game_over else "victory")
		else:
			confirm_retreat = true
			scroll = 0
	elif index == 0:
		start_mission(mission_id())
	else:
		upgrade_nest()


func draw_hud() -> void:
	var rect := hud_rect()
	g.draw_style_box(g._rounded_style(Color("0e2630"), Color("c7ad6d"), 7, 2), rect)
	var label := text("hud")
	g.draw_string(g.fallback_font, rect.position + Vector2(10, 21), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, g._fit_font_size(label, rect.size.x - 20, 12, 8), Color("f2d797"))
	if g._campaign_active():
		return
	var core_id: int = int(g.campaign.get("main_core_id", -1))
	if g._is_core_alive(core_id):
		var pos: Vector2 = g.world_to_screen(g.cores[core_id]["pos"])
		var radius: float = maxf(8.0, g._core_visual_size() * 0.65)
		for x in [-1, 1]:
			for y in [-1, 1]:
				var mark := pos + Vector2(x, y) * radius
				g.draw_rect(Rect2(g._pixel_snap(mark), Vector2.ONE * (4 if int(g.campaign.nest_level) > 1 else 2)), Color("e6c67c"))


func progress_text(compact: bool = false) -> String:
	if mission_id() not in [State.MISSION_ID, "remote_pantry"] and g._campaign_active():
		var rows: Array[Dictionary] = g.active_world.mission_status(g)
		var lines: Array[String] = []
		for row in rows:
			var current := float(row.get("current", 0.0))
			var target := float(row.get("target", 0.0))
			var label := chapter_text("mission_goal_row", {
				"name": chapter_text(String(row["key"])),
				"current": _progress_number(minf(current, target), target, compact),
				"target": _goal_number(target)
			})
			lines.append(label)
			if compact and current < target - 0.0005:
				return label
		return (" · ".join(lines) if not compact else (lines[-1] if not lines.is_empty() else ""))
	var targets: Dictionary = g._campaign_goal_targets()
	var organic_goal := float(targets.get("organic", 0.0))
	var mineral_goal := float(targets.get("mineral", 0.0))
	var length_goal := float(targets.get("length_world", 0.0))
	if mission_id() == "remote_pantry":
		var delivered_organic: float = g._chapter_bounded_progress(g.lifetime_expedition_organic_returned, organic_goal)
		var delivered_mineral: float = g._chapter_bounded_progress(g.lifetime_expedition_mineral_returned, mineral_goal)
		return chapter_text("transport_progress_compact" if compact else "transport_progress", {
			"organic": _progress_number(delivered_organic, organic_goal, compact), "organic_goal": _goal_number(organic_goal),
			"mineral": _progress_number(delivered_mineral, mineral_goal, compact), "mineral_goal": _goal_number(mineral_goal)
		})
	# Normalize in world units with the authoritative predicate's exact epsilon.
	var organic: float = g._chapter_bounded_progress(g.lifetime_organic_absorbed, organic_goal)
	var mineral: float = g._chapter_bounded_progress(g.lifetime_mineral_absorbed, mineral_goal)
	var length: float = g._chapter_bounded_progress(g._chapter_living_hypha_length(), length_goal)
	return text("progress_compact" if compact else "progress", {
		"organic": _progress_number(organic, organic_goal, compact), "organic_goal": _goal_number(organic_goal),
		"mineral": _progress_number(mineral, mineral_goal, compact), "mineral_goal": _goal_number(mineral_goal),
		"length": _progress_number(length / 2.0, length_goal / 2.0, true), "length_goal": _goal_number(length_goal / 2.0)
	})


func _progress_number(value: float, goal: float, whole: bool) -> String:
	if value >= goal:
		return _goal_number(goal) if whole else "%.3f" % goal
	# Never round an incomplete value up into a visually completed objective.
	return "%.0f" % floorf(value) if whole else "%.3f" % (floorf(value * 1000.0) / 1000.0)


func progress_hint_key() -> String:
	if g.game_over or g._living_core_count() <= 0:
		return "hint_dead" if mission_id() in [State.MISSION_ID, "remote_pantry"] else "mission_failed_hint"
	if g._campaign_mission_ready():
		return "hint_ready"
	if mission_id() not in [State.MISSION_ID, "remote_pantry"]:
		return "mission_hint"
	if mission_id() == "remote_pantry":
		var has_barracks := false
		for core_id in range(g.cores.size()):
			if g._is_core_alive(core_id) and g.cores[core_id].get("kind", "normal") == "barracks":
				has_barracks = true
		if not has_barracks:
			return "hint_barracks"
		if not bool(g.barracks_unit_unlocks.get("chelator", false)):
			return "hint_chelator"
		var transport_targets: Dictionary = g._campaign_goal_targets()
		if g._chapter_bounded_progress(g.lifetime_expedition_organic_returned, float(transport_targets.get("organic", 0.0))) < float(transport_targets.get("organic", 0.0)):
			return "hint_transport_organic"
		return "hint_transport_mineral"
	var has_live_extension := false
	for segment in g.segments:
		if g._is_core_alive(int(segment.get("core_id", -1))) and not bool(segment.get("orphaned", false)) and float(segment.get("viability", 1.0)) > 0.0:
			has_live_extension = true
			break
	if not has_live_extension:
		return "hint_extend"
	var targets: Dictionary = g._campaign_goal_targets()
	var organic_goal := float(targets.get("organic", 0.0))
	var mineral_goal := float(targets.get("mineral", 0.0))
	if g._chapter_bounded_progress(g.lifetime_organic_absorbed, organic_goal) < organic_goal:
		return "hint_organic"
	if g._chapter_bounded_progress(g.lifetime_mineral_absorbed, mineral_goal) < mineral_goal:
		return "hint_mineral"
	return "hint_grow"


func _goal_number(value: float) -> String:
	return str(int(value)) if value == floorf(value) else "%.3f" % value


func mission_values() -> Dictionary:
	var targets: Dictionary = g._campaign_goal_targets()
	return {"organic": _goal_number(float(targets.get("organic", 0.0))), "mineral": _goal_number(float(targets.get("mineral", 0.0))), "length": _goal_number(float(targets.get("length_world", 0.0)) / 2.0)}


func progress_hud_lines(rect: Rect2) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var width := rect.size.x - 20.0
	var hint := text(progress_hint_key())
	if progress_hint_key() in ["mission_hint", "mission_failed_hint"] or (mission_id() == "remote_pantry" and progress_hint_key() not in ["hint_ready", "hint_dead"]):
		hint = chapter_text(progress_hint_key())
	if rect.size.y <= 60:
		lines.append(_progress_line(hint, "hint", 13, width, 10))
		lines.append(_progress_line(progress_text(true), "progress", 28, width, 9))
		return lines
	lines.append(_progress_line(mission_title(), "title", 22, width, 12))
	if rect.size.y < 100 or mission_id() not in [State.MISSION_ID, "remote_pantry"]:
		lines.append(_progress_line(progress_text(true), "progress", 41, width, 11))
	else:
		var progress_lines: Array[String] = g._wrap_guide_text(progress_text(), width, 11)
		for index in range(progress_lines.size()):
			lines.append(_progress_line(progress_lines[index], "progress", 43 + index * 17, width, 11))
	lines.append(_progress_line(hint, "hint", rect.size.y - 10, width, 11))
	return lines


func _progress_line(value: String, role: String, baseline: float, width: float, preferred: int) -> Dictionary:
	return {"text": value, "role": role, "position": Vector2(10, baseline), "size": g._fit_font_size(value, width, preferred, 7)}


func draw_progress(rect: Rect2) -> void:
	g.draw_style_box(g._rounded_style(Color("091d29"), Color("c7ad6d"), 8, 2), rect)
	for line in progress_hud_lines(rect):
		var color := Color("cbe5db") if line["role"] == "progress" else Color("f2d797")
		g.draw_string(g.fallback_font, rect.position + line["position"], line["text"], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, line["size"], color)


func _title_for(id: String) -> String:
	return text("mission_title") if id == State.MISSION_ID else chapter_text(id + "_title")


func reward_text(id: String, actual: Dictionary = {}) -> String:
	var reward := actual if not actual.is_empty() else {"materials": Catalog.first_victory_materials(id), "tissues": Catalog.first_victory_tissues(id)}
	var parts: Array[String] = [chapter_text("common_reward", {"amount": int(reward.get("materials", 0))})]
	var tissues: Dictionary = reward.get("tissues", {})
	for branch_id in State.BRANCH_IDS:
		if int(tissues.get(branch_id, 0)) > 0:
			parts.append(chapter_text("tissue_" + branch_id) + " " + str(int(tissues[branch_id])))
	return " · ".join(parts)


func card_reward_text(id: String) -> String:
	if bool(g.campaign.get("completed", {}).get(id, false)):
		return chapter_text("reward_claimed")
	return chapter_text("first_win_reward", {"reward": reward_text(id)})


func mission_status_text(id: String) -> String:
	if bool(g.campaign.get("completed", {}).get(id, false)):
		return chapter_text("branch_replay")
	if not Catalog.is_unlocked(g.campaign, id):
		return chapter_text("locked")
	var story := "first_contact" if id in ["remote_pantry", "lost_network", "substrate_race"] else ("two_fronts" if id in ["toxic_frontier", "boundary_counterattack"] else "")
	if not story.is_empty() and Catalog.is_unlocked(g.campaign, story):
		return chapter_text("branch_optional")
	return chapter_text("mission_ready")


func mission_requirement_text(id: String) -> String:
	var progress := Catalog.unlock_progress(g.campaign, id)
	if bool(progress.get("unlocked", false)):
		return chapter_text("legacy_access") if bool(progress.get("legacy", false)) else mission_status_text(id)
	var parts: Array[String] = []
	if int(progress.get("current_nest_level", 1)) < int(progress.get("required_nest_level", 1)):
		parts.append(chapter_text("gate_nest", {"level": progress["required_nest_level"]}))
	var missing := String(progress.get("missing_prerequisite", ""))
	if not missing.is_empty():
		parts.append(chapter_text("gate_mission", {"mission": _title_for(missing)}))
	if int(progress.get("required", 0)) > 0:
		parts.append(chapter_text("branch_progress", {"done": int(progress.get("completed", 0)), "need": int(progress["required"]), "total": progress.get("choices", []).size()}))
	return " · ".join(parts) if not parts.is_empty() else chapter_text("locked")


func board_rule_text() -> String:
	if _mission_choices().size() == 1:
		return chapter_text("isolated_review")
	var group := board_group()
	var result := chapter_text("stage_rule_%d" % int(group["stage"]))
	if not String(group["story"]).is_empty():
		var progress := Catalog.unlock_progress(g.campaign, group["story"])
		result += " · " + chapter_text("branch_progress", {"done": int(progress.get("completed", 0)), "need": int(progress.get("required", 0)), "total": progress.get("choices", []).size()})
	return result


func branch_button_lines(branch_id: String) -> Array[String]:
	var status := State.branch_purchase_status(g.campaign, branch_id)
	var first := chapter_text("branch_stock", {"branch": chapter_text("tissue_" + branch_id), "level": State.branch_level(g.campaign, branch_id), "balance": State.tissue_balance(g.campaign, branch_id)})
	var second := chapter_text("benefit_" + branch_id)
	match String(status.get("reason", "")):
		"max_level": first += " · " + chapter_text("branch_max")
		"nest_level": second = chapter_text("gate_nest", {"level": status.get("required_nest_level", 3)})
		_: first += " · -" + str(State.BRANCH_MATERIAL_COST)
	return [first, second]


func paragraphs() -> Array[String]:
	var result: Array[String] = []
	if notice != "":
		result.append(notice)
	if g._campaign_active():
		result.append(text("mission_active"))
		result.append(mission_description())
		if g.active_world.has_method("mission_notes"):
			for note in g.active_world.mission_notes(g):
				if note is Dictionary and note.get("key", "") is String and note.get("values", {}) is Dictionary:
					result.append(chapter_text(note["key"], note.get("values", {})))
		if g.active_world.has_method("warning_key"):
			result.append(chapter_text(g.active_world.warning_key()))
		result.append(progress_text())
		if g.game_over:
			result.append(chapter_text("mission_failed"))
		elif g._campaign_mission_ready():
			result.append(text("return_win"))
		result.append(text("confirm_retreat") if confirm_retreat else text("mission_paused"))
	else:
		var last: Dictionary = g.campaign.get("last_result", {})
		if not last.is_empty():
			var outcome := String(last.get("outcome", ""))
			if outcome == "victory":
				var reward: Dictionary = last.get("reward", {})
				result.append(chapter_text("settlement_rewards", {"reward": reward_text(String(last.get("mission_id", mission_id())), reward)}) if int(reward.get("materials", 0)) > 0 else chapter_text("replay_no_reward"))
			else:
				result.append(chapter_text("mission_failed") if outcome == "failure" else text("retreated"))
		if g._founder_spore_active():
			result.append(text("settle_first"))
		result.append(mission_title() + " · " + mission_requirement_text(mission_id()))
		result.append(mission_description())
		result.append(chapter_text("chapter_end") if State.chapter_completed(g.campaign) else chapter_text("story_%d" % int(g.campaign.nest_level)))
		result.append(chapter_text("currency_rules"))
		result.append(chapter_text("branch_info"))
		result.append(chapter_text("nest_benefits"))
		result.append(chapter_text("optional_hint"))
		result.append(chapter_text("hub_help"))
	if _is_trial(mission_id()):
		result.append(chapter_text("trial_rules"))
	else:
		result.append(chapter_text("inheritance_note"))
		result.append(text("rules"))
		result.append(text("home_note"))
	return result


func panel_body_layout(viewport: Vector2) -> Dictionary:
	# This is also used by layout tests: drawing and hit targets share one source.
	var panel := panel_rect(viewport)
	var width := panel.size.x - 40.0
	var lines: Array[String] = []
	var font_size := 12 if panel.size.y >= 500.0 else 10
	var has_phase: bool = g._campaign_active() and not confirm_retreat and not _phase_action_key().is_empty()
	var first_baseline: float = board_layout(viewport)["detail_y"] if not g._campaign_active() else (135.0 if has_phase else 97.0)
	for paragraph in paragraphs():
		lines.append_array(g._wrap_guide_text(paragraph, width - 12, font_size))
		lines.append("")
	var line_height := font_size + 6
	var last_baseline := button_rect(viewport, 0).position.y - panel.position.y - 12.0
	var visible := maxi(1, 1 + int((last_baseline - first_baseline) / line_height))
	return {"lines": lines, "font_size": font_size, "line_height": line_height,
		"visible": visible, "first_baseline": first_baseline,
		"selection_height": first_baseline - 97.0, "has_phase": has_phase,
		"max_scroll": maxi(0, lines.size() - visible), "width": width - 12.0}


func _draw_text_line(rect: Rect2, value: String, baseline: float, color: Color, preferred: int = 12) -> void:
	g.draw_string(g.fallback_font, rect.position + Vector2(8, baseline), value, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, g._fit_font_size(value, rect.size.x - 16, preferred, 7), color)


func _draw_home_board(viewport: Vector2) -> void:
	var panel := panel_rect(viewport)
	var layout := board_layout(viewport)
	var compact: bool = layout["compact"]
	var groups := _board_groups()
	for index in groups.size():
		var rect := stage_rect(viewport, index)
		var accent := Color("f2d797") if index == selection_start else Color("88a8aa")
		g.draw_style_box(g._rounded_style(Color("163a3c") if index == selection_start else Color("0c2630"), accent, 5, 1), rect)
		var label := chapter_text("isolated_review") if groups.size() == 1 else chapter_text("stage_%d" % int(groups[index]["stage"]))
		_draw_text_line(rect, label, rect.size.y * 0.5 + 4.0, accent, 11)
	var rule := board_rule_text()
	g.draw_string(g.fallback_font, panel.position + Vector2(20, layout["rule_y"]), rule, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 40, g._fit_font_size(rule, panel.size.x - 40, 11, 7), Color("cbe5db"))
	var choices := board_missions()
	for index in choices.size():
		var id := choices[index]
		var rect := selection_rect(viewport, index)
		var selected := id == mission_id()
		var accent := Color("f2d797") if selected else (Color("bad7c1") if Catalog.is_unlocked(g.campaign, id) else Color("61777e"))
		g.draw_style_box(g._rounded_style(Color("163a3c") if selected else Color("0c2630"), accent, 7, 2 if selected else 1), rect)
		_draw_text_line(rect, _title_for(id), 15 if compact else 21, accent, 12 if compact else 14)
		_draw_text_line(rect, chapter_text(id + "_role"), 29 if compact else 43, Color("cbe5db"), 9 if compact else 11)
		_draw_text_line(rect, card_reward_text(id), 43 if compact else 64, Color("d7c697"), 8 if compact else 10)
		_draw_text_line(rect, mission_status_text(id), 57 if compact else 84, accent, 8 if compact else 10)
	var story := String(board_group()["story"])
	var story_box := story_rect(viewport)
	if not story.is_empty():
		var accent := Color("f2d797") if mission_id() == story else Color("b9a4d7")
		g.draw_style_box(g._rounded_style(Color("24323d") if mission_id() == story else Color("111f2d"), accent, 6, 2 if mission_id() == story else 1), story_box)
		_draw_text_line(story_box, chapter_text("story_challenge", {"mission": _title_for(story)}) + " · " + mission_status_text(story), 13 if compact else 17, accent, 10 if compact else 12)
		_draw_text_line(story_box, mission_requirement_text(story) if not Catalog.is_unlocked(g.campaign, story) else card_reward_text(story), 26 if compact else 34, Color("cbe5db"), 8 if compact else 10)
	else:
		_draw_text_line(story_box, chapter_text("optional_hint") if _mission_choices().size() > 1 else chapter_text("isolated_note"), story_box.size.y * 0.5 + 4, Color("88a8aa"), 10)
	for index in range(3):
		var branch_id: String = State.BRANCH_IDS[index]
		var rect := branch_rect(viewport, index)
		var enabled: bool = State.can_purchase_branch(g.campaign, branch_id) and not g.game_over
		var accent := Color("bad7c1") if enabled else Color("829995")
		g.draw_style_box(g._rounded_style(Color("163a3c") if enabled and rect.has_point(g.last_mouse) else Color("0c2630"), accent, 6, 1), rect)
		var labels := branch_button_lines(branch_id)
		_draw_text_line(rect, labels[0], 14 if compact else 18, accent, 9 if compact else 11)
		_draw_text_line(rect, labels[1], 29 if compact else 36, Color("cbe5db"), 8 if compact else 10)


func draw_panel(viewport: Vector2) -> void:
	g.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.015, 0.025, 0.88))
	var panel := panel_rect(viewport)
	g.draw_style_box(g._rounded_style(Color("081c26"), Color("a7c9b8"), 12, 2), panel)
	var width := panel.size.x - 40.0
	var compact := panel.size.y < 500.0
	var title := text("title")
	g.draw_string(g.fallback_font, panel.position + Vector2(20, 21 if compact else 28), title, HORIZONTAL_ALIGNMENT_LEFT, width, g._fit_font_size(title, width, 14 if compact else 18, 12), Color("f2d797"))
	var nest := text("nest", {"level": g.campaign.nest_level, "materials": g.campaign.materials})
	g.draw_string(g.fallback_font, panel.position + Vector2(20, 42 if compact else 52), nest, HORIZONTAL_ALIGNMENT_LEFT, width, g._fit_font_size(nest, width, 11 if compact else 12, 9), Color("cbe5db"))
	if g._campaign_active():
		var subtitle := mission_title()
		g.draw_string(g.fallback_font, panel.position + Vector2(20, 73), subtitle, HORIZONTAL_ALIGNMENT_LEFT, width, g._fit_font_size(subtitle, width, 10, 8), Color("88a8aa"))
	var body := panel_body_layout(viewport)
	var lines: Array[String] = body["lines"]
	var font_size: int = body["font_size"]
	var has_phase: bool = body["has_phase"]
	var line_height: int = body["line_height"]
	var visible: int = body["visible"]
	scroll = clampi(scroll, 0, int(body["max_scroll"]))
	for index in range(mini(visible, lines.size() - scroll)):
		g.draw_string(g.fallback_font, panel.position + Vector2(20, float(body["first_baseline"]) + index * line_height), lines[index + scroll], HORIZONTAL_ALIGNMENT_LEFT, width - 12, font_size, Color("cbe5db"))
	if lines.size() > visible:
		g.draw_string(g.fallback_font, panel.position + Vector2(panel.size.x - 30, float(body["first_baseline"])), "↕", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f2d797"))
	if not g._campaign_active():
		_draw_home_board(viewport)
	elif has_phase:
		_draw_button(phase_action_rect(viewport), chapter_text(_phase_action_key()), not g.game_over)
	var labels := action_labels()
	for index in range(3):
		_draw_button(button_rect(viewport, index), labels[index], action_enabled(index))


func _draw_button(rect: Rect2, label: String, enabled: bool) -> void:
	var accent := Color("bad7c1") if enabled else Color("465c60")
	g.draw_style_box(g._rounded_style(Color("163a3c") if rect.has_point(g.last_mouse) and enabled else Color("0c2630"), accent, 7, 1), rect)
	g.draw_string(g.fallback_font, rect.position + Vector2(8, 21), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, g._fit_font_size(label, rect.size.x - 16, 12, 7), accent)
