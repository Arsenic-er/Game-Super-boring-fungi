extends SceneTree


const OfflineLocalization = preload("res://scripts/offline_localization.gd")
const FORMAT_ARGUMENTS := {
	"cap_note_fmt": [48],
	"absence_fmt": ["72h", "48h", " / cap"],
	"feeder_organic_fmt": [12.345],
	"feeder_mineral_fmt": [1.234],
	"expedition_organic_fmt": [23.456],
	"expedition_mineral_fmt": [2.345],
	"balance_fmt": [34.567, -3.456],
	"dna_fmt": [5],
	"units_fmt": [6, 7, 8],
	"exploration_fmt": [9, 10.25],
	"hotspots_fmt": [11],
	"bacteria_fmt": [12, 13],
	"biomass_fmt": [-14.567, 15, 16],
	"rules_fmt": [48, 2],
	"capped_fmt": [48]
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _check(OfflineLocalization.KEYS.size() == 19, "all 19 report keys are declared"):
		return
	if not _check(OfflineLocalization.LOCALES.size() == 7, "all seven locales are declared"):
		return
	var english: Dictionary = OfflineLocalization.TEXTS["en"]
	for locale_id in OfflineLocalization.LOCALES:
		var table: Dictionary = OfflineLocalization.TEXTS.get(locale_id, {})
		if not _check(table.size() == OfflineLocalization.KEYS.size(), "%s has a complete report table" % locale_id):
			return
		for key in OfflineLocalization.KEYS:
			if not _check(table.has(key), "%s:%s is explicitly translated" % [locale_id, key]):
				return
			var value := String(table[key])
			if not _check(not value.strip_edges().is_empty(), "%s:%s is nonempty" % [locale_id, key]):
				return
			if not _check(OfflineLocalization.text(key, locale_id) == value, "%s:%s lookup uses its locale" % [locale_id, key]):
				return
			if not _check(_placeholder_signature(value) == _placeholder_signature(String(english[key])), "%s:%s preserves placeholder types, order and precision" % [locale_id, key]):
				return
			if FORMAT_ARGUMENTS.has(key):
				var formatted := value % FORMAT_ARGUMENTS[key]
				if not _check(not formatted.is_empty() and _placeholder_signature(formatted).is_empty(), "%s:%s formats with real report values" % [locale_id, key]):
					return
		var rules := OfflineLocalization.text("rules_fmt", locale_id) % [48, 2]
		if not _check(rules.contains("48") and rules.contains("2"), "%s presents separate income and risk windows" % locale_id):
			return
		var exploration := OfflineLocalization.text("exploration_fmt", locale_id) % [9, 10.25]
		if not _check(exploration.contains("+10.25%"), "%s preserves the signed exploration percentage" % locale_id):
			return
	if not _check(OfflineLocalization.text("title", "unsupported") == String(english["title"]), "unknown locales fall back to English"):
		return
	if not _check(OfflineLocalization.text("unknown_key", "en") == "unknown_key", "unknown keys stay diagnosable"):
		return
	print("OFFLINE_REPORT_I18N_OK locales=7 keys=19 placeholders=matched gains=48h risks=2h")
	quit(0)


func _placeholder_signature(value: String) -> String:
	var matcher := RegEx.new()
	matcher.compile("%[-+0 #]*\\d*(?:\\.\\d+)?[sdf]")
	var tokens: PackedStringArray = []
	for result in matcher.search_all(value):
		tokens.append(result.get_string())
	return "|".join(tokens)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("OFFLINE_REPORT_I18N_FAIL: " + message)
	quit(1)
	return false
