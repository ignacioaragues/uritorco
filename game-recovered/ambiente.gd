extends Node

const BIRD_LEVEL_DB := -25.0

var step: = AudioStreamPlayer.new()
var dry_step: AudioStreamWAV
var water_step: AudioStreamWAV
var bird := AudioStreamPlayer3D.new()
var travel: = 0.0
var silence: = 3.0
var rain_air := AudioStreamPlayer.new()
var rain_roof := AudioStreamPlayer.new()
var rain_gain := 0.0
var roof_mix := 0.0
static var open_rain: AudioStreamWAV
static var covered_rain: AudioStreamWAV
var rng: = RandomNumberGenerator.new()

func _ready():
	rng.seed = 1871
	add_child(step)
	add_child(bird)
	dry_step = sound(false)
	bird.stream = sound(true)
	water_step = sound(false, true)
	step.volume_db = -24
	bird.volume_db = BIRD_LEVEL_DB
	bird.unit_size = 10.0
	bird.max_distance = 38.0
	if not open_rain:
		open_rain = rain_sound(false)
		covered_rain = rain_sound(true)
	add_child(rain_air)
	add_child(rain_roof)
	rain_air.stream = open_rain
	rain_roof.stream = covered_rain

func sound(song: bool, splash := false) -> AudioStreamWAV:
	var rate: = 22050
	var count: = int(rate * (0.42 if song else (0.32 if splash else 0.18)))
	var samples: = PackedByteArray()
	samples.resize(count * 2)
	var filter: = 0.0
	var phase: = 0.0
	for i in count:
		var t: = float(i) / rate
		var value: float
		if song:
			var pulse := sin(PI * fmod(t, 0.21) / 0.21)
			var pitch := 1740.0 + 565.0 * pulse - t * 510.0
			phase += TAU * pitch / rate
			value = (sin(phase) + 0.13 * sin(phase * 2.0)) * pow(pulse, 3) * exp(-t * 2.9) * 0.72
		elif splash:
			var noise := rng.randf_range(-1.0, 1.0)
			filter = lerpf(filter, noise, 0.31)
			phase += TAU * lerpf(275.0, 120.0, minf(t * 4.0, 1.0)) / rate
			value = (filter * 0.86 + sin(phase) * 0.16) * (exp(-t * 17.0) - exp(-t * 115.0))
		else:
			filter = lerpf(filter, rng.randf_range(-1, 1), 0.27)
			value = (filter * 0.85 + sin(t * TAU * 64) * 0.12) * exp( - t * 24) * minf(1, t * 120)
		samples.encode_s16(i * 2, int(value * 18000))
	var wave: = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = rate
	wave.data = samples
	return wave

func update(delta: float, listener: Vector3, speed: float, daytime: bool, cave_interior: bool = false, depth := 0.0):
	travel += speed * delta
	if travel >= 1.72:
		travel = 0
		step.pitch_scale = rng.randf_range(0.86, 1.12)
		step.stream = water_step if depth > 0.07 else dry_step
		step.volume_db = -20.0 if cave_interior else (-24.0 if depth > 0.07 else -28.0)
		step.play()
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

func weather(delta: float, rain: float, sheltered: bool, radio_active: bool):
	var target := pow(rain, 1.2) * (0.52 if radio_active else 1.0)
	rain_gain = move_toward(rain_gain, target, delta * 0.9)
	roof_mix = move_toward(roof_mix, 1.0 if sheltered else 0.0, delta * 2.5)
	weather_volume(rain_air, rain_gain * (1.0 - roof_mix), -32.0)
	weather_volume(rain_roof, rain_gain * roof_mix, -36.0)

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
