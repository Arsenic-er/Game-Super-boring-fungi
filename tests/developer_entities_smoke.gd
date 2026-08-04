extends SceneTree


const TEST_SAVE_PATH := "user://v047_developer_entities_normal.json"
const UNIT_TYPES := [
	"forager",
	"carrier",
	"chelator",
	"scout",
	"lytic",
	"suppressor",
	"disperser",
	"piercer",
	"coil",
	"antifungal",
]
const EXPECTED_METHODS := [
	"_enter_developer_mode",
	"_developer_spawn_resource",
	"_developer_spawn_bacterium",
	"_developer_spawn_core",
	"_developer_spawn_expedition",
	"_developer_spawn_enemy_fungus",
	"_developer_spawn_enemy_guard",
	"_developer_spawn_ecology_event",
	"_developer_clear_entity_group",
]

var assertion_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_save(TEST_SAVE_PATH)
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game.autosave_enabled = false
	game.save_path = TEST_SAVE_PATH

	var missing: Array[String] = []
	for method_name in EXPECTED_METHODS:
		if not game.has_method(method_name):
			missing.append(method_name)
	if not _check(missing.is_empty(), "developer entity API missing: %s" % ", ".join(missing)):
		return
	game.call("_enter_developer_mode")
	game.organic = 0.0
	game.mineral = 0.0
	game.dna = 0
	var resources_before: int = int(game.resources.size())
	var bacteria_before: int = int(game.bacteria.size())
	var cores_before: int = int(game.cores.size())
	var units_before: int = int(game.expedition_units.size())
	var enemies_before: int = int(game.enemy_fungi.size())
	var guards_before: int = int(game.enemy_guard_spores.size())
	var events_before: int = int(game.ecology_events.size())

	# Every developer spawn must bypass gameplay costs and return a stable ID/index.
	var organic_id := int(game.call("_developer_spawn_resource", Vector2(96.0, -32.0), 0, 18.75))
	var mineral_id := int(game.call("_developer_spawn_resource", Vector2(132.0, -24.0), 1, 4.125))
	if not _check(organic_id >= 0 and mineral_id >= 0 and organic_id != mineral_id, "organic and mineral resource spawns should return distinct IDs"):
		return
	if not _check(game.resources.size() == resources_before + 2 and _has_resource(game.resources, organic_id, 0, 18.75) and _has_resource(game.resources, mineral_id, 1, 4.125), "resource spawns should preserve kind and three-decimal amount"):
		return

	var bacterium_id := int(game.call("_developer_spawn_bacterium", Vector2(180.0, 30.0)))
	if not _check(bacterium_id >= 0 and bacterium_id < game.bacteria.size() and game.bacteria.size() == bacteria_before + 1 and float(game.bacteria[bacterium_id].get("biomass", 0.0)) > 0.0, "bacterium spawn should return the array index of a live selectable bacterium"):
		return

	var normal_core_id := int(game.call("_developer_spawn_core", Vector2(220.0, -80.0), "normal"))
	var barracks_core_id := int(game.call("_developer_spawn_core", Vector2(280.0, -80.0), "barracks"))
	if not _check(normal_core_id >= 0 and barracks_core_id >= 0 and normal_core_id != barracks_core_id and game.cores.size() == cores_before + 2, "normal and barracks core spawns should return distinct core IDs"):
		return
	if not _check(bool(game.cores[normal_core_id].get("alive", false)) and String(game.cores[normal_core_id].get("kind", "")) == "normal" and bool(game.cores[barracks_core_id].get("alive", false)) and String(game.cores[barracks_core_id].get("kind", "")) == "barracks", "developer cores should preserve kind and start alive"):
		return

	var spawned_unit_ids: Array[int] = []
	for unit_type in UNIT_TYPES:
		spawned_unit_ids.append(int(game.call("_developer_spawn_expedition", barracks_core_id, unit_type)))
	if not _check(game.expedition_units.size() == units_before + UNIT_TYPES.size() and _all_non_negative_unique(spawned_unit_ids), "all ten expedition archetypes should spawn with unique IDs"):
		return
	if not _check(_contains_all_unit_types(game.expedition_units), "developer expedition spawns should preserve every requested archetype"):
		return

	var enemy_id := int(game.call("_developer_spawn_enemy_fungus", Vector2(520.0, 40.0)))
	if not _check(enemy_id >= 0 and game.enemy_fungi.size() == enemies_before + 1 and _has_id(game.enemy_fungi, enemy_id), "enemy fungus spawn should create a stable rival ID"):
		return
	if not _check(not game.enemy_hyphae.is_empty(), "enemy fungus spawn should include connected rival hyphae"):
		return
	var guard_id := int(game.call("_developer_spawn_enemy_guard", enemy_id, Vector2(488.0, 48.0)))
	if not _check(guard_id >= 0 and game.enemy_guard_spores.size() == guards_before + 1 and _has_id(game.enemy_guard_spores, guard_id), "enemy guard spawn should return a stable guard ID"):
		return
	if not _check(_guard_belongs_to(game.enemy_guard_spores, guard_id, enemy_id), "enemy guard should belong to the requested rival fungus"):
		return

	var bloom_id := int(game.call("_developer_spawn_ecology_event", "bloom", Vector2(-260.0, 120.0)))
	var toxin_id := int(game.call("_developer_spawn_ecology_event", "toxin", Vector2(-180.0, 150.0)))
	if not _check(bloom_id >= 0 and toxin_id >= 0 and bloom_id != toxin_id and game.ecology_events.size() == events_before + 2, "bloom and toxin events should spawn independently"):
		return
	if not _check(_has_event_type(game.ecology_events, "bloom") and _has_event_type(game.ecology_events, "toxin"), "ecology event spawns should preserve their requested types"):
		return
	if not _check(is_zero_approx(float(game.organic)) and is_zero_approx(float(game.mineral)) and int(game.dna) == 0, "developer entity spawns should be free even with zero resources"):
		return

	# Group cleanup is intentionally checked through public developer hooks so it
	# also covers secondary caches, selections and dependent rival structures.
	game.call("_developer_clear_entity_group", "resources")
	if not _check(game.resources.is_empty() and game.feeders.is_empty(), "resource cleanup should also clear dependent feeder hyphae"):
		return
	game.call("_developer_clear_entity_group", "bacteria")
	if not _check(game.bacteria.is_empty(), "bacterium cleanup should remove all bacteria"):
		return
	game.selected_expedition_ids = spawned_unit_ids.duplicate()
	game.call("_developer_clear_entity_group", "expedition")
	if not _check(game.expedition_units.is_empty() and game.selected_expedition_ids.is_empty(), "expedition cleanup should also clear the RTS selection"):
		return
	game.call("_developer_clear_entity_group", "enemies")
	if not _check(game.enemy_fungi.is_empty() and game.enemy_hyphae.is_empty() and game.enemy_guard_spores.is_empty(), "enemy cleanup should cascade through fungi, hyphae and guards"):
		return
	game.call("_developer_clear_entity_group", "ecology")
	if not _check(game.ecology_events.is_empty(), "ecology cleanup should remove all active events"):
		return
	game.call("_developer_clear_entity_group", "cores")
	if not _check(_count_alive_cores(game.cores) == 1 and game.segments.is_empty() and game.feeders.is_empty(), "core cleanup should leave one safe live player core and remove dependent player hyphae"):
		return

	_remove_save(TEST_SAVE_PATH)
	_remove_save(String(game.call("_developer_save_path")) if game.has_method("_developer_save_path") else "")
	print("V047_DEVELOPER_ENTITIES_OK assertions=%d resources=2 bacteria=1 cores=2 units=10 enemies=1 guards=1 events=2 cleanup=6" % assertion_count)
	game.queue_free()
	quit(0)


func _has_resource(items: Array, wanted_id: int, wanted_kind: int, wanted_amount: float) -> bool:
	for item in items:
		if int(item.get("id", -1)) == wanted_id:
			return int(item.get("kind", -1)) == wanted_kind and is_equal_approx(float(item.get("amount", -1.0)), wanted_amount) and bool(item.get("alive", false))
	return false


func _has_id(items: Array, wanted_id: int) -> bool:
	for item in items:
		if int(item.get("id", -1)) == wanted_id:
			return true
	return false


func _all_non_negative_unique(ids: Array[int]) -> bool:
	var seen := {}
	for entity_id in ids:
		if entity_id < 0 or seen.has(entity_id):
			return false
		seen[entity_id] = true
	return true


func _contains_all_unit_types(units: Array) -> bool:
	var seen := {}
	for unit in units:
		seen[String(unit.get("unit_type", ""))] = true
	for unit_type in UNIT_TYPES:
		if not seen.has(unit_type):
			return false
	return true


func _guard_belongs_to(guards: Array, guard_id: int, enemy_id: int) -> bool:
	for guard in guards:
		if int(guard.get("id", -1)) == guard_id:
			return int(guard.get("enemy_id", guard.get("fungus_id", -1))) == enemy_id
	return false


func _has_event_type(events: Array, wanted_type: String) -> bool:
	for event in events:
		if String(event.get("type", "")) == wanted_type:
			return true
	return false


func _count_alive_cores(cores: Array) -> int:
	var count := 0
	for core in cores:
		if bool(core.get("alive", false)):
			count += 1
	return count


func _remove_save(path: String) -> void:
	if not path.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, message: String) -> bool:
	assertion_count += 1
	if condition:
		return true
	push_error("V047_DEVELOPER_ENTITIES_FAIL[%d]: %s" % [assertion_count, message])
	quit(1)
	return false
