extends Node

const MIX_RATE := 22050
const PLAYER_POOL_SIZE := 12
const AMBIENT_SECONDS := 32.0
const AMBIENT_TEMPLATE: AudioStreamWAV = preload("res://assets/audio/pixel-laboratory-nebula.wav")
const UI_CUES := ["ui_hover", "ui_click", "ui_confirm", "ui_cancel", "ui_error", "panel_open", "panel_close", "save", "zoom_scan", "select_core", "select_unit", "command", "return_order"]
const COMBAT_CUES := ["attack", "lytic_burst", "hypha_cut", "damage", "loss", "warning"]

const CUE_SPECS := {
	"ui_hover": {"duration": 0.045, "start": 920.0, "end": 1120.0, "wave": "square", "gain": 0.16, "interval": 0.045},
	"ui_click": {"duration": 0.080, "start": 620.0, "end": 820.0, "wave": "square", "gain": 0.22, "interval": 0.035},
	"ui_confirm": {"duration": 0.150, "start": 620.0, "end": 1040.0, "wave": "triangle", "gain": 0.25, "interval": 0.080},
	"ui_cancel": {"duration": 0.120, "start": 520.0, "end": 260.0, "wave": "square", "gain": 0.18, "interval": 0.080},
	"ui_error": {"duration": 0.180, "start": 190.0, "end": 125.0, "wave": "pulse", "gain": 0.24, "interval": 0.260},
	"panel_open": {"duration": 0.180, "start": 310.0, "end": 720.0, "wave": "triangle", "gain": 0.20, "interval": 0.100},
	"panel_close": {"duration": 0.140, "start": 620.0, "end": 300.0, "wave": "triangle", "gain": 0.17, "interval": 0.100},
	"save": {"duration": 0.250, "start": 440.0, "end": 880.0, "wave": "arpeggio", "gain": 0.22, "interval": 0.500},
	"zoom_scan": {"duration": 0.055, "start": 1180.0, "end": 960.0, "wave": "square", "gain": 0.10, "interval": 0.080},
	"select_core": {"duration": 0.120, "start": 280.0, "end": 560.0, "wave": "triangle", "gain": 0.22, "interval": 0.100},
	"select_unit": {"duration": 0.090, "start": 760.0, "end": 940.0, "wave": "square", "gain": 0.19, "interval": 0.075},
	"command": {"duration": 0.145, "start": 480.0, "end": 760.0, "wave": "radar", "gain": 0.25, "interval": 0.110},
	"return_order": {"duration": 0.180, "start": 740.0, "end": 370.0, "wave": "radar", "gain": 0.22, "interval": 0.160},
	"hypha_grow": {"duration": 0.360, "start": 170.0, "end": 610.0, "wave": "scan", "gain": 0.19, "interval": 0.280},
	"hypha_complete": {"duration": 0.180, "start": 520.0, "end": 880.0, "wave": "triangle", "gain": 0.17, "interval": 0.350},
	"organic_absorb": {"duration": 0.095, "start": 220.0, "end": 285.0, "wave": "triangle", "gain": 0.10, "interval": 0.650},
	"mineral_absorb": {"duration": 0.120, "start": 780.0, "end": 1320.0, "wave": "triangle", "gain": 0.13, "interval": 0.750},
	"dna_queue": {"duration": 0.210, "start": 360.0, "end": 680.0, "wave": "arpeggio", "gain": 0.23, "interval": 0.180},
	"dna_ready": {"duration": 0.430, "start": 440.0, "end": 1320.0, "wave": "arpeggio", "gain": 0.28, "interval": 0.450},
	"upgrade": {"duration": 0.360, "start": 330.0, "end": 990.0, "wave": "arpeggio", "gain": 0.27, "interval": 0.250},
	"core_build": {"duration": 0.520, "start": 130.0, "end": 520.0, "wave": "scan", "gain": 0.25, "interval": 0.450},
	"repair": {"duration": 0.300, "start": 260.0, "end": 720.0, "wave": "scan", "gain": 0.19, "interval": 0.450},
	"cargo_deposit": {"duration": 0.190, "start": 340.0, "end": 760.0, "wave": "arpeggio", "gain": 0.16, "interval": 0.350},
	"unit_queue": {"duration": 0.160, "start": 240.0, "end": 390.0, "wave": "pulse", "gain": 0.18, "interval": 0.180},
	"unit_spawn": {"duration": 0.230, "start": 310.0, "end": 920.0, "wave": "triangle", "gain": 0.24, "interval": 0.220},
	"deploy": {"duration": 0.300, "start": 190.0, "end": 470.0, "wave": "radar", "gain": 0.22, "interval": 0.260},
	"attack": {"duration": 0.075, "start": 180.0, "end": 95.0, "wave": "noise", "gain": 0.15, "interval": 0.330},
	"lytic_burst": {"duration": 0.320, "start": 980.0, "end": 210.0, "wave": "radar", "gain": 0.26, "interval": 0.450},
	"hypha_cut": {"duration": 0.190, "start": 260.0, "end": 110.0, "wave": "noise", "gain": 0.22, "interval": 0.300},
	"damage": {"duration": 0.105, "start": 145.0, "end": 90.0, "wave": "pulse", "gain": 0.13, "interval": 0.300},
	"loss": {"duration": 0.480, "start": 330.0, "end": 72.0, "wave": "pulse", "gain": 0.26, "interval": 0.600},
	"warning": {"duration": 0.460, "start": 220.0, "end": 440.0, "wave": "alarm", "gain": 0.24, "interval": 1.000},
	"discovery": {"duration": 0.380, "start": 520.0, "end": 1180.0, "wave": "arpeggio", "gain": 0.25, "interval": 0.500},
	"goal": {"duration": 0.520, "start": 390.0, "end": 1170.0, "wave": "arpeggio", "gain": 0.28, "interval": 0.500}
}

var cue_streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var ambient_player: AudioStreamPlayer
var random := RandomNumberGenerator.new()
var last_play_ms: Dictionary = {}
var debug_play_counts: Dictionary = {}
var player_cursor := 0
var recent_play_times: Array[int] = []
var master_volume := 0.80
var ui_volume := 0.75
var world_volume := 0.65
var combat_volume := 0.70
var ambient_volume := 0.35
var context_gain := 1.0


func _ready() -> void:
	random.seed = 0x510A8
	for cue_name in CUE_SPECS:
		cue_streams[cue_name] = _make_cue_stream(CUE_SPECS[cue_name])
	for _index in range(PLAYER_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.max_polyphony = 1
		add_child(player)
		players.append(player)
	ambient_player = AudioStreamPlayer.new()
	# The original procedural loop is baked with tools/generate_ambient.gd so normal
	# launches do not synchronously synthesize 705,600 frames on the main thread.
	var ambient_stream: AudioStreamWAV = AMBIENT_TEMPLATE.duplicate()
	ambient_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambient_stream.loop_begin = 0
	ambient_stream.loop_end = int(AMBIENT_SECONDS * MIX_RATE)
	ambient_player.stream = ambient_stream
	add_child(ambient_player)
	_apply_mix()
	ambient_player.play()


func configure(new_master_volume: float, new_ui_volume: float, new_world_volume: float, new_combat_volume: float, new_ambient_volume: float) -> void:
	master_volume = clampf(new_master_volume, 0.0, 1.0)
	ui_volume = clampf(new_ui_volume, 0.0, 1.0)
	world_volume = clampf(new_world_volume, 0.0, 1.0)
	combat_volume = clampf(new_combat_volume, 0.0, 1.0)
	ambient_volume = clampf(new_ambient_volume, 0.0, 1.0)
	_apply_mix()


func update_context(in_main_menu: bool, paused: bool, failed: bool, camera_zoom: float) -> void:
	var far_view := clampf((0.080 - camera_zoom) / 0.062, 0.0, 1.0)
	context_gain = lerpf(0.76, 1.0, far_view)
	if in_main_menu:
		context_gain *= 0.72
	elif paused:
		context_gain *= 0.52
	elif failed:
		context_gain *= 0.24
	if ambient_player != null:
		ambient_player.pitch_scale = 0.94 if in_main_menu else lerpf(1.02, 0.97, far_view)
	_apply_mix()


func play_cue(cue_name: String, strength: float = 1.0, force: bool = false) -> bool:
	if master_volume <= 0.0001 or not cue_streams.has(cue_name):
		return false
	var spec: Dictionary = CUE_SPECS[cue_name]
	var now := Time.get_ticks_msec()
	var interval_ms := int(float(spec.get("interval", 0.0)) * 1000.0)
	if not force and now - int(last_play_ms.get(cue_name, -1000000)) < interval_ms:
		return false
	while not recent_play_times.is_empty() and now - recent_play_times[0] >= 1000:
		recent_play_times.pop_front()
	var priority := ["warning", "loss", "goal", "ui_confirm", "command", "return_order"].has(cue_name)
	if recent_play_times.size() >= 12 and not priority:
		return false
	var category_volume := ui_volume if UI_CUES.has(cue_name) else (combat_volume if COMBAT_CUES.has(cue_name) else world_volume)
	if category_volume <= 0.0001:
		return false
	last_play_ms[cue_name] = now
	recent_play_times.append(now)
	var player := _next_player()
	player.stream = cue_streams[cue_name]
	player.pitch_scale = 1.0 + random.randf_range(-0.025, 0.025)
	var gain := clampf(float(spec.get("gain", 0.2)) * clampf(strength, 0.25, 1.5) * master_volume * category_volume, 0.0001, 1.0)
	player.volume_db = linear_to_db(gain)
	player.play()
	debug_play_counts[cue_name] = int(debug_play_counts.get(cue_name, 0)) + 1
	return true


func cue_count(cue_name: String) -> int:
	return int(debug_play_counts.get(cue_name, 0))


func _next_player() -> AudioStreamPlayer:
	for player in players:
		if not player.playing:
			return player
	var player := players[player_cursor % players.size()]
	player_cursor = (player_cursor + 1) % players.size()
	return player


func _apply_mix() -> void:
	if ambient_player == null:
		return
	var gain := maxf(0.0001, master_volume * ambient_volume * 0.34 * context_gain)
	ambient_player.volume_db = linear_to_db(gain)
	if master_volume > 0.0001 and ambient_volume > 0.0001 and not ambient_player.playing:
		ambient_player.play()


func _make_cue_stream(spec: Dictionary) -> AudioStreamWAV:
	var duration := float(spec.get("duration", 0.1))
	var frame_count := maxi(2, int(duration * MIX_RATE))
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var phase := 0.0
	var start_frequency := float(spec.get("start", 440.0))
	var end_frequency := float(spec.get("end", start_frequency))
	var wave := String(spec.get("wave", "square"))
	for frame in range(frame_count):
		var t := float(frame) / float(frame_count - 1)
		var frequency := lerpf(start_frequency, end_frequency, t)
		if wave == "arpeggio":
			frequency *= [1.0, 1.25, 1.5, 2.0][mini(3, int(t * 4.0))]
		elif wave == "alarm":
			frequency *= 1.0 if int(t * 6.0) % 2 == 0 else 1.35
		phase += TAU * frequency / MIX_RATE
		var sample := _wave_sample(wave, phase, t, frame)
		var attack := minf(1.0, t / 0.055)
		var release := pow(maxf(0.0, 1.0 - t), 1.35)
		if wave == "radar":
			release *= 0.55 + 0.45 * sin(t * PI)
		var value := clampi(int(sample * attack * release * 32767.0), -32768, 32767)
		data.encode_s16(frame * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _wave_sample(wave: String, phase: float, t: float, frame: int) -> float:
	match wave:
		"triangle", "arpeggio":
			return asin(sin(phase)) * 2.0 / PI
		"pulse":
			return 0.78 if fmod(phase, TAU) < TAU * 0.28 else -0.58
		"noise":
			var grit := sin(float(frame * 73 + 19) * 0.47) * sin(float(frame * 31 + 7) * 0.19)
			return grit * (0.55 + 0.45 * sin(phase))
		"radar":
			return sin(phase) * (0.55 + 0.45 * sign(sin(phase * 0.5)))
		"scan":
			return asin(sin(phase)) * 1.4 / PI + sin(phase * 0.5) * 0.24
		"alarm":
			return (1.0 if sin(phase) >= 0.0 else -1.0) * (0.65 + 0.20 * sin(t * TAU * 3.0))
		_:
			return 0.72 if sin(phase) >= 0.0 else -0.72


func _make_ambient_stream() -> AudioStreamWAV:
	var frame_count := int(AMBIENT_SECONDS * MIX_RATE)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	for frame in range(frame_count):
		var seconds := float(frame) / MIX_RATE
		var loop_t := seconds / AMBIENT_SECONDS
		var hum := sin(TAU * 55.0 * seconds) * 0.34 + sin(TAU * 82.5 * seconds) * 0.14
		var scanner_gate := pow(maxf(0.0, sin(TAU * (loop_t * 3.0 + 0.08))), 18.0)
		var scanner := sin(TAU * (660.0 + 110.0 * sin(TAU * loop_t)) * seconds) * scanner_gate * 0.22
		var star_gate := pow(maxf(0.0, sin(TAU * (loop_t * 5.0 + 0.31))), 28.0)
		var star := asin(sin(TAU * 990.0 * seconds)) * 2.0 / PI * star_gate * 0.13
		var digital_air := sin(TAU * 137.5 * seconds) * sin(TAU * 0.25 * seconds) * 0.07
		var sample := clampf((hum + scanner + star + digital_air) * 0.42, -0.95, 0.95)
		data.encode_s16(frame * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	return stream
