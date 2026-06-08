extends Control

class SlotView:
	extends PanelContainer

	var main: Control
	var slot_index := -1

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if main == null or not main.can_start_slot_drag(slot_index):
			return null

		var tile_type: String = main.tile_type_at(slot_index)
		var preview: Control = main.make_drag_preview(tile_type)
		set_drag_preview(preview)
		return {
			"kind": "placed",
			"type": tile_type,
			"from_slot": slot_index
		}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return main != null and main.can_drop_on_slot(slot_index, data)

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if main != null:
			main.drop_on_slot(slot_index, data)


class TileView:
	extends PanelContainer

	var main: Control
	var tile_type := ""
	var slot_index := -1
	var from_palette := false

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if main == null or not main.can_start_tile_drag(from_palette):
			return null

		var preview: Control = main.make_drag_preview(tile_type)
		set_drag_preview(preview)

		return {
			"kind": "palette" if from_palette else "placed",
			"type": tile_type,
			"from_slot": slot_index
		}


class DeleteDrop:
	extends PanelContainer

	var main: Control

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return main != null and main.can_drop_on_delete(data)

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if main != null:
			main.drop_on_delete(data)


const GameStateScript = preload("res://scripts/game_state.gd")

const GRID_COLUMNS := 4
const GRID_ROWS := 5
const TOTAL_SLOTS := GRID_COLUMNS * GRID_ROWS
const MAX_TILE_CLICKS := 4
const MAX_MANUAL_CLICKS := 8
const STARTING_COINS := 18
const STARTING_QUOTA := 1
const FLASH_SECONDS := 1.0
const TRIGGER_CHANCE := 0.5

const TILE_TEXTURES := {
	"normal": preload("res://textures/tiles/tile_normal.png"),
	"left": preload("res://textures/tiles/tile_left.png"),
	"right": preload("res://textures/tiles/tile_right.png"),
	"up": preload("res://textures/tiles/tile_up.png"),
	"down": preload("res://textures/tiles/tile_down.png"),
	"star": preload("res://textures/tiles/tile_star.png"),
	"bank": preload("res://textures/tiles/tile_normal.png"),
	"cross": preload("res://textures/tiles/tile_star.png"),
	"surge": preload("res://textures/tiles/tile_right.png")
}

const SFX_PATHS := {
	"coin": "res://audio/coin.wav",
	"miss": "res://audio/miss.wav",
	"buy": "res://audio/buy.wav",
	"upgrade": "res://audio/upgrade.wav",
	"chain": "res://audio/chain.wav",
	"settle": "res://audio/settle.wav",
	"error": "res://audio/error.wav"
}

const TILE_TYPES := {
	"normal": {"name": "Normal", "symbol": "N", "cost": 1, "directions": [], "rarity": "common", "coin_value": 1, "trigger_chance": 0.50, "tip": "点击后只结算自己，不触发周围方块。花费 1 金币。"},
	"left": {"name": "Left", "symbol": "<", "cost": 3, "directions": [Vector2i.LEFT], "rarity": "common", "coin_value": 1, "trigger_chance": 0.50, "tip": "点击后有 50% 概率触发左侧方块。花费 3 金币。"},
	"right": {"name": "Right", "symbol": ">", "cost": 3, "directions": [Vector2i.RIGHT], "rarity": "common", "coin_value": 1, "trigger_chance": 0.50, "tip": "点击后有 50% 概率触发右侧方块。花费 3 金币。"},
	"up": {"name": "Up", "symbol": "^", "cost": 3, "directions": [Vector2i.UP], "rarity": "common", "coin_value": 1, "trigger_chance": 0.50, "tip": "点击后有 50% 概率触发上方方块。花费 3 金币。"},
	"down": {"name": "Down", "symbol": "v", "cost": 3, "directions": [Vector2i.DOWN], "rarity": "common", "coin_value": 1, "trigger_chance": 0.50, "tip": "点击后有 50% 概率触发下方方块。花费 3 金币。"},
	"star": {"name": "Star", "symbol": "*", "cost": 6, "directions": [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN], "rarity": "uncommon", "coin_value": 1, "trigger_chance": 0.50, "tip": "点击后四个方向各自有 50% 概率触发。花费 6 金币。"},
	"bank": {"name": "Bank", "symbol": "$", "cost": 5, "directions": [], "rarity": "rare", "coin_value": 2, "trigger_chance": 0.50, "tip": "稀有方块。点击成功获得 2 金币，不触发周围。"},
	"cross": {"name": "Cross", "symbol": "+", "cost": 7, "directions": [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN], "rarity": "rare", "coin_value": 1, "trigger_chance": 0.62, "tip": "稀有方块。四个方向各自有 62% 概率触发。"},
	"surge": {"name": "Surge", "symbol": "!", "cost": 8, "directions": [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN], "rarity": "rare", "coin_value": 2, "trigger_chance": 0.42, "tip": "稀有方块。成功给 2 金币，并有较低概率触发四周。"}
}

const TILE_ORDER := ["normal", "left", "right", "up", "down", "star", "bank", "cross", "surge"]
const COMMON_SHOP_TYPES := ["normal", "left", "right", "up", "down", "star"]
const RARE_SHOP_TYPES := ["bank", "cross", "surge"]
const MAX_TILE_LEVEL := 3
const BG_COLOR := Color(0.035, 0.045, 0.055)
const PANEL_COLOR := Color(0.105, 0.115, 0.12, 0.98)
const PANEL_LIGHT := Color(0.18, 0.20, 0.20)
const SLOT_COLOR := Color(0.09, 0.19, 0.18)
const GOLD := Color(1.0, 0.72, 0.24)
const CREAM := Color(0.94, 0.91, 0.80)
const GREEN := Color(0.26, 0.78, 0.45)
const COIN_FLASH := Color(0.95, 0.32, 0.24)
const BLUE := Color(0.32, 0.62, 1.0)

var game_state: Node
var rng := RandomNumberGenerator.new()
var is_intermission := true
var manual_clicks_left := MAX_MANUAL_CLICKS
var round_collected := 0
var quota := STARTING_QUOTA
var current_event: Dictionary = {}
var shop_offer_types: Array[String] = []
var best_chain_this_round := 0
var last_round_summary: Dictionary = {}
var board_tiles: Array[Dictionary] = []
var slot_views: Array[Dictionary] = []
var palette_views: Dictionary = {}
var palette_container: GridContainer
var sfx_players: Dictionary = {}

var coin_label: Label
var round_label: Label
var quota_label: Label
var clicks_label: Label
var state_label: Label
var notice_label: Label
var progress_label: Label
var action_button: Button
var delete_zone: DeleteDrop
var game_over_dialog: AcceptDialog
var settlement_dialog: AcceptDialog


func _ready() -> void:
	rng.randomize()
	_create_game_state()
	_roll_shop_offers()
	_pick_round_event()
	manual_clicks_left = _round_manual_click_max()
	_build_interface()
	_update_ui("准备阶段：查看本回合事件，从右侧购买方块；把同类方块拖到已有方块上可升级。")


func _create_game_state() -> void:
	game_state = GameStateScript.new()
	game_state.name = "GameState"
	add_child(game_state)
	game_state.coins = STARTING_COINS
	game_state.current_round = 1
	game_state.required_coins = STARTING_QUOTA


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BG_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 14)
	root.add_theme_constant_override("margin_top", 10)
	root.add_theme_constant_override("margin_right", 14)
	root.add_theme_constant_override("margin_bottom", 10)
	add_child(root)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	root.add_child(page)
	page.add_child(_build_header())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	page.add_child(body)
	body.add_child(_build_board_panel())
	body.add_child(_build_side_panel())

	_build_game_over_dialog()
	_build_settlement_dialog()
	_build_audio_players()


func _build_header() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 96)
	panel.add_theme_stylebox_override("panel", style(Color(0.12, 0.10, 0.08), 8, GOLD.darkened(0.15), 2))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(title_box)

	var title := Label.new()
	title.text = "Fate Coins: Coin Cascade"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", GOLD)
	title_box.add_child(title)

	notice_label = Label.new()
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_label.add_theme_font_size_override("font_size", 18)
	notice_label.add_theme_color_override("font_color", CREAM)
	title_box.add_child(notice_label)

	coin_label = _make_stat_label()
	round_label = _make_stat_label()
	quota_label = _make_stat_label()
	clicks_label = _make_stat_label()
	state_label = _make_stat_label()
	row.add_child(coin_label)
	row.add_child(round_label)
	row.add_child(quota_label)
	row.add_child(clicks_label)
	row.add_child(state_label)

	return panel


func _build_board_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", style(Color(0.07, 0.20, 0.18), 8, Color(0.95, 0.62, 0.18), 2))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var status := PanelContainer.new()
	status.custom_minimum_size = Vector2(0, 72)
	status.add_theme_stylebox_override("panel", style(Color(0.13, 0.14, 0.12), 8, GOLD.darkened(0.25), 2))
	column.add_child(status)

	progress_label = Label.new()
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 24)
	progress_label.add_theme_color_override("font_color", CREAM)
	status.add_child(progress_label)

	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)

	for index in range(TOTAL_SLOTS):
		board_tiles.append({})
		grid.add_child(_build_slot(index))

	return panel


func _build_side_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	panel.add_theme_stylebox_override("panel", style(Color(0.10, 0.105, 0.11), 8, GOLD.darkened(0.30), 2))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title := Label.new()
	title.text = "方块栏"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", GOLD)
	column.add_child(title)

	palette_container = GridContainer.new()
	palette_container.columns = 2
	palette_container.add_theme_constant_override("h_separation", 6)
	palette_container.add_theme_constant_override("v_separation", 6)
	column.add_child(palette_container)
	_rebuild_shop_palette()

	delete_zone = DeleteDrop.new()
	delete_zone.main = self
	delete_zone.custom_minimum_size = Vector2(0, 90)
	delete_zone.add_theme_stylebox_override("panel", style(Color(0.22, 0.12, 0.10), 8, Color(0.95, 0.30, 0.24), 2))
	column.add_child(delete_zone)

	var delete_label := Label.new()
	delete_label.text = "删除区\n拖入已放置方块返还金币"
	delete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delete_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	delete_label.add_theme_font_size_override("font_size", 18)
	delete_label.add_theme_color_override("font_color", CREAM)
	delete_zone.add_child(delete_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	action_button = _make_action_button("开始下一回合", BLUE)
	action_button.pressed.connect(_on_action_button_pressed)
	column.add_child(action_button)

	return panel


func _build_slot(index: int) -> Control:
	var slot := SlotView.new()
	slot.main = self
	slot.slot_index = index
	slot.custom_minimum_size = Vector2(210, 120)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot.add_theme_stylebox_override("panel", style(SLOT_COLOR, 8, Color(0.34, 0.55, 0.46), 2))

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 5)
	slot.add_child(stack)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(112, 70)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stack.add_child(icon)

	var history := HBoxContainer.new()
	history.custom_minimum_size = Vector2(0, 18)
	history.alignment = BoxContainer.ALIGNMENT_CENTER
	history.add_theme_constant_override("separation", 2)
	stack.add_child(history)

	var info := Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 17)
	info.add_theme_color_override("font_color", Color(0.82, 0.88, 0.80))
	stack.add_child(info)

	var button := Button.new()
	button.flat = true
	button.text = ""
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_slot_pressed.bind(index))
	slot.add_child(button)

	slot_views.append({
		"slot": slot,
		"icon": icon,
		"history": history,
		"info": info,
		"button": button,
		"tile_view": null
	})
	_refresh_slot(index)
	return slot


func _build_palette_tile(tile_type: String) -> Control:
	var config: Dictionary = TILE_TYPES[tile_type]
	var tile := TileView.new()
	tile.main = self
	tile.tile_type = tile_type
	tile.from_palette = true
	tile.custom_minimum_size = Vector2(170, 110)
	tile.tooltip_text = config["tip"]
	tile.add_theme_stylebox_override("panel", style(PANEL_LIGHT, 8, _rarity_color(String(config["rarity"])), 2))

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	tile.add_child(stack)

	var icon := TextureRect.new()
	icon.texture = TILE_TEXTURES[tile_type]
	icon.custom_minimum_size = Vector2(108, 54)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stack.add_child(icon)

	var label := Label.new()
	label.text = "%s  %s\n%s  花费 %d" % [config["symbol"], config["name"], String(config["rarity"]).to_upper(), config["cost"]]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", CREAM)
	stack.add_child(label)

	return tile


func _roll_shop_offers() -> void:
	shop_offer_types.clear()
	var common_pool := COMMON_SHOP_TYPES.duplicate()
	common_pool.shuffle()
	for index in range(5):
		shop_offer_types.append(common_pool[index % common_pool.size()])
	if rng.randf() < 0.72:
		shop_offer_types.append(RARE_SHOP_TYPES[rng.randi_range(0, RARE_SHOP_TYPES.size() - 1)])
	else:
		shop_offer_types.append(common_pool[5 % common_pool.size()])


func _rebuild_shop_palette() -> void:
	if palette_container == null:
		return
	for child in palette_container.get_children():
		child.queue_free()
	palette_views.clear()
	for tile_type in shop_offer_types:
		var tile := _build_palette_tile(tile_type)
		palette_views[tile_type] = tile
		palette_container.add_child(tile)


func _pick_round_event() -> void:
	var events: Array[Dictionary] = [
		{"name": "黄金潮汐", "desc": "本回合所有成功点击额外 +1 金币。", "coin_bonus": 1, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0},
		{"name": "连锁顺风", "desc": "所有方向触发概率 +15%。", "coin_bonus": 0, "trigger_bonus": 0.15, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0},
		{"name": "长线布局", "desc": "本回合手动点击次数 +2。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 2, "quota_discount": 0, "click_bonus": 0},
		{"name": "税务宽免", "desc": "结束回合时少收 2 金币，最低收 0。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 2, "click_bonus": 0},
		{"name": "耐久强化", "desc": "每个方块本回合最大触发次数 +1。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 1}
	]
	current_event = events[rng.randi_range(0, events.size() - 1)]


func _round_manual_click_max() -> int:
	return MAX_MANUAL_CLICKS + int(current_event.get("manual_bonus", 0))


func _round_tile_click_max(tile: Dictionary) -> int:
	return MAX_TILE_CLICKS + int(tile.get("level", 1)) - 1 + int(current_event.get("click_bonus", 0))


func _round_quota_due() -> int:
	return max(0, quota - int(current_event.get("quota_discount", 0)))


func _tile_trigger_chance(tile_type: String, level: int) -> float:
	var config: Dictionary = TILE_TYPES[tile_type]
	return clampf(float(config["trigger_chance"]) + float(current_event.get("trigger_bonus", 0.0)) + float(level - 1) * 0.08, 0.05, 0.95)


func _tile_coin_value(tile_type: String, level: int) -> int:
	var config: Dictionary = TILE_TYPES[tile_type]
	return int(config["coin_value"]) + int(current_event.get("coin_bonus", 0)) + level - 1


func _make_stat_label() -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(126, 54)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_stylebox_override("normal", style(PANEL_LIGHT, 6, Color(0.36, 0.37, 0.34), 1))
	return label


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"rare":
			return Color(0.70, 0.48, 1.0)
		"uncommon":
			return Color(0.38, 0.78, 1.0)
		_:
			return Color(0.92, 0.72, 0.34)


func _make_action_button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 64)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.06, 0.07, 0.07))
	button.add_theme_stylebox_override("normal", style(color, 8, Color(1, 1, 1, 0.2), 1))
	button.add_theme_stylebox_override("hover", style(color.lightened(0.08), 8, Color(1, 1, 1, 0.45), 1))
	button.add_theme_stylebox_override("pressed", style(color.darkened(0.12), 8, Color(0, 0, 0, 0.25), 1))
	return button


func _build_game_over_dialog() -> void:
	game_over_dialog = AcceptDialog.new()
	game_over_dialog.title = "游戏结束"
	game_over_dialog.dialog_text = "金币不足以支付本轮收取。"
	game_over_dialog.ok_button_text = "重新开始"
	game_over_dialog.confirmed.connect(_restart_game)
	add_child(game_over_dialog)


func _build_settlement_dialog() -> void:
	settlement_dialog = AcceptDialog.new()
	settlement_dialog.title = "回合结算"
	settlement_dialog.ok_button_text = "继续布阵"
	add_child(settlement_dialog)


func _build_audio_players() -> void:
	for key in SFX_PATHS:
		var player := AudioStreamPlayer.new()
		player.stream = _load_wav_stream(SFX_PATHS[key])
		player.volume_db = -8.0
		add_child(player)
		sfx_players[key] = player


func _load_wav_stream(path: String) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return stream
	var bytes := file.get_buffer(file.get_length())
	if bytes.size() <= 44:
		return stream
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	stream.data = bytes.slice(44)
	return stream


func _play_sfx(key: String) -> void:
	if not sfx_players.has(key):
		return
	var player: AudioStreamPlayer = sfx_players[key]
	player.stop()
	player.play()


func _show_settlement() -> void:
	var summary := last_round_summary
	settlement_dialog.dialog_text = "第 %d 回合完成\n事件：%s\n本轮获得金币：%d\n本轮收取金币：%d\n最高连锁：%d\n当前金币：%d\n\n下一回合事件：%s\n商店已经刷新。" % [
		int(summary.get("round", 0)),
		String(summary.get("event", "")),
		int(summary.get("collected", 0)),
		int(summary.get("due", 0)),
		int(summary.get("best_chain", 0)),
		game_state.coins,
		String(current_event.get("name", ""))
	]
	settlement_dialog.popup_centered()


func style(fill: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.border_color = border
	box.border_width_left = width
	box.border_width_top = width
	box.border_width_right = width
	box.border_width_bottom = width
	box.content_margin_left = 8
	box.content_margin_top = 5
	box.content_margin_right = 8
	box.content_margin_bottom = 5
	return box


func can_start_tile_drag(from_palette: bool) -> bool:
	if not is_intermission:
		return false
	return true if from_palette else true


func can_start_slot_drag(slot_index: int) -> bool:
	return is_intermission and slot_index >= 0 and slot_index < TOTAL_SLOTS and not board_tiles[slot_index].is_empty()


func tile_type_at(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= TOTAL_SLOTS or board_tiles[slot_index].is_empty():
		return "normal"
	return String(board_tiles[slot_index]["type"])


func make_drag_preview(tile_type: String) -> Control:
	var preview := Label.new()
	preview.text = tile_symbol(tile_type)
	preview.custom_minimum_size = Vector2(72, 72)
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_theme_font_size_override("font_size", 40)
	preview.add_theme_color_override("font_color", Color.WHITE)
	preview.add_theme_stylebox_override("normal", style(Color(0.18, 0.20, 0.18), 8, GOLD, 2))
	return preview


func can_drop_on_slot(slot_index: int, data: Variant) -> bool:
	if not is_intermission or typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("kind") or not data.has("type"):
		return false
	if slot_index < 0 or slot_index >= TOTAL_SLOTS:
		return false
	if String(data["kind"]) == "palette":
		var tile_type := String(data["type"])
		if board_tiles[slot_index].is_empty():
			return game_state.coins >= int(TILE_TYPES[tile_type]["cost"])
		return _can_upgrade_slot(slot_index, tile_type)
	if String(data["kind"]) == "placed":
		var from_slot := int(data["from_slot"])
		return from_slot != slot_index and board_tiles[slot_index].is_empty()
	return false


func drop_on_slot(slot_index: int, data: Variant) -> void:
	var kind := String(data["kind"])
	var tile_type := String(data["type"])
	if kind == "palette":
		if board_tiles[slot_index].is_empty():
			var cost := int(TILE_TYPES[tile_type]["cost"])
			game_state.coins -= cost
			board_tiles[slot_index] = _new_tile(tile_type)
			_refresh_slot(slot_index)
			_play_sfx("buy")
			_update_ui("购买并放置 %s，花费 %d 金币。" % [TILE_TYPES[tile_type]["name"], cost])
		else:
			_upgrade_slot(slot_index)
	elif kind == "placed":
		var from_slot := int(data["from_slot"])
		board_tiles[slot_index] = board_tiles[from_slot]
		board_tiles[from_slot] = {}
		_refresh_slot(from_slot)
		_refresh_slot(slot_index)
		_play_sfx("buy")
		_update_ui("方块已移动。")


func can_drop_on_delete(data: Variant) -> bool:
	return is_intermission and typeof(data) == TYPE_DICTIONARY and String(data.get("kind", "")) == "placed"


func drop_on_delete(data: Variant) -> void:
	var from_slot := int(data["from_slot"])
	if from_slot < 0 or from_slot >= TOTAL_SLOTS or board_tiles[from_slot].is_empty():
		return
	var tile_type := String(board_tiles[from_slot]["type"])
	var refund := int(board_tiles[from_slot].get("invested", TILE_TYPES[tile_type]["cost"]))
	game_state.coins += refund
	board_tiles[from_slot] = {}
	_refresh_slot(from_slot)
	_play_sfx("buy")
	_update_ui("删除 %s，返还 %d 金币。" % [TILE_TYPES[tile_type]["name"], refund])


func _new_tile(tile_type: String) -> Dictionary:
	var cost := int(TILE_TYPES[tile_type]["cost"])
	return {
		"type": tile_type,
		"level": 1,
		"invested": cost,
		"clicks_left": MAX_TILE_CLICKS,
		"history": []
	}


func _can_upgrade_slot(slot_index: int, tile_type: String) -> bool:
	if board_tiles[slot_index].is_empty() or String(board_tiles[slot_index]["type"]) != tile_type:
		return false
	var level := int(board_tiles[slot_index].get("level", 1))
	return level < MAX_TILE_LEVEL and game_state.coins >= _upgrade_cost(tile_type, level)


func _upgrade_cost(tile_type: String, current_level: int) -> int:
	return int(TILE_TYPES[tile_type]["cost"]) * (current_level + 1)


func _upgrade_slot(slot_index: int) -> void:
	var tile := board_tiles[slot_index]
	var tile_type := String(tile["type"])
	var level := int(tile.get("level", 1))
	if level >= MAX_TILE_LEVEL:
		_update_ui("%s 已经满级。" % TILE_TYPES[tile_type]["name"])
		return
	var cost := _upgrade_cost(tile_type, level)
	if game_state.coins < cost:
		_update_ui("金币不足，升级需要 %d 金币。" % cost)
		return
	game_state.coins -= cost
	tile["level"] = level + 1
	tile["invested"] = int(tile.get("invested", TILE_TYPES[tile_type]["cost"])) + cost
	tile["clicks_left"] = _round_tile_click_max(tile)
	board_tiles[slot_index] = tile
	_refresh_slot(slot_index)
	_play_sfx("upgrade")
	_update_ui("%s 升到 Lv.%d，收益和触发率提升。" % [TILE_TYPES[tile_type]["name"], int(tile["level"])])


func _on_slot_pressed(index: int) -> void:
	if is_intermission:
		_update_ui("准备阶段不能点击方块。点击“开始下一回合”后开始收集金币。")
		return
	if manual_clicks_left <= 0:
		_update_ui("本轮手动点击次数已用完，请结束回合。")
		return
	if board_tiles[index].is_empty():
		_update_ui("空位没有方块，不会触发金币效果。")
		return

	manual_clicks_left -= 1
	var result := _trigger_tile(index, true, 0)
	best_chain_this_round = max(best_chain_this_round, int(result["triggered"]))
	_update_ui("手动点击触发 %d 个方块，获得 %d 金币。" % [result["triggered"], result["coins"]])


func _trigger_tile(index: int, is_manual: bool, depth: int) -> Dictionary:
	if depth > 80 or index < 0 or index >= TOTAL_SLOTS or board_tiles[index].is_empty():
		return {"coins": 0, "triggered": 0}

	var tile := board_tiles[index]
	if int(tile["clicks_left"]) <= 0:
		return {"coins": 0, "triggered": 0}

	var level := int(tile.get("level", 1))
	tile["clicks_left"] = int(tile["clicks_left"]) - 1
	var got_coin := rng.randf() < 0.5
	tile["history"].append(got_coin)
	board_tiles[index] = tile

	var tile_type := String(tile["type"])
	var coins := _tile_coin_value(tile_type, level) if got_coin else 0
	if got_coin:
		game_state.coins += coins
		round_collected += coins
		_play_sfx("coin")
	elif is_manual:
		_play_sfx("miss")
	elif depth <= 2:
		_play_sfx("chain")

	_refresh_slot(index)
	_flash_slot(index, COIN_FLASH if got_coin else GREEN)

	var triggered := 1
	for direction in TILE_TYPES[tile_type]["directions"]:
		if rng.randf() >= _tile_trigger_chance(tile_type, level):
			continue
		var next_index := _neighbor_index(index, direction)
		if next_index == -1:
			continue
		var result := _trigger_tile(next_index, false, depth + 1)
		coins += int(result["coins"])
		triggered += int(result["triggered"])

	return {"coins": coins, "triggered": triggered}


func _neighbor_index(index: int, direction: Vector2i) -> int:
	var x := index % GRID_COLUMNS
	var y := index / GRID_COLUMNS
	var nx := x + direction.x
	var ny := y + direction.y
	if nx < 0 or nx >= GRID_COLUMNS or ny < 0 or ny >= GRID_ROWS:
		return -1
	return ny * GRID_COLUMNS + nx


func _on_action_button_pressed() -> void:
	if is_intermission:
		_start_round()
	else:
		_end_round()


func _start_round() -> void:
	is_intermission = false
	manual_clicks_left = _round_manual_click_max()
	round_collected = 0
	best_chain_this_round = 0
	for index in range(TOTAL_SLOTS):
		if not board_tiles[index].is_empty():
			board_tiles[index]["clicks_left"] = _round_tile_click_max(board_tiles[index])
			board_tiles[index]["history"] = []
			_refresh_slot(index)
	_update_ui("回合开始：%s。只能点击已放置方块，拖拽购买/移动/删除已禁用。" % current_event["name"])


func _end_round() -> void:
	var due := _round_quota_due()
	last_round_summary = {
		"round": game_state.current_round,
		"collected": round_collected,
		"due": due,
		"best_chain": best_chain_this_round,
		"event": current_event.get("name", "")
	}
	game_state.coins -= due
	if game_state.coins < 0:
		_play_sfx("error")
		_update_ui("金币不足，游戏结束。")
		game_over_dialog.popup_centered()
		return

	game_state.current_round += 1
	quota = _next_quota(quota)
	game_state.required_coins = quota
	is_intermission = true
	_roll_shop_offers()
	_pick_round_event()
	manual_clicks_left = _round_manual_click_max()
	_rebuild_shop_palette()
	for index in range(TOTAL_SLOTS):
		if not board_tiles[index].is_empty():
			board_tiles[index]["clicks_left"] = _round_tile_click_max(board_tiles[index])
			board_tiles[index]["history"] = []
			_refresh_slot(index)
	_show_settlement()
	_play_sfx("settle")
	_update_ui("结算完成并收取 %d 金币。新事件：%s。商店已刷新。" % [due, current_event["name"]])


func _next_quota(current: int) -> int:
	var grown := int(ceil(float(current) * 1.3))
	return max(current + 1, grown)


func _restart_game() -> void:
	game_state.coins = STARTING_COINS
	game_state.current_round = 1
	quota = STARTING_QUOTA
	game_state.required_coins = quota
	is_intermission = true
	_roll_shop_offers()
	_pick_round_event()
	manual_clicks_left = _round_manual_click_max()
	round_collected = 0
	best_chain_this_round = 0
	for index in range(TOTAL_SLOTS):
		board_tiles[index] = {}
		_refresh_slot(index)
	_rebuild_shop_palette()
	_update_ui("已重新开始。准备阶段：从右侧拖拽购买方块。")


func _refresh_slot(index: int) -> void:
	var view := slot_views[index]
	var slot: PanelContainer = view["slot"]
	var icon: TextureRect = view["icon"]
	var history: HBoxContainer = view["history"]
	var info: Label = view["info"]
	var button: Button = view["button"]
	var tile := board_tiles[index]

	for child in history.get_children():
		child.queue_free()

	if tile.is_empty():
		icon.texture = null
		info.text = "空位"
		button.disabled = false
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_intermission else Control.MOUSE_FILTER_STOP
		button.tooltip_text = "准备阶段可拖入方块。回合中空位不会触发。"
		slot.add_theme_stylebox_override("panel", style(SLOT_COLOR, 8, Color(0.34, 0.55, 0.46), 2))
		return

	var tile_type := String(tile["type"])
	var config: Dictionary = TILE_TYPES[tile_type]
	icon.texture = TILE_TEXTURES[tile_type]
	var level := int(tile.get("level", 1))
	var max_clicks := _round_tile_click_max(tile)
	info.text = "%s Lv.%d  %d/%d" % [config["name"], level, int(tile["clicks_left"]), max_clicks]
	button.disabled = is_intermission
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_intermission else Control.MOUSE_FILTER_STOP
	button.tooltip_text = "%s\nLv.%d 成功金币 %d，方向触发率 %d%%。\n剩余触发次数 %d/%d。同类方块拖到这里可升级。" % [
		config["tip"],
		level,
		_tile_coin_value(tile_type, level),
		int(round(_tile_trigger_chance(tile_type, level) * 100.0)),
		int(tile["clicks_left"]),
		max_clicks
	]
	var border := _rarity_color(String(config["rarity"])).lightened(0.10 * float(level - 1))
	slot.add_theme_stylebox_override("panel", style(Color(0.13, 0.16, 0.16), 8, border if not is_intermission else border.darkened(0.18), 2 + level - 1))

	for item in tile["history"]:
		var mark := ColorRect.new()
		mark.custom_minimum_size = Vector2(16, 16)
		mark.color = COIN_FLASH if bool(item) else GREEN
		history.add_child(mark)


func _flash_slot(index: int, color: Color) -> void:
	var slot: PanelContainer = slot_views[index]["slot"]
	slot.pivot_offset = slot.size * 0.5
	slot.add_theme_stylebox_override("panel", style(color, 8, Color.WHITE, 2))
	var tween := create_tween()
	tween.tween_property(slot, "scale", Vector2(1.04, 1.04), 0.08)
	tween.tween_property(slot, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(max(0.0, FLASH_SECONDS - 0.20))
	tween.tween_callback(_refresh_slot.bind(index))


func _update_ui(message: String = "") -> void:
	coin_label.text = "金币\n%d" % game_state.coins
	round_label.text = "回合\n%d" % game_state.current_round
	quota_label.text = "收取\n%d" % quota
	clicks_label.text = "手动\n%d/%d" % [manual_clicks_left, _round_manual_click_max()]
	state_label.text = "状态\n%s" % ("准备" if is_intermission else "回合中")
	progress_label.text = "事件：%s - %s    本轮金币：%d    结束收取：%d    最高连锁：%d" % [
		current_event.get("name", ""),
		current_event.get("desc", ""),
		round_collected,
		_round_quota_due(),
		best_chain_this_round
	]
	notice_label.text = message
	action_button.text = "开始下一回合" if is_intermission else "结束回合"
	delete_zone.modulate = Color.WHITE if is_intermission else Color(0.55, 0.55, 0.55)

	for index in range(TOTAL_SLOTS):
		_refresh_slot(index)


func tile_symbol(tile_type: String) -> String:
	return String(TILE_TYPES[tile_type]["symbol"])
