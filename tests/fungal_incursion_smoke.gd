extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game._start_new_culture()
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false
	game.save_path = "user://fungal_incursion_smoke.json"
	game.organic = 10000.0
	game.mineral = 1000.0

	game._update_fungal_incursion(9999.0)
	if not _check(String(game.fungal_incursion["phase"]) == "locked", "new culture should not start recurring invasions before Chapter 1 completion"):
		return
	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(180.0, 0.0), "barracks"))
	game.chapter_complete = true
	var initial_enemy_id := int(game.enemy_fungi[0]["id"])
	game._damage_enemy_fungus(initial_enemy_id, 999.0)
	game._update_fungal_incursion(0.1)
	if not _check(String(game.fungal_incursion["phase"]) == "cooldown" and float(game.fungal_incursion["remaining"]) >= game.FUNGAL_INCURSION_DELAY_MIN, "clearing the initial rival should unlock a long recurring cooldown"):
		return

	var cooldown_before := float(game.fungal_incursion["remaining"])
	game.ecology_events = [{"id": 999, "type": "bloom", "phase": "warning", "pos": Vector2(800.0, 0.0), "remaining": 30.0}]
	game._update_fungal_incursion(30.0)
	if not _check(is_equal_approx(float(game.fungal_incursion["remaining"]), cooldown_before), "ecology events should pause the incursion cooldown"):
		return
	game.ecology_events.clear()
	game.fungal_incursion["remaining"] = 0.1
	game._update_fungal_incursion(0.2)
	var landing: Vector2 = game.fungal_incursion["pos"]
	if not _check(String(game.fungal_incursion["phase"]) == "warning" and landing.is_finite() and landing.length() < game.WORLD_HALF and game._is_world_explored(landing), "cooldown expiry should choose, reveal, and warn about a bounded landing point"):
		return
	var nearest_core := INF
	for core in game.cores:
		if bool(core.get("alive", true)):
			nearest_core = minf(nearest_core, landing.distance_to(core["pos"]))
	if not _check(nearest_core >= game.FUNGAL_INCURSION_CORE_CLEARANCE and nearest_core <= game.FUNGAL_INCURSION_SPAWN_MAX_DISTANCE, "landing point should respect player-core clearance and maximum response distance"):
		return
	game._save_game()
	if not _check(game._load_game() and String(game.fungal_incursion["phase"]) == "warning" and (game.fungal_incursion["pos"] as Vector2).is_equal_approx(landing), "warning phase and landing point should survive save/load"):
		return

	game.fungal_incursion["remaining"] = 1.0
	game.ecology_events = [{"id": 1000, "type": "toxin", "phase": "active", "pos": Vector2(900.0, 0.0), "remaining": 20.0}]
	game._update_fungal_incursion(10.0)
	if not _check(is_equal_approx(float(game.fungal_incursion["remaining"]), 1.0), "ecology events should also pause an active landing warning"):
		return
	var ecology_rect: Rect2 = game._ecology_event_hud_rect()
	var incursion_rect: Rect2 = game._fungal_incursion_hud_rect()
	var chapter_rect: Rect2 = game._chapter_guidance_rect()
	if not _check(not ecology_rect.intersects(incursion_rect) and not incursion_rect.intersects(chapter_rect), "ecology, incursion, and chapter cards should stack without overlap"):
		return
	game.ecology_events.clear()
	game._update_fungal_incursion(1.1)
	if not _check(String(game.fungal_incursion["phase"]) == "active" and game._living_enemy_fungus_count() == 1, "warning expiry should create exactly one active recurring rival"):
		return
	var active_id := int(game.fungal_incursion["enemy_id"])
	var active_index: int = game._enemy_fungus_index_by_id(active_id)
	var active: Dictionary = game.enemy_fungi[active_index]
	if not _check(String(active["source"]) == "incursion" and int(active["wave"]) == 1 and is_equal_approx(float(active["max_biomass"]), 30.0) and is_equal_approx(float(active["attack_multiplier"]), 0.75) and is_zero_approx(float(active["state_time"])), "wave 1 should spawn as a 30-biomass immature rival with 0.75 attack multiplier and no dormancy"):
		return
	game._save_game()
	if not _check(game._load_game() and String(game.fungal_incursion["phase"]) == "active" and game._enemy_fungus_index_by_id(active_id) >= 0, "active phase and linked recurring rival should survive save/load"):
		return
	active_index = game._enemy_fungus_index_by_id(active_id)
	active = game.enemy_fungi[active_index]
	game.diet_levels["fungi"] = 1
	game._spawn_expedition_spore(barracks_id, "piercer")
	var piercer: Dictionary = game.expedition_units.back()
	piercer["pos"] = active["pos"]
	piercer["target_enemy_id"] = active_id
	var piercer_health_before: float = piercer["biomass"]
	game._update_expedition_fungus_attack(piercer, 1.0)
	if not _check(is_equal_approx(piercer_health_before - float(piercer["biomass"]), game.EXPEDITION_ENEMY_FUNGUS_COUNTER_RATE * 0.75 * 0.75), "wave attack multiplier should affect the piercer's counterattack damage"):
		return

	var offline_phase := String(game.fungal_incursion["phase"])
	var offline_enemy_biomass := float(active["biomass"])
	game._apply_offline_progress(60.0, 60.0)
	game.offline_report_open = false
	if not _check(String(game.fungal_incursion["phase"]) == offline_phase and is_equal_approx(float(active["biomass"]), offline_enemy_biomass), "offline settlement should freeze recurring-invasion timing and combat"):
		return

	var reward_organic_before: float = game.organic
	var reward_mineral_before: float = game.mineral
	game._damage_enemy_fungus(active_id, 999.0)
	if not _check(game.lifetime_fungal_incursions_defeated == 1 and String(game.fungal_incursion["phase"]) == "cooldown" and is_equal_approx(game.organic - reward_organic_before, 15.0) and is_equal_approx(game.mineral - reward_mineral_before, 0.5), "wave 1 defeat should atomically grant its reward and restart cooldown"):
		return
	var reward_after_first := Vector2(game.organic, game.mineral)
	game._damage_enemy_fungus(active_id, 999.0)
	if not _check(Vector2(game.organic, game.mineral).is_equal_approx(reward_after_first), "a defeated rival must never pay its reward twice"):
		return

	game.lifetime_fungal_incursions_defeated = 2
	game.fungal_incursion = {"phase": "warning", "remaining": 0.0, "pos": landing, "wave": 3, "enemy_id": -1}
	game._activate_fungal_incursion()
	active_id = int(game.fungal_incursion["enemy_id"])
	active_index = game._enemy_fungus_index_by_id(active_id)
	active = game.enemy_fungi[active_index]
	if not _check(is_equal_approx(float(active["max_biomass"]), 37.2) and is_equal_approx(float(active["attack_multiplier"]), 0.85) and is_equal_approx(float(active["organic_reserve"]), 10.0) and game._enemy_guard_count_for_fungus(active_id) == 3, "wave 3 scaling should pay the real organic cost of its three starting guards"):
		return
	var dna_before: int = game.dna
	reward_organic_before = game.organic
	reward_mineral_before = game.mineral
	game._damage_enemy_fungus(active_id, 999.0)
	if not _check(game.lifetime_fungal_incursions_defeated == 3 and game.dna == dna_before + 1 and is_equal_approx(game.organic - reward_organic_before, 21.0) and is_equal_approx(game.mineral - reward_mineral_before, 1.0) and game._goal_complete("sporefall_guard"), "every third wave should grant bonus DNA and complete the three-wave goal"):
		return

	game._save_game()
	if not _check(game._load_game() and String(game.fungal_incursion["phase"]) == "cooldown" and game.lifetime_fungal_incursions_defeated == 3, "cooldown and lifetime wave count should survive save/load"):
		return
	for wave in range(4, 11):
		game.fungal_incursion = {"phase": "warning", "remaining": 0.0, "pos": landing, "wave": wave, "enemy_id": -1}
		if not _check(game._activate_fungal_incursion(), "later wave should activate"):
			return
		game._damage_enemy_fungus(int(game.fungal_incursion["enemy_id"]), 999.0)
	if not _check(game.lifetime_fungal_incursions_defeated == 10 and game.enemy_fungi.size() <= 3 and game.enemy_hyphae.size() <= 9, "ten direct waves should keep rival cores and hyphae bounded"):
		return
	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	legacy.erase("fungal_incursion")
	legacy.erase("lifetime_fungal_incursions_defeated")
	for item in legacy["enemy_fungi"]:
		item.erase("source")
		item.erase("wave")
		item.erase("attack_multiplier")
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game() and String(game.fungal_incursion["phase"]) == "locked" and game.lifetime_fungal_incursions_defeated == 0, "v0.25 saves without incursion fields should load safely without immediately spawning an enemy"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("FUNGAL_INCURSION_OK warning=90 waves=3 reward=atomic save=compatible offline=frozen cards=stacked")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FUNGAL_INCURSION_FAIL: " + message)
	quit(1)
	return false
