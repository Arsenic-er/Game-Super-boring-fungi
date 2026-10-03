extends SceneTree


const Campaign = preload("res://scripts/campaign_state.gd")
var failures: Array[String] = []


func _initialize() -> void:
	_test_fresh_and_roundtrip()
	_test_first_victory_and_replay()
	_test_retreat_failure_and_upgrade()
	_test_snapshot_integrity()
	_test_malformed_data()
	_test_attempt_replay_and_exhaustion()
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPAIGN_STATE_FAIL: " + failure)
		quit(1)
		return
	print("CAMPAIGN_STATE_OK fresh=true exactly_once=true retry=true upgrade=true full_snapshot=true json_roundtrip=true malformed=true")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _json_equal(left: Variant, right: Variant) -> bool:
	# JSON legitimately changes integral world numbers from int to float.
	return JSON.parse_string(JSON.stringify(left)) == JSON.parse_string(JSON.stringify(right))


func _home() -> Dictionary:
	return {"version": 1, "saved_at": 1234.5, "organic": 220.125, "mineral": 24.0, "dna": 7, "cores": [{"x": 0.0, "y": 0.0}], "rng_seed": "9223372036854775807", "rng_state": "18446744073709551615", "simulation_clocks": {"bacteria": 0.75, "growth": 0.25}, "hotspot_catalog": [{"id": "organic_west", "kind": 0}]}


func _test_fresh_and_roundtrip() -> void:
	var state := Campaign.fresh()
	_expect(state["version"] == 1 and state["nest_level"] == 1 and state["materials"] == 0 and state["main_core_id"] == -1, "fresh campaign has no retroactive rewards")
	_expect(Campaign.sanitize(null) == state and Campaign.sanitize({"chapter_complete": true, "goals_claimed": {"rival_colony": true}}) == state, "missing campaign does not translate old goal rewards")
	_expect(Campaign.sanitize(JSON.parse_string(JSON.stringify(state))) == state, "fresh campaign survives JSON number conversion")
	_expect(not Campaign.upgrade(state), "no free nest upgrade")
	_expect(not Campaign.next_mission_preview(state)["unlocked"] and Campaign.next_mission_preview(state)["implemented"], "implemented second task remains locked until first victory and nest upgrade")


func _test_first_victory_and_replay() -> void:
	var state := Campaign.fresh()
	state["main_core_id"] = 0
	var home := _home()
	_expect(Campaign.begin(state, home, 1300.0), "start first mission")
	_expect(state["serial"] == 1 and state["active_mission"]["attempt_id"] == 1 and state["active_mission"]["id"] == Campaign.MISSION_ID, "first attempt uses monotonic identity")
	_expect(state["active_mission"]["initial_stats"]["organic_absorbed"] == 0.0, "independent task defaults to zero, not home lifetime totals")
	var pending := state.duplicate(true)
	_expect(not Campaign.begin(state, home, 1301.0) and state == pending, "cannot replace an active mission")
	var invalid := Campaign.settle(state, "aborted")
	_expect(not invalid["ok"] and state == pending, "invalid outcome changes nothing")
	state = Campaign.sanitize(JSON.parse_string(JSON.stringify(state)))
	_expect(not state["active_mission"].is_empty(), "active task survives JSON save/load")
	var result := Campaign.settle(state, "victory")
	_expect(result["ok"] and result["reward"]["materials"] == 3 and _json_equal(result["home_world"], home), "first victory returns the original world and exactly three materials")
	_expect(state["materials"] == 3 and state["completed"][Campaign.MISSION_ID] and state["active_mission"].is_empty() and state["home_world"].is_empty(), "settlement commits materials and clears the return snapshot")
	_expect(not state["last_result"].has("home_world"), "result history cannot recursively retain whole worlds")
	var committed := state.duplicate(true)
	result = Campaign.settle(state, "victory")
	_expect(not result["ok"] and result["reward"]["materials"] == 0 and state == committed, "double settlement cannot pay twice")
	_expect(Campaign.begin(state, home, 1400.0), "completed mission may be replayed")
	_expect(state["serial"] == 2, "retry increments serial")
	result = Campaign.settle(state, "victory")
	_expect(result["reward"]["materials"] == 0 and state["materials"] == 3, "replay victory cannot farm progression materials")


func _test_retreat_failure_and_upgrade() -> void:
	var state := Campaign.fresh()
	for outcome in ["failure", "retreat"]:
		_expect(Campaign.begin(state, _home(), 1500.0), "retry after " + outcome)
		var result := Campaign.settle(state, outcome)
		_expect(result["ok"] and result["home_world"] == _home() and result["reward"]["materials"] == 0 and state["materials"] == 0, "failure/retreat restore home without progression payment")
		_expect(not state["completed"].has(Campaign.MISSION_ID), "unsuccessful attempt is not completed")
	_expect(Campaign.begin(state, _home(), 1600.0, {"organic_absorbed": 1.25, "mature_hypha_length": 15.0}), "explicit mission baseline accepted")
	_expect(state["active_mission"]["initial_stats"]["organic_absorbed"] == 1.25, "explicit baseline retained")
	Campaign.settle(state, "victory")
	_expect(Campaign.begin(state, _home(), 1700.0), "a material-bearing campaign can enter a replay")
	_expect(not Campaign.upgrade(state) and state["materials"] == 3, "upgrade is unavailable during an active mission")
	Campaign.settle(state, "retreat")
	_expect(state["materials"] == 3, "retreat cannot erase already committed materials")
	_expect(Campaign.upgrade(state) and state["materials"] == 0 and state["nest_level"] == 2, "upgrade spends exactly three materials")
	_expect(not Campaign.upgrade(state), "nest does not advance past implemented level two")
	_expect(Campaign.next_mission_preview(state)["unlocked"] and Campaign.next_mission_preview(state)["implemented"], "level two unlocks the implemented remote-pantry mission")
	_expect(Campaign.sanitize(JSON.parse_string(JSON.stringify(state))) == state, "completed/leveled campaign survives JSON roundtrip")


func _test_snapshot_integrity() -> void:
	var home := _home()
	var catalog: Array = []
	for i in range(3147):
		catalog.append({"id": i, "x": float(i), "y": -float(i), "amount": 1.25, "alive": true})
	home["resource_catalog"] = catalog
	home["campaign"] = {"home_world": {"campaign": {"home_world": {}}}}
	home["nested"] = {"campaign_state": {"bad": true}, "retained": "runtime"}
	var state := Campaign.fresh()
	_expect(Campaign.begin(state, home, 1800.0), "a full 3147-resource snapshot fits the bounded copy")
	home["resource_catalog"][0]["amount"] = 999.0
	_expect(state["home_world"]["resource_catalog"][0]["amount"] == 1.25, "saved home is not aliased to caller data")
	_expect(not state["home_world"].has("campaign") and not state["home_world"]["nested"].has("campaign_state"), "campaign recursion is stripped at every depth")
	var restored := Campaign.sanitize(JSON.parse_string(JSON.stringify(state)))
	var result := Campaign.settle(restored, "retreat")
	_expect(result["ok"] and result["home_world"]["resource_catalog"].size() == 3147, "all resource entries survive a mission save roundtrip")
	_expect(result["home_world"]["rng_seed"] == "9223372036854775807" and result["home_world"]["rng_state"] == "18446744073709551615", "RNG string precision is not converted to floats")
	_expect(_json_equal(result["home_world"]["simulation_clocks"], home["simulation_clocks"]) and _json_equal(result["home_world"]["hotspot_catalog"], home["hotspot_catalog"]) and result["home_world"]["nested"]["retained"] == "runtime", "runtime fields are retained rather than whitelisted away")


func _test_malformed_data() -> void:
	for value in [null, true, "1", [], {"version": 2}]:
		_expect(Campaign.sanitize(value) == Campaign.fresh(), "reject unsupported campaign root/version")
	var malformed := Campaign.fresh()
	malformed["nest_level"] = "2"
	malformed["materials"] = NAN
	malformed["main_core_id"] = true
	malformed["serial"] = INF
	malformed["completed"] = {Campaign.MISSION_ID: "true", "unknown_task": true}
	var clean := Campaign.sanitize(malformed)
	_expect(clean["nest_level"] == 1 and clean["materials"] == 0 and clean["main_core_id"] == -1 and clean["serial"] == 0 and clean["completed"].is_empty(), "reject strings, booleans and nonfinite counters")
	malformed["nest_level"] = 900
	malformed["materials"] = 900
	clean = Campaign.sanitize(malformed)
	_expect(clean["nest_level"] == 2 and clean["materials"] == Campaign.MAX_MATERIALS, "finite counters stay within nest and full-roster ledger boundaries")
	_expect(clean["completed"][Campaign.MISSION_ID], "level-two repair prevents a missing completion flag from rewarding again")
	malformed["materials"] = -8
	_expect(Campaign.sanitize(malformed)["materials"] == 0, "negative material counter clamps to zero")
	malformed["materials"] = 1.5
	_expect(Campaign.sanitize(malformed)["materials"] == 0, "fractional materials are not rounded into spendable progression")
	var state := Campaign.fresh()
	for invalid_now in [NAN, INF, -1.0, "123", true]:
		_expect(not Campaign.begin(state, _home(), invalid_now), "begin rejects invalid timestamp")
	var bad_home := _home()
	bad_home["organic"] = INF
	_expect(not Campaign.begin(state, bad_home, 1900.0), "nonfinite world data does not create an unrestorable mission")
	_expect(not Campaign.begin(state, _home(), 1900.0, {"organic_absorbed": NAN}), "nonfinite initial statistics are rejected")
	var cyclic := _home()
	cyclic["self"] = cyclic
	_expect(not Campaign.begin(state, cyclic, 1900.0), "cyclic homes terminate at a bounded depth")
	cyclic.erase("self")
	var too_deep: Dictionary = {"leaf": 1}
	for _i in range(18):
		too_deep = {"nested": too_deep}
	_expect(not Campaign.begin(state, too_deep, 1900.0), "overdeep snapshots are rejected")
	var oversized: Array = []
	oversized.resize(Campaign.MAX_JSON_NODES + 1)
	_expect(not Campaign.begin(state, {"catalog": oversized}, 1900.0), "node budget rejects oversized containers without iterating a million entries")
	_expect(state == Campaign.fresh(), "failed begin never mutates the live campaign")


func _test_attempt_replay_and_exhaustion() -> void:
	var state := Campaign.fresh()
	Campaign.begin(state, _home(), 2000.0)
	var first_attempt: Dictionary = state["active_mission"].duplicate(true)
	Campaign.settle(state, "victory")
	var missing_flag := state.duplicate(true)
	missing_flag["completed"] = {}
	var repaired := Campaign.sanitize(missing_flag)
	_expect(repaired["completed"].get(Campaign.MISSION_ID, false) and repaired["materials"] == 3, "a recorded victory repairs its completion flag without paying a new reward")
	Campaign.begin(repaired, _home(), 2001.0)
	_expect(Campaign.settle(repaired, "victory")["reward"]["materials"] == 0, "historical victory blocks reward farming after a damaged completion flag")
	state["active_mission"] = first_attempt
	state["home_world"] = _home()
	var clean := Campaign.sanitize(state)
	_expect(clean["active_mission"].is_empty() and clean["home_world"].is_empty() and clean["materials"] == 3, "an already-settled attempt cannot be resurrected by stale active data")
	_expect(not Campaign.settle(state, "victory")["ok"], "stale double settlement is rejected")
	state = clean
	Campaign.begin(state, _home(), 2100.0)
	state["home_world"]["organic"] = NAN
	clean = Campaign.sanitize(state)
	_expect(clean["active_mission"].is_empty() and clean["materials"] == 3 and clean["completed"][Campaign.MISSION_ID], "invalid active snapshot clears only activity, preserving the material ledger for loader backup recovery")
	_expect(not Campaign.begin(state, _home(), 2101.0) and not Campaign.upgrade(state), "a damaged in-flight task cannot be silently overwritten or upgraded before loader recovery")
	_expect(state["materials"] == 3 and not state["active_mission"].is_empty() and is_nan(state["home_world"]["organic"]), "refusing to mutate damaged activity preserves the original recovery data")
	state = Campaign.fresh()
	state["serial"] = Campaign.MAX_SERIAL
	_expect(not Campaign.begin(state, _home(), 2200.0) and state["serial"] == Campaign.MAX_SERIAL, "attempt serial never wraps or reuses an old identity")
	for bad_id in [0, -1, 1.5, INF, NAN, true, "1", Campaign.MAX_SERIAL + 1]:
		state = Campaign.fresh()
		Campaign.begin(state, _home(), 2300.0)
		state["active_mission"]["attempt_id"] = bad_id
		_expect(Campaign.sanitize(state)["active_mission"].is_empty(), "invalid attempt identity is rejected, not clamped into a real attempt")
	state = Campaign.fresh()
	Campaign.begin(state, _home(), 2400.0)
	state["serial"] = 2
	_expect(Campaign.sanitize(state)["active_mission"].is_empty(), "active attempt older than the durable serial is rejected")
