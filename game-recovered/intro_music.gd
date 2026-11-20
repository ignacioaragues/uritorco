extends AudioStreamPlayer

var envelope: Tween

func begin():
	var track: = preload("res://audio/Montañas Vacías.ogg") as AudioStreamOggVorbis
	track.loop = true
	stream = track
	volume_db = -55
	play()
	envelope = create_tween()
	envelope.tween_property(self, "volume_db", -12.0, 2.6).set_trans(Tween.TRANS_SINE)

func close():
	if not playing: return
	if envelope: envelope.kill()
	envelope = create_tween()
	envelope.tween_property(self, "volume_db", -55.0, 4.0).set_trans(Tween.TRANS_SINE)
	envelope.tween_callback(stop)
