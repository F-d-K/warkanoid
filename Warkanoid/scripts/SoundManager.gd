extends Node

const SR : int = 22050

func play_bounce():     _play(_make_bounce())
func play_brick():      _play(_make_brick())
func play_powerup():    _play(_make_powerup())
func play_die():        _play(_make_die())
func play_level_up():   _play(_make_level_up())
func play_launch():     _play(_make_launch())

func _make_bounce() -> AudioStreamWAV:
	var dur : float = 0.06
	var n   : int   = int(SR * dur)
	var d   := PackedByteArray()
	d.resize(n * 2)
	for i in n:
		var t : float = float(i) / float(SR)
		var s : int   = int(sin(t * 440.0 * TAU) * (1.0 - t / dur) * 20000.0)
		d[i*2] = s & 0xFF; d[i*2+1] = (s >> 8) & 0xFF
	return _wav(d)

func _make_brick() -> AudioStreamWAV:
	var dur : float = 0.12
	var n   : int   = int(SR * dur)
	var d   := PackedByteArray()
	d.resize(n * 2)
	for i in n:
		var t    : float = float(i) / float(SR)
		var freq : float = lerpf(800.0, 200.0, t / dur)
		var env  : float = pow(1.0 - t / dur, 0.7)
		var s    : int   = int(sin(t * freq * TAU) * env * 24000.0)
		d[i*2] = s & 0xFF; d[i*2+1] = (s >> 8) & 0xFF
	return _wav(d)

func _make_powerup() -> AudioStreamWAV:
	var dur : float = 0.25
	var n   : int   = int(SR * dur)
	var d   := PackedByteArray()
	d.resize(n * 2)
	for i in n:
		var t    : float = float(i) / float(SR)
		var freq : float = 400.0 * pow(4.0, t / dur)
		var env  : float = sin(t / dur * PI)
		var s    : int   = int(sin(t * freq * TAU) * env * 26000.0)
		d[i*2] = s & 0xFF; d[i*2+1] = (s >> 8) & 0xFF
	return _wav(d)

func _make_die() -> AudioStreamWAV:
	var freqs : Array[float] = [330.0, 262.0, 196.0, 147.0]
	var nd    : float = 0.15
	var n     : int   = int(float(SR) * nd * 4.0 + float(SR) * 0.1)
	var d     := PackedByteArray()
	d.resize(n * 2)
	for i in n:
		var t   : float = float(i) / float(SR)
		var fi  : int   = mini(3, int(t / nd))
		var nt  : float = fmod(t, nd)
		var env : float = 1.0 - nt / nd
		var s   : int   = int(sin(t * freqs[fi] * TAU) * env * 26000.0)
		d[i*2] = s & 0xFF; d[i*2+1] = (s >> 8) & 0xFF
	return _wav(d)

func _make_level_up() -> AudioStreamWAV:
	var freqs : Array[float] = [261.6, 329.6, 392.0, 523.3]
	var nd    : float = 0.10
	var n     : int   = int(float(SR) * nd * 4.0 + float(SR) * 0.1)
	var d     := PackedByteArray()
	d.resize(n * 2)
	for i in n:
		var t  : float = float(i) / float(SR)
		var fi : int   = int(t / nd)
		if fi >= 4:
			d[i*2] = 0; d[i*2+1] = 0
			continue
		var nt  : float = fmod(t, nd)
		var env : float = 1.0 - nt / nd
		var s   : int   = int(sin(t * freqs[fi] * TAU) * env * 26000.0)
		d[i*2] = s & 0xFF; d[i*2+1] = (s >> 8) & 0xFF
	return _wav(d)

func _make_launch() -> AudioStreamWAV:
	var dur : float = 0.08
	var n   : int   = int(SR * dur)
	var d   := PackedByteArray()
	d.resize(n * 2)
	for i in n:
		var t    : float = float(i) / float(SR)
		var freq : float = lerpf(200.0, 600.0, t / dur)
		var s    : int   = int(sin(t * freq * TAU) * (1.0 - t / dur) * 22000.0)
		d[i*2] = s & 0xFF; d[i*2+1] = (s >> 8) & 0xFF
	return _wav(d)

func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format   = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = SR
	s.stereo   = false
	s.data     = data
	return s

func _play(stream: AudioStreamWAV) -> void:
	var p := AudioStreamPlayer.new()
	p.stream     = stream
	p.volume_db  = -6.0
	add_child(p)
	p.play()
	p.connect("finished", p.queue_free)
