extends "res://tests/chapter1_opening_progression_smoke.gd"


# A real paid route following the inherited, intact twenty-minute opening.
# No resource/entity fixture, developer resources, teleport, or offline shortcut.
const FOLLOWUP_DEADLINE_SECONDS := 45.0 * 60.0
const HARVEST_MIN := Vector2(245.0, -205.0)
const HARVEST_MAX := Vector2(475.0, 25.0)

var following_up := false
var followup_started_ms := 0
var followed_unit_id := -1
var previous_returned := 0.0
var followup_deposits: Array = []
var paid_extensions: Array = []
var supply_reached_at := -1.0
var expansion_reached_at := -1.0
var minimum_living_cores := 999


func _after_opening() -> bool:
	following_up = true
	followup_started_ms = Time.get_ticks_msec()
	previous_returned = float(game.lifetime_expedition_organic_returned)
	var start_balances := _balances()
	var start_spent: Dictionary = spent.duplicate(true)
	var start_rewards: Dictionary = rewards.duplicate(true)
	var initial_resource_count: int = game.resources.size()
	var initial_enemy_count: int = game.enemy_fungi.size()
	var barracks_id := -1
	for core_id in range(game.cores.size()):
		if game._is_core_alive(core_id) and String(game.cores[core_id].get("kind", "normal")) == "barracks":
			barracks_id = core_id
			break
	if not _check(barracks_id >= 0 and game.expedition_units.size() == 1 and not game.developer_mode_enabled, "follow-up starts with the real opening barracks and its one paid forager"):
		return false
	var forager: Dictionary = game.expedition_units[0]
	followed_unit_id = int(forager["id"])
	game.selected_expedition_ids = [followed_unit_id]
	if not _check(game._assign_harvest_zone(HARVEST_MIN, HARVEST_MAX) == 1, "the existing forager accepts a continuous square over the original visible organic cluster"):
		return false
	if not _check(game._best_harvest_resource(forager).size() > 0, "the assigned real zone contains a currently accessible finite deposit"):
		return false
	print("CHAPTER1_SUPPLY_EXPANSION_START ", JSON.stringify({"elapsed_seconds": elapsed_seconds, "organic": game.organic, "mineral": game.mineral, "dna": game.dna, "harvest_min": [HARVEST_MIN.x, HARVEST_MIN.y], "harvest_max": [HARVEST_MAX.x, HARVEST_MAX.y], "unit_id": followed_unit_id, "existing_live_hypha_length": game._chapter_living_hypha_length()}))

	# Extend the barracks' resource-side perimeter and the secondary core's
	# mineral-side perimeter. Each command pays the real length-dependent cost.
	for waypoint in [Vector2(350.0, -330.0), Vector2(530.0, -160.0)]:
		if not _paid_extension(barracks_id, waypoint):
			return false
	for waypoint in [Vector2(-300.0, 540.0), Vector2(-550.0, 540.0)]:
		if not _paid_extension(1, waypoint):
			return false

	while elapsed_seconds < FOLLOWUP_DEADLINE_SECONDS and not failed and not (game._chapter_supply_ready() and game._chapter_expansion_ready()):
		_tick()
	if failed:
		return false
	if not _check(game._chapter_supply_ready() and game._chapter_expansion_ready(), "the paid intact-map route reaches both current economic goals within forty-five simulated minutes"):
		return false
	if not _check(followup_deposits.size() >= 2 and game.lifetime_expedition_organic_returned >= game.CHAPTER_SUPPLY_RETURNED_ORGANIC_REQUIRED - 0.00000001, "at least two genuine home deliveries satisfy the six-organic return requirement"):
		return false
	if not _check(game._living_core_count() >= game.CHAPTER_LIVING_CORE_REQUIRED and minimum_living_cores >= game.CHAPTER_LIVING_CORE_REQUIRED and game._chapter_living_hypha_length() >= game.CHAPTER_HYPHA_WORLD_REQUIRED, "three living cores and two thousand mature connected hypha units coexist at the milestone"):
		return false
	if not _check(game.chapter_task_index >= 9 and not game.chapter_complete and game.lifetime_enemy_fungi_defeated == 0, "the route unlocks rival discovery, not a falsely claimed whole-chapter victory"):
		return false
	if not _check(game.resources.size() == initial_resource_count and game.enemy_fungi.size() >= initial_enemy_count and not game.bacteria.is_empty() and game.lifetime_expedition_units_built == 1 and game.lifetime_dna_produced == 4, "no world deposits or units are injected and the original competitors and paid DNA history remain"):
		return false
	if not _check(rewards == start_rewards and game.dna == 3, "the follow-up claims no further rewards or free DNA"):
		return false
	for deposit in game.resources:
		if not _check(float(deposit["amount"]) >= 0.0 and float(deposit["amount"]) <= float(deposit["initial_amount"]) + 0.000001, "all original finite deposits remain bounded by their real initial amounts"):
			return false
	var health: Array = []
	for core in game.cores:
		health.append(snappedf(float(core["biomass"]), 0.001))
	print("CHAPTER1_SUPPLY_EXPANSION_SNAPSHOT ", JSON.stringify({
		"elapsed_seconds": elapsed_seconds, "world_seconds": game.sim_time,
		"supply_reached_at_seconds": supply_reached_at, "expansion_reached_at_seconds": expansion_reached_at,
		"organic": snappedf(game.organic, 0.001), "mineral": snappedf(game.mineral, 0.001), "dna": game.dna,
		"absorbed_organic": snappedf(game.lifetime_organic_absorbed, 0.001), "absorbed_mineral": snappedf(game.lifetime_mineral_absorbed, 0.001),
		"returned_organic": snappedf(game.lifetime_expedition_organic_returned, 0.001), "returned_mineral": snappedf(game.lifetime_expedition_mineral_returned, 0.001),
		"living_hypha_length": snappedf(game._chapter_living_hypha_length(), 0.001), "core_biomass": health,
		"deposits": followup_deposits, "extensions": paid_extensions, "start_balances": start_balances,
		"followup_spent": {"organic": float(spent["organic"]) - float(start_spent["organic"]), "mineral": float(spent["mineral"]) - float(start_spent["mineral"]), "dna": int(spent["dna"]) - int(start_spent["dna"])},
		"total_spent": spent, "claimed_rewards": rewards, "chapter_task_index": game.chapter_task_index,
		"bacteria": game.bacteria.size(), "enemy_fungi": game.enemy_fungi.size(), "map_resource_count": game.resources.size(),
		"followup_runtime_ms": Time.get_ticks_msec() - followup_started_ms
	}))
	print("CHAPTER1_SUPPLY_EXPANSION_OK normal_mode=true intact_world=true paid_extensions=4 natural_deliveries=", followup_deposits.size())
	return _after_supply_expansion()


func _after_supply_expansion() -> bool:
	# Optional victory routes continue from these exact paid economic milestones.
	return true


func _paid_extension(core_id: int, target: Vector2) -> bool:
	var before := float(game.organic)
	var ordered_at := elapsed_seconds
	var segment_id := _extend(core_id, target)
	if failed:
		return false
	var segment: Dictionary = game.segments[segment_id]
	var source: Vector2 = segment["a"]
	var endpoint: Vector2 = segment["b"]
	var paid := before - float(game.organic)
	if not _check(paid > 0.0 and float(segment["growth"]) == 0.0, "each new extension is paid for and starts unformed"):
		return false
	_wait_for_segment(segment_id)
	if failed:
		return false
	paid_extensions.append({"core_id": core_id, "from": [source.x, source.y], "to": [endpoint.x, endpoint.y], "ordered_at_seconds": ordered_at, "mature_at_seconds": elapsed_seconds, "organic_cost": paid})
	return true


func _tick() -> void:
	super._tick()
	if not following_up or failed:
		return
	minimum_living_cores = mini(minimum_living_cores, game._living_core_count())
	if supply_reached_at < 0.0 and game._chapter_supply_ready():
		supply_reached_at = elapsed_seconds
	if expansion_reached_at < 0.0 and game._chapter_expansion_ready():
		expansion_reached_at = elapsed_seconds
	var returned := float(game.lifetime_expedition_organic_returned)
	if returned > previous_returned + 0.000001:
		var unit: Dictionary = {}
		for candidate in game.expedition_units:
			if int(candidate["id"]) == followed_unit_id:
				unit = candidate
				break
		if not _check(not unit.is_empty() and (unit["pos"] as Vector2).distance_to(game.cores[int(unit["home_core_id"])]["pos"]) <= game.EXPEDITION_ARRIVAL_DISTANCE, "cargo income occurs only when the original forager physically reaches home"):
			return
		var delivery := {"at_seconds": elapsed_seconds, "amount": snappedf(returned - previous_returned, 0.001), "cumulative_unrounded": returned, "supply_ready": game._chapter_supply_ready()}
		followup_deposits.append(delivery)
		print("CHAPTER1_SUPPLY_EXPANSION_DELIVERY ", JSON.stringify(delivery))
		previous_returned = returned
		if returned >= game.CHAPTER_SUPPLY_RETURNED_ORGANIC_REQUIRED - 0.00000001 and game.lifetime_organic_absorbed >= game.CHAPTER_SUPPLY_ORGANIC_REQUIRED and game.lifetime_mineral_absorbed >= game.CHAPTER_SUPPLY_MINERAL_REQUIRED:
			if not _check(game._chapter_supply_ready(), "two genuine three-organic loads must not require a third trip because of floating-point accumulation noise"):
				return
	var expected_organic := STARTING_ORGANIC + float(game.lifetime_organic_absorbed) + float(game.lifetime_expedition_organic_returned) + float(rewards["organic"]) - float(spent["organic"])
	var expected_mineral := STARTING_MINERAL + float(game.lifetime_mineral_absorbed) + float(game.lifetime_expedition_mineral_returned) + float(rewards["mineral"]) - float(spent["mineral"])
	_check(not game.developer_mode_enabled and absf(float(game.organic) - expected_organic) < 0.001 and absf(float(game.mineral) - expected_mineral) < 0.001 and game.dna == game.lifetime_dna_produced + int(rewards["dna"]) - int(spent["dna"]), "every follow-up step preserves the actual absorption/cargo/reward/payment ledger")
