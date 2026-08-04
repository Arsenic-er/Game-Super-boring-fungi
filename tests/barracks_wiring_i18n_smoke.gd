extends SceneTree


const BarracksLocalization = preload("res://scripts/barracks_localization.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_script: Script = load("res://scripts/main.gd")
	if not _check(game_script != null, "main script loads"):
		return
	var game: Node = game_script.new()
	for locale_id in BarracksLocalization.LOCALES:
		game.settings_locale = locale_id
		game.cores = [game._make_core(Vector2.ZERO, "barracks")]
		game.selected_core = 0
		game._set_barracks_rally(0, Vector2(40.0, 0.0))
		if not _check(game.toast_text == BarracksLocalization.text("toast_rally_set", locale_id), "%s rally set" % locale_id):
			return
		game._clear_barracks_rally(0)
		if not _check(game.toast_text == BarracksLocalization.text("toast_rally_cleared", locale_id), "%s rally cleared" % locale_id):
			return
		game._toggle_barracks_auto(0)
		var expected_auto := BarracksLocalization.text("toast_auto_replenish_fmt", locale_id) % BarracksLocalization.text("common_enabled", locale_id)
		if not _check(game.toast_text == expected_auto, "%s auto replenish" % locale_id):
			return
		game._cycle_barracks_auto_target(0)
		var expected_target := BarracksLocalization.text("toast_auto_target_fmt", locale_id) % int(game.cores[0]["auto_replenish_target"])
		if not _check(game.toast_text == expected_target, "%s auto target" % locale_id):
			return
		game.cores[0]["auto_replenish"] = false
		game.cores[0]["production_unit"] = "forager"
		if not _check(game._begin_barracks_directive_mode("defense"), "%s defense directive starts" % locale_id):
			return
		var expected_prompt := BarracksLocalization.text("toast_directive_prompt_fmt", locale_id) % [game._localized_unit_name("forager"), BarracksLocalization.text("directive_defense", locale_id)]
		if not _check(game.toast_text == expected_prompt, "%s directive prompt" % locale_id):
			return
		game._clear_barracks_directive(0)
		if not _check(game.toast_text == BarracksLocalization.text("toast_directive_cleared_fmt", locale_id) % 0, "%s directive clear" % locale_id):
			return
	print("BARRACKS_WIRING_I18N_OK locales=7 rally=localized auto=localized directives=localized")
	game.free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BARRACKS_WIRING_I18N_FAIL: " + message)
	quit(1)
	return false
