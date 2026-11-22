extends Node

const BIRD_LEVEL_DB := -25.0
const FOOTSTEPS := {
	&"soil": {"pitch": 92.0, "ring": 0.17, "grit": 0.40, "decay": 31.0, "level": -30.0},
	&"mud": {"pitch": 110.0, "ring": 0.18, "grit": 0.34, "decay": 22.0, "level": -30.0},
	&"wood": {"pitch": 137.0, "ring": 0.48, "grit": 0.15, "decay": 29.0, "level": -30.0},
	&"stone": {"pitch": 175.0, "ring": 0.26, "grit": 0.36, "decay": 39.0, "level": -31.0},
	&"cave": {"pitch": 175.0, "ring": 0.26, "grit": 0.36, "decay": 39.0, "level": -25.0},
	&"water": {"pitch": 262.0, "ring": 0.08, "grit": 0.48, "decay": 17.0, "level": -28.0},
}
const STEP_VARIANTS := 3

var step: = AudioStreamPlayer.new()
var step_variant := 0
var bird := AudioStreamPlayer3D.new()
var silence: = 3.0
var rain_air := AudioStreamPlayer.new()
var rain_roof := AudioStreamPlayer.new()
var thunder := AudioStreamPlayer.new()
var cave_air := AudioStreamPlayer3D.new()
var rope_snap := AudioStreamPlayer3D.new()
var piece_pulse := AudioStreamPlayer.new()
var cave_air_gain := 0.0
var rain_gain := 0.0
var roof_mix := 0.0
var thunder_wait := 11.0
static var open_rain: AudioStreamWAV
static var covered_rain: AudioStreamWAV
static var distant_thunder: AudioStreamWAV
static var cave_wind: AudioStreamWAV
static var footstep_samples := {}
var rng: = RandomNumberGenerator.new()

func _ready():
	rng.seed = 1871
	add_child(step)
	add_child(bird)
	bird.stream = bird_call()
	bird.volume_db = BIRD_LEVEL_DB
	bird.unit_size = 10.0
	bird.max_distance = 38.0
	if not open_rain:
		open_rain = rain_sound(false)
		covered_rain = rain_sound(true)
		distant_thunder = thunder_sound()
		cave_wind = cave_wind_sound()
		for surface: StringName in FOOTSTEPS:
			var variants: Array[AudioStreamWAV] = []
			for variant in STEP_VARIANTS:
				variants.append(footstep_sample(surface, variant))
			footstep_samples[surface] = variants
	add_child(rain_air)
	add_child(rain_roof)
	add_child(thunder)
	add_child(cave_air)
	add_child(rope_snap)
	add_child(piece_pulse)
	rain_air.stream = open_rain
	rain_roof.stream = covered_rain
	thunder.stream = distant_thunder
	cave_air.stream = cave_wind
	cave_air.unit_size = 9.0
	cave_air.max_distance = 39.0
	cave_air.panning_strength = 0.48
	rope_snap.stream = rope_snap_sound()
	rope_snap.unit_size = 8.0
	rope_snap.volume_db = -18.0
	piece_pulse.stream = piece_pulse_sound()

func play_piece_pulse(intensity: float):
	piece_pulse.volume_db = lerpf(-46.0, -37.0, intensity)
	piece_pulse.play()

static func piece_pulse_sound() -> AudioStreamWAV:
	const RATE := 22050
	var count := int(RATE * 0.20)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var phase := TAU * t * (156.0 + 49.0 * t)
		var envelope := smoothstep(0.0, 0.047, t) * (1.0 - smoothstep(0.065, 0.20, t))
		var tone := sin(phase) * 0.66 + sin(phase * 1.51) * 0.09
		samples.encode_s16(2 * i, int(tone * envelope * 17000.0))
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = RATE
	wave.data = samples
	return wave

func play_rope_snap(at: Vector3):
	rope_snap.position = at
	rope_snap.play()

static func rope_snap_sound() -> AudioStreamWAV:
	const RATE := 22050
	var count := int(RATE * 0.38)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 7564
	var grain := 0.0
	for i in count:
		var t := float(i) / RATE
		grain = lerpf(grain, noise.randf_range(-1.0, 1.0), 0.28)
		var snap := maxf(t - 0.056, 0.0)
		var strain := (1.0 - smoothstep(0.041, 0.056, t)) * smoothstep(0.0, 0.037, t)
		var crack := smoothstep(0.0, 0.003, snap) * exp(-snap * 35.0)
		var sound := grain * (0.23 * strain + 0.72 * crack) + 0.26 * sin(TAU * 218.0 * snap) * crack
		samples.encode_s16(2 * i, int(sound * 27000.0))
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = RATE
	wave.data = samples
	return wave

func bird_call() -> AudioStreamWAV:
	const RATE := 22050
	var count := int(RATE * 0.42)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / RATE
		var pulse := sin(PI * fmod(t, 0.21) / 0.21)
		var pitch := 1740.0 + 565.0 * pulse - t * 510.0
		phase += TAU * pitch / RATE
		var value := (sin(phase) + 0.13 * sin(phase * 2.0)) * pow(pulse, 3) * exp(-t * 2.9) * 0.72
		samples.encode_s16(i * 2, int(value * 18000))
	var wave: = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = RATE
	wave.data = samples
	return wave

func play_footstep(surface: StringName, impact: float):
	step.stream = footstep_samples[surface][step_variant]
	step_variant = (step_variant + 1) % STEP_VARIANTS
	step.pitch_scale = rng.randf_range(0.93, 1.07) - impact * 0.07
	step.volume_db = float(FOOTSTEPS[surface].level) + rng.randf_range(-1.4, 0.6) + impact * 3.6
	step.play()

static func footstep_sample(surface: StringName, variant: int) -> AudioStreamWAV:
	const RATE := 22050
	const COUNT := 6615
	var profile: Dictionary = FOOTSTEPS[surface]
	var random := RandomNumberGenerator.new()
	random.seed = 690 + variant * 127
	var wet := surface in [&"mud", &"water"]
	var frequency := float(profile.pitch) * random.randf_range(0.89, 1.11)
	var second_contact := random.randf_range(0.028, 0.049)
	var filtered := 0.0
	var phase := 0.0
	var direct := PackedFloat32Array()
	direct.resize(COUNT)
	for i in COUNT:
		var t := float(i) / RATE
		var white := random.randf_range(-1.0, 1.0)
		filtered = lerpf(filtered, white, 0.09 if wet else 0.22)
		var heel := minf(t * 290.0, 1.0) * exp(-t * float(profile.decay))
		var toe_time := maxf(0.0, t - second_contact)
		var toe := minf(toe_time * 170.0, 1.0) * exp(-toe_time * 54.0)
		var grit := (white * 0.26 + filtered * 0.84) * (heel + toe * 0.54)
		phase += TAU * frequency * (1.0 + 0.24 * exp(-t * 28.0)) / RATE
		var knock := (sin(phase) * 0.63 + sin(phase * 1.51) * 0.20) * heel
		var value := grit * float(profile.grit) + knock * float(profile.ring)
		if wet:
			var spray := pow(0.5 + 0.5 * sin(t * TAU * (34.0 + 10.0 * variant)), 2.6)
			value += (filtered + sin(phase * 2.91) * 0.12) * spray * toe * 0.31
		direct[i] = value
	var data := PackedByteArray()
	data.resize(COUNT * 2)
	var reflection := 0.0
	for i in COUNT:
		var value := direct[i]
		if surface == &"cave":
			var bounce := direct[i - 950] * 0.31 if i >= 950 else 0.0
			if i >= 2095: bounce += direct[i - 2095] * 0.13
			reflection = lerpf(reflection, bounce, 0.28)
			value += reflection
		data.encode_s16(i * 2, roundi(clampf(value, -1.0, 1.0) * 29490.0))
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = RATE
	wave.data = data
	return wave

func update_birds(delta: float, listener: Vector3, daytime: bool):
	if daytime:
		silence -= delta
		if silence <= 0:
			silence = rng.randf_range(8, 18)
			bird.pitch_scale = rng.randf_range(0.83, 1.14)
			var angle := rng.randf() * TAU
			var distance := rng.randf_range(10.0, 14.0)
			bird.global_position = listener + Vector3(cos(angle) * distance, 4.2, sin(angle) * distance)
			bird.volume_db = BIRD_LEVEL_DB
			bird.play()
	elif bird.playing:
		bird.volume_db = move_toward(bird.volume_db, -50.0, delta * 110.0)
		if bird.volume_db <= -50.0: bird.stop()

func mix_cave_air(delta: float, near_cave: bool, radio_active: bool):
	var target := (0.38 if radio_active else 1.0) if near_cave else 0.0
	cave_air_gain = move_toward(cave_air_gain, target, delta * (1.9 if radio_active else 0.76))
	if cave_air_gain < 0.0015:
		if cave_air.playing: cave_air.stop()
		return
	cave_air.volume_db = -28.0 + linear_to_db(cave_air_gain)
	if not cave_air.playing: cave_air.play()

static func cave_wind_sound() -> AudioStreamWAV:
	const RATE := 22050
	const COUNT := RATE * 8
	const FADE := 8820
	var random := RandomNumberGenerator.new()
	random.seed = 5779
	var values := PackedFloat32Array()
	var soft := 0.0
	var bass := 0.0
	for i in COUNT + FADE:
		var t := float(i) / RATE
		soft = lerpf(soft, random.randf_range(-1.0, 1.0), 0.030)
		bass = lerpf(bass, soft, 0.007)
		var breath := 0.61 + 0.22 * sin(t * 1.53) + 0.12 * sin(t * 3.31 + 1.2)
		values.append((soft * 0.48 + bass * 0.52) * breath * 2.3)
	var data := PackedByteArray()
	data.resize(COUNT * 2)
	for i in COUNT:
		var sample := values[i] if i >= FADE else lerpf(values[COUNT + i], values[i], float(i) / FADE)
		data.encode_s16(i * 2, roundi(clampf(sample, -1.0, 1.0) * 30000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = COUNT
	stream.data = data
	return stream

func weather(delta: float, rain: float, sheltered: bool, radio_active: bool, storm: bool):
	var target := pow(rain, 1.2) * (0.52 if radio_active else 1.0)
	rain_gain = move_toward(rain_gain, target, delta * 0.9)
	roof_mix = move_toward(roof_mix, 1.0 if sheltered else 0.0, delta * 2.5)
	weather_volume(rain_air, rain_gain * (1.0 - roof_mix), -32.0)
	weather_volume(rain_roof, rain_gain * roof_mix, -36.0)
	thunder.volume_db = lerpf(-27.0, -34.0, roof_mix) - (12.0 if radio_active else 0.0)
	if not storm:
		thunder_wait = 11.0
	elif rain > 0.44 and not radio_active:
		thunder_wait -= delta
		if thunder_wait <= 0.0:
			thunder.pitch_scale = rng.randf_range(0.88, 1.10)
			thunder.play()
			thunder_wait = rng.randf_range(29.0, 43.0)

func weather_volume(channel: AudioStreamPlayer, gain: float, peak: float):
	if gain < 0.0015:
		if channel.playing: channel.stop()
		return
	channel.volume_db = peak + linear_to_db(gain)
	if not channel.playing: channel.play()

static func rain_sound(muffled: bool) -> AudioStreamWAV:
	const RATE := 22050
	const LOOP := RATE * 8
	const CROSSFADE := 4410
	var noise := RandomNumberGenerator.new()
	noise.seed = 32197
	var values := PackedFloat32Array()
	var patter := 0.0
	var rumble := 0.0
	var drops := 0.0
	var filtered := 0.0
	for i in LOOP + CROSSFADE:
		var sample := noise.randf_range(-1.0, 1.0)
		patter = lerpf(patter, sample, 0.40)
		filtered = lerpf(filtered, patter, 0.19)
		rumble = lerpf(rumble, filtered, 0.058)
		if noise.randf() < 0.0039: drops = noise.randf_range(0.14, 0.40)
		drops *= 0.991 if muffled else 0.979
		var value := rumble * 0.58 + filtered * 0.60
		if not muffled: value += (patter - filtered) * 0.24
		value += drops * (filtered * 0.54 + rumble * 0.85)
		values.append(value)
	var data := PackedByteArray()
	data.resize(LOOP * 2)
	for i in LOOP:
		var value := values[i]
		if i < CROSSFADE:
			value = lerpf(values[LOOP + i], value, float(i) / CROSSFADE)
		data.encode_s16(i * 2, roundi(clampf(value, -1.0, 1.0) * 29000.0))
	var tape := AudioStreamWAV.new()
	tape.format = AudioStreamWAV.FORMAT_16_BITS
	tape.mix_rate = RATE
	tape.loop_mode = AudioStreamWAV.LOOP_FORWARD
	tape.loop_end = LOOP
	tape.data = data
	return tape

static func thunder_sound() -> AudioStreamWAV:
	const RATE := 22050
	const SECONDS := 3.4
	var count := int(RATE * SECONDS)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 3619
	var low := 0.0
	var bass := 0.0
	for i in count:
		var time := float(i) / RATE
		low = lerpf(low, noise.randf_range(-1.0, 1.0), 0.044)
		bass = lerpf(bass, low, 0.009)
		var swell := smoothstep(0.0, 0.32, time) * (1.0 - smoothstep(0.48, SECONDS, time))
		var roll := 0.65 + 0.35 * sin(time * TAU * 1.71 + 0.4)
		var value := clampf((low - bass * 0.70) * swell * roll * 3.2, -1.0, 1.0)
		samples.encode_s16(i * 2, roundi(value * 30000.0))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = RATE
	sound.data = samples
	return sound
