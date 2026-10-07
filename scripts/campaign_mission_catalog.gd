class_name CampaignMissionCatalog
extends RefCounted

# Stable IDs identify independent scenes; order is presentation, never a gate.
# Expeditions in each branch group unlock together and remain available later.
const EARLY_BRANCHES := ["remote_pantry", "lost_network", "substrate_race"]
const ADVANCED_BRANCHES := ["toxic_frontier", "boundary_counterattack"]
const MISSIONS := [
	{"id": "first_supply", "order": 1, "title_key": "first_supply_title", "kind": "expedition", "group": "tutorial", "implemented": true, "required_nest_level": 1, "prerequisite": "", "first_victory_materials": 3, "first_victory_tissues": {}},
	{"id": "remote_pantry", "order": 2, "title_key": "remote_pantry_title", "kind": "expedition", "group": "branch_early", "implemented": true, "required_nest_level": 2, "prerequisite": "first_supply", "first_victory_materials": 3, "first_victory_tissues": {"transport": 1}},
	{"id": "lost_network", "order": 3, "title_key": "lost_network_title", "kind": "expedition", "group": "branch_early", "implemented": true, "required_nest_level": 2, "prerequisite": "first_supply", "first_victory_materials": 3, "first_victory_tissues": {"resilience": 1}},
	{"id": "substrate_race", "order": 4, "title_key": "substrate_race_title", "kind": "expedition", "group": "branch_early", "implemented": true, "required_nest_level": 2, "prerequisite": "first_supply", "first_victory_materials": 3, "first_victory_tissues": {"defense": 1}},
	{"id": "first_contact", "order": 5, "title_key": "first_contact_title", "kind": "nest_challenge", "group": "trial_early", "implemented": true, "required_nest_level": 2, "prerequisite": "first_supply", "prerequisites_any": EARLY_BRANCHES, "required_completions": 2, "first_victory_materials": 3, "first_victory_tissues": {"transport": 1, "resilience": 1, "defense": 1}},
	{"id": "toxic_frontier", "order": 6, "title_key": "toxic_frontier_title", "kind": "expedition", "group": "branch_advanced", "implemented": true, "required_nest_level": 3, "prerequisite": "first_contact", "first_victory_materials": 3, "first_victory_tissues": {"transport": 1, "resilience": 1}},
	{"id": "boundary_counterattack", "order": 7, "title_key": "boundary_counterattack_title", "kind": "expedition", "group": "branch_advanced", "implemented": true, "required_nest_level": 3, "prerequisite": "first_contact", "first_victory_materials": 3, "first_victory_tissues": {"defense": 1, "resilience": 1}},
	{"id": "two_fronts", "order": 8, "title_key": "two_fronts_title", "kind": "nest_challenge", "group": "trial_advanced", "implemented": true, "required_nest_level": 3, "prerequisite": "first_contact", "prerequisites_any": ADVANCED_BRANCHES, "required_completions": 1, "first_victory_materials": 3, "first_victory_tissues": {}},
	{"id": "stable_colony", "order": 9, "title_key": "stable_colony_title", "kind": "nest_challenge", "group": "finale", "implemented": true, "required_nest_level": 4, "prerequisite": "two_fronts", "first_victory_materials": 3, "first_victory_tissues": {}},
]
const TOTAL_MATERIAL_BUDGET := 27
const TISSUE_BUDGETS := {"transport": 3, "resilience": 4, "defense": 3}
# The version-one gates are frozen solely for saved-progress migration.
const LEGACY_GATES := {
	"first_supply": [1, ""], "remote_pantry": [2, "first_supply"],
	"first_contact": [2, "remote_pantry"], "substrate_race": [3, "first_contact"],
	"lost_network": [3, "substrate_race"], "two_fronts": [3, "lost_network"],
	"toxic_frontier": [4, "two_fronts"], "boundary_counterattack": [4, "toxic_frontier"],
	"stable_colony": [4, "boundary_counterattack"]
}


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
	return bool(unlock_progress(state, mission_id)["unlocked"])


static func unlock_progress(state: Dictionary, mission_id: Variant) -> Dictionary:
	var entry := mission(mission_id)
	var level := _nest_level(state)
	var result := {"unlocked": false, "required_nest_level": int(entry.get("required_nest_level", 1)), "current_nest_level": level, "completed": 0, "required": int(entry.get("required_completions", 0)), "choices": entry.get("prerequisites_any", []).duplicate(), "missing_prerequisite": "", "legacy": false}
	if entry.is_empty():
		return result
	for choice in result["choices"]:
		if _true_flag(state.get("completed", {}), choice):
			result["completed"] += 1
	var prerequisite := String(entry.get("prerequisite", ""))
	if not prerequisite.is_empty() and not _true_flag(state.get("completed", {}), prerequisite):
		result["missing_prerequisite"] = prerequisite
	result["legacy"] = _true_flag(state.get("legacy_unlocked_missions", {}), String(mission_id))
	# First victories and grandfathered openings are permanent access, not
	# invented victories. They never increment the any-of branch counter.
	result["unlocked"] = _true_flag(state.get("completed", {}), String(mission_id)) or result["legacy"] or (level >= int(result["required_nest_level"]) and result["missing_prerequisite"].is_empty() and int(result["completed"]) >= int(result["required"]))
	return result


static func legacy_is_unlocked(state: Dictionary, mission_id: String) -> bool:
	if not LEGACY_GATES.has(mission_id):
		return false
	var gate: Array = LEGACY_GATES[mission_id]
	return _nest_level(state) >= int(gate[0]) and (String(gate[1]).is_empty() or _true_flag(state.get("completed", {}), String(gate[1])))


static func first_victory_materials(mission_id: Variant) -> int:
	if not is_implemented(mission_id):
		return 0
	return int(mission(mission_id).get("first_victory_materials", 0))


static func first_victory_tissues(mission_id: Variant) -> Dictionary:
	return mission(mission_id).get("first_victory_tissues", {}).duplicate(true)


static func _nest_level(state: Dictionary) -> int:
	var level: Variant = state.get("nest_level", null)
	if not (typeof(level) == TYPE_INT or typeof(level) == TYPE_FLOAT) or not is_finite(float(level)) or float(level) != floor(float(level)) or float(level) < 1.0 or float(level) > 4.0:
		return 0
	return int(level)


static func _true_flag(flags: Variant, key: String) -> bool:
	return flags is Dictionary and typeof(flags.get(key, null)) == TYPE_BOOL and flags[key]
