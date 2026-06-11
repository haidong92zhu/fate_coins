extends SceneTree

const MainScript = preload("res://scripts/main.gd")


func _init() -> void:
	var missing: Array[String] = []
	_check_tile_assets(missing)
	_check_assets("enemy", MainScript.ENEMY_TYPES.keys(), "res://textures/enemies", missing)
	_check_assets("relic", MainScript.RELICS.keys(), "res://textures/relics", missing)
	_check_assets("consumable", MainScript.CONSUMABLES.keys(), "res://textures/consumables", missing)
	_check_assets("curse", MainScript.CURSE_DEALS.keys(), "res://textures/curses", missing)
	_check_assets("event", _event_icon_types(), "res://textures/events", missing)
	if missing.is_empty():
		print("Asset coverage check passed")
		quit(0)
	else:
		for item in missing:
			push_error(item)
		quit(1)


func _check_assets(kind: String, ids: Array, directory: String, missing: Array[String]) -> void:
	for raw_id in ids:
		var id := String(raw_id)
		var path := "%s/%s.png" % [directory, id]
		var import_path := "%s.import" % path
		if not FileAccess.file_exists(path):
			missing.append("Missing %s icon: %s" % [kind, path])
		if not FileAccess.file_exists(import_path):
			missing.append("Missing %s import metadata: %s" % [kind, import_path])
		if not ResourceLoader.exists(path):
			missing.append("ResourceLoader cannot resolve %s icon: %s" % [kind, path])


func _check_tile_assets(missing: Array[String]) -> void:
	var tile_texture_ids := ["normal", "left", "right", "up", "down", "star", "bank", "cross", "surge"]
	for raw_id in MainScript.TILE_TYPES.keys():
		var id := String(raw_id)
		var texture_id := "debt" if id == "debt_coin" else id
		var path := "res://textures/tiles/tile_%s.png" % texture_id if tile_texture_ids.has(id) else "res://textures/coins/coin_%s.png" % texture_id
		var import_path := "%s.import" % path
		if not FileAccess.file_exists(path):
			missing.append("Missing tile icon: %s" % path)
		if not FileAccess.file_exists(import_path):
			missing.append("Missing tile import metadata: %s" % import_path)
		if not ResourceLoader.exists(path):
			missing.append("ResourceLoader cannot resolve tile icon: %s" % path)


func _event_icon_types() -> Array[String]:
	return ["coin", "chain", "reverse", "manual", "quota_down", "quota_up", "shop", "durability", "fragile", "defense", "danger", "neutral"]
