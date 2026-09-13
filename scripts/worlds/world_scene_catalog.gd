extends RefCounted

# Save data chooses a stable ID, never an arbitrary resource path.
const PATHS := {
	"home_nest": "res://scenes/worlds/HomeNest.tscn",
	"first_supply": "res://scenes/missions/FirstSupply.tscn",
}
const REVISION := 1
static var _target_cache: Dictionary = {}

static func prepare(scene_id: String) -> Node2D:
	if not PATHS.has(scene_id):
		return null
	var packed = load(PATHS[scene_id])
	if not packed is PackedScene:
		return null
	var scene = packed.instantiate()
	if not scene is Node2D or not scene.has_method("validate_definition") or not scene.validate_definition() or scene.scene_id != scene_id or scene.revision != REVISION:
		scene.free()
		return null
	return scene

static func valid_metadata(snapshot: Dictionary) -> bool:
	if not snapshot.has("world_scene_id") and not snapshot.has("world_scene_revision"):
		return true
	var id = snapshot.get("world_scene_id", null)
	var revision = snapshot.get("world_scene_revision", null)
	return id is String and PATHS.has(id) and (typeof(revision) == TYPE_INT or typeof(revision) == TYPE_FLOAT) and revision == REVISION

static func matches(snapshot: Dictionary, expected_id: String) -> bool:
	return valid_metadata(snapshot) and snapshot.get("world_scene_id", expected_id) == expected_id

static func resolve_id(snapshot: Dictionary, fallback_id: String) -> String:
	if not valid_metadata(snapshot) or not PATHS.has(fallback_id):
		return ""
	return String(snapshot.get("world_scene_id", fallback_id))

static func targets(scene_id: String) -> Dictionary:
	if not _target_cache.has(scene_id):
		var scene := prepare(scene_id)
		if scene == null:
			return {}
		_target_cache[scene_id] = scene.goal_targets().duplicate(true)
		scene.free()
	return _target_cache[scene_id].duplicate(true)
