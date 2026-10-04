extends RefCounted

const Worlds = preload("res://scripts/worlds/world_scene_catalog.gd")


# Read the same counters and scene-defined thresholds as mission completion.
# Never restore the unrelated legacy home tutorial inside an expedition.
static func rows(game) -> Array[Dictionary]:
	var active: bool = game._campaign_active()
	var world: Node2D = game.active_world if active else Worlds.prepare(game.review_mission_id)
	var result: Array[Dictionary] = []
	if world == null:
		return result
	var id: String = game.review_mission_id
	var raw: Array[Dictionary] = []
	if id in ["first_supply", "remote_pantry"]:
		var targets: Dictionary = world.goal_targets()
		var organic: float = game.lifetime_organic_absorbed if id == "first_supply" else game.lifetime_expedition_organic_returned
		var mineral: float = game.lifetime_mineral_absorbed if id == "first_supply" else game.lifetime_expedition_mineral_returned
		raw.append({"key": "campaign_goal_absorbed_organic" if id == "first_supply" else "campaign_goal_cargo_organic", "current": organic, "target": targets["organic"]})
		raw.append({"key": "campaign_goal_absorbed_mineral" if id == "first_supply" else "campaign_goal_cargo_mineral", "current": mineral, "target": targets["mineral"]})
		if id == "first_supply":
			raw.append({"key": "trial_network", "current": game._chapter_living_hypha_length(), "target": targets["length_world"], "display_scale": 0.5})
	else:
		raw = world.mission_status(game)
	for row in raw:
		var target := float(row["target"])
		var current := float(row["current"]) if active else 0.0
		var scale := float(row.get("display_scale", 1.0))
		var epsilon := 0.00000001 if id in ["first_supply", "remote_pantry"] else 0.000001
		var done := active and current >= target - epsilon
		var bounded := target if done else clampf(current, 0.0, target)
		var text: String = game.campaign_ui.chapter_text("mission_goal_row", {
			"name": game.campaign_ui.chapter_text(String(row["key"])),
			"current": game.campaign_ui._progress_number(bounded * scale, target * scale, false),
			"target": game.campaign_ui._goal_number(target * scale)
		})
		result.append({"key": row["key"], "text": text, "complete": done, "current": current, "target": target})
	if not active:
		world.free()
	return result


static func hint(game) -> String:
	if not game._campaign_active():
		return ""
	var key: String = game.campaign_ui.progress_hint_key()
	if key in ["mission_hint", "mission_failed_hint"] or (game.review_mission_id == "remote_pantry" and key not in ["hint_ready", "hint_dead"]):
		return game.campaign_ui.chapter_text(key)
	return game.campaign_ui.text(key)


static func briefing(game) -> String:
	var result: Array[String] = [game._review_text("progress") + " · [J]"]
	if game.review_started and not game._campaign_active():
		return ""
	for row in rows(game):
		result.append(("[x] " if row["complete"] else "[ ] ") + String(row["text"]))
	if game._campaign_active():
		result.append(hint(game))
	return "\n".join(result)


static func hud_rect(game, base: Rect2) -> Rect2:
	if not game._campaign_active():
		return base
	var count := rows(game).size()
	var viewport: Vector2 = game._layout_viewport_size()
	var wanted := maxf(112.0, 50.0 + count * 18.0)
	base.size.y = minf(wanted, maxf(90.0, viewport.y - base.position.y - 24.0))
	return base


static func hud_lines(game, rect: Rect2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var objectives := rows(game)
	var width := rect.size.x - 20.0
	result.append(game.campaign_ui._progress_line(game._review_text("progress") + " · [J]", "title", 19, width, 12))
	var spacing := minf(18.0, (rect.size.y - 49.0) / maxf(1.0, objectives.size()))
	for index in range(objectives.size()):
		var row: Dictionary = objectives[index]
		var label := ("[x] " if row["complete"] else "[ ] ") + String(row["text"])
		result.append(game.campaign_ui._progress_line(label, "progress", 37.0 + index * spacing, width, 11))
	result.append(game.campaign_ui._progress_line(hint(game), "hint", rect.size.y - 9.0, width, 10))
	return result
