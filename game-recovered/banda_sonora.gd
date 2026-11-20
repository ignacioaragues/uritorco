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
const SILENT: = -60.0

var voices: Array[AudioStreamPlayer] = [AudioStreamPlayer.new(), AudioStreamPlayer.new()]
var envelopes: Array[Tween] = [null, null]
var playing_cue: = ""
var current: = 0

func _ready():
	for voice in voices:
		add_child(voice)

func cue(key: String, seconds: float, level: float = -15.0, fade_in: float = 2.0, from_position: float = 0.0):
	if key == playing_cue and is_playing(): return
	fade_out(current, 1.5)
	current = 1 - current
	cancel_fade(current)
	var voice: = voices[current]
	voice.stop()
	voice.stream = TRACKS[key]
	voice.volume_db = SILENT
	voice.play(from_position)
	playing_cue = key
	var envelope: = create_tween().set_trans(Tween.TRANS_SINE)
	envelopes[current] = envelope
	envelope.tween_property(voice, "volume_db", level, fade_in)
	envelope.tween_interval(seconds)
	envelope.tween_property(voice, "volume_db", SILENT, 3.0)
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
	envelope.tween_property(voice, "volume_db", SILENT, seconds)
	envelope.tween_callback(voice.stop)

func cancel_fade(index: int):
	if envelopes[index] and envelopes[index].is_valid():
		envelopes[index].kill()
