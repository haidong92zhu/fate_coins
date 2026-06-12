extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const SAVE_PATH := "user://fate_coins_save.json"
const SETTINGS_PATH := "user://fate_coins_settings.json"
const META_PATH := "user://fate_coins_meta.json"
const PATHS := [SAVE_PATH, SETTINGS_PATH, META_PATH]

var failed := false
var backups := {}
var main: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_backup_user_files()
	_write_text(SETTINGS_PATH, "{bad settings")
	_write_text(META_PATH, "[bad meta")
	_write_text(SAVE_PATH, "not json")

	main = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_assert(not FileAccess.file_exists(SETTINGS_PATH), "Corrupt settings should be quarantined")
	_assert(not FileAccess.file_exists(META_PATH), "Corrupt meta progress should be quarantined")
	_assert(_global_exists("%s.corrupt" % SETTINGS_PATH), "Corrupt settings backup should exist")
	_assert(_global_exists("%s.corrupt" % META_PATH), "Corrupt meta backup should exist")
	_assert(int(main.meta_progress.get("best_round", 0)) >= 1, "Meta progress should fall back to defaults")

	var loaded: bool = main._load_game()
	await process_frame
	_assert(not loaded, "Corrupt save should not load")
	_assert(not FileAccess.file_exists(SAVE_PATH), "Corrupt save should be quarantined")
	_assert(_global_exists("%s.corrupt" % SAVE_PATH), "Corrupt save backup should exist")
	_assert(main.notice_label.text.find("隔离损坏存档") != -1, "Corrupt save should explain recovery")

	main._apply_save_data(_legacy_partial_save())
	await process_frame
	_assert(main.difficulty_id == "normal", "Invalid difficulty should fall back to normal")
	_assert(main.wager_mode == "standard", "Invalid wager mode should fall back to standard")
	_assert(main.starter_bag_id == "balanced", "Invalid starter should fall back to balanced")
	_assert(int(main.game_state.coins) == 0, "Negative coins should clamp to zero")
	_assert(int(main.player_health) == main.MAX_HEALTH, "Health should clamp to max")
	_assert(int(main.game_state.current_round) == main.FINAL_ROUND, "Round should clamp to final round")
	_assert(main.board_tiles.size() == main.TOTAL_SLOTS, "Oversized board should be trimmed")
	_assert(not main.coin_bag.is_empty(), "Missing coin bag should be rebuilt")
	_assert(not main.hand_tiles.is_empty(), "Missing hand should be redrawn")
	_assert(not main.current_event.is_empty(), "Missing event should be regenerated")

	main._save_game()
	await process_frame
	_assert(FileAccess.file_exists(SAVE_PATH), "Save should exist before delete confirmation")
	main._request_delete_save()
	await process_frame
	_assert(main.delete_save_confirm_dialog.visible, "Delete save should open a confirmation dialog")
	_assert(FileAccess.file_exists(SAVE_PATH), "Save should not be deleted before confirmation")
	main.delete_save_confirm_dialog.hide()
	main._delete_save_confirmed()
	await process_frame
	_assert(not FileAccess.file_exists(SAVE_PATH), "Save should be deleted after confirmation")

	main.sfx_volume_db = -12.0
	main.music_volume_db = -22.0
	main.audio_muted = true
	main.fullscreen_enabled = false
	main.reduced_motion_enabled = true
	main.window_size = Vector2i(1280, 800)
	main.language_id = "en_US"
	main._save_settings()

	main.sfx_volume_db = -2.0
	main.music_volume_db = -4.0
	main.audio_muted = false
	main.reduced_motion_enabled = false
	main.window_size = Vector2i(1600, 1000)
	main.language_id = "zh_CN"
	main._load_settings()
	_assert(is_equal_approx(main.sfx_volume_db, -12.0), "SFX volume should persist")
	_assert(is_equal_approx(main.music_volume_db, -22.0), "Music volume should persist")
	_assert(main.audio_muted, "Mute toggle should persist")
	_assert(main.reduced_motion_enabled, "Reduced motion should persist")
	_assert(main.window_size == Vector2i(1280, 800), "Window size should persist")
	_assert(main.language_id == "en_US", "Language entrance should persist")

	_write_text(SETTINGS_PATH, JSON.stringify({
		"audio_muted": true,
		"window_size": {"x": 1, "y": 1},
		"language_id": "bad_locale"
	}))
	main.audio_muted = false
	main.window_size = Vector2i(1920, 1080)
	main.language_id = "en_US"
	main._load_settings()
	_assert(main.audio_muted, "Valid mute value should still load from partially invalid settings")
	_assert(main.window_size == Vector2i(1600, 1000), "Invalid window size should fall back to default")
	_assert(main.language_id == "zh_CN", "Invalid language should fall back to Simplified Chinese")

	_cleanup_main()
	_restore_user_files()
	if failed:
		push_error("Persistence recovery smoke test failed")
		quit(1)
	else:
		print("Persistence recovery smoke test passed")
		quit(0)


func _legacy_partial_save() -> Dictionary:
	var board: Array[Dictionary] = []
	for _i in range(40):
		board.append({})
	board[0] = {"type": "normal", "level": 1, "clicks_left": 4}
	return {
		"coins": -99,
		"current_round": 99,
		"player_health": 999,
		"difficulty_id": "unknown",
		"wager_mode": "panic",
		"starter_bag_id": "missing",
		"board_tiles": board,
		"coin_bag": [],
		"hand_tiles": [],
		"current_event": {}
	}


func _backup_user_files() -> void:
	for path in PATHS:
		backups[path] = _read_text(path) if FileAccess.file_exists(path) else null
		_remove_user_file(path)
		_remove_user_file("%s.corrupt" % path)


func _restore_user_files() -> void:
	for path in PATHS:
		_remove_user_file(path)
		_remove_user_file("%s.corrupt" % path)
		if backups[path] != null:
			_write_text(path, String(backups[path]))


func _cleanup_main() -> void:
	if main == null:
		return
	main._release_audio_players()
	main.queue_free()
	main = null


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _remove_user_file(path: String) -> void:
	var global_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_path):
		DirAccess.remove_absolute(global_path)


func _global_exists(path: String) -> bool:
	return FileAccess.file_exists(ProjectSettings.globalize_path(path))


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
