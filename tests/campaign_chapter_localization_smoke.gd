extends SceneTree


const Words = preload("res://scripts/campaign_chapter_localization.gd")
const BaseWords = preload("res://scripts/campaign_localization.gd")
const FONT_PATH := "res://assets/fonts/fusion-bold/fusion-bold-pixel-12px-proportional-zh_hans.ttf"
const EXPECTED_KEYS: Array[String] = [
	"remote_pantry_title", "remote_pantry_desc", "transport_progress", "transport_progress_compact",
	"hint_barracks", "hint_chelator", "hint_transport_organic", "hint_transport_mineral",
	"choose_mission", "mission_locked", "mission_ready", "mission_done", "remote_pantry_story",
	"inheritance_note", "first_supply_title", "first_contact_title", "substrate_race_title",
	"lost_network_title", "two_fronts_title", "toxic_frontier_title", "boundary_counterattack_title",
	"stable_colony_title", "planned", "chapter_roster"
]
const VALUES := {"organic": "12.345", "organic_goal": "180", "mineral": "0.125", "mineral_goal": "8"}
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _check(Words.LOCALES == ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"] and Words.KEYS == EXPECTED_KEYS, "seven locales and exactly 24 chapter keys"):
		return
	var font = load(FONT_PATH)
	if not _check(font is FontFile, "the shipped pixel font loads"):
		return
	font = font.duplicate()
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.generate_mipmaps = false
	var original_values := VALUES.duplicate(true)
	for locale in Words.LOCALES:
		var table: Dictionary = Words.TEXTS.get(locale, {})
		if not _check(table.size() == EXPECTED_KEYS.size(), "%s has a full explicit table" % locale):
			return
		for key in EXPECTED_KEYS:
			if not _check(table.has(key), "%s:%s is translated explicitly" % [locale, key]):
				return
			var raw := String(table[key])
			if not _check(not raw.strip_edges().is_empty() and Words.text(locale, key) == raw, "%s:%s resolves without a fallback" % [locale, key]):
				return
			if not _check(_tokens(raw) == _tokens(String(Words.TEXTS["en"][key])), "%s:%s preserves named placeholders" % [locale, key]):
				return
			var value := Words.text(locale, key, VALUES)
			if not _check(not value.is_empty() and _tokens(value).is_empty(), "%s:%s formats all placeholders" % [locale, key]):
				return
			for index in value.length():
				var codepoint := value.unicode_at(index)
				if not _check(font.has_char(codepoint), "%s:%s ships glyph U+%04X" % [locale, key, codepoint]):
					return
			if not _check(font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > 0.0, "%s:%s has usable pixel font metrics" % [locale, key]):
				return
		for key in ["remote_pantry_desc", "transport_progress", "transport_progress_compact"]:
			var value := Words.text(locale, key, VALUES)
			if not _check(value.contains("12.345") and value.contains("0.125"), "%s:%s retains three-decimal caller precision" % [locale, key]):
				return
		for key in ["transport_progress", "transport_progress_compact"]:
			var value := Words.text(locale, key, VALUES)
			if not _check(value.contains("12.345/180") and value.contains("0.125/8"), "%s:%s retains both delivery targets" % [locale, key]):
				return
		for key in ["hint_barracks", "hint_chelator", "hint_transport_organic", "hint_transport_mineral"]:
			var value := Words.text(locale, key)
			var measured: Vector2 = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 7)
			if not _check(measured.x <= 188.0, "%s:%s fits the compact HUD at its minimum font size (%.1f px)" % [locale, key, measured.x]):
				return
		if not _check(Words.text(locale, "hint_barracks").contains("2") and Words.text(locale, "hint_chelator").contains("4") and Words.text(locale, "mission_locked").contains("2") and BaseWords.text(locale, "rules").contains("3"), "%s preserves live costs, unlock level and reward" % locale):
			return
		if not _check(Words.text(locale, "unknown_key") == "unknown_key", "%s unknown keys remain diagnosable" % locale):
			return
	for pair in [["zh-Hans-CN", "zh_CN"], ["zh-Hant-HK", "zh_TW"], ["zh-HK", "zh_TW"], ["zh-MO", "zh_TW"], [" en-US ", "en"], ["ja-JP", "ja"], ["es-ES", "es"], ["de-DE", "de"], ["ru-RU", "ru"]]:
		if not _check(Words.normalize_locale(pair[0]) == pair[1] and Words.text(pair[0], "remote_pantry_title") == Words.text(pair[1], "remote_pantry_title"), "%s resolves its supported locale" % pair[0]):
			return
	for locale in ["", "not-a-locale", "fr", "ko_KR"]:
		if not _check(Words.text(locale, "remote_pantry_desc", VALUES) == Words.text("en", "remote_pantry_desc", VALUES), "unsupported locale uses formatted English"):
			return
	if not _check(Words.text("en", "transport_progress", {"organic": 0}).contains("{mineral}") and VALUES == original_values, "missing arguments stay visible and caller data remains unchanged"):
		return
	print("CAMPAIGN_CHAPTER_LOCALIZATION_OK locales=7 keys=24 placeholders=matched glyphs=bundled-pixel-font compact-hints=188px checks=%d" % checks)
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
	push_error("CAMPAIGN_CHAPTER_LOCALIZATION_FAIL: " + message)
	quit(1)
	return false
