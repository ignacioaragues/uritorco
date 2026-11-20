extends Node

var step: = AudioStreamPlayer.new()
var dry_step: AudioStreamWAV
var water_step: AudioStreamWAV
var bird: = AudioStreamPlayer.new()
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
	bird.volume_db = -22
	if not open_rain:
		open_rain = rain_sound(false)
		covered_rain = rain_sound(true)
	add_child(rain_air)
	add_child(rain_roof)
	rain_air.stream = open_rain
	rain_roof.stream = covered_rain

func sound(song: bool, splash := false) -> AudioStreamWAV:
	var rate: = 22050
	var count: = int(rate * (0.54 if song else (0.32 if splash else 0.18)))
	var samples: = PackedByteArray()
	samples.resize(count * 2)
	var filter: = 0.0
	var phase: = 0.0
	for i in count:
		var t: = float(i) / rate
		var value: float
		if song:
			var local: = fmod(t, 0.19)
			phase += TAU * (2100 + 950 * sin(PI * local / 0.19)) / rate
			value = sin(phase) * pow(sin(PI * local / 0.19), 3) * exp( - t * 1.9)
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

func update(delta: float, speed: float, daytime: bool, cave_interior: bool = false, depth := 0.0):
	travel += speed * delta
	if travel >= 1.72:
		travel = 0
		step.pitch_scale = rng.randf_range(0.86, 1.12)
		step.stream = water_step if depth > 0.07 else dry_step
		step.volume_db = -16.0 if cave_interior else (-20.5 if depth > 0.07 else -24.0)
		step.play()
	if daytime:
		silence -= delta
		if silence <= 0:
			silence = rng.randf_range(8, 18)
			bird.pitch_scale = rng.randf_range(0.83, 1.14)
			bird.play()
	elif bird.playing: bird.stop()

func weather(delta: float, rain: float, sheltered: bool, radio_active: bool):
	var target := pow(rain, 0.78) * (0.52 if radio_active else 1.0)
	rain_gain = move_toward(rain_gain, target, delta * 0.9)
	roof_mix = move_toward(roof_mix, 1.0 if sheltered else 0.0, delta * 2.5)
	weather_volume(rain_air, rain_gain * (1.0 - roof_mix), -22.0)
	weather_volume(rain_roof, rain_gain * roof_mix, -26.0)

func weather_volume(channel: AudioStreamPlayer, gain: float, peak: float):
	if gain < 0.0015:
		if channel.playing: channel.stop()
		return
	channel.volume_db = peak + linear_to_db(gain)
	if not channel.playing: channel.play()

static func rain_sound(muffled: bool) -> AudioStreamWAV:
	const RATE := 22050
	const LOOP := 44100
	const CROSSFADE := 2208
	var noise := RandomNumberGenerator.new()
	noise.seed = 32197
	var values := PackedFloat32Array()
	var rumble := 0.0
	var drops := 0.0
	var filtered := 0.0
	for i in LOOP + CROSSFADE:
		var sample := noise.randf_range(-1.0, 1.0)
		filtered = lerpf(filtered, sample, 0.24)
		rumble = lerpf(rumble, filtered, 0.058)
		if noise.randf() < 0.0039: drops = noise.randf_range(0.14, 0.61)
		drops *= 0.991 if muffled else 0.979
		var swell := 0.83 + 0.15 * sin(i * 0.00063) * cos(i * 0.00081)
		var value := (rumble * 0.54 + filtered * 0.74) * swell
		if not muffled: value += (sample - filtered) * 0.24
		value += drops * (filtered * 0.66 + rumble * 0.85)
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
