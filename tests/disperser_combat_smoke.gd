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
	game.save_path = "user://disperser_combat_smoke.json"
	game.dna = 14

	game._purchase_diet_unit("bacteria", "disperser")
	if not _check(not bool(game.diet_unit_unlocks["disperser"]) and game.dna == 14, "disperser should require bacteria diet"):
		return
	game.diet_levels["bacteria"] = 1
	game.diet_order = ["bacteria"]
	game._purchase_diet_unit("bacteria", "disperser")
	if not _check(bool(game.diet_unit_unlocks["disperser"]) and game.dna == 7 and game._available_barracks_units().has("disperser"), "bacteria diet should unlock disperser for seven DNA"):
		return
	if not _check(is_equal_approx(float(game.UNIT_ORGANIC_COSTS["disperser"]), 16.0) and is_equal_approx(float(game.UNIT_MINERAL_COSTS["disperser"]), 1.25) and is_equal_approx(float(game.UNIT_BUILD_SECONDS["disperser"]), 50.0) and is_equal_approx(float(game.UNIT_MAX_BIOMASS["disperser"]), 9.0), "disperser production balance should match v0.30"):
		return
	if not _check(game._unit_filter_ids().size() == 11 and game._unit_filter_ids().has("disperser"), "disperser should have its own unit filter"):
		return

	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2.ZERO, "barracks"))
	game._spawn_expedition_spore(barracks_id, "disperser")
	var disperser: Dictionary = game.expedition_units.back()
	disperser["pos"] = Vector2.ZERO
	game._spawn_expedition_spore(barracks_id, "lytic")
	var lytic: Dictionary = game.expedition_units.back()
	lytic["pos"] = Vector2.ZERO
	var target := Vector2(100.0, 0.0)
	game.bacteria = [game._make_bacterium(target)]
	game._reveal_exploration(target, 220.0)
	game.camera_center = target
	game.camera_zoom = 1.0
	game.selected_expedition_ids = [int(disperser["id"]), int(lytic["id"])]
	game._issue_expedition_command(game.world_to_screen(target))
	if not _check(String(disperser["target_kind"]) == "bacteria" and String(lytic["target_kind"]) == "bacteria" and is_equal_approx(float(disperser["burst_cooldown"]), 2.0), "mixed right-click should preserve bacteria targets and start disperser windup"):
		return
	game._update_expedition_units(1.0, false)
	if not _check(String(disperser["state"]) == "attacking" and (disperser["pos"] as Vector2).distance_to(target) > 10.0 and String(lytic["state"]) == "moving", "disperser should stop at range while lytic spores continue closing"):
		return
	lytic["state"] = "guarding"

	game.bacteria.clear()
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		game.bacteria.append(game._make_bacterium(target + Vector2.from_angle(angle) * 24.0))
	var outside: Dictionary = game._make_bacterium(target + Vector2(72.0, 0.0))
	game.bacteria.append(outside)
	disperser["pos"] = target + Vector2(-game.DISPERSER_ATTACK_RANGE, 0.0)
	disperser["target_pos"] = target
	disperser["target_kind"] = "bacteria"
	disperser["state"] = "attacking"
	disperser["burst_cooldown"] = game.DISPERSER_WINDUP_SECONDS
	disperser["biomass"] = disperser["max_biomass"]
	disperser["cargo_organic"] = 0.0
	game._update_disperser_attack(disperser, 1.9)
	if not _check(is_equal_approx(float(game.bacteria[0]["biomass"]), 1.0), "first burst should require the full two-second windup"):
		return
	game._update_disperser_attack(disperser, 0.1)
	var disperser_toxin_damage_level0 := float(disperser["max_biomass"]) - float(disperser["biomass"])
	if not _check(is_equal_approx(float(game.bacteria[0]["biomass"]), 0.88) and is_equal_approx(float(outside["biomass"]), 1.0), "burst should deal 0.600 times diet efficiency only inside radius 60"):
		return
	if not _check(int(disperser["last_burst_hits"]) == 8 and game.lifetime_disperser_best_hit == 8 and game._goal_complete("disperser_burst"), "one dense burst should record eight hits and complete the specialist goal"):
		return
	if not _check(is_equal_approx(float(disperser["cargo_organic"]), 0.24) and is_equal_approx(float(disperser["burst_cooldown"]), 6.0), "burst should recover 25 percent organic cargo and start a six-second cooldown"):
		return

	for bacterium in game.bacteria:
		bacterium["biomass"] = 1.0
	game.survival_levels["detox"] = 1
	disperser["biomass"] = disperser["max_biomass"]
	disperser["cargo_organic"] = 0.0
	disperser["burst_cooldown"] = 0.0
	disperser["target_pos"] = target
	disperser["state"] = "attacking"
	game._update_disperser_attack(disperser, 0.01)
	var disperser_toxin_damage_level1 := float(disperser["max_biomass"]) - float(disperser["biomass"])
	if not _check(disperser_toxin_damage_level0 > 0.0 and is_equal_approx(disperser_toxin_damage_level1, disperser_toxin_damage_level0 * 0.85), "level-one detox should reduce disperser bacterial toxin backlash by 15 percent"):
		return
	game.survival_levels["detox"] = 0
	game.selected_expedition_ids = [int(disperser["id"])]
	var reissue_target: Vector2 = game.bacteria[0]["pos"]
	game._issue_expedition_command(game.world_to_screen(reissue_target))
	if not _check(String(disperser["target_kind"]) == "bacteria" and is_equal_approx(float(disperser["burst_cooldown"]), 6.0), "reissuing a bacteria attack order must not shorten the active six-second cooldown"):
		return
	disperser["target_pos"] = target
	disperser["state"] = "attacking"
	var first_biomass := float(game.bacteria[0]["biomass"])
	game._update_disperser_attack(disperser, 5.9)
	if not _check(is_equal_approx(float(game.bacteria[0]["biomass"]), first_biomass), "cooldown should block early repeated damage"):
		return
	game._update_disperser_attack(disperser, 0.1)
	if not _check(is_equal_approx(float(game.bacteria[0]["biomass"]), 0.76), "second burst should fire exactly after six seconds"):
		return

	game.bacteria.clear()
	for i in range(3):
		var weak: Dictionary = game._make_bacterium(target + Vector2(float(i) * 4.0, 0.0))
		weak["biomass"] = 0.05
		game.bacteria.append(weak)
	var safe_outside: Dictionary = game._make_bacterium(target + Vector2(90.0, 0.0))
	game.bacteria.append(safe_outside)
	disperser["burst_cooldown"] = 0.0
	disperser["cargo_organic"] = 0.0
	disperser["biomass"] = disperser["max_biomass"]
	game._update_disperser_attack(disperser, 0.01)
	if not _check(game.bacteria.size() == 1 and game.lifetime_disperser_bacteria_killed == 3 and is_equal_approx(float(disperser["cargo_organic"]), 0.0375), "pulse should count each kill once and recover cargo from actual damage only"):
		return
	if not _check(String(disperser["state"]) == "returning", "clearing the local burst cluster should return carried biomass without waiting for a global bacteria wipe"):
		return
	if not _check(is_equal_approx(float(safe_outside["biomass"]), 1.0), "bacteria outside burst radius should remain unharmed"):
		return
	var cargo_before_disabled := float(disperser["cargo_organic"])
	var kills_before_disabled: int = game.lifetime_disperser_bacteria_killed
	game.diet_levels["bacteria"] = 0
	disperser["state"] = "attacking"
	disperser["burst_cooldown"] = 0.0
	disperser["target_pos"] = safe_outside["pos"]
	disperser["pos"] = safe_outside["pos"] + Vector2(-game.DISPERSER_ATTACK_RANGE, 0.0)
	game._update_disperser_attack(disperser, 1.0)
	if not _check(String(disperser["state"]) == "guarding" and is_equal_approx(float(safe_outside["biomass"]), 1.0) and is_equal_approx(float(disperser["cargo_organic"]), cargo_before_disabled) and game.lifetime_disperser_bacteria_killed == kills_before_disabled, "an existing disperser must stop dealing damage when bacteria diet is inactive"):
		return
	game.diet_levels["bacteria"] = 1

	disperser["state"] = "attacking"
	disperser["burst_cooldown"] = 0.0
	disperser["burst_flash"] = 0.2
	game._damage_expedition_unit(disperser, 7.0, "range test")
	if not _check(String(disperser["state"]) == "retreating" and is_equal_approx(float(disperser["burst_cooldown"]), 2.0) and is_zero_approx(float(disperser["burst_flash"])), "critical damage should interrupt the burst and force retreat"):
		return

	disperser["state"] = "attacking"
	disperser["biomass"] = disperser["max_biomass"]
	disperser["burst_cooldown"] = 0.0
	disperser["target_pos"] = safe_outside["pos"]
	disperser["pos"] = safe_outside["pos"] + Vector2(-game.DISPERSER_ATTACK_RANGE, 0.0)
	var protected_event: Dictionary = game._make_bacterium(safe_outside["pos"] + Vector2(3.0, 0.0))
	protected_event["event_id"] = 99
	game.bacteria.append(protected_event)
	game.offline_simulating = true
	game.offline_expedition_combat_active = false
	game._update_disperser_attack(disperser, 10.0)
	if not _check(is_equal_approx(float(safe_outside["biomass"]), 1.0) and is_zero_approx(float(disperser["burst_cooldown"])), "offline combat freeze should prevent burst damage and cooldown progress"):
		return
	game.offline_expedition_combat_active = true
	game._update_disperser_attack(disperser, 0.01)
	if not _check(float(safe_outside["biomass"]) < 1.0 and is_equal_approx(float(protected_event["biomass"]), 1.0), "enabled capped offline combat should damage normal bacteria but preserve event bacteria"):
		return
	game.offline_simulating = false
	game.offline_expedition_combat_active = false

	disperser["state"] = "attacking"
	disperser["burst_cooldown"] = 4.25
	disperser["last_burst_hits"] = 8
	game._save_game()
	if not _check(game._load_game(), "disperser state should load"):
		return
	var loaded_disperser: Dictionary = {}
	for unit in game.expedition_units:
		if String(unit.get("unit_type", "")) == "disperser":
			loaded_disperser = unit
			break
	if not _check(not loaded_disperser.is_empty() and is_equal_approx(float(loaded_disperser["burst_cooldown"]), 4.25) and int(loaded_disperser["last_burst_hits"]) == 8 and game.lifetime_disperser_best_hit == 8, "burst cooldown, hit record, and goal progress should round-trip"):
		return

	var file := FileAccess.open(game.save_path, FileAccess.READ)
	var legacy: Dictionary = JSON.parse_string(file.get_as_text())
	file = null
	legacy.erase("lifetime_disperser_bacteria_killed")
	legacy.erase("lifetime_disperser_best_hit")
	var legacy_unlocks: Dictionary = legacy.get("diet_unit_unlocks", {})
	legacy_unlocks.erase("disperser")
	legacy["diet_unit_unlocks"] = legacy_unlocks
	legacy["expedition_units"] = []
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	if not _check(game._load_game() and not bool(game.diet_unit_unlocks["disperser"]) and game.lifetime_disperser_bacteria_killed == 0 and game.lifetime_disperser_best_hit == 0, "v0.29 saves should default disperser fields safely"):
		return

	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("DISPERSER_COMBAT_OK unlock=7 windup=2 cooldown=6 radius=60 damage=0.600 save=compatible")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("DISPERSER_COMBAT_FAIL: " + message)
	quit(1)
	return false
