extends SceneTree

const NORMAL_SAVE := "user://damaged_network_normal_smoke.json"
const LOAD_RETURN_BUDGET_MS := 750
const SETTLEMENT_BUDGET_MS := 30000
const MAX_PUMP_FRAMES := 2400

var game: Node
var assertions := 0
var developer_save := ""
var owns_developer_save := false
var maximum_load_ms := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.set_process(false)
	game.autosave_enabled = false
	game.splash_active = false
	game.developer_mode_enabled = false
	game.save_path = NORMAL_SAVE
	game._start_new_culture()
	game._complete_founder_spore_germination()
	game.main_menu_active = false
	game.game_started = true
	# Controlled starting geometry; final death, growth and takeover are never injected.
	game.cores = [game._make_core(Vector2.ZERO), game._make_core(Vector2(0, 220)), game._make_core(Vector2(1000, 0))]
	game.segments.clear()
	game.feeders.clear()
	game.bacteria.clear()
	game.enemy_fungi.clear()
	game.enemy_hyphae.clear()
	game.enemy_guard_spores.clear()
	# Keep the original full-resource slow-load case in the default CI path.
	# Optional depletion isolates topology when diagnosing a future failure.
	var full_resources := not OS.get_cmdline_user_args().has("--depleted-resources")
	if not full_resources:
		for resource in game.resources:
			resource["amount"] = 0.0
			resource["alive"] = false
	game._rebuild_resource_grid()
	for core_id in [0, 2]:
		game.selected_core = core_id
		game.selected_tip_valid = false
		game._confirm_extension((game.cores[core_id]["pos"] as Vector2) + Vector2(140, 0))
	game._update_growth(game._hypha_growth_seconds())
	if not _check(game.segments.size() == 2 and float(game.segments[0]["growth"]) == 1.0, "initial branches use paid extension and timed growth"):
		return
	game._queue_dna(0)
	if not _check(not (game.cores[0]["jobs"] as Array).is_empty(), "doomed core starts with a real prepaid DNA job"):
		return
	for core_id in [0, 2]:
		game._damage_core(core_id, float(game.cores[core_id]["biomass"]) - 0.020, "bacteria_toxin")
		game.bacteria.append(game._make_bacterium(game.cores[core_id]["pos"]))
	game._update_core_hazards(10.0)
	if not _check(_two_dead_one_alive() and not game.game_over and (game.cores[0]["jobs"] as Array).is_empty(), "real toxin update kills damaged cores, clears jobs and leaves surviving colony playable"):
		return
	game.bacteria.clear()
	game._update_orphaned_segments(30.0)
	if not _check(_segment_for_owner(0).get("orphaned", false) and _segment_for_owner(2).get("orphaned", false) and is_equal_approx(float(_segment_for_owner(2)["viability"]), 1.0 - 30.0 / float(game.ORPHAN_HYPHA_DECAY_SECONDS)), "unrescued branches decay through the real update"):
		return
	if not _check(game._save_game() and _reload_now(), "damaged pre-rescue save reloads within the existing return budget"):
		return
	if not _check(_two_dead_one_alive() and bool(_segment_for_owner(0).get("orphaned", false)) and is_equal_approx(float(_segment_for_owner(2)["viability"]), 1.0 - 30.0 / float(game.ORPHAN_HYPHA_DECAY_SECONDS)), "pre-rescue reload preserves dead cores and exact orphan viability"):
		return
	var organic_before_repair := float(game.organic)
	game._repair_core(0)
	game._update_core_hazards(60.0)
	if not _check(_two_dead_one_alive() and is_equal_approx(float(game.organic), organic_before_repair), "dead core cannot buy repair or regenerate after reload"):
		return
	game.selected_core = 1
	game.selected_tip_valid = false
	var organic_before_extension := float(game.organic)
	game._confirm_extension(Vector2.ZERO)
	if not _check(game.segments.size() == 3 and float(game.organic) < organic_before_extension and float(game.segments[2]["growth"]) == 0.0, "survivor builds a paid legal rescue branch instead of injecting a connected segment"):
		return
	var rescue_ticks := 0
	while bool(_segment_for_owner(0).get("orphaned", false)) and rescue_ticks < 150:
		game._update_growth(1.0)
		game._update_orphaned_segments(1.0)
		rescue_ticks += 1
	if not _check(_segment_for_owner(0).is_empty() and _owned_segment_count(1) == 2 and bool(_segment_for_owner(2).get("orphaned", false)), "growing legal contact transfers only the touched dead-owner network to the living core"):
		return
	for segment in game.segments:
		if int(segment["core_id"]) == 1 and not _check(not bool(segment["orphaned"]) and is_equal_approx(float(segment["viability"]), 1.0), "taken-over network is active and restored without reviving its old core"):
			return
	var orphan_viability := float(_segment_for_owner(2)["viability"])
	if not _check(game._save_game() and _reload_now() and _two_dead_one_alive() and _owned_segment_count(1) == 2 and is_equal_approx(float(_segment_for_owner(2)["viability"]), orphan_viability), "post-rescue save preserves ownership and unrecovered damage"):
		return
	game._update_orphaned_segments(5.0)
	if not _check(is_equal_approx(float(_segment_for_owner(2)["viability"]), orphan_viability - 5.0 / float(game.ORPHAN_HYPHA_DECAY_SECONDS)), "unrescued branch continues decaying rather than resetting on reload"):
		return
	game._save_game()
	var stale: Dictionary = JSON.parse_string(_read(NORMAL_SAVE))
	stale["saved_at"] = Time.get_unix_time_from_system() - 48.0 * 3600.0
	_write(NORMAL_SAVE, JSON.stringify(stale))
	var alive_resources := 0
	for resource in game.resources:
		if bool(resource["alive"]):
			alive_resources += 1
	print("DAMAGED_NETWORK_FIXTURE full_resources=%s cores=%d living_cores=%d segments=%d units=%d bacteria=%d resources=%d alive_resources=%d feeders=%d absence_seconds=172800" % [full_resources, game.cores.size(), game._living_core_count(), game.segments.size(), game.expedition_units.size(), game.bacteria.size(), game.resources.size(), alive_resources, game.feeders.size()])
	if full_resources:
		_write("user://damaged_network_slow_fixture.json", JSON.stringify(stale))
	var settlement_started := Time.get_ticks_msec()
	if not _check(_reload_now() and game.offline_settlement_active, "48-hour damaged save hydrates promptly and defers settlement to frames"):
		return
	game.set_process(true)
	var frames := 0
	var previous_progress := 0.0
	var intermediate := false
	while game.offline_settlement_active and frames < MAX_PUMP_FRAMES and Time.get_ticks_msec() - settlement_started <= SETTLEMENT_BUDGET_MS:
		await process_frame
		frames += 1
		var progress := float(game.offline_settlement_progress)
		if not _check(progress + 0.000001 >= previous_progress, "damaged-save settlement progress stays monotonic"):
			return
		intermediate = intermediate or (progress > 0.0 and progress < 1.0)
		previous_progress = progress
	game.set_process(false)
	var settlement_ms := Time.get_ticks_msec() - settlement_started
	if not _check(not game.offline_settlement_active and frames >= 2 and frames < MAX_PUMP_FRAMES and intermediate and settlement_ms <= SETTLEMENT_BUDGET_MS, "damaged-save settlement yields intermediate frames within the unchanged 30-second budget (frames=%d elapsed_ms=%d progress=%.6f active=%s)" % [frames, settlement_ms, float(game.offline_settlement_progress), game.offline_settlement_active]):
		return
	if not _check(_two_dead_one_alive() and _segment_for_owner(2).is_empty() and _owned_segment_count(1) == 2 and game.offline_report_open, "offline settlement preserves deaths and rescued network, removes abandoned network and opens report"):
		return
	game._close_offline_report()
	if not _check(_reload_now() and not game.offline_settlement_active and _two_dead_one_alive() and _segment_for_owner(2).is_empty(), "checkpoint reload neither resurrects abandoned structures nor repeats settlement"):
		return
	var normal_payload := _read(NORMAL_SAVE)
	var normal_organic := float(game.organic)
	developer_save = String(game._developer_save_path())
	if not _check(not FileAccess.file_exists(developer_save) and not FileAccess.file_exists(developer_save + ".bak"), "run in an isolated user directory; never overwrite an existing developer profile"):
		return
	game._enter_developer_mode()
	if not _check(game.developer_mode_enabled and String(game.save_path) == developer_save and developer_save != NORMAL_SAVE, "real developer entry chooses a distinct profile"):
		return
	owns_developer_save = true
	game._damage_core(1, 1.0, "bacteria_toxin")
	if not _check(game._save_game() and _read(NORMAL_SAVE) == normal_payload and _reload_now() and _two_dead_one_alive() and _owned_segment_count(1) == 2, "developer save/load retains damaged topology without mutating normal slot"):
		return
	game._exit_developer_mode()
	if not _check(not game.developer_mode_enabled and String(game.save_path) == NORMAL_SAVE and _read(NORMAL_SAVE) == normal_payload and _reload_now() and is_equal_approx(float(game.organic), normal_organic) and _two_dead_one_alive() and _owned_segment_count(1) == 2, "returning to normal profile restores its own balances and damaged topology"):
		return
	_cleanup_saves()
	for player in game.pixel_audio.players:
		player.stop()
		player.stream = null
	game.pixel_audio.ambient_player.stop()
	game.pixel_audio.ambient_player.stream = null
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("DAMAGED_NETWORK_SAVE_OK assertions=%d death=real-toxin rescue=paid-grown-contact save=before+after profiles=isolated max_load_ms=%d settlement_ms=%d frames=%d" % [assertions, maximum_load_ms, settlement_ms, frames])
	quit(0)


func _reload_now() -> bool:
	var started := Time.get_ticks_msec()
	var loaded := bool(game._load_game(true))
	var elapsed := Time.get_ticks_msec() - started
	maximum_load_ms = maxi(maximum_load_ms, elapsed)
	return loaded and elapsed <= LOAD_RETURN_BUDGET_MS


func _two_dead_one_alive() -> bool:
	return game.cores.size() == 3 and not game._is_core_alive(0) and game._is_core_alive(1) and not game._is_core_alive(2) and is_zero_approx(float(game.cores[0]["biomass"])) and is_zero_approx(float(game.cores[2]["biomass"]))


func _segment_for_owner(core_id: int) -> Dictionary:
	for segment in game.segments:
		if int(segment["core_id"]) == core_id:
			return segment
	return {}


func _owned_segment_count(core_id: int) -> int:
	var count := 0
	for segment in game.segments:
		if int(segment["core_id"]) == core_id:
			count += 1
	return count


func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _write(path: String, text_value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text_value)


func _cleanup_saves() -> void:
	var paths := [NORMAL_SAVE]
	if owns_developer_save:
		paths.append(developer_save)
	for path in paths:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))


func _check(condition: bool, message: String) -> bool:
	assertions += 1
	if condition:
		return true
	push_error("DAMAGED_NETWORK_SAVE_FAIL[%d]: %s" % [assertions, message])
	_cleanup_saves()
	quit(1)
	return false
