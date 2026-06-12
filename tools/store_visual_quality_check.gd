extends SceneTree

const REPORT_PATH := "res://build/store_visual_quality_report.md"
const SCREENSHOT_SIZE := Vector2i(1600, 1000)

const SCREENSHOTS := [
	{"name": "Main menu", "path": "res://screenshots/steam/01_main_menu.png"},
	{"name": "Preparation board", "path": "res://screenshots/steam/02_preparation_board.png"},
	{"name": "Opening layout", "path": "res://screenshots/steam/03_opening_layout.png"},
	{"name": "Combat chain", "path": "res://screenshots/steam/04_combat_chain.png"},
	{"name": "Boss pressure", "path": "res://screenshots/steam/05_boss_pressure.png"}
]

const BRANDING := [
	{"name": "App icon", "path": "res://textures/branding/app_icon.png", "size": Vector2i(1024, 1024)},
	{"name": "Boot splash", "path": "res://textures/branding/boot_splash.png", "size": Vector2i(1600, 1000)},
	{"name": "Steam capsule", "path": "res://textures/branding/steam_capsule_616x353.png", "size": Vector2i(616, 353)},
	{"name": "Steam header", "path": "res://textures/branding/steam_header_920x430.png", "size": Vector2i(920, 430)},
	{"name": "Steam library", "path": "res://textures/branding/steam_library_600x900.png", "size": Vector2i(600, 900)}
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var lines: Array[String] = []
	var failures: Array[String] = []
	lines.append("# Fate Coins Store Visual Quality Report")
	lines.append("")
	lines.append("- Generated: %s" % Time.get_datetime_string_from_system(false, true))
	lines.append("- Checks: size, import metadata, ResourceLoader availability, sampled color variety, luminance range, dark/bright coverage.")
	lines.append("")
	lines.append("## Screenshots")
	lines.append("")
	for raw_spec in SCREENSHOTS:
		var spec: Dictionary = raw_spec
		lines.append(_visual_line(String(spec["name"]), String(spec["path"]), SCREENSHOT_SIZE, _screenshot_thresholds(), failures))
	lines.append("")
	lines.append("## Branding")
	lines.append("")
	for raw_spec in BRANDING:
		var spec: Dictionary = raw_spec
		lines.append(_visual_line(String(spec["name"]), String(spec["path"]), spec["size"], _branding_thresholds(), failures))
	lines.append("")
	if failures.is_empty():
		lines.append("## Result")
		lines.append("")
		lines.append("- [PASS] Store visual assets passed automated quality gates.")
	else:
		lines.append("## Failures")
		lines.append("")
		for failure in failures:
			lines.append("- [FAIL] %s" % failure)
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write store visual quality report")
		quit(1)
		return
	file.store_string("\n".join(lines))
	if failures.is_empty():
		print("Store visual quality check passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _screenshot_thresholds() -> Dictionary:
	return {
		"min_unique": 80,
		"min_luma_range": 0.22,
		"min_dark_ratio": 0.08,
		"min_bright_ratio": 0.008
	}


func _branding_thresholds() -> Dictionary:
	return {
		"min_unique": 38,
		"min_luma_range": 0.20,
		"min_dark_ratio": 0.10,
		"min_bright_ratio": 0.006
	}


func _visual_line(name: String, path: String, expected_size: Vector2i, thresholds: Dictionary, failures: Array[String]) -> String:
	if not FileAccess.file_exists(path):
		failures.append("%s missing: %s" % [name, path])
		return "- [FAIL] %s: `%s` missing" % [name, path]
	if not FileAccess.file_exists("%s.import" % path):
		failures.append("%s missing import metadata: %s.import" % [name, path])
	if not ResourceLoader.exists(path):
		failures.append("%s cannot be resolved by ResourceLoader: %s" % [name, path])
	var img := _load_png(path, failures)
	if img == null:
		return "- [FAIL] %s: `%s` could not be loaded" % [name, path]
	var actual_size := Vector2i(img.get_width(), img.get_height())
	var metrics := _sample_metrics(img)
	var asset_failures: Array[String] = []
	if actual_size != expected_size:
		asset_failures.append("size %s expected %s" % [actual_size, expected_size])
	if int(metrics["unique_colors"]) < int(thresholds["min_unique"]):
		asset_failures.append("sampled colors %d below %d" % [metrics["unique_colors"], thresholds["min_unique"]])
	if float(metrics["luma_range"]) < float(thresholds["min_luma_range"]):
		asset_failures.append("luminance range %.3f below %.3f" % [metrics["luma_range"], thresholds["min_luma_range"]])
	if float(metrics["dark_ratio"]) < float(thresholds["min_dark_ratio"]):
		asset_failures.append("dark coverage %.1f%% below %.1f%%" % [float(metrics["dark_ratio"]) * 100.0, float(thresholds["min_dark_ratio"]) * 100.0])
	if float(metrics["bright_ratio"]) < float(thresholds["min_bright_ratio"]):
		asset_failures.append("bright accent coverage %.1f%% below %.1f%%" % [float(metrics["bright_ratio"]) * 100.0, float(thresholds["min_bright_ratio"]) * 100.0])
	for failure in asset_failures:
		failures.append("%s: %s" % [name, failure])
	var status := "PASS" if asset_failures.is_empty() else "FAIL"
	return "- [%s] %s: `%s` %dx%d, colors=%d, luma=%.3f..%.3f, dark=%.1f%%, bright=%.1f%%" % [
		status,
		name,
		path,
		actual_size.x,
		actual_size.y,
		int(metrics["unique_colors"]),
		float(metrics["min_luma"]),
		float(metrics["max_luma"]),
		float(metrics["dark_ratio"]) * 100.0,
		float(metrics["bright_ratio"]) * 100.0
	]


func _load_png(path: String, failures: Array[String]) -> Image:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Could not open PNG %s" % path)
		return null
	var img := Image.new()
	var error := img.load_png_from_buffer(file.get_buffer(file.get_length()))
	if error != OK:
		failures.append("Could not load PNG %s: %s" % [path, error_string(error)])
		return null
	return img


func _sample_metrics(img: Image) -> Dictionary:
	var unique := {}
	var min_luma := 1.0
	var max_luma := 0.0
	var dark_count := 0
	var bright_count := 0
	var sample_count := 0
	var step_x: int = max(1, img.get_width() / 96)
	var step_y: int = max(1, img.get_height() / 60)
	for y in range(0, img.get_height(), step_y):
		for x in range(0, img.get_width(), step_x):
			var color := img.get_pixel(x, y)
			var luma := _luma(color)
			min_luma = min(min_luma, luma)
			max_luma = max(max_luma, luma)
			if luma < 0.10:
				dark_count += 1
			if luma > 0.55:
				bright_count += 1
			var key := "%d:%d:%d" % [
				int(clamp(color.r, 0.0, 1.0) * 63.0),
				int(clamp(color.g, 0.0, 1.0) * 63.0),
				int(clamp(color.b, 0.0, 1.0) * 63.0)
			]
			unique[key] = true
			sample_count += 1
	return {
		"unique_colors": unique.size(),
		"min_luma": min_luma,
		"max_luma": max_luma,
		"luma_range": max_luma - min_luma,
		"dark_ratio": float(dark_count) / max(1.0, float(sample_count)),
		"bright_ratio": float(bright_count) / max(1.0, float(sample_count))
	}


func _luma(color: Color) -> float:
	return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
