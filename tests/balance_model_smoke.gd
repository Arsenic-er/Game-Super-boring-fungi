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
	if game._founder_spore_active():
		game._complete_founder_spore_germination()
	game.main_menu_active = false
	game.game_started = true
	game.autosave_enabled = false

	game.resources.clear()
	game.bacteria.clear()
	var parent: Dictionary = game._make_bacterium(Vector2(4000.0, 4000.0))
	parent["stored"] = game.BACTERIA_DIVISION_NUTRIENT
	parent["cooldown"] = 0.0
	var mass_before := float(parent["biomass"]) + float(parent["stored"])
	game.bacteria.append(parent)
	game._update_bacteria(0.001)
	var mass_after := 0.0
	for bacterium in game.bacteria:
		mass_after += float(bacterium.get("biomass", 0.0)) + float(bacterium.get("stored", 0.0))
	if not _check(game.bacteria.size() == 2 and is_equal_approx(float(game.bacteria[1]["biomass"]), game.BACTERIA_DIVISION_NUTRIENT) and is_equal_approx(mass_before, mass_after), "bacterial division must conserve stored nutrient and biomass"):
		return

	game.dna = 200
	game._purchase_diet("animal")
	game._purchase_diet("plant")
	if not _check(game.dna == 200 and game.diet_order.is_empty(), "unavailable diets must not consume DNA or occupy an unlock slot"):
		return
	game._purchase_diet("bacteria")
	for unused_level in range(4):
		game._purchase_diet("bacteria")
	game._purchase_diet("fungi")
	if not _check(game.dna == 142 and int(game.diet_investments["bacteria"]) == 28 and int(game.diet_levels["bacteria"]) == 5 and int(game.diet_investments["fungi"]) == 30 and game.diet_order == ["bacteria", "fungi"], "diet licenses must retain their permanent 3x10^n acquisition order"):
		return
	game._request_diet_respec("bacteria")
	if not _check(game.dna == 142 and int(game.diet_levels["bacteria"]) == 5, "the first respec click should only confirm"):
		return
	game._request_diet_respec("bacteria")
	if not _check(game.dna == 157 and int(game.diet_levels["bacteria"]) == 1 and int(game.diet_investments["bacteria"]) == 3 and game.diet_order == ["bacteria", "fungi"] and game._diet_unlock_cost() == 300, "respec must refund only upgrade spend while preserving the license and tenfold unlock history"):
		return
	game._request_diet_respec("bacteria")
	if not _check(game.dna == 157 and int(game.diet_levels["bacteria"]) == 1, "a base license with no enhancements must not produce another refund"):
		return
	for unused_level in range(4):
		game._purchase_diet("bacteria")
	if not _check(game.dna == 132 and int(game.diet_levels["bacteria"]) == 5 and int(game.diet_investments["bacteria"]) == 28, "restoring a reset diet must repay only its normal enhancement costs"):
		return

	if not _check(is_equal_approx(game._shared_production_total_throughput(1), 1.0) and is_equal_approx(game._shared_production_total_throughput(2), 1.5) and is_equal_approx(game._shared_production_total_throughput(3), 1.75), "shared production should have geometrically diminishing total throughput"):
		return
	game.cores.clear()
	for x in [0.0, 100.0]:
		game.cores.append(game._make_core(Vector2(x, 0.0), "normal"))
	game.cores[0]["jobs"] = [{"remaining": 1.0}]
	game.cores[1]["jobs"] = [{"remaining": 100.0}]
	game.dna = 0
	game.lifetime_dna_produced = 0
	game._update_dna_jobs(60.0)
	if not _check(game.cores[0]["jobs"].is_empty() and is_equal_approx(float(game.cores[1]["jobs"][0]["remaining"]), 40.333333) and game.dna == 1, "a large DNA update must redistribute capacity immediately when one worker becomes idle"):
		return

	game.cores.clear()
	for x in [0.0, 100.0]:
		var barracks: Dictionary = game._make_core(Vector2(x, 0.0), "barracks")
		barracks["spore_jobs"] = [{"remaining": 30.0, "total": 30.0, "unit_type": "forager", "automatic": false}]
		game.cores.append(barracks)
	game.expedition_units.clear()
	game._update_barracks_jobs(20.0)
	if not _check(is_equal_approx(float(game.cores[0]["spore_jobs"][0]["remaining"]), 15.0) and is_equal_approx(float(game.cores[1]["spore_jobs"][0]["remaining"]), 15.0), "two active barracks should each run at 75 percent speed"):
		return

	game.cores[0]["spore_jobs"] = [{"remaining": 1.0, "total": 100.0, "unit_type": "forager", "automatic": false}]
	game.cores[1]["spore_jobs"] = [{"remaining": 100.0, "total": 100.0, "unit_type": "forager", "automatic": false}]
	game.expedition_units.clear()
	game._update_barracks_jobs(60.0)
	if not _check(game.cores[0]["spore_jobs"].is_empty() and is_equal_approx(float(game.cores[1]["spore_jobs"][0]["remaining"]), 40.333333) and game.expedition_units.size() == 1, "a large barracks update must redistribute capacity immediately when one worker becomes idle"):
		return

	game.diet_levels["fungi"] = 1
	var enemy: Dictionary = game.enemy_fungi[0]
	enemy["alive"] = true
	enemy["biomass"] = 60.0
	enemy["state_time"] = 0.0
	game.expedition_units.clear()
	for unit_index in range(7):
		var unit: Dictionary = {
			"id": unit_index + 1, "unit_type": "piercer", "home_core_id": 0,
			"pos": enemy["pos"], "state": "attacking_fungus", "target_kind": "enemy_fungus",
			"target_enemy_id": int(enemy["id"]), "cargo_organic": 0.0, "cargo_mineral": 0.0,
			"biomass": 18.0, "max_biomass": 18.0, "lost": false
		}
		game.expedition_units.append(unit)
	var enemy_before := float(enemy["biomass"])
	for unit in game.expedition_units:
		game._update_expedition_fungus_attack(unit, 1.0)
	var expected_damage: float = 6.0 * 0.180 * float(game._diet_efficiency("fungi"))
	if not _check(is_equal_approx(enemy_before - float(enemy["biomass"]), expected_damage) and is_equal_approx(float(game.expedition_units[6]["biomass"]), 18.0), "only six units may damage and take counterfire from one enemy core"):
		return

	game.offline_simulating = true
	game.cores[0]["biomass"] = 1.0
	game._damage_core(0, 999.0, "offline_balance_test")
	if not _check(bool(game.cores[0]["alive"]) and is_equal_approx(float(game.cores[0]["biomass"]), float(game.cores[0]["max_biomass"]) * 0.10), "offline threats should reduce biomass but never erase the last playable state"):
		return
	game.offline_simulating = false

	var upgrade_localization = load("res://scripts/upgrade_localization.gd")
	for locale in upgrade_localization.LOCALES:
		for key in ["diet_chapter_locked", "diet_chapter_locked_reason", "respec_button", "toast_diet_chapter_locked", "toast_respec_confirm_fmt", "toast_respec_done_fmt", "toast_respec_nothing"]:
			if not _check(upgrade_localization.text(key, locale) != key and not upgrade_localization.text(key, locale).is_empty(), "every balance UI key must exist in all seven locales"):
				return

	print("BALANCE_MODEL_OK mass=conserved respec=upgrades_only license_order=permanent throughput=1.5 siege=6 offline_floor=10% locales=7")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BALANCE_MODEL_FAIL: " + message)
	quit(1)
	return false
