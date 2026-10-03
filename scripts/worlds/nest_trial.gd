extends "res://scripts/worlds/culture_world.gd"

# Challenge worlds receive a copy of the player's home. Only this runtime is
# mutated; campaign_controller owns the checkpoint and reward transaction.
const HomeWorld = preload("res://scripts/worlds/home_nest.gd")
const TRIAL_IDS := ["first_contact", "two_fronts", "stable_colony"]

@export var wave_sizes: Array[int] = [2, 3, 4]
@export var organic_required: float = 0.0
@export var mineral_required: float = 0.0
@export var hypha_world_required: float = 0.0
@export var raider_biomass: float = 1.2
@export var raider_speed: float = 8.0
@export var raider_attack_rate: float = 0.018


func generate_map(game) -> void:
	var home := HomeWorld.new()
	home.generate_map(game)
	home.free()


func initialize_colony(game) -> void:
	# Fallback for isolated scene tests. Production entry restores the real home
	# before initialize_trial() and never replaces the user's colony with this.
	game.founder_spore = {}
	game.cores.clear()
	game.cores.append(game._make_core(Vector2.ZERO))
	game.enemy_fungi_initialized = true
	game._update_exploration(false)


func initialize_trial(game) -> void:
	if not validate_definition() or bool(_state().get("initialized", false)):
		return
	game.enemy_fungi.clear()
	game.enemy_hyphae.clear()
	game.enemy_guard_spores.clear()
	game.enemy_fungi_initialized = true
	# Old environmental incidents must not ambush the manual preparation phase.
	game.ecology_events.clear()
	runtime.data["mission_state"] = {
		"initialized": true, "wave_index": 0, "completed_waves": 0,
		"wave_active": false, "raider_ids": [], "spawned_total": 0,
		"guard_defeats_baseline": int(game.lifetime_enemy_guards_defeated),
		"organic_baseline": float(game.lifetime_organic_absorbed),
		"mineral_baseline": float(game.lifetime_mineral_absorbed),
		"elapsed": 0.0
	}


func _state() -> Dictionary:
	var value = runtime.data.get("mission_state", {})
	return value if value is Dictionary else {}


func handles_enemy_guard(guard_id: int) -> bool:
	if guard_id < 1:
		return false
	for saved_id in _state().get("raider_ids", []):
		if int(saved_id) == guard_id:
			return true
	return false


func mission_tick(game, delta: float) -> void:
	var state := _state()
	if not bool(state.get("initialized", false)) or game.game_over or delta <= 0.0 or not is_finite(delta):
		return
	state["elapsed"] = float(state.get("elapsed", 0.0)) + delta
	if not bool(state.get("wave_active", false)):
		return
	var live_ids: Array = []
	for guard_id in state.get("raider_ids", []):
		var guard_index: int = game._enemy_guard_index_by_id(int(guard_id))
		if guard_index < 0:
			continue
		var guard: Dictionary = game.enemy_guard_spores[guard_index]
		if not bool(guard.get("alive", false)) or float(guard.get("biomass", 0.0)) <= 0.0005:
			continue
		live_ids.append(int(guard_id))
		_tick_raider(game, guard, delta)
	state["raider_ids"] = live_ids
	var defeated := maxi(0, int(game.lifetime_enemy_guards_defeated) - int(state.get("guard_defeats_baseline", 0)))
	# Absence alone cannot win: actual combat deaths must account for every
	# spawned raider. This also exposes restore/filter regressions instead of
	# converting vanished enemies into a free victory.
	if live_ids.is_empty() and defeated >= int(state.get("spawned_total", 0)):
		state["completed_waves"] = int(state.get("wave_index", 0))
		state["wave_active"] = false


func _tick_raider(game, guard: Dictionary, delta: float) -> void:
	var pos: Vector2 = guard["pos"]
	guard["damage_flash"] = maxf(0.0, float(guard.get("damage_flash", 0.0)) - delta)
	var unit_index: int = game._nearest_living_expedition_index(pos, 90.0)
	if unit_index >= 0:
		var unit: Dictionary = game.expedition_units[unit_index]
		var target: Vector2 = unit["pos"]
		guard["target_unit_id"] = int(unit.get("id", -1))
		guard["target_pos"] = target
		if pos.distance_to(target) > game.ENEMY_GUARD_ATTACK_RADIUS:
			guard["state"] = "chasing"
			guard["pos"] = pos.move_toward(target, raider_speed * delta)
		else:
			guard["state"] = "attacking"
			game._damage_expedition_unit(unit, raider_attack_rate * delta, "enemy_guard")
		return
	guard["target_unit_id"] = -1
	var nearest_core := -1
	var nearest_distance := INF
	for index in range(game.cores.size()):
		if not game._is_core_alive(index):
			continue
		var distance: float = pos.distance_squared_to(game.cores[index]["pos"])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_core = index
	if nearest_core < 0:
		return
	var target: Vector2 = game.cores[nearest_core]["pos"]
	guard["target_pos"] = target
	if pos.distance_to(target) > 22.0:
		guard["state"] = "chasing"
		guard["pos"] = pos.move_toward(target, raider_speed * delta)
	else:
		guard["state"] = "attacking"
		game._damage_core(nearest_core, raider_attack_rate * delta, "enemy_guard")


func mission_action(game) -> bool:
	var state := _state()
	if not validate_definition() or not bool(state.get("initialized", false)) or mission_failed(game):
		return false
	var wave := int(state.get("wave_index", 0))
	if bool(state.get("wave_active", false)) or wave >= wave_sizes.size():
		return false
	if not state.get("raider_ids", []).is_empty():
		return false
	if game.enemy_guard_spores.size() + wave_sizes[wave] > game.MAX_ENEMY_GUARD_SPORES:
		return false
	var ids: Array = []
	for index in range(wave_sizes[wave]):
		# First Contact alternates a single front. Later trials split every wave
		# across both sides of the player's current colony, not a fixed map origin.
		var direction := 1.0 if (wave % 2 == 0 if scene_id == "first_contact" else index % 2 == 0) else -1.0
		var anchor := _outer_core(game, direction)
		var offset := Vector2(direction * (420.0 + float(index / 2) * 14.0), float(index % 3 - 1) * 36.0)
		var spawn := anchor + offset
		var limit: float = game.WORLD_HALF - 30.0
		if spawn.length() > limit:
			spawn = spawn.normalized() * limit
		var guard: Dictionary = game._make_enemy_guard(-1, spawn)
		game.next_enemy_guard_id += 1
		guard["biomass"] = raider_biomass
		guard["max_biomass"] = raider_biomass
		guard["state"] = "chasing"
		game.enemy_guard_spores.append(guard)
		ids.append(int(guard["id"]))
	state["raider_ids"] = ids
	state["spawned_total"] = int(state.get("spawned_total", 0)) + ids.size()
	state["wave_index"] = wave + 1
	state["wave_active"] = true
	return true


func _outer_core(game, direction: float) -> Vector2:
	var selected := Vector2.ZERO
	var furthest := -INF
	for index in range(game.cores.size()):
		if game._is_core_alive(index):
			var pos: Vector2 = game.cores[index]["pos"]
			if pos.x * direction > furthest:
				furthest = pos.x * direction
				selected = pos
	return selected


func manual_action_key(_game) -> String:
	var state := _state()
	if not bool(state.get("initialized", false)) or bool(state.get("wave_active", false)) or int(state.get("wave_index", 0)) >= wave_sizes.size():
		return ""
	return "trial_start_wave"


func warning_key() -> String:
	if scene_id != "first_contact":
		return "trial_warning_two_fronts"
	var state := _state()
	var wave := int(state.get("wave_index", 0)) - (1 if bool(state.get("wave_active", false)) else 0)
	return "trial_warning_east" if wave % 2 == 0 else "trial_warning_west"


func mission_status(game) -> Array[Dictionary]:
	var state := _state()
	var total := 0
	for count in wave_sizes:
		total += count
	var result: Array[Dictionary] = [
		{"key": "trial_waves", "current": mini(int(state.get("completed_waves", 0)), wave_sizes.size()), "target": wave_sizes.size()},
		{"key": "trial_enemies", "current": mini(maxi(0, int(game.lifetime_enemy_guards_defeated) - int(state.get("guard_defeats_baseline", game.lifetime_enemy_guards_defeated))), total), "target": total}
	]
	if organic_required > 0.0:
		result.append({"key": "trial_organic", "current": clampf(float(game.lifetime_organic_absorbed) - float(state.get("organic_baseline", game.lifetime_organic_absorbed)), 0.0, organic_required), "target": organic_required})
	if mineral_required > 0.0:
		result.append({"key": "trial_mineral", "current": clampf(float(game.lifetime_mineral_absorbed) - float(state.get("mineral_baseline", game.lifetime_mineral_absorbed)), 0.0, mineral_required), "target": mineral_required})
	if hypha_world_required > 0.0:
		result.append({"key": "trial_network", "current": clampf(game._chapter_living_hypha_length() / 2.0, 0.0, hypha_world_required / 2.0), "target": hypha_world_required / 2.0})
	return result


func mission_ready(game) -> bool:
	if not validate_definition() or not bool(_state().get("initialized", false)) or mission_failed(game):
		return false
	for row in mission_status(game):
		if not is_finite(float(row["current"])) or float(row["current"]) + 0.000001 < float(row["target"]):
			return false
	return true


func mission_failed(game) -> bool:
	return game.game_over or game._living_core_count() <= 0


func validate_snapshot(raw: Dictionary) -> bool:
	if not super.validate_snapshot(raw):
		return false
	var state: Dictionary = raw["mission_state"]
	if not bool(state["wave_active"]):
		return true
	var guards = raw.get("enemy_guard_spores")
	if not guards is Array:
		return false
	for guard_id in state["raider_ids"]:
		var found := false
		for index in range(mini(guards.size(), SNAPSHOT_MAX_GUARDS)):
			var guard = guards[index]
			if guard is Dictionary and guard.get("id", -1) == guard_id:
				found = _snapshot_point_in_circle(guard, 12.0)
				break
		# A defeated guard can still be present on a legitimate failure frame.
		# A missing record cannot: it would strand the active wave on resume.
		if not found:
			return false
	return true


func validate_mission_state(raw: Dictionary) -> bool:
	if not validate_definition() or not raw.get("initialized") is bool or not raw["initialized"] or not raw.get("wave_active") is bool or not raw.get("raider_ids") is Array:
		return false
	for key in ["wave_index", "completed_waves", "spawned_total", "guard_defeats_baseline"]:
		var value = raw.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0.0 or float(value) != floorf(float(value)) or float(value) > 2147483647.0:
			return false
	for key in ["organic_baseline", "mineral_baseline", "elapsed"]:
		var value = raw.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0.0:
			return false
	var wave := int(raw["wave_index"])
	var completed := int(raw["completed_waves"])
	var active := bool(raw["wave_active"])
	if wave > wave_sizes.size() or completed != wave - (1 if active else 0):
		return false
	var expected_total := 0
	for index in range(wave):
		expected_total += wave_sizes[index]
	if int(raw["spawned_total"]) != expected_total:
		return false
	var ids: Array = raw["raider_ids"]
	if active:
		if wave < 1 or ids.is_empty() or ids.size() > wave_sizes[wave - 1]:
			return false
	elif not ids.is_empty():
		return false
	var seen := {}
	for id in ids:
		if not (id is int or id is float) or not is_finite(float(id)) or float(id) < 1.0 or float(id) != floorf(float(id)) or float(id) > 2147483647.0 or seen.has(int(id)):
			return false
		seen[int(id)] = true
	return true


func validate_definition() -> bool:
	if not super.validate_definition() or not TRIAL_IDS.has(scene_id) or wave_sizes.is_empty() or wave_sizes.size() > 8:
		return false
	for count in wave_sizes:
		if count < 1 or count > 16:
			return false
	for value in [organic_required, mineral_required, hypha_world_required]:
		if not is_finite(value) or value < 0.0:
			return false
	return is_finite(raider_biomass) and raider_biomass >= 0.5 and raider_biomass <= 4.0 and is_finite(raider_speed) and raider_speed > 0.0 and is_finite(raider_attack_rate) and raider_attack_rate > 0.0
