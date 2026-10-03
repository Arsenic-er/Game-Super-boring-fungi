extends SceneTree

# Ledger-only fixtures. Scene behavior and actual branch effects have separate
# integration tests; no normal/developer save slots or runtime worlds are touched.
const Campaign = preload("res://scripts/campaign_state.gd")
const Catalog = preload("res://scripts/campaign_mission_catalog.gd")
const IDS := ["first_supply", "remote_pantry", "first_contact", "substrate_race", "lost_network", "two_fronts", "toxic_frontier", "boundary_counterattack", "stable_colony"]
const LEVELS := [1, 2, 2, 3, 3, 3, 4, 4, 4]
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_test_full_chapter_accounting()
	_test_greedy_optional_spending()
	_test_upgrade_gates_and_budget_edges()
	_test_branch_sanitization_and_queries()
	_test_legacy_active_migration()
	_test_invalid_edits()
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPAIGN_PROGRESSION_FAIL: " + failure)
		quit(1)
		return
	print("CAMPAIGN_PROGRESSION_OK checks=%d missions=9 rewards=27 mandatory=15 optional=12 branches=3x2 greedy-orders=6 legacy-active=M1+M2 versions=1" % checks)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _home() -> Dictionary:
	return {"version": 1, "world_scene_id": "home_nest", "saved_at": 50.0, "organic": 100.125, "mineral": 3.5, "dna": 17, "cores": [{"id": 0, "biomass": 76.125}]}


func _same_json(left: Variant, right: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(left)) == JSON.parse_string(JSON.stringify(right))


func _win(state: Dictionary, mission_id: String) -> Dictionary:
	_expect(Campaign.begin(state, _home(), 1000.0 + float(state["serial"]), {}, mission_id), mission_id + " can begin when unlocked")
	var result := Campaign.settle(state, "victory")
	_expect(result.get("ok", false) and result.get("mission_id", "") == mission_id and result["reward"]["materials"] == 3, mission_id + " pays exactly its first-win reward")
	return result


func _upgrade_after(state: Dictionary, index: int) -> void:
	if index not in [0, 2, 5]:
		return
	var old_level := int(state["nest_level"])
	var cost := Campaign.upgrade_cost(state)
	var before := int(state["materials"])
	_expect(cost == (3 if index == 0 else 6) and Campaign.can_upgrade(state), "mandatory upgrade is fully funded at milestone %d" % index)
	_expect(Campaign.upgrade(state) and int(state["nest_level"]) == old_level + 1 and int(state["materials"]) == before - cost, "mandatory upgrade spends exact cost and advances one level")


func _test_full_chapter_accounting() -> void:
	var state := Campaign.fresh()
	var total_reward := 0
	_expect(Campaign.required_material_reserve(state) == 15 and not Campaign.chapter_completed(state), "fresh campaign reserves all 15 required materials and is incomplete")
	for index in range(IDS.size()):
		var mission_id: String = IDS[index]
		_expect(int(state["nest_level"]) == LEVELS[index] and Catalog.is_unlocked(state, mission_id), mission_id + " requires its act's real nest level")
		for outcome in ["failure", "retreat"]:
			var before := state.duplicate(true)
			_expect(Campaign.begin(state, _home(), 100.0 + state["serial"], {}, mission_id), mission_id + " starts before " + outcome)
			var active_before := state.duplicate(true)
			_expect(not Campaign.can_upgrade(state) and not Campaign.upgrade(state), "active task cannot upgrade persistent nest")
			for branch_id in Campaign.BRANCH_IDS:
				_expect(not Campaign.can_purchase_branch(state, branch_id) and not Campaign.purchase_branch(state, branch_id), "active task cannot purchase " + branch_id)
			_expect(state == active_before, "rejected persistent edits never mutate active task")
			state = Campaign.sanitize(JSON.parse_string(JSON.stringify(state)))
			_expect(_same_json(state, active_before), "every mission and challenge roundtrips while active")
			var failed := Campaign.settle(state, outcome)
			_expect(failed["ok"] and failed["reward"]["materials"] == 0 and _same_json(failed["home_world"], _home()), "failure/retreat restore original home without materials")
			_expect(state["completed"] == before["completed"] and state["materials"] == before["materials"] and state["branches"] == before["branches"], "failed task preserves all progression")
		var result := _win(state, mission_id)
		total_reward += int(result["reward"]["materials"])
		_expect(Campaign.chapter_completed(state) == (index == IDS.size() - 1), "only the final victory completes the chapter")
		var settled := state.duplicate(true)
		_expect(not Campaign.settle(state, "victory")["ok"] and state == settled, "settlement is exactly once for " + mission_id)
		_upgrade_after(state, index)
	_expect(total_reward == 27 and state["materials"] == 12 and state["nest_level"] == 4 and state["completed"].size() == 9, "all nine rewards minus 15 mandatory materials leave exactly 12 optional materials")
	_expect(Campaign.upgrade_cost(state) == 0 and not Campaign.can_upgrade(state) and not Campaign.upgrade(state), "level four is the actual nest cap")
	_expect(Campaign.next_mission_preview(state).is_empty() and Campaign.recommended_mission_id(state) == "stable_colony", "completed chapter has no phantom next mission and keeps final replay available")
	for mission_id in IDS:
		_expect(Campaign.begin(state, _home(), 2000.0 + state["serial"], {}, mission_id), "completed task can replay: " + mission_id)
		var result := Campaign.settle(state, "victory")
		_expect(result["reward"]["materials"] == 0 and state["materials"] == 12 and Campaign.chapter_completed(state), "replay cannot repeat any of the nine rewards")
	for branch_id in Campaign.BRANCH_IDS:
		for level in range(1, 3):
			_expect(Campaign.purchase_branch(state, branch_id) and Campaign.branch_level(state, branch_id) == level, "remaining materials fund " + branch_id + " level " + str(level))
		var maxed := state.duplicate(true)
		_expect(not Campaign.can_purchase_branch(state, branch_id) and not Campaign.purchase_branch(state, branch_id) and state == maxed, "branch cannot exceed level two")
	_expect(state["materials"] == 0 and state["branches"] == {"transport": 2, "resilience": 2, "defense": 2}, "all six optional purchases spend exactly the remaining 12 materials")
	_expect(_same_json(Campaign.sanitize(JSON.parse_string(JSON.stringify(state))), state), "completed ledger and all branches roundtrip")


func _test_greedy_optional_spending() -> void:
	var priorities := [
		["transport", "resilience", "defense"], ["transport", "defense", "resilience"],
		["resilience", "transport", "defense"], ["resilience", "defense", "transport"],
		["defense", "transport", "resilience"], ["defense", "resilience", "transport"]
	]
	for priority in priorities:
		var state := Campaign.fresh()
		var purchases := 0
		for index in range(IDS.size()):
			_win(state, IDS[index])
			for branch_id in priority:
				while Campaign.can_purchase_branch(state, branch_id):
					var before := int(state["materials"])
					var reserve := Campaign.required_material_reserve(state)
					_expect(Campaign.purchase_branch(state, branch_id), "greedy optional purchase succeeds")
					purchases += 1
					_expect(int(state["materials"]) == before - 2 and int(state["materials"]) >= reserve, "greedy spending always leaves every unpaid upgrade funded")
			_upgrade_after(state, index)
		_expect(Campaign.chapter_completed(state) and state["nest_level"] == 4 and purchases == 6 and state["materials"] == 0, "every branch-priority order finishes the chapter with all six upgrades and no soft lock")


func _test_upgrade_gates_and_budget_edges() -> void:
	for level in [1, 2, 3, 4]:
		var state := Campaign.fresh()
		state["nest_level"] = level
		state["materials"] = 27
		var before := state.duplicate(true)
		_expect(not Campaign.can_upgrade(state) and not Campaign.upgrade(state) and state == before, "materials alone cannot bypass mandatory completion at level %d" % level)
		if level < 4:
			var prerequisite: String = ["first_supply", "first_contact", "two_fronts"][level - 1]
			state["completed"][prerequisite] = true
			var cost := Campaign.upgrade_cost(state)
			state["materials"] = cost - 1
			_expect(not Campaign.can_upgrade(state) and not Campaign.upgrade(state), "one material below upgrade cost is insufficient")
			state["materials"] = cost
			_expect(Campaign.can_upgrade(state) and Campaign.upgrade(state) and state["materials"] == 0, "exact upgrade cost is sufficient with prerequisite")
		state = Campaign.fresh()
		state["nest_level"] = level
		var reserve: int = [15, 12, 6, 0][level - 1]
		_expect(Campaign.required_material_reserve(state) == reserve, "reserve includes all remaining mandatory payments")
		state["materials"] = reserve + 1
		before = state.duplicate(true)
		_expect(not Campaign.can_purchase_branch(state, "transport") and not Campaign.purchase_branch(state, "transport") and state == before, "one optional material cannot consume mandatory budget")
		state["materials"] = reserve + 2
		_expect(Campaign.can_purchase_branch(state, "transport") and Campaign.purchase_branch(state, "transport") and state["materials"] == reserve and Campaign.branch_level(state, "transport") == 1, "exact surplus buys a branch and leaves full reserve")
		_expect(not Campaign.can_purchase_branch(state, "resilience"), "reserved materials are not available to another branch")
	var state := Campaign.fresh()
	state["nest_level"] = 2
	state["materials"] = 27
	state["completed"] = {"first_supply": true, "first_contact": true}
	_expect(not Catalog.is_unlocked(state, "substrate_race"), "first challenge completion alone cannot bypass nest level three")
	state["nest_level"] = 3
	state["completed"]["two_fronts"] = true
	_expect(not Catalog.is_unlocked(state, "toxic_frontier"), "second challenge completion alone cannot bypass nest level four")


func _test_branch_sanitization_and_queries() -> void:
	var legacy := Campaign.fresh()
	legacy.erase("branches")
	_expect(Campaign.sanitize(legacy)["branches"] == {"transport": 0, "resilience": 0, "defense": 0}, "old saves receive zero branches without payment or free levels")
	for raw in [null, [], true, "transport"]:
		var state := Campaign.fresh()
		state["branches"] = raw
		_expect(Campaign.sanitize(state)["branches"] == Campaign.fresh()["branches"], "malformed branch roots reset only branch values")
	var malformed := Campaign.fresh()
	malformed["branches"] = {"transport": 900, "resilience": -1, "defense": 1.5, "unknown": 2}
	var clean := Campaign.sanitize(malformed)
	_expect(clean["branches"] == {"transport": 2, "resilience": 0, "defense": 0}, "known branch values clamp while fractional and unknown entries are rejected")
	for bad in [true, "2", NAN, INF, -INF]:
		malformed["branches"]["transport"] = bad
		_expect(Campaign.branch_level(malformed, "transport") == 0, "branch query rejects boolean, string and nonfinite levels")
	malformed["branches"] = {"transport": 1.0, "resilience": 2.0, "defense": 0.0}
	clean = Campaign.sanitize(malformed)
	_expect(clean["branches"] == {"transport": 1, "resilience": 2, "defense": 0}, "JSON integral floats preserve branch levels")
	var before := malformed.duplicate(true)
	for branch_id in ["transport", "resilience", "defense", "unknown"]:
		Campaign.branch_level(malformed, branch_id)
	Campaign.upgrade_cost(malformed)
	Campaign.required_material_reserve(malformed)
	Campaign.chapter_completed(malformed)
	_expect(malformed == before, "all progression queries are read-only")
	for flag in [true, false, "true", 1, null]:
		var state := Campaign.fresh()
		state["completed"]["stable_colony"] = flag
		_expect(Campaign.chapter_completed(state) == (typeof(flag) == TYPE_BOOL and flag), "chapter completion requires a real final-win boolean")
	for level in [2, 3, 4]:
		var state := Campaign.fresh()
		state["nest_level"] = level
		state["completed"] = {}
		clean = Campaign.sanitize(state)
		_expect(clean["completed"] == {"first_supply": true} and not Campaign.chapter_completed(clean), "level-based migration repairs only the historical first mission")
	var result_only := Campaign.fresh()
	result_only["last_result"] = {"mission_id": "stable_colony", "attempt_id": 10, "outcome": "victory", "reward": {"materials": 3}}
	clean = Campaign.sanitize(result_only)
	_expect(Campaign.chapter_completed(clean) and clean["materials"] == 0, "a genuine final-win record repairs completion without creating materials")


func _test_legacy_active_migration() -> void:
	for mission_id in ["first_supply", "remote_pantry"]:
		var state := Campaign.fresh()
		if mission_id == "remote_pantry":
			_win(state, "first_supply")
			Campaign.upgrade(state)
		_expect(Campaign.begin(state, _home(), 400.0, {"organic_cargo_returned": 2.125}, mission_id), "prepare legacy active " + mission_id)
		state.erase("branches")
		var active: Dictionary = state["active_mission"].duplicate(true)
		var home: Dictionary = state["home_world"].duplicate(true)
		var materials := int(state["materials"])
		var loaded := Campaign.sanitize(JSON.parse_string(JSON.stringify(state)))
		_expect(_same_json(loaded["active_mission"], active) and _same_json(loaded["home_world"], home) and loaded["materials"] == materials, "old active task keeps ID, attempt, baseline, snapshot and materials")
		_expect(loaded["branches"] == Campaign.fresh()["branches"] and loaded["version"] == 1, "active v1 migration adds zero branches without version reset")
		var result := Campaign.settle(loaded, "retreat")
		_expect(result["ok"] and _same_json(result["home_world"], home) and result["reward"]["materials"] == 0, "migrated old task can safely return")


func _test_invalid_edits() -> void:
	for version in [0, 2, true, "1", 1.5, NAN, INF]:
		var state := Campaign.fresh()
		state["version"] = version
		state["materials"] = 27
		state["completed"] = {"first_supply": true, "stable_colony": true}
		var before := state.duplicate(true)
		_expect(Campaign.sanitize(state) == Campaign.fresh(), "unsupported or malformed version cannot enter migration")
		_expect(not Campaign.upgrade(state) and not Campaign.purchase_branch(state, "transport") and not Campaign.chapter_completed(state), "unsupported version cannot buy, upgrade or claim completion")
		var after := state.duplicate(true)
		var unchanged_version: bool = is_nan(state["version"]) if typeof(version) == TYPE_FLOAT and is_nan(version) else state["version"] == version
		before.erase("version")
		after.erase("version")
		_expect(unchanged_version and after == before, "invalid-version edits preserve the original recovery data")
	for active in [null, [], true, {"id": "unknown"}, {"id": "first_supply", "attempt_id": -1}]:
		var state := Campaign.fresh()
		state["materials"] = 27
		state["completed"]["first_supply"] = true
		state["active_mission"] = active
		var before := state.duplicate(true)
		_expect(not Campaign.upgrade(state) and not Campaign.purchase_branch(state, "transport") and state == before, "damaged activity cannot be cleared to permit progression editing")
	var state := Campaign.fresh()
	state["materials"] = 27
	var before := state.duplicate(true)
	_expect(not Campaign.can_purchase_branch(state, "unknown") and not Campaign.purchase_branch(state, "") and state == before and Campaign.branch_level(state, "unknown") == 0, "unknown branches cannot charge resources or create levels")
	state["materials"] = NAN
	before = state.duplicate(true)
	_expect(not Campaign.purchase_branch(state, "transport") and is_nan(state["materials"]), "nonfinite material balance is rejected without rewriting it")
