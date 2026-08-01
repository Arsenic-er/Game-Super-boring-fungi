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
	game.save_path = "user://unit_role_orders_smoke.json"
	game.diet_levels["bacteria"] = 1
	game.diet_levels["fungi"] = 1
	game.diet_order = ["bacteria", "fungi"]
	game.ecology_events.clear()
	game.enemy_fungi.clear()
	game.enemy_hyphae.clear()
	game.enemy_guard_spores.clear()
	for resource in game.resources:
		resource["alive"] = false
		resource["amount"] = 0.0
	game._rebuild_resource_grid()

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2.ZERO, "barracks"))
	var roles := ["forager", "carrier", "chelator", "scout", "lytic", "suppressor", "disperser", "antifungal", "piercer", "coil"]
	for unit_type in roles:
		game._spawn_expedition_spore(barracks_id, unit_type)
	var bacteria_target: Dictionary = game._make_bacterium(Vector2(70.0, 0.0))
	bacteria_target["stored"] = 0.0
	bacteria_target["cooldown"] = 9999.0
	game.bacteria = [bacteria_target]
	game._reveal_exploration(Vector2.ZERO, 320.0)
	game.camera_center = Vector2.ZERO
	game.camera_zoom = 1.0
	game.selected_expedition_ids.clear()
	for unit in game.expedition_units:
		unit["pos"] = Vector2.ZERO
		game.selected_expedition_ids.append(int(unit["id"]))
		var expected_bacteria := ["forager", "lytic", "disperser"].has(String(unit["unit_type"]))
		if not _check(game._unit_can_attack_bacteria(unit) == expected_bacteria, "bacteria permission matrix should contain exactly three roles"):
			return

	game._issue_expedition_command(game.world_to_screen(bacteria_target["pos"]))
	for unit in game.expedition_units:
		var unit_type := String(unit["unit_type"])
		var expected_kind := "bacteria" if ["forager", "lytic", "disperser"].has(unit_type) else ("deploy_zone" if ["suppressor", "antifungal"].has(unit_type) else "ground")
		if not _check(String(unit["target_kind"]) == expected_kind and String(unit["state"]) == "moving", "mixed bacteria order should execute or fall back by role"):
			return
	if not _check(game.toast_text.contains("5 \u6539\u4e3a\u8b66\u6212"), "mixed command receipt should report five fallback guards"):
		return

	var piercer := _unit_by_type(game, "piercer")
	var coil := _unit_by_type(game, "coil")
	for specialist in [piercer, coil]:
		specialist["state"] = "idle"
		specialist["manual"] = false
		specialist["target_kind"] = ""
		specialist["pos"] = Vector2(40.0, 0.0)
		game._acquire_expedition_target(specialist)
		if not _check(not ["resource", "bacteria"].has(String(specialist["target_kind"])), "fungal specialists must not auto gather or attack bacteria"):
			return

	var forager := _unit_by_type(game, "forager")
	for unit in game.expedition_units:
		if int(unit["id"]) == int(forager["id"]):
			continue
		game._set_expedition_hold(unit, unit["pos"])
	game.selected_expedition_ids = [int(forager["id"])]
	game._issue_expedition_command(game.world_to_screen(Vector2(150.0, 0.0)))
	forager["pos"] = forager["target_pos"]
	game._update_expedition_units(0.1, false)
	if not _check(game._unit_is_manual_hold(forager), "manual ground arrival should become a true hold"):
		return
	var held_pos: Vector2 = forager["pos"]
	var bacteria_before := float(bacteria_target["biomass"])
	for i in range(5):
		forager["search_cooldown"] = 0.0
		game._update_expedition_units(2.1, false)
	if not _check(game._unit_is_manual_hold(forager) and (forager["pos"] as Vector2).is_equal_approx(held_pos) and is_equal_approx(float(bacteria_target["biomass"]), bacteria_before) and is_zero_approx(float(forager["cargo_organic"])), "hold should survive five search cycles without moving or fighting"):
		return
	game._clear_selected_persistent_orders()
	if not _check(not bool(forager["manual"]) and String(forager["state"]) == "idle", "C should release an empty hold to automatic idle"):
		return
	game._update_expedition_units(0.1, false)
	if not _check(String(forager["target_kind"]) == "bacteria" and String(forager["state"]) == "moving", "released forager should resume its legal automatic role"):
		return

	game._set_expedition_hold(forager, held_pos)
	forager["cargo_organic"] = 0.5
	game._clear_selected_persistent_orders()
	if not _check(String(forager["state"]) == "returning" and String(forager["target_kind"]) == "home" and not bool(forager["manual"]), "C should return a released unit carrying cargo"):
		return
	var suppressor := _unit_by_type(game, "suppressor")
	suppressor["state"] = "deployed"
	suppressor["manual"] = true
	game.selected_expedition_ids = [int(suppressor["id"])]
	game._clear_selected_persistent_orders()
	if not _check(String(suppressor["state"]) == "deployed" and bool(suppressor["manual"]), "C must not collapse a deployed pod"):
		return
	var lytic := _unit_by_type(game, "lytic")
	lytic["state"] = "wounded"
	lytic["manual"] = true
	lytic["target_kind"] = "home"
	game.selected_expedition_ids = [int(lytic["id"])]
	game._clear_selected_persistent_orders()
	if not _check(String(lytic["state"]) == "wounded" and String(lytic["target_kind"]) == "home", "C must not interrupt a wounded unit"):
		return

	var carrier := _unit_by_type(game, "carrier")
	var resource: Dictionary = game.resources[0]
	resource["pos"] = Vector2(20.0, 20.0)
	resource["kind"] = 0
	resource["amount"] = 10.0
	resource["initial_amount"] = 10.0
	resource["alive"] = true
	game._rebuild_resource_grid()
	carrier["pos"] = Vector2.ZERO
	carrier["state"] = "guarding"
	carrier["manual"] = true
	carrier["target_kind"] = ""
	carrier["harvest_enabled"] = true
	carrier["harvest_min"] = Vector2(-80.0, -80.0)
	carrier["harvest_max"] = Vector2(80.0, 80.0)
	lytic["pos"] = Vector2.ZERO
	lytic["biomass"] = lytic["max_biomass"]
	lytic["state"] = "guarding"
	lytic["manual"] = true
	lytic["target_kind"] = ""
	lytic["purge_enabled"] = true
	lytic["purge_min"] = Vector2(-80.0, -80.0)
	lytic["purge_max"] = Vector2(80.0, 80.0)
	game._update_expedition_units(0.1, false)
	if not _check(bool(carrier["harvest_enabled"]) and String(carrier["target_kind"]) == "resource", "persistent harvest must not be mistaken for manual hold"):
		return
	if not _check(bool(lytic["purge_enabled"]) and String(lytic["target_kind"]) == "bacteria", "persistent purge must not be mistaken for manual hold"):
		return

	game.expedition_units.clear()
	game.bacteria = [game._make_bacterium(Vector2(60.0, 0.0))]
	game.bacteria[0]["stored"] = 0.0
	game.bacteria[0]["cooldown"] = 9999.0
	for resource_item in game.resources:
		resource_item["alive"] = false
		resource_item["amount"] = 0.0
	game._rebuild_resource_grid()
	game._spawn_expedition_spore(barracks_id, "carrier")
	carrier = game.expedition_units[0]
	carrier["pos"] = Vector2(60.0, 0.0)
	carrier["state"] = "attacking"
	carrier["target_kind"] = "bacteria"
	carrier["target_pos"] = Vector2(60.0, 0.0)
	carrier["manual"] = true
	carrier["cargo_organic"] = 0.0
	game._save_game()
	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var saved: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	saved["saved_at"] = Time.get_unix_time_from_system() - 60.0
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(saved))
	file = null
	var saved_bacteria_biomass := float(game.bacteria[0]["biomass"])
	var saved_kills := int(game.lifetime_expedition_bacteria_killed)
	if not _check(game._load_game(), "crafted legacy order save should load"):
		return
	carrier = game.expedition_units[0]
	if not _check(game._unit_is_manual_hold(carrier) and String(carrier["target_kind"]) == "" and is_zero_approx(float(carrier["cargo_organic"])), "illegal saved bacteria order should sanitize into hold before offline settlement"):
		return
	if not _check(game.bacteria.size() == 1 and is_equal_approx(float(game.bacteria[0]["biomass"]), saved_bacteria_biomass) and int(game.lifetime_expedition_bacteria_killed) == saved_kills, "sanitized legacy unit must not damage bacteria or earn cargo/kills offline"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("ROLE_ORDERS_OK matrix=10 hold_cycles=5 clear=auto persistent=2 legacy=clean_before_offline")
	game.queue_free()
	quit(0)


func _unit_by_type(game: Node, unit_type: String) -> Dictionary:
	for unit in game.expedition_units:
		if String(unit.get("unit_type", "")) == unit_type:
			return unit
	return {}


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("ROLE_ORDERS_FAIL: " + message)
	quit(1)
	return false
