extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const SAVE_PATH := "user://fate_coins_save.json"

var failed := false
var main: Control
var save_backup = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_backup_save()
	main = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	main.language_id = "en_US"
	main._apply_language()
	await process_frame

	_assert(main.header_menu_button.text == "Menu", "Header menu button should localize to English")
	_assert(main.menu_new_button.text == "New Game", "Main menu new game button should localize to English")
	_assert(main.menu_save_button.text == "Save Run", "Main menu save button should localize to English")
	_assert(main.menu_settings_button.text == "Settings", "Main menu settings button should localize to English")
	_assert(main.menu_rules_button.text == "How To Play", "Main menu rules button should localize to English")
	_assert(main.menu_credits_button.text == "Credits / Licenses", "Main menu credits button should localize to English")
	if not FileAccess.file_exists(main.SAVE_PATH):
		_assert(main.menu_delete_save_button.disabled, "Delete save should be disabled when no save exists")
	_assert(main.settings_dialog.title == "Settings", "Settings dialog title should localize to English")
	_assert(main.rules_dialog.title == "How To Play", "Rules dialog title should localize to English")
	_assert(main.rules_dialog.ok_button_text == "Got It", "Rules dialog OK should localize to English")
	_assert(main.rules_dialog.dialog_text.find("30-Second Core Loop") != -1, "Rules dialog should explain the English core loop")
	_assert(main.rules_dialog.dialog_text.find("Planning: drag fate-hand coins") != -1, "Rules dialog should explain drag placement")
	_assert(main.credits_dialog.title == "Credits / Licenses", "Credits dialog title should localize to English")
	_assert(main.credits_dialog.ok_button_text == "Close", "Credits dialog OK should localize to English")
	_assert(main.credits_dialog.dialog_text.find("Godot Engine 4.6") != -1, "Credits dialog should mention the engine")
	_assert(main.credits_dialog.dialog_text.find("MIT License") != -1, "Credits dialog should mention Godot licensing")
	_assert(main.credits_dialog.dialog_text.find("LICENSES.md") != -1, "Credits dialog should point external asset updates to LICENSES.md")
	_assert(main.delete_save_confirm_dialog.title == "Delete Save?", "Delete confirmation title should localize to English")
	_assert(main.delete_save_confirm_dialog.ok_button_text == "Confirm", "Delete confirmation OK should localize to English")
	_assert(main.delete_save_confirm_dialog.get_cancel_button().text == "Cancel", "Delete confirmation cancel should localize to English")
	_assert(main.quit_confirm_dialog.title == "Quit to Desktop?", "Quit confirmation title should localize to English")
	_assert(main.game_over_menu_button.text == "Back to Menu", "Game-over menu action should localize to English")
	_assert(main.fullscreen_toggle.text == "Fullscreen", "Fullscreen toggle should localize to English")
	_assert(main.mute_toggle.text == "Mute", "Mute toggle should localize to English")
	_assert(main.settings_accessibility_label.text == "Accessibility", "Accessibility label should localize to English")
	_assert(main.reduced_motion_toggle.text == "Reduced Motion", "Reduced motion toggle should localize to English")
	_assert(main.tutorial_toggle.text == "Show First-Run Tutorial", "Tutorial toggle should localize to English")
	_assert(main.action_button.text == "Start Round", "Action button should localize to English")
	_assert(main.coin_label.text.begins_with("Coins"), "HUD coins label should localize to English")
	_assert(main.tutorial_label.text.find("Tutorial 1/5") != -1, "Tutorial should localize to English")
	_assert(main.tutorial_label.text.find("Goals:") != -1, "Tutorial should show localized goal checklist")
	_assert(main.tutorial_label.text.find("Now:") != -1, "Tutorial should show localized current action")
	_assert(main.fate_hand_title_label.text == "Fate Hand", "Side hand title should localize to English")
	_assert(main.shop_title_label.text == "Fate Shop", "Shop section title should localize to English")
	_assert(main.delete_zone_label.text.find("Recycle Zone") != -1, "Recycle zone should localize to English")
	_assert(main.starter_select.get_item_text(0) == "Balanced", "Starter bag names should localize to English")
	_assert(main.wager_select.get_item_text(0) == "Safe", "Wager names should localize to English")
	_assert(main.difficulty_select.get_item_text(0).begins_with("Normal - Standard challenge"), "Difficulty text should localize to English")
	_assert(not main.palette_views.is_empty(), "Palette should contain localized hand tiles")
	var first_tile_type := String(main.palette_views.keys()[0])
	var first_tile: Control = main.palette_views[first_tile_type]
	_assert(first_tile.tooltip_text.find("点击") == -1, "Hand tile tooltip should not remain Chinese in English")
	_assert(first_tile.tooltip_text.length() > 20, "Hand tile tooltip should include English rules text")
	_assert(main.shop_container.get_child_count() > 0, "Market should contain localized offers")
	var first_offer: Button = main.shop_container.get_child(0)
	_assert(first_offer.tooltip_text.find("Bought coins enter the fate bag") != -1, "Market tooltip should localize the buy explanation")
	_assert(main.relic_container.get_child_count() > 1, "Relic market should contain localized offers")
	var first_relic: Button = main.relic_container.get_child(1)
	_assert(first_relic.text.find("coins") != -1, "Relic offer price should localize to English")
	_assert(first_relic.tooltip_text.find("。") == -1, "Relic tooltip should not remain Chinese in English")
	_assert(main.consumable_container.get_child_count() > 0, "Consumable market should contain localized offers")
	var first_consumable: Button = main.consumable_container.get_child(0)
	_assert(first_consumable.tooltip_text.find("。") == -1, "Consumable tooltip should not remain Chinese in English")
	_assert(main.curse_container.get_child_count() > 1, "Curse market should contain localized offers")
	var first_curse: Button = main.curse_container.get_child(1)
	_assert(first_curse.tooltip_text.find("immediately") != -1 or first_curse.tooltip_text.find("future") != -1, "Curse tooltip should localize to English")
	_assert(main.enemy_panel_container.get_child_count() > 0, "Enemy panel should contain localized cards")
	var first_enemy: Control = main.enemy_panel_container.get_child(0)
	_assert(first_enemy.tooltip_text.find("Attack") != -1, "Enemy card tooltip should localize stat labels to English")
	_assert(main.progress_label.text.find("Event:") != -1, "Progress event label should localize to English")
	_assert(main.progress_label.text.find("Tempo: Steady") != -1, "Director tempo label should localize to English")
	_assert(main.progress_label.text.find("Bag: ") != -1 and main.progress_label.text.find("Due: ") != -1, "HUD compact metrics should localize to English")
	_assert(main.event_icon_rect.tooltip_text.find("。") == -1, "Event tooltip should not remain Chinese in English")

	main.drop_on_slot(0, {"kind": "palette", "type": first_tile_type})
	await process_frame
	_assert(main.tile_type_at(0) == first_tile_type, "Localized test should place a hand tile")
	_assert(main.notice_label.text.find("Placed") != -1 and main.notice_label.text.find("上阵") == -1, "Placement notice should localize to English")
	var slot_view: Dictionary = main.slot_views[0]
	var slot_button: Button = slot_view["button"]
	var slot_info: Label = slot_view["info"]
	_assert(slot_info.text.find(main._tile_name(first_tile_type)) != -1, "Placed coin label should use localized tile name")
	_assert(slot_button.tooltip_text.find("heads coins") != -1, "Placed coin tooltip should localize stat text")

	main.board_tiles[0]["locked_turns"] = 1
	main.board_tiles[0]["jammed_turns"] = 1
	main.board_tiles[0]["polluted_turns"] = 1
	main.board_tiles[0]["steal_mark_turns"] = 1
	var state_text: String = main._tile_state_text(main.board_tiles[0])
	var state_description: String = main._tile_state_description(main.board_tiles[0])
	_assert(state_text.find("Lock1") != -1 and state_text.find("Jam1") != -1, "Tile state badges should localize to English")
	_assert(state_description.find("State:") == 0 and state_description.find("状态") == -1, "Tile state description should localize to English")

	var thief_report: String = main._apply_enemy_interference(main._make_enemy("thief", 1))
	_assert(thief_report.find("marked") != -1 and thief_report.find("标记") == -1, "Enemy interference report should localize to English")
	var outcome_text: String = main._outcome_feedback_text({"success": false, "heal": 0, "manual_bonus": 0, "self_damage": 0}, 0, 0, true)
	_assert(outcome_text.find("Heads") != -1 and outcome_text.find("miss") != -1, "Flip feedback should localize to English")
	main.wager_mode = "greedy"
	_assert(main._wager_warning_text().find("Greedy warning") != -1, "Wager warning should localize to English")
	_assert(main._run_score_summary().find("Difficulty:") != -1, "Run score summary should localize to English")
	_assert(main._run_advice(false, "金币不足以支付本轮收取。").find("economy failed") != -1, "Run advice should localize to English")
	main._on_slot_pressed(1)
	await process_frame
	_assert(main.notice_label.text.find("Planning phase") != -1, "Planning click warning should localize to English")

	main.last_round_summary = {
		"round": 1,
		"event": "Test Event",
		"collected": 8,
		"damage": 4,
		"failures": 0,
		"due": 1,
		"best_chain": 1,
		"enemy_report": "No enemy pressure."
	}
	main._show_settlement()
	await process_frame
	_assert(main.settlement_dialog.title == "Round Settlement", "Settlement title should localize to English")
	_assert(main.settlement_dialog.dialog_text.find("Tutorial Recap") != -1, "Settlement recap should localize to English")
	_assert(main.settlement_dialog.dialog_text.find("core loop") != -1, "English recap should explain the core loop")

	main.language_id = "zh_CN"
	main._apply_language()
	await process_frame
	_assert(main.menu_new_button.text == "新游戏", "Language switch should restore Simplified Chinese")
	_assert(main.menu_rules_button.text == "玩法说明", "Rules button should restore Simplified Chinese")
	_assert(main.menu_credits_button.text == "鸣谢与许可证", "Credits button should restore Simplified Chinese")
	_assert(main.rules_dialog.title == "玩法说明", "Rules dialog title should restore Simplified Chinese")
	_assert(main.rules_dialog.dialog_text.find("30 秒核心循环") != -1, "Rules dialog body should restore Simplified Chinese")
	_assert(main.credits_dialog.title == "鸣谢与许可证", "Credits dialog title should restore Simplified Chinese")
	_assert(main.credits_dialog.dialog_text.find("MIT License") != -1, "Credits dialog body should restore license notes")
	_assert(main.settings_accessibility_label.text == "可访问性", "Accessibility label should restore Simplified Chinese")
	_assert(main.reduced_motion_toggle.text == "减少动效", "Reduced motion toggle should restore Simplified Chinese")
	_assert(main.action_button.text == "开始下一回合", "Action button should restore Simplified Chinese")
	_assert(main.delete_save_confirm_dialog.title == "删除存档？", "Delete confirmation should restore Simplified Chinese")

	if failed:
		push_error("Localization smoke test failed")
		main._release_audio_players()
		main.queue_free()
		await process_frame
		_restore_save()
		quit(1)
	else:
		print("Localization smoke test passed")
		main._release_audio_players()
		main.queue_free()
		await process_frame
		_restore_save()
		quit(0)


func _backup_save() -> void:
	save_backup = _read_text(SAVE_PATH) if FileAccess.file_exists(SAVE_PATH) else null
	_remove_user_file(SAVE_PATH)


func _restore_save() -> void:
	_remove_user_file(SAVE_PATH)
	if save_backup != null:
		var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(String(save_backup))


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _remove_user_file(path: String) -> void:
	var global_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_path):
		DirAccess.remove_absolute(global_path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
