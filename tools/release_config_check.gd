extends SceneTree

const REQUIRED_BRANDING := {
	"app_icon": {"path": "res://textures/branding/app_icon.png", "size": Vector2i(1024, 1024)},
	"boot_splash": {"path": "res://textures/branding/boot_splash.png", "size": Vector2i(1600, 1000)},
	"steam_capsule": {"path": "res://textures/branding/steam_capsule_616x353.png", "size": Vector2i(616, 353)},
	"steam_header": {"path": "res://textures/branding/steam_header_920x430.png", "size": Vector2i(920, 430)},
	"steam_library": {"path": "res://textures/branding/steam_library_600x900.png", "size": Vector2i(600, 900)}
}
const REQUIRED_PRESETS := {
	"Windows Desktop": "build/windows/FateCoins.exe",
	"macOS": "build/macos/FateCoins.zip",
	"Linux/X11": "build/linux/FateCoins.x86_64"
}
const REQUIRED_SCREENSHOTS := [
	"res://screenshots/steam/01_main_menu.png",
	"res://screenshots/steam/02_preparation_board.png",
	"res://screenshots/steam/03_opening_layout.png",
	"res://screenshots/steam/04_combat_chain.png",
	"res://screenshots/steam/05_boss_pressure.png"
]
const SCREENSHOT_SIZE := Vector2i(1600, 1000)


func _init() -> void:
	var failures: Array[String] = []
	_check_project_settings(failures)
	_check_license_notes(failures)
	_check_branding_assets(failures)
	_check_store_screenshots(failures)
	_check_export_presets(failures)
	if failures.is_empty():
		print("Release config check passed")
		quit()
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check_project_settings(failures: Array[String]) -> void:
	_expect_setting("application/config/name", "Fate Coins", failures)
	_expect_setting("application/config/version", "0.1.0", failures)
	_expect_setting("application/config/icon", "res://textures/branding/app_icon.png", failures)
	_expect_setting("boot_splash/image", "res://textures/branding/boot_splash.png", failures)
	var description := String(ProjectSettings.get_setting("application/config/description", ""))
	if description.length() < 20:
		failures.append("Project description is missing or too short")


func _expect_setting(key: String, expected: Variant, failures: Array[String]) -> void:
	var actual: Variant = ProjectSettings.get_setting(key, null)
	if actual != expected:
		failures.append("Project setting %s expected %s but got %s" % [key, str(expected), str(actual)])


func _check_license_notes(failures: Array[String]) -> void:
	if not FileAccess.file_exists("res://LICENSES.md"):
		failures.append("Missing LICENSES.md")
		return
	var file := FileAccess.open("res://LICENSES.md", FileAccess.READ)
	if file == null:
		failures.append("Could not read LICENSES.md")
		return
	var text := file.get_as_text()
	for required in ["Godot Engine", "MIT License", "Project Code And Game Content", "Final Release Checklist"]:
		if text.find(required) == -1:
			failures.append("LICENSES.md is missing required section/text: %s" % required)


func _check_branding_assets(failures: Array[String]) -> void:
	for raw_name in REQUIRED_BRANDING.keys():
		var name := String(raw_name)
		var spec: Dictionary = REQUIRED_BRANDING[name]
		var path := String(spec["path"])
		var expected_size: Vector2i = spec["size"]
		if not FileAccess.file_exists(path):
			failures.append("Missing branding asset %s: %s" % [name, path])
			continue
		if not FileAccess.file_exists("%s.import" % path):
			failures.append("Missing branding import metadata %s.import" % path)
		if not ResourceLoader.exists(path):
			failures.append("ResourceLoader cannot resolve branding asset %s" % path)
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			failures.append("Could not open branding asset %s" % path)
			continue
		var img := Image.new()
		var load_error := img.load_png_from_buffer(file.get_buffer(file.get_length()))
		if load_error != OK:
			failures.append("Could not load branding asset %s" % path)
			continue
		var actual_size := Vector2i(img.get_width(), img.get_height())
		if actual_size != expected_size:
			failures.append("Branding asset %s expected %s but got %s" % [path, expected_size, actual_size])


func _check_export_presets(failures: Array[String]) -> void:
	if not FileAccess.file_exists("res://export_presets.cfg"):
		failures.append("Missing export_presets.cfg")
		return
	var config := ConfigFile.new()
	var error := config.load("res://export_presets.cfg")
	if error != OK:
		failures.append("Could not parse export_presets.cfg: %s" % error_string(error))
		return
	var found := {}
	for section in config.get_sections():
		if not section.begins_with("preset.") or section.ends_with(".options"):
			continue
		var platform := String(config.get_value(section, "platform", ""))
		var export_path := String(config.get_value(section, "export_path", ""))
		var runnable := bool(config.get_value(section, "runnable", false))
		var export_filter := String(config.get_value(section, "export_filter", ""))
		if platform == "":
			failures.append("%s is missing platform" % section)
			continue
		found[platform] = true
		if REQUIRED_PRESETS.has(platform) and export_path != String(REQUIRED_PRESETS[platform]):
			failures.append("%s export path expected %s but got %s" % [platform, REQUIRED_PRESETS[platform], export_path])
		if not runnable:
			failures.append("%s preset is not runnable" % platform)
		if export_filter != "all_resources":
			failures.append("%s preset should export all resources" % platform)
		var options_section := "%s.options" % section
		if not config.has_section(options_section):
			failures.append("%s is missing options section" % platform)
	for platform in REQUIRED_PRESETS.keys():
		if not found.has(platform):
			failures.append("Missing export preset for %s" % platform)


func _check_store_screenshots(failures: Array[String]) -> void:
	var manifest_path := "res://screenshots/steam/README.md"
	if not FileAccess.file_exists(manifest_path):
		failures.append("Missing Steam screenshot manifest: %s" % manifest_path)
	else:
		var manifest := FileAccess.open(manifest_path, FileAccess.READ)
		var manifest_text := manifest.get_as_text() if manifest != null else ""
		for required_text in ["Productized main menu", "Plan your fate machine", "Build chain routes", "Click, chain, and fight", "Survive boss disruption"]:
			if manifest_text.find(required_text) == -1:
				failures.append("Steam screenshot manifest is missing caption: %s" % required_text)
	for path in REQUIRED_SCREENSHOTS:
		if not FileAccess.file_exists(path):
			failures.append("Missing store screenshot: %s" % path)
			continue
		var img := _load_png(path, failures)
		if img == null:
			continue
		var actual_size := Vector2i(img.get_width(), img.get_height())
		if actual_size != SCREENSHOT_SIZE:
			failures.append("Store screenshot %s expected %s but got %s" % [path, SCREENSHOT_SIZE, actual_size])
		if _sample_unique_colors(img) < 12:
			failures.append("Store screenshot appears blank or too flat: %s" % path)


func _load_png(path: String, failures: Array[String]) -> Image:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Could not open PNG %s" % path)
		return null
	var img := Image.new()
	var load_error := img.load_png_from_buffer(file.get_buffer(file.get_length()))
	if load_error != OK:
		failures.append("Could not load PNG %s" % path)
		return null
	return img


func _sample_unique_colors(img: Image) -> int:
	var unique := {}
	var step_x: int = max(1, img.get_width() / 24)
	var step_y: int = max(1, img.get_height() / 16)
	for y in range(0, img.get_height(), step_y):
		for x in range(0, img.get_width(), step_x):
			var color := img.get_pixel(x, y)
			var key := "%d:%d:%d" % [int(color.r * 31.0), int(color.g * 31.0), int(color.b * 31.0)]
			unique[key] = true
	return unique.size()
