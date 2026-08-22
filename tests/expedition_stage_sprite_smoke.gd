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
	if not _check(game.expedition_stage_atlases.size() == 3 and game.expedition_stage_mid_atlases.size() == 3, "all full and simplified evolution atlases should load"):
		return
	var full_sizes := {"gather": Vector2(48.0, 64.0), "bacteria": Vector2(48.0, 48.0), "fungus": Vector2(48.0, 48.0)}
	var mid_sizes := {"gather": Vector2(24.0, 32.0), "bacteria": Vector2(24.0, 24.0), "fungus": Vector2(24.0, 24.0)}
	for group in ["gather", "bacteria", "fungus"]:
		var full_texture = game.expedition_stage_atlases.get(group)
		var mid_texture = game.expedition_stage_mid_atlases.get(group)
		if not _check(full_texture is Texture2D and full_texture.get_size() == full_sizes[group], "%s full atlas should use 16px logical cells" % group):
			return
		if not _check(mid_texture is Texture2D and mid_texture.get_size() == mid_sizes[group], "%s simplified atlas should use 8px logical cells" % group):
			return
	var group_by_unit := {
		"forager": "gather", "carrier": "gather", "chelator": "gather", "scout": "gather",
		"lytic": "bacteria", "suppressor": "bacteria", "disperser": "bacteria",
		"piercer": "fungus", "coil": "fungus", "antifungal": "fungus"
	}
	for unit_type in group_by_unit.keys():
		var group: String = group_by_unit[unit_type]
		for stage in range(3):
			var full_rect: Rect2 = game._expedition_stage_source_rect(unit_type, stage, false)
			var mid_rect: Rect2 = game._expedition_stage_source_rect(unit_type, stage, true)
			if not _check(full_rect.size == Vector2(16.0, 16.0) and Rect2(Vector2.ZERO, full_sizes[group]).encloses(full_rect), "%s stage %d full rect must stay inside its atlas" % [unit_type, stage]):
				return
			if not _check(mid_rect.size == Vector2(8.0, 8.0) and Rect2(Vector2.ZERO, mid_sizes[group]).encloses(mid_rect), "%s stage %d simplified rect must stay inside its atlas" % [unit_type, stage]):
				return
	game.structure_levels["growth"] = 0
	if not _check(game._expedition_visual_stage("forager") == 0, "forager should start with initial art"):
		return
	game.structure_levels["growth"] = 1
	if not _check(game._expedition_visual_stage("forager") == 1, "forager should use differentiated art after a related upgrade"):
		return
	game.structure_levels["growth"] = 3
	if not _check(game._expedition_visual_stage("forager") == 2, "forager should use mature art at high related upgrade"):
		return
	game.bacteria_components["enzymes"] = 3
	if not _check(game._expedition_visual_stage("lytic") == 2 and game._expedition_visual_stage("disperser") == 2, "bacteria component upgrades should mature matching units"):
		return
	game.diet_levels["fungi"] = 4
	if not _check(game._expedition_visual_stage("antifungal") == 2, "advanced fungi diet should use mature art"):
		return
	game.camera_zoom = 2.4
	if not _check(game._expedition_lod("forager") == 2, "maximum zoom should use the full 16px source sprite"):
		return
	game.camera_zoom = 0.65
	if not _check(game._expedition_lod("forager") == 1 and is_equal_approx(game._expedition_projected_diameter("forager"), 11.7), "default zoom should use the simplified sprite at world scale"):
		return
	game.camera_zoom = 0.25
	if not _check(game._expedition_lod("forager") == 0, "distant zoom should use a compact pixel marker"):
		return
	game.camera_zoom = 1.0
	if not _check(is_equal_approx(game._expedition_world_diameter("forager") / game._core_visual_size(), 0.375), "forager diameter must remain 37.5 percent of a core"):
		return
	print("EXPEDITION_STAGE_SPRITE_OK full_cell=16 mid_cell=8 units=10 stages=3 ratio=0.375 lod=projected_pixels")
	game.queue_free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("EXPEDITION_STAGE_SPRITE_FAIL: " + message)
	quit(1)
	return false
