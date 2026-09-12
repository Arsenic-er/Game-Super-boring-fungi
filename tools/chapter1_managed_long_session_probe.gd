extends "res://tests/chapter1_victory_progression_smoke.gd"


# Optional managed-session diagnostic; deliberately outside tests/*_smoke.gd.
# By default, the first two managed hours follow an actual first victory and
# are real online simulation. Later checkpoints mix two-minute online visits
# with unchanged offline settlement. The legacy route does not clear chapter 1.
const WALL_BUDGET_MS := 570000
const VISIT_SECONDS := 120.0
const LONG_CHECKPOINTS := [12.0, 24.0, 36.0, 48.0, 60.0, 72.0]
const PROBE_SAVE_PATH := "user://chapter1_managed_long_session_probe.json"

var probe_started_ms := 0
var managed := false
var online_seconds := 0.0
var offline_seconds := 0.0
var next_maintenance := 0.0
var next_production := 0.0
var next_expansion := 0.0
var actions: Array = []
var sessions: Array = []
var snapshots: Array = []
var observed_deaths: Array = []
var seen_dead_cores := {}
var repair_purchases := 0
var dna_batches := 0
var resumed_online_prefix := false
var resumed_prefix_seconds := 0.0
var postclear_mode := false
var managed_origin_seconds := 0.0
var reserve_organic := 150.0
var reserve_mineral := 10.0
var dna_queue_limit := 10
var maintenance_period := 300.0
var expansion_period := 1200.0
var short_frontier_mode := false
var construction_until := 0.0
var next_construction_check := 0.0
var pending_construction_segment := -1
var construction_orders_refreshed := false
var fixed_frontier_core := 6
var fixed_frontier_target := Vector2(-3178.308, 1681.778)


func _run() -> void:
	if OS.get_cmdline_user_args().has("--short-frontier-checkpoint"):
		await _recover_postclear_checkpoint(false, true)
		return
	if OS.get_cmdline_user_args().has("--postclear-checkpoint-window"):
		await _recover_postclear_checkpoint(true)
		return
	if OS.get_cmdline_user_args().has("--recover-postclear-checkpoint"):
		await _recover_postclear_checkpoint()
		return
	if OS.get_cmdline_user_args().has("--inspect-postclear-checkpoint"):
		await _inspect_postclear_checkpoint()
		return
	if not OS.get_cmdline_user_args().has("--resume-online-prefix"):
		await super._run()
		return
	# This continuation option accepts only an online-prefix checkpoint before
	# two hours. It never manufactures the unobserved remainder of that prefix.
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.developer_mode_enabled = false
	game.autosave_enabled = false
	game.splash_active = false
	game.save_path = PROBE_SAVE_PATH
	var file := FileAccess.open(PROBE_SAVE_PATH, FileAccess.READ)
	if not _check(file != null, "resume needs the isolated online-prefix checkpoint"):
		return
	var saved: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	var saved_world := float(saved.get("sim_time", 0.0))
	resumed_prefix_seconds = saved_world + 6.75
	if not _check(resumed_prefix_seconds >= 1200.0 and resumed_prefix_seconds < 7200.0, "only a measured pre-two-hour online prefix can use this continuation"):
		return
	if not _check(game._load_game(false), "resume uses the normal save reader"):
		return
	var recovery_absence := maxf(0.0, float(game.sim_time) - saved_world)
	offline_seconds = recovery_absence
	online_seconds = resumed_prefix_seconds
	elapsed_seconds = resumed_prefix_seconds + recovery_absence
	if game.offline_report_open:
		game._close_offline_report()
	game.main_menu_active = false
	game.game_started = true
	game.sim_speed = 1.0
	queued_dna = game.lifetime_dna_produced
	for core in game.cores:
		queued_dna += (core["jobs"] as Array).size()
	resumed_online_prefix = true
	print("MANAGED_RESUME_PREFIX ", JSON.stringify({"measured_online_prefix_seconds": resumed_prefix_seconds, "actual_loader_offline_seconds": recovery_absence, "new_segment_budget_ms": WALL_BUDGET_MS, "prior_actions": "retained in the preceding segment log, not recounted here"}))
	if _start_managed(false):
		game.queue_free()
		quit(0)


func _inspect_postclear_checkpoint() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.developer_mode_enabled = false
	game.autosave_enabled = false
	game.splash_active = false
	game.save_path = PROBE_SAVE_PATH
	if not _check(game._load_game(false), "inspect the real isolated checkpoint through the normal loader"):
		return
	if game.offline_report_open:
		game._close_offline_report()
	if game.chapter_report_open:
		game._close_chapter_report(false)
	game.main_menu_active = false
	game.game_started = true
	game.sim_speed = 1.0
	for index in range(5):
		print("MANAGED_CHECKPOINT_INSPECT ", JSON.stringify({
			"tick": index, "world_seconds": game.sim_time,
			"pause": game.pause_menu_open, "chapter_report": game.chapter_report_open,
			"offline_report": game.offline_report_open, "offline_settlement": game.offline_settlement_active,
			"main_menu": game.main_menu_active, "game_over": game.game_over,
			"ecology": game.ecology_events.duplicate(true),
			"incursion": game.fungal_incursion.duplicate(true)
		}))
		if index < 4:
			game._process(STEP_SECONDS)
	game.queue_free()
	quit(0)


func _recover_postclear_checkpoint(mixed_window := false, short_frontier := false) -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.developer_mode_enabled = false
	game.autosave_enabled = false
	game.splash_active = false
	game.save_path = PROBE_SAVE_PATH
	var file := FileAccess.open(PROBE_SAVE_PATH, FileAccess.READ)
	if not _check(file != null, "recovery requires a genuine completed-culture checkpoint"):
		return
	var saved: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	var prior_world := float(saved.get("sim_time", 0.0))
	if not _check(game._load_game(false) and game.chapter_complete, "recover via the normal loader, without injecting completion"):
		return
	offline_seconds = maxf(0.0, float(game.sim_time) - prior_world)
	if game.offline_report_open:
		game._close_offline_report()
	if game.chapter_report_open:
		game._close_chapter_report(false)
	game.main_menu_active = false
	game.game_started = true
	game.sim_speed = 1.0
	managed = true
	postclear_mode = true
	following_up = false
	fighting = false
	forward_barracks_id = -1
	for core_id in range(game.cores.size()):
		if game._is_core_alive(core_id) and String(game.cores[core_id].get("kind", "normal")) == "barracks":
			forward_barracks_id = core_id
	elapsed_seconds = float(game.sim_time)
	managed_origin_seconds = elapsed_seconds
	reserve_organic = 300.0
	reserve_mineral = 30.0
	dna_queue_limit = 5
	if short_frontier:
		short_frontier_mode = true
		construction_until = elapsed_seconds + 600.0
		next_construction_check = elapsed_seconds
	queued_dna = game.lifetime_dna_produced
	for core in game.cores:
		queued_dna += (core["jobs"] as Array).size()
	next_maintenance = elapsed_seconds
	next_expansion = elapsed_seconds
	next_production = elapsed_seconds
	var before := _state()
	if mixed_window:
		print("MANAGED_NEW_WINDOW_POLICY ", JSON.stringify({"prior_saved_world_seconds": prior_world, "actual_loader_offline_seconds": offline_seconds, "new_observation_hours": 72, "visit_seconds": VISIT_SECONDS, "baseline": before, "note": "separate post-recovery 72h window; not a rerun of the first three days"}))
		_snapshot("new_window_start")
		for hour in LONG_CHECKPOINTS:
			next_maintenance = elapsed_seconds + 300.0
			_maintenance(true)
			var visit_end := elapsed_seconds + VISIT_SECONDS
			while elapsed_seconds < visit_end and not failed:
				_online_step()
			if failed:
				return
			_disable_auto_before_absence()
			if not _settle_to_checkpoint(managed_origin_seconds + float(hour) * 3600.0, hour, "new_window_%dh_arrival" % int(hour)):
				return
		print("MANAGED_NEW_WINDOW_RESULT ", JSON.stringify({"before": before, "after": _state(), "actions": actions, "online_seconds": online_seconds, "offline_seconds_including_loader": offline_seconds, "wall_ms": Time.get_ticks_msec() - probe_started_ms}))
		game.queue_free()
		quit(0)
		return
	print("MANAGED_RECOVERY_POLICY ", JSON.stringify({"prior_saved_world_seconds": prior_world, "actual_loader_offline_seconds": offline_seconds, "online_recovery_seconds": 1200 if short_frontier else 7200, "maintenance_seconds": maintenance_period, "expansion_seconds": expansion_period, "construction_window_seconds": 600.0 if short_frontier else 0.0, "construction_rule": "check each second; wait for real previous-segment maturity; keep repair/DNA cadence unchanged" if short_frontier else "periodic visits", "baseline": before, "note": "real checkpoint recovery, not a replacement for the preceding 72h result"}))
	if short_frontier and not _prepare_short_frontier():
		return
	var recovery_checkpoints: Array = [2, 5, 10, 20] if short_frontier else [20, 60, 120]
	for checkpoint_minutes in recovery_checkpoints:
		while elapsed_seconds < managed_origin_seconds + float(checkpoint_minutes) * 60.0 and not failed:
			_online_step()
		if failed:
			return
		_snapshot(("short_frontier_%dm_online" if short_frontier else "recovery_%dm_online") % checkpoint_minutes)
		_checkpoint()
	var after := _state()
	print("MANAGED_RECOVERY_RESULT ", JSON.stringify({"before": before, "after": after, "actions": actions, "online_seconds": online_seconds, "actual_loader_offline_seconds": offline_seconds, "wall_ms": Time.get_ticks_msec() - probe_started_ms}))
	game.queue_free()
	quit(0)


func _initialize() -> void:
	probe_started_ms = Time.get_ticks_msec()
	super._initialize()


func _after_supply_expansion() -> bool:
	if OS.get_cmdline_user_args().has("--legacy-insufficient"):
		return _start_managed(false)
	return super._after_supply_expansion()


func _after_victory() -> bool:
	return _start_managed(true)


func _start_managed(after_victory: bool) -> bool:
	following_up = false
	postclear_mode = after_victory
	managed_origin_seconds = elapsed_seconds if after_victory else 0.0
	reserve_organic = 300.0 if after_victory else 150.0
	reserve_mineral = 30.0 if after_victory else 10.0
	dna_queue_limit = 5 if after_victory else 10
	managed = true
	if not resumed_online_prefix:
		online_seconds = 0.0 if after_victory else elapsed_seconds
	if game.chapter_report_open:
		game._close_chapter_report(false)
	game.save_path = PROBE_SAVE_PATH
	# Auto-saving stays off; explicit diagnostic checkpoints use an isolated slot.
	next_maintenance = elapsed_seconds
	next_production = elapsed_seconds
	next_expansion = elapsed_seconds
	if resumed_online_prefix:
		# Preserve the original 23m05.5s review phase across a budget split.
		next_maintenance = 1385.5 + ceil((elapsed_seconds - 1385.5) / 300.0) * 300.0
		next_production = 1385.5 + ceil((elapsed_seconds - 1385.5) / 1200.0) * 1200.0
		next_expansion = next_production
	print("MANAGED_SESSION_POLICY ", JSON.stringify({
		"base_route": "real victory plus post-clear frontier management" if after_victory else "intact opening plus real supply/expansion",
		"managed_origin_seconds": managed_origin_seconds,
		"first_online_h": 2, "later_visits_h": LONG_CHECKPOINTS,
		"visit_seconds": VISIT_SECONDS, "maintenance_seconds": 300,
		"dna_review_seconds": 1200, "dna_batch_max": dna_queue_limit,
		"organic_reserve": reserve_organic, "mineral_reserve": reserve_mineral,
		"offline_income_cap_h": game.OFFLINE_CAP_SECONDS / 3600.0,
		"offline_ecology_cap_h_per_absence": game.OFFLINE_ECOLOGY_CAP_SECONDS / 3600.0,
		"offline_core_biomass_floor_fraction": 0.1
	}))
	while elapsed_seconds < managed_origin_seconds + 7200.0 and not failed:
		_online_step()
	if failed:
		return false
	_snapshot("2h_online" if is_zero_approx(offline_seconds) else "2h_mixed_after_resume")
	_checkpoint()
	for hour in LONG_CHECKPOINTS:
		if not _budget_ok():
			return false
		var target := managed_origin_seconds + float(hour) * 3600.0
		_maintenance(true)
		_disable_auto_before_absence()
		if not _settle_to_checkpoint(target, hour, "%dh_arrival" % int(hour)):
			return false
		if hour < 72.0:
			_maintenance(true)
			var visit_end := elapsed_seconds + VISIT_SECONDS
			while elapsed_seconds < visit_end and not failed:
				_online_step()
			if failed:
				return false
			_snapshot("%dh_after_visit" % int(hour))
	print("MANAGED_LONG_SESSION_RESULT ", JSON.stringify({
		"status": "completed_observation", "snapshots": snapshots,
		"observed_deaths": observed_deaths, "actions": actions,
		"repair_purchases": repair_purchases, "dna_batches": dna_batches,
		"resumed_online_prefix_seconds": resumed_prefix_seconds,
		"postclear_mode": postclear_mode, "managed_origin_seconds": managed_origin_seconds,
		"action_counts_scope": "this diagnostic process; see previous log for online-prefix commands" if resumed_online_prefix else "entire route",
		"online_seconds": online_seconds, "offline_seconds": offline_seconds,
		"elapsed_seconds": elapsed_seconds, "wall_ms": Time.get_ticks_msec() - probe_started_ms,
		"whole_chapter_complete": game.chapter_complete,
		"limitation": "One seeded scripted mixed-mode route; not 72h fully online or proof of balance"
	}))
	print("CHAPTER1_MANAGED_LONG_SESSION_OK observed_h=72 mixed_online_offline=true normal_prices=true")
	return true


func _settle_to_checkpoint(target: float, hour: float, label: String) -> bool:
	var absence := maxf(0.0, target - elapsed_seconds)
	var before: Dictionary = _state()
	var start_ms := Time.get_ticks_msec()
	if not game._begin_offline_progress(absence, absence, false):
		return _check(false, "scheduled absence can enter the real offline settler")
	while game.offline_settlement_active:
		if not _budget_ok():
			return false
		game._advance_offline_progress_step()
	elapsed_seconds += absence
	offline_seconds += absence
	_observe_deaths()
	if not _validate_world():
		return false
	var session := {"target_h": hour, "absence_seconds": absence, "full_offline_report": game.offline_report.duplicate(true), "before": before, "after": _state(), "runtime_ms": Time.get_ticks_msec() - start_ms}
	sessions.append(session)
	print("MANAGED_OFFLINE_SESSION ", JSON.stringify(session))
	game._close_offline_report()
	_snapshot(label)
	_checkpoint()
	return true


func _tick() -> void:
	if managed:
		_online_step()
	else:
		super._tick()


func _online_step() -> void:
	if failed or not _budget_ok():
		return
	if elapsed_seconds >= next_maintenance:
		next_maintenance = elapsed_seconds + maintenance_period
		_maintenance(false)
	if short_frontier_mode:
		_advance_short_construction()
	var prior_world := float(game.sim_time)
	game._process(STEP_SECONDS)
	if not _check(is_equal_approx(float(game.sim_time) - prior_world, STEP_SECONDS), "each reported online step must advance the actual game clock, not a paused modal"):
		return
	elapsed_seconds += STEP_SECONDS
	online_seconds += STEP_SECONDS
	_observe_deaths()
	_validate_world()


func _advance_short_construction() -> void:
	if elapsed_seconds >= construction_until:
		if not construction_orders_refreshed:
			construction_orders_refreshed = true
			_configure_postclear_orders()
		return
	if elapsed_seconds < next_construction_check:
		return
	next_construction_check = elapsed_seconds + 1.0
	if pending_construction_segment >= 0 and float(game.segments[pending_construction_segment]["growth"]) < 1.0:
		return
	var previous_count: int = game.segments.size()
	_try_fixed_frontier_extension()
	if game.segments.size() > previous_count:
		pending_construction_segment = game.segments.size() - 1
	else:
		# No affordable/legal command is not a reason to rescan each frame.
		next_construction_check = elapsed_seconds + 30.0


func _prepare_short_frontier() -> bool:
	if not _check(game._is_core_alive(fixed_frontier_core) and game._is_world_explored(fixed_frontier_target), "the archived route has a real live core and an already explored target cluster"):
		return false
	var known_organic := 0.0
	var known_count := 0
	for resource in game.resources:
		if bool(resource.get("alive", false)) and int(resource["kind"]) == 0 and game._is_world_explored(resource["pos"]) and (resource["pos"] as Vector2).distance_to(fixed_frontier_target) <= 180.0:
			known_organic += float(resource["amount"])
			known_count += 1
	if not _check(known_organic >= 300.0, "the chosen visible cluster has substantial real remaining nutrients"):
		return false
	for level in range(int(game.structure_levels.get("branching", 0)), 4):
		var before := _balances()
		game._purchase_structure("branching")
		_record_spend(before)
		if not _check(int(game.structure_levels.get("branching", 0)) == level + 1, "branching upgrade is bought normally, without level injection"):
			return false
		_action("paid_branching_upgrade", {"level": level + 1, "before": before, "after": _balances()})
	var source: Vector2 = game._best_source(fixed_frontier_core, fixed_frontier_target)
	var distance := source.distance_to(fixed_frontier_target)
	var remaining: float = game._hypha_capacity_for_core(fixed_frontier_core) - game._core_hypha_length(fixed_frontier_core)
	var unplanned := distance
	var cost := 0
	var segments_needed := 0
	while unplanned > 0.0005:
		var length: float = minf(unplanned, game._max_segment_length())
		cost += ceili(length / game.ORGANIC_PER_LENGTH)
		segments_needed += 1
		unplanned -= length
	if not _check(remaining >= distance and game.organic >= float(cost) + 10.0, "real upgraded capacity and existing balance cover the complete bridge plus a ten-organic repair buffer"):
		return false
	construction_until = elapsed_seconds + 600.0
	_action("fixed_bridge_plan", {"core": fixed_frontier_core, "source": _xy(source), "target": _xy(fixed_frontier_target), "distance": distance, "remaining_capacity": remaining, "planned_segments": segments_needed, "planned_organic": cost, "known_cluster_organic": known_organic, "known_cluster_count": known_count, "construction_budget_seconds": 600.0})
	return true


func _try_fixed_frontier_extension() -> void:
	if not _check(game._is_core_alive(fixed_frontier_core), "the selected bridge core remains alive during actual construction"):
		return
	var source: Vector2 = game._best_source(fixed_frontier_core, fixed_frontier_target)
	if source.distance_to(fixed_frontier_target) < game.MIN_SEGMENT_LENGTH:
		construction_until = elapsed_seconds
		_action("fixed_bridge_connected", {"core": fixed_frontier_core, "position": _xy(source)})
		return
	game.selected_core = fixed_frontier_core
	game.selected_tip_valid = false
	game._apply_menu_action("extend_core")
	var before := _balances()
	var previous_count: int = game.segments.size()
	game._confirm_extension(fixed_frontier_target)
	_record_spend(before)
	if not _check(game.segments.size() == previous_count + 1, "the planned bridge extends using the normal payment and growth path"):
		return
	var segment: Dictionary = game.segments.back()
	_action("fixed_bridge_extension", {"core": fixed_frontier_core, "a": _xy(segment["a"]), "b": _xy(segment["b"]), "cost": float(before["organic"]) - float(game.organic), "initial_growth": float(segment["growth"])})


func _maintenance(force: bool) -> void:
	if game.chapter_report_open:
		game._close_chapter_report(false)
	var before := _balances()
	_claim_completed_goals()
	if postclear_mode:
		_service_scout_and_auto()
		_service_scout_orders()
	for core_id in range(game.cores.size()):
		if not game._is_core_alive(core_id):
			continue
		var core: Dictionary = game.cores[core_id]
		var maximum := float(core["max_biomass"])
		var missing := maximum - float(core["biomass"]) - float(core.get("repair_reserve", 0.0))
		if missing >= 5.0 and game.organic >= game.CORE_REPAIR_ORGANIC_COST:
			var prior := _balances()
			game._repair_core(core_id)
			_record_spend(prior)
			repair_purchases += 1
			_action("repair", {"core": core_id, "biomass_before": float(core["biomass"]), "reserve_after": float(core["repair_reserve"])})
	# Only buy actual priced protection when existing damage/pressure warrants it.
	var pressure := false
	var wounded := false
	for core in game.cores:
		if bool(core.get("alive", true)):
			pressure = pressure or float(core.get("toxin_pressure", 0.0)) > 0.0
			wounded = wounded or float(core["biomass"]) < float(core["max_biomass"]) * 0.7
	for upgrade_id in ["detox", "repair", "wall"]:
		var desired_level := 2 if upgrade_id == "detox" else 1
		var needed := pressure if upgrade_id == "detox" else wounded
		if needed and int(game.survival_levels[upgrade_id]) < desired_level and game.dna >= game._survival_cost(upgrade_id):
			var prior := _balances()
			game._purchase_survival(upgrade_id)
			_record_spend(prior)
			_action("survival_upgrade", {"id": upgrade_id, "level": game.survival_levels[upgrade_id]})
	if force or elapsed_seconds >= next_expansion:
		if not short_frontier_mode:
			_try_extension()
		_reassign_known_harvest()
		next_expansion = elapsed_seconds + expansion_period
	if force or elapsed_seconds >= next_production:
		# Fund one bounded queue only after protecting the strategy's capital.
		for core_id in range(game.cores.size()):
			var core: Dictionary = game.cores[core_id]
			if not game._is_core_alive(core_id) or String(core.get("kind", "normal")) != "normal":
				continue
			var jobs: Array = core["jobs"]
			var amount := mini(dna_queue_limit - jobs.size(), mini(floori((game.organic - reserve_organic) / game.DNA_ORGANIC_COST), floori((game.mineral - reserve_mineral) / game.DNA_MINERAL_COST)))
			if amount > 0:
				_queue_dna(core_id, amount)
				dna_batches += 1
				_action("dna_batch", {"core": core_id, "count": amount, "queue": jobs.size()})
				break
		next_production = elapsed_seconds + 1200.0
	_action("visit", {"balance_before": before, "balance_after": _balances()})


func _try_extension() -> void:
	if postclear_mode:
		_try_frontier_extension()
		return
	if game.organic < 170.0:
		return
	var best_core := -1
	var best_target := Vector2.INF
	var best_score := -INF
	for core_id in range(game.cores.size()):
		if not game._is_core_alive(core_id) or game._hypha_capacity_for_core(core_id) - game._core_hypha_length(core_id) < game.MIN_SEGMENT_LENGTH:
			continue
		for resource in game.resources:
			if not bool(resource.get("alive", false)) or not game._is_world_explored(resource["pos"]):
				continue
			var target: Vector2 = resource["pos"]
			var source: Vector2 = game._best_source(core_id, target)
			var distance := source.distance_to(target)
			if distance < 80.0 or distance > game._max_segment_length() + 80.0:
				continue
			var score := float(resource["amount"]) / (1.0 + distance / 100.0)
			if score > best_score:
				best_score = score
				best_core = core_id
				best_target = target
	if best_core < 0:
		_action("extension_unavailable", {"reason": "no affordable reachable explored target or remaining capacity"})
		return
	var previous_count: int = game.segments.size()
	game.selected_core = best_core
	game.selected_tip_valid = false
	game._apply_menu_action("extend_core")
	var before := _balances()
	game._confirm_extension(best_target)
	_record_spend(before)
	if game.segments.size() > previous_count:
		var segment: Dictionary = game.segments.back()
		_action("extension", {"core": best_core, "a": _xy(segment["a"]), "b": _xy(segment["b"]), "cost": float(before["organic"]) - float(game.organic)})


func _reassign_known_harvest() -> void:
	if postclear_mode:
		_configure_postclear_orders()
		return
	for unit in game.expedition_units:
		if not game._unit_can_harvest(unit):
			continue
		var resource: Dictionary = game._nearest_resource_kind(unit["pos"], game.EXPEDITION_SEARCH_RADIUS, game._harvest_resource_kind(unit))
		if resource.is_empty():
			continue
		var point: Vector2 = resource["pos"]
		var zone := Rect2(point - Vector2.ONE * 75.0, Vector2.ONE * 150.0)
		if not game._defense_zone_within_operating_range(zone, unit):
			continue
		game.selected_expedition_ids = [int(unit["id"])]
		var assigned: int = game._assign_harvest_zone(zone.position, zone.end)
		if assigned > 0:
			_action("harvest_zone", {"unit": unit["id"], "center": _xy(point)})


func _observe_deaths() -> void:
	for core_id in range(game.cores.size()):
		if not game._is_core_alive(core_id) and not seen_dead_cores.has(core_id):
			seen_dead_cores[core_id] = true
			var event := {"at_seconds": elapsed_seconds, "core": core_id, "kind": game.cores[core_id].get("kind", "normal")}
			observed_deaths.append(event)
			print("MANAGED_CORE_LOSS ", JSON.stringify(event))


func _validate_world() -> bool:
	if not _check(not game.developer_mode_enabled and not game.game_over and is_finite(game.organic) and game.organic >= -0.000001 and is_finite(game.mineral) and game.mineral >= -0.000001 and game.dna >= 0, "managed route stays alive with normal finite nonnegative balances"):
		return false
	return true


func _state() -> Dictionary:
	var health: Array = []
	for core_id in range(game.cores.size()):
		var core: Dictionary = game.cores[core_id]
		health.append({"id": core_id, "kind": core.get("kind", "normal"), "alive": game._is_core_alive(core_id), "biomass": snappedf(float(core["biomass"]), 0.001), "reserve": snappedf(float(core.get("repair_reserve", 0.0)), 0.001), "queue": (core["jobs"] as Array).size()})
	return {
		"elapsed_seconds": elapsed_seconds, "world_seconds": game.sim_time,
		"managed_seconds": elapsed_seconds - managed_origin_seconds, "postclear_mode": postclear_mode,
		"online_seconds": online_seconds, "offline_seconds": offline_seconds,
		"organic": snappedf(game.organic, 0.001), "mineral": snappedf(game.mineral, 0.001), "dna": game.dna,
		"dna_produced": game.lifetime_dna_produced, "paid_dna": queued_dna,
		"absorbed_organic": snappedf(game.lifetime_organic_absorbed, 0.001), "absorbed_mineral": snappedf(game.lifetime_mineral_absorbed, 0.001),
		"returned_organic": snappedf(game.lifetime_expedition_organic_returned, 0.001), "returned_mineral": snappedf(game.lifetime_expedition_mineral_returned, 0.001),
		"living_cores": game._living_core_count(), "living_hypha": snappedf(game._chapter_living_hypha_length(), 0.001),
		"cores": health, "units": game.expedition_units.size(), "units_lost": game.lifetime_expedition_units_lost,
		"units_repaired": game.lifetime_expedition_units_repaired,
		"units_built": game.lifetime_expedition_units_built,
		"explored_cells": game.explored_cells.size(), "explored_fraction": game._explored_fraction(),
		"incursions_defeated": game.lifetime_fungal_incursions_defeated, "incursion": game.fungal_incursion.duplicate(true),
		"bacteria": game.bacteria.size(), "rivals_defeated": game.lifetime_enemy_fungi_defeated,
		"chapter_complete": game.chapter_complete, "chapter_index": game.chapter_task_index,
		"survival_levels": game.survival_levels.duplicate(true),
		"structure_levels": game.structure_levels.duplicate(true), "scout_levels": game.scout_upgrade_levels.duplicate(true),
		"wall_ms": Time.get_ticks_msec() - probe_started_ms
	}


func _snapshot(label: String) -> void:
	if not managed:
		super._snapshot(label)
		return
	var snapshot := _state()
	snapshot["label"] = label
	snapshots.append(snapshot)
	print("MANAGED_LONG_SNAPSHOT ", JSON.stringify(snapshot))


func _checkpoint() -> void:
	_check(game._save_game(), "write the genuine isolated diagnostic checkpoint")


func _action(kind: String, data: Dictionary) -> void:
	data["at_seconds"] = elapsed_seconds
	data["kind"] = kind
	actions.append(data)
	print("MANAGED_ACTION ", JSON.stringify(data))


func _xy(point: Vector2) -> Array:
	return [point.x, point.y]


func _budget_ok() -> bool:
	if Time.get_ticks_msec() - probe_started_ms < WALL_BUDGET_MS:
		return true
	_snapshot("wall_budget_stop")
	_checkpoint()
	return _check(false, "diagnostic wall-clock budget reached; partial observations and isolated checkpoint retained")


func _claim_completed_goals() -> void:
	if not managed or not postclear_mode:
		super._claim_completed_goals()
		return
	for goal in game._goal_definitions():
		var goal_id := String(goal["id"])
		if bool(game.goals_claimed.get(goal_id, false)) or not game._goal_complete(goal_id):
			continue
		var before := _balances()
		game._claim_goal(goal_id)
		rewards["organic"] += float(game.organic) - float(before["organic"])
		rewards["mineral"] += float(game.mineral) - float(before["mineral"])
		rewards["dna"] += int(game.dna) - int(before["dna"])
		_action("claim_completed_goal", {"goal_id": goal_id, "before": before, "after": _balances()})


func _service_scout_and_auto() -> void:
	var barracks_id := -1
	for core_id in range(game.cores.size() - 1, -1, -1):
		if game._is_core_alive(core_id) and String(game.cores[core_id].get("kind", "normal")) == "barracks":
			barracks_id = core_id
			break
	if barracks_id < 0:
		return
	if not bool(game.barracks_unit_unlocks.get("scout", false)) and game.dna >= 5:
		var before := _balances()
		game._purchase_barracks_unit("scout")
		_record_spend(before)
		_action("scout_unlock", {"dna_cost": int(before["dna"]) - int(game.dna)})
	var scout_count := 0
	for core_id in range(game.cores.size()):
		scout_count += game._barracks_unit_count(core_id, "scout", true)
	if scout_count == 0 and bool(game.barracks_unit_unlocks.get("scout", false)) and game.organic >= 120.0 and game.mineral >= 6.4:
		var before := _balances()
		if game._queue_expedition_spores(barracks_id, "scout", 1, false):
			_record_spend(before)
			_action("scout_order", {"barracks": barracks_id, "before": before, "after": _balances()})
	for core_id in range(game.cores.size()):
		var core: Dictionary = game.cores[core_id]
		if not game._is_core_alive(core_id) or String(core.get("kind", "normal")) != "barracks":
			continue
		# Cycle only through existing menu options, never invent a target of two.
		for _attempt in range(4):
			if String(core.get("production_unit", "forager")) == "forager":
				break
			game._cycle_barracks_unit(core_id)
		for _attempt in range(3):
			if int(core.get("auto_replenish_target", 4)) == 4:
				break
			game._cycle_barracks_auto_target(core_id)
		var desired: bool = game.organic >= reserve_organic and game.mineral >= reserve_mineral
		if bool(core.get("auto_replenish", false)) != desired:
			var before := _balances()
			game._toggle_barracks_auto(core_id)
			_record_spend(before)
			_action("auto_replenishment", {"core": core_id, "enabled": desired, "target": 4})


func _service_scout_orders() -> void:
	for unit in game.expedition_units:
		if String(unit.get("unit_type", "forager")) != "scout":
			continue
		game.selected_expedition_ids = [int(unit["id"])]
		if game._unit_is_manual_hold(unit):
			game._clear_selected_persistent_orders()
			_action("scout_resume_auto", {"unit": int(unit["id"])})
		if String(unit.get("state", "idle")) != "idle" or game._nearest_unexplored_scout_target(unit["pos"]).is_finite():
			continue
		# Read fog coverage, not hidden resources. A player can order the scout
		# toward a different reachable black area after the old local search ends.
		var target := Vector2.INF
		var best_score := INF
		for cell_y in range(game.EXPLORATION_GRID_SIDE):
			for cell_x in range(game.EXPLORATION_GRID_SIDE):
				var cell := Vector2i(cell_x, cell_y)
				if game.explored_cells.has(game._exploration_key(cell)):
					continue
				var point: Vector2 = game._exploration_cell_center(cell)
				if point.length() > game.WORLD_HALF or game._distance_to_colony(point) > game.SCOUT_OPERATING_RADIUS:
					continue
				var score: float = point.distance_squared_to(unit["pos"])
				if score < best_score:
					best_score = score
					target = point
		if target.is_finite():
			var before: Vector2 = unit["pos"]
			game._issue_expedition_command(game.world_to_screen(target))
			_action("scout_reposition", {"unit": int(unit["id"]), "from": _xy(before), "target": _xy(unit["target_pos"]), "state": unit["state"]})
	game.selected_expedition_ids = []


func _disable_auto_before_absence() -> void:
	if not postclear_mode:
		return
	for core_id in range(game.cores.size()):
		var core: Dictionary = game.cores[core_id]
		if game._is_core_alive(core_id) and String(core.get("kind", "normal")) == "barracks" and bool(core.get("auto_replenish", false)):
			game._toggle_barracks_auto(core_id)
			_action("auto_paused_for_absence", {"core": core_id})


func _configure_postclear_orders() -> void:
	for core_id in range(game.cores.size()):
		var core: Dictionary = game.cores[core_id]
		if not game._is_core_alive(core_id) or String(core.get("kind", "normal")) != "barracks":
			continue
		# Keep the forward assault army guarding its real base; rear forces gather.
		if core_id == forward_barracks_id:
			var center: Vector2 = core["pos"]
			var assigned: int = game._assign_barracks_directive(core_id, "defense", center - Vector2.ONE * 150.0, center + Vector2.ONE * 150.0)
			_action("forward_defense", {"core": core_id, "assigned": assigned})
			continue
		var best: Dictionary = {}
		var best_score := -INF
		for resource in game.resources:
			if not bool(resource.get("alive", false)) or int(resource["kind"]) != 0 or not game._is_world_explored(resource["pos"]):
				continue
			var point: Vector2 = resource["pos"]
			var zone := Rect2(point - Vector2.ONE * 100.0, Vector2.ONE * 200.0)
			if not game._defense_zone_within_operating_range(zone, {"unit_type": "forager"}):
				continue
			var score := float(resource["amount"]) / (1.0 + point.distance_to(core["pos"]) / 600.0)
			if score > best_score:
				best_score = score
				best = resource
		if not best.is_empty():
			var center: Vector2 = best["pos"]
			var assigned: int = game._assign_barracks_directive(core_id, "harvest", center - Vector2.ONE * 100.0, center + Vector2.ONE * 100.0)
			_action("barracks_harvest", {"core": core_id, "center": _xy(center), "assigned": assigned})


func _try_frontier_extension() -> void:
	# DNA reserves are capital available for expansion, not a ban on spending it.
	if game.organic < 40.0 + 1.0:
		return
	var candidates: Array = []
	for core_id in range(game.cores.size()):
		if not game._is_core_alive(core_id):
			continue
		var remaining: float = game._hypha_capacity_for_core(core_id) - game._core_hypha_length(core_id)
		var needs_core: bool = remaining < game.MIN_SEGMENT_LENGTH
		if needs_core and (game._living_core_count() >= 8 or game.mineral < game.CORE_MINERAL_COST + 12.0):
			continue
		for resource in game.resources:
			if not bool(resource.get("alive", false)) or not game._is_world_explored(resource["pos"]):
				continue
			var point: Vector2 = resource["pos"]
			var source: Vector2 = game._best_source(core_id, point)
			var distance := source.distance_to(point)
			if distance < 100.0 or distance > 1600.0:
				continue
			var tip: Dictionary = {}
			if needs_core:
				var too_close := false
				for core in game.cores:
					too_close = too_close or source.distance_to(core["pos"]) < 70.0
				if too_close:
					continue
				tip = game._tip_at(game.world_to_screen(source))
				if tip.is_empty():
					continue
			var length: float = minf(distance, game._max_segment_length())
			if not needs_core:
				length = minf(length, remaining)
			var cost: float = ceil(length / game.ORGANIC_PER_LENGTH) + (game.CORE_ORGANIC_COST if needs_core else 0.0)
			if game.organic < cost + 40.0:
				continue
			var score := float(resource["amount"]) / (1.0 + distance / 400.0)
			if int(resource["kind"]) == 0:
				score *= 1.5
			candidates.append({"core": core_id, "target": point, "needs_core": needs_core, "tip": tip, "score": score})
	if candidates.is_empty():
		_action("frontier_search_empty", {"reason": "no suitable explored target in this bounded strategy search"})
		return
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
	for candidate in candidates:
		var core_id := int(candidate["core"])
		if bool(candidate["needs_core"]):
			var tip: Dictionary = candidate["tip"]
			game.selected_tip = tip["pos"]
			game.selected_tip_core = int(tip["core_id"])
			game.selected_tip_valid = true
			var before := _balances()
			var previous_count: int = game.cores.size()
			game._create_secondary_core()
			_record_spend(before)
			if game.cores.size() <= previous_count:
				continue
			core_id = game.cores.size() - 1
			_action("frontier_core", {"core": core_id, "position": _xy(game.cores[core_id]["pos"]), "before": before, "after": _balances()})
		game.selected_core = core_id
		game.selected_tip_valid = false
		game._apply_menu_action("extend_core")
		var before := _balances()
		var previous_count: int = game.segments.size()
		game._confirm_extension(candidate["target"])
		_record_spend(before)
		if game.segments.size() > previous_count:
			var segment: Dictionary = game.segments.back()
			_action("frontier_extension", {"core": core_id, "a": _xy(segment["a"]), "b": _xy(segment["b"]), "cost": float(before["organic"]) - float(game.organic)})
			return
