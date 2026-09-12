extends "res://tests/chapter1_supply_expansion_smoke.gd"


# Full normal-mode scripted route. All entities, costs, damage, movement and
# production remain real; this is not an estimate of new-player completion time.
# The full route has been measured below the unchanged 120-second smoke budget.
const VICTORY_DEADLINE_SECONDS := 60.0 * 60.0
const FORWARD_BASE := Vector2(1450.0, -700.0)
const FORWARD_HYPHA_TIP := Vector2(2060.0, -990.0)
const STAGING_POINT := Vector2(2010.0, -940.0)
const ASSAULT_MIN := Vector2(2120.0, -1130.0)
const ASSAULT_MAX := Vector2(2280.0, -970.0)
const ARMY_TARGET := 10
const MAX_REPLACEMENTS := 8

var fighting := false
var victory_started_ms := 0
var forward_barracks_id := -1
var initial_rival_id := -1
var repair_orders := 0
var replacement_orders := 0
var commanded_units := {}
var observed_states := {}
var next_snapshot_at := 0.0
var next_orders_at := 0.0
var battle_milestones := {}


func _after_supply_expansion() -> bool:
	# The parent observer attributes cargo to its one economic-route unit. From
	# here a whole army may return cargo; keep its route unchanged and switch to
	# the all-unit accounting observer below.
	following_up = false
	fighting = true
	victory_started_ms = Time.get_ticks_msec()
	var initial_enemy: Dictionary = game.enemy_fungi[0]
	initial_rival_id = int(initial_enemy["id"])
	if not _check(bool(initial_enemy.get("alive", false)) and String(initial_enemy.get("source", "")) == "initial", "the original rival is alive at the beginning of the intact-world assault route"):
		return false
	battle_milestones["economic_goals"] = elapsed_seconds
	next_snapshot_at = elapsed_seconds
	_queue_dna(0, 1)
	_queue_dna(1, 1)
	if failed:
		return false
	var front_segment := _extend_to(2, FORWARD_BASE)
	if failed:
		return false
	forward_barracks_id = _build_at_tip(front_segment, true)
	if failed:
		return false
	battle_milestones["forward_barracks"] = elapsed_seconds
	# Leave new troops on ordinary automatic self-defense around the barracks;
	# a manual hold rally would forbid responding to approaching enemy guards.
	var before := _balances()
	if not _check(game._queue_expedition_spores(forward_barracks_id, "forager", ARMY_TARGET, false), "the forward barracks accepts ten normally paid basic foragers"):
		return false
	_record_spend(before)
	_extend_to(forward_barracks_id, FORWARD_HYPHA_TIP)
	if failed:
		return false
	while not (game.cores[forward_barracks_id].get("spore_jobs", []) as Array).is_empty() and elapsed_seconds < VICTORY_DEADLINE_SECONDS and not failed:
		_tick()
	if not _check(game.lifetime_expedition_units_built >= ARMY_TARGET + 1 and not _front_units().is_empty(), "the real ten-unit production queue finishes and surviving troops can advance despite combat casualties"):
		return false
	battle_milestones["army_ready"] = elapsed_seconds
	_select_front_units(false)
	game._issue_expedition_command(game.world_to_screen(STAGING_POINT))
	var discovery_deadline := elapsed_seconds + 60.0
	while not bool(_rival().get("discovered", false)) and elapsed_seconds < discovery_deadline and not failed:
		_tick()
	if not _check(bool(_rival().get("discovered", false)) and game._is_world_explored(_rival()["pos"]), "normal forward expansion or troop movement reveals the original rival before any assault zone is issued"):
		return false
	if not battle_milestones.has("rival_discovered"):
		battle_milestones["rival_discovered"] = elapsed_seconds
	_select_front_units(false)
	if not _check(game._assign_defense_zone(ASSAULT_MIN, ASSAULT_MAX) > 0, "a visible small defense zone starts the real core assault"):
		return false
	for unit in _front_units():
		if bool(unit.get("defense_enabled", false)):
			commanded_units[int(unit["id"])] = true
	battle_milestones["assault_ordered"] = elapsed_seconds
	next_snapshot_at = elapsed_seconds
	while not game.chapter_complete and elapsed_seconds < VICTORY_DEADLINE_SECONDS and not failed:
		if elapsed_seconds >= next_orders_at:
			_service_army()
			next_orders_at = elapsed_seconds + 5.0
		if elapsed_seconds >= next_snapshot_at:
			_snapshot("progress")
			next_snapshot_at = elapsed_seconds + 120.0
		_tick()
	if failed:
		return false
	_snapshot("final")
	if not _check(game.chapter_complete and game.chapter_task_index == 11 and game.chapter_report_open and game.chapter_completed_rules_version == 2 and not bool(_rival().get("alive", true)), "normal combat defeats the original rival and opens the current composite chapter-completion report"):
		return false
	if not _check(game._chapter_supply_ready() and game._chapter_expansion_ready() and game._living_core_count() >= 3 and not game.developer_mode_enabled, "economic goals and living expansion still qualify at actual victory"):
		return false
	if not _check(game.lifetime_dna_produced == 6 and int(game.survival_levels.get("repair", 0)) == 1 and game.lifetime_expedition_units_built >= ARMY_TARGET + 1, "additional paid DNA, the real repair upgrade and normally produced troops support the victory"):
		return false
	print("CHAPTER1_VICTORY_PROGRESSION_OK intact_world=true paid_army=true original_rival_defeated=true composite_completion=true elapsed_seconds=", elapsed_seconds, " battle_runtime_ms=", Time.get_ticks_msec() - victory_started_ms)
	fighting = false
	return _after_victory()


func _after_victory() -> bool:
	# Longer diagnostics can continue this real completed world without making
	# the normal smoke test perform post-victory days of simulation.
	return true


func _extend_to(core_id: int, target: Vector2) -> int:
	var segment_id := -1
	for _part in range(12):
		if not _paid_extension(core_id, target):
			return -1
		segment_id = game.segments.size() - 1
		if (game.segments[segment_id]["b"] as Vector2).distance_to(target) < 0.01:
			return segment_id
	_check(false, "the selected forward waypoint is reachable with bounded real hypha commands")
	return -1


func _rival() -> Dictionary:
	var index: int = game._enemy_fungus_index_by_id(initial_rival_id)
	return game.enemy_fungi[index] if index >= 0 else {}


func _front_units() -> Array:
	var units: Array = []
	for unit in game.expedition_units:
		if int(unit.get("home_core_id", -1)) == forward_barracks_id and not bool(unit.get("lost", false)):
			units.append(unit)
	return units


func _select_front_units(only_unassigned: bool) -> void:
	game.selected_expedition_ids = []
	for unit in _front_units():
		if ["retreating", "repairing", "wounded"].has(String(unit.get("state", "idle"))):
			continue
		if only_unassigned and bool(unit.get("defense_enabled", false)):
			continue
		game.selected_expedition_ids.append(int(unit["id"]))


func _service_army() -> void:
	if int(game.survival_levels.get("repair", 0)) == 0 and game.dna >= game._survival_cost("repair"):
		var before := _balances()
		game._purchase_survival("repair")
		_record_spend(before)
		battle_milestones["repair_upgrade"] = elapsed_seconds
	for core_id in range(game.cores.size()):
		var core: Dictionary = game.cores[core_id]
		if game._is_core_alive(core_id) and float(core.get("biomass", 0.0)) < 70.0 and float(core.get("repair_reserve", 0.0)) < 5.0 and game.organic >= game.CORE_REPAIR_ORGANIC_COST:
			var before := _balances()
			game._repair_core(core_id)
			_record_spend(before)
			repair_orders += 1
	if not game._is_core_alive(forward_barracks_id):
		_check(false, "the paid forward barracks must remain alive for retreat and real replenishment")
		return
	var queued: int = (game.cores[forward_barracks_id].get("spore_jobs", []) as Array).size()
	if _front_units().size() + queued < ARMY_TARGET and replacement_orders < MAX_REPLACEMENTS and game.organic >= game.EXPEDITION_SPORE_ORGANIC_COST and game.mineral >= game.EXPEDITION_SPORE_MINERAL_COST:
		var before := _balances()
		if game._queue_expedition_spores(forward_barracks_id, "forager", 1, false):
			_record_spend(before)
			replacement_orders += 1
	_select_front_units(true)
	if not game.selected_expedition_ids.is_empty():
		game._assign_defense_zone(ASSAULT_MIN, ASSAULT_MAX)


func _tick() -> void:
	super._tick()
	if not fighting or failed:
		return
	if not battle_milestones.has("rival_discovered") and bool(_rival().get("discovered", false)):
		battle_milestones["rival_discovered"] = elapsed_seconds
	if elapsed_seconds >= next_snapshot_at:
		_snapshot("route")
		next_snapshot_at = elapsed_seconds + 120.0
	for unit in _front_units():
		var state := String(unit.get("state", "unknown"))
		observed_states[state] = true
	var expected_organic := STARTING_ORGANIC + float(game.lifetime_organic_absorbed) + float(game.lifetime_expedition_organic_returned) + float(rewards["organic"]) - float(spent["organic"])
	var expected_mineral := STARTING_MINERAL + float(game.lifetime_mineral_absorbed) + float(game.lifetime_expedition_mineral_returned) + float(rewards["mineral"]) - float(spent["mineral"])
	_check(not game.developer_mode_enabled and absf(float(game.organic) - expected_organic) < 0.001 and absf(float(game.mineral) - expected_mineral) < 0.001 and game.dna == game.lifetime_dna_produced + int(rewards["dna"]) - int(spent["dna"]), "the whole assault preserves real absorption/cargo/reward/payment accounting")


func _snapshot(phase: String) -> void:
	var health: Array = []
	for core in game.cores:
		health.append(snappedf(float(core.get("biomass", 0.0)), 0.001))
	var states := {}
	for unit in _front_units():
		var state := String(unit.get("state", "unknown"))
		states[state] = int(states.get(state, 0)) + 1
	print("CHAPTER1_VICTORY_SNAPSHOT ", JSON.stringify({
		"phase": phase, "elapsed_seconds": elapsed_seconds, "chapter_complete": game.chapter_complete,
		"chapter_report_open": game.chapter_report_open, "completion_rules_version": game.chapter_completed_rules_version,
		"rival_biomass": snappedf(float(_rival().get("biomass", -1.0)), 0.001), "rival_alive": _rival().get("alive", false),
		"organic": snappedf(game.organic, 0.001), "mineral": snappedf(game.mineral, 0.001), "dna": game.dna,
		"absorbed_organic": snappedf(game.lifetime_organic_absorbed, 0.001), "absorbed_mineral": snappedf(game.lifetime_mineral_absorbed, 0.001),
		"returned_organic": snappedf(game.lifetime_expedition_organic_returned, 0.001), "returned_mineral": snappedf(game.lifetime_expedition_mineral_returned, 0.001),
		"total_spent": spent, "claimed_rewards": rewards, "dna_produced": game.lifetime_dna_produced,
		"units_built": game.lifetime_expedition_units_built, "units_lost": game.lifetime_expedition_units_lost, "units_repaired": game.lifetime_expedition_units_repaired,
		"replacement_orders": replacement_orders, "core_repair_orders": repair_orders, "army_states": states, "observed_army_states": observed_states.keys(),
		"enemy_guards_defeated": game.lifetime_enemy_guards_defeated, "core_biomass": health,
		"living_hypha_length": snappedf(game._chapter_living_hypha_length(), 0.001), "milestones": battle_milestones,
		"battle_runtime_ms": Time.get_ticks_msec() - victory_started_ms
	}))
