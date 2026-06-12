extends SceneTree

const SAMPLE_RATE := 22050
const TAU_VALUE := PI * 2.0


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://audio"))
	_save_tone("res://audio/coin.wav", 0.12, [523.25, 659.25], 0.30)
	_save_tone("res://audio/miss.wav", 0.18, [146.83, 123.47], 0.28, true)
	_save_tone("res://audio/buy.wav", 0.22, [392.0, 523.25, 659.25], 0.30)
	_save_tone("res://audio/upgrade.wav", 0.42, [392.0, 493.88, 587.33, 783.99], 0.34)
	_save_tone("res://audio/chain.wav", 0.28, [329.63, 440.0, 659.25], 0.32)
	_save_tone("res://audio/settle.wav", 0.30, [196.0, 246.94, 196.0], 0.30)
	_save_tone("res://audio/error.wav", 0.28, [110.0, 98.0], 0.40, true)
	_save_tone("res://audio/hit.wav", 0.16, [196.0, 294.0], 0.34)
	_save_tone("res://audio/hurt.wav", 0.22, [164.0, 82.0], 0.42, true)
	_save_tone("res://audio/warning.wav", 0.48, [196.0, 146.83, 98.0], 0.38, true)
	_save_tone("res://audio/boss_sting.wav", 0.72, [92.0, 138.0, 184.0], 0.46, true)
	_save_tone("res://audio/victory.wav", 0.96, [261.63, 329.63, 392.0, 523.25], 0.40)
	_save_music("res://audio/music_run.wav", 7.6, [110.0, 146.83, 164.81, 196.0], 0.18)
	_save_music("res://audio/music_warning.wav", 5.8, [98.0, 110.0, 82.41, 73.42], 0.23, true)
	_save_music("res://audio/music_boss.wav", 6.4, [82.41, 98.0, 123.47, 146.83], 0.24, true)
	print("Generated audio assets")
	quit()


func _save_tone(path: String, seconds: float, notes: Array[float], volume: float, gritty: bool = false) -> void:
	var frames := int(seconds * SAMPLE_RATE)
	var data := PackedByteArray()
	for index in range(frames):
		var t := float(index) / float(SAMPLE_RATE)
		var note := notes[min(notes.size() - 1, int(float(index) / max(1.0, float(frames)) * float(notes.size())))]
		var envelope := _pluck_envelope(t, seconds)
		var wave := sin(TAU_VALUE * note * t)
		wave += 0.35 * sin(TAU_VALUE * note * 2.0 * t)
		if gritty:
			wave += 0.22 * sin(TAU_VALUE * note * 0.5 * t)
			wave = clamp(wave * 1.25, -1.0, 1.0)
		_write_sample(data, wave * envelope * volume)
	_write_wav(path, data)


func _save_music(path: String, seconds: float, notes: Array[float], volume: float, tense: bool = false) -> void:
	var frames := int(seconds * SAMPLE_RATE)
	var data := PackedByteArray()
	var beat := 0.48 if tense else 0.60
	for index in range(frames):
		var t := float(index) / float(SAMPLE_RATE)
		var step := int(floor(t / beat)) % notes.size()
		var root := notes[step]
		var pulse := fmod(t, beat) / beat
		var envelope := 0.40 + 0.60 * exp(-pulse * (7.0 if tense else 5.0))
		var bass := sin(TAU_VALUE * root * t) * 0.62
		var fifth := sin(TAU_VALUE * root * 1.5 * t) * 0.22
		var shimmer := sin(TAU_VALUE * root * 4.0 * t) * (0.10 if tense else 0.16)
		var tick := sin(TAU_VALUE * 880.0 * t) * (0.14 if pulse < 0.10 else 0.0)
		var wave := (bass + fifth + shimmer + tick) * envelope
		_write_sample(data, clamp(wave * volume, -0.85, 0.85))
	_write_wav(path, data)


func _pluck_envelope(t: float, seconds: float) -> float:
	var attack: float = min(1.0, t / 0.025)
	var release: float = clamp((seconds - t) / max(0.001, seconds * 0.70), 0.0, 1.0)
	return attack * release


func _write_sample(data: PackedByteArray, value: float) -> void:
	var sample := int(clamp(value, -1.0, 1.0) * 32767.0)
	if sample < 0:
		sample += 65536
	data.append(sample & 0xff)
	data.append((sample >> 8) & 0xff)


func _write_wav(path: String, pcm_data: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s" % path)
		return
	var byte_rate := SAMPLE_RATE * 2
	var block_align := 2
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(36 + pcm_data.size())
	file.store_buffer("WAVE".to_ascii_buffer())
	file.store_buffer("fmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(SAMPLE_RATE)
	file.store_32(byte_rate)
	file.store_16(block_align)
	file.store_16(16)
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(pcm_data.size())
	file.store_buffer(pcm_data)
