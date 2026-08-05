extends SceneTree


var assertion_count := 0


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
	game.autosave_enabled = false
	game._enter_developer_mode()
	game._begin_new_culture()
	await process_frame

	if not _check(game.has_method("_developer_set_upgrade_level"), "developer level API should exist"):
		return
	if not _check(float(game.organic) >= 1000000.0 and float(game.mineral) >= 1000000.0 and int(game.dna) >= 1000000, "developer culture should keep free resources"):
		return
	for diet_id in game.DIET_IDS:
		if not _check(int(game.diet_levels[diet_id]) == 0, "developer diets should start at level zero"):
			return
	for component_id in game.BACTERIA_COMPONENT_IDS:
		if not _check(int(game.bacteria_components[component_id]) == 0, "developer components should start at level zero"):
			return
	for structure_id in game.STRUCTURE_IDS:
		if not _check(int(game.structure_levels[structure_id]) == 0, "developer structures should start at level zero"):
			return
	for survival_id in game.SURVIVAL_IDS:
		if not _check(int(game.survival_levels[survival_id]) == 0, "developer survival upgrades should start at level zero"):
			return
	if not _check(bool(game.barracks_unit_unlocks["forager"]) and not bool(game.barracks_unit_unlocks["carrier"]) and not bool(game.barracks_unit_unlocks["scout"]), "only the base forager should start unlocked"):
		return

	var resource_snapshot := [float(game.organic), float(game.mineral), int(game.dna)]
	if not _check(game._developer_set_upgrade_level("diet", "bacteria", 3), "bacteria diet should be freely set"):
		return
	if not _check(int(game.diet_levels["bacteria"]) == 3 and game.diet_order.count("bacteria") == 1, "diet level should update order once"):
		return
	game._developer_set_upgrade_level("diet", "bacteria", 5)
	if not _check(game.diet_order.count("bacteria") == 1, "repeated diet changes should not duplicate order"):
		return
	game._developer_set_upgrade_level("component", "trap", 9)
	if not _check(int(game.bacteria_components["trap"]) == 3, "component levels should clamp to three"):
		return
	game._developer_set_upgrade_level("diet_unit", "lytic", 1)
	if not _check(bool(game.diet_unit_unlocks["lytic"]), "available diet unit should toggle on"):
		return
	game._developer_set_upgrade_level("diet", "bacteria", 0)
	if not _check(not game.diet_order.has("bacteria") and not game._available_barracks_units().has("lytic"), "zero diet should leave the order and disable its units"):
		return
	if not _check(not game._developer_set_upgrade_level("component", "enzymes", 1), "component increase should respect its diet prerequisite"):
		return
	game._developer_set_upgrade_level("component", "trap", 0)
	if not _check(int(game.bacteria_components["trap"]) == 0, "existing dependent levels should still be reducible"):
		return

	game.cores.append(game._make_core(Vector2(120.0, 0.0)))
	game._developer_set_upgrade_level("node", "feeder_range", 4, 0)
	game._developer_set_upgrade_level("node", "feeder_range", 2, 1)
	if not _check(int(game.cores[0]["feeder_range_level"]) == 4 and int(game.cores[1]["feeder_range_level"]) == 2, "node levels should be independent per core"):
		return
	game._developer_set_upgrade_level("node", "feeder_range", -8, 0)
	if not _check(int(game.cores[0]["feeder_range_level"]) == 0, "node levels should clamp to zero"):
		return

	game.cores[0]["biomass"] = float(game.cores[0]["max_biomass"]) * 0.5
	game._developer_set_upgrade_level("survival", "wall", 4)
	if not _check(is_equal_approx(float(game.cores[0]["max_biomass"]), 200.0) and is_equal_approx(float(game.cores[0]["biomass"]), 100.0), "wall increase should preserve biomass percentage"):
		return
	game._developer_set_upgrade_level("survival", "wall", 0)
	if not _check(is_equal_approx(float(game.cores[0]["max_biomass"]), 100.0) and is_equal_approx(float(game.cores[0]["biomass"]), 50.0), "wall decrease should keep biomass legal"):
		return

	game._developer_set_upgrade_level("structure", "growth", 99)
	if not _check(int(game.structure_levels["growth"]) == 4, "structure level should clamp to four"):
		return
	if not _check(not game._developer_set_upgrade_level("scout", "vision", 1), "scout upgrades should require scout unlock"):
		return
	game._developer_set_upgrade_level("barracks", "scout", 1)
	game._developer_set_upgrade_level("scout", "vision", 3)
	if not _check(bool(game.barracks_unit_unlocks["scout"]) and int(game.scout_upgrade_levels["vision"]) == 3, "scout unlock and levels should be independently adjustable"):
		return
	game._developer_set_upgrade_level("barracks", "scout", 0)
	if not _check(not bool(game.barracks_unit_unlocks["scout"]) and int(game.scout_upgrade_levels["vision"]) == 3, "locking scout should preserve its test level"):
		return
	game._developer_set_upgrade_level("barracks", "forager", 0)
	if not _check(bool(game.barracks_unit_unlocks["forager"]), "base forager must remain unlocked"):
		return

	game.upgrade_tab = 2
	var panel: Rect2 = game._upgrade_panel_rect(game.get_viewport_rect().size)
	var growth_button: Rect2 = game._structure_button_rect(panel, game.STRUCTURE_IDS.find("growth"))
	var previous_growth := int(game.structure_levels["growth"])
	game._handle_upgrade_click(game._developer_level_part_rect(growth_button, false).get_center())
	if not _check(int(game.structure_levels["growth"]) == previous_growth - 1, "shop minus control should lower a developer level"):
		return
	game._handle_upgrade_click(game._developer_level_part_rect(growth_button, true).get_center())
	if not _check(int(game.structure_levels["growth"]) == previous_growth, "shop plus control should raise a developer level"):
		return

	if not _check(resource_snapshot == [float(game.organic), float(game.mineral), int(game.dna)], "developer level changes should consume no resources"):
		return
	await process_frame
	await process_frame
	if not _check(int(game.structure_levels["growth"]) == previous_growth, "developer levels should not refill to maximum on later frames"):
		return

	game._exit_developer_mode()
	var normal_level := int(game.structure_levels["growth"])
	if not _check(not game._developer_set_upgrade_level("structure", "growth", 0) and int(game.structure_levels["growth"]) == normal_level, "normal mode must reject developer level writes"):
		return

	print("DEVELOPER_UPGRADE_LEVELS_OK assertions=%d resources=free shop=adjustable dependencies=guarded" % assertion_count)
	game.queue_free()
	await process_frame
	quit(0)


func _check(condition: bool, message: String) -> bool:
	assertion_count += 1
	if condition:
		return true
	push_error("DEVELOPER_UPGRADE_LEVELS_FAIL[%d]: %s" % [assertion_count, message])
	quit(1)
	return false
