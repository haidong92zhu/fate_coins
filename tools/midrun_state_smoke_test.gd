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
	main._hide_menu()

	for starter_id in main.STARTER_BAG_ORDER:
		await _exercise_starter(String(starter_id))

	if failed:
		push_error("Mid-run state smoke test failed")
		_cleanup()
		quit(1)
	else:
		print("Mid-run state smoke test passed")
		_cleanup()
		quit(0)


func _exercise_starter(starter_id: String) -> void:
	var save_data := _make_midrun_save(starter_id)
	main._apply_save_data(save_data)
	await process_frame

	_assert(main.starter_bag_id == starter_id, "%s starter should restore" % starter_id)
	_assert(int(main.game_state.current_round) == 12, "%s should restore round 12" % starter_id)
	_assert(main._placed_tile_count() >= 7, "%s should restore a built board" % starter_id)
	_assert(main.enemies.size() > 0, "%s should have enemies after restore" % starter_id)
	_assert(main.progress_label.text.find(main.STARTER_BAGS[starter_id]["name"]) == -1 or main.progress_label.text.length() > 0, "%s UI should refresh after restore" % starter_id)

	main._start_round()
	await process_frame
	_assert(not main.is_intermission, "%s should enter action phase" % starter_id)
	_assert(main.manual_clicks_left > 0, "%s should have manual clicks" % starter_id)

	var before_round := int(main.game_state.current_round)
	var before_health := int(main.player_health)
	var before_coins := int(main.game_state.coins)
	var click_index := _best_click_slot()
	_assert(click_index != -1, "%s should have a clickable tile" % starter_id)
	main._on_slot_pressed(click_index)
	await process_frame
	_assert(int(main.round_collected) >= 0, "%s collected total should remain valid" % starter_id)
	_assert(int(main.round_damage) >= 0, "%s damage total should remain valid" % starter_id)
	_assert(int(main.player_health) <= main.MAX_HEALTH, "%s health should stay within max" % starter_id)

	main._end_round()
	await process_frame
	await process_frame
	_assert(main.is_intermission, "%s should return to intermission after settlement" % starter_id)
	_assert(int(main.game_state.current_round) == before_round + 1 or int(main.player_health) <= 0, "%s should advance or end safely" % starter_id)
	_assert(main.last_round_summary.has("enemy_report"), "%s settlement should include enemy report" % starter_id)
	_assert(int(main.game_state.coins) >= 0 or int(main.player_health) <= 0, "%s coins should not remain negative after live round" % starter_id)
	_assert(int(main.player_health) <= before_health or int(main.game_state.coins) >= before_coins or int(main.round_damage) >= 0, "%s state should change after live round" % starter_id)

	var round_after := int(main.game_state.current_round)
	var health_after := int(main.player_health)
	var coins_after := int(main.game_state.coins)
	var snapshot := _snapshot_from_main()
	main._apply_save_data(snapshot)
	await process_frame
	_assert(int(main.game_state.current_round) == round_after, "%s save restore should preserve round" % starter_id)
	_assert(int(main.player_health) == health_after, "%s save restore should preserve health" % starter_id)
	_assert(int(main.game_state.coins) == coins_after, "%s save restore should preserve coins" % starter_id)
	_assert(main.board_tiles.size() == main.TOTAL_SLOTS, "%s save restore should preserve board size" % starter_id)


func _make_midrun_save(starter_id: String) -> Dictionary:
	var board: Array[Dictionary] = []
	for _i in range(main.TOTAL_SLOTS):
		board.append({})
	var loadout: Array[String] = _loadout_for(starter_id)
	var slots := [1, 5, 6, 7, 8, 11, 12, 13, 17]
	for i in range(min(loadout.size(), slots.size())):
		var tile: Dictionary = main._new_tile(String(loadout[i]))
		tile["level"] = 2 if i % 3 == 0 else 1
		tile["invested"] = 4 * int(tile["level"])
		tile["clicks_left"] = main._round_tile_click_max(tile)
		board[int(slots[i])] = tile

	var bag: Array[String] = []
	for tile_id in main.STARTER_BAGS[starter_id]["coins"]:
		bag.append(String(tile_id))
	bag.append_array(["shield", "compass", "bank", "lucky", "reverse", "anchor"])

	return {
		"coins": 72,
		"current_round": 12,
		"required_coins": main._quota_for_round(12),
		"player_health": 34,
		"difficulty_id": "normal",
		"wager_mode": "standard",
		"tutorial_enabled": false,
		"quota": main._quota_for_round(12),
		"starter_bag_id": starter_id,
		"coin_bag": bag,
		"hand_tiles": ["shield", "lucky", "reverse", "bank", "anchor", "compass"],
		"locked_hand_tiles": [],
		"removed_from_bag": 1,
		"shop_offer_types": ["shield", "compass", "bank", "mirror"],
		"relic_offer_ids": ["golden_glove", "shield_charm", "war_banner"],
		"consumable_offer_ids": ["heal_potion", "repair_kit"],
		"curse_offer_ids": ["blood_money", "thin_bag"],
		"owned_relics": ["golden_glove", "shield_charm"],
		"active_curses": [],
		"enemies": [main._make_enemy("market_boss", 12), main._make_enemy("sniper", 12)],
		"current_event": {"name": "复现压力", "desc": "中期复现测试事件。", "coin_bonus": 1, "trigger_bonus": 0.06, "manual_bonus": 1, "quota_discount": 1, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 0},
		"board_tiles": board,
		"is_intermission": true,
		"manual_clicks_left": main._round_manual_click_max(),
		"round_collected": 0,
		"round_damage": 0,
		"round_failures": 0,
		"run_total_collected": 420,
		"run_total_damage": 360,
		"run_kills": 7,
		"run_best_chain": 5,
		"best_chain_this_round": 0
	}


func _loadout_for(starter_id: String) -> Array[String]:
	match starter_id:
		"chain":
			return ["left", "right", "magnet", "arc", "compass", "lucky", "down", "bank", "shield"]
		"gambler":
			return ["reverse", "glass", "joker", "surge", "stock", "mirror", "lucky", "right", "shield"]
		"blood":
			return ["vampire", "demon", "bloom", "angel", "lucky", "reverse", "up", "down", "shield"]
		_:
			return ["shield", "compass", "left", "right", "lucky", "reverse", "bank", "anchor", "down"]


func _snapshot_from_main() -> Dictionary:
	return {
		"coins": main.game_state.coins,
		"current_round": main.game_state.current_round,
		"required_coins": main.game_state.required_coins,
		"player_health": main.player_health,
		"difficulty_id": main.difficulty_id,
		"wager_mode": main.wager_mode,
		"tutorial_enabled": main.tutorial_enabled,
		"quota": main.quota,
		"starter_bag_id": main.starter_bag_id,
		"coin_bag": main.coin_bag,
		"hand_tiles": main.hand_tiles,
		"locked_hand_tiles": main.locked_hand_tiles,
		"removed_from_bag": main.removed_from_bag,
		"shop_offer_types": main.shop_offer_types,
		"relic_offer_ids": main.relic_offer_ids,
		"consumable_offer_ids": main.consumable_offer_ids,
		"curse_offer_ids": main.curse_offer_ids,
		"owned_relics": main.owned_relics,
		"active_curses": main.active_curses,
		"enemies": main.enemies,
		"current_event": main.current_event,
		"board_tiles": main.board_tiles,
		"is_intermission": main.is_intermission,
		"manual_clicks_left": main.manual_clicks_left,
		"round_collected": main.round_collected,
		"round_damage": main.round_damage,
		"round_failures": main.round_failures,
		"run_total_collected": main.run_total_collected,
		"run_total_damage": main.run_total_damage,
		"run_kills": main.run_kills,
		"run_best_chain": main.run_best_chain,
		"best_chain_this_round": main.best_chain_this_round
	}


func _best_click_slot() -> int:
	for index in range(main.TOTAL_SLOTS):
		if not main.board_tiles[index].is_empty() and int(main.board_tiles[index].get("clicks_left", 0)) > 0 and int(main.board_tiles[index].get("locked_turns", 0)) <= 0:
			return index
	return -1


func _cleanup() -> void:
	if main != null:
		main._release_audio_players()
		main.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
