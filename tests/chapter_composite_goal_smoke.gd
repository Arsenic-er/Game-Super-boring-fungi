extends SceneTree


# Bounded rule/migration fixtures, not a claim about normal opening speed.
# Counters and networks are explicit setup; no gameplay prices are altered.
const SaveStore = preload("res://scripts/save_store.gd")
const TEST_SAVE_PATH := "user://chapter_composite_goal_smoke.json"

var game: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveStore.remove_slot(TEST_SAVE_PATH)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	# Rules and migrations are tested here; sound playback has its own smoke.
	if game.pixel_audio != null:
		game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
		game.pixel_audio.ambient_player.stop()
	game.developer_mode_enabled = false
	game.autosave_enabled = false
	game.splash_active = false
	game.save_path = TEST_SAVE_PATH
	game._start_new_culture()
	if game._founder_spore_active():
		game._complete_founder_spore_germination()
	game.main_menu_active = false
	game.game_started = false
	if not _check(game._chapter_tasks().size() == 11, "composite chapter exposes eleven tasks"):
		return
	if not _supply_boundaries() or not _expansion_boundaries() or not _composite_ordering() or not _combat_independent_of_guidance() or not _developer_boundary() or not _save_compatibility():
		return
	SaveStore.remove_slot(TEST_SAVE_PATH)
	print("CHAPTER_COMPOSITE_GOAL_OK supply_thresholds=true live_network=true preemptive_kill_gated=true regression_gated=true completion_sticky=true rules_v2=true legacy_migration=true")
	if game.pixel_audio != null:
		for player in game.pixel_audio.players:
			player.stop()
			player.stream = null
		game.pixel_audio.ambient_player.stop()
		game.pixel_audio.ambient_player.stream = null
	# Let the dummy audio driver release queued playback references before exit.
	await create_timer(0.10).timeout
	game.queue_free()
	await process_frame
	quit(0)


func _fixture() -> void:
	game.developer_mode_enabled = false
	game.founder_spore = {}
	game.cores.clear()
	game.cores.append(game._make_core(Vector2.ZERO))
	game.cores.append(game._make_core(Vector2(200.0, 0.0)))
	game.cores.append(game._make_core(Vector2(400.0, 0.0), "barracks"))
	game.segments.clear()
	game.segments.append(_segment(float(game.CHAPTER_HYPHA_WORLD_REQUIRED)))
	game.feeders.clear()
	game.expedition_units.clear()
	game.lifetime_expedition_units_built = 0
	game._spawn_expedition_spore(2, "forager")
	game.core_selected_once = true
	game.lifetime_organic_absorbed = game.CHAPTER_SUPPLY_ORGANIC_REQUIRED
	game.lifetime_mineral_absorbed = game.CHAPTER_SUPPLY_MINERAL_REQUIRED
	game.lifetime_expedition_organic_returned = game.CHAPTER_SUPPLY_RETURNED_ORGANIC_REQUIRED
	game.lifetime_expedition_mineral_returned = 0.0
	game.lifetime_dna_produced = 1
	game.lifetime_enemy_fungi_defeated = 0
	game.diet_order = ["bacteria"]
	for diet_id in game.diet_levels:
		game.diet_levels[diet_id] = 1 if diet_id == "bacteria" else 0
	for enemy in game.enemy_fungi:
		enemy["alive"] = true
		enemy["biomass"] = float(enemy.get("max_biomass", 100.0))
		enemy["discovered"] = true
	game.chapter_task_index = 7
	game.chapter_complete = false
	game.chapter_report_open = false
	game.chapter_report_seen = false
	game.chapter_completed_at = 0.0
	game.offline_report_open = false
	game.game_over = false
	game.organic = 0.0
	game.mineral = 0.0
	game.dna = 0
	game.sim_time = 1234.5


func _segment(length: float, core_id: int = 0, growth: float = 1.0, orphaned: bool = false, viability: float = 1.0) -> Dictionary:
	return {"a": Vector2.ZERO, "b": Vector2(length, 0.0), "growth": growth, "core_id": core_id, "curve": 0.0, "orphaned": orphaned, "viability": viability}


func _supply_boundaries() -> bool:
	_fixture()
	if not _check(game._chapter_supply_ready(), "exact cumulative thresholds qualify even with empty current stock"):
		return false
	var requirements := {
		"lifetime_organic_absorbed": float(game.CHAPTER_SUPPLY_ORGANIC_REQUIRED),
		"lifetime_mineral_absorbed": float(game.CHAPTER_SUPPLY_MINERAL_REQUIRED),
		"lifetime_expedition_organic_returned": float(game.CHAPTER_SUPPLY_RETURNED_ORGANIC_REQUIRED)
	}
	for field in requirements:
		var threshold := float(requirements[field])
		game.set(field, threshold - 0.001)
		if not _check(not game._chapter_supply_ready(), "%s just below threshold blocks supply" % field):
			return false
		game.set(field, threshold)
		if not _check(game._chapter_supply_ready(), "%s at threshold qualifies" % field):
			return false
		game.set(field, threshold + 0.001)
		if not _check(game._chapter_supply_ready(), "%s above threshold qualifies" % field):
			return false
		game.set(field, threshold)
	game.organic = 100000.0
	game.mineral = 100000.0
	game.lifetime_organic_absorbed = 0.0
	game.lifetime_expedition_organic_returned = 100000.0
	if not _check(not game._chapter_supply_ready(), "inventory and cargo cannot substitute for actual hyphal organic absorption"):
		return false
	game.lifetime_organic_absorbed = game.CHAPTER_SUPPLY_ORGANIC_REQUIRED
	game.lifetime_mineral_absorbed = 0.0
	game.lifetime_expedition_mineral_returned = 100000.0
	return _check(not game._chapter_supply_ready(), "returned minerals cannot substitute for hyphal mineral absorption")


func _expansion_boundaries() -> bool:
	_fixture()
	var required_length := float(game.CHAPTER_HYPHA_WORLD_REQUIRED)
	if not _check(game.CHAPTER_LIVING_CORE_REQUIRED == 3 and game._chapter_expansion_ready() and is_equal_approx(game._chapter_living_hypha_length(), required_length), "three living cores and exactly required mature length qualify"):
		return false
	game.segments[0]["b"] = Vector2(required_length - 0.001, 0.0)
	if not _check(not game._chapter_expansion_ready(), "length just below threshold blocks expansion"):
		return false
	game.segments[0]["b"] = Vector2(required_length + 0.001, 0.0)
	if not _check(game._chapter_expansion_ready(), "length just above threshold qualifies"):
		return false
	game.cores[2]["alive"] = false
	game.cores[2]["biomass"] = 0.0
	if not _check(not game._chapter_expansion_ready(), "two living cores do not qualify even when a dead third core remains in the array"):
		return false
	game.cores.append(game._make_core(Vector2(600.0, 0.0)))
	if not _check(game._chapter_expansion_ready(), "a replacement living core restores the three-core count"):
		return false
	game.segments.clear()
	game.segments.append(_segment(required_length))
	game.segments.append(_segment(1000.0, 0, 0.5))
	game.segments.append(_segment(1000.0, 0, 1.0, true))
	game.segments.append(_segment(1000.0, 2))
	game.segments.append(_segment(1000.0, -1))
	game.segments.append(_segment(1000.0, 999))
	game.segments.append(_segment(1000.0, 0, 1.0, false, 0.0))
	if not _check(is_equal_approx(game._chapter_living_hypha_length(), required_length), "unfinished, orphaned, dead-owner, invalid-owner and nonviable hyphae are excluded"):
		return false
	game.segments.remove_at(0)
	return _check(is_zero_approx(game._chapter_living_hypha_length()) and not game._chapter_expansion_ready(), "invalid branches alone cannot complete expansion")


func _composite_ordering() -> bool:
	_fixture()
	game.lifetime_enemy_fungi_defeated = 1
	game.lifetime_expedition_organic_returned = game.CHAPTER_SUPPLY_RETURNED_ORGANIC_REQUIRED - 0.001
	game._update_chapter_flow(false)
	if not _check(not game.chapter_complete and game.chapter_task_index == 7, "an early rival kill cannot skip the supply goal"):
		return false
	game.lifetime_expedition_organic_returned = game.CHAPTER_SUPPLY_RETURNED_ORGANIC_REQUIRED
	game.segments[0]["b"] = Vector2(game.CHAPTER_HYPHA_WORLD_REQUIRED - 0.001, 0.0)
	game._update_chapter_flow(false)
	if not _check(not game.chapter_complete and game.chapter_task_index == 8, "an early rival kill cannot skip expansion"):
		return false
	game.segments[0]["b"] = Vector2(game.CHAPTER_HYPHA_WORLD_REQUIRED, 0.0)
	game._update_chapter_flow(false)
	if not _check(game.chapter_complete and game.chapter_task_index == 11, "the preemptive kill is retained and finishes only when both live gates qualify"):
		return false
	if not _check(game.chapter_completed_rules_version == 2 and game._chapter_report_subtitle() == game._ct("report_subtitle"), "new composite completion records rules two and uses the new-goal report"):
		return false

	_fixture()
	game._update_chapter_flow(false)
	if not _check(game.chapter_task_index == 10 and not game.chapter_complete, "a qualified economy still requires defeating the rival"):
		return false
	game.lifetime_expedition_organic_returned = game.CHAPTER_SUPPLY_RETURNED_ORGANIC_REQUIRED - 0.001
	game._update_chapter_flow(false)
	if not _check(game.chapter_task_index == 7 and not game.chapter_complete, "a stale later index cannot bypass a currently unqualified supply state"):
		return false
	game.lifetime_expedition_organic_returned = game.CHAPTER_SUPPLY_RETURNED_ORGANIC_REQUIRED
	game._update_chapter_flow(false)
	game.cores[2]["alive"] = false
	game.cores[2]["biomass"] = 0.0
	game.lifetime_enemy_fungi_defeated = 1
	game._update_chapter_flow(false)
	if not _check(game.chapter_task_index == 8 and not game.chapter_complete, "losing a core before the kill is checked revokes live expansion eligibility"):
		return false
	game.cores[2]["alive"] = true
	game.cores[2]["biomass"] = 100.0
	game._update_chapter_flow(false)
	if not _check(game.chapter_complete and game.chapter_task_index == 11, "restoring expansion after the kill completes the composite goal"):
		return false
	var completed_at := float(game.chapter_completed_at)
	game.segments.clear()
	game.cores[2]["alive"] = false
	game.cores[2]["biomass"] = 0.0
	game.lifetime_expedition_organic_returned = 0.0
	game._update_chapter_flow(false)
	return _check(game.chapter_complete and game.chapter_task_index == 11 and is_equal_approx(game.chapter_completed_at, completed_at), "once completed the chapter achievement and completion time are never revoked")


func _combat_independent_of_guidance() -> bool:
	_fixture()
	# Target-selection fixture: remove competing food and combat targets, but use
	# the normal unit capability, operating-range and explored-cell checks.
	game.resources.clear()
	game.resource_grid.clear()
	game.bacteria.clear()
	game.enemy_hyphae.clear()
	game.enemy_guard_spores.clear()
	var forager: Dictionary = game.expedition_units[0]
	var enemy: Dictionary = game.enemy_fungi[0]
	game.enemy_fungi = [enemy]
	enemy["pos"] = (forager["pos"] as Vector2) + Vector2(-60.0, 0.0)
	game._update_exploration(false)
	game._update_chapter_flow(false)
	game._acquire_expedition_target(forager)
	if not _check(game.chapter_task_index == 10 and game._unit_can_attack_enemy_fungus(forager) and String(forager.get("target_kind", "")) == "enemy_fungus" and int(forager.get("target_enemy_id", -1)) == int(enemy["id"]), "a basic forager automatically acquires the visible rival at the final objective"):
		return false
	# Kill another core, not the forager's barracks home, so its combat capability
	# and target range are unchanged while the live expansion goal regresses.
	game.cores[0]["alive"] = false
	game.cores[0]["biomass"] = 0.0
	game._update_chapter_flow(false)
	forager["target_kind"] = ""
	forager["state"] = "idle"
	game._acquire_expedition_target(forager)
	if not _check(game.chapter_task_index == 8 and not game.chapter_complete and String(forager.get("target_kind", "")) == "enemy_fungus" and int(forager.get("target_enemy_id", -1)) == int(enemy["id"]), "losing live expansion eligibility does not disable automatic acquisition of the same visible rival"):
		return false
	game.explored_cells.clear()
	forager["target_kind"] = ""
	forager["state"] = "idle"
	game._acquire_expedition_target(forager)
	return _check(String(forager.get("target_kind", "")) != "enemy_fungus", "guidance-independent targeting still cannot acquire a rival hidden by fog")


func _developer_boundary() -> bool:
	_fixture()
	game.developer_mode_enabled = true
	game.lifetime_expedition_organic_returned = 0.0
	game.segments.clear()
	game._developer_apply_action("advance_task")
	game._update_chapter_flow(false)
	if not _check(game.chapter_task_index == 8 and not game.chapter_complete, "explicit sandbox task advancement is not pulled back by ordinary supply constraints"):
		return false
	game.developer_mode_enabled = false
	game._update_chapter_flow(false)
	return _check(game.chapter_task_index == 7 and not game.chapter_complete, "the same incomplete state is constrained again outside developer mode")


func _save_compatibility() -> bool:
	_fixture()
	game.lifetime_organic_absorbed = 1.0
	game.lifetime_mineral_absorbed = 0.0
	game.lifetime_expedition_organic_returned = 0.0
	game.segments[0]["b"] = Vector2(80.0, 0.0)
	game.lifetime_enemy_fungi_defeated = 1
	if not _check(game._save_game(), "the migration baseline uses the real save writer"):
		return false
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	var baseline: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	if not _check(int(baseline.get("chapter_rules_version", -1)) == 2, "new saves declare chapter rules version two"):
		return false

	var current_complete: Dictionary = baseline.duplicate(true)
	current_complete["chapter_complete"] = true
	current_complete["chapter_task_index"] = 11
	current_complete["chapter_completed_rules_version"] = 2
	current_complete["chapter_completed_at"] = 1234.5
	if not _load_payload(current_complete):
		return false
	if not _check(game.chapter_complete and game.chapter_task_index == 11 and is_equal_approx(game.chapter_completed_at, 1234.5) and game.chapter_completed_rules_version == 2 and game._chapter_report_subtitle() == game._ct("report_subtitle"), "current completed saves retain their rules-two achievement despite a now-smaller network"):
		return false

	var current_incomplete: Dictionary = baseline.duplicate(true)
	current_incomplete["chapter_task_index"] = 11
	current_incomplete["chapter_complete"] = false
	if not _load_payload(current_incomplete):
		return false
	if not _check(not game.chapter_complete and game.chapter_task_index == 7, "even a current incomplete save with a terminal stale index cannot skip live supply"):
		return false

	for old_index in [7, 8, 9]:
		var old_incomplete: Dictionary = baseline.duplicate(true)
		old_incomplete.erase("chapter_rules_version")
		old_incomplete.erase("chapter_completed_rules_version")
		old_incomplete["chapter_task_index"] = old_index
		old_incomplete["chapter_complete"] = false
		if not _load_payload(old_incomplete):
			return false
		game._update_chapter_flow(false)
		if not _check(not game.chapter_complete and game.chapter_task_index == 7, "old explicit incomplete index %d must earn the new economy goals despite a prior rival kill" % old_index):
			return false

	var old_complete: Dictionary = baseline.duplicate(true)
	old_complete.erase("chapter_rules_version")
	old_complete.erase("chapter_completed_rules_version")
	old_complete["chapter_task_index"] = 9
	old_complete["chapter_complete"] = true
	old_complete["chapter_completed_at"] = 321.0
	if not _load_payload(old_complete):
		return false
	if not _check(game.chapter_complete and game.chapter_task_index == 11 and is_equal_approx(game.chapter_completed_at, 321.0), "explicitly completed old saves retain their earned completion"):
		return false
	var legacy_subtitle := String(game._chapter_report_subtitle())
	if not _check(game.chapter_completed_rules_version == 1 and not legacy_subtitle.is_empty() and legacy_subtitle == game._ct("report_legacy_subtitle") and legacy_subtitle != game._ct("report_subtitle"), "old completion is identified as rules one and does not claim the new economy goals were achieved"):
		return false
	if not _check(game._save_game(), "the migrated completed save can be written in the current format"):
		return false
	file = FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	var upgraded_complete: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	if not _check(int(upgraded_complete.get("chapter_rules_version", -1)) == 2 and int(upgraded_complete.get("chapter_completed_rules_version", -1)) == 1, "upgrading the save format preserves the old completion provenance"):
		return false
	if not _load_payload(upgraded_complete):
		return false
	if not _check(game.chapter_complete and game.chapter_completed_rules_version == 1 and game._chapter_report_subtitle() == legacy_subtitle and is_equal_approx(game.chapter_completed_at, 321.0), "a second load of the upgraded save still shows the original legacy completion and timestamp"):
		return false

	var ancient: Dictionary = baseline.duplicate(true)
	for key in ["chapter_rules_version", "chapter_completed_rules_version", "chapter_task_index", "chapter_complete", "chapter_report_seen", "chapter_completed_at", "core_selected_once", "guidance_collapsed", "lifetime_expedition_units_built"]:
		ancient.erase(key)
	if not _load_payload(ancient):
		return false
	if not _check(game.chapter_complete and game.chapter_task_index == 11 and game.chapter_completed_rules_version == 1 and game._chapter_report_subtitle() == legacy_subtitle, "very old fieldless saves infer only legacy completion when their old chain and rival kill are fulfilled"):
		return false
	var ancient_without_kill: Dictionary = ancient.duplicate(true)
	ancient_without_kill["lifetime_enemy_fungi_defeated"] = 0
	if not _load_payload(ancient_without_kill):
		return false
	if not _check(not game.chapter_complete and game.chapter_task_index == 7, "very old saves without a rival kill do not receive inferred completion"):
		return false
	var ancient_broken_chain: Dictionary = ancient.duplicate(true)
	ancient_broken_chain["lifetime_dna_produced"] = 0
	if not _load_payload(ancient_broken_chain):
		return false
	return _check(not game.chapter_complete and game.chapter_task_index == 3, "a rival kill alone cannot infer an unfinished old tutorial chain as completed")


func _load_payload(data: Dictionary) -> bool:
	SaveStore.remove_slot(TEST_SAVE_PATH)
	data["saved_at"] = Time.get_unix_time_from_system() + 60.0
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	if not _check(file != null, "test save payload opens without touching the player slot"):
		return false
	file.store_string(JSON.stringify(data))
	file = null
	return _check(game._load_game(false), "the real loader accepts the bounded compatibility payload")


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CHAPTER_COMPOSITE_GOAL_FAIL: " + message)
	SaveStore.remove_slot(TEST_SAVE_PATH)
	quit(1)
	return false
