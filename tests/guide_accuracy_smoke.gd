extends SceneTree


const GuideLocalization = preload("res://scripts/guide_localization.gd")
# These terms guard the translated instructions; the runtime checks below guard
# the gameplay facts they describe. This is not a native-speaker readability test.
const FACT_TERMS := {
	"zh_CN": [["右键", "游动", "萌发", "延伸"], ["立即预付", "矿物", "计时", "不会自动续产"]],
	"zh_TW": [["右鍵", "游動", "萌發", "延伸"], ["立即預付", "礦物", "計時", "不會自動續產"]],
	"en": [["right-click", "swim", "Germinate", "Extend"], ["immediately prepays", "mineral", "takes time", "never restarts itself"]],
	"ja": [["右クリック", "泳", "発芽", "伸長"], ["即座に前払い", "ミネラル", "時間", "自動で再開しません"]],
	"es": [["clic derecho", "nadar", "Germinar", "Extender"], ["pagas de inmediato", "minerales", "tarda", "no se reinicia sola"]],
	"de": [["Rechtsklick", "schwimmt", "Keimen", "Verlängern"], ["sofort im Voraus", "Mineralionen", "Zeit", "nicht von selbst neu"]],
	"ru": [["правой", "плыть", "Прорасти", "Удлинить"], ["сразу", "предоплата", "минералов", "времени", "сама не возобновляется"]]
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var reference: Dictionary = GuideLocalization.TEXTS["en"]
	if not _check(GuideLocalization.LOCALES.size() == 7 and GuideLocalization.PAGE_IDS.size() == 6, "keep all seven languages and the six illustrated pages"):
		return
	for locale_id in GuideLocalization.LOCALES:
		var table: Dictionary = GuideLocalization.TEXTS[locale_id]
		if not _check(table.size() == reference.size(), "%s must retain all guide fields" % locale_id):
			return
		for key in reference:
			if not _check(table.has(key) and not String(table[key]).is_empty(), "%s:%s must be translated" % [locale_id, key]):
				return
		for page_index in range(2):
			var page_id: String = ["germination", "resources_dna"][page_index]
			var body: String = GuideLocalization.page(page_id, locale_id)["body"]
			if not _check(body.count("\n") == 2, "%s:%s keeps three short paragraphs" % [locale_id, page_id]):
				return
			for term in FACT_TERMS[locale_id][page_index]:
				if not _check(body.contains(term), "%s:%s should explain %s" % [locale_id, page_id, term]):
					return

	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not _check(packed != null, "main scene loads"):
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	# Audio is covered separately; this contract test need not start new cues.
	game.pixel_audio.configure(0.0, 0.0, 0.0, 0.0, 0.0)
	game.pixel_audio.ambient_player.stop()
	game.splash_active = false
	game.autosave_enabled = false
	game._start_new_culture()
	game.set_process(false)
	if not _check(game._founder_spore_active() and game.cores.is_empty() and game.segments.is_empty(), "a new culture begins with a mobile founder, not a settled core"):
		return
	var start: Vector2 = game.founder_spore["pos"]
	if not _check(game._issue_founder_spore_move(start + Vector2(40.0, 0.0)), "the founder accepts a site-selection movement order"):
		return
	game._update_founder_spore(0.25)
	var site: Vector2 = game.founder_spore["pos"]
	if not _check(site.x > start.x and site.x < start.x + 40.0 and game.cores.is_empty(), "site selection moves gradually before settlement"):
		return
	if not _check(game._begin_founder_spore_germination(), "germination can begin at the selected site"):
		return
	game._update_founder_spore(game.FOUNDER_SPORE_GERMINATION_SECONDS)
	if not _check(not game._founder_spore_active() and game.cores.size() == 1 and (game.cores[0]["pos"] as Vector2).is_equal_approx(site), "germination establishes the first core at that site"):
		return
	game.selected_core = 0
	game.selected_tip_valid = false
	game._confirm_extension(site + Vector2(60.0, 0.0))
	if not _check(game.segments.size() == 1 and (game.segments[0]["a"] as Vector2).is_equal_approx(site), "the settled core can then extend its first hypha"):
		return

	var organic_before: float = game.organic
	var mineral_before: float = game.mineral
	var dna_before: int = game.dna
	if not _check(game._queue_dna(0, 1), "normal starting resources can pay for one DNA job"):
		return
	var prepaid_organic: float = organic_before - game.DNA_ORGANIC_COST
	var prepaid_mineral: float = mineral_before - game.DNA_MINERAL_COST
	if not _check(is_equal_approx(game.organic, prepaid_organic) and is_equal_approx(game.mineral, prepaid_mineral) and game.dna == dna_before, "queue submission prepays both resources without instantly awarding DNA"):
		return
	var duration: float = game._dna_job_duration(0)
	game._update_dna_jobs(duration * 0.5)
	if not _check(game.dna == dna_before and is_equal_approx(game.organic, prepaid_organic) and is_equal_approx(game.mineral, prepaid_mineral), "the prepaid job takes time and does not charge a second time"):
		return
	game._update_dna_jobs(duration * 0.5)
	if not _check(game.dna == dna_before + 1 and (game.cores[0]["jobs"] as Array).is_empty(), "the timed job awards one DNA and empties the queue"):
		return
	game._update_dna_jobs(duration * 10.0)
	if not _check(game.dna == dna_before + 1 and (game.cores[0]["jobs"] as Array).is_empty() and is_equal_approx(game.organic, prepaid_organic) and is_equal_approx(game.mineral, prepaid_mineral), "an empty queue cannot restart or spend remaining resources automatically"):
		return
	print("GUIDE_ACCURACY_OK locales=7 pages=6 founder=move-germinate-extend dna=prepaid-timed-no-auto-renew")
	# The focused test finishes before its audio cues; let the headless mixer
	# release their playback references before destroying the scene.
	for player in game.pixel_audio.players:
		player.stop()
		player.stream = null
	game.pixel_audio.ambient_player.stop()
	game.pixel_audio.ambient_player.stream = null
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("GUIDE_ACCURACY_FAIL: " + message)
	quit(1)
	return false
