extends SceneTree


const RivalCombatLocalization = preload("res://scripts/rival_combat_localization.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_script: Script = load("res://scripts/main.gd")
	if not _check(game_script != null, "main script loads"):
		return
	var game: Node = game_script.new()
	if not _check(game._normalize_combat_reason_id("竞争菌守卫孢子") == "enemy_guard", "legacy guard migration"):
		return
	if not _check(game._normalize_combat_reason_id("竞争真菌反击") == "rival_core_counter", "legacy core counter migration"):
		return
	if not _check(game._normalize_combat_reason_id("手动返巢") == "manual_return", "legacy return migration"):
		return
	if not _check(game._normalize_combat_reason_id("future translated text") == "unknown", "unknown reason sanitized"):
		return

	for locale_id in RivalCombatLocalization.LOCALES:
		game.settings_locale = locale_id
		for reason_id in RivalCombatLocalization.REASON_IDS:
			var reason_text: String = game._localized_combat_reason(reason_id)
			if not _check(not reason_text.is_empty() and not reason_text.begins_with("reason_"), "%s reason %s" % [locale_id, reason_id]):
				return
		var unit := {"unit_type": "piercer", "lost": false, "biomass": 1.0}
		game._mark_expedition_lost(unit, "enemy_guard")
		var unit_name: String = game._localized_unit_name("piercer")
		var expected_loss := RivalCombatLocalization.text("toast_unit_lost_fmt", locale_id) % [unit_name, RivalCombatLocalization.text("reason_enemy_guard", locale_id)]
		if not _check(game.toast_text == expected_loss, "%s localized unit loss" % locale_id):
			return

	game.settings_locale = "en"
	game.cores = [game._make_core(Vector2.ZERO, "barracks")]
	game._spawn_expedition_spore(0, "forager")
	var wounded: Dictionary = game.expedition_units[0]
	var maximum := float(wounded["max_biomass"])
	wounded["biomass"] = maximum * 0.31
	game._damage_expedition_unit(wounded, maximum * 0.02, "enemy_guard")
	if not _check(String(wounded["last_damage_source"]) == "enemy_guard" and String(wounded["retreat_reason"]) == "enemy_guard", "damage and retreat store stable IDs"):
		return
	game._set_expedition_retreat(wounded, "manual_return")
	if not _check(String(wounded["retreat_reason"]) == "manual_return", "manual return stable ID"):
		return

	print("RIVAL_COMBAT_I18N_OK locales=7 legacy=migrated damage=stable tooltip_reasons=localized")
	game.free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("RIVAL_COMBAT_I18N_FAIL: " + message)
	quit(1)
	return false
