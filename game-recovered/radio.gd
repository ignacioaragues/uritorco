extends AudioStreamPlayer

var interference: = AudioStreamPlayer.new()

func _ready():
	add_child(interference)
	var noise: = RandomNumberGenerator.new()
	noise.seed = 513
	var data: = PackedByteArray()
	var sample_count: = 11025
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t: = float(i) / 22050.0
		var envelope: = sin(PI * i / sample_count) * (0.3 if t > 0.16 and t < 0.28 else 1.0)
		var sample: = noise.randf_range(-1.0, 1.0) + sin(TAU * 830.0 * t) * 0.28
		data.encode_s16(i * 2, int(sample * envelope * 2200))
	var burst: = AudioStreamWAV.new()
	burst.format = AudioStreamWAV.FORMAT_16_BITS
	burst.mix_rate = 22050
	burst.data = data
	interference.stream = burst

	var rate: = 22050
	var count: = int(rate * 0.09)
	var samples: = PackedByteArray()
	samples.resize(count * 2)
	for i in range(count):
		var t: = float(i) / rate
		var envelope: = pow(sin(PI * i / count), 2)
		var tone: = sin(TAU * 410.0 * t) + 0.22 * sin(TAU * 615.0 * t)
		samples.encode_s16(i * 2, int(tone * envelope * 1250))
	var wave: = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = rate
	wave.data = samples
	stream = wave

func play_interference():
	interference.play()
