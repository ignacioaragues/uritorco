extends AudioStreamPlayer

var envelope: Tween
var closing := false

func begin():
	closing = false
	if envelope and envelope.is_valid(): envelope.kill()
	var track: = preload("res://audio/Montañas Vacías.ogg") as AudioStreamOggVorbis
	track.loop = true
	stream = track
	volume_db = -55
	play()
	envelope = create_tween()
	envelope.tween_property(self, "volume_db", -12.0, 2.6).set_trans(Tween.TRANS_SINE)

func close(seconds := 4.0):
	if not playing or closing: return
	closing = true
	if envelope: envelope.kill()
	envelope = create_tween()
	envelope.tween_property(self, "volume_db", -55.0, seconds).set_trans(Tween.TRANS_SINE)
	envelope.tween_callback(stop)
