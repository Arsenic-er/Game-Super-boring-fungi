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
	game.save_path = "user://antifungal_deployment_smoke.json"
	game.dna = 12

	game._purchase_diet_unit("fungi", "antifungal")
	if not _check(not bool(game.diet_unit_unlocks["antifungal"]) and game.dna == 12, "antifungal pod should require fungi diet"):
		return
	game.diet_levels["fungi"] = 1
	game.diet_order = ["fungi"]
	game._purchase_diet_unit("fungi", "antifungal")
	if not _check(bool(game.diet_unit_unlocks["antifungal"]) and game.dna == 6 and game._available_barracks_units().has("antifungal"), "fungi diet should unlock antifungal pod for six DNA"):
		return
	if not _check(is_equal_approx(float(game.UNIT_ORGANIC_COSTS["antifungal"]), 18.0) and is_equal_approx(float(game.UNIT_MINERAL_COSTS["antifungal"]), 2.0) and is_equal_approx(float(game.UNIT_BUILD_SECONDS["antifungal"]), 58.0) and is_equal_approx(float(game.UNIT_MAX_BIOMASS["antifungal"]), 14.0), "antifungal production balance should match v0.29"):
		return
	if not _check(game._unit_filter_ids().has("antifungal") and game._unit_filter_ids().size() == 10, "antifungal pod should have its own unit filter"):
		return

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(800.0, 0.0), "barracks"))
	game._spawn_expedition_spore(barracks_id, "antifungal")
	var pod: Dictionary = game.expedition_units.back()
	pod["pos"] = Vector2(980.0, 0.0)
	game._spawn_expedition_spore(barracks_id, "piercer")
	var piercer: Dictionary = game.expedition_units.back()
	piercer["pos"] = Vector2(980.0, 8.0)

	game.enemy_fungi.clear()
	game.enemy_hyphae.clear()
	var enemy: Dictionary = game._make_enemy_fungus(Vector2(1000.0, 0.0))
	enemy["id"] = 41
	enemy["state_time"] = 0.0
	enemy["growth_time"] = 100.0
	enemy["organic_reserve"] = 0.0
	game.enemy_fungi.append(enemy)
	game.enemy_fungi_initialized = true
	game._reveal_exploration(enemy["pos"], 400.0)
	game.camera_center = enemy["pos"]
	game.camera_zoom = 1.0
	game.selected_expedition_ids = [int(pod["id"]), int(piercer["id"])]
	game._issue_expedition_command(game.world_to_screen(enemy["pos"]))
	if not _check(String(pod["target_kind"]) == "deploy_zone" and String(piercer["target_kind"]) == "enemy_fungus", "mixed right-click should deploy antifungal pod while piercer attacks the core"):
		return

	game._update_expedition_units(1.0, false)
	if not _check(String(pod["state"]) == "deploying" and is_zero_approx(float(pod["deploy_progress"])), "pod should begin unfolding after arrival"):
		return
	game._update_expedition_units(4.9, false)
	if not _check(String(pod["state"]) == "deploying", "deployment should not finish before five seconds"):
		return
	game._update_expedition_units(0.1, false)
	if not _check(String(pod["state"]) == "deployed" and is_equal_approx(float(pod["deploy_progress"]), 5.0), "deployment should finish at five seconds"):
		return
	if not _check(is_equal_approx(game._antifungal_multiplier_at(enemy["pos"]), 0.35), "deployed field should apply a non-stacking 0.35 multiplier"):
		return

	var resource_id: int = game.resources.size()
	game._add_resource(enemy["pos"] + Vector2(10.0, 0.0), 0, 10.0)
	game.enemy_hyphae = [{
		"id": 501, "fungus_id": 41, "parent_id": -1,
		"a": enemy["pos"], "b": enemy["pos"] + Vector2(160.0, 0.0),
		"growth": 0.0, "curve": 0.0, "viability": 1.0, "connected": true
	}]
	var core_biomass_before := float(enemy["biomass"])
	game._update_enemy_fungi(10.0)
	var resource: Dictionary = game._resource_by_id(resource_id)
	if not _check(is_equal_approx(10.0 - float(resource["amount"]), 0.063) and is_equal_approx(float(enemy["growth_time"]), 96.5), "field should reduce enemy absorption and growth timer to 35 percent"):
		return
	if not _check(is_equal_approx(float(game.enemy_hyphae[0]["growth"]), 0.175), "local connected hypha growth should be reduced to 35 percent"):
		return
	if not _check(is_equal_approx(float(enemy["biomass"]), core_biomass_before), "antifungal field should not directly damage enemy cores"):
		return

	game.enemy_hyphae[0]["parent_id"] = 9999
	game.enemy_hyphae[0]["growth"] = 1.0
	game.enemy_hyphae[0]["viability"] = 1.0
	game._update_enemy_fungi(22.5)
	if not _check(is_equal_approx(float(game.enemy_hyphae[0]["viability"]), 0.5), "covered disconnected hypha should decay at double speed"):
		return

	game._spawn_expedition_spore(barracks_id, "antifungal")
	var overlapping: Dictionary = game.expedition_units.back()
	overlapping["pos"] = enemy["pos"]
	overlapping["state"] = "deployed"
	overlapping["deploy_progress"] = 5.0
	if not _check(is_equal_approx(game._antifungal_multiplier_at(enemy["pos"]), 0.35), "overlapping antifungal fields should not multiply"):
		return

	enemy["biomass"] = 0.1
	game._damage_enemy_fungus(41, 0.1)
	if not _check(game.lifetime_antifungal_assisted_kills == 1 and game._goal_complete("antifungal_lockdown"), "a core defeated inside the field should complete the specialist goal"):
		return

	game.selected_expedition_ids = [int(pod["id"])]
	game._issue_expedition_command(game.world_to_screen(Vector2(1200.0, 0.0)))
	if not _check(String(pod["state"]) == "moving" and is_zero_approx(float(pod["deploy_progress"])) and is_equal_approx(game._antifungal_multiplier_at(Vector2(1000.0, 0.0)), 0.35), "redeployment should collapse only the ordered pod while another field remains active"):
		return
	overlapping["state"] = "idle"
	if not _check(is_equal_approx(game._antifungal_multiplier_at(Vector2(1000.0, 0.0)), 1.0), "old field should disappear immediately after redeployment"):
		return

	pod["pos"] = Vector2(1200.0, 0.0)
	pod["state"] = "deployed"
	pod["deploy_progress"] = 5.0
	pod["biomass"] = pod["max_biomass"]
	game._save_game()
	if not _check(game._load_game(), "antifungal state should load"):
		return
	var loaded_pod: Dictionary = {}
	for unit in game.expedition_units:
		if String(unit.get("unit_type", "")) == "antifungal" and String(unit.get("state", "")) == "deployed":
			loaded_pod = unit
			break
	if not _check(not loaded_pod.is_empty() and is_equal_approx(float(loaded_pod["deploy_progress"]), 5.0) and game.lifetime_antifungal_assisted_kills == 1, "unlock, deployed progress, and goal count should round-trip"):
		return

	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	legacy.erase("lifetime_antifungal_assisted_kills")
	var legacy_unlocks: Dictionary = legacy.get("diet_unit_unlocks", {})
	legacy_unlocks.erase("antifungal")
	legacy["diet_unit_unlocks"] = legacy_unlocks
	legacy["expedition_units"] = []
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game() and game.lifetime_antifungal_assisted_kills == 0 and not bool(game.diet_unit_unlocks["antifungal"]), "v0.28 saves should default antifungal fields safely"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("ANTIFUNGAL_DEPLOYMENT_OK unlock=6 deploy=5 radius=150 multiplier=0.35 decay=2 save=compatible")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("ANTIFUNGAL_DEPLOYMENT_FAIL: " + message)
	quit(1)
	return false
