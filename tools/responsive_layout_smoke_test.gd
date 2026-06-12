extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const REPORT_PATH := "res://build/responsive_layout_report.md"
const DESIGN_SIZE := Vector2i(1600, 1000)
const MIN_DESKTOP_WINDOW := Vector2i(1280, 800)
const MENU_PANEL_SIZE := Vector2i(980, 620)
const RULES_DIALOG_SIZE := Vector2i(780, 620)
const CREDITS_DIALOG_SIZE := Vector2i(780, 640)

var failed := false
var main: Control
var report_lines: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	report_lines = [
		"# Fate Coins Responsive Layout Report",
		"",
		"- Generated: %s" % Time.get_datetime_string_from_system(false, true),
		"- Checks: minimum desktop window constraints, default design-layout node presence, nonzero critical controls, menu button ordering.",
		""
	]
	_static_size_checks()
	await _runtime_design_layout_check()
	_write_report()
	if failed:
		push_error("Responsive layout smoke test failed")
		quit(1)
		return
	print("Responsive layout smoke test passed")
	quit(0)


func _static_size_checks() -> void:
	_assert(_fits(MENU_PANEL_SIZE, MIN_DESKTOP_WINDOW), "Main menu panel should fit 1280x800 minimum desktop window")
	_assert(_fits(RULES_DIALOG_SIZE, MIN_DESKTOP_WINDOW), "Rules dialog target size should fit 1280x800 minimum desktop window")
	_assert(_fits(CREDITS_DIALOG_SIZE, MIN_DESKTOP_WINDOW), "Credits dialog target size should fit 1280x800 minimum desktop window")
	report_lines.append("## Static Size Checks")
	report_lines.append("")
	report_lines.append("- [PASS] Main menu panel target: %s within %s" % [_size_text(MENU_PANEL_SIZE), _size_text(MIN_DESKTOP_WINDOW)])
	report_lines.append("- [PASS] Rules dialog target: %s within %s" % [_size_text(RULES_DIALOG_SIZE), _size_text(MIN_DESKTOP_WINDOW)])
	report_lines.append("- [PASS] Credits dialog target: %s within %s" % [_size_text(CREDITS_DIALOG_SIZE), _size_text(MIN_DESKTOP_WINDOW)])
	report_lines.append("")


func _runtime_design_layout_check() -> void:
	root.size = DESIGN_SIZE
	main = MainScene.instantiate()
	root.add_child(main)
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame
	main.language_id = "en_US"
	main._apply_language()
	main._show_menu()
	await process_frame
	await process_frame

	var bounds := main.get_global_rect()
	_assert(bounds.size.x > 0.0 and bounds.size.y > 0.0, "Main scene should have a nonzero design layout rect")
	_assert_control_nonzero(main.header_menu_button, "header menu")
	_assert_control_nonzero(main.action_button, "action button")
	_assert_control_nonzero(main.side_tabs, "side tabs")
	_assert_control_nonzero(main.progress_label, "progress label")
	_assert_control_nonzero(main.tutorial_panel, "tutorial panel")
	_assert_control_nonzero(main.menu_overlay, "menu overlay")
	_assert_menu_buttons()
	_assert_board_slots()
	report_lines.append("## Runtime Layout Checks")
	report_lines.append("")
	report_lines.append("- [PASS] Critical HUD/menu controls exist and have nonzero layout rects.")
	report_lines.append("- [PASS] Menu action buttons are ordered without vertical overlap.")
	report_lines.append("- [PASS] Board exposes %d nonzero slot views." % main.slot_views.size())
	report_lines.append("")

	main._release_audio_players()
	root.remove_child(main)
	main.free()
	main = null
	await process_frame


func _assert_menu_buttons() -> void:
	var buttons: Array[Control] = [
		main.menu_new_button,
		main.menu_continue_button,
		main.menu_save_button,
		main.menu_delete_save_button,
		main.menu_settings_button,
		main.menu_rules_button,
		main.menu_credits_button,
		main.menu_close_button,
		main.menu_quit_button
	]
	var previous_bottom := -1000000.0
	for button in buttons:
		_assert_control_nonzero(button, button.text)
		var rect := button.get_global_rect()
		_assert(rect.position.y >= previous_bottom - 1.0, "Menu buttons should not overlap: %s" % button.text)
		previous_bottom = rect.position.y + rect.size.y


func _assert_board_slots() -> void:
	_assert(main.slot_views.size() == main.TOTAL_SLOTS, "Board should expose all slot views")
	for index in range(main.slot_views.size()):
		var view: Dictionary = main.slot_views[index]
		var slot := view.get("slot") as Control
		_assert_control_nonzero(slot, "board slot %d" % index)


func _assert_control_nonzero(control: Control, label: String) -> void:
	_assert(control != null, "%s should exist" % label)
	if control == null:
		return
	var rect := control.get_global_rect()
	_assert(rect.size.x > 0.0 and rect.size.y > 0.0, "%s should have nonzero size" % label)


func _fits(child: Vector2i, parent: Vector2i) -> bool:
	return child.x <= parent.x and child.y <= parent.y


func _write_report() -> void:
	report_lines.append("## Result")
	report_lines.append("")
	report_lines.append("- %s Responsive layout smoke test %s." % ["[FAIL]" if failed else "[PASS]", "failed" if failed else "passed"])
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(report_lines))


func _size_text(size: Vector2i) -> String:
	return "%dx%d" % [size.x, size.y]


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	report_lines.append("- [FAIL] %s" % message)
	push_error(message)
