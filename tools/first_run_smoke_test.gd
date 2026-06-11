extends SceneTree

const MainScene := preload("res://scenes/main.tscn")

var failed := false
var main: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	main = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_assert(main.game_state != null, "GameState should be initialized")
	_assert(main.menu_overlay != null and main.menu_overlay.visible, "Main menu should open on first launch")
	main._hide_menu()
	await process_frame

	_assert(main.tutorial_focus == "place", "Tutorial should first focus hand placement")
	_assert(main.tutorial_panel.visible, "Tutorial panel should be visible")
	_assert(main.hand_tiles.size() > 0, "Opening hand should contain tiles")

	for slot_index in range(3):
		var tile_type := String(main.hand_tiles[0])
		main.drop_on_slot(slot_index, {"kind": "palette", "type": tile_type})
		await process_frame

	_assert(main._placed_tile_count() == 3, "Player path should place three starter tiles")
	_assert(main.tutorial_focus == "action_start", "Tutorial should focus start button after enough placements")
	_assert(main.action_button.text == "开始下一回合", "Action button should be ready to start the round")

	main._on_action_button_pressed()
	await process_frame

	_assert(not main.is_intermission, "Action button should start the action phase")
	_assert(main.tutorial_focus == "board_coin", "Tutorial should focus clickable board coins")
	_assert(main.manual_clicks_left > 0, "Action phase should provide manual clicks")

	var click_index := _first_clickable_slot()
	_assert(click_index != -1, "There should be at least one clickable tile")
	var clicks_before := int(main.manual_clicks_left)
	main._on_slot_pressed(click_index)
	await process_frame

	_assert(int(main.manual_clicks_left) <= clicks_before, "Clicking a tile should consume or convert one manual click")
	_assert(main.tutorial_focus == "board_coin" or main.tutorial_focus == "action_end", "Tutorial should remain on board or move to end button")

	main._on_action_button_pressed()
	await process_frame
	await process_frame

	_assert(main.is_intermission, "Ending the round should return to intermission")
	_assert(int(main.game_state.current_round) == 2, "First round settlement should advance to round 2")
	_assert(main.settlement_dialog != null and main.settlement_dialog.visible, "Settlement dialog should appear after round end")

	if failed:
		push_error("First-run smoke test failed")
		main._release_audio_players()
		main.queue_free()
		await process_frame
		quit(1)
	else:
		print("First-run smoke test passed")
		main._release_audio_players()
		main.queue_free()
		await process_frame
		quit(0)


func _first_clickable_slot() -> int:
	for index in range(main.TOTAL_SLOTS):
		if main._slot_can_tutorial_click(index):
			return index
	return -1


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
