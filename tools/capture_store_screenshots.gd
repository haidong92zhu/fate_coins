extends SceneTree

const OUTPUT_DIR := "res://screenshots/steam"
const VIEW_SIZE := Vector2i(1600, 1000)
const SCREENSHOT_NOTES := {
	"01_main_menu.png": {
		"title": "Productized main menu",
		"caption": "Persistent settings, how-to-play rules, credits/licenses, save preview, difficulty selection, and first-run entry point."
	},
	"02_preparation_board.png": {
		"title": "Plan your fate machine",
		"caption": "Drag coins from the fate hand, read the tutorial checklist, and prepare for quota pressure."
	},
	"03_opening_layout.png": {
		"title": "Build chain routes",
		"caption": "Directional and special coins turn a small board into a risky coin engine."
	},
	"04_combat_chain.png": {
		"title": "Click, chain, and fight",
		"caption": "Manual triggers earn coins, deal damage, and can cascade across the board."
	},
	"05_boss_pressure.png": {
		"title": "Survive boss disruption",
		"caption": "Bosses lock, jam, pollute, and steal from your strongest coins."
	}
}

var main: Variant


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DisplayServer.window_set_size(VIEW_SIZE)
	root.size = VIEW_SIZE
	var scene := load("res://scenes/main.tscn") as PackedScene
	main = scene.instantiate()
	root.add_child(main)
	main.size = VIEW_SIZE
	await _settle()
	main.language_id = "en_US"
	main._apply_language()
	await _settle()

	await _capture("01_main_menu.png")
	main._hide_menu()
	await _settle()
	_place_opening_coins()
	await _settle()
	await _capture("02_preparation_board.png")

	main._skip_tutorial()
	await _settle()
	await _capture("03_opening_layout.png")

	main._start_round()
	await _settle()
	main._on_slot_pressed(6)
	await _settle(8)
	await _capture("04_combat_chain.png")

	_setup_boss_showcase()
	await _settle()
	await _capture("05_boss_pressure.png")

	print("Captured Steam screenshots")
	await _cleanup()
	quit()


func _settle(frames: int = 4) -> void:
	for _i in range(frames):
		await process_frame


func _capture(filename: String) -> void:
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		push_error("Viewport texture is unavailable. Run this script without --headless to capture screenshots.")
		quit(1)
		return
	var image := texture.get_image()
	if image == null:
		push_error("Viewport image is unavailable. Run this script without --headless to capture screenshots.")
		quit(1)
		return
	var path := "%s/%s" % [OUTPUT_DIR, filename]
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save screenshot %s: %s" % [path, error_string(error)])


func _place_opening_coins() -> void:
	main.starter_bag_id = "chain"
	main._initialize_coin_bag()
	var hand: Array[String] = ["left", "right", "star", "spirit", "lucky", "compass"]
	main.hand_tiles = hand
	var placements := {
		6: "left",
		7: "star",
		8: "right",
		12: "spirit",
		2: "lucky"
	}
	for raw_slot in placements.keys():
		var slot := int(raw_slot)
		var tile_type := String(placements[raw_slot])
		main.drop_on_slot(slot, {"kind": "palette", "type": tile_type})


func _setup_boss_showcase() -> void:
	main.is_intermission = true
	main.game_state.current_round = 8
	var boss_enemies: Array[Dictionary] = [main._make_enemy("lock_boss", 8), main._make_enemy("sniper", 8)]
	main.enemies = boss_enemies
	main.current_event = {"name": "庄家凝视", "desc": "敌人攻击提高，连锁收益也更高。", "enemy_attack_delta": 2, "trigger_bonus": 1}
	main._rebuild_enemy_panel()
	main._show_boss_warning_if_needed()
	main._update_ui("Boss showcase: The Lock Warden is pinning down your core route.")


func _cleanup() -> void:
	_write_manifest()
	if main != null:
		if main.has_method("_release_audio_players"):
			main._release_audio_players()
		root.remove_child(main)
		main.free()
		main = null
	await process_frame


func _write_manifest() -> void:
	var lines: Array[String] = [
		"# Fate Coins Steam Screenshot Candidates",
		"",
		"Generated at 1600x1000 from live Godot UI states. These are English storefront candidates, not mockups.",
		""
	]
	for filename in SCREENSHOT_NOTES.keys():
		var note: Dictionary = SCREENSHOT_NOTES[filename]
		lines.append("- `%s` - %s: %s" % [filename, note["title"], note["caption"]])
	var path := "%s/README.md" % OUTPUT_DIR
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(lines) + "\n")
