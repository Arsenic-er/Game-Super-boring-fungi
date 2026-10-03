extends "res://scripts/worlds/culture_world.gd"

const ResourceCluster = preload("res://scripts/worlds/resource_cluster.gd")
const IDS := ["substrate_race", "lost_network", "toxic_frontier", "boundary_counterattack"]
const RESCUE_SECONDS := 900.0

@export var starting_organic: float = 220.0
@export var starting_mineral: float = 24.0
@export var organic_required: float = 360.0
@export var mineral_required: float = 18.0
@export var map_seed: int = 8221

var _map_rng_state := 0


func generate_map(game) -> void:
	game.resources.clear()
	game.resource_grid.clear()
	game.bacteria.clear()
	game.resource_hotspots.clear()
	game.water_motes.clear()
	game.substrate_marks.clear()
	game.rng.seed = map_seed
	for cluster in get_node("ResourceClusters").get_children():
		cluster.populate(game)
	if scene_id == "substrate_race":
		for center in [Vector2(520, -180), Vector2(520, 210)]:
			for i in range(5):
				game.bacteria.append(game._make_bacterium(center + Vector2.from_angle(i * TAU / 5.0) * 34.0))
	_map_rng_state = game.rng.state
	game._generate_substrate()
	game.rng.state = _map_rng_state


func initialize_colony(game) -> void:
	game.founder_spore = {}
	game.organic = starting_organic
	game.mineral = starting_mineral
	game.dna = 0
	game.cores.clear()
	game.cores.append(game._make_core(Vector2.ZERO))
	game.core_selected_once = true
	game.enemy_fungi_initialized = true
	runtime.data["mission_state"] = {"mission_id": scene_id, "schema": 1, "started": false, "failed": false}
	if scene_id == "lost_network":
		for pos in [Vector2(420, -180), Vector2(510, 170)]:
			var dead: Dictionary = game._make_core(pos)
			dead["alive"] = false
			dead["biomass"] = 0.0
			game.cores.append(dead)
		var relay: Dictionary = game._make_core(Vector2(700, 210))
		relay["biomass"] = float(relay["max_biomass"]) * 0.25
		game.cores.append(relay)
		_state()["rescued"] = [0, 0]
		_state()["relay_id"] = 3
	if scene_id == "toxic_frontier":
		_state()["hazard_clock"] = 0.0
		_state()["hazard_cycles"] = 0
		_state()["visited_ids"] = []
		_state()["returned_ids"] = []
		_state()["previous_ids"] = []
		_state()["previous_cargo"] = []
	if scene_id == "boundary_counterattack":
		var enemy: Dictionary = game._make_enemy_fungus(Vector2(850, -20), "initial", 0)
		var enemy_id := int(enemy["id"])
		game.next_enemy_fungus_id += 1
		enemy["biomass"] = 40.0
		enemy["max_biomass"] = 40.0
		enemy["organic_reserve"] = 8.0
		game.enemy_fungi.append(enemy)
		game._append_initial_enemy_hyphae(enemy_id, enemy["pos"])
		game._seed_enemy_guards(enemy_id, 1)
		_state()["target_enemy_id"] = enemy_id
	game.rng.state = _map_rng_state
	game.explored_cells.clear()
	game.discovered_hotspots.clear()
	game.last_discovery_scan_cell_count = -1
	game._update_exploration(false)
	game._sync_hotspot_discoveries(false)


func _state() -> Dictionary:
	if not runtime.data.get("mission_state", null) is Dictionary:
		runtime.data["mission_state"] = {"started": false, "failed": false}
	return runtime.data["mission_state"]


func goal_targets() -> Dictionary:
	return {"organic": organic_required, "mineral": mineral_required, "length_world": 0.0}


func _row(key: String, current: float, target: float) -> Dictionary:
	return {"key": key, "current": clampf(current, 0.0, target) if is_finite(current) else 0.0, "target": target}


func mission_status(game) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match scene_id:
		"substrate_race":
			result.append(_row("campaign_goal_contested_patches", _contested_patches(game), 2.0))
			result.append(_row("campaign_goal_absorbed_organic", game.lifetime_organic_absorbed, organic_required))
			result.append(_row("campaign_goal_absorbed_mineral", game.lifetime_mineral_absorbed, mineral_required))
		"lost_network":
			var rescued: Array = _state().get("rescued", [0, 0])
			var count := 0
			for flag in rescued:
				count += 1 if int(flag) == 1 else 0
			result.append(_row("campaign_goal_networks_rescued", count, 2.0))
			var core_id := int(_state().get("relay_id", -1))
			var percent := 0.0
			if game._is_core_alive(core_id):
				percent = 100.0 * float(game.cores[core_id]["biomass"]) / maxf(1.0, float(game.cores[core_id]["max_biomass"]))
			result.append(_row("campaign_goal_relay_biomass", percent, 75.0))
			result.append(_row("campaign_goal_absorbed_organic", game.lifetime_organic_absorbed, organic_required))
		"toxic_frontier":
			result.append(_row("campaign_goal_cargo_organic", game.lifetime_expedition_organic_returned, organic_required))
			result.append(_row("campaign_goal_cargo_mineral", game.lifetime_expedition_mineral_returned, mineral_required))
			result.append(_row("campaign_goal_units_returned", _state().get("returned_ids", []).size(), 2.0))
		"boundary_counterattack":
			var defeated := 0.0
			var target_id := int(_state().get("target_enemy_id", -1))
			for enemy in game.enemy_fungi:
				if int(enemy["id"]) == target_id and not bool(enemy.get("alive", true)):
					defeated = 1.0
			result.append(_row("campaign_goal_target_defeated", defeated, 1.0))
			result.append(_row("campaign_goal_absorbed_organic", game.lifetime_organic_absorbed, organic_required))
	return result


func mission_ready(game) -> bool:
	if not validate_definition() or not validate_mission_state(_state()) or game.game_over or game._living_core_count() <= 0 or mission_failed(game):
		return false
	var rows := mission_status(game)
	if rows.is_empty():
		return false
	for row in rows:
		if float(row["current"]) + 0.000001 < float(row["target"]):
			return false
	return true


func mission_failed(game) -> bool:
	if bool(_state().get("failed", false)):
		return true
	return scene_id == "lost_network" and not game._is_core_alive(int(_state().get("relay_id", -1)))


func manual_action_key(_game) -> String:
	return "campaign_action_begin_rescue" if scene_id == "lost_network" and not bool(_state().get("started", false)) else ""


func mission_action(game) -> bool:
	if scene_id != "lost_network" or bool(_state().get("started", false)) or game.game_over:
		return false
	_state()["started"] = true
	_state()["rescue_elapsed"] = 0.0
	for i in range(2):
		var start := Vector2(420, -180) if i == 0 else Vector2(510, 170)
		var finish := start + Vector2(100, 0)
		game.segments.append({"a": start, "b": finish, "core_id": i + 1, "growth": 1.0, "curve": 0.0, "orphaned": true, "viability": 1.0})
		game._reveal_exploration(start, 140.0)
	game._update_exploration(false)
	return true


func mission_tick(game, delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or game.game_over:
		return
	if scene_id == "lost_network" and bool(_state().get("started", false)):
		_tick_rescue(game, delta)
	elif scene_id == "toxic_frontier":
		_tick_toxin(game, delta)
		_track_cargo_returns(game)


func _contested_patches(game) -> int:
	var count := 0
	for center in [Vector2(520, -180), Vector2(520, 210)]:
		var connected := false
		for segment in game.segments:
			if bool(segment.get("orphaned", false)) or float(segment.get("growth", 0.0)) < 1.0 or not game._is_core_alive(int(segment.get("core_id", -1))):
				continue
			if game._distance_to_line_segment(center, segment["a"], segment["b"]) <= 75.0:
				connected = true
				break
		if connected:
			count += 1
	return count


func _tick_rescue(game, delta: float) -> void:
	_state()["rescue_elapsed"] = float(_state().get("rescue_elapsed", 0.0)) + delta
	var flags: Array = _state().get("rescued", [0, 0])
	for i in range(2):
		if int(flags[i]) == 1:
			continue
		var start := Vector2(420, -180) if i == 0 else Vector2(510, 170)
		var found := false
		for segment in game.segments:
			if (segment["a"] as Vector2).distance_to(start) > 0.01 or (segment["b"] as Vector2).distance_to(start + Vector2(100, 0)) > 0.01:
				continue
			found = true
			if not bool(segment.get("orphaned", false)) and game._is_core_alive(int(segment.get("core_id", -1))):
				flags[i] = 1
			else:
				# The sealed sample offers a 15-minute rescue window rather than
				# the normal 3-minute decay. Ownership changes only in the real
				# colony reconnect implementation; this never resurrects cores.
				var restored: float = delta * (1.0 / game.ORPHAN_HYPHA_DECAY_SECONDS - 1.0 / RESCUE_SECONDS)
				segment["viability"] = minf(1.0, float(segment.get("viability", 1.0)) + restored)
			break
		if not found:
			_state()["failed"] = true
	_state()["rescued"] = flags


func _tick_toxin(game, delta: float) -> void:
	# Authored hazard is independent of diet unlocks. The safe southern route
	# is outside the cloud; no acid, climate or infinite unavoidable damage.
	_state()["hazard_clock"] = float(_state().get("hazard_clock", 0.0)) + delta
	if game.ecology_events.is_empty():
		if float(_state()["hazard_clock"]) < 180.0:
			return
		_state()["hazard_clock"] = 0.0
		var event_id := int(game.next_ecology_event_id)
		game.next_ecology_event_id += 1
		game.ecology_events = [{"id": event_id, "type": "toxin", "pos": Vector2(530, -100), "radius": 125.0, "phase": "warning", "remaining": 60.0, "anchor_core_id": 0, "spawned": 0, "control_progress": 0.0, "controlled_by_suppressor": false}]
		game._reveal_exploration(Vector2(530, -100), 160.0)
		game._show_ecology_banner(game._et("ecology_warning_title_fmt") % game._et("ecology_name_toxin"), game._et("ecology_warning_detail"), 7.0)
		game._play_sound("warning")
		return
	var event: Dictionary = game.ecology_events[0]
	event["remaining"] = maxf(0.0, float(event.get("remaining", 0.0)) - delta)
	if float(event["remaining"]) > 0.0:
		return
	if String(event.get("phase", "warning")) == "warning":
		event["phase"] = "active"
		event["remaining"] = 240.0
		_state()["hazard_cycles"] = int(_state().get("hazard_cycles", 0)) + 1
		game._show_ecology_banner(game._et("ecology_toxin_active_title"), game._et("ecology_toxin_active_detail_fmt") % 240, 7.0)
	else:
		game.ecology_events.clear()
		_state()["hazard_clock"] = 0.0


func _track_cargo_returns(game) -> void:
	var state := _state()
	var visited := _integer_ids(state.get("visited_ids", []))
	var returned := _integer_ids(state.get("returned_ids", []))
	var previous_ids := _integer_ids(state.get("previous_ids", []))
	var previous_cargo: Array = state.get("previous_cargo", [])
	var ids := []
	var cargo := []
	for unit in game.expedition_units:
		var id := int(unit["id"])
		var amount := float(unit.get("cargo_organic", 0.0)) + float(unit.get("cargo_mineral", 0.0))
		var pos: Vector2 = unit["pos"]
		if amount > 0.0005 and not visited.has(id):
			visited.append(id)
		var previous_index := previous_ids.find(id)
		if returned.size() < 2 and visited.has(id) and not returned.has(id) and previous_index >= 0 and previous_index < previous_cargo.size() and float(previous_cargo[previous_index]) > amount + 0.0005:
			var home: Vector2 = game._expedition_home_position(unit)
			if home.is_finite() and pos.distance_to(home) <= 32.0 and not bool(unit.get("lost", false)):
				returned.append(id)
		ids.append(id)
		cargo.append(amount)
	# Only living collectors and the first two proven returns are needed.
	# This remains bounded even if a long test produces hundreds of replacements.
	var relevant_visited := []
	for id in visited:
		if ids.has(id) or returned.has(id):
			relevant_visited.append(id)
	state["visited_ids"] = relevant_visited
	state["returned_ids"] = returned
	state["previous_ids"] = ids
	state["previous_cargo"] = cargo


func validate_definition() -> bool:
	if not super.validate_definition() or not IDS.has(scene_id):
		return false
	if not is_finite(starting_organic) or starting_organic < 0.0 or not is_finite(starting_mineral) or starting_mineral < 0.0:
		return false
	if not is_finite(organic_required) or organic_required <= 0.0 or not is_finite(mineral_required) or mineral_required < 0.0:
		return false
	var clusters := get_node_or_null("ResourceClusters")
	if not clusters is Node2D or clusters.get_child_count() < 2:
		return false
	for cluster in clusters.get_children():
		if not cluster is ResourceCluster or not cluster.validate_definition():
			return false
	return true

func validate_snapshot(raw: Dictionary) -> bool:
	if not super.validate_snapshot(raw):
		return false
	var state: Dictionary = raw["mission_state"]
	if scene_id == "lost_network":
		var cores = raw.get("cores")
		var relay_id := int(state["relay_id"])
		# Core indices are stable across death. The relay may be dead in a
		# failed task, but a missing relay means the snapshot is incomplete.
		return cores is Array and cores.size() > relay_id and cores[relay_id] is Dictionary
	if scene_id == "boundary_counterattack":
		var enemies = raw.get("enemy_fungi")
		if not enemies is Array:
			return false
		for index in range(mini(enemies.size(), SNAPSHOT_MAX_ENEMY_CORES)):
			var enemy = enemies[index]
			if enemy is Dictionary and enemy.get("id", -1) == state["target_enemy_id"]:
				# Keep defeated targets valid: their record proves this specific
				# core was destroyed rather than silently dropped during load.
				return _snapshot_point_in_circle(enemy, 20.0)
		return false
	return true

func validate_mission_state(raw: Dictionary) -> bool:
	if raw.get("mission_id", "") != scene_id or not _finite_number(raw.get("schema", null), 1.0, 1.0, true) or not raw.get("started", null) is bool or not raw.get("failed", null) is bool:
		return false
	if scene_id == "lost_network":
		if raw.get("relay_id", -1) != 3 or not _number_array(raw.get("rescued", null), 2, 0.0, 1.0, true):
			return false
		if raw["rescued"].size() != 2:
			return false
		if bool(raw["started"]):
			if not _finite_number(raw.get("rescue_elapsed", null), 0.0, 315360000.0):
				return false
		else:
			for flag in raw["rescued"]:
				if int(flag) != 0:
					return false
	if scene_id == "toxic_frontier":
		if not _finite_number(raw.get("hazard_clock", null), 0.0, 1000.0) or not _finite_number(raw.get("hazard_cycles", null), 0.0, 10000000.0, true):
			return false
		for key in ["visited_ids", "returned_ids", "previous_ids"]:
			var maximum_ids := 2 if key == "returned_ids" else (64 if key == "previous_ids" else 66)
			if not _number_array(raw.get(key, null), maximum_ids, 1.0, 2147483647.0, true):
				return false
			var seen := {}
			for id in raw[key]:
				if seen.has(int(id)):
					return false
				seen[int(id)] = true
		if not _number_array(raw.get("previous_cargo", null), 64, 0.0, 1000000.0) or raw["previous_ids"].size() != raw["previous_cargo"].size():
			return false
		for id in raw["returned_ids"]:
			if not _integer_ids(raw["visited_ids"]).has(int(id)):
				return false
	if scene_id == "boundary_counterattack" and not _finite_number(raw.get("target_enemy_id", null), 1.0, 1.0, true):
		return false
	return true


func _finite_number(value, minimum: float, maximum: float, whole: bool = false) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum and (not whole or float(value) == floorf(float(value)))


func _number_array(value, maximum_size: int, minimum: float, maximum: float, whole: bool = false) -> bool:
	if not value is Array or value.size() > maximum_size:
		return false
	for item in value:
		if not _finite_number(item, minimum, maximum, whole):
			return false
	return true

func _integer_ids(raw: Array) -> Array:
	# JSON stores numbers as floats. Variant Array.has/find do not equate
	# float IDs with integer unit IDs, so normalize after every resume.
	var result := []
	for value in raw:
		result.append(int(value))
	return result

func mission_markers(_game) -> Array[Dictionary]:
	# Task intelligence markers are not fog reveals or spawned game entities.
	var result: Array[Dictionary] = []
	if scene_id == "substrate_race":
		for center in [Vector2(520, -180), Vector2(520, 210)]:
			result.append({"pos": center, "radius": 75.0, "key": "campaign_marker_contested_patch", "accent": "e3be78"})
	elif scene_id == "lost_network":
		for center in [Vector2(420, -180), Vector2(510, 170)]:
			result.append({"pos": center, "radius": 32.0, "key": "campaign_marker_orphan_network", "accent": "e3be78"})
		result.append({"pos": Vector2(700, 210), "radius": 38.0, "key": "campaign_marker_damaged_relay", "accent": "89d9bd"})
	return result


func mission_notes(_game) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match scene_id:
		"substrate_race":
			result.append({"key": "campaign_note_contested", "values": {}})
		"lost_network":
			if not bool(_state().get("started", false)):
				result.append({"key": "campaign_note_rescue_prepare", "values": {"minutes": int(RESCUE_SECONDS / 60.0)}})
			else:
				var rescued: Array = _state().get("rescued", [0, 0])
				if rescued.size() == 2 and int(rescued[0]) == 1 and int(rescued[1]) == 1:
					result.append({"key": "campaign_note_rescue_recovered", "values": {}})
				else:
					result.append({"key": "campaign_note_rescue_remaining", "values": {"seconds": ceili(maxf(0.0, RESCUE_SECONDS - float(_state().get("rescue_elapsed", 0.0))))}})
		"toxic_frontier":
			result.append({"key": "campaign_note_toxin_returns", "values": {}})
		"boundary_counterattack":
			result.append({"key": "campaign_note_scout_east", "values": {}})
	return result
