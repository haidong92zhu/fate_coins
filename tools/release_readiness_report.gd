extends SceneTree

const REPORT_PATH := "res://build/release_readiness_report.md"
const AUDIO_REPORT_PATH := "res://build/audio_quality_report.md"
const STORE_REPORT_PATH := "res://build/store_page_materials_report.md"
const PLAYTEST_REPORT_PATH := "res://build/first_run_playtest_materials_report.md"
const STORE_VISUAL_REPORT_PATH := "res://build/store_visual_quality_report.md"
const LICENSES_PATH := "res://LICENSES.md"
const MAIN_SCRIPT_PATH := "res://scripts/main.gd"
const RESPONSIVE_LAYOUT_REPORT_PATH := "res://build/responsive_layout_report.md"
const REQUIRED_BRANDING := {
	"App icon": {"path": "res://textures/branding/app_icon.png", "size": Vector2i(1024, 1024)},
	"Boot splash": {"path": "res://textures/branding/boot_splash.png", "size": Vector2i(1600, 1000)},
	"Steam capsule": {"path": "res://textures/branding/steam_capsule_616x353.png", "size": Vector2i(616, 353)},
	"Steam header": {"path": "res://textures/branding/steam_header_920x430.png", "size": Vector2i(920, 430)},
	"Steam library": {"path": "res://textures/branding/steam_library_600x900.png", "size": Vector2i(600, 900)}
}
const REQUIRED_SCREENSHOTS := [
	"res://screenshots/steam/01_main_menu.png",
	"res://screenshots/steam/02_preparation_board.png",
	"res://screenshots/steam/03_opening_layout.png",
	"res://screenshots/steam/04_combat_chain.png",
	"res://screenshots/steam/05_boss_pressure.png"
]
const SCREENSHOT_SIZE := Vector2i(1600, 1000)
const REQUIRED_PRESETS := {
	"Windows Desktop": "build/windows/FateCoins.exe",
	"macOS": "build/macos/FateCoins.zip",
	"Linux/X11": "build/linux/FateCoins.x86_64"
}
const TEMPLATE_FILES := {
	"Windows Desktop": [
		"windows_debug_x86_64.exe",
		"windows_release_x86_64.exe"
	],
	"macOS": [
		"macos.zip"
	],
	"Linux/X11": [
		"linux_debug.x86_64",
		"linux_release.x86_64"
	]
}


func _init() -> void:
	var report := _build_report()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write release readiness report: %s" % REPORT_PATH)
		quit(1)
		return
	file.store_string(report)
	print("Release readiness report written to %s" % ProjectSettings.globalize_path(REPORT_PATH))
	quit(0)


func _build_report() -> String:
	var sections: Array[String] = []
	sections.append("# Fate Coins Release Readiness Report")
	sections.append("")
	sections.append("- Generated: %s" % Time.get_datetime_string_from_system(false, true))
	sections.append("- Godot: %s" % Engine.get_version_info().get("string", "unknown"))
	sections.append("- Project: %s %s" % [
		ProjectSettings.get_setting("application/config/name", "unknown"),
		ProjectSettings.get_setting("application/config/version", "unknown")
	])
	sections.append("- Main scene: %s" % ProjectSettings.get_setting("application/run/main_scene", "missing"))
	sections.append("")
	sections.append("## Gate Summary")
	sections.append("")
	var gates := _gate_summary()
	for gate in gates:
		sections.append("- %s %s" % [_status_icon(String(gate["status"])), String(gate["text"])])
	sections.append("")
	sections.append("## Branding Assets")
	sections.append("")
	sections.append_array(_branding_lines())
	sections.append("")
	sections.append("## Store Screenshots")
	sections.append("")
	sections.append_array(_screenshot_lines())
	sections.append("")
	sections.append("## Store Visual Quality")
	sections.append("")
	sections.append_array(_store_visual_lines())
	sections.append("")
	sections.append("## Store Page Materials")
	sections.append("")
	sections.append_array(_store_material_lines())
	sections.append("")
	sections.append("## Legal And Credits")
	sections.append("")
	sections.append_array(_legal_lines())
	sections.append("")
	sections.append("## Accessibility And Comfort")
	sections.append("")
	sections.append_array(_accessibility_lines())
	sections.append("")
	sections.append("## Responsive Layout")
	sections.append("")
	sections.append_array(_responsive_layout_lines())
	sections.append("")
	sections.append("## First-Run Playtest Materials")
	sections.append("")
	sections.append_array(_playtest_material_lines())
	sections.append("")
	sections.append("## Export Presets")
	sections.append("")
	sections.append_array(_preset_lines())
	sections.append("")
	sections.append("## Audio Quality")
	sections.append("")
	sections.append_array(_audio_lines())
	sections.append("")
	sections.append("## Export Templates")
	sections.append("")
	sections.append_array(_template_lines())
	sections.append("")
	sections.append("## Expected Artifacts")
	sections.append("")
	for platform in REQUIRED_PRESETS.keys():
		sections.append("- %s: `%s`" % [platform, REQUIRED_PRESETS[platform]])
	sections.append("")
	sections.append("## Platform Follow-Up")
	sections.append("")
	sections.append("- Run `tools/export_release_smoke.sh` after installing Godot export templates.")
	sections.append("- Run `tools/audio_quality_check.gd` after regenerating or replacing any audio.")
	sections.append("- Run `tools/store_visual_quality_check.gd` after regenerating screenshots or branding art.")
	sections.append("- Run `tools/store_page_materials_check.gd` after changing screenshots, capsules, or store copy.")
	sections.append("- Run `tools/first_run_playtest_materials_check.gd` after changing first-run tutorial, rules, or menu flow.")
	sections.append("- Launch each exported build and rerun save/settings/user-data checks on Windows, macOS, and Linux.")
	sections.append("- macOS preset currently uses Godot codesign settings with no Developer ID identity and notarization disabled; final Steam release still needs signing/notarization policy confirmation.")
	sections.append("- Final storefront still needs human-selected screenshots, final capsule polish, and English Steam backend formatting.")
	sections.append("")
	return "\n".join(sections)


func _gate_summary() -> Array[Dictionary]:
	var gates: Array[Dictionary] = []
	gates.append({"status": _project_metadata_ok(), "text": "Project metadata and main scene are configured."})
	gates.append({"status": _all_branding_ok(), "text": "Required branding assets exist at expected sizes."})
	gates.append({"status": _all_screenshots_ok(), "text": "Five English live UI screenshots exist at 1600x1000."})
	gates.append({"status": _store_visual_report_ok(), "text": "Latest store visual quality report has no failed screenshots or branding assets."})
	gates.append({"status": _store_materials_report_ok(), "text": "Bilingual Steam store materials have no failed checks."})
	gates.append({"status": _legal_notes_ok(), "text": "Release-facing license notes and in-game credits/legal copy are present."})
	gates.append({"status": _accessibility_settings_ok(), "text": "Accessibility/comfort settings include persisted reduced-motion support."})
	gates.append({"status": _responsive_layout_report_ok(), "text": "Latest responsive layout smoke report has no failed checks."})
	gates.append({"status": _playtest_materials_report_ok(), "text": "First-run human observation protocol and template have no failed checks."})
	gates.append({"status": _audio_quality_report_ok(), "text": "Latest audio quality report has no failed assets."})
	gates.append({"status": _all_presets_ok(), "text": "Windows, macOS, and Linux export presets target expected artifact paths."})
	gates.append({"status": _all_templates_ok(), "text": "Export template availability for all required platforms."})
	gates.append({"status": _macos_release_policy_ok(), "text": "macOS signing/notarization final-release policy."})
	return gates


func _project_metadata_ok() -> String:
	if ProjectSettings.get_setting("application/config/name", "") != "Fate Coins":
		return "fail"
	if String(ProjectSettings.get_setting("application/config/version", "")).is_empty():
		return "fail"
	if ProjectSettings.get_setting("application/run/main_scene", "") != "res://scenes/main.tscn":
		return "fail"
	if ProjectSettings.get_setting("application/config/icon", "") != "res://textures/branding/app_icon.png":
		return "fail"
	return "pass"


func _all_branding_ok() -> String:
	for name in REQUIRED_BRANDING.keys():
		var spec: Dictionary = REQUIRED_BRANDING[name]
		if _image_status(String(spec["path"]), spec["size"]) != "pass":
			return "fail"
	return "pass"


func _all_screenshots_ok() -> String:
	for path in REQUIRED_SCREENSHOTS:
		if _image_status(path, SCREENSHOT_SIZE) != "pass":
			return "fail"
	return "pass"


func _store_materials_report_ok() -> String:
	if not FileAccess.file_exists(STORE_REPORT_PATH):
		return "blocked"
	var file := FileAccess.open(STORE_REPORT_PATH, FileAccess.READ)
	if file == null:
		return "blocked"
	var text := file.get_as_text()
	if text.find("[FAIL]") != -1:
		return "fail"
	return "pass" if text.count("[PASS]") >= 10 else "blocked"


func _store_visual_report_ok() -> String:
	if not FileAccess.file_exists(STORE_VISUAL_REPORT_PATH):
		return "blocked"
	var file := FileAccess.open(STORE_VISUAL_REPORT_PATH, FileAccess.READ)
	if file == null:
		return "blocked"
	var text := file.get_as_text()
	if text.find("[FAIL]") != -1:
		return "fail"
	return "pass" if text.count("[PASS]") >= 11 else "blocked"


func _legal_notes_ok() -> String:
	if not FileAccess.file_exists(LICENSES_PATH):
		return "fail"
	var file := FileAccess.open(LICENSES_PATH, FileAccess.READ)
	if file == null:
		return "fail"
	var text := file.get_as_text()
	for required in ["Godot Engine", "MIT License", "Project Code And Game Content", "Final Release Checklist"]:
		if text.find(required) == -1:
			return "fail"
	if not FileAccess.file_exists(MAIN_SCRIPT_PATH):
		return "fail"
	var script_file := FileAccess.open(MAIN_SCRIPT_PATH, FileAccess.READ)
	if script_file == null:
		return "fail"
	var script_text := script_file.get_as_text()
	for required in ["menu_credits_button", "credits_dialog", "credits_body", "Credits / Licenses"]:
		if script_text.find(required) == -1:
			return "fail"
	return "pass"


func _accessibility_settings_ok() -> String:
	if not FileAccess.file_exists(MAIN_SCRIPT_PATH):
		return "fail"
	var file := FileAccess.open(MAIN_SCRIPT_PATH, FileAccess.READ)
	if file == null:
		return "fail"
	var text := file.get_as_text()
	for required in [
		"reduced_motion_enabled",
		"reduced_motion_toggle",
		"_on_reduced_motion_toggled",
		"reduced_motion_enabled\": reduced_motion_enabled",
		"create_timer(0.95)"
	]:
		if text.find(required) == -1:
			return "fail"
	return "pass"


func _responsive_layout_report_ok() -> String:
	if not FileAccess.file_exists(RESPONSIVE_LAYOUT_REPORT_PATH):
		return "blocked"
	var file := FileAccess.open(RESPONSIVE_LAYOUT_REPORT_PATH, FileAccess.READ)
	if file == null:
		return "blocked"
	var text := file.get_as_text()
	if text.find("[FAIL]") != -1:
		return "fail"
	return "pass" if text.count("[PASS]") >= 6 else "blocked"


func _playtest_materials_report_ok() -> String:
	if not FileAccess.file_exists(PLAYTEST_REPORT_PATH):
		return "blocked"
	var file := FileAccess.open(PLAYTEST_REPORT_PATH, FileAccess.READ)
	if file == null:
		return "blocked"
	var text := file.get_as_text()
	if text.find("[FAIL]") != -1:
		return "fail"
	return "pass" if text.count("[PASS]") >= 2 else "blocked"


func _all_presets_ok() -> String:
	var config := _load_export_config()
	if config == null:
		return "fail"
	for platform in REQUIRED_PRESETS.keys():
		var section := _preset_section_for_platform(config, platform)
		if section == "":
			return "fail"
		if String(config.get_value(section, "export_path", "")) != String(REQUIRED_PRESETS[platform]):
			return "fail"
		if not bool(config.get_value(section, "runnable", false)):
			return "fail"
		if String(config.get_value(section, "export_filter", "")) != "all_resources":
			return "fail"
	return "pass"


func _audio_quality_report_ok() -> String:
	if not FileAccess.file_exists(AUDIO_REPORT_PATH):
		return "blocked"
	var file := FileAccess.open(AUDIO_REPORT_PATH, FileAccess.READ)
	if file == null:
		return "blocked"
	var text := file.get_as_text()
	if text.find("[FAIL]") != -1:
		return "fail"
	return "pass" if text.count("[PASS]") >= 15 else "blocked"


func _all_templates_ok() -> String:
	var template_dirs := _template_dirs(_template_version())
	for platform in TEMPLATE_FILES.keys():
		for filename in TEMPLATE_FILES[platform]:
			if not _template_exists(template_dirs, String(filename)):
				return "blocked"
	return "pass"


func _macos_release_policy_ok() -> String:
	var config := _load_export_config()
	if config == null:
		return "fail"
	var section := _preset_section_for_platform(config, "macOS")
	if section == "":
		return "fail"
	var options := "%s.options" % section
	var identity := String(config.get_value(options, "codesign/identity", ""))
	var notarization := int(config.get_value(options, "notarization/notarization", 0))
	if identity == "" or notarization == 0:
		return "blocked"
	return "pass"


func _branding_lines() -> Array[String]:
	var lines: Array[String] = []
	for name in REQUIRED_BRANDING.keys():
		var spec: Dictionary = REQUIRED_BRANDING[name]
		var path := String(spec["path"])
		lines.append("- %s %s: `%s` expected %s" % [
			_status_icon(_image_status(path, spec["size"])),
			name,
			path,
			_size_text(spec["size"])
		])
	return lines


func _screenshot_lines() -> Array[String]:
	var lines: Array[String] = []
	var manifest_status := "pass" if FileAccess.file_exists("res://screenshots/steam/README.md") else "fail"
	lines.append("- %s Screenshot manifest: `res://screenshots/steam/README.md`" % _status_icon(manifest_status))
	for path in REQUIRED_SCREENSHOTS:
		lines.append("- %s `%s` expected %s" % [
			_status_icon(_image_status(path, SCREENSHOT_SIZE)),
			path,
			_size_text(SCREENSHOT_SIZE)
		])
	return lines


func _store_material_lines() -> Array[String]:
	if not FileAccess.file_exists(STORE_REPORT_PATH):
		return ["- %s Latest report missing: `%s`" % [_status_icon("blocked"), STORE_REPORT_PATH]]
	var file := FileAccess.open(STORE_REPORT_PATH, FileAccess.READ)
	if file == null:
		return ["- %s Could not read `%s`" % [_status_icon("blocked"), STORE_REPORT_PATH]]
	var text := file.get_as_text()
	var status := "fail" if text.find("[FAIL]") != -1 else ("pass" if text.count("[PASS]") >= 10 else "blocked")
	return [
		"- %s Latest report: `%s`" % [_status_icon(status), STORE_REPORT_PATH],
		"- Passing store material checks in latest report: %d" % text.count("[PASS]")
	]


func _store_visual_lines() -> Array[String]:
	if not FileAccess.file_exists(STORE_VISUAL_REPORT_PATH):
		return ["- %s Latest report missing: `%s`" % [_status_icon("blocked"), STORE_VISUAL_REPORT_PATH]]
	var file := FileAccess.open(STORE_VISUAL_REPORT_PATH, FileAccess.READ)
	if file == null:
		return ["- %s Could not read `%s`" % [_status_icon("blocked"), STORE_VISUAL_REPORT_PATH]]
	var text := file.get_as_text()
	var status := "fail" if text.find("[FAIL]") != -1 else ("pass" if text.count("[PASS]") >= 11 else "blocked")
	return [
		"- %s Latest report: `%s`" % [_status_icon(status), STORE_VISUAL_REPORT_PATH],
		"- Passing visual asset checks in latest report: %d" % text.count("[PASS]")
	]


func _legal_lines() -> Array[String]:
	if not FileAccess.file_exists(LICENSES_PATH):
		return ["- %s License notes missing: `%s`" % [_status_icon("fail"), LICENSES_PATH]]
	var file := FileAccess.open(LICENSES_PATH, FileAccess.READ)
	if file == null:
		return ["- %s Could not read `%s`" % [_status_icon("fail"), LICENSES_PATH]]
	var text := file.get_as_text()
	var required := ["Godot Engine", "MIT License", "Project Code And Game Content", "Final Release Checklist"]
	var lines: Array[String] = []
	for phrase in required:
		var status := "pass" if text.find(phrase) != -1 else "fail"
		lines.append("- %s `%s` includes `%s`" % [_status_icon(status), LICENSES_PATH, phrase])
	if FileAccess.file_exists(MAIN_SCRIPT_PATH):
		var script_file := FileAccess.open(MAIN_SCRIPT_PATH, FileAccess.READ)
		var script_text := script_file.get_as_text() if script_file != null else ""
		for phrase in ["menu_credits_button", "credits_dialog", "credits_body", "Credits / Licenses"]:
			var status := "pass" if script_text.find(phrase) != -1 else "fail"
			lines.append("- %s `%s` includes `%s`" % [_status_icon(status), MAIN_SCRIPT_PATH, phrase])
	else:
		lines.append("- %s Main script missing: `%s`" % [_status_icon("fail"), MAIN_SCRIPT_PATH])
	return lines


func _accessibility_lines() -> Array[String]:
	if not FileAccess.file_exists(MAIN_SCRIPT_PATH):
		return ["- %s Main script missing: `%s`" % [_status_icon("fail"), MAIN_SCRIPT_PATH]]
	var file := FileAccess.open(MAIN_SCRIPT_PATH, FileAccess.READ)
	if file == null:
		return ["- %s Could not read `%s`" % [_status_icon("fail"), MAIN_SCRIPT_PATH]]
	var text := file.get_as_text()
	var required := {
		"Reduced motion state": "reduced_motion_enabled",
		"Settings toggle": "reduced_motion_toggle",
		"Toggle callback": "_on_reduced_motion_toggled",
		"Persisted settings field": "reduced_motion_enabled\": reduced_motion_enabled",
		"Reduced impact banner motion": "create_timer(0.95)"
	}
	var lines: Array[String] = []
	for name in required.keys():
		var phrase := String(required[name])
		var status := "pass" if text.find(phrase) != -1 else "fail"
		lines.append("- %s %s: `%s`" % [_status_icon(status), name, phrase])
	return lines


func _responsive_layout_lines() -> Array[String]:
	if not FileAccess.file_exists(RESPONSIVE_LAYOUT_REPORT_PATH):
		return ["- %s Latest report missing: `%s`" % [_status_icon("blocked"), RESPONSIVE_LAYOUT_REPORT_PATH]]
	var file := FileAccess.open(RESPONSIVE_LAYOUT_REPORT_PATH, FileAccess.READ)
	if file == null:
		return ["- %s Could not read `%s`" % [_status_icon("blocked"), RESPONSIVE_LAYOUT_REPORT_PATH]]
	var text := file.get_as_text()
	var status := "fail" if text.find("[FAIL]") != -1 else ("pass" if text.count("[PASS]") >= 6 else "blocked")
	return [
		"- %s Latest report: `%s`" % [_status_icon(status), RESPONSIVE_LAYOUT_REPORT_PATH],
		"- Passing responsive layout checks in latest report: %d" % text.count("[PASS]")
	]


func _playtest_material_lines() -> Array[String]:
	if not FileAccess.file_exists(PLAYTEST_REPORT_PATH):
		return ["- %s Latest report missing: `%s`" % [_status_icon("blocked"), PLAYTEST_REPORT_PATH]]
	var file := FileAccess.open(PLAYTEST_REPORT_PATH, FileAccess.READ)
	if file == null:
		return ["- %s Could not read `%s`" % [_status_icon("blocked"), PLAYTEST_REPORT_PATH]]
	var text := file.get_as_text()
	var status := "fail" if text.find("[FAIL]") != -1 else ("pass" if text.count("[PASS]") >= 2 else "blocked")
	return [
		"- %s Latest report: `%s`" % [_status_icon(status), PLAYTEST_REPORT_PATH],
		"- Passing first-run playtest material checks in latest report: %d" % text.count("[PASS]")
	]


func _preset_lines() -> Array[String]:
	var lines: Array[String] = []
	var config := _load_export_config()
	if config == null:
		return ["- %s `export_presets.cfg` missing or unparsable." % _status_icon("fail")]
	for platform in REQUIRED_PRESETS.keys():
		var section := _preset_section_for_platform(config, platform)
		if section == "":
			lines.append("- %s %s preset missing." % [_status_icon("fail"), platform])
			continue
		var export_path := String(config.get_value(section, "export_path", ""))
		var runnable := bool(config.get_value(section, "runnable", false))
		var export_filter := String(config.get_value(section, "export_filter", ""))
		var status := "pass" if export_path == REQUIRED_PRESETS[platform] and runnable and export_filter == "all_resources" else "fail"
		lines.append("- %s %s -> `%s` runnable=%s filter=%s" % [
			_status_icon(status),
			platform,
			export_path,
			str(runnable),
			export_filter
		])
		if platform == "macOS":
			var options := "%s.options" % section
			lines.append("  - macOS signing identity: `%s`; notarization: `%s`" % [
				String(config.get_value(options, "codesign/identity", "")),
				str(config.get_value(options, "notarization/notarization", 0))
			])
	return lines


func _audio_lines() -> Array[String]:
	if not FileAccess.file_exists(AUDIO_REPORT_PATH):
		return ["- %s Latest report missing: `%s`" % [_status_icon("blocked"), AUDIO_REPORT_PATH]]
	var file := FileAccess.open(AUDIO_REPORT_PATH, FileAccess.READ)
	if file == null:
		return ["- %s Could not read `%s`" % [_status_icon("blocked"), AUDIO_REPORT_PATH]]
	var text := file.get_as_text()
	var status := "fail" if text.find("[FAIL]") != -1 else ("pass" if text.count("[PASS]") >= 15 else "blocked")
	return [
		"- %s Latest report: `%s`" % [_status_icon(status), AUDIO_REPORT_PATH],
		"- Passing audio assets in latest report: %d" % text.count("[PASS]")
	]


func _template_lines() -> Array[String]:
	var lines: Array[String] = []
	var template_version := _template_version()
	var template_dirs := _template_dirs(template_version)
	lines.append("- Template version: `%s`" % template_version)
	lines.append("- Checked directories: `%s`" % "`, `".join(template_dirs))
	for platform in TEMPLATE_FILES.keys():
		for filename in TEMPLATE_FILES[platform]:
			var status := "pass" if _template_exists(template_dirs, String(filename)) else "blocked"
			lines.append("- %s %s requires `%s`" % [_status_icon(status), platform, String(filename)])
	return lines


func _image_status(path: String, expected_size: Vector2i) -> String:
	if not FileAccess.file_exists(path):
		return "fail"
	if not FileAccess.file_exists("%s.import" % path):
		return "fail"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "fail"
	var img := Image.new()
	if img.load_png_from_buffer(file.get_buffer(file.get_length())) != OK:
		return "fail"
	if Vector2i(img.get_width(), img.get_height()) != expected_size:
		return "fail"
	return "pass"


func _load_export_config() -> ConfigFile:
	if not FileAccess.file_exists("res://export_presets.cfg"):
		return null
	var config := ConfigFile.new()
	if config.load("res://export_presets.cfg") != OK:
		return null
	return config


func _preset_section_for_platform(config: ConfigFile, platform: String) -> String:
	for section in config.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			if String(config.get_value(section, "platform", "")) == platform:
				return section
	return ""


func _template_version() -> String:
	var version := Engine.get_version_info()
	return "%s.%s.%s.%s" % [
		str(version.get("major", 0)),
		str(version.get("minor", 0)),
		str(version.get("patch", 0)),
		str(version.get("status", "stable"))
	]


func _template_dirs(template_version: String) -> Array[String]:
	var dirs: Array[String] = []
	dirs.append(OS.get_data_dir().path_join("export_templates").path_join(template_version))
	var home := OS.get_environment("HOME")
	if home != "":
		dirs.append(home.path_join("Library/Application Support/Godot/export_templates").path_join(template_version))
	return dirs


func _template_exists(template_dirs: Array[String], filename: String) -> bool:
	for dir in template_dirs:
		if FileAccess.file_exists(dir.path_join(filename)):
			return true
	return false


func _status_icon(status: String) -> String:
	match status:
		"pass":
			return "[PASS]"
		"blocked":
			return "[BLOCKED]"
		_:
			return "[FAIL]"


func _size_text(size: Vector2i) -> String:
	return "%dx%d" % [size.x, size.y]
