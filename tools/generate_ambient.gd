extends SceneTree


func _initialize() -> void:
	var output_dir := ProjectSettings.globalize_path("res://assets/audio")
	var directory_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if directory_error != OK:
		push_error("AMBIENT_GENERATOR_FAIL: could not create assets/audio")
		quit(1)
		return
	var audio_script: Script = load("res://scripts/pixel_audio.gd")
	var maker: Node = audio_script.new()
	var stream: AudioStreamWAV = maker._make_ambient_stream()
	var save_error := stream.save_to_wav(output_dir.path_join("pixel-laboratory-nebula"))
	if save_error != OK:
		push_error("AMBIENT_GENERATOR_FAIL: save_to_wav returned %d" % save_error)
		quit(1)
		return
	print("AMBIENT_GENERATOR_OK seconds=32 rate=22050 output=res://assets/audio/pixel-laboratory-nebula.wav")
	quit(0)
