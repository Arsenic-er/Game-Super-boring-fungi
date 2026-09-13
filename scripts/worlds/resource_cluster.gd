extends Node2D

const MAX_RESOURCE_COUNT := 10000

@export var count: int = 1
@export var spread: float = 58.0
@export_enum("Organic:0", "Mineral:1") var kind: int = 0
@export var amount_min: float = 14.0
@export var amount_max: float = 20.0
@export var anomalous: bool = true


func center_in_world() -> Vector2:
	# Resource positions are relative to the owning world scene, not the UI or
	# WorldHost transform. A translated ResourceClusters container is supported.
	var center := position
	var ancestor := get_parent()
	while ancestor != null and ancestor != owner:
		if ancestor is Node2D:
			center = ancestor.transform * center
		ancestor = ancestor.get_parent()
	return center


func populate(game) -> void:
	if not validate_definition():
		push_error("Invalid resource cluster definition: " + String(name))
		return
	game._scatter_cluster(center_in_world(), count, spread, kind, amount_min, amount_max, anomalous)


func validate_definition() -> bool:
	return position.is_finite() and center_in_world().is_finite() and count > 0 and count <= MAX_RESOURCE_COUNT and kind in [0, 1] and is_finite(spread) and spread > 0.0 and is_finite(amount_min) and is_finite(amount_max) and amount_min > 0.0 and amount_max >= amount_min
