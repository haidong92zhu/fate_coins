extends SceneTree

const REPORT_PATH := "res://build/first_run_playtest_materials_report.md"
const PROTOCOL_PATH := "res://PLAYTEST_FIRST_RUN_PROTOCOL.md"
const TEMPLATE_PATH := "res://PLAYTEST_FIRST_RUN_OBSERVATION_TEMPLATE.md"
const REQUIRED_PROTOCOL_TERMS := [
	"30 seconds",
	"drag fate-hand coins",
	"start the round",
	"click board coins",
	"settlement recap",
	"How To Play",
	"Pass Bar For Steam-Readiness",
	"3 fresh players"
]
const REQUIRED_TASKS := [
	"Start a new game",
	"Identify the fate hand",
	"Drag 3 hand coins",
	"Start the round",
	"Click at least 1 board coin",
	"End the round",
	"Read the settlement recap"
]
const REQUIRED_TAGS := [
	"unclear_goal",
	"missed_drag",
	"missed_start",
	"missed_click",
	"missed_end",
	"hud_overload",
	"text_too_small",
	"rules_needed",
	"shop_confusion",
	"enemy_confusion",
	"wager_confusion"
]
const REQUIRED_TEMPLATE_TERMS := [
	"First 30 Seconds",
	"Core Loop Timing",
	"Friction Tags",
	"Direct Quotes",
	"Observer Summary",
	"Required Follow-Up"
]


func _init() -> void:
	var failures: Array[String] = []
	var report_lines := _build_report(failures)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var report := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if report == null:
		push_error("Could not write first-run playtest materials report")
		quit(1)
		return
	report.store_string("\n".join(report_lines))
	if failures.is_empty():
		print("First-run playtest materials check passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _build_report(failures: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	lines.append("# Fate Coins First-Run Playtest Materials Report")
	lines.append("")
	lines.append("- Generated: %s" % Time.get_datetime_string_from_system(false, true))
	lines.append("- Checks: protocol coverage, core-loop task coverage, friction tags, pass bar, and observation template sections.")
	lines.append("")
	lines.append("## Protocol")
	lines.append("")
	lines.append_array(_protocol_lines(failures))
	lines.append("")
	lines.append("## Observation Template")
	lines.append("")
	lines.append_array(_template_lines(failures))
	lines.append("")
	return lines


func _protocol_lines(failures: Array[String]) -> Array[String]:
	var text := _read_text(PROTOCOL_PATH)
	var errors: Array[String] = []
	if text.length() < 1500:
		errors.append("protocol is too short")
	for term in REQUIRED_PROTOCOL_TERMS:
		if text.find(term) == -1:
			errors.append("missing protocol term %s" % term)
	for task in REQUIRED_TASKS:
		if text.find(task) == -1:
			errors.append("missing core-loop task %s" % task)
	for tag in REQUIRED_TAGS:
		if text.find(tag) == -1:
			errors.append("missing friction tag %s" % tag)
	return _lines_for_file(PROTOCOL_PATH, text, errors, failures)


func _template_lines(failures: Array[String]) -> Array[String]:
	var text := _read_text(TEMPLATE_PATH)
	var errors: Array[String] = []
	if text.length() < 900:
		errors.append("template is too short")
	for term in REQUIRED_TEMPLATE_TERMS:
		if text.find(term) == -1:
			errors.append("missing template section %s" % term)
	for tag in REQUIRED_TAGS:
		if text.find(tag) == -1:
			errors.append("template missing friction tag %s" % tag)
	return _lines_for_file(TEMPLATE_PATH, text, errors, failures)


func _lines_for_file(path: String, text: String, errors: Array[String], failures: Array[String]) -> Array[String]:
	var status := "pass" if errors.is_empty() else "fail"
	var lines: Array[String] = ["- %s `%s`: %d chars" % [_status_icon(status), path, text.length()]]
	for error in errors:
		failures.append("%s: %s" % [path, error])
		lines.append("  - %s" % error)
	return lines


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _status_icon(status: String) -> String:
	return "[PASS]" if status == "pass" else "[FAIL]"
