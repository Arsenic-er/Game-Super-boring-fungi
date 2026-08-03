extends SceneTree


const UpgradeLocalization = preload("res://scripts/upgrade_localization.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_script: Script = load("res://scripts/main.gd")
	if not _check(game_script != null, "main script should load"):
		return
	var game: Node = game_script.new()

	for locale_id in UpgradeLocalization.LOCALES:
		game.settings_locale = locale_id
		for diet_id in ["animal", "plant", "bacteria", "fungi"]:
			if not _check(game._localized_diet_name(diet_id) == UpgradeLocalization.text("diet_%s_name" % diet_id, locale_id), "%s diet name should use catalog" % locale_id):
				return
			if not _check(game._localized_diet_target(diet_id) == UpgradeLocalization.text("diet_%s_target" % diet_id, locale_id), "%s diet target should use catalog" % locale_id):
				return
		for component_id in ["trap", "enzymes", "antibiotic"]:
			if not _check(game._localized_component_name(component_id) == UpgradeLocalization.text("component_%s_name" % component_id, locale_id), "%s component name should use catalog" % locale_id):
				return
			if not _check(game._localized_component_description(component_id) == UpgradeLocalization.text("component_%s_desc" % component_id, locale_id), "%s component description should use catalog" % locale_id):
				return
		for unit_id in ["animal_attach", "plant_vessel", "lytic", "antifungal"]:
			var name_key := "unit_%s" % unit_id
			if not _check(game._localized_upgrade_unit_name(unit_id) != name_key, "%s unit name should resolve" % locale_id):
				return
			if not _check(game._localized_upgrade_unit_description(unit_id) == UpgradeLocalization.text("unit_%s_desc" % unit_id, locale_id), "%s unit description should use catalog" % locale_id):
				return

	game.settings_locale = "en"
	game.dna = 0
	game._purchase_diet("bacteria")
	if not _check(game.toast_text == UpgradeLocalization.text("toast_diet_need_fmt", "en") % game._diet_unlock_cost(), "English diet failure toast"):
		return
	if not _check(int(game.diet_levels["bacteria"]) == 0, "failed diet purchase must not change stable state"):
		return

	game.dna = 100
	game._purchase_diet("bacteria")
	if not _check(game.toast_text == UpgradeLocalization.text("toast_diet_established_fmt", "en") % game._localized_diet_name("bacteria"), "English diet success toast"):
		return
	game._purchase_diet_unit("bacteria", "lytic")
	if not _check(bool(game.diet_unit_unlocks["lytic"]), "special unit unlock should keep stable unit id"):
		return
	if not _check(game.toast_text == UpgradeLocalization.text("toast_unit_unlocked_fmt", "en") % game._localized_upgrade_unit_name("lytic"), "English special unit success toast"):
		return

	game.settings_locale = "ru"
	game.dna = 0
	game._purchase_structure("branching")
	if not _check(game.toast_text == UpgradeLocalization.text("toast_structure_need_fmt", "ru") % game._structure_cost("branching"), "Russian structure failure toast"):
		return
	game._purchase_survival("wall")
	if not _check(game.toast_text == UpgradeLocalization.text("toast_survival_need_fmt", "ru") % game._survival_cost("wall"), "Russian survival failure toast"):
		return
	game._purchase_bacteria_component("trap")
	if not _check(game.toast_text == UpgradeLocalization.text("toast_component_need_fmt", "ru") % game._bacteria_component_cost("trap"), "Russian component failure toast"):
		return

	print("UPGRADE_INTERACTION_I18N_OK locales=7 diets=4 components=3 unit_samples=4 purchases=7")
	game.free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("UPGRADE_INTERACTION_I18N_FAIL: " + message)
	quit(1)
	return false
