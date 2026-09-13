extends RefCounted

# Each PackedScene instance owns an independent runtime. Main's compatibility
# properties proxy here, including whole-array assignments during pruning.
var data: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _init(defaults: Dictionary = {}) -> void:
	ensure_defaults(defaults)

func ensure_defaults(defaults: Dictionary) -> void:
	for key in defaults:
		if not data.has(key):
			var value = defaults[key]
			data[key] = value.duplicate(true) if value is Array or value is Dictionary else value
