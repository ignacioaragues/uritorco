extends Node

const TRACKS: = {
	"calma1": preload("res://audio/score/calma1.ogg"), 
	"calma2": preload("res://audio/score/calma2.ogg"), 
	"cosmic": preload("res://audio/score/cosmic.ogg"), 
	"domestic": preload("res://audio/score/domestic.ogg"), 
	"melancholy": preload("res://audio/score/melancholy.ogg"), 
	"misterio": preload("res://audio/score/misterio.ogg"), 
	"noche": preload("res://audio/score/noche.ogg"), 
	"otromundo": preload("res://audio/score/otromundo.ogg"), 
	"quietud": preload("res://audio/score/quietud.ogg"), 
	"tension": preload("res://audio/score/tension.ogg"), 
}
const FLOOR_GAIN := 0.001
const RADIO_DUCK_DB := -7.0
const CROSSFADE_SECONDS := 2.8

var voices: Array[AudioStreamPlayer] = [AudioStreamPlayer.new(), AudioStreamPlayer.new(), AudioStreamPlayer.new()]
var envelopes: Array[Tween] = [null, null, null]
var gains: Array[float] = [FLOOR_GAIN, FLOOR_GAIN, FLOOR_GAIN]
var playing_cue: = ""
var current: = 0
var radio_active := false
var radio_db := 0.0

func _ready():
	for voice in voices:
		add_child(voice)

func _process(delta: float):
	var target := RADIO_DUCK_DB if radio_active else 0.0
	var mixed := move_toward(radio_db, target, delta * (26.0 if radio_active else 9.0))
	if mixed == radio_db: return
	radio_db = mixed
	for index in voices.size():
		set_gain(gains[index], index)

func set_gain(gain: float, index: int):
	gains[index] = gain
	voices[index].volume_db = linear_to_db(gain) + radio_db

func cue(key: String, seconds: float, level: float = -15.0, fade_in: float = 2.0, from_position: float = 0.0):
	if key == playing_cue and is_playing(): return
	fade_out(current, CROSSFADE_SECONDS)
	var next := (current + 1) % voices.size()
	for i in range(1, voices.size()):
		var candidate := (current + i) % voices.size()
		if not voices[candidate].playing:
			next = candidate
			break
		if gains[candidate] < gains[next]: next = candidate
	current = next
	cancel_fade(current)
	var voice: = voices[current]
	voice.stop()
	voice.stream = TRACKS[key]
	set_gain(FLOOR_GAIN, current)
	voice.play(from_position)
	playing_cue = key
	var envelope: = create_tween().set_trans(Tween.TRANS_SINE)
	envelopes[current] = envelope
	var apply := set_gain.bind(current)
	var full := db_to_linear(level)
	var available := maxf(0.1, voice.stream.get_length() - from_position - 0.08)
	var attack := minf(fade_in, available * 0.40)
	var release := minf(4.0, available * 0.55)
	envelope.tween_method(apply, FLOOR_GAIN, full, attack)
	envelope.tween_interval(minf(seconds, available - attack - release))
	envelope.tween_method(apply, full, FLOOR_GAIN, release)
	envelope.tween_callback(voice.stop)

func is_playing() -> bool:
	return voices[current].playing

func silence(seconds: float = 2.0):
	for index in voices.size():
		fade_out(index, maxf(seconds, CROSSFADE_SECONDS))
	playing_cue = ""

func fade_out(index: int, seconds: float):
	var voice: = voices[index]
	if not voice.playing: return
	var remaining := maxf(0.05, voice.stream.get_length() - voice.get_playback_position() - 0.06)
	cancel_fade(index)
	var envelope: = create_tween().set_trans(Tween.TRANS_SINE)
	envelopes[index] = envelope
	envelope.tween_method(set_gain.bind(index), gains[index], FLOOR_GAIN, minf(seconds, remaining))
	envelope.tween_callback(voice.stop)

func cancel_fade(index: int):
	if envelopes[index] and envelopes[index].is_valid():
		envelopes[index].kill()
