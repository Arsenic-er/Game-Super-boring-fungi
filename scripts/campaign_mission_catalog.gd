class_name CampaignMissionCatalog
extends RefCounted

# Stable progression metadata for the nine independent Chapter 1 scenes.
# Scene paths live in WorldSceneCatalog; save data never supplies resource paths.
const MISSIONS := [
	{"id": "first_supply", "order": 1, "title_key": "first_supply_title", "kind": "expedition", "implemented": true, "required_nest_level": 1, "prerequisite": "", "first_victory_materials": 3},
	{"id": "remote_pantry", "order": 2, "title_key": "remote_pantry_title", "kind": "expedition", "implemented": true, "required_nest_level": 2, "prerequisite": "first_supply", "first_victory_materials": 3},
	{"id": "first_contact", "order": 3, "title_key": "first_contact_title", "kind": "nest_challenge", "implemented": true, "required_nest_level": 2, "prerequisite": "remote_pantry", "first_victory_materials": 3},
	{"id": "substrate_race", "order": 4, "title_key": "substrate_race_title", "kind": "expedition", "implemented": true, "required_nest_level": 3, "prerequisite": "first_contact", "first_victory_materials": 3},
	{"id": "lost_network", "order": 5, "title_key": "lost_network_title", "kind": "expedition", "implemented": true, "required_nest_level": 3, "prerequisite": "substrate_race", "first_victory_materials": 3},
	{"id": "two_fronts", "order": 6, "title_key": "two_fronts_title", "kind": "nest_challenge", "implemented": true, "required_nest_level": 3, "prerequisite": "lost_network", "first_victory_materials": 3},
	{"id": "toxic_frontier", "order": 7, "title_key": "toxic_frontier_title", "kind": "expedition", "implemented": true, "required_nest_level": 4, "prerequisite": "two_fronts", "first_victory_materials": 3},
	{"id": "boundary_counterattack", "order": 8, "title_key": "boundary_counterattack_title", "kind": "expedition", "implemented": true, "required_nest_level": 4, "prerequisite": "toxic_frontier", "first_victory_materials": 3},
	{"id": "stable_colony", "order": 9, "title_key": "stable_colony_title", "kind": "nest_challenge", "implemented": true, "required_nest_level": 4, "prerequisite": "boundary_counterattack", "first_victory_materials": 3},
]
const TOTAL_MATERIAL_BUDGET := 27


static func entries() -> Array:
	return MISSIONS.duplicate(true)


static func mission(mission_id: Variant) -> Dictionary:
	if typeof(mission_id) != TYPE_STRING:
		return {}
	for entry in MISSIONS:
		if entry["id"] == mission_id:
			return entry.duplicate(true)
	return {}


static func is_implemented(mission_id: Variant) -> bool:
	return bool(mission(mission_id).get("implemented", false))


static func is_unlocked(state: Dictionary, mission_id: Variant) -> bool:
	var entry := mission(mission_id)
	if entry.is_empty():
		return false
	var level: Variant = state.get("nest_level", null)
	if not (typeof(level) == TYPE_INT or typeof(level) == TYPE_FLOAT) or not is_finite(float(level)) or float(level) != floor(float(level)) or float(level) < float(entry["required_nest_level"]):
		return false
	var prerequisite := String(entry["prerequisite"])
	if prerequisite.is_empty():
		return true
	var completed: Variant = state.get("completed", {})
	return completed is Dictionary and typeof(completed.get(prerequisite, null)) == TYPE_BOOL and completed[prerequisite]


static func first_victory_materials(mission_id: Variant) -> int:
	if not is_implemented(mission_id):
		return 0
	return int(mission(mission_id).get("first_victory_materials", 0))
