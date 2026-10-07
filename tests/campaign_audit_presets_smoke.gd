extends SceneTree

const Presets = preload("res://scripts/campaign_audit_presets.gd")
const Words = preload("res://scripts/campaign_audit_localization.gd")
const State = preload("res://scripts/campaign_state.gd")
var checks := 0
var failed := false
var game: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var data_home := OS.get_environment("XDG_DATA_HOME")
	if not _check(data_home.begins_with("/tmp/fungi-") or data_home.begins_with("/home/ubuntu/fungi/tmp/"), "requires disposable server user-data"):
		return
	var entries := Presets.entries()
	if not _check(entries.size() == 8 and Presets.IDS.size() == 8, "eight independent audit checkpoints"):
		return
	var materials := [0, 3, 6, 9, 3, 6, 3, 6]
	var tiers := [2, 2, 2, 2, 3, 3, 4, 4]
	var completion_counts := [1, 2, 3, 4, 4, 5, 6, 7]
	var transport := [0, 1, 1, 2, 2, 3, 3, 3]
	var resilience := [0, 0, 1, 2, 2, 3, 3, 3]
	var defense := [0, 0, 0, 1, 1, 1, 1, 1]
	for index in range(Presets.IDS.size()):
		var id: String = Presets.IDS[index]
		var state := Presets.campaign_for(id, 7)
		var metadata := Presets.preset(id)
		if not _check(not state.is_empty() and state == State.sanitize(state) and state["version"] == 2 and state["main_core_id"] == 7, id + " is a valid deterministic v2 state"):
			return
		if not _check(state["active_mission"].is_empty() and state["home_world"].is_empty(), id + " never leaks placeholder active/home data"):
			return
		if not _check(state["nest_level"] == tiers[index] and state["materials"] == materials[index] and state["completed"].size() == completion_counts[index], id + " real operations derive nest/material/completion ledger"):
			return
		if not _check(state["tissues"] == {"transport": transport[index], "resilience": resilience[index], "defense": defense[index]} and state["branches"] == {"transport": 0, "resilience": 0, "defense": 0}, id + " specialty reward balances match actual settlements"):
			return
		if not _check(not state["completed"].has("substrate_race") and not state["completed"].has("boundary_counterattack") and State.can_begin(state, "substrate_race"), id + " optional early branch remains unfinished and accessible"):
			return
		if not _check(State.can_begin(state, "first_contact") == (index >= 2) and State.can_begin(state, "toxic_frontier") == (index >= 4) and State.can_begin(state, "boundary_counterattack") == (index >= 4) and State.can_begin(state, "two_fronts") == (index >= 5) and State.can_begin(state, "stable_colony") == (index >= 6), id + " live campaign gates are preserved"):
			return
		if not _check(State.can_upgrade(state) == (index == 3) and State.chapter_completed(state) == (index == 7), id + " upgrade and completion status"):
			return
		if not _check(metadata["synthetic_completed"].size() == completion_counts[index] and not metadata["earned_prior_victories"] and metadata["normal_costs"] and not metadata["developer_mode"] and not metadata["offline_gains"], id + " synthetic access and paid rules are disclosed"):
			return
		var mutated := state.duplicate(true)
		mutated["materials"] = 999
		mutated["completed"].clear()
		metadata["synthetic_completed"].clear()
		if not _check(Presets.campaign_for(id, 7) == state and Presets.preset(id)["synthetic_completed"].size() == completion_counts[index], id + " repeated calls are independent"):
			return
		var seen_reward := state.duplicate(true)
		var before_materials := int(seen_reward["materials"])
		var before_tissues: Dictionary = seen_reward["tissues"].duplicate(true)
		if not _check(State.begin(seen_reward, {"fixture": true}, 99.0, {}, "first_supply") and State.settle(seen_reward, "victory")["reward"]["materials"] == 0 and seen_reward["materials"] == before_materials and seen_reward["tissues"] == before_tissues, id + " synthetic prior wins cannot pay twice"):
			return
	for invalid in ["", "unknown", "../save", 1, null, {}, []]:
		if not _check(Presets.preset(invalid).is_empty() and Presets.campaign_for(invalid, 0).is_empty(), "reject non-whitelisted checkpoint"):
			return
	if not _check(Presets.campaign_for("early_choice", -1).is_empty() and Presets.campaign_for("early_choice", 2147483648).is_empty(), "reject invalid main-core identity"):
		return
	entries[0]["title_key"] = "tampered"
	if not _check(Presets.entries()[0]["title_key"] == "early_choice_title", "catalog entries are independent"):
		return
	var substitutions := {"title": "TITLE", "path": "PATH", "organic": "220.000", "mineral": "24.000", "dna": "0", "commit": "COMMIT", "status": "STATUS", "sim": "0", "wall": "0", "speeds": "1", "speed": "1"}
	for locale in Words.LOCALES:
		if not _check(Words.TEXTS.has(locale), "locale dictionary exists " + locale):
			return
		for key in Words.KEYS:
			var translated: String = Words.text(locale, key, substitutions)
			if not _check(Words.TEXTS[locale].has(key) and not translated.is_empty() and translated != key and not translated.contains("{") and not translated.contains("}"), locale + "/" + key + " complete with substituted placeholders"):
				return
			if not _check(_placeholders(Words.TEXTS[locale][key]) == _placeholders(Words.TEXTS["en"][key]), locale + "/" + key + " placeholder parity"):
				return
	if not _check(Words.text("invalid", "title") == Words.text("en", "title"), "unknown locale safely falls back to English"):
		return
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.autosave_enabled = false
	game.developer_mode_enabled = false
	game.save_path = "user://campaign_audit_presets_smoke.json"
	for id in Presets.IDS:
		if not _check(game._start_new_culture("home_nest") and game._complete_founder_spore_germination(), id + " real fresh home and germination"):
			return
		var resource_count: int = game.resources.size()
		var bacteria_count: int = game.bacteria.size()
		var applied := Presets.apply(game, id)
		if not _check(applied["ok"] and game.campaign == Presets.campaign_for(id, game.campaign["main_core_id"]), id + " applied through actual main-core identity"):
			return
		if not _check(game.cores.size() == 2 and game.cores[0]["kind"] == "normal" and game.cores[1]["kind"] == "barracks" and game.segments.size() == 4 and game.expedition_units.size() == 8, id + " disclosed prepared core, barracks, hyphae and army"):
			return
		if not _check(game.resources.size() == resource_count and game.bacteria.size() == bacteria_count and game.enemy_fungi.is_empty() and game.enemy_hyphae.is_empty() and game.enemy_guard_spores.is_empty(), id + " resources/bacteria preserved and ambient enemies removed"):
			return
		if not _check(game.organic == 220.0 and game.mineral == 24.0 and game.dna == 0 and not game.developer_mode_enabled and game.barracks_unit_unlocks == {"forager": true, "carrier": false, "chelator": false, "scout": false}, id + " paid stock and only basic license"):
			return
		for segment in game.segments:
			if not _check(segment["a"] == game.cores[0]["pos"] and is_equal_approx(segment["a"].distance_to(segment["b"]), 240.0) and segment["growth"] == 1.0 and segment["core_id"] == 0 and not segment["orphaned"] and segment["viability"] == 1.0, id + " mature hypha stays attached to main core"):
				return
		for unit in game.expedition_units:
			if not _check(unit["unit_type"] == "forager" and unit["home_core_id"] == 1 and unit["cargo_organic"] == 0.0 and unit["cargo_mineral"] == 0.0, id + " real ordinary units carry no hidden reward"):
				return
		var world: Dictionary = game._capture_world_state()
		world["campaign"] = game.campaign.duplicate(true)
		if not _check(not game._parse_save_payload(JSON.stringify(world)).is_empty(), id + " full fixture meets actual world/save validator"):
			return
		var before := _stable_world()
		if not _check(not Presets.apply(game, "bad")["ok"] and not Presets.prepare_home(game) and _stable_world() == before, id + " invalid or duplicate preparation does not replace played world"):
			return
		var organic_before: float = game.organic
		var mineral_before: float = game.mineral
		if not _check(game._queue_dna(0, 1) and is_equal_approx(game.organic, organic_before - game.DNA_ORGANIC_COST) and is_equal_approx(game.mineral, mineral_before - game.DNA_MINERAL_COST), id + " post-fixture DNA production pays real costs"):
			return
	game.queue_free()
	await process_frame
	print("CAMPAIGN_AUDIT_PRESETS_SMOKE_PASS checks=", checks)
	quit(0)


func _stable_world() -> Dictionary:
	var result: Dictionary = game._capture_world_state()
	result.erase("saved_at")
	return result


func _placeholders(value: String) -> Array:
	var regex := RegEx.new()
	regex.compile("\\{[^}]+\\}")
	var found := []
	for item in regex.search_all(value):
		found.append(item.get_string())
	found.sort()
	return found


func _check(condition: bool, label: String) -> bool:
	checks += 1
	if condition:
		return true
	failed = true
	push_error("CAMPAIGN_AUDIT_PRESETS_SMOKE_FAIL " + label)
	if is_instance_valid(game):
		game.queue_free()
	quit(1)
	return false
