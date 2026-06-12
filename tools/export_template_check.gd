extends SceneTree

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
	var version := Engine.get_version_info()
	var template_version := "%s.%s.%s.%s" % [
		str(version.get("major", 0)),
		str(version.get("minor", 0)),
		str(version.get("patch", 0)),
		str(version.get("status", "stable"))
	]
	var template_dirs := _template_dirs(template_version)
	var missing: Array[String] = []
	for platform in TEMPLATE_FILES.keys():
		for filename in TEMPLATE_FILES[platform]:
			if not _template_exists(template_dirs, String(filename)):
				missing.append("%s requires %s" % [platform, String(filename)])
	if missing.is_empty():
		print("Export templates available for %s" % template_version)
		quit(0)
		return
	push_error("Missing Godot export templates for %s. Install templates from Godot: Editor > Manage Export Templates, then rerun this check." % template_version)
	push_error("Checked template directories: %s" % ", ".join(template_dirs))
	for item in missing:
		push_error(item)
	quit(1)


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
