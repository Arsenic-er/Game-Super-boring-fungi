extends SceneTree


const TEST_SAVE_PATH := "user://barracks_sprite_smoke.json"
const MAIN_TEXTURE_PATH := "res://assets/sprites/cores/main_core.png"
const MAIN_MID_TEXTURE_PATH := "res://assets/sprites/cores/main_core_mid.png"
const BARRACKS_TEXTURE_PATH := "res://assets/sprites/cores/barracks_core.png"
const BARRACKS_MID_TEXTURE_PATH := "res://assets/sprites/cores/barracks_core_mid.png"
const SaveStore = preload("res://scripts/save_store.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveStore.remove_slot(TEST_SAVE_PATH)
	for path in [MAIN_TEXTURE_PATH, MAIN_MID_TEXTURE_PATH, BARRACKS_TEXTURE_PATH, BARRACKS_MID_TEXTURE_PATH]:
		if not _check(ResourceLoader.exists(path), "core sprite must exist: %s" % path):
			return
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene should load"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.splash_active = false
	game.autosave_enabled = false
	game.save_path = TEST_SAVE_PATH
	if not _check(game.main_core_texture.get_size() == Vector2(24.0, 24.0) and game.main_core_mid_texture.get_size() == Vector2(12.0, 12.0), "main base must load 24px full and 12px simplified sprites"):
		return
	if not _check(game.barracks_core_texture.get_size() == Vector2(24.0, 24.0) and game.barracks_core_mid_texture.get_size() == Vector2(12.0, 12.0), "barracks must load 24px full and 12px simplified sprites"):
		return
	if not _check(game.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "core sprites must inherit nearest-neighbor filtering"):
		return
	if not _check(game._core_texture_for_kind("normal") == game.main_core_texture and game._core_texture_for_kind("barracks") == game.barracks_core_texture, "normal and barracks cores must route to their full sprites"):
		return
	if not _check(game._core_texture_for_kind("normal", true) == game.main_core_mid_texture and game._core_texture_for_kind("barracks", true) == game.barracks_core_mid_texture, "normal and barracks cores must route to their simplified sprites"):
		return
	game.camera_zoom = 1.0
	if not _check(is_equal_approx(game._core_visual_size(), 48.0) and is_equal_approx(game._barracks_visual_size(), 48.0), "main base and barracks must share the same 48-world-unit footprint"):
		return

	game._start_new_culture()
	if game._founder_spore_active():
		game._complete_founder_spore_germination()
	game.main_menu_active = false
	game.game_started = true
	var barracks_id: int = game.cores.size()
	game.cores.append(game._make_core(Vector2(180.0, 0.0), "barracks"))
	if not _check(String(game.cores[barracks_id].get("kind", "")) == "barracks", "runtime barracks factory must retain its visual kind"):
		return
	if not _check(game._save_game() and game._load_game(false), "barracks visual kind must survive a save round-trip"):
		return
	var loaded_barracks := false
	for core in game.cores:
		if String(core.get("kind", "normal")) == "barracks":
			loaded_barracks = game._core_texture_for_kind(String(core.get("kind", "normal"))) == game.barracks_core_texture
			break
	if not _check(loaded_barracks, "loaded barracks must still route to the barracks sprite"):
		return

	SaveStore.remove_slot(TEST_SAVE_PATH)
	print("CORE_SPRITE_OK full=24 mid=12 world=48 equal_footprint=true main=ring barracks=amber_pods")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BARRACKS_SPRITE_FAIL: " + message)
	SaveStore.remove_slot(TEST_SAVE_PATH)
	quit(1)
	return false
