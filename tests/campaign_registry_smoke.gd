extends SceneTree

const Campaign = preload("res://scripts/campaign_state.gd")
const Catalog = preload("res://scripts/campaign_mission_catalog.gd")
var failures: Array[String] = []


func _initialize() -> void:
	_test_catalog()
	_test_unlocks_and_legacy_migration()
	_test_isolated_rewards_and_replays()
	_test_remote_roundtrip_and_restore()
	_test_rejected_mission_ids()
	_test_result_repair_and_versions()
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPAIGN_REGISTRY_FAIL: " + failure)
		quit(1)
		return
	print("CAMPAIGN_REGISTRY_OK roster=9 implemented=9 legacy_v1=true unlocks=true per_mission_rewards=true exactly_once=true malformed_ids=true")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _home() -> Dictionary:
	return {"version": 1, "organic": 123.125, "mineral": 14.25, "dna": 6, "world_scene_id": "home_nest", "cores": [{"x": 0.0, "y": 0.0}]}


func _ready_for_second() -> Dictionary:
	var state := Campaign.fresh()
	Campaign.begin(state, _home(), 100.0)
	Campaign.settle(state, "victory")
	Campaign.upgrade(state)
	return state


func _test_catalog() -> void:
	var entries := Catalog.entries()
	var ids := ["first_supply", "remote_pantry", "first_contact", "substrate_race", "lost_network", "two_fronts", "toxic_frontier", "boundary_counterattack", "stable_colony"]
	_expect(entries.size() == 9, "approved roster includes six expeditions and three challenges")
	var rewards := 0
	var expeditions := 0
	var challenges := 0
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		_expect(entry["id"] == ids[index] and entry["order"] == index + 1, "stable mission ID and order")
		_expect(entry["implemented"] == true, "every approved mission is now implemented")
		_expect(entry["title_key"] == String(entry["id"]) + "_title", "catalog resolves the actual localized title key")
		_expect(entry["required_nest_level"] == [1, 2, 2, 3, 3, 3, 4, 4, 4][index], "each act requires its nest upgrade")
		rewards += int(entry["first_victory_materials"])
		expeditions += 1 if entry["kind"] == "expedition" else 0
		challenges += 1 if entry["kind"] == "nest_challenge" else 0
	_expect(expeditions == 6 and challenges == 3, "roster distinguishes expeditions from nest challenges")
	_expect(rewards == Campaign.MAX_MATERIALS and rewards == 27 and Campaign.MAX_NEST_LEVEL == 4, "all nine first wins fund the four-level nest and optional branches")
	entries[0]["implemented"] = false
	var copy := Catalog.mission("remote_pantry")
	copy["prerequisite"] = ""
	_expect(Catalog.is_implemented("first_supply") and Catalog.mission("remote_pantry")["prerequisite"] == "first_supply", "catalog callers cannot mutate shared definitions")
	_expect(Catalog.mission("missing").is_empty() and Catalog.mission(null).is_empty(), "unknown and malformed catalog IDs are rejected")


func _test_unlocks_and_legacy_migration() -> void:
	var state := Campaign.fresh()
	_expect(Campaign.can_begin(state) and not Campaign.can_begin(state, "remote_pantry"), "new campaign only starts first supply")
	var preview := Campaign.next_mission_preview(state)
	_expect(preview["id"] == "remote_pantry" and preview["implemented"] and not preview["unlocked"], "real second task is visible but initially locked")
	_expect(Campaign.recommended_mission_id(state) == "first_supply", "fresh campaign recommends first supply")
	Campaign.begin(state, _home(), 10.0)
	Campaign.settle(state, "victory")
	_expect(not Campaign.can_begin(state, "remote_pantry"), "first victory alone does not bypass the nest upgrade")
	_expect(Campaign.recommended_mission_id(state) == "first_supply", "available completed mission can be replayed while upgrade is pending")
	Campaign.upgrade(state)
	_expect(Campaign.can_begin(state, "remote_pantry") and Campaign.recommended_mission_id(state) == "remote_pantry", "level two plus first victory unlocks the second mission")
	var legacy := Campaign.fresh()
	legacy["nest_level"] = 2
	legacy["materials"] = 0
	legacy["serial"] = 1
	var loaded := Campaign.sanitize(JSON.parse_string(JSON.stringify(legacy)))
	_expect(loaded["version"] == 1 and loaded["completed"].get("first_supply", false) and not loaded["completed"].get("remote_pantry", false), "old level-two save repairs only its historical first victory")
	_expect(loaded["materials"] == 0 and Campaign.can_begin(loaded, "remote_pantry"), "legacy migration invents no materials and enables the new mission")
	var dishonest := Campaign.fresh()
	dishonest["nest_level"] = 2
	_expect(not Catalog.is_unlocked(dishonest, "remote_pantry"), "raw catalog unlock requires both nest level and first victory")


func _test_isolated_rewards_and_replays() -> void:
	var state := _ready_for_second()
	_expect(Campaign.begin(state, _home(), 200.0, {}, "remote_pantry"), "second mission begins through explicit stable ID")
	_expect(state["active_mission"]["id"] == "remote_pantry", "active ledger records the selected mission")
	var result := Campaign.settle(state, "victory")
	_expect(result["mission_id"] == "remote_pantry" and result["reward"]["materials"] == 3 and state["materials"] == 3, "second victory pays its own reward")
	_expect(state["completed"].get("first_supply", false) and state["completed"].get("remote_pantry", false), "both completion entries survive")
	_expect(state["last_result"]["mission_id"] == "remote_pantry", "result history retains second mission identity")
	var preview := Campaign.next_mission_preview(state)
	_expect(preview["id"] == "first_contact" and preview["implemented"] and preview["unlocked"], "completed transport task unlocks the implemented first nest challenge")
	_expect(Campaign.can_begin(state, "first_contact"), "first challenge becomes playable only after its prerequisites")
	_expect(Campaign.recommended_mission_id(state) == "first_contact", "next uncompleted playable task is recommended")
	var paid := state.duplicate(true)
	_expect(not Campaign.settle(state, "victory")["ok"] and state == paid, "double settlement leaves the ledger untouched")
	for mission_id in ["first_supply", "remote_pantry"]:
		_expect(Campaign.begin(state, _home(), 201.0, {}, mission_id), "each completed mission can replay independently")
		result = Campaign.settle(state, "victory")
		_expect(result["mission_id"] == mission_id and result["reward"]["materials"] == 0 and state["materials"] == 3, "replaying either mission never pays again")
	state = _ready_for_second()
	state["materials"] = 3
	Campaign.begin(state, _home(), 205.0, {}, "remote_pantry")
	result = Campaign.settle(state, "victory")
	_expect(result["reward"]["materials"] == 3 and state["materials"] == 6, "existing materials no longer swallow a second first-win reward")


func _test_remote_roundtrip_and_restore() -> void:
	for outcome in ["retreat", "failure", "victory"]:
		var state := _ready_for_second()
		var home := _home()
		var stats := {"organic_cargo_returned": 12.5, "mineral_cargo_returned": 1.25}
		_expect(Campaign.begin(state, home, 300.0, stats, "remote_pantry"), "second mission begins with transport baselines")
		state = Campaign.sanitize(JSON.parse_string(JSON.stringify(state)))
		_expect(state["active_mission"]["id"] == "remote_pantry" and state["active_mission"]["initial_stats"]["organic_cargo_returned"] == 12.5, "second mission and transport baseline survive JSON save/load")
		var result := Campaign.settle(state, outcome)
		_expect(result["ok"] and result["mission_id"] == "remote_pantry" and JSON.parse_string(JSON.stringify(result["home_world"])) == JSON.parse_string(JSON.stringify(home)), "every second-mission outcome restores the same isolated home snapshot")
		_expect(state["completed"].get("remote_pantry", false) == (outcome == "victory"), "only victory completes the second mission")


func _test_rejected_mission_ids() -> void:
	for mission_id in ["first_contact", "stable_colony", "missing", "res://other.gd", ""]:
		var state := _ready_for_second()
		var before := state.duplicate(true)
		_expect(not Campaign.begin(state, _home(), 400.0, {}, mission_id) and state == before, "locked or unknown mission cannot begin or mutate state")
	for bad_id in ["missing", "first_contact", null, true, 2, [], {}]:
		var state := _ready_for_second()
		Campaign.begin(state, _home(), 410.0, {}, "remote_pantry")
		state["active_mission"]["id"] = bad_id
		var clean := Campaign.sanitize(state)
		_expect(clean["active_mission"].is_empty() and clean["home_world"].is_empty() and clean["completed"].get("first_supply", false), "invalid active mission ID clears activity but preserves ledger")
		_expect(not Campaign.settle(state, "victory")["ok"], "invalid active IDs cannot receive rewards")
	var malformed := _ready_for_second()
	malformed["completed"] = {"first_supply": true, "remote_pantry": "true", "first_contact": true, "missing": true}
	var clean := Campaign.sanitize(malformed)
	_expect(clean["completed"] == {"first_supply": true, "first_contact": true}, "completion map preserves known boolean entries and rejects unknown IDs or non-boolean flags")


func _test_result_repair_and_versions() -> void:
	var state := Campaign.fresh()
	state["last_result"] = {"mission_id": "remote_pantry", "attempt_id": 2, "outcome": "victory", "reward": {"materials": 999}}
	state["materials"] = 3
	var clean := Campaign.sanitize(state)
	_expect(clean["completed"].get("remote_pantry", false) and not clean["completed"].get("first_supply", false), "second historical victory never gets misattributed to the first mission")
	_expect(clean["last_result"]["reward"]["materials"] == 3 and clean["materials"] == 3, "history clamps one mission reward without adding materials")
	for mission_id in ["missing", "res://scenes/Main.tscn"]:
		state["last_result"]["mission_id"] = mission_id
		clean = Campaign.sanitize(state)
		_expect(clean["last_result"].is_empty() and clean["completed"].is_empty(), "unknown result cannot fabricate completion")
	for version in [2, 0, "1", true]:
		state = _ready_for_second()
		state["version"] = version
		var before := state.duplicate(true)
		_expect(Campaign.sanitize(state) == Campaign.fresh(), "unsupported campaign version does not enter a permissive migration")
		_expect(not Campaign.can_begin(state, "remote_pantry") and not Campaign.begin(state, _home(), 500.0, {}, "remote_pantry") and state == before, "begin rejects unsupported versions without resetting data")
