extends SceneTree


# Scripted normal-mode route, not a forecast of human onboarding time.
# Commands use the normal factories and payment paths; the seeded map is intact.
const STEP_SECONDS := 0.25
const OPENING_SECONDS := 20.0 * 60.0
const STARTING_ORGANIC := 220.0
const STARTING_MINERAL := 24.0
const CLAIMABLE_GOALS := [
	"first_hypha", "mineral_trace", "second_core", "primary_diet",
	"bacterial_bloom", "first_bacterium", "bacteria_control", "ecology_response"
]

var game: Node
var elapsed_seconds := 0.0
var milestones := {}
var spent := {"organic": 0.0, "mineral": 0.0, "dna": 0}
var rewards := {"organic": 0.0, "mineral": 0.0, "dna": 0}
var queued_dna := 0
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var started_ms := Time.get_ticks_msec()
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.developer_mode_enabled = false
	game.autosave_enabled = false
	game.splash_active = false
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	game.sim_speed = 1.0
	if not _check(game._founder_spore_active() and game.cores.is_empty() and is_equal_approx(game.organic, STARTING_ORGANIC) and is_equal_approx(game.mineral, STARTING_MINERAL) and game.dna == 0, "use the real new-game resources and mobile founder"):
		return
	var initial_resource_count: int = game.resources.size()
	var initial_bacteria_count: int = game.bacteria.size()
	if not _check(initial_resource_count > 1000 and initial_bacteria_count > 0 and game._is_world_explored(Vector2(360.0, -90.0)) and game._is_world_explored(Vector2(-300.0, 320.0)), "keep the seeded world, competitors, and initially visible resource clusters"):
		return

	# Both clusters are visible from the initial 620-unit founder reveal radius.
	# Settle outside the dense bacterial patch, then reach it with paid hyphae.
	if not _check(game._issue_founder_spore_move(Vector2(100.0, -90.0)), "the founder accepts the nearby settlement destination"):
		return
	while String(game.founder_spore.get("state", "")) == "moving" and elapsed_seconds < 30.0:
		_tick()
	if not _check((game.founder_spore["pos"] as Vector2).is_equal_approx(Vector2(100.0, -90.0)), "the founder reaches the site by swimming, without teleportation"):
		return
	if not _check(game._begin_founder_spore_germination(), "normal germination can begin"):
		return
	while game._founder_spore_active() and elapsed_seconds < 40.0:
		_tick()
	if not _check(game.cores.size() == 1 and not game.enemy_fungi.is_empty(), "germination creates a core and retains the real rival colony"):
		return
	milestones["settled"] = elapsed_seconds
	game._handle_left_click(game.world_to_screen(game.cores[0]["pos"]))
	if not _check(game.core_selected_once, "normal core selection advances the first chapter objective"):
		return

	_extend(0, Vector2(360.0, -90.0))
	milestones["first_hypha"] = elapsed_seconds
	_claim_completed_goals()
	_queue_dna(0, 2)
	var second_core_segment := _extend(0, Vector2(-125.0, 60.0))
	_wait_for_segment(second_core_segment)
	var second_core_id := _build_at_tip(second_core_segment, false)
	if failed:
		return
	milestones["second_core"] = elapsed_seconds
	_claim_completed_goals()
	_queue_dna(second_core_id, 2)
	var mineral_bridge := _extend(second_core_id, Vector2(-300.0, 320.0))
	_wait_for_segment(mineral_bridge)
	_extend(second_core_id, Vector2(-300.0, 320.0))
	var barracks_segment := _extend(0, Vector2(100.0, -330.0))
	var barracks_id := -1
	var unit_queued := false

	# A modest scripted plan: check goals and prerequisites every five seconds.
	# No free upgrades, injected entities, forced damage, or disabled enemies.
	while elapsed_seconds < OPENING_SECONDS and not failed:
		if fmod(elapsed_seconds, 5.0) < STEP_SECONDS:
			_claim_completed_goals()
			if game.diet_order.is_empty() and game.dna >= game._diet_unlock_cost():
				var before := _balances()
				game._purchase_diet("bacteria")
				_record_spend(before)
				if not _check(int(game.diet_levels["bacteria"]) == 1, "the first diet uses the real shop purchase"):
					return
				milestones["primary_diet"] = elapsed_seconds
				_claim_completed_goals()
			if barracks_id < 0 and not game.diet_order.is_empty() and game.organic >= game.BARRACKS_ORGANIC_COST and game.mineral >= game.BARRACKS_MINERAL_COST and game.dna >= game.BARRACKS_DNA_COST:
				barracks_id = _build_at_tip(barracks_segment, true)
				if failed:
					return
				milestones["barracks"] = elapsed_seconds
			if barracks_id >= 0 and not unit_queued and game.organic >= game.EXPEDITION_SPORE_ORGANIC_COST and game.mineral >= game.EXPEDITION_SPORE_MINERAL_COST:
				var before := _balances()
				unit_queued = game._queue_expedition_spores(barracks_id, "forager", 1, false)
				_record_spend(before)
				if not _check(unit_queued, "a normal barracks order pays for the first forager"):
					return
		_tick()
	if failed:
		return
	_claim_completed_goals()

	for milestone in ["settled", "first_hypha", "organic_absorbed", "mineral_absorbed", "first_dna", "second_core", "primary_diet", "barracks", "first_unit"]:
		if not _check(milestones.has(milestone) and float(milestones[milestone]) <= OPENING_SECONDS, "%s is reachable inside this scripted twenty-minute route" % milestone):
			return
	if not _check(not game.developer_mode_enabled and game.resources.size() == initial_resource_count and game.bacteria.size() > 0 and not game.enemy_fungi.is_empty(), "the complete route keeps normal mode and the original living world"):
		return
	if not _check(queued_dna == 4 and game.lifetime_dna_produced == 4, "exactly the four paid DNA jobs finish; no automatic DNA is invented"):
		return
	if not _check(game._living_core_count() == 3 and not game.game_over, "all three reasonably placed cores survive the opening"):
		return
	if not _check(absf(game.organic - (STARTING_ORGANIC + game.lifetime_organic_absorbed + game.lifetime_expedition_organic_returned + float(rewards["organic"]) - float(spent["organic"]))) < 0.001, "organic balance equals actual absorption, cargo and claimed rewards minus paid orders"):
		return
	if not _check(absf(game.mineral - (STARTING_MINERAL + game.lifetime_mineral_absorbed + game.lifetime_expedition_mineral_returned + float(rewards["mineral"]) - float(spent["mineral"]))) < 0.001, "mineral balance equals actual absorption, cargo and claimed rewards minus paid orders"):
		return
	if not _check(game.dna == game.lifetime_dna_produced + int(rewards["dna"]) - int(spent["dna"]), "DNA balance equals completed prepaid jobs and legitimate rewards minus purchases"):
		return
	for resource in game.resources:
		if not _check(float(resource["amount"]) >= 0.0 and float(resource["amount"]) <= float(resource["initial_amount"]) + 0.000001, "the route never replenishes or overdraws a map deposit"):
			return
	var health: Array = []
	for core in game.cores:
		health.append(snappedf(float(core["biomass"]), 0.001))
	var snapshot := {
		"elapsed_seconds": elapsed_seconds, "simulation_seconds": game.sim_time,
		"organic": snappedf(game.organic, 0.001), "mineral": snappedf(game.mineral, 0.001), "dna": game.dna,
		"absorbed_organic": snappedf(game.lifetime_organic_absorbed, 0.001), "absorbed_mineral": snappedf(game.lifetime_mineral_absorbed, 0.001),
		"dna_produced": game.lifetime_dna_produced, "unit_count": game.expedition_units.size(),
		"bacteria_initial": initial_bacteria_count, "bacteria_final": game.bacteria.size(),
		"bacteria_consumed": game.lifetime_bacteria_consumed, "ecology_events_seen": game.lifetime_ecology_events_seen,
		"core_biomass": health, "hypha_length": snappedf(game._total_hypha_length(), 0.001),
		"paid": spent, "claimed_rewards": rewards, "goals_claimed": game.goals_claimed.keys(), "milestones_seconds": milestones
	}
	print("CHAPTER1_OPENING_SNAPSHOT ", JSON.stringify(snapshot))
	print("CHAPTER1_OPENING_PROGRESSION_OK normal_mode=true scripted_seconds=1200 prepaid_dna=4 runtime_ms=", Time.get_ticks_msec() - started_ms)
	game.queue_free()
	quit(0)


func _tick() -> void:
	if failed:
		return
	game._process(STEP_SECONDS)
	elapsed_seconds += STEP_SECONDS
	if game.lifetime_organic_absorbed > 0.0 and not milestones.has("organic_absorbed"):
		milestones["organic_absorbed"] = elapsed_seconds
	if game.lifetime_mineral_absorbed > 0.0 and not milestones.has("mineral_absorbed"):
		milestones["mineral_absorbed"] = elapsed_seconds
	if game.lifetime_dna_produced > 0 and not milestones.has("first_dna"):
		milestones["first_dna"] = elapsed_seconds
	if game.lifetime_expedition_units_built > 0 and not milestones.has("first_unit"):
		milestones["first_unit"] = elapsed_seconds
	_check(not game.game_over and is_finite(game.organic) and game.organic >= -0.000001 and is_finite(game.mineral) and game.mineral >= -0.000001 and game.dna >= 0, "normal simulation remains alive with finite, nonnegative balances")


func _balances() -> Dictionary:
	return {"organic": float(game.organic), "mineral": float(game.mineral), "dna": int(game.dna)}


func _record_spend(before: Dictionary) -> void:
	spent["organic"] += float(before["organic"]) - float(game.organic)
	spent["mineral"] += float(before["mineral"]) - float(game.mineral)
	spent["dna"] += int(before["dna"]) - int(game.dna)


func _extend(core_id: int, target: Vector2) -> int:
	game.selected_core = core_id
	game.selected_tip_valid = false
	game._apply_menu_action("extend_core")
	var before := _balances()
	var previous_count: int = game.segments.size()
	game._confirm_extension(target)
	_record_spend(before)
	_check(game.segments.size() == previous_count + 1, "a paid, length-limited hypha extension succeeds")
	return game.segments.size() - 1


func _wait_for_segment(segment_id: int) -> void:
	var deadline := elapsed_seconds + 40.0
	while not failed and float(game.segments[segment_id]["growth"]) < 1.0 and elapsed_seconds < deadline:
		_tick()
	_check(float(game.segments[segment_id]["growth"]) >= 1.0, "new hyphae mature through elapsed normal simulation")


func _build_at_tip(segment_id: int, barracks: bool) -> int:
	var tip: Dictionary = game._tip_at(game.world_to_screen(game.segments[segment_id]["b"]))
	if not _check(not tip.is_empty(), "building requires a real mature selectable tip"):
		return -1
	game.selected_tip = tip["pos"]
	game.selected_tip_core = int(tip["core_id"])
	game.selected_tip_valid = true
	var before := _balances()
	var previous_count: int = game.cores.size()
	if barracks:
		game._create_barracks_core()
	else:
		game._create_secondary_core()
	_record_spend(before)
	_check(game.cores.size() == previous_count + 1, "building uses normal placement and resource prerequisites")
	return game.cores.size() - 1


func _queue_dna(core_id: int, count: int) -> void:
	var before := _balances()
	if _check(game._queue_dna(core_id, count), "normal nutrient balances can prepay the intended DNA batch"):
		queued_dna += count
	_record_spend(before)


func _claim_completed_goals() -> void:
	for goal_id in CLAIMABLE_GOALS:
		if not bool(game.goals_claimed.get(goal_id, false)) and game._goal_complete(goal_id):
			var before := _balances()
			game._claim_goal(goal_id)
			rewards["organic"] += float(game.organic) - float(before["organic"])
			rewards["mineral"] += float(game.mineral) - float(before["mineral"])
			rewards["dna"] += int(game.dna) - int(before["dna"])


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	failed = true
	push_error("CHAPTER1_OPENING_PROGRESSION_FAIL at %.2fs: %s" % [elapsed_seconds, message])
	quit(1)
	return false
