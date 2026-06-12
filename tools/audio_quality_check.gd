extends SceneTree

const REPORT_PATH := "res://build/audio_quality_report.md"
const AUDIO_SPECS := {
	"coin": {"path": "res://audio/coin.wav", "kind": "sfx", "min": 0.06, "max": 0.35},
	"miss": {"path": "res://audio/miss.wav", "kind": "sfx", "min": 0.08, "max": 0.45},
	"buy": {"path": "res://audio/buy.wav", "kind": "sfx", "min": 0.10, "max": 0.55},
	"upgrade": {"path": "res://audio/upgrade.wav", "kind": "sfx", "min": 0.20, "max": 0.80},
	"chain": {"path": "res://audio/chain.wav", "kind": "sfx", "min": 0.12, "max": 0.60},
	"settle": {"path": "res://audio/settle.wav", "kind": "sfx", "min": 0.16, "max": 0.70},
	"error": {"path": "res://audio/error.wav", "kind": "sfx", "min": 0.12, "max": 0.60},
	"hit": {"path": "res://audio/hit.wav", "kind": "sfx", "min": 0.08, "max": 0.45},
	"hurt": {"path": "res://audio/hurt.wav", "kind": "sfx", "min": 0.12, "max": 0.55},
	"warning": {"path": "res://audio/warning.wav", "kind": "sfx", "min": 0.30, "max": 0.90},
	"boss": {"path": "res://audio/boss_sting.wav", "kind": "sfx", "min": 0.45, "max": 1.20},
	"victory": {"path": "res://audio/victory.wav", "kind": "sfx", "min": 0.60, "max": 1.40},
	"music_run": {"path": "res://audio/music_run.wav", "kind": "music", "min": 6.0, "max": 12.0},
	"music_warning": {"path": "res://audio/music_warning.wav", "kind": "music", "min": 4.0, "max": 10.0},
	"music_boss": {"path": "res://audio/music_boss.wav", "kind": "music", "min": 4.0, "max": 10.0}
}
const REQUIRED_SAMPLE_RATES := [22050, 44100]
const MIN_PEAK := 0.05
const MAX_PEAK := 0.98
const MAX_CLIPPED_RATIO := 0.001


func _init() -> void:
	var failures: Array[String] = []
	var report_lines := _build_report(failures)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var report := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if report == null:
		push_error("Could not write audio quality report")
		quit(1)
		return
	report.store_string("\n".join(report_lines))
	if failures.is_empty():
		print("Audio quality check passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _build_report(failures: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	lines.append("# Fate Coins Audio Quality Report")
	lines.append("")
	lines.append("- Generated: %s" % Time.get_datetime_string_from_system(false, true))
	lines.append("- Checks: file/import coverage, ResourceLoader availability, PCM WAV header, mono 16-bit format, sample rate, duration, peak level, clipping ratio.")
	lines.append("")
	lines.append("## Assets")
	lines.append("")
	for key in AUDIO_SPECS.keys():
		var spec: Dictionary = AUDIO_SPECS[key]
		var result := _inspect_wav(String(spec["path"]))
		var status := _validate_audio(key, spec, result, failures)
		lines.append("- %s `%s` (%s): %s" % [
			_status_icon(status),
			spec["path"],
			spec["kind"],
			_result_summary(result)
		])
	lines.append("")
	return lines


func _validate_audio(key: String, spec: Dictionary, result: Dictionary, failures: Array[String]) -> String:
	var path := String(spec["path"])
	var errors: Array[String] = []
	if not bool(result.get("exists", false)):
		errors.append("missing file")
	if not bool(result.get("import_exists", false)):
		errors.append("missing import metadata")
	if not bool(result.get("resource_exists", false)):
		errors.append("ResourceLoader cannot resolve")
	if not bool(result.get("valid_wav", false)):
		errors.append("invalid wav")
	if int(result.get("channels", 0)) != 1:
		errors.append("expected mono")
	if int(result.get("bits", 0)) != 16:
		errors.append("expected 16-bit PCM")
	if not REQUIRED_SAMPLE_RATES.has(int(result.get("sample_rate", 0))):
		errors.append("unexpected sample rate")
	var seconds := float(result.get("seconds", 0.0))
	if seconds < float(spec["min"]) or seconds > float(spec["max"]):
		errors.append("duration %.2fs outside %.2f-%.2fs" % [seconds, float(spec["min"]), float(spec["max"])])
	var peak := float(result.get("peak", 0.0))
	if peak < MIN_PEAK:
		errors.append("peak too quiet %.3f" % peak)
	if peak > MAX_PEAK:
		errors.append("peak too hot %.3f" % peak)
	var clipped_ratio := float(result.get("clipped_ratio", 0.0))
	if clipped_ratio > MAX_CLIPPED_RATIO:
		errors.append("clipping ratio %.4f" % clipped_ratio)
	if errors.is_empty():
		return "pass"
	failures.append("%s %s: %s" % [key, path, ", ".join(errors)])
	return "fail"


func _inspect_wav(path: String) -> Dictionary:
	var result := {
		"exists": FileAccess.file_exists(path),
		"import_exists": FileAccess.file_exists("%s.import" % path),
		"resource_exists": ResourceLoader.exists(path),
		"valid_wav": false,
		"channels": 0,
		"sample_rate": 0,
		"bits": 0,
		"seconds": 0.0,
		"peak": 0.0,
		"clipped_ratio": 0.0
	}
	if not bool(result["exists"]):
		return result
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result
	var bytes := file.get_buffer(file.get_length())
	if bytes.size() < 44:
		return result
	if _ascii(bytes, 0, 4) != "RIFF" or _ascii(bytes, 8, 4) != "WAVE":
		return result
	var format_offset := _find_chunk(bytes, "fmt ")
	var data_offset := _find_chunk(bytes, "data")
	if format_offset == -1 or data_offset == -1:
		return result
	var audio_format := _u16(bytes, format_offset + 8)
	var channels := _u16(bytes, format_offset + 10)
	var sample_rate := _u32(bytes, format_offset + 12)
	var bits := _u16(bytes, format_offset + 22)
	var data_size := _u32(bytes, data_offset + 4)
	var data_start := data_offset + 8
	if audio_format != 1 or bits != 16 or channels <= 0 or sample_rate <= 0:
		result["channels"] = channels
		result["sample_rate"] = sample_rate
		result["bits"] = bits
		return result
	var sample_count: int = int(min(data_size, bytes.size() - data_start) / 2)
	var peak := 0.0
	var clipped := 0
	for index in range(sample_count):
		var raw: int = _u16(bytes, data_start + index * 2)
		var sample: int = raw if raw < 32768 else raw - 65536
		var normalized: float = abs(float(sample) / 32768.0)
		peak = max(peak, normalized)
		if normalized >= 0.985:
			clipped += 1
	result["valid_wav"] = true
	result["channels"] = channels
	result["sample_rate"] = sample_rate
	result["bits"] = bits
	result["seconds"] = float(sample_count) / float(sample_rate * channels)
	result["peak"] = peak
	result["clipped_ratio"] = float(clipped) / max(1.0, float(sample_count))
	return result


func _find_chunk(bytes: PackedByteArray, chunk_name: String) -> int:
	var offset := 12
	while offset + 8 <= bytes.size():
		var name := _ascii(bytes, offset, 4)
		var size := _u32(bytes, offset + 4)
		if name == chunk_name:
			return offset
		offset += 8 + size + (size % 2)
	return -1


func _ascii(bytes: PackedByteArray, start: int, length: int) -> String:
	var out := ""
	for index in range(length):
		out += char(bytes[start + index])
	return out


func _u16(bytes: PackedByteArray, offset: int) -> int:
	if offset + 1 >= bytes.size():
		return 0
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _u32(bytes: PackedByteArray, offset: int) -> int:
	if offset + 3 >= bytes.size():
		return 0
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)


func _result_summary(result: Dictionary) -> String:
	if not bool(result.get("exists", false)):
		return "missing"
	if not bool(result.get("valid_wav", false)):
		return "invalid wav"
	return "%.2fs, %d Hz, %d ch, %d-bit, peak %.3f, clipped %.4f" % [
		float(result.get("seconds", 0.0)),
		int(result.get("sample_rate", 0)),
		int(result.get("channels", 0)),
		int(result.get("bits", 0)),
		float(result.get("peak", 0.0)),
		float(result.get("clipped_ratio", 0.0))
	]


func _status_icon(status: String) -> String:
	return "[PASS]" if status == "pass" else "[FAIL]"
