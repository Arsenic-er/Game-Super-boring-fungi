class_name WorldSnapshotValidator
extends RefCounted

# Keep this synchronized with main.WORLD_HALF; twice the radius accepts legacy
# edge positions while rejecting double values that overflow Vector2's floats.
const MAX_COORDINATE := 16384.0 * 2.0
const COORDINATE_FIELDS := ["x", "y", "ax", "ay", "bx", "by", "rally_x", "rally_y", "directive_min_x", "directive_min_y", "directive_max_x", "directive_max_y", "target_x", "target_y", "defense_min_x", "defense_min_y", "defense_max_x", "defense_max_y", "harvest_min_x", "harvest_min_y", "harvest_max_x", "harvest_max_y", "purge_min_x", "purge_min_y", "purge_max_x", "purge_max_y"]
const ENTITY_NUMBERS := {
	"cores": ["auto_replenish_target", "feeder_range_level", "biomass", "max_biomass", "repair_reserve"],
	"segments": ["growth", "core_id", "curve", "viability"],
	"resource_states": ["id", "amount"],
	"resource_catalog": ["kind", "initial_amount", "amount", "phase"],
	"hotspot_catalog": ["radius", "kind"],
	"feeders": ["resource_id", "core_id", "growth", "phase"],
	"bacteria": ["stored", "cooldown", "biomass", "resource_id", "seek_cooldown", "contact_cooldown", "event_id", "phase"],
	"expedition_units": ["id", "home_core_id", "target_resource_id", "target_enemy_id", "target_enemy_hypha_id", "target_enemy_guard_id", "defense_patrol_index", "harvest_patrol_index", "purge_patrol_index", "deploy_progress", "burst_cooldown", "last_burst_hits", "cargo_organic", "cargo_mineral", "biomass", "max_biomass", "search_cooldown", "phase"],
	"enemy_fungi": ["id", "biomass", "max_biomass", "organic_reserve", "state_time", "growth_time", "guard_spawn_time", "wave", "attack_multiplier", "pulse"],
	"enemy_hyphae": ["id", "fungus_id", "parent_id", "growth", "curve", "viability"],
	"enemy_guard_spores": ["id", "fungus_id", "target_unit_id", "biomass", "max_biomass", "patrol_time", "phase"],
	"ecology_events": ["id", "radius", "remaining", "anchor_core_id", "spawned", "control_progress"]
}
const ENTITY_TEXT := {
	"cores": ["kind", "production_unit", "auto_replenish_unit", "directive_type", "directive_unit"],
	"hotspot_catalog": ["id"],
	"bacteria": ["strain"],
	"expedition_units": ["unit_type", "state", "target_kind", "retreat_reason"],
	"enemy_fungi": ["state", "source"],
	"enemy_guard_spores": ["state"],
	"ecology_events": ["type", "phase"]
}
const NUMERIC_CONFIGS := ["diet_levels", "diet_investments", "bacteria_components", "structure_levels", "survival_levels", "scout_upgrade_levels", "simulation_clocks"]
const FLAG_CONFIGS := ["barracks_unit_unlocks", "diet_unit_unlocks", "goals_claimed"]
const TOP_LEVEL_NUMBERS := ["world_generation", "chapter_rules_version", "chapter_task_index", "chapter_completed_at", "chapter_completed_rules_version", "ecology_event_countdown", "next_ecology_event_id", "camera_zoom", "sim_time", "next_expedition_id", "next_enemy_fungus_id", "next_enemy_hypha_id", "next_enemy_guard_id"]


static func validate(raw: Dictionary) -> bool:
	# Required top-level version/profile/economy validation remains in main.
	# Optional fields stay optional for old saves; values that are present must
	# be safe for the exact .get, typed assignment and Vector2 restore operations.
	for field in ENTITY_NUMBERS:
		if not raw.has(field):
			continue
		if not raw[field] is Array:
			return false
		for item in raw[field]:
			if not item is Dictionary or not _record(item, ENTITY_NUMBERS[field], ENTITY_TEXT.get(field, [])):
				return false
			if field == "cores" and (not _jobs(item, "jobs", true) or not _jobs(item, "spore_jobs", false)):
				return false
	for field in NUMERIC_CONFIGS:
		if raw.has(field) and not _config(raw[field], false):
			return false
	for field in FLAG_CONFIGS:
		if raw.has(field) and not _config(raw[field], true):
			return false
	if not _numbers(raw, TOP_LEVEL_NUMBERS) or not _numbers(raw, ["camera_x", "camera_y"], MAX_COORDINATE):
		return false
	for key in raw:
		if key is String and key.begins_with("lifetime_") and not _number(raw[key]):
			return false
	for field in ["diet_order", "discovered_hotspots", "explored_cells"]:
		if not raw.has(field):
			continue
		if not raw[field] is Array:
			return false
		for value in raw[field]:
			if field == "explored_cells":
				if not _number(value):
					return false
			elif not value is String:
				return false
	if raw.has("founder_spore"):
		var founder = raw["founder_spore"]
		if not founder is Dictionary or not _record(founder, ["energy"], ["state"]):
			return false
	if raw.has("fungal_incursion"):
		var incursion = raw["fungal_incursion"]
		if not incursion is Dictionary or not _numbers(incursion, ["remaining", "wave", "enemy_id"]) or not _text(incursion, ["phase"]):
			return false
		# Legacy inactive incursions could serialize their unused INF sentinel.
		# Restore does not read x/y unless has_pos is true.
		if bool(incursion.get("has_pos", false)) and not _numbers(incursion, ["x", "y"], MAX_COORDINATE):
			return false
	for field in ["rng_seed", "rng_state"]:
		if raw.has(field) and (not raw[field] is String or not raw[field].is_valid_int()):
			return false
	return true


static func _record(raw: Dictionary, numbers: Array, words: Array) -> bool:
	return _numbers(raw, COORDINATE_FIELDS, MAX_COORDINATE) and _numbers(raw, numbers) and _text(raw, words)


static func _number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))


static func _numbers(raw: Dictionary, fields: Array, maximum: float = INF) -> bool:
	for field in fields:
		if raw.has(field) and (not _number(raw[field]) or absf(float(raw[field])) > maximum):
			return false
	return true


static func _text(raw: Dictionary, fields: Array) -> bool:
	for field in fields:
		if raw.has(field) and not raw[field] is String:
			return false
	return true


static func _config(raw: Variant, flags: bool) -> bool:
	if not raw is Dictionary:
		return false
	for key in raw:
		if not key is String or (not _number(raw[key]) and not (flags and typeof(raw[key]) == TYPE_BOOL)):
			return false
	return true


static func _jobs(core: Dictionary, field: String, allow_legacy_number: bool) -> bool:
	if not core.has(field):
		return true
	if not core[field] is Array:
		return false
	for job in core[field]:
		# Original DNA queues stored remaining seconds as numbers, not records.
		if allow_legacy_number and _number(job):
			continue
		if not job is Dictionary or not _numbers(job, ["remaining", "total"]):
			return false
		if not allow_legacy_number and not _text(job, ["unit_type"]):
			return false
	return true
