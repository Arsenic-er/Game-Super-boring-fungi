extends RefCounted

# These are synthetic access checkpoints, never evidence of earned victories.
# All progression balances are derived through the live campaign operations.
const State = preload("res://scripts/campaign_state.gd")
const IDS: Array[String] = ["early_choice", "early_one", "first_contact_ready", "nest_upgrade_ready", "advanced_choice", "two_fronts_ready", "finale_ready", "chapter_complete"]
const FIXTURE_ID := "branch_audit_prepared_home_v1"
const HOME_SEED := 0xF00D47
const STOCK := {"organic": 220.0, "mineral": 24.0, "dna": 0}


static func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in IDS:
		result.append({"id": id, "preset_id": id, "title_key": id + "_title", "description_key": id + "_description", "body_key": id + "_description"})
	return result


static func preset(id: Variant) -> Dictionary:
	if typeof(id) != TYPE_STRING or not IDS.has(id):
		return {}
	var state := campaign_for(id, 0)
	if state.is_empty():
		return {}
	var completed: Array[String] = []
	for entry in State.Catalog.entries():
		if bool(state["completed"].get(entry["id"], false)):
			completed.append(String(entry["id"]))
	var result := {
		"id": id, "preset_id": id, "title_key": id + "_title", "description_key": id + "_description",
		"fixture": FIXTURE_ID, "home_seed": HOME_SEED, "synthetic_completed": completed,
		"earned_prior_victories": false, "normal_costs": true, "developer_mode": false, "offline_gains": false,
		"starting_organic": STOCK["organic"], "starting_mineral": STOCK["mineral"], "starting_dna": STOCK["dna"],
		"prepared_cores": 2, "prepared_segments": 4, "prepared_units": 8,
		"main_core_kind": "normal", "other_core_kind": "barracks", "prepared_unit_type": "forager",
		"prepared_segment_length": 240.0, "prepared_segment_growth": 1.0,
		"research_levels": 0, "branches": state["branches"].duplicate(true),
		"unit_licenses": {"forager": true}, "nest_level": state["nest_level"],
		"materials": state["materials"], "tissues": state["tissues"].duplicate(true),
		"late_campaign_home_representative": false, "ordinary_nest_tier_passives": true
	}
	return result


static func get_preset(id: Variant) -> Dictionary:
	return preset(id)


static func campaign_for(id: Variant, main_core_id: int) -> Dictionary:
	if typeof(id) != TYPE_STRING or not IDS.has(id) or main_core_id < 0 or main_core_id > State.MAX_CORE_ID:
		return {}
	var state := State.fresh()
	state["main_core_id"] = main_core_id
	if not _complete(state, "first_supply") or not State.upgrade(state):
		return {}
	if id == "early_choice":
		return state
	if not _complete(state, "remote_pantry"):
		return {}
	if id == "early_one":
		return state
	if not _complete(state, "lost_network"):
		return {}
	if id == "first_contact_ready":
		return state
	if not _complete(state, "first_contact"):
		return {}
	if id == "nest_upgrade_ready":
		return state
	if not State.upgrade(state):
		return {}
	if id == "advanced_choice":
		return state
	if not _complete(state, "toxic_frontier"):
		return {}
	if id == "two_fronts_ready":
		return state
	if not _complete(state, "two_fronts") or not State.upgrade(state):
		return {}
	if id == "finale_ready":
		return state
	if not _complete(state, "stable_colony"):
		return {}
	return state


static func _complete(state: Dictionary, mission_id: String) -> bool:
	# begin only requires a safe JSON home here; this placeholder never enters
	# a game save, and settle removes it before a checkpoint is returned.
	var placeholder := {"audit_fixture_placeholder": true}
	if not State.begin(state, placeholder, float(state["serial"]), {}, mission_id):
		return false
	return bool(State.settle(state, "victory").get("ok", false))


static func prepare_home(game) -> bool:
	# Caller must use the real fresh-world and founder-germination entry points.
	# Refuse an existing played world rather than silently replace its contents.
	var main_id := int(game.campaign.get("main_core_id", -1))
	if game._world_scene_id() != "home_nest" or game.developer_mode_enabled or game._campaign_active() or game.cores.size() != 1 or not game.segments.is_empty() or not game.expedition_units.is_empty() or not game._is_core_alive(main_id):
		return false
	for property in ["structure_levels", "survival_levels", "diet_levels", "bacteria_components", "scout_upgrade_levels"]:
		for value in game.get(property).values():
			if int(value) != 0:
				return false
	var origin: Vector2 = game.cores[main_id]["pos"]
	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(origin + Vector2(240.0, 0.0), "barracks"))
	for offset in [Vector2(240.0, 0.0), Vector2(-240.0, 0.0), Vector2(0.0, 240.0), Vector2(0.0, -240.0)]:
		game.segments.append({
			"a": origin, "b": origin + offset, "growth": 1.0,
			"core_id": main_id, "curve": 0.0, "orphaned": false, "viability": 1.0
		})
	game.enemy_fungi.clear()
	game.enemy_hyphae.clear()
	game.enemy_guard_spores.clear()
	game.enemy_fungi_initialized = true
	for _index in range(8):
		game._spawn_expedition_spore(barracks_id, "forager")
	game.organic = STOCK["organic"]
	game.mineral = STOCK["mineral"]
	game.dna = STOCK["dna"]
	game.camera_center = origin
	game.camera_zoom = 0.65
	game._update_exploration(false)
	return true


static func apply(game, id: Variant) -> Dictionary:
	var initial := preset(id)
	var main_id := int(game.campaign.get("main_core_id", -1))
	var state := campaign_for(id, main_id)
	if initial.is_empty() or state.is_empty() or not prepare_home(game):
		return {"ok": false, "initial_conditions": {}}
	game.campaign = state
	initial["main_core_id"] = main_id
	initial["world_entities"] = {
		"cores": game.cores.size(), "segments": game.segments.size(), "units": game.expedition_units.size(),
		"resource_particles": game.resources.size(), "bacteria": game.bacteria.size(),
		"enemy_cores": game.enemy_fungi.size()
	}
	return {"ok": true, "initial_conditions": initial}
