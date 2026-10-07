extends SceneTree

# Ledger-only fixtures: graph reachability is not a gameplay-time benchmark.
const Campaign = preload("res://scripts/campaign_state.gd")
const Catalog = preload("res://scripts/campaign_mission_catalog.gd")
const IDS := ["first_supply", "remote_pantry", "lost_network", "substrate_race", "first_contact", "toxic_frontier", "boundary_counterattack", "two_fronts", "stable_colony"]
const LEVELS := [1, 2, 2, 2, 2, 3, 3, 3, 4]
const LEGACY_IDS := ["first_supply", "remote_pantry", "first_contact", "substrate_race", "lost_network", "two_fronts", "toxic_frontier", "boundary_counterattack", "stable_colony"]
const LEGACY_LEVELS := [1, 2, 2, 3, 3, 3, 4, 4, 4]
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_test_full_chapter_accounting()
	_test_all_minimal_routes()
	_test_upgrade_gates_and_budget_edges()
	_test_branch_sanitization_and_queries()
	_test_legacy_active_migration()
	_test_invalid_edits()
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPAIGN_PROGRESSION_FAIL: " + failure)
		quit(1)
		return
	print("CAMPAIGN_PROGRESSION_OK checks=%d missions=9 common=27 nest=15 tissues=3/4/3 minimal_routes=6 ordered_routes=12 legacy_boundaries=9+9 versions=1-to-2" % checks)
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
	_expect(result["reward"]["tissues"] == Catalog.first_victory_tissues(mission_id), mission_id + " pays its route-specific tissues exactly")
	return result


func _upgrade(state: Dictionary) -> void:
	var old_level := int(state["nest_level"])
	var cost := Campaign.upgrade_cost(state)
	var before := int(state["materials"])
	_expect(cost == (3 if old_level == 1 else 6) and Campaign.can_upgrade(state), "story milestone funds nest upgrade")
	_expect(Campaign.upgrade(state) and int(state["nest_level"]) == old_level + 1 and int(state["materials"]) == before - cost, "nest upgrade spends only its exact common cost")


func _buy_all_available(state: Dictionary, priority: Array) -> void:
	for branch_id in priority:
		while Campaign.can_purchase_branch(state, branch_id):
			var common := int(state["materials"])
			var balance := Campaign.tissue_balance(state, branch_id)
			_expect(Campaign.purchase_branch(state, branch_id), "available tissue purchase succeeds")
			_expect(state["materials"] == common and Campaign.tissue_balance(state, branch_id) == balance - 1, "specialty consumes exactly one tissue and no nest materials")


func _test_full_chapter_accounting() -> void:
	var state := Campaign.fresh()
	var total_reward := 0
	_expect(Campaign.required_material_reserve(state) == 15 and not Campaign.chapter_completed(state), "new campaign has 15 future nest costs and no completion")
	for index in range(IDS.size()):
		var mission_id: String = IDS[index]
		_expect(int(state["nest_level"]) == LEVELS[index] and Catalog.is_unlocked(state, mission_id), mission_id + " is accessible in its branch act")
		for outcome in ["failure", "retreat"]:
			var before := state.duplicate(true)
			_expect(Campaign.begin(state, _home(), 100.0 + state["serial"], {}, mission_id), mission_id + " starts before " + outcome)
			var active_before := state.duplicate(true)
			_expect(not Campaign.can_upgrade(state) and not Campaign.upgrade(state), "away nest cannot upgrade")
			for branch_id in Campaign.BRANCH_IDS:
				_expect(not Campaign.purchase_branch(state, branch_id), "away nest cannot buy " + branch_id)
			_expect(state == active_before, "refused persistent edits preserve active state")
			state = Campaign.sanitize(JSON.parse_string(JSON.stringify(state)))
			_expect(_same_json(state, active_before), "active mission roundtrips")
			var failed := Campaign.settle(state, outcome)
			_expect(failed["ok"] and failed["reward"] == {"materials": 0, "tissues": {}} and _same_json(failed["home_world"], _home()), "failed/retreated mission restores home with no currency")
			for field in ["completed", "materials", "branches", "tissues"]:
				_expect(state[field] == before[field], "nonvictory preserves " + field)
		var result := _win(state, mission_id)
		total_reward += int(result["reward"]["materials"])
		_expect(Campaign.chapter_completed(state) == (index == IDS.size() - 1), "only final win completes chapter")
		var settled := state.duplicate(true)
		_expect(not Campaign.settle(state, "victory")["ok"] and state == settled, "settlement is exactly once")
		if index in [0, 4, 7]:
			_upgrade(state)
	_expect(total_reward == 27 and state["materials"] == 12 and state["completed"].size() == 9, "nine first wins minus nest costs leave 12 common")
	_expect(state["tissues"] == Catalog.TISSUE_BUDGETS, "all tissue reward totals equal independent currency budgets")
	_expect(Campaign.upgrade_cost(state) == 0 and not Campaign.upgrade(state), "nest cap four")
	_expect(Campaign.next_mission_preview(state).is_empty() and Campaign.recommended_mission_id(state) == "stable_colony", "finished chapter retains finale replay")
	for mission_id in IDS:
		var before := state.duplicate(true)
		_expect(Campaign.begin(state, _home(), 2000.0 + state["serial"], {}, mission_id), "every completed mission replays")
		var result := Campaign.settle(state, "victory")
		_expect(result["reward"] == {"materials": 0, "tissues": {}} and state["materials"] == before["materials"] and state["tissues"] == before["tissues"], "no replay farms either currency")
	_buy_all_available(state, Campaign.BRANCH_IDS)
	_expect(state["materials"] == 12 and state["branches"] == {"transport": 2, "resilience": 2, "defense": 2} and state["tissues"] == {"transport": 1, "resilience": 2, "defense": 1}, "six specialty purchases leave common budget untouched")
	for branch_id in Campaign.BRANCH_IDS:
		_expect(not Campaign.purchase_branch(state, branch_id) and Campaign.branch_purchase_status(state, branch_id)["reason"] == "max_level", "specialty cap cannot be exceeded")
	_expect(_same_json(Campaign.sanitize(JSON.parse_string(JSON.stringify(state))), state), "completed ledger roundtrips")


func _test_all_minimal_routes() -> void:
	var pairs := [["remote_pantry", "lost_network"], ["remote_pantry", "substrate_race"], ["lost_network", "substrate_race"]]
	var priorities := [["transport", "resilience", "defense"], ["defense", "resilience", "transport"]]
	for pair in pairs:
		for reverse_order in [false, true]:
			var ordered: Array = pair.duplicate()
			if reverse_order:
				ordered.reverse()
			for advanced in Catalog.ADVANCED_BRANCHES:
				var state := Campaign.fresh()
				_win(state, "first_supply")
				_upgrade(state)
				for branch in Catalog.EARLY_BRANCHES:
					_expect(Campaign.can_begin(state, branch), "all three early branches open simultaneously")
				_expect(not Campaign.can_begin(state, "first_contact"), "zero branches cannot open first trial")
				_win(state, ordered[0])
				_buy_all_available(state, priorities[1 if reverse_order else 0])
				_expect(not Campaign.can_begin(state, "first_contact") and Catalog.unlock_progress(state, "first_contact")["completed"] == 1, "one distinct win is below 2-of-3")
				Campaign.begin(state, _home(), 200.0, {}, ordered[0])
				Campaign.settle(state, "victory")
				_expect(not Campaign.can_begin(state, "first_contact"), "replaying one branch is not two distinct wins")
				_win(state, ordered[1])
				_expect(Campaign.can_begin(state, "first_contact") and Campaign.recommended_mission_id(state) == "first_contact", "second branch opens story without third or purchased specialty gate")
				_win(state, "first_contact")
				_upgrade(state)
				_buy_all_available(state, priorities[1 if reverse_order else 0])
				for branch in Catalog.ADVANCED_BRANCHES:
					_expect(Campaign.can_begin(state, branch), "both advanced routes open together")
				_expect(not Campaign.can_begin(state, "two_fronts"), "advanced story requires one distinct route")
				_win(state, advanced)
				_expect(Campaign.can_begin(state, "two_fronts"), "either advanced route opens the second trial")
				_buy_all_available(state, priorities[1 if reverse_order else 0])
				_win(state, "two_fronts")
				_upgrade(state)
				_win(state, "stable_colony")
				_expect(Campaign.chapter_completed(state) and state["completed"].size() == 7 and state["materials"] == 6, "every minimal route finishes seven first wins with no material soft lock")
				var optional := 0
				for entry in Catalog.entries():
					if not state["completed"].get(entry["id"], false):
						optional += 1
						_expect(Campaign.can_begin(state, entry["id"]), "omitted route remains playable after finale")
						_win(state, entry["id"])
				_expect(optional == 2 and state["materials"] == 12, "two optional maps can still pay first-win rewards after story completion")


func _test_upgrade_gates_and_budget_edges() -> void:
	for level in [1, 2, 3, 4]:
		var state := Campaign.fresh()
		state["nest_level"] = level
		state["materials"] = 27
		var before := state.duplicate(true)
		_expect(not Campaign.can_upgrade(state) and not Campaign.upgrade(state) and state == before, "common currency alone cannot bypass story gate")
		if level < 4:
			state["completed"][["first_supply", "first_contact", "two_fronts"][level - 1]] = true
			var cost := Campaign.upgrade_cost(state)
			state["materials"] = cost - 1
			_expect(not Campaign.upgrade(state), "below-cost nest upgrade refused")
			state["materials"] = cost
			_expect(Campaign.upgrade(state) and state["materials"] == 0, "exact nest payment succeeds")
	var state := Campaign.fresh()
	state["nest_level"] = 2
	state["materials"] = 0
	state["tissues"]["transport"] = 2
	_expect(Campaign.purchase_branch(state, "transport") and state["materials"] == 0, "level-one specialty is affordable with only matching tissue")
	var before := state.duplicate(true)
	_expect(Campaign.branch_purchase_status(state, "transport")["reason"] == "nest_level" and not Campaign.purchase_branch(state, "transport") and state == before, "second specialty level needs nest three")
	state["nest_level"] = 3
	_expect(Campaign.purchase_branch(state, "transport") and state["tissues"]["transport"] == 0, "nest three unlocks second specialty level")
	_expect(Campaign.branch_purchase_status(state, "resilience")["reason"] == "tissues", "a different route needs its own tissue")
	state["completed"] = {"first_supply": true}
	_expect(not Catalog.is_unlocked(state, "toxic_frontier"), "level three without first trial does not open advanced routes")


func _test_branch_sanitization_and_queries() -> void:
	for field in ["branches", "tissues", "legacy_unlocked_missions"]:
		for raw in [null, [], true, "transport"]:
			var state := Campaign.fresh()
			state[field] = raw
			_expect(Campaign.sanitize(state)[field] == Campaign.fresh()[field], "malformed " + field + " root is rejected")
	var malformed := Campaign.fresh()
	malformed["branches"] = {"transport": 900, "resilience": -1, "defense": 1.5, "unknown": 2}
	malformed["tissues"] = {"transport": 900, "resilience": -1, "defense": 1.5, "unknown": 2}
	malformed["legacy_unlocked_missions"] = {"first_contact": true, "two_fronts": "true", "missing": true}
	var clean := Campaign.sanitize(malformed)
	_expect(clean["branches"] == {"transport": 2, "resilience": 0, "defense": 0} and clean["tissues"] == {"transport": 3, "resilience": 0, "defense": 0}, "known counters clamp; fractions and unknown entries rejected")
	_expect(clean["legacy_unlocked_missions"] == {"first_contact": true} and Catalog.is_unlocked(clean, "first_contact") and not Catalog.is_unlocked(clean, "two_fronts"), "legacy access accepts only known boolean flags")
	for bad in [true, "2", NAN, INF, -INF]:
		malformed["branches"]["transport"] = bad
		malformed["tissues"]["transport"] = bad
		_expect(Campaign.branch_level(malformed, "transport") == 0 and Campaign.tissue_balance(malformed, "transport") == 0, "queries reject malformed counter")
	malformed["branches"] = {"transport": 1.0, "resilience": 2.0, "defense": 0.0}
	malformed["tissues"] = {"transport": 1.0, "resilience": 2.0, "defense": 0.0}
	clean = Campaign.sanitize(malformed)
	_expect(clean["branches"]["transport"] == 1 and clean["tissues"]["resilience"] == 2, "integral JSON floats accepted")
	var before := clean.duplicate(true)
	for branch_id in ["transport", "resilience", "defense", "unknown"]:
		Campaign.branch_purchase_status(clean, branch_id)
		Catalog.unlock_progress(clean, branch_id)
	Campaign.upgrade_cost(clean)
	Campaign.required_material_reserve(clean)
	Campaign.chapter_completed(clean)
	_expect(clean == before, "all UI progression queries are read-only")
	for flag in [true, false, "true", 1, null]:
		var state := Campaign.fresh()
		state["completed"]["stable_colony"] = flag
		_expect(Campaign.chapter_completed(state) == (typeof(flag) == TYPE_BOOL and flag), "only real final-win boolean finishes story")
	for level in [2, 3, 4]:
		var state := Campaign.fresh()
		state["nest_level"] = level
		clean = Campaign.sanitize(state)
		_expect(clean["completed"] == {"first_supply": true}, "existing damaged-level repair only restores tutorial, no new branch victories")
	var receipt := Campaign.fresh()
	receipt["last_result"] = {"mission_id": "stable_colony", "attempt_id": 10, "outcome": "victory", "reward": {"materials": 3}}
	clean = Campaign.sanitize(receipt)
	_expect(Campaign.chapter_completed(clean) and clean["materials"] == 0, "past receipt repairs completion without replaying payment")


func _test_legacy_active_migration() -> void:
	for index in range(LEGACY_IDS.size()):
		for active in [false, true]:
			var state := Campaign.fresh()
			state["version"] = 1
			state.erase("tissues")
			state.erase("legacy_unlocked_missions")
			state["nest_level"] = LEGACY_LEVELS[index]
			for earlier in range(index):
				state["completed"][LEGACY_IDS[earlier]] = true
			state["materials"] = 4
			state["branches"] = {"transport": 1, "resilience": 2, "defense": 0}
			var mission_id: String = LEGACY_IDS[index]
			if active:
				state["serial"] = index + 10
				state["active_mission"] = {"id": mission_id, "attempt_id": index + 10, "started_at": 400.0, "initial_stats": {"organic_cargo_returned": 2.125}}
				state["home_world"] = _home()
			var loaded := Campaign.sanitize(JSON.parse_string(JSON.stringify(state)))
			_expect(loaded["version"] == 2 and loaded["materials"] == 10 and loaded["branches"] == state["branches"], "v1 preserves all bought levels and refunds six common exactly once")
			var earned := {"transport": 0, "resilience": 0, "defense": 0}
			for done in state["completed"]:
				for branch_id in Catalog.first_victory_tissues(done):
					earned[branch_id] += Catalog.first_victory_tissues(done)[branch_id]
			for branch_id in Campaign.BRANCH_IDS:
				_expect(loaded["tissues"][branch_id] == maxi(0, earned[branch_id] - int(state["branches"][branch_id])), "migration converts earned tissue minus preserved investment")
			_expect(loaded["completed"] == state["completed"], "migration never invents branch victories")
			_expect(Catalog.is_unlocked(loaded, mission_id), "old legitimate next mission remains open at each linear boundary")
			_expect(_same_json(Campaign.sanitize(loaded), loaded) and _same_json(Campaign.sanitize(JSON.parse_string(JSON.stringify(loaded))), loaded), "refund and retrospective tissues are idempotent across JSON reload")
			if active:
				_expect(loaded["active_mission"].get("id", "") == mission_id and _same_json(loaded["home_world"], _home()), "active legacy mission and full home snapshot survive changed gates")
				var returned := Campaign.settle(loaded, "retreat")
				_expect(returned["ok"] and _same_json(returned["home_world"], _home()) and returned["reward"] == {"materials": 0, "tissues": {}}, "legacy active retreat safely restores home with no extra reward")
			else:
				_expect(Campaign.can_begin(loaded, mission_id), "grandfathered idle next mission can still begin")
	var old := Campaign.fresh()
	old["version"] = 1
	old["nest_level"] = 2
	old["completed"] = {"first_supply": true, "remote_pantry": true}
	old["last_result"] = {"mission_id": "remote_pantry", "attempt_id": 2, "outcome": "victory", "reward": {"materials": 3}}
	var migrated := Campaign.sanitize(old)
	_expect(migrated["last_result"] == old["last_result"] and migrated["tissues"]["transport"] == 1, "migration does not rewrite historic receipt as a new tissue award")
	_expect(Campaign.can_begin(migrated, "first_contact") and Catalog.unlock_progress(migrated, "first_contact")["completed"] == 1, "legacy first trial access is not a fabricated second branch completion")


func _test_invalid_edits() -> void:
	for version in [0, 3, true, "1", 1.5, NAN, INF]:
		var state := Campaign.fresh()
		state["version"] = version
		state["materials"] = 27
		state["tissues"]["transport"] = 3
		state["completed"] = {"first_supply": true, "stable_colony": true}
		var before := state.duplicate(true)
		_expect(not Campaign.supports_version(version) and Campaign.sanitize(state) == Campaign.fresh(), "unsupported or malformed version cannot enter migration")
		_expect(not Campaign.upgrade(state) and not Campaign.purchase_branch(state, "transport") and not Campaign.chapter_completed(state), "invalid version cannot spend or complete")
		var after := state.duplicate(true)
		var unchanged_version: bool = is_nan(state["version"]) if typeof(version) == TYPE_FLOAT and is_nan(version) else state["version"] == version
		before.erase("version")
		after.erase("version")
		_expect(unchanged_version and after == before, "invalid edit preserves recovery input")
	for version in [1, 1.0, 2, 2.0]:
		_expect(Campaign.supports_version(version), "strict supported integral versions accepted")
	for active in [null, [], true, {"id": "unknown"}, {"id": "first_supply", "attempt_id": -1}]:
		var state := Campaign.fresh()
		state["nest_level"] = 3
		state["materials"] = 27
		state["tissues"]["transport"] = 3
		state["completed"]["first_supply"] = true
		state["active_mission"] = active
		var before := state.duplicate(true)
		_expect(not Campaign.upgrade(state) and not Campaign.purchase_branch(state, "transport") and state == before, "malformed activity cannot be discarded to allow spending")
	var state := Campaign.fresh()
	state["nest_level"] = 3
	state["materials"] = 27
	var before := state.duplicate(true)
	_expect(not Campaign.purchase_branch(state, "unknown") and not Campaign.purchase_branch(state, "") and state == before, "unknown specialty cannot charge")
	state["tissues"]["transport"] = NAN
	_expect(not Campaign.purchase_branch(state, "transport") and is_nan(state["tissues"]["transport"]), "nonfinite tissue refused without rewriting recovery data")
