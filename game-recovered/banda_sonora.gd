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

var voices: Array[AudioStreamPlayer] = [AudioStreamPlayer.new(), AudioStreamPlayer.new()]
var envelopes: Array[Tween] = [null, null]
var gains: Array[float] = [FLOOR_GAIN, FLOOR_GAIN]
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
	fade_out(current, 1.5)
	current = 1 - current
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
	envelope.tween_method(apply, FLOOR_GAIN, full, fade_in)
	envelope.tween_interval(seconds)
	envelope.tween_method(apply, full, FLOOR_GAIN, 4.0)
	envelope.tween_callback(voice.stop)

func is_playing() -> bool:
	return voices[current].playing

func silence(seconds: float = 2.0):
	for index in voices.size():
		fade_out(index, seconds)
	playing_cue = ""

func fade_out(index: int, seconds: float):
	var voice: = voices[index]
	if not voice.playing: return
	cancel_fade(index)
	var envelope: = create_tween().set_trans(Tween.TRANS_SINE)
	envelopes[index] = envelope
	envelope.tween_method(set_gain.bind(index), gains[index], FLOOR_GAIN, seconds)
	envelope.tween_callback(voice.stop)

func cancel_fade(index: int):
	if envelopes[index] and envelopes[index].is_valid():
		envelopes[index].kill()
