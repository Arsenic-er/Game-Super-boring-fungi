extends RefCounted

const State = preload("res://scripts/campaign_state.gd")
const Words = preload("res://scripts/campaign_localization.gd")
const ChapterWords = preload("res://scripts/campaign_chapter_localization.gd")
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


func _init(game) -> void:
	g = game


func text(key: String, values: Dictionary = {}) -> String:
	return Words.text(g.settings_locale, key, values)


func chapter_text(key: String, values: Dictionary = {}) -> String:
	return ChapterWords.text(g.settings_locale, key, values)


func mission_id() -> String:
	if g._campaign_active():
		return String(g.campaign["active_mission"]["id"])
	return selected_mission_id if Catalog.is_implemented(selected_mission_id) else State.MISSION_ID


func mission_title() -> String:
	return chapter_text("remote_pantry_title") if mission_id() == "remote_pantry" else text("mission_title")


func mission_description() -> String:
	return chapter_text("remote_pantry_desc", mission_values()) if mission_id() == "remote_pantry" else text("mission_desc", mission_values())


func selection_rect(viewport: Vector2, index: int) -> Rect2:
	var panel := panel_rect(viewport)
	var width := (panel.size.x - 48.0) * 0.5
	return Rect2(panel.position + Vector2(20 + index * (width + 8), 82), Vector2(width, 30))


func _mission_choices() -> Array[String]:
	return [State.MISSION_ID, "remote_pantry"]


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
		selected_mission_id = State.recommended_mission_id(g.campaign)
	open = true
	confirm_retreat = false
	scroll = 0
	g._play_sound("panel_open")
	g.queue_redraw()


func hud_rect() -> Rect2:
	return Rect2(18, 156, 180, 32)


func panel_rect(viewport: Vector2) -> Rect2:
	var size := Vector2(minf(860.0, viewport.x - 32.0), minf(600.0, viewport.y - 32.0))
	return Rect2((viewport - size) * 0.5, size)


func button_rect(viewport: Vector2, index: int) -> Rect2:
	var panel := panel_rect(viewport)
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
		for index in range(3):
			if button_rect(g.get_viewport_rect().size, index).has_point(event.position):
				var target := "campaign_%d" % index
				if g.audio_hover_target != target:
					g.audio_hover_target = target
					g._play_sound("ui_hover", 0.65)
	elif event is InputEventMouseButton:
		g.last_mouse = event.position
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
			scroll = maxi(0, scroll + (2 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -2))
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not g._campaign_active():
				for choice_index in range(_mission_choices().size()):
					if selection_rect(g.get_viewport_rect().size, choice_index).has_point(event.position):
						selected_mission_id = _mission_choices()[choice_index]
						scroll = 0
						g._play_sound("ui_confirm")
						g.queue_redraw()
						return true
			for index in range(3):
				if button_rect(g.get_viewport_rect().size, index).has_point(event.position):
					activate(index)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if confirm_retreat:
				confirm_retreat = false
			else:
				reset_panel()
			g._play_sound("ui_cancel")
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
	g._play_sound("upgrade")
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
	return [text("retry") if g.campaign.get("completed", {}).get(mission_id(), false) else text("start"), text("upgrade"), text("close")]


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
		return "hint_dead"
	if g._campaign_mission_ready():
		return "hint_ready"
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
	if mission_id() == "remote_pantry" and progress_hint_key() not in ["hint_ready", "hint_dead"]:
		hint = chapter_text(progress_hint_key())
	if rect.size.y <= 60:
		lines.append(_progress_line(hint, "hint", 13, width, 10))
		lines.append(_progress_line(progress_text(true), "progress", 28, width, 9))
		return lines
	lines.append(_progress_line(mission_title(), "title", 22, width, 12))
	if rect.size.y < 100:
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


func paragraphs() -> Array[String]:
	var result: Array[String] = []
	if notice != "":
		result.append(notice)
	if g._campaign_active():
		result.append(text("mission_active"))
		result.append(mission_description())
		result.append(progress_text())
		if g.game_over:
			result.append(text("failure"))
		elif g._campaign_mission_ready():
			result.append(text("return_win"))
		result.append(text("confirm_retreat") if confirm_retreat else text("mission_paused"))
	else:
		var last: Dictionary = g.campaign.get("last_result", {})
		if not last.is_empty():
			var outcome := String(last.get("outcome", ""))
			var reward_value = last.get("reward", {})
			var reward: int = int(reward_value.get("materials", 0)) if reward_value is Dictionary else int(reward_value)
			result.append(text("victory", {"reward": reward}) if outcome == "victory" else text("failure" if outcome == "failure" else "retreated"))
		if int(g.campaign.nest_level) >= 2:
			result.append(text("story"))
			if bool(g.campaign.get("completed", {}).get("remote_pantry", false)):
				result.append(chapter_text("remote_pantry_story"))
		else:
			result.append(text("settle_first") if g._founder_spore_active() else text("need_materials"))
		result.append(mission_title())
		result.append(mission_description())
		if not Catalog.is_unlocked(g.campaign, mission_id()):
			result.append(chapter_text("mission_locked"))
		result.append(chapter_text("chapter_roster"))
		for entry in Catalog.entries():
			var id: String = String(entry["id"])
			var status_key := "planned" if not Catalog.is_implemented(id) else ("mission_done" if bool(g.campaign.get("completed", {}).get(id, false)) else "mission_ready")
			if Catalog.is_implemented(id) and not Catalog.is_unlocked(g.campaign, id):
				status_key = "mission_locked"
			result.append(chapter_text(id + "_title") + " · " + chapter_text(status_key))
	result.append(chapter_text("inheritance_note"))
	result.append(text("rules"))
	result.append(text("home_note"))
	return result


func draw_panel(viewport: Vector2) -> void:
	g.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.015, 0.025, 0.88))
	var panel := panel_rect(viewport)
	g.draw_style_box(g._rounded_style(Color("081c26"), Color("a7c9b8"), 12, 2), panel)
	var width := panel.size.x - 40.0
	var title := text("title")
	g.draw_string(g.fallback_font, panel.position + Vector2(20, 28), title, HORIZONTAL_ALIGNMENT_LEFT, width, g._fit_font_size(title, width, 18, 12), Color("f2d797"))
	var nest := text("nest", {"level": g.campaign.nest_level, "materials": g.campaign.materials})
	g.draw_string(g.fallback_font, panel.position + Vector2(20, 52), nest, HORIZONTAL_ALIGNMENT_LEFT, width, g._fit_font_size(nest, width, 12, 9), Color("cbe5db"))
	var subtitle := text("prototype")
	g.draw_string(g.fallback_font, panel.position + Vector2(20, 73), subtitle, HORIZONTAL_ALIGNMENT_LEFT, width, g._fit_font_size(subtitle, width, 10, 8), Color("88a8aa"))
	var lines: Array[String] = []
	var font_size := 12 if panel.size.y >= 440.0 else 10
	var selection_height := 38.0 if not g._campaign_active() else 0.0
	for paragraph in paragraphs():
		lines.append_array(g._wrap_guide_text(paragraph, width - 12, font_size))
		lines.append("")
	var line_height := font_size + 6
	var visible := maxi(1, int((panel.size.y - 220.0 - selection_height) / line_height))
	scroll = clampi(scroll, 0, maxi(0, lines.size() - visible))
	for index in range(mini(visible, lines.size() - scroll)):
		g.draw_string(g.fallback_font, panel.position + Vector2(20, 97 + selection_height + index * line_height), lines[index + scroll], HORIZONTAL_ALIGNMENT_LEFT, width - 12, font_size, Color("cbe5db"))
	if lines.size() > visible:
		g.draw_string(g.fallback_font, panel.position + Vector2(panel.size.x - 30, 100 + selection_height), "↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f2d797"))
		g.draw_string(g.fallback_font, panel.position + Vector2(panel.size.x - 30, panel.size.y - 142), "↓", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f2d797"))
	if not g._campaign_active():
		for choice_index in range(_mission_choices().size()):
			var id := _mission_choices()[choice_index]
			var choice := selection_rect(viewport, choice_index)
			var selected := id == mission_id()
			var accent := Color("f2d797") if selected else Color("88a8aa")
			g.draw_style_box(g._rounded_style(Color("163a3c") if selected else Color("0c2630"), accent, 6, 1), choice)
			var label := chapter_text(id + "_title")
			g.draw_string(g.fallback_font, choice.position + Vector2(8, 21), label, HORIZONTAL_ALIGNMENT_CENTER, choice.size.x - 16, g._fit_font_size(label, choice.size.x - 16, 12, 8), accent)
	var labels := action_labels()
	for index in range(3):
		var rect := button_rect(viewport, index)
		var enabled := action_enabled(index)
		var accent := Color("bad7c1") if enabled else Color("465c60")
		g.draw_style_box(g._rounded_style(Color("163a3c") if rect.has_point(g.last_mouse) and enabled else Color("0c2630"), accent, 7, 1), rect)
		g.draw_string(g.fallback_font, rect.position + Vector2(12, 21), labels[index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24, g._fit_font_size(labels[index], rect.size.x - 24, 12, 8), accent)
