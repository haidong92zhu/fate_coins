extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const SAVE_PATH := "user://fate_coins_save.json"
const SETTINGS_PATH := "user://fate_coins_settings.json"
const META_PATH := "user://fate_coins_meta.json"
const PROBE_PATH := "user://fate_coins_storage_probe.json"
const PATHS := [SAVE_PATH, SETTINGS_PATH, META_PATH, PROBE_PATH]

var failed := false
var backups := {}
var main: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_backup_user_files()

	var user_dir := OS.get_user_data_dir()
	var global_user := ProjectSettings.globalize_path("user://")
	_assert(user_dir != "", "OS user data directory should be available")
	_assert(global_user != "" and global_user.find("res://") == -1, "user:// should resolve to a platform directory")
	_assert(DirAccess.dir_exists_absolute(user_dir), "OS user data directory should exist")

	_write_json(PROBE_PATH, {
		"probe": "fate_coins_storage",
		"user_dir": user_dir,
		"global_user": global_user
	})
	var probe = _read_json(PROBE_PATH)
	_assert(typeof(probe) == TYPE_DICTIONARY, "Probe file should roundtrip through user://")
	_assert(String(probe.get("probe", "")) == "fate_coins_storage", "Probe payload should persist")

	main = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	main._save_settings()
	main._save_meta_progress()
	main._save_game()
	await process_frame

	_assert(_json_dictionary_exists(SETTINGS_PATH), "Settings file should write to user://")
	_assert(_json_dictionary_exists(META_PATH), "Meta progress file should write to user://")
	_assert(_json_dictionary_exists(SAVE_PATH), "Save file should write to user://")

	var settings: Dictionary = _read_json(SETTINGS_PATH)
	_assert(settings.has("window_size"), "Settings should include window size for desktop persistence")
	_assert(settings.has("audio_muted"), "Settings should include mute state")

	_cleanup_main()
	_restore_user_files()
	if failed:
		push_error("Platform storage smoke test failed")
		quit(1)
	else:
		print("Platform storage smoke test passed")
		quit(0)


func _backup_user_files() -> void:
	for path in PATHS:
		backups[path] = _read_text(path) if FileAccess.file_exists(path) else null
		_remove_user_file(path)


func _restore_user_files() -> void:
	for path in PATHS:
		_remove_user_file(path)
		if backups[path] != null:
			_write_text(path, String(backups[path]))


func _cleanup_main() -> void:
	if main == null:
		return
	main._release_audio_players()
	main.queue_free()
	main = null


func _write_json(path: String, data: Dictionary) -> void:
	_write_text(path, JSON.stringify(data))


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())


func _json_dictionary_exists(path: String) -> bool:
	return FileAccess.file_exists(path) and typeof(_read_json(path)) == TYPE_DICTIONARY


func _remove_user_file(path: String) -> void:
	var global_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_path):
		DirAccess.remove_absolute(global_path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
