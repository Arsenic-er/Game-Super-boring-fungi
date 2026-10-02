extends SceneTree


const Campaign = preload("res://scripts/campaign_localization.gd")
const EXPECTED_KEYS: Array[String] = [
	"hud", "title", "nest", "mission_title", "mission_desc", "rules", "home_note",
	"start", "settle_first", "progress", "return_win", "retreat", "confirm_retreat",
	"confirm", "cancel", "return_fail", "victory", "failure", "retreated", "upgrade",
	"need_materials", "next_preview", "story", "close", "save_failed", "mission_active",
	"prototype", "retry", "mission_paused", "main_nest", "progress_compact",
	"hint_extend", "hint_organic", "hint_mineral", "hint_grow", "hint_ready", "hint_dead"
]
const VALUES := {
	"level": 2, "materials": 3, "organic": "12.345", "mineral": "0.125",
	"length": "456.789", "organic_goal": "30.000", "mineral_goal": "2.000",
	"length_goal": "600.000", "reward": 3
}
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _check(Campaign.LOCALES == ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"] and Campaign.KEYS == EXPECTED_KEYS, "all seven locales and exactly thirty-seven required keys are declared"):
		return
	var originals: Dictionary = VALUES.duplicate(true)
	for locale in Campaign.LOCALES:
		var table: Dictionary = Campaign.TEXTS.get(locale, {})
		if not _check(table.size() == EXPECTED_KEYS.size(), "%s has an explicit complete table" % locale):
			return
		for key in EXPECTED_KEYS:
			if not _check(table.has(key), "%s:%s is explicitly translated" % [locale, key]):
				return
			var raw := String(table[key])
			if not _check(not raw.strip_edges().is_empty() and Campaign.text(locale, key) == raw, "%s:%s resolves locale-first without fallback or empty text" % [locale, key]):
				return
			if not _check(_tokens(raw) == _tokens(String(Campaign.TEXTS["en"][key])), "%s:%s preserves all named placeholders" % [locale, key]):
				return
			var formatted := Campaign.text(locale, key, VALUES)
			if not _check(not formatted.is_empty() and _tokens(formatted).is_empty(), "%s:%s substitutes the full runtime value set" % [locale, key]):
				return
		for key in ["mission_desc", "progress", "progress_compact"]:
			var formatted := Campaign.text(locale, key, VALUES)
			if not _check(formatted.contains("12.345") and formatted.contains("0.125") and formatted.contains("456.789") and formatted.contains("μm"), "%s:%s keeps caller precision and physical units" % [locale, key]):
				return
		if not _check(Campaign.text(locale, "hud").contains("[J]") and Campaign.text(locale, "hint_ready").contains("[J]") and Campaign.text(locale, "hint_dead").contains("[J]") and Campaign.text(locale, "home_note").contains("48") and Campaign.text(locale, "rules").contains("3") and Campaign.text(locale, "upgrade").contains("3"), "%s preserves the shortcuts, home cap and fixed material amounts" % locale):
			return
		if not _check(Campaign.text(locale, "victory", {"reward": 0}).contains("+0") and Campaign.text(locale, "nest", {"level": 0, "materials": 0}).count("0") == 2, "%s correctly formats zero instead of inventing rewards" % locale):
			return
		if not _check(Campaign.text(locale, "unknown_key") == "unknown_key", "unknown keys remain diagnosable in %s" % locale):
			return
	for pair in [["zh-Hans-CN", "zh_CN"], ["zh-Hant-HK", "zh_TW"], ["zh-HK", "zh_TW"], ["zh-MO", "zh_TW"], [" en-US ", "en"], ["ja-JP", "ja"], ["es-ES", "es"], ["de-DE", "de"], ["ru-RU", "ru"]]:
		if not _check(Campaign.text(pair[0], "title") == Campaign.text(pair[1], "title"), "%s uses its supported base locale" % pair[0]):
			return
	for unsupported in ["", "not-a-locale", "fr", "ko_KR"]:
		if not _check(Campaign.text(unsupported, "mission_desc", VALUES) == Campaign.text("en", "mission_desc", VALUES), "unknown locale falls back to fully formatted English"):
			return
	if not _check(Campaign.text("en", "nest", {"level": 2}).contains("{materials}") and VALUES == originals, "missing arguments stay visible and caller values are not modified"):
		return
	print("CAMPAIGN_LOCALIZATION_OK locales=7 keys=37 named-placeholders=matched fallback=en api=locale,key,values checks=%d" % checks)
	quit(0)


func _tokens(value: String) -> Array[String]:
	var matcher := RegEx.new()
	matcher.compile("\\{[a-z][a-z0-9_]*\\}")
	var result: Array[String] = []
	for token_match in matcher.search_all(value):
		result.append(token_match.get_string())
	result.sort()
	return result


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if condition:
		return true
	push_error("CAMPAIGN_LOCALIZATION_FAIL: " + message)
	quit(1)
	return false
