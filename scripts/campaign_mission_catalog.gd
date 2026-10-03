class_name CampaignMissionCatalog
extends RefCounted

# This is the approved Chapter 1 roster, not a claim that every scene exists.
# Future rewards remain tuning values; unavailable missions never enter saves.
const MISSIONS := [
	{"id": "first_supply", "order": 1, "title_key": "campaign.mission.first_supply", "kind": "expedition", "implemented": true, "required_nest_level": 1, "prerequisite": "", "first_victory_materials": 3},
	{"id": "remote_pantry", "order": 2, "title_key": "campaign.mission.remote_pantry", "kind": "expedition", "implemented": true, "required_nest_level": 2, "prerequisite": "first_supply", "first_victory_materials": 3},
	{"id": "first_contact", "order": 3, "title_key": "campaign.mission.first_contact", "kind": "nest_challenge", "implemented": false, "required_nest_level": 2, "prerequisite": "remote_pantry", "first_victory_materials": 3},
	{"id": "substrate_race", "order": 4, "title_key": "campaign.mission.substrate_race", "kind": "expedition", "implemented": false, "required_nest_level": 2, "prerequisite": "first_contact", "first_victory_materials": 3},
	{"id": "lost_network", "order": 5, "title_key": "campaign.mission.lost_network", "kind": "expedition", "implemented": false, "required_nest_level": 2, "prerequisite": "substrate_race", "first_victory_materials": 3},
	{"id": "two_fronts", "order": 6, "title_key": "campaign.mission.two_fronts", "kind": "nest_challenge", "implemented": false, "required_nest_level": 2, "prerequisite": "lost_network", "first_victory_materials": 3},
	{"id": "toxic_frontier", "order": 7, "title_key": "campaign.mission.toxic_frontier", "kind": "expedition", "implemented": false, "required_nest_level": 2, "prerequisite": "two_fronts", "first_victory_materials": 3},
	{"id": "boundary_counterattack", "order": 8, "title_key": "campaign.mission.boundary_counterattack", "kind": "expedition", "implemented": false, "required_nest_level": 2, "prerequisite": "toxic_frontier", "first_victory_materials": 3},
	{"id": "stable_colony", "order": 9, "title_key": "campaign.mission.stable_colony", "kind": "nest_challenge", "implemented": false, "required_nest_level": 2, "prerequisite": "boundary_counterattack", "first_victory_materials": 3},
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
