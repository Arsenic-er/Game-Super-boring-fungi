class_name CampaignState
extends RefCounted


const Catalog = preload("res://scripts/campaign_mission_catalog.gd")
const VERSION := 1
const MISSION_ID := "first_supply"
const FIRST_VICTORY_MATERIALS := 3
const MAX_MATERIALS := Catalog.TOTAL_MATERIAL_BUDGET
const MAX_NEST_LEVEL := 2
const MAX_SERIAL := 2147483647
const MAX_CORE_ID := 2147483647
const MAX_JSON_DEPTH := 16
const MAX_JSON_NODES := 1000000
const MAX_TEXT_LENGTH := 1048576
const MAX_TIMESTAMP := 1000000000000.0
const MAX_STAT_VALUE := 1000000000000000.0
const OUTCOMES := ["victory", "failure", "retreat"]


static func fresh() -> Dictionary:
	return {
		"version": VERSION, "nest_level": 1, "materials": 0,
		"main_core_id": -1, "serial": 0, "completed": {},
		"active_mission": {}, "home_world": {}, "last_result": {}
	}


static func sanitize(raw: Variant) -> Dictionary:
	var clean := fresh()
	if not raw is Dictionary or _integer(raw.get("version", null), -1, -1, MAX_SERIAL) != VERSION:
		return clean
	clean["nest_level"] = _integer(raw.get("nest_level", 1), 1, 1, MAX_NEST_LEVEL)
	clean["materials"] = _integer(raw.get("materials", 0), 0, 0, MAX_MATERIALS)
	clean["main_core_id"] = _integer(raw.get("main_core_id", -1), -1, -1, MAX_CORE_ID)
	clean["serial"] = _integer(raw.get("serial", 0), 0, 0, MAX_SERIAL)
	var completed: Variant = raw.get("completed", {})
	if completed is Dictionary:
		for entry in Catalog.entries():
			var mission_id := String(entry["id"])
			if bool(entry["implemented"]) and typeof(completed.get(mission_id, null)) == TYPE_BOOL and completed[mission_id]:
				clean["completed"][mission_id] = true
	# Level 2 necessarily follows the first mission; repairing this flag never
	# fabricates materials, and prevents a broken flag from granting twice.
	if int(clean["nest_level"]) >= 2:
		clean["completed"][MISSION_ID] = true
	clean["last_result"] = _sanitize_result(raw.get("last_result", {}))
	if clean["last_result"].get("outcome", "") == "victory":
		clean["completed"][String(clean["last_result"]["mission_id"])] = true
	var last_attempt := int(clean["last_result"].get("attempt_id", 0))
	clean["serial"] = maxi(int(clean["serial"]), last_attempt)
	var active: Variant = raw.get("active_mission", {})
	if not active is Dictionary or active.is_empty():
		return clean
	var attempt_id := _attempt_id(active.get("attempt_id", null))
	var started: Variant = active.get("started_at", null)
	var active_id: Variant = active.get("id", null)
	if not Catalog.is_implemented(active_id) or not Catalog.is_unlocked(clean, active_id) or attempt_id <= last_attempt or attempt_id < int(clean["serial"]) or not _number_in_range(started, 0.0, MAX_TIMESTAMP):
		return clean
	var stats := _sanitize_stats(active.get("initial_stats", {}))
	var home := _copy_home(raw.get("home_world", {}))
	if home.is_empty() or not bool(stats["ok"]):
		return clean
	clean["serial"] = maxi(int(clean["serial"]), attempt_id)
	clean["active_mission"] = {
		"id": String(active_id), "attempt_id": attempt_id,
		"started_at": float(started), "initial_stats": stats["value"]
	}
	clean["home_world"] = home
	return clean


static func begin(state: Dictionary, home_world: Variant, now: Variant, initial_stats: Variant = {}, mission_id: String = MISSION_ID) -> bool:
	# Never overwrite even a damaged in-flight task. The save loader must
	# reject or recover that task before a new excursion may begin.
	if _integer(state.get("version", null), -1, -1, MAX_SERIAL) != VERSION or not state.get("active_mission", null) is Dictionary or not state["active_mission"].is_empty():
		return false
	var clean := sanitize(state)
	if not can_begin(clean, mission_id) or not _number_in_range(now, 0.0, MAX_TIMESTAMP):
		return false
	var home := _copy_home(home_world)
	var stats := _sanitize_stats(initial_stats)
	if home.is_empty() or not bool(stats["ok"]):
		return false
	var attempt_id := int(clean["serial"]) + 1
	clean["serial"] = attempt_id
	clean["active_mission"] = {
		"id": mission_id, "attempt_id": attempt_id,
		"started_at": float(now), "initial_stats": stats["value"]
	}
	clean["home_world"] = home
	_replace(state, clean)
	return true


static func settle(state: Dictionary, outcome: Variant) -> Dictionary:
	if typeof(outcome) != TYPE_STRING or not OUTCOMES.has(outcome):
		return _rejected("invalid_outcome")
	var clean := sanitize(state)
	if clean["active_mission"].is_empty():
		return _rejected("no_active_mission")
	var attempt_id := int(clean["active_mission"]["attempt_id"])
	var mission_id := String(clean["active_mission"]["id"])
	var material_reward := 0
	if outcome == "victory" and not bool(clean["completed"].get(mission_id, false)):
		# Rewards belong to a stable mission ID, never to the displayed scene.
		# Reserve enough ledger capacity for the approved roster, while only
		# implemented missions may pay and each mission may pay once.
		material_reward = mini(Catalog.first_victory_materials(mission_id), MAX_MATERIALS - int(clean["materials"]))
		clean["materials"] = int(clean["materials"]) + material_reward
		clean["completed"][mission_id] = true
	var result := {
		"ok": true, "mission_id": mission_id, "attempt_id": attempt_id,
		"outcome": outcome, "reward": {"materials": material_reward},
		"home_world": clean["home_world"]
	}
	clean["last_result"] = {
		"mission_id": mission_id, "attempt_id": attempt_id,
		"outcome": outcome, "reward": {"materials": material_reward}
	}
	clean["active_mission"] = {}
	clean["home_world"] = {}
	_replace(state, clean)
	return result


static func upgrade(state: Dictionary) -> bool:
	if not state.get("active_mission", null) is Dictionary or not state["active_mission"].is_empty():
		return false
	var clean := sanitize(state)
	if not can_upgrade(clean):
		return false
	clean["materials"] = int(clean["materials"]) - FIRST_VICTORY_MATERIALS
	clean["nest_level"] = 2
	clean["completed"][MISSION_ID] = true
	_replace(state, clean)
	return true


static func can_begin(state: Dictionary, mission_id: String = MISSION_ID) -> bool:
	return _integer(state.get("version", null), -1, -1, MAX_SERIAL) == VERSION and Catalog.is_implemented(mission_id) and Catalog.is_unlocked(state, mission_id) and state.get("active_mission", null) is Dictionary and state["active_mission"].is_empty() and _integer(state.get("serial", MAX_SERIAL), MAX_SERIAL, 0, MAX_SERIAL) < MAX_SERIAL


static func can_upgrade(state: Dictionary) -> bool:
	return state.get("active_mission", null) is Dictionary and state["active_mission"].is_empty() and _integer(state.get("nest_level", 1), 1, 1, MAX_NEST_LEVEL) == 1 and _integer(state.get("materials", 0), 0, 0, MAX_MATERIALS) >= FIRST_VICTORY_MATERIALS


static func next_mission_preview(state: Dictionary) -> Dictionary:
	var clean := sanitize(state)
	var entries := Catalog.entries()
	for index in range(1, entries.size()):
		var entry: Dictionary = entries[index]
		if not bool(clean["completed"].get(entry["id"], false)):
			entry["unlocked"] = Catalog.is_unlocked(clean, entry["id"])
			return entry
	return {}


static func recommended_mission_id(state: Dictionary) -> String:
	var clean := sanitize(state)
	var latest_playable := ""
	for entry in Catalog.entries():
		var mission_id := String(entry["id"])
		if not bool(entry["implemented"]) or not Catalog.is_unlocked(clean, mission_id):
			continue
		latest_playable = mission_id
		if not bool(clean["completed"].get(mission_id, false)):
			return mission_id
	return latest_playable


static func _replace(target: Dictionary, source: Dictionary) -> void:
	target.clear()
	for key in source:
		target[key] = source[key]


static func _rejected(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "reward": {"materials": 0}, "home_world": {}}


static func _integer(value: Variant, fallback: int, minimum: int, maximum: int) -> int:
	# Integral JSON floats are accepted, but booleans, strings and fractional
	# values are not coerced into campaign counters.
	if typeof(value) == TYPE_INT:
		return clampi(value, minimum, maximum)
	if typeof(value) == TYPE_FLOAT and is_finite(value) and value == floor(value):
		return int(clampf(value, float(minimum), float(maximum)))
	return fallback


static func _number_in_range(value: Variant, minimum: float, maximum: float) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum


static func _attempt_id(value: Variant) -> int:
	if not _number_in_range(value, 1.0, float(MAX_SERIAL)) or float(value) != floor(float(value)):
		return -1
	return int(value)


static func _sanitize_stats(raw: Variant) -> Dictionary:
	if not raw is Dictionary or raw.size() > 64:
		return {"ok": false, "value": {}}
	var stats := {"organic_absorbed": 0.0, "mineral_absorbed": 0.0, "mature_hypha_length": 0.0}
	for key in raw:
		if typeof(key) != TYPE_STRING or key.length() > 128 or not _number_in_range(raw[key], 0.0, MAX_STAT_VALUE):
			return {"ok": false, "value": {}}
		stats[key] = float(raw[key])
	return {"ok": true, "value": stats}


static func _sanitize_result(raw: Variant) -> Dictionary:
	if not raw is Dictionary or raw.is_empty():
		return {}
	var attempt_id := _attempt_id(raw.get("attempt_id", null))
	var outcome: Variant = raw.get("outcome", null)
	var mission_id: Variant = raw.get("mission_id", null)
	if not Catalog.is_implemented(mission_id) or attempt_id < 1 or typeof(outcome) != TYPE_STRING or not OUTCOMES.has(outcome):
		return {}
	var reward: Variant = raw.get("reward", {})
	var materials := 0
	if outcome == "victory" and reward is Dictionary:
		materials = _integer(reward.get("materials", 0), 0, 0, Catalog.first_victory_materials(mission_id))
	return {"mission_id": String(mission_id), "attempt_id": attempt_id, "outcome": outcome, "reward": {"materials": materials}}


static func _copy_home(raw: Variant) -> Dictionary:
	if not raw is Dictionary or raw.is_empty():
		return {}
	var budget := {"remaining": MAX_JSON_NODES, "ok": true}
	var copied: Variant = _copy_json(raw, 0, budget)
	if not bool(budget["ok"]) or not copied is Dictionary:
		return {}
	return copied


static func _copy_json(raw: Variant, depth: int, budget: Dictionary) -> Variant:
	budget["remaining"] = int(budget["remaining"]) - 1
	if not bool(budget["ok"]) or int(budget["remaining"]) < 0 or depth > MAX_JSON_DEPTH:
		budget["ok"] = false
		return null
	match typeof(raw):
		TYPE_NIL, TYPE_BOOL, TYPE_INT:
			return raw
		TYPE_FLOAT:
			if is_finite(raw):
				return raw
		TYPE_STRING:
			if raw.length() <= MAX_TEXT_LENGTH:
				return raw
		TYPE_ARRAY:
			if raw.size() > int(budget["remaining"]):
				budget["ok"] = false
				return null
			var result: Array = []
			for item in raw:
				result.append(_copy_json(item, depth + 1, budget))
				if not bool(budget["ok"]):
					return null
			return result
		TYPE_DICTIONARY:
			if raw.size() > int(budget["remaining"]):
				budget["ok"] = false
				return null
			var result := {}
			for key in raw:
				if typeof(key) != TYPE_STRING or key.length() > MAX_TEXT_LENGTH:
					budget["ok"] = false
					return null
				if key == "campaign" or key == "campaign_state":
					continue
				result[key] = _copy_json(raw[key], depth + 1, budget)
				if not bool(budget["ok"]):
					return null
			return result
	budget["ok"] = false
	return null
