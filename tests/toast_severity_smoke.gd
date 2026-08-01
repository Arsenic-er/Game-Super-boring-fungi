extends SceneTree


class AudioSpy:
	extends Node

	var cues: Array[String] = []


	func play_cue(cue_name: String, _strength: float = 1.0, _force: bool = false) -> bool:
		cues.append(cue_name)
		return true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_script: Script = load("res://scripts/main.gd")
	if not _check(game_script != null, "main script should load"):
		return
	var game: Node = game_script.new()
	var audio_spy := AudioSpy.new()
	game.pixel_audio = audio_spy

	game.toast("Not enough biomass", 1.0, "error")
	if not _check(audio_spy.cues == ["ui_error"], "explicit error should play ui_error for non-Chinese text"):
		return

	audio_spy.cues.clear()
	game.toast("资源不足，但这是说明文字", 1.0, "info")
	if not _check(audio_spy.cues.is_empty(), "explicit info should not infer an error from Chinese markers"):
		return

	audio_spy.cues.clear()
	game.toast("有机营养不足", 1.0)
	if not _check(audio_spy.cues == ["ui_error"], "legacy auto mode should preserve Chinese marker detection"):
		return

	print("TOAST_SEVERITY_OK error=explicit info=silent auto=compatible")
	audio_spy.free()
	game.free()
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("TOAST_SEVERITY_FAIL: " + message)
	quit(1)
	return false

# End of toast severity smoke coverage.
