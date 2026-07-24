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
	game.save_path = "user://enemy_fungi_smoke.json"

	if not _check(game.enemy_fungi_initialized and game.enemy_fungi.size() == 1 and game.enemy_hyphae.size() == 3, "new culture should create exactly one rival colony with three initial hyphae"):
		return
	var enemy: Dictionary = game.enemy_fungi[0]
	var enemy_pos: Vector2 = enemy["pos"]
	if not _check(enemy_pos.distance_to(Vector2.ZERO) >= 1800.0 and enemy_pos.distance_to(Vector2.ZERO) <= 3000.0 and not game._is_world_explored(enemy_pos), "rival colony should begin far away and remain hidden by fog"):
		return
	if not _check(game._nearest_enemy_fungus_index(enemy_pos, 30.0, true) == -1, "hidden rival colony should not be targetable"):
		return

	var total_resource_before := _total_organic_resources(game)
	var reserve_before := float(enemy["organic_reserve"])
	game._update_enemy_fungi(10.0)
	var absorbed := float(enemy["organic_reserve"]) - reserve_before
	if not _check(absorbed > 0.0 and is_equal_approx(total_resource_before - _total_organic_resources(game), absorbed), "rival colony should transfer organic reserve from real map resources"):
		return

	enemy["state_time"] = 0.0
	enemy["growth_time"] = 0.0
	enemy["organic_reserve"] = 100.0
	var segment_count_before: int = game.enemy_hyphae.size()
	game._update_enemy_fungi(0.25)
	if not _check(game.enemy_hyphae.size() == segment_count_before + 1 and float(enemy["organic_reserve"]) < 96.1 and float(enemy["organic_reserve"]) >= 0.0, "rival growth should consume reserve and add one bounded hypha"):
		return

	enemy["state_time"] = 0.0
	enemy["growth_time"] = 999.0
	enemy["organic_reserve"] = 10.0
	game.enemy_hyphae.append({
		"id": game.next_enemy_hypha_id,
		"fungus_id": int(enemy["id"]),
		"a": Vector2(30.0, 0.0),
		"b": Vector2.ZERO,
		"growth": 1.0,
		"curve": 0.0,
		"viability": 1.0
	})
	game.next_enemy_hypha_id += 1
	var player_biomass_before := float(game.cores[0]["biomass"])
	game._update_enemy_fungi(1.0)
	if not _check(is_equal_approx(player_biomass_before - float(game.cores[0]["biomass"]), game.ENEMY_FUNGUS_ATTACK_RATE) and float(enemy["organic_reserve"]) < 10.0, "contacting enemy hypha should cause slow fractional damage and consume enemy reserve"):
		return

	game.bacteria.clear()
	game.ecology_events.clear()
	game.cores[0]["biomass"] = game.CORE_MAX_BIOMASS
	var offline_enemy_reserve := float(enemy["organic_reserve"])
	game._apply_offline_progress(60.0, 60.0)
	if not _check(is_equal_approx(float(game.cores[0]["biomass"]), game.CORE_MAX_BIOMASS) and is_equal_approx(float(enemy["organic_reserve"]), offline_enemy_reserve), "offline progress should freeze rival fungus growth and attacks"):
		return
	game.offline_report_open = false

	game._reveal_exploration(enemy_pos, 320.0)
	game._sync_enemy_fungi_discovery(true)
	if not _check(bool(enemy["discovered"]) and game._nearest_enemy_fungus_index(enemy_pos, 30.0, true) == 0, "exploration should reveal and enable targeting of the rival colony"):
		return
	game.dna = 10
	game._purchase_diet_unit("fungi", "piercer")
	if not _check(not bool(game.diet_unit_unlocks["piercer"]), "piercer should remain locked before fungi diet is established"):
		return
	game.diet_levels["fungi"] = 1
	game.diet_order = ["fungi"]
	game._purchase_diet_unit("fungi", "piercer")
	if not _check(bool(game.diet_unit_unlocks["piercer"]) and game._available_barracks_units().has("piercer"), "fungi diet should unlock piercer in the barracks production list"):
		return

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(enemy_pos + Vector2(-120.0, 0.0), "barracks"))
	game._spawn_expedition_spore(barracks_id, "piercer")
	var piercer: Dictionary = game.expedition_units.back()
	game.selected_expedition_ids = [int(piercer["id"])]
	game.camera_center = enemy_pos
	game.camera_zoom = 0.65
	game._issue_expedition_command(game.world_to_screen(enemy_pos))
	if not _check(String(piercer["target_kind"]) == "enemy_fungus" and int(piercer["target_enemy_id"]) == int(enemy["id"]), "explored rival core should accept a piercer attack command"):
		return
	enemy["biomass"] = 0.05
	game._update_expedition_units(4.0, false)
	game._update_expedition_units(2.0, false)
	if not _check(not bool(enemy["alive"]) and game.lifetime_enemy_fungi_defeated == 1 and game._goal_complete("rival_colony"), "piercer should defeat the rival core and complete the rival goal"):
		return

	enemy["alive"] = true
	enemy["biomass"] = 12.5
	enemy["state"] = "starved"
	enemy["organic_reserve"] = 3.25
	game._save_game()
	game.enemy_fungi.clear()
	game.enemy_hyphae.clear()
	if not _check(game._load_game() and game.enemy_fungi.size() == 1 and game.enemy_hyphae.size() >= 1, "rival colony state should survive save and load"):
		return
	enemy = game.enemy_fungi[0]
	if not _check(is_equal_approx(float(enemy["biomass"]), 12.5) and String(enemy["state"]) == "starved" and is_equal_approx(float(enemy["organic_reserve"]), 3.25), "rival core state should round-trip exactly"):
		return

	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	for key in ["enemy_fungi_initialized", "next_enemy_fungus_id", "next_enemy_hypha_id", "enemy_fungi", "enemy_hyphae", "lifetime_enemy_fungi_defeated"]:
		legacy.erase(key)
	var legacy_unlocks: Dictionary = legacy.get("diet_unit_unlocks", {})
	legacy_unlocks.erase("piercer")
	legacy["diet_unit_unlocks"] = legacy_unlocks
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game() and game.enemy_fungi_initialized and game.enemy_fungi.size() == 1 and game.enemy_hyphae.size() == 3, "v0.21 save should migrate to exactly one deterministic rival colony"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("ENEMY_FUNGI_OK enemy=1 resource_bound=true piercer=true save=compatible offline=frozen")
	game.queue_free()
	quit(0)


func _total_organic_resources(game: Node) -> float:
	var total := 0.0
	for resource in game.resources:
		if int(resource.get("kind", -1)) == 0:
			total += float(resource.get("amount", 0.0))
	return total


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("ENEMY_FUNGI_FAIL: " + message)
	quit(1)
	return false
