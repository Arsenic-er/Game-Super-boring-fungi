extends Node2D

# Scene definitions do not tick, own UI, write saves or register singletons.
# Main remains the sole simulation driver; every scene owns its own runtime.
const Runtime = preload("res://scripts/worlds/culture_world_runtime.gd")

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
