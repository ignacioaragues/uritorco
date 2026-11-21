extends AudioStreamPlayer

var interference: = AudioStreamPlayer.new()
var knocks := AudioStreamPlayer.new()
var incoming := AudioStreamPlayer.new()

func _ready():
	add_child(interference)
	add_child(knocks)
	add_child(incoming)
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
	knocks.stream = make_knocks(rate)
	var call_data := PackedByteArray()
	call_data.resize(int(rate * 0.81) * 2)
	for delay: float in [0.01, 0.23, 0.49]:
		var offset := int(delay * rate)
		for i in count:
			call_data.encode_s16((offset + i) * 2, roundi(samples.decode_s16(i * 2) * 1.55))
	var call := AudioStreamWAV.new()
	call.format = AudioStreamWAV.FORMAT_16_BITS
	call.mix_rate = rate
	call.data = call_data
	incoming.stream = call

func make_knocks(rate: int) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(int(rate * 0.45) * 2)
	for onset in [0.012, 0.29]:
		var start := int(rate * onset)
		var gain := 1.0 if onset < 0.1 else 0.76
		for i in int(rate * 0.10):
			var t := float(i) / rate
			var envelope := minf(1.0, t * 700.0) * exp(-t * 55.0)
			var sample := sin(TAU * 148.0 * t) + 0.35 * sin(TAU * 640.0 * t)
			data.encode_s16((start + i) * 2, int(sample * envelope * 4900.0 * gain))
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = rate
	wave.data = data
	return wave

func play_interference():
	interference.play()

func play_knocks():
	knocks.play()
