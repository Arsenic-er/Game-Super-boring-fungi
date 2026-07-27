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
	game.save_path = "user://enemy_guard_spores_smoke.json"

	if not _check(game.enemy_guard_spores.size() == 2 and game._enemy_guard_count_for_fungus(int(game.enemy_fungi[0]["id"])) == 2, "a new rival colony should begin with two bounded guard spores"):
		return
	var enemy: Dictionary = game.enemy_fungi[0]
	var enemy_id := int(enemy["id"])
	var guard: Dictionary = game.enemy_guard_spores[0]
	var guard_pos: Vector2 = guard["pos"]
	if not _check(not game._is_world_explored(guard_pos) and game._nearest_enemy_guard_index(guard_pos, 20.0, true) == -1, "fog-hidden guards should neither render nor accept targeting queries"):
		return

	game._reveal_exploration(enemy["pos"], 360.0)
	game.diet_levels["fungi"] = 1
	game.diet_order = ["fungi"]
	game.diet_unit_unlocks["piercer"] = true
	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core((enemy["pos"] as Vector2) + Vector2(-120.0, 0.0), "barracks"))
	game._spawn_expedition_spore(barracks_id, "piercer")
	var piercer: Dictionary = game.expedition_units.back()
	game.selected_expedition_ids = [int(piercer["id"])]
	game.camera_center = guard_pos
	game.camera_zoom = 0.65
	game._issue_expedition_command(game.world_to_screen(guard_pos))
	if not _check(String(piercer["target_kind"]) == "enemy_guard" and int(piercer["target_enemy_guard_id"]) == int(guard["id"]), "right click should prioritize a visible guard over the rival core behind it"):
		return

	guard["pos"] = guard_pos + Vector2(24.0, 0.0)
	game._update_expedition_units(0.1, false)
	if not _check((piercer["target_pos"] as Vector2).is_equal_approx(guard["pos"]), "player units should continuously refresh the moving guard position"):
		return
	piercer["pos"] = (enemy["pos"] as Vector2) + Vector2(34.0, 0.0)
	guard["pos"] = (piercer["pos"] as Vector2) + Vector2(4.0, 0.0)
	guard["target_unit_id"] = int(piercer["id"])
	var player_biomass_before := float(piercer["biomass"])
	game._update_enemy_guard_spores(1.0)
	if not _check(is_equal_approx(player_biomass_before - float(piercer["biomass"]), game.ENEMY_GUARD_ATTACK_RATE), "a guard in contact should apply slow fractional biomass damage"):
		return

	guard["biomass"] = 2.345
	guard["state"] = "returning"
	game._save_game()
	game.enemy_guard_spores.clear()
	if not _check(game._load_game() and game.enemy_guard_spores.size() == 2, "guard state should survive save and load"):
		return
	guard = game.enemy_guard_spores[0]
	if not _check(is_equal_approx(float(guard["biomass"]), 2.345) and String(guard["state"]) == "returning", "guard biomass and finite-state data should round-trip"):
		return

	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	legacy.erase("enemy_guard_spores")
	legacy.erase("next_enemy_guard_id")
	legacy.erase("lifetime_enemy_guards_defeated")
	for saved_enemy in legacy.get("enemy_fungi", []):
		saved_enemy.erase("guard_spawn_time")
		saved_enemy["organic_reserve"] = 0.0
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game() and game.enemy_guard_spores.size() == 2 and is_zero_approx(float(game.enemy_fungi[0]["organic_reserve"])), "v0.31 saves should receive two free guards without changing a depleted rival reserve"):
		return

	enemy = game.enemy_fungi[0]
	enemy_id = int(enemy["id"])
	guard = game.enemy_guard_spores[0]
	piercer = game.expedition_units[0]
	var frozen_guard_pos: Vector2 = guard["pos"]
	var frozen_guard_biomass := float(guard["biomass"])
	var frozen_unit_biomass := float(piercer["biomass"])
	piercer["state"] = "moving"
	piercer["target_kind"] = "enemy_guard"
	piercer["target_enemy_guard_id"] = int(guard["id"])
	piercer["target_pos"] = guard["pos"]
	var frozen_unit_pos: Vector2 = piercer["pos"]
	game._apply_offline_progress(game.OFFLINE_MIN_SECONDS)
	if not _check((guard["pos"] as Vector2).is_equal_approx(frozen_guard_pos) and is_equal_approx(float(guard["biomass"]), frozen_guard_biomass) and (piercer["pos"] as Vector2).is_equal_approx(frozen_unit_pos) and is_equal_approx(float(piercer["biomass"]), frozen_unit_biomass) and String(piercer["state"]) == "moving" and String(piercer["target_kind"]) == "enemy_guard" and int(piercer["target_enemy_guard_id"]) == int(guard["id"]), "the complete offline settlement path should preserve mobile rival combat and its pending command"):
		return

	guard["biomass"] = 0.020
	piercer["pos"] = guard["pos"]
	piercer["state"] = "attacking_guard"
	piercer["target_kind"] = "enemy_guard"
	piercer["target_enemy_guard_id"] = int(guard["id"])
	game._update_expedition_units(1.0, false)
	if not _check(game.lifetime_enemy_guards_defeated == 1 and game.enemy_guard_spores.size() == 1, "a fungi-specialist unit should defeat and remove a targeted guard exactly once"):
		return

	enemy["organic_reserve"] = 100.0
	game._seed_enemy_guards(enemy_id, 10)
	if not _check(game._enemy_guard_count_for_fungus(enemy_id) == game.ENEMY_GUARD_MAX_PER_FUNGUS and game.enemy_guard_spores.size() <= game.MAX_ENEMY_GUARD_SPORES, "guard replenishment should respect per-colony and global hard caps"):
		return
	game._damage_enemy_fungus(enemy_id, 1000.0)
	for candidate in game.enemy_guard_spores:
		if not _check(String(candidate["state"]) == "orphaned" and int(candidate["target_unit_id"]) == -1, "core death should immediately orphan every linked guard"):
			return
	game._update_enemy_guard_spores(game.ENEMY_GUARD_ORPHAN_DECAY_SECONDS + 0.1)
	if not _check(game.enemy_guard_spores.is_empty(), "orphaned guards should gradually decay and disappear"):
		return
	game.lifetime_enemy_guards_defeated = 5
	if not _check(game._goal_complete("rival_guard") and game._goal_progress_text("rival_guard") == "5 / 5", "five interceptions should complete the dedicated long-term goal"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("ENEMY_GUARDS_OK seeded=2 cap=", game.ENEMY_GUARD_MAX_PER_FUNGUS, " pursuit=dynamic combat=fractional save=compatible offline=frozen orphan=decays goal=5")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("ENEMY_GUARDS_FAIL: " + message)
	quit(1)
	return false
