extends SceneTree


const Words = preload("res://scripts/campaign_story_localization.gd")
const ChapterWords = preload("res://scripts/campaign_chapter_localization.gd")
const FONT_PATH := "res://assets/fonts/fusion-bold/fusion-bold-pixel-12px-proportional-zh_hans.ttf"
const EXPECTED_KEYS: Array[String] = [
	"first_contact_desc",
	"substrate_race_desc",
	"lost_network_desc",
	"two_fronts_desc",
	"toxic_frontier_desc",
	"boundary_counterattack_desc",
	"stable_colony_desc",
	"mission_goal_row",
	"mission_hint",
	"mission_locked_generic",
	"locked",
	"upgrade_cost",
	"nest_max",
	"chapter_progress",
	"chapter_end",
	"nest_benefits",
	"branch_transport",
	"branch_resilience",
	"branch_defense",
	"branch_buy",
	"branch_info",
	"branch_reserve",
	"trial_rules",
	"story_1",
	"story_2",
	"story_3",
	"story_4",
	"campaign_goal_contested_patches",
	"campaign_goal_absorbed_organic",
	"campaign_goal_absorbed_mineral",
	"campaign_goal_networks_rescued",
	"campaign_goal_relay_biomass",
	"campaign_goal_cargo_organic",
	"campaign_goal_cargo_mineral",
	"campaign_goal_units_returned",
	"campaign_goal_target_defeated",
	"campaign_action_begin_rescue",
	"trial_waves",
	"trial_enemies",
	"trial_organic",
	"trial_mineral",
	"trial_network",
	"trial_start_wave",
	"trial_wave_active",
	"trial_finished",
	"trial_warning_east",
	"trial_warning_west",
	"trial_warning_two_fronts",
	"mission_failed",
	"mission_failed_hint",
	"campaign_marker_contested_patch",
	"campaign_marker_orphan_network",
	"campaign_marker_damaged_relay",
	"campaign_note_contested",
	"campaign_note_rescue_prepare",
	"campaign_note_rescue_remaining",
	"campaign_note_rescue_recovered",
	"campaign_note_toxin_returns",
	"campaign_note_scout_east",
]
const VALUES := {
	"name": "Organic", "current": "12.345", "target": "180.000",
	"level": 3, "mission": "First contact", "cost": 6, "done": 7,
	"branch": "Transport", "reserve": 12, "minutes": 15, "seconds": "899.125"
}
const DESCRIPTIONS := ["first_contact_desc", "substrate_race_desc", "lost_network_desc", "two_fronts_desc", "toxic_frontier_desc", "boundary_counterattack_desc", "stable_colony_desc"]
const METRICS := [
	"campaign_goal_contested_patches", "campaign_goal_absorbed_organic",
	"campaign_goal_absorbed_mineral", "campaign_goal_networks_rescued",
	"campaign_goal_relay_biomass", "campaign_goal_cargo_organic",
	"campaign_goal_cargo_mineral", "campaign_goal_units_returned",
	"campaign_goal_target_defeated", "trial_waves", "trial_enemies",
	"trial_organic", "trial_mineral", "trial_network"
]
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _check(Words.LOCALES == ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"] and Words.KEYS == EXPECTED_KEYS and EXPECTED_KEYS.size() == 59, "seven locales and exactly 59 story/progression keys"):
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
	var digit_matcher := RegEx.new()
	digit_matcher.compile("[0-9]")
	for locale in Words.LOCALES:
		var table: Dictionary = Words.TEXTS.get(locale, {})
		if not _check(table.size() == EXPECTED_KEYS.size(), "%s has a full explicit table" % locale):
			return
		for key in EXPECTED_KEYS:
			if not _check(table.has(key), "%s:%s is explicitly translated" % [locale, key]):
				return
			var raw := String(table[key])
			if not _check(not raw.strip_edges().is_empty() and Words.text(locale, key) == raw, "%s:%s resolves without fallback" % [locale, key]):
				return
			if not _check(_tokens(raw) == _tokens(String(Words.TEXTS["en"][key])), "%s:%s preserves all named placeholders" % [locale, key]):
				return
			var value := Words.text(locale, key, VALUES)
			if not _check(not value.is_empty() and _tokens(value).is_empty(), "%s:%s formats all named values" % [locale, key]):
				return
			for index in value.length():
				var codepoint := value.unicode_at(index)
				if not _check(font.has_char(codepoint), "%s:%s ships glyph U+%04X" % [locale, key, codepoint]):
					return
			if not _check(font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > 0.0, "%s:%s has usable pixel font metrics" % [locale, key]):
				return
		for key in DESCRIPTIONS:
			if not _check(digit_matcher.search(Words.text(locale, key)) == null, "%s:%s leaves objective thresholds to the live scene" % [locale, key]):
				return
		for key in METRICS:
			if not _check(_tokens(Words.text(locale, key)).is_empty(), "%s:%s is a pure metric label" % [locale, key]):
				return
		var goal := Words.text(locale, "mission_goal_row", VALUES)
		if not _check(goal.contains("Organic") and goal.contains("12.345/180.000"), "%s generic objective rows retain caller precision" % locale):
			return
		var hint := Words.text(locale, "mission_hint")
		if not _check(hint.contains("[J]") and font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x <= 188.0, "%s objective shortcut fits the compact HUD" % locale):
			return
		var failure_hint := Words.text(locale, "mission_failed_hint")
		if not _check(failure_hint.contains("[J]") and font.get_string_size(failure_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x <= 188.0, "%s mission failure shortcut fits the compact HUD" % locale):
			return
		if not _check(Words.text(locale, "campaign_goal_relay_biomass").contains("%") and Words.text(locale, "trial_network").contains("μm"), "%s preserves relay percent and the already-converted micrometre metric" % locale):
			return
		if not _check(Words.text(locale, "nest_benefits").count("10%") == 3 and Words.text(locale, "branch_info").contains("15%"), "%s preserves all three nest bonuses and branch magnitude" % locale):
			return
		if not _check(Words.text(locale, "chapter_progress", VALUES).contains("7/9") and Words.text(locale, "branch_buy", VALUES).contains("3/2"), "%s formats caller progress rather than silently clamping it" % locale):
			return
		if not _check(Words.text(locale, "mission_goal_row", {"name": "Zero", "current": 0, "target": 1}).contains("0/1") and Words.text(locale, "upgrade_cost", {"level": 4, "cost": 0}).contains("0"), "%s represents zero values accurately" % locale):
			return
		if not _check(Words.text(locale, "unknown_key") == "unknown_key", "%s keeps unknown keys diagnosable" % locale):
			return
		if not _check(not ChapterWords.text(locale, "remote_pantry_story").is_empty() and ChapterWords.TEXTS[locale].has("planned"), "%s retains updated second-mission story and compatibility key" % locale):
			return
	for pair in [["zh-Hans-CN", "zh_CN"], ["zh-Hant-HK", "zh_TW"], ["zh-HK", "zh_TW"], ["zh-MO", "zh_TW"], [" en-US ", "en"], ["ja-JP", "ja"], ["es-ES", "es"], ["de-DE", "de"], ["ru-RU", "ru"]]:
		if not _check(Words.normalize_locale(pair[0]) == pair[1] and Words.text(pair[0], "chapter_end") == Words.text(pair[1], "chapter_end"), "%s uses its supported locale" % pair[0]):
			return
	for locale in ["", "not-a-locale", "fr", "ko_KR"]:
		if not _check(Words.text(locale, "mission_locked_generic", VALUES) == Words.text("en", "mission_locked_generic", VALUES), "unsupported locale falls back to formatted English"):
			return
	if not _check(Words.text("en", "mission_goal_row", {"current": 0}).contains("{target}") and VALUES == original_values, "missing values remain visible and inputs are never modified"):
		return
	print("CAMPAIGN_STORY_LOCALIZATION_OK locales=7 keys=59 placeholders=matched glyphs=bundled-pixel-font compact-hint=188px scene-thresholds=external checks=%d" % checks)
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
	push_error("CAMPAIGN_STORY_LOCALIZATION_FAIL: " + message)
	quit(1)
	return false
