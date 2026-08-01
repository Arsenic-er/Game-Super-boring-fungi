extends SceneTree


const GameplayLocalization = preload("res://scripts/gameplay_localization.gd")


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
	game._start_new_culture()
	game.game_started = true
	game.main_menu_active = false
	game.selected_core = 0
	game.selected_tip_valid = false
	game.mode = "normal"
	game.menu_anim = 1.0

	var unit_types: Array[String] = ["forager", "carrier", "chelator", "scout", "lytic", "suppressor", "disperser", "piercer", "coil", "antifungal"]
	var states: Array[String] = ["idle", "moving", "gathering", "attacking", "attacking_fungus", "attacking_hypha", "attacking_guard", "deploying", "deployed", "returning", "retreating", "repairing", "wounded", "guarding"]
	for locale_id in GameplayLocalization.LOCALES:
		game.settings_locale = locale_id
		var dna_title: String = game._dna_batch_tooltip_title(0, 5)
		var dna_cost: String = game._dna_batch_tooltip_cost(5)
		if not _check(not _has_format_token(dna_title) and not _has_format_token(dna_cost), "%s DNA tooltip should format every placeholder" % locale_id):
			return
		for unit_type in unit_types:
			var unit_name: String = game._localized_unit_name(unit_type)
			if not _check(not unit_name.is_empty() and not unit_name.begins_with("unit_"), "%s:%s should resolve a localized unit name" % [locale_id, unit_type]):
				return
		for state in states:
			var state_name: String = game._expedition_state_name(state)
			if not _check(not state_name.is_empty() and not state_name.begins_with("state_"), "%s:%s should resolve a localized state" % [locale_id, state]):
				return

		var buttons: Array = game._current_menu_buttons()
		if not _check(buttons.size() == 6, "%s core radial menu should keep six actions" % locale_id):
			return
		for button in buttons:
			var label := String(button.get("label", ""))
			var title := String(button.get("tooltip_title", ""))
			var cost := String(button.get("tooltip_cost", ""))
			if not _check(not label.is_empty() and not title.is_empty() and not cost.is_empty(), "%s radial text should not be empty" % locale_id):
				return
			if not _check(not _looks_like_key(label) and not _looks_like_key(title) and not _looks_like_key(cost), "%s radial text should not echo catalog keys" % locale_id):
				return
			if not _check(not _has_format_token(title) and not _has_format_token(cost), "%s radial tooltip should format every placeholder" % locale_id):
				return
			var radius := float(button.get("radius", 0.0))
			var max_width := maxf(8.0, radius * 2.0 - 8.0)
			var font_size: int = game._fit_font_size(label, max_width, 12, 8)
			var width: float = game.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			if not _check(width <= max_width + 0.01, "%s radial label should fit after shrinking" % locale_id):
				return

		var core_name := GameplayLocalization.text("core_type_spore", locale_id)
		var core_hover := GameplayLocalization.text("hover_core_fmt", locale_id) % [core_name, 1, 87.5]
		var bacteria_line := GameplayLocalization.text("bacteria_suppressed_fmt", locale_id) % [GameplayLocalization.text("suppress_source_core", locale_id), 30.0]
		if not _check(not _has_format_token(core_hover) and not _has_format_token(bacteria_line), "%s common hover samples should format cleanly" % locale_id):
			return

	print("CORE_GAMEPLAY_I18N_OK locales=7 radial=6 units=10 states=14")
	game.queue_free()
	quit(0)


func _has_format_token(value: String) -> bool:
	var matcher := RegEx.new()
	matcher.compile("%(?:\\.\\d+)?[sdf]")
	return matcher.search(value) != null


func _looks_like_key(value: String) -> bool:
	for prefix in ["hud_", "core_", "stat_", "hover_", "unit_", "state_", "bacteria_", "resource_", "suppress_"]:
		if value.begins_with(prefix):
			return true
	return false


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CORE_GAMEPLAY_I18N_FAIL: " + message)
	quit(1)
	return false
