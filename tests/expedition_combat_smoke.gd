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
	game.save_path = "user://expedition_combat_smoke.json"
	game.organic = 10000.0
	game.mineral = 1000.0
	game.diet_levels["bacteria"] = 1
	game.diet_levels["fungi"] = 1

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(120.0, 0.0), "barracks"))
	var expected_max := {"forager": 12.0, "carrier": 18.0, "chelator": 13.0, "scout": 8.0, "lytic": 10.0, "suppressor": 12.0, "disperser": 9.0, "piercer": 14.0, "coil": 11.0, "antifungal": 14.0}
	for unit_type in expected_max:
		game._spawn_expedition_spore(barracks_id, unit_type)
		var unit: Dictionary = game.expedition_units.back()
		if not _check(is_equal_approx(float(unit["max_biomass"]), float(expected_max[unit_type])) and is_equal_approx(float(unit["biomass"]), float(expected_max[unit_type])), "each unit type should spawn at its own full biomass"):
			return

	var wounded: Dictionary = game.expedition_units[0]
	wounded["pos"] = Vector2(260.0, 0.0)
	wounded["cargo_organic"] = 1.25
	game.selected_expedition_ids = [int(wounded["id"])]
	game._damage_expedition_unit(wounded, 8.5, "test damage")
	if not _check(String(wounded["state"]) == "retreating" and is_equal_approx(float(wounded["biomass"]), 3.5), "unit at or below 30 percent should retreat with fractional biomass"):
		return
	game._update_expedition_units(10.0, false)
	if not _check(String(wounded["state"]) == "repairing" and is_zero_approx(float(wounded["cargo_organic"])), "retreat should deposit cargo and enter barracks repair"):
		return
	var organic_after_deposit: float = game.organic
	game._update_expedition_units(1.0, false)
	if not _check(is_equal_approx(float(wounded["biomass"]), 3.58) and is_equal_approx(game.organic, organic_after_deposit), "barracks repair should be free and heal 0.080 biomass per second"):
		return
	game._update_expedition_units(200.0, false)
	if not _check(String(wounded["state"]) == "idle" and is_equal_approx(float(wounded["biomass"]), float(wounded["max_biomass"])) and game.lifetime_expedition_units_repaired == 1, "fully repaired unit should return to idle and be recorded"):
		return

	var doomed: Dictionary = game.expedition_units[1]
	var doomed_id := int(doomed["id"])
	game.selected_expedition_ids = [doomed_id]
	game._damage_expedition_unit(doomed, 999.0, "test lethal damage")
	game._update_expedition_units(0.1, false)
	if not _check(game.lifetime_expedition_units_lost == 1 and not game.selected_expedition_ids.has(doomed_id) and not _has_unit(game, doomed_id), "dead unit should be removed, counted, and pruned from selection"):
		return

	var saved: Dictionary = game.expedition_units[0]
	saved["biomass"] = float(saved["max_biomass"]) * 0.625
	saved["state"] = "repairing"
	game.cores[barracks_id]["auto_replenish"] = true
	game.cores[barracks_id]["auto_replenish_unit"] = "lytic"
	game.cores[barracks_id]["auto_replenish_target"] = 4
	game.diet_levels["bacteria"] = 0
	game.diet_unit_unlocks["lytic"] = false
	game._save_game()
	if not _check(game._load_game(), "combat save should load"):
		return
	var loaded: Dictionary = game.expedition_units[0]
	if not _check(is_equal_approx(float(loaded["biomass"]) / float(loaded["max_biomass"]), 0.625) and String(loaded["state"]) == "repairing" and game.lifetime_expedition_units_lost == 1, "fractional biomass, repair state, and lifetime losses should survive save/load"):
		return
	var resources_before_invalid_auto := Vector2(game.organic, game.mineral)
	game._update_auto_replenishment()
	if not _check(bool(game.cores[barracks_id]["auto_replenish"]) and String(game.cores[barracks_id]["auto_replenish_unit"]) == "lytic" and (game.cores[barracks_id]["spore_jobs"] as Array).is_empty() and Vector2(game.organic, game.mineral).is_equal_approx(resources_before_invalid_auto), "invalid specialist auto-replenishment should preserve its setting and pause without falling back to foragers"):
		return

	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	legacy.erase("lifetime_expedition_units_lost")
	legacy.erase("lifetime_expedition_units_repaired")
	for item in legacy["expedition_units"]:
		item.erase("biomass")
		item.erase("max_biomass")
		item.erase("retreat_reason")
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game(), "legacy unit save should load"):
		return
	loaded = game.expedition_units[0]
	if not _check(is_equal_approx(float(loaded["biomass"]), float(loaded["max_biomass"])) and game.lifetime_expedition_units_lost == 0 and game.lifetime_expedition_units_repaired == 0, "legacy units should migrate at full biomass with zero new lifetime counters"):
		return
	game.selected_expedition_ids = [int(loaded["id"])]
	game._order_selected_expedition_return()
	if not _check(String(loaded["state"]) == "returning" and String(loaded["target_kind"]) == "home", "R-style return order should send a healthy selected unit home without labeling it wounded"):
		return
	var second_barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(340.0, 0.0), "barracks"))
	game.camera_center = Vector2(340.0, 0.0)
	game.camera_zoom = 1.0
	game._issue_expedition_command(game.world_to_screen(Vector2(340.0, 0.0)))
	if not _check(int(loaded["home_core_id"]) == second_barracks_id and String(loaded["state"]) == "returning", "right-clicking another friendly barracks should reassign the unit and return it there"):
		return

	game.diet_levels["bacteria"] = 1
	game.bacteria = [game._make_bacterium(loaded["pos"])]
	loaded["state"] = "attacking"
	loaded["target_pos"] = loaded["pos"]
	var bacteria_before: float = game.bacteria[0]["biomass"]
	var health_before: float = loaded["biomass"]
	game.offline_simulating = true
	game.offline_expedition_combat_active = false
	game._update_expedition_attack(loaded, 5.0)
	if not _check(is_equal_approx(float(game.bacteria[0]["biomass"]), bacteria_before) and is_equal_approx(float(loaded["biomass"]), health_before), "offline combat should stop after its capped window instead of becoming risk-free damage"):
		return
	game.offline_expedition_combat_active = true
	game._update_expedition_attack(loaded, 1.0)
	game.offline_simulating = false
	game.offline_expedition_combat_active = false
	if not _check(float(game.bacteria[0]["biomass"]) < bacteria_before and float(loaded["biomass"]) < health_before, "offline combat inside the capped window should apply both attack and counterattack"):
		return

	game.offline_simulating = false
	game.offline_expedition_combat_active = false
	game.survival_levels["detox"] = 0
	game.bacteria = [game._make_bacterium(loaded["pos"])]
	loaded["biomass"] = loaded["max_biomass"]
	loaded["state"] = "attacking"
	loaded["target_pos"] = loaded["pos"]
	var toxin_before_level0: float = loaded["biomass"]
	game._update_expedition_attack(loaded, 1.0)
	var toxin_damage_level0 := toxin_before_level0 - float(loaded["biomass"])
	game.survival_levels["detox"] = 1
	game.bacteria = [game._make_bacterium(loaded["pos"])]
	loaded["biomass"] = loaded["max_biomass"]
	loaded["state"] = "attacking"
	loaded["target_pos"] = loaded["pos"]
	var toxin_before_level1: float = loaded["biomass"]
	game._update_expedition_attack(loaded, 1.0)
	var toxin_damage_level1 := toxin_before_level1 - float(loaded["biomass"])
	if not _check(toxin_damage_level0 > 0.0 and is_equal_approx(toxin_damage_level1, toxin_damage_level0 * 0.85), "level-one detox should reduce expedition bacterial toxin backlash by 15 percent"):
		return
	game.survival_levels["detox"] = 0

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("EXPEDITION_COMBAT_OK maxes=10 retreat=30% repair=0.080 death=true save=compatible offline=capped")
	game.queue_free()
	quit(0)


func _has_unit(game: Node, unit_id: int) -> bool:
	for unit in game.expedition_units:
		if int(unit.get("id", -1)) == unit_id:
			return true
	return false


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("EXPEDITION_COMBAT_FAIL: " + message)
	quit(1)
	return false
