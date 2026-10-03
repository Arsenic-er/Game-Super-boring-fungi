extends Node2D

# Scene definitions do not tick, own UI, write saves or register singletons.
# Main remains the sole simulation driver; every scene owns its own runtime.
const Runtime = preload("res://scripts/worlds/culture_world_runtime.gd")

# Mirror Main's restore bounds without preloading Main (which owns these scenes).
# campaign_snapshot_integrity_smoke pins the public constants against Main.
const SNAPSHOT_WORLD_HALF := 16384.0
const SNAPSHOT_MAX_GUARDS := 24
const SNAPSHOT_MAX_ENEMY_CORES := 3

@export var scene_id: String = ""
@export var revision: int = 1
var runtime = Runtime.new()


func generate_map(_game) -> void:
	push_error("CultureWorld requires a concrete map definition")


func initialize_colony(_game) -> void:
	push_error("CultureWorld requires a concrete colony definition")


func goal_targets() -> Dictionary:
	return {}


func mission_ready(_game) -> bool:
	return false


func allows_ecology_events() -> bool:
	return false


func allows_legacy_chapter() -> bool:
	return false


func validate_definition() -> bool:
	return not scene_id.is_empty() and scene_id == scene_id.strip_edges() and revision >= 1

# Mission scripts never run their own _process; Main supplies scaled simulation time.
func mission_tick(_game, _delta: float) -> void:
	pass


func mission_status(_game) -> Array[Dictionary]:
	return []


func mission_failed(_game) -> bool:
	return false


func manual_action_key(_game) -> String:
	return ""


func mission_action(_game) -> bool:
	return false


func initialize_trial(_game) -> void:
	pass


func handles_enemy_guard(_guard_id: int) -> bool:
	return false


func validate_mission_state(_state: Dictionary) -> bool:
	return true


func validate_snapshot(raw: Dictionary) -> bool:
	# Scene-specific identity references must be checked before any live world
	# is replaced, so a damaged primary can fall back to a complete checkpoint.
	var state = raw.get("mission_state", {})
	return state is Dictionary and validate_mission_state(state)


func _snapshot_point_in_circle(record: Dictionary, margin: float) -> bool:
	var x = record.get("x", 0.0)
	var y = record.get("y", 0.0)
	if not (x is int or x is float) or not (y is int or y is float):
		return false
	var point := Vector2(float(x), float(y))
	return point.is_finite() and point.length() <= SNAPSHOT_WORLD_HALF - margin
