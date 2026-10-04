extends "res://scripts/campaign_controller.gd"

# Only ReviewSlice installs this controller. Ordinary campaigns keep their
# full mission selection, progression and replay behavior.

func progress_hud_lines(rect: Rect2) -> Array[Dictionary]:
	return g.ReviewObjectives.hud_lines(g, rect)


func _mission_choices() -> Array[String]:
	return [String(g.review_mission_id)]


func _sync_selection() -> void:
	selected_mission_id = g.review_mission_id
	selection_start = 0


func show_panel() -> void:
	super.show_panel()
	if not g._campaign_active() and bool(g.review_result.get("settled", false)):
		notice = g._review_text("replay_locked")


func action_enabled(index: int) -> bool:
	if index == 0 and not g._campaign_active() and bool(g.review_result.get("settled", false)):
		return false
	return super.action_enabled(index)


func start_mission(requested_id: String = State.MISSION_ID) -> bool:
	if requested_id != g.review_mission_id or bool(g.review_result.get("settled", false)):
		notice = g._review_text("replay_locked")
		g.review_notice = notice
		g.queue_redraw()
		return false
	return super.start_mission(requested_id)


func return_home(outcome: String) -> bool:
	if not super.return_home(outcome):
		return false
	# Do this for mouse, keyboard and direct callers, before another frame runs.
	g._review_detect_settlement()
	return true
