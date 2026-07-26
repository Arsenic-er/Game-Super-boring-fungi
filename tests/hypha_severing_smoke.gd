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
	game.save_path = "user://hypha_severing_smoke.json"
	game.dna = 10

	game._purchase_diet_unit("fungi", "coil")
	if not _check(not bool(game.diet_unit_unlocks["coil"]) and game.dna == 10, "coil should remain unavailable without fungi diet"):
		return
	game.diet_levels["fungi"] = 1
	game.diet_order = ["fungi"]
	game._purchase_diet_unit("fungi", "coil")
	if not _check(bool(game.diet_unit_unlocks["coil"]) and game.dna == 5 and game._available_barracks_units().has("coil"), "fungi diet should unlock coil for five DNA"):
		return
	if not _check(is_equal_approx(float(game.UNIT_ORGANIC_COSTS["coil"]), 15.0) and is_equal_approx(float(game.UNIT_MINERAL_COSTS["coil"]), 1.5) and is_equal_approx(float(game.UNIT_BUILD_SECONDS["coil"]), 52.0), "coil production costs should match the v0.27 balance"):
		return

	var enemy: Dictionary = game.enemy_fungi[0]
	enemy["pos"] = Vector2(300.0, 0.0)
	enemy["state_time"] = 9999.0
	enemy["growth_time"] = 9999.0
	var enemy_id := int(enemy["id"])
	game.enemy_hyphae = [
		{"id": 101, "fungus_id": enemy_id, "parent_id": -1, "a": Vector2(300, 0), "b": Vector2(360, 0), "growth": 1.0, "curve": 0.0, "viability": 1.0},
		{"id": 102, "fungus_id": enemy_id, "parent_id": 101, "a": Vector2(360, 0), "b": Vector2(420, 0), "growth": 1.0, "curve": 0.0, "viability": 1.0},
		{"id": 103, "fungus_id": enemy_id, "parent_id": 102, "a": Vector2(420, 0), "b": Vector2(480, 0), "growth": 1.0, "curve": 0.0, "viability": 1.0},
		{"id": 104, "fungus_id": enemy_id, "parent_id": -1, "a": Vector2(300, 0), "b": Vector2(300, 70), "growth": 1.0, "curve": 0.0, "viability": 1.0}
	]
	game.next_enemy_hypha_id = 105
	game._refresh_enemy_hypha_connectivity()
	game._reveal_exploration(Vector2(390, 0), 280.0)

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(380.0, 80.0), "barracks"))
	game._spawn_expedition_spore(barracks_id, "coil")
	var coil: Dictionary = game.expedition_units.back()
	coil["pos"] = Vector2(390.0, 8.0)
	game.selected_expedition_ids = [int(coil["id"])]
	game.camera_center = Vector2(390.0, 0.0)
	game.camera_zoom = 1.0
	game._issue_expedition_command(game.world_to_screen(Vector2(390.0, 0.0)))
	if not _check(String(coil["target_kind"]) == "enemy_hypha" and int(coil["target_enemy_hypha_id"]) == 102, "right-clicking a red segment should assign that exact segment to coil"):
		return
	game._spawn_expedition_spore(barracks_id, "forager")
	var forager: Dictionary = game.expedition_units.back()
	forager["pos"] = Vector2(390.0, 12.0)
	game.selected_expedition_ids = [int(coil["id"]), int(forager["id"])]
	game._issue_expedition_command(game.world_to_screen(Vector2(390.0, 0.0)))
	if not _check(String(coil["target_kind"]) == "enemy_hypha" and String(forager["target_kind"]) == "ground" and int(forager["target_enemy_hypha_id"]) == -1, "mixed orders should let only coil cut while other units move to guard the cut point"):
		return
	game.selected_expedition_ids = [int(coil["id"])]

	game.diet_levels["fungi"] = 5
	coil["state"] = "attacking_hypha"
	game._update_expedition_hypha_attack(coil, 17.0)
	if not _check(game._enemy_hypha_index_by_id(102) < 0 and game.lifetime_enemy_hyphae_severed == 1, "a full-efficiency coil should cut one full segment in about 16.7 seconds"):
		return
	var grandchild: Dictionary = game.enemy_hyphae[game._enemy_hypha_index_by_id(103)]
	var independent: Dictionary = game.enemy_hyphae[game._enemy_hypha_index_by_id(104)]
	if not _check(not bool(grandchild["connected"]) and bool(independent["connected"]), "cutting a parent should immediately orphan only its descendants"):
		return
	var viability_before := float(grandchild["viability"])
	game._update_enemy_fungi(45.0)
	if not _check(float(grandchild["viability"]) < viability_before and float(grandchild["viability"]) > 0.0 and bool(independent["connected"]), "orphan branch should fade while an independent root remains active"):
		return
	game._update_enemy_fungi(46.0)
	if not _check(game._enemy_hypha_index_by_id(103) < 0, "orphan branch should disappear after ninety seconds"):
		return

	game.explored_cells.clear()
	if not _check(game._nearest_enemy_hypha_id(Vector2(330, 0), 20.0, true, true) == -1, "fogged hyphae should not be targetable"):
		return
	game._reveal_exploration(Vector2(330, 0), 180.0)
	enemy["state_time"] = 0.0
	enemy["growth_time"] = 0.0
	enemy["organic_reserve"] = 100.0
	var before_regrowth: int = game.enemy_hyphae.size()
	game._update_enemy_fungi(0.25)
	if not _check(game.enemy_hyphae.size() == before_regrowth + 1 and bool(game.enemy_hyphae.back()["connected"]), "enemy should naturally regrow from a remaining connected source"):
		return

	game.lifetime_enemy_hyphae_severed = 3
	if not _check(game._goal_complete("hypha_severing"), "three cuts should complete the severing goal"):
		return
	coil["state"] = "attacking_hypha"
	coil["target_kind"] = "enemy_hypha"
	coil["target_enemy_hypha_id"] = 104
	game._save_game()
	if not _check(game._load_game(), "v0.27 severing state should load"):
		return
	coil = game.expedition_units[0]
	if not _check(game.lifetime_enemy_hyphae_severed == 3 and String(coil["target_kind"]) == "enemy_hypha" and int(coil["target_enemy_hypha_id"]) == 104, "cut count and in-progress hypha target should round-trip"):
		return

	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	legacy.erase("lifetime_enemy_hyphae_severed")
	for segment in legacy["enemy_hyphae"]:
		segment.erase("parent_id")
	for unit in legacy["expedition_units"]:
		unit.erase("target_enemy_hypha_id")
		if String(unit.get("target_kind", "")) == "enemy_hypha":
			unit["target_kind"] = ""
			unit["state"] = "idle"
	var legacy_unlocks: Dictionary = legacy.get("diet_unit_unlocks", {})
	legacy_unlocks.erase("coil")
	legacy["diet_unit_unlocks"] = legacy_unlocks
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game() and game.lifetime_enemy_hyphae_severed == 0 and not bool(game.diet_unit_unlocks["coil"]), "v0.26 saves should migrate without granting new progress or unlocks"):
		return
	var migrated_child_index: int = game._enemy_hypha_index_by_id(105)
	if not _check(migrated_child_index >= 0 and int(game.enemy_hyphae[migrated_child_index]["parent_id"]) in [101, 104] and bool(game.enemy_hyphae[migrated_child_index]["connected"]), "v0.26 segment order should reconstruct the root-to-child topology"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("HYPHA_SEVERING_OK coil=true topology=true decay=90 regrowth=true save=compatible")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("HYPHA_SEVERING_FAIL: " + message)
	quit(1)
	return false
