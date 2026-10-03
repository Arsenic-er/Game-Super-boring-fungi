extends "res://scripts/worlds/culture_world.gd"

const ResourceCluster = preload("res://scripts/worlds/resource_cluster.gd")
const MAP_SEED := 0xCA472
const MAX_CLUSTER_NODES := 256

@export var organic_required: float = 36.0
@export var mineral_required: float = 4.0
@export var starting_organic: float = 220.0
@export var starting_mineral: float = 24.0
@export var starting_dna: int = 0

var _map_rng_state: int = 0
var _map_generated := false


func generate_map(game) -> void:
	if not validate_definition():
		push_error("Invalid RemotePantry scene definition")
		return
	game.resources.clear()
	game.resource_grid.clear()
	game.bacteria.clear()
	game.resource_hotspots.clear()
	game.water_motes.clear()
	game.substrate_marks.clear()
	game.rng.seed = MAP_SEED
	# Scene child order makes resource IDs and save restoration deterministic.
	for cluster in get_node("ResourceClusters").get_children():
		cluster.populate(game)
	_map_rng_state = game.rng.state
	_map_generated = true
	game._generate_substrate()
	game.rng.state = _map_rng_state


func initialize_colony(game) -> void:
	if not validate_definition():
		push_error("Invalid RemotePantry colony definition")
		return
	game.founder_spore = {}
	game.organic = starting_organic
	game.mineral = starting_mineral
	game.dna = starting_dna
	game.cores.clear()
	var spawn := get_node("SpawnPoint") as Marker2D
	game.cores.append(game._make_core(spawn.position))
	if _map_generated:
		game.rng.state = _map_rng_state
	game.core_selected_once = true
	game.enemy_fungi_initialized = true
	game.explored_cells.clear()
	game.discovered_hotspots.clear()
	game.last_discovery_scan_cell_count = -1
	game._update_exploration(false)
	game._sync_hotspot_discoveries(false)


func goal_targets() -> Dictionary:
	# These targets mean unloaded unit cargo, never passive uptake or stock.
	return {"organic": organic_required, "mineral": mineral_required, "length_world": 0.0}


func mission_ready(game) -> bool:
	return validate_definition() and not game.game_over and game._living_core_count() > 0 and game._chapter_bounded_progress(game.lifetime_expedition_organic_returned, organic_required) >= organic_required and game._chapter_bounded_progress(game.lifetime_expedition_mineral_returned, mineral_required) >= mineral_required


func validate_definition() -> bool:
	if not super.validate_definition() or scene_id != "remote_pantry":
		return false
	if not is_finite(organic_required) or organic_required <= 0.0 or not is_finite(mineral_required) or mineral_required <= 0.0:
		return false
	if not is_finite(starting_organic) or starting_organic < 0.0 or not is_finite(starting_mineral) or starting_mineral < 0.0 or starting_dna < 0:
		return false
	var spawn := get_node_or_null("SpawnPoint")
	var clusters := get_node_or_null("ResourceClusters")
	if not spawn is Marker2D or not spawn.position.is_finite() or not clusters is Node2D:
		return false
	if clusters.get_child_count() <= 0 or clusters.get_child_count() > MAX_CLUSTER_NODES:
		return false
	var available := [0.0, 0.0]
	for cluster in clusters.get_children():
		if not cluster is ResourceCluster or not cluster.validate_definition():
			return false
		available[cluster.kind] += cluster.count * cluster.amount_min
	return available[0] >= organic_required and available[1] >= mineral_required
