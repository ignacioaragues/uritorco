extends Node

var step: = AudioStreamPlayer.new()
var bird: = AudioStreamPlayer.new()
var travel: = 0.0
var silence: = 3.0
var rng: = RandomNumberGenerator.new()

func _ready():
	rng.seed = 1871
	add_child(step)
	add_child(bird)
	step.stream = sound(false)
	bird.stream = sound(true)
	step.volume_db = -24
	bird.volume_db = -22

func sound(song: bool) -> AudioStreamWAV:
	var rate: = 22050
	var count: = int(rate * (0.54 if song else 0.18))
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
		else:
			filter = lerpf(filter, rng.randf_range(-1, 1), 0.27)
			value = (filter * 0.85 + sin(t * TAU * 64) * 0.12) * exp( - t * 24) * minf(1, t * 120)
		samples.encode_s16(i * 2, int(value * 18000))
	var wave: = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = rate
	wave.data = samples
	return wave

func update(delta: float, speed: float, daytime: bool, cave_interior: bool = false):
	travel += speed * delta
	if travel >= 1.72:
		travel = 0
		step.pitch_scale = rng.randf_range(0.86, 1.12)
		step.volume_db = -16.0 if cave_interior else -24.0
		step.play()
	if daytime:
		silence -= delta
		if silence <= 0:
			silence = rng.randf_range(8, 18)
			bird.pitch_scale = rng.randf_range(0.83, 1.14)
			bird.play()
	elif bird.playing: bird.stop()
