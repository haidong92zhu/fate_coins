extends SceneTree

const REPORT_PATH := "res://build/store_page_materials_report.md"
const DRAFTS := {
	"zh_CN": "res://STEAM_STORE_DRAFT_CN.md",
	"en_US": "res://STEAM_STORE_DRAFT_EN.md"
}
const SCREENSHOTS := [
	"res://screenshots/steam/01_main_menu.png",
	"res://screenshots/steam/02_preparation_board.png",
	"res://screenshots/steam/03_opening_layout.png",
	"res://screenshots/steam/04_combat_chain.png",
	"res://screenshots/steam/05_boss_pressure.png"
]
const BRANDING := [
	"res://textures/branding/steam_capsule_616x353.png",
	"res://textures/branding/steam_header_920x430.png",
	"res://textures/branding/steam_library_600x900.png"
]
const REQUIRED_CN_SECTIONS := ["## 简短描述", "## 一句话卖点", "## 长描述", "## 核心特色", "## 当前截图素材", "## 当前商店图素材", "## 系统需求草案", "## 上架前仍需确认"]
const REQUIRED_EN_SECTIONS := ["## Short Description", "## One-Line Pitch", "## Long Description", "## Key Features", "## Screenshot Candidates", "## Current Store Art", "## Suggested Tags", "## Content Notes", "## Draft System Requirements", "## Pre-Release Follow-Up"]
const REQUIRED_EN_TERMS := ["single-player roguelite", "4x5", "wager", "24-round", "real-money gambling", "Windows", "macOS", "Linux"]


func _init() -> void:
	var failures: Array[String] = []
	var report_lines := _build_report(failures)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var report := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if report == null:
		push_error("Could not write store materials report")
		quit(1)
		return
	report.store_string("\n".join(report_lines))
	if failures.is_empty():
		print("Store page materials check passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _build_report(failures: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	lines.append("# Fate Coins Store Page Materials Report")
	lines.append("")
	lines.append("- Generated: %s" % Time.get_datetime_string_from_system(false, true))
	lines.append("- Checks: bilingual store drafts, required sections, short-description length, screenshot references, branding references, platform requirements, and content notes.")
	lines.append("")
	lines.append("## Drafts")
	lines.append("")
	lines.append_array(_draft_lines(failures))
	lines.append("")
	lines.append("## Screenshots")
	lines.append("")
	lines.append_array(_screenshot_lines(failures))
	lines.append("")
	lines.append("## Branding")
	lines.append("")
	lines.append_array(_branding_lines(failures))
	lines.append("")
	return lines


func _draft_lines(failures: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	for locale in DRAFTS.keys():
		var path := String(DRAFTS[locale])
		var text := _read_text(path)
		var errors: Array[String] = []
		if text == "":
			errors.append("missing or empty")
		var required_sections := REQUIRED_CN_SECTIONS if locale == "zh_CN" else REQUIRED_EN_SECTIONS
		for section in required_sections:
			if text.find(section) == -1:
				errors.append("missing section %s" % section)
		if locale == "en_US":
			for term in REQUIRED_EN_TERMS:
				if text.find(term) == -1:
					errors.append("missing required term %s" % term)
			var short_description := _section_body(text, "## Short Description", "## One-Line Pitch")
			if short_description.length() < 80 or short_description.length() > 300:
				errors.append("short description length %d outside 80-300" % short_description.length())
		else:
			var short_description_cn := _section_body(text, "## 简短描述", "## 一句话卖点")
			if short_description_cn.length() < 30 or short_description_cn.length() > 180:
				errors.append("简短描述长度 %d 不在 30-180" % short_description_cn.length())
		for shot in SCREENSHOTS:
			if text.find(shot.trim_prefix("res://")) == -1:
				errors.append("missing screenshot reference %s" % shot)
		for art in BRANDING:
			if text.find(art.trim_prefix("res://")) == -1:
				errors.append("missing branding reference %s" % art)
		var status := "pass" if errors.is_empty() else "fail"
		lines.append("- %s `%s`: %d chars" % [_status_icon(status), path, text.length()])
		for error in errors:
			failures.append("%s %s: %s" % [locale, path, error])
			lines.append("  - %s" % error)
	return lines


func _screenshot_lines(failures: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	var manifest := _read_text("res://screenshots/steam/README.md")
	for shot in SCREENSHOTS:
		var exists := FileAccess.file_exists(shot)
		var mentioned := manifest.find(shot.get_file()) != -1
		var status := "pass" if exists and mentioned else "fail"
		lines.append("- %s `%s` manifest=%s" % [_status_icon(status), shot, str(mentioned)])
		if not exists:
			failures.append("Missing screenshot %s" % shot)
		if not mentioned:
			failures.append("Screenshot manifest missing %s" % shot.get_file())
	return lines


func _branding_lines(failures: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	for art in BRANDING:
		var exists := FileAccess.file_exists(art)
		var status := "pass" if exists else "fail"
		lines.append("- %s `%s`" % [_status_icon(status), art])
		if not exists:
			failures.append("Missing branding asset %s" % art)
	return lines


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _section_body(text: String, start_marker: String, end_marker: String) -> String:
	var start := text.find(start_marker)
	if start == -1:
		return ""
	start += start_marker.length()
	var end := text.find(end_marker, start)
	if end == -1:
		end = text.length()
	return text.substr(start, end - start).strip_edges()


func _status_icon(status: String) -> String:
	return "[PASS]" if status == "pass" else "[FAIL]"
