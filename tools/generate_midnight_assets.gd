extends SceneTree

const COIN_SIZE := Vector2i(512, 320)
const TILE_SIZE := Vector2i(512, 512)
const ICON_SIZE := Vector2i(128, 128)

const CLEAR := Color(0, 0, 0, 0)
const INK := Color(0.010, 0.013, 0.022, 1)
const TEAL := Color(0.090, 0.140, 0.170, 1)
const MINT := Color(0.56, 0.82, 0.76, 1)
const GOLD := Color(0.86, 0.82, 0.64, 1)
const COPPER := Color(0.58, 0.66, 0.70, 1)
const VIOLET := Color(0.50, 0.50, 0.76, 1)
const ROSE := Color(0.88, 0.12, 0.20, 1)
const SKY := Color(0.42, 0.68, 0.78, 1)
const GLASS := Color(0.76, 0.88, 0.92, 0.78)
const WHITE := Color(0.86, 0.90, 0.88, 1)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://textures/coins"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://textures/tiles"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://textures/ui"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://textures/enemies"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://textures/relics"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://textures/consumables"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://textures/curses"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://textures/events"))

	_save_coin("res://textures/coins/coin_normal.png", COPPER.lightened(0.10), GOLD, "normal")
	_save_coin("res://textures/coins/coin_lucky.png", MINT, GOLD, "lucky")
	_save_coin("res://textures/coins/coin_reverse.png", VIOLET, SKY, "reverse")
	_save_coin("res://textures/coins/coin_glass.png", GLASS, SKY, "glass")
	_save_coin("res://textures/coins/coin_stock.png", Color(0.34, 0.80, 0.72), GOLD, "stock")
	_save_coin("res://textures/coins/coin_bitcoin.png", Color(0.74, 0.70, 0.52), GOLD, "bit")
	_save_coin("res://textures/coins/coin_vampire.png", ROSE, COPPER, "vampire")
	_save_coin("res://textures/coins/coin_spirit.png", VIOLET, SKY, "spirit")
	_save_coin("res://textures/coins/coin_angel.png", WHITE, MINT, "angel")
	_save_coin("res://textures/coins/coin_demon.png", ROSE.darkened(0.18), VIOLET, "demon")
	_save_coin("res://textures/coins/coin_mirror.png", GLASS, VIOLET, "mirror")
	_save_coin("res://textures/coins/coin_magnet.png", SKY, ROSE, "magnet")
	_save_coin("res://textures/coins/coin_echo.png", SKY, VIOLET, "echo")
	_save_coin("res://textures/coins/coin_shield.png", SKY, MINT, "shield")
	_save_coin("res://textures/coins/coin_forge.png", COPPER, ROSE, "forge")
	_save_coin("res://textures/coins/coin_compass.png", GOLD, SKY, "compass")
	_save_coin("res://textures/coins/coin_debt.png", COPPER, VIOLET, "debt")
	_save_coin("res://textures/coins/coin_arc.png", MINT, GOLD, "arc")
	_save_coin("res://textures/coins/coin_bloom.png", MINT, GOLD, "bloom")
	_save_coin("res://textures/coins/coin_titan.png", COPPER, GOLD, "titan")
	_save_coin("res://textures/coins/coin_hourglass.png", GOLD, VIOLET, "hourglass")
	_save_coin("res://textures/coins/coin_joker.png", VIOLET, GOLD, "joker")
	_save_coin("res://textures/coins/coin_anchor.png", SKY, GOLD, "anchor")

	_save_tile("res://textures/tiles/tile_normal.png", "dot")
	_save_tile("res://textures/tiles/tile_left.png", "left")
	_save_tile("res://textures/tiles/tile_right.png", "right")
	_save_tile("res://textures/tiles/tile_up.png", "up")
	_save_tile("res://textures/tiles/tile_down.png", "down")
	_save_tile("res://textures/tiles/tile_star.png", "star")
	_save_tile("res://textures/tiles/tile_bank.png", "bank")
	_save_tile("res://textures/tiles/tile_cross.png", "cross")
	_save_tile("res://textures/tiles/tile_surge.png", "surge")
	_save_icon("res://textures/ui/icon_enemy.png", ROSE, "enemy")
	_save_icon("res://textures/ui/icon_boss.png", VIOLET, "boss")
	_save_icon("res://textures/ui/icon_relic.png", GOLD, "relic")
	_save_icon("res://textures/ui/icon_consumable.png", MINT, "consumable")
	_save_icon("res://textures/ui/icon_curse.png", ROSE, "curse")
	_save_enemy_icons()
	_save_relic_icons()
	_save_consumable_icons()
	_save_curse_icons()
	_save_event_icons()
	quit()


func _save_coin(path: String, body: Color, accent: Color, symbol: String) -> void:
	var img := Image.create(COIN_SIZE.x, COIN_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)

	var center := Vector2(256, 160)
	_draw_ellipse(img, center + Vector2(0, 22), Vector2(198, 96), Color(0, 0, 0, 0.42))
	_draw_ellipse(img, center, Vector2(192, 106), body.darkened(0.34))
	_draw_ellipse(img, center + Vector2(0, -8), Vector2(174, 88), body.lightened(0.02))
	_draw_ellipse(img, center + Vector2(-48, -34), Vector2(84, 24), _alpha(WHITE, 0.26))
	_draw_ellipse_outline(img, center, Vector2(194, 107), accent.lightened(0.03), 11)
	_draw_ellipse_outline(img, center, Vector2(150, 73), _alpha(INK, 0.44), 5)
	_draw_ellipse_outline(img, center, Vector2(118, 56), accent.lightened(0.30), 3)
	_draw_line(img, center + Vector2(-132, -8), center + Vector2(132, -8), _alpha(WHITE, 0.16), 4)

	match symbol:
		"lucky":
			_draw_diamond(img, center, 56, WHITE, 10)
			_draw_line(img, center + Vector2(-42, 0), center + Vector2(42, 0), GOLD, 8)
		"reverse":
			_draw_arrow(img, center + Vector2(54, -18), center + Vector2(-54, -18), WHITE, 10)
			_draw_arrow(img, center + Vector2(-54, 20), center + Vector2(54, 20), SKY, 10)
		"glass":
			_draw_line(img, center + Vector2(-70, -46), center + Vector2(54, 50), WHITE, 7)
			_draw_line(img, center + Vector2(-10, -58), center + Vector2(72, 22), SKY, 5)
			_draw_line(img, center + Vector2(-78, 28), center + Vector2(12, -12), Color(1, 1, 1, 0.7), 5)
		"stock":
			_draw_line(img, center + Vector2(-74, 42), center + Vector2(-20, 10), WHITE, 10)
			_draw_line(img, center + Vector2(-20, 10), center + Vector2(18, 24), WHITE, 10)
			_draw_arrow(img, center + Vector2(18, 24), center + Vector2(78, -44), GOLD, 10)
		"bit":
			_draw_line(img, center + Vector2(-42, -54), center + Vector2(-42, 54), WHITE, 9)
			_draw_line(img, center + Vector2(42, -54), center + Vector2(42, 54), WHITE, 9)
			_draw_ellipse_outline(img, center + Vector2(0, -20), Vector2(58, 32), WHITE, 8)
			_draw_ellipse_outline(img, center + Vector2(0, 24), Vector2(66, 34), WHITE, 8)
		"vampire":
			_draw_diamond(img, center + Vector2(-18, 0), 30, WHITE, 10)
			_draw_diamond(img, center + Vector2(18, 0), 30, ROSE, 10)
			_draw_line(img, center + Vector2(-52, 34), center + Vector2(52, -34), COPPER, 7)
		"spirit":
			_draw_ellipse_outline(img, center, Vector2(76, 48), WHITE, 8)
			_draw_ellipse_outline(img, center, Vector2(42, 26), SKY, 6)
			_draw_line(img, center + Vector2(-70, 0), center + Vector2(70, 0), VIOLET, 6)
		"angel":
			_draw_line(img, center + Vector2(-66, 20), center + Vector2(0, -40), WHITE, 9)
			_draw_line(img, center + Vector2(66, 20), center + Vector2(0, -40), WHITE, 9)
			_draw_ellipse_outline(img, center + Vector2(0, -48), Vector2(44, 18), GOLD, 7)
			_draw_line(img, center + Vector2(0, -8), center + Vector2(0, 50), MINT, 8)
		"demon":
			_draw_line(img, center + Vector2(-48, -44), center + Vector2(-18, -10), VIOLET, 9)
			_draw_line(img, center + Vector2(48, -44), center + Vector2(18, -10), VIOLET, 9)
			_draw_diamond(img, center + Vector2(0, 14), 46, ROSE, 10)
			_draw_line(img, center + Vector2(-32, 36), center + Vector2(32, -36), WHITE, 6)
		"mirror":
			_draw_diamond(img, center, 72, WHITE, 8)
			_draw_diamond(img, center, 46, SKY, 6)
			_draw_line(img, center + Vector2(0, -62), center + Vector2(0, 62), VIOLET, 5)
			_draw_line(img, center + Vector2(-36, -28), center + Vector2(36, 28), Color(1, 1, 1, 0.72), 5)
		"magnet":
			_draw_ellipse_outline(img, center + Vector2(-36, 0), Vector2(38, 56), ROSE, 12)
			_draw_ellipse_outline(img, center + Vector2(36, 0), Vector2(38, 56), SKY, 12)
			_draw_line(img, center + Vector2(-36, -56), center + Vector2(36, -56), WHITE, 10)
			_draw_line(img, center + Vector2(-36, 56), center + Vector2(36, 56), WHITE, 10)
		"echo":
			_draw_ellipse_outline(img, center, Vector2(84, 50), SKY, 8)
			_draw_ellipse_outline(img, center, Vector2(56, 34), WHITE, 6)
			_draw_ellipse_outline(img, center, Vector2(30, 18), VIOLET, 5)
		"shield":
			_draw_diamond(img, center, 70, SKY, 12)
			_draw_line(img, center + Vector2(-38, -2), center + Vector2(-6, 34), WHITE, 9)
			_draw_line(img, center + Vector2(-6, 34), center + Vector2(46, -42), MINT, 9)
		"forge":
			_draw_round_rect(img, Rect2(center.x - 74, center.y - 24, 148, 58), 14, COPPER)
			_draw_line(img, center + Vector2(-60, -52), center + Vector2(60, -52), WHITE, 9)
			_draw_ellipse(img, center + Vector2(0, 20), Vector2(34, 38), ROSE)
			_draw_line(img, center + Vector2(-28, 48), center + Vector2(0, -22), GOLD, 7)
			_draw_line(img, center + Vector2(28, 48), center + Vector2(0, -22), GOLD, 7)
		"compass":
			_draw_ellipse_outline(img, center, Vector2(74, 74), SKY, 8)
			_draw_arrow(img, center + Vector2(-42, 42), center + Vector2(42, -42), GOLD, 9)
			_draw_arrow(img, center + Vector2(32, -32), center + Vector2(-32, 32), WHITE, 7)
		"debt":
			_draw_round_rect(img, Rect2(center.x - 64, center.y - 54, 128, 108), 14, COPPER)
			_draw_line(img, center + Vector2(-42, -24), center + Vector2(42, -24), WHITE, 7)
			_draw_line(img, center + Vector2(-42, 0), center + Vector2(26, 0), VIOLET, 7)
			_draw_line(img, center + Vector2(-42, 24), center + Vector2(42, 24), GOLD, 7)
		"arc":
			_draw_arrow(img, center + Vector2(-66, -34), center + Vector2(66, 34), GOLD, 10)
			_draw_arrow(img, center + Vector2(-66, 34), center + Vector2(66, -34), MINT, 10)
			_draw_ellipse(img, center, Vector2(24, 24), WHITE)
		"bloom":
			for offset in [Vector2(0, -44), Vector2(42, -12), Vector2(26, 38), Vector2(-26, 38), Vector2(-42, -12)]:
				_draw_ellipse(img, center + offset, Vector2(28, 22), MINT)
			_draw_ellipse(img, center, Vector2(28, 28), GOLD)
		"titan":
			_draw_round_rect(img, Rect2(center.x - 74, center.y - 38, 148, 76), 18, COPPER)
			_draw_line(img, center + Vector2(-54, -56), center + Vector2(-24, -28), GOLD, 11)
			_draw_line(img, center + Vector2(54, -56), center + Vector2(24, -28), GOLD, 11)
			_draw_line(img, center + Vector2(-48, 52), center + Vector2(48, 52), WHITE, 10)
		"hourglass":
			_draw_diamond(img, center + Vector2(0, -30), 46, GOLD, 7)
			_draw_diamond(img, center + Vector2(0, 30), 46, VIOLET, 7)
			_draw_line(img, center + Vector2(-42, -66), center + Vector2(42, -66), WHITE, 7)
			_draw_line(img, center + Vector2(-42, 66), center + Vector2(42, 66), WHITE, 7)
		"joker":
			_draw_ellipse(img, center + Vector2(-34, -8), Vector2(34, 44), VIOLET)
			_draw_ellipse(img, center + Vector2(34, -8), Vector2(34, 44), GOLD)
			_draw_ellipse(img, center + Vector2(-18, -14), Vector2(9, 9), WHITE)
			_draw_ellipse(img, center + Vector2(18, -14), Vector2(9, 9), WHITE)
			_draw_line(img, center + Vector2(-34, 34), center + Vector2(34, 34), ROSE, 7)
		"anchor":
			_draw_line(img, center + Vector2(0, -66), center + Vector2(0, 58), SKY, 12)
			_draw_ellipse_outline(img, center + Vector2(0, -62), Vector2(24, 18), WHITE, 6)
			_draw_line(img, center + Vector2(-62, -4), center + Vector2(62, -4), GOLD, 10)
			_draw_line(img, center + Vector2(-62, -4), center + Vector2(-34, 50), SKY, 10)
			_draw_line(img, center + Vector2(62, -4), center + Vector2(34, 50), SKY, 10)
		_:
			_draw_ellipse_outline(img, center, Vector2(68, 42), WHITE, 10)
			_draw_line(img, center + Vector2(-64, 0), center + Vector2(64, 0), GOLD, 8)

	img.save_png(path)


func _save_tile(path: String, symbol: String) -> void:
	var img := Image.create(TILE_SIZE.x, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)

	_draw_round_rect(img, Rect2(54, 54, 404, 404), 34, Color(0, 0, 0, 0.34))
	_draw_round_rect(img, Rect2(48, 42, 416, 416), 32, TEAL.darkened(0.16))
	_draw_round_rect(img, Rect2(74, 68, 364, 364), 22, TEAL.lightened(0.04))
	_draw_round_rect_outline(img, Rect2(48, 42, 416, 416), 32, SKY.darkened(0.05), 12)
	_draw_round_rect_outline(img, Rect2(96, 90, 320, 320), 18, Color(0.86, 0.90, 0.88, 0.12), 5)

	var center := Vector2(256, 248)
	match symbol:
		"left":
			_draw_arrow(img, center + Vector2(82, 0), center + Vector2(-82, 0), GOLD, 22)
		"right":
			_draw_arrow(img, center + Vector2(-82, 0), center + Vector2(82, 0), GOLD, 22)
		"up":
			_draw_arrow(img, center + Vector2(0, 82), center + Vector2(0, -82), GOLD, 22)
		"down":
			_draw_arrow(img, center + Vector2(0, -82), center + Vector2(0, 82), GOLD, 22)
		"star":
			_draw_arrow(img, center + Vector2(-96, 0), center + Vector2(96, 0), GOLD, 15)
			_draw_arrow(img, center + Vector2(96, 0), center + Vector2(-96, 0), GOLD, 15)
			_draw_arrow(img, center + Vector2(0, -96), center + Vector2(0, 96), SKY, 15)
			_draw_arrow(img, center + Vector2(0, 96), center + Vector2(0, -96), SKY, 15)
			_draw_ellipse(img, center, Vector2(34, 34), WHITE)
		"bank":
			_draw_ellipse(img, center, Vector2(76, 76), GOLD)
			_draw_line(img, center + Vector2(-46, -22), center + Vector2(46, -22), WHITE, 14)
			_draw_line(img, center + Vector2(-46, 22), center + Vector2(46, 22), WHITE, 14)
			_draw_line(img, center + Vector2(0, -78), center + Vector2(0, 78), GOLD.darkened(0.25), 12)
		"cross":
			_draw_arrow(img, center + Vector2(-98, 0), center + Vector2(98, 0), GOLD, 18)
			_draw_arrow(img, center + Vector2(98, 0), center + Vector2(-98, 0), GOLD, 18)
			_draw_arrow(img, center + Vector2(0, -98), center + Vector2(0, 98), WHITE, 18)
			_draw_arrow(img, center + Vector2(0, 98), center + Vector2(0, -98), WHITE, 18)
			_draw_diamond(img, center, 38, SKY, 7)
		"surge":
			_draw_diamond(img, center, 112, ROSE, 12)
			_draw_arrow(img, center + Vector2(-78, 48), center + Vector2(78, -48), GOLD, 18)
			_draw_line(img, center + Vector2(0, -76), center + Vector2(0, 18), WHITE, 15)
			_draw_ellipse(img, center + Vector2(0, 68), Vector2(14, 14), WHITE)
		_:
			_draw_ellipse(img, center, Vector2(78, 78), GOLD)
			_draw_ellipse_outline(img, center, Vector2(106, 106), _alpha(WHITE, 0.85), 12)

	img.save_png(path)


func _save_icon(path: String, accent: Color, symbol: String) -> void:
	var img := Image.create(ICON_SIZE.x, ICON_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	var rect := Rect2(10, 10, 108, 108)
	var center := Vector2(64, 64)
	_draw_round_rect(img, Rect2(14, 18, 100, 100), 14, Color(0, 0, 0, 0.34))
	_draw_round_rect(img, rect, 14, TEAL.darkened(0.26))
	_draw_round_rect(img, Rect2(18, 18, 92, 92), 10, TEAL)
	_draw_round_rect_outline(img, rect, 14, accent, 5)
	match symbol:
		"enemy":
			_draw_ellipse(img, center, Vector2(32, 20), WHITE)
			_draw_ellipse(img, center, Vector2(12, 12), accent.darkened(0.15))
			_draw_line(img, center + Vector2(-34, -30), center + Vector2(-20, -16), accent, 5)
			_draw_line(img, center + Vector2(34, -30), center + Vector2(20, -16), accent, 5)
		"boss":
			_draw_diamond(img, center, 36, accent.lightened(0.20), 7)
			_draw_line(img, center + Vector2(-28, 0), center + Vector2(28, 0), WHITE, 6)
			_draw_line(img, center + Vector2(0, -28), center + Vector2(0, 28), WHITE, 6)
		"relic":
			_draw_diamond(img, center, 38, WHITE, 7)
			_draw_diamond(img, center, 20, accent, 6)
		"consumable":
			_draw_line(img, center + Vector2(-30, 0), center + Vector2(30, 0), WHITE, 11)
			_draw_line(img, center + Vector2(0, -30), center + Vector2(0, 30), WHITE, 11)
			_draw_ellipse_outline(img, center, Vector2(40, 40), accent, 5)
		"curse":
			_draw_line(img, center + Vector2(-30, -30), center + Vector2(30, 30), accent, 9)
			_draw_line(img, center + Vector2(30, -30), center + Vector2(-30, 30), accent, 9)
			_draw_ellipse_outline(img, center, Vector2(36, 36), WHITE, 5)
	img.save_png(path)


func _save_enemy_icons() -> void:
	var specs := {
		"thief": {"accent": ROSE, "symbol": "steal"},
		"guard": {"accent": SKY, "symbol": "shield"},
		"sniper": {"accent": GOLD, "symbol": "target"},
		"debt": {"accent": COPPER, "symbol": "debt"},
		"taxer": {"accent": GOLD, "symbol": "tax"},
		"devourer": {"accent": ROSE, "symbol": "fang"},
		"hexer": {"accent": VIOLET, "symbol": "curse"},
		"saboteur": {"accent": ROSE, "symbol": "cut"},
		"healer": {"accent": MINT, "symbol": "heal"},
		"gambler_rat": {"accent": GOLD, "symbol": "dice"},
		"frost": {"accent": SKY, "symbol": "frost"},
		"mimic": {"accent": VIOLET, "symbol": "copy"},
		"timekeeper": {"accent": GOLD, "symbol": "clock"},
		"lock_boss": {"accent": ROSE, "symbol": "lock_boss"},
		"market_boss": {"accent": GOLD, "symbol": "market_boss"},
		"debt_boss": {"accent": COPPER, "symbol": "debt_boss"},
		"mirror_boss": {"accent": VIOLET, "symbol": "mirror_boss"},
		"banker": {"accent": GOLD, "symbol": "banker"}
	}
	for enemy_id in specs.keys():
		var spec: Dictionary = specs[enemy_id]
		_save_enemy_icon("res://textures/enemies/%s.png" % enemy_id, Color(spec["accent"]), String(spec["symbol"]))


func _save_enemy_icon(path: String, accent: Color, symbol: String) -> void:
	var img := Image.create(ICON_SIZE.x, ICON_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	var rect := Rect2(8, 8, 112, 112)
	var center := Vector2(64, 64)
	_draw_round_rect(img, Rect2(13, 17, 104, 104), 15, Color(0, 0, 0, 0.36))
	_draw_round_rect(img, rect, 15, TEAL.darkened(0.30))
	_draw_round_rect(img, Rect2(18, 18, 92, 92), 10, TEAL.darkened(0.02))
	_draw_round_rect_outline(img, rect, 15, accent, 5)
	_draw_enemy_symbol(img, center, accent, symbol)
	img.save_png(path)


func _draw_enemy_symbol(img: Image, center: Vector2, accent: Color, symbol: String) -> void:
	match symbol:
		"steal":
			_draw_ellipse(img, center, Vector2(34, 20), WHITE)
			_draw_ellipse(img, center + Vector2(12, 0), Vector2(8, 8), accent)
			_draw_line(img, center + Vector2(-22, 24), center + Vector2(22, 24), accent, 6)
		"shield":
			_draw_diamond(img, center, 38, SKY, 8)
			_draw_line(img, center + Vector2(-22, -4), center + Vector2(0, 22), WHITE, 7)
			_draw_line(img, center + Vector2(0, 22), center + Vector2(28, -22), WHITE, 7)
		"target":
			_draw_ellipse_outline(img, center, Vector2(38, 38), accent, 7)
			_draw_ellipse_outline(img, center, Vector2(20, 20), WHITE, 5)
			_draw_line(img, center + Vector2(-44, 0), center + Vector2(44, 0), accent, 4)
			_draw_line(img, center + Vector2(0, -44), center + Vector2(0, 44), accent, 4)
		"debt":
			_draw_line(img, center + Vector2(-30, -24), center + Vector2(30, -24), WHITE, 7)
			_draw_line(img, center + Vector2(-30, 0), center + Vector2(22, 0), accent, 7)
			_draw_line(img, center + Vector2(-30, 24), center + Vector2(30, 24), WHITE, 7)
		"tax":
			_draw_line(img, center + Vector2(-34, -28), center + Vector2(34, 28), accent, 8)
			_draw_ellipse(img, center + Vector2(-22, -20), Vector2(10, 10), WHITE)
			_draw_ellipse(img, center + Vector2(22, 20), Vector2(10, 10), WHITE)
		"fang":
			_draw_diamond(img, center + Vector2(-16, 0), 20, WHITE, 8)
			_draw_diamond(img, center + Vector2(16, 0), 20, WHITE, 8)
			_draw_line(img, center + Vector2(-38, -26), center + Vector2(38, 26), accent, 7)
		"curse":
			_draw_line(img, center + Vector2(-34, -34), center + Vector2(34, 34), accent, 8)
			_draw_line(img, center + Vector2(34, -34), center + Vector2(-34, 34), accent, 8)
			_draw_ellipse_outline(img, center, Vector2(36, 36), WHITE, 5)
		"cut":
			_draw_line(img, center + Vector2(-34, 28), center + Vector2(34, -28), WHITE, 8)
			_draw_line(img, center + Vector2(-36, -16), center + Vector2(-10, 10), accent, 7)
			_draw_line(img, center + Vector2(36, 16), center + Vector2(10, -10), accent, 7)
		"heal":
			_draw_line(img, center + Vector2(-30, 0), center + Vector2(30, 0), WHITE, 11)
			_draw_line(img, center + Vector2(0, -30), center + Vector2(0, 30), WHITE, 11)
			_draw_ellipse_outline(img, center, Vector2(42, 42), accent, 5)
		"dice":
			_draw_round_rect(img, Rect2(center.x - 30, center.y - 30, 60, 60), 12, WHITE)
			_draw_ellipse(img, center + Vector2(-14, -14), Vector2(5, 5), accent)
			_draw_ellipse(img, center, Vector2(5, 5), accent)
			_draw_ellipse(img, center + Vector2(14, 14), Vector2(5, 5), accent)
		"frost":
			_draw_line(img, center + Vector2(-36, 0), center + Vector2(36, 0), SKY, 8)
			_draw_line(img, center + Vector2(0, -36), center + Vector2(0, 36), SKY, 8)
			_draw_line(img, center + Vector2(-26, -26), center + Vector2(26, 26), WHITE, 6)
			_draw_line(img, center + Vector2(26, -26), center + Vector2(-26, 26), WHITE, 6)
		"copy":
			_draw_round_rect_outline(img, Rect2(center.x - 36, center.y - 24, 52, 52), 10, VIOLET, 6)
			_draw_round_rect_outline(img, Rect2(center.x - 16, center.y - 32, 52, 52), 10, WHITE, 6)
		"clock":
			_draw_ellipse_outline(img, center, Vector2(40, 40), GOLD, 7)
			_draw_line(img, center, center + Vector2(0, -26), WHITE, 6)
			_draw_line(img, center, center + Vector2(20, 12), WHITE, 6)
		"lock_boss":
			_draw_round_rect_outline(img, Rect2(center.x - 30, center.y - 2, 60, 42), 10, ROSE, 8)
			_draw_ellipse_outline(img, center + Vector2(0, -14), Vector2(24, 26), WHITE, 7)
		"market_boss":
			_draw_line(img, center + Vector2(-36, 30), center + Vector2(-10, 2), WHITE, 8)
			_draw_line(img, center + Vector2(-10, 2), center + Vector2(8, 16), WHITE, 8)
			_draw_arrow(img, center + Vector2(8, 16), center + Vector2(38, -32), GOLD, 8)
		"debt_boss":
			_draw_diamond(img, center, 38, COPPER, 8)
			_draw_line(img, center + Vector2(-22, -20), center + Vector2(22, 20), WHITE, 7)
			_draw_line(img, center + Vector2(22, -20), center + Vector2(-22, 20), WHITE, 7)
		"mirror_boss":
			_draw_diamond(img, center, 42, VIOLET, 7)
			_draw_line(img, center + Vector2(0, -34), center + Vector2(0, 34), WHITE, 6)
			_draw_line(img, center + Vector2(-24, -16), center + Vector2(24, 16), SKY, 6)
		"banker":
			_draw_ellipse_outline(img, center, Vector2(42, 32), GOLD, 8)
			_draw_line(img, center + Vector2(-28, 0), center + Vector2(28, 0), WHITE, 7)
			_draw_line(img, center + Vector2(0, -28), center + Vector2(0, 28), WHITE, 7)


func _save_relic_icons() -> void:
	var specs := {
		"golden_glove": {"accent": GOLD, "symbol": "glove"},
		"chain_bell": {"accent": MINT, "symbol": "bell"},
		"red_heart": {"accent": ROSE, "symbol": "heart"},
		"tax_receipt": {"accent": GOLD, "symbol": "receipt"},
		"loaded_die": {"accent": VIOLET, "symbol": "die"},
		"war_banner": {"accent": ROSE, "symbol": "banner"},
		"merchant_seal": {"accent": GOLD, "symbol": "seal"},
		"deep_pockets": {"accent": COPPER, "symbol": "pocket"},
		"silver_lens": {"accent": SKY, "symbol": "lens"},
		"steady_anvil": {"accent": COPPER, "symbol": "anvil"},
		"void_purse": {"accent": VIOLET, "symbol": "void"},
		"shield_charm": {"accent": SKY, "symbol": "shield"},
		"blood_cup": {"accent": ROSE, "symbol": "cup"},
		"glass_hammer": {"accent": GLASS, "symbol": "hammer"},
		"oracle_deck": {"accent": VIOLET, "symbol": "deck"},
		"echo_chamber": {"accent": SKY, "symbol": "echo"},
		"bloom_crown": {"accent": MINT, "symbol": "crown"},
		"titan_gauntlet": {"accent": COPPER, "symbol": "gauntlet"},
		"debt_ledger": {"accent": COPPER, "symbol": "ledger"},
		"cartographer_map": {"accent": GOLD, "symbol": "map"},
		"joker_mask": {"accent": VIOLET, "symbol": "mask"},
		"anchor_chain": {"accent": SKY, "symbol": "anchor"},
		"bounty_contract": {"accent": GOLD, "symbol": "contract"},
		"furnace_core": {"accent": ROSE, "symbol": "furnace"},
		"pocket_watch": {"accent": GOLD, "symbol": "watch"}
	}
	for relic_id in specs.keys():
		var spec: Dictionary = specs[relic_id]
		_save_relic_icon("res://textures/relics/%s.png" % relic_id, Color(spec["accent"]), String(spec["symbol"]))


func _save_consumable_icons() -> void:
	var specs := {
		"heal_potion": {"accent": MINT, "symbol": "potion"},
		"smoke_bomb": {"accent": SKY, "symbol": "smoke"},
		"lucky_ticket": {"accent": GOLD, "symbol": "ticket"},
		"market_tip": {"accent": VIOLET, "symbol": "tip"},
		"repair_kit": {"accent": COPPER, "symbol": "repair"}
	}
	for item_id in specs.keys():
		var spec: Dictionary = specs[item_id]
		_save_item_icon("res://textures/consumables/%s.png" % item_id, Color(spec["accent"]), String(spec["symbol"]))


func _save_curse_icons() -> void:
	var specs := {
		"blood_money": {"accent": ROSE, "symbol": "blood_money"},
		"heavy_debt": {"accent": COPPER, "symbol": "heavy_debt"},
		"thin_bag": {"accent": SKY, "symbol": "thin_bag"},
		"cursed_coin": {"accent": VIOLET, "symbol": "cursed_coin"}
	}
	for curse_id in specs.keys():
		var spec: Dictionary = specs[curse_id]
		_save_item_icon("res://textures/curses/%s.png" % curse_id, Color(spec["accent"]), String(spec["symbol"]))


func _save_event_icons() -> void:
	var specs := {
		"coin": {"accent": GOLD, "symbol": "event_coin"},
		"chain": {"accent": MINT, "symbol": "event_chain"},
		"reverse": {"accent": VIOLET, "symbol": "event_reverse"},
		"manual": {"accent": SKY, "symbol": "event_manual"},
		"quota_down": {"accent": MINT, "symbol": "event_quota_down"},
		"quota_up": {"accent": ROSE, "symbol": "event_quota_up"},
		"shop": {"accent": GOLD, "symbol": "event_shop"},
		"durability": {"accent": COPPER, "symbol": "event_durability"},
		"fragile": {"accent": ROSE, "symbol": "event_fragile"},
		"defense": {"accent": SKY, "symbol": "event_defense"},
		"danger": {"accent": ROSE, "symbol": "event_danger"},
		"neutral": {"accent": WHITE, "symbol": "event_neutral"}
	}
	for event_id in specs.keys():
		var spec: Dictionary = specs[event_id]
		_save_item_icon("res://textures/events/%s.png" % event_id, Color(spec["accent"]), String(spec["symbol"]))


func _save_item_icon(path: String, accent: Color, symbol: String) -> void:
	var img := Image.create(ICON_SIZE.x, ICON_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	var rect := Rect2(8, 8, 112, 112)
	var center := Vector2(64, 64)
	_draw_round_rect(img, Rect2(13, 17, 104, 104), 15, Color(0, 0, 0, 0.34))
	_draw_round_rect(img, rect, 15, TEAL.darkened(0.28))
	_draw_round_rect(img, Rect2(18, 18, 92, 92), 10, TEAL)
	_draw_round_rect_outline(img, rect, 15, accent, 5)
	_draw_item_symbol(img, center, accent, symbol)
	img.save_png(path)


func _save_relic_icon(path: String, accent: Color, symbol: String) -> void:
	var img := Image.create(ICON_SIZE.x, ICON_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	var rect := Rect2(8, 8, 112, 112)
	var center := Vector2(64, 64)
	_draw_round_rect(img, Rect2(13, 17, 104, 104), 15, Color(0, 0, 0, 0.34))
	_draw_round_rect(img, rect, 15, TEAL.darkened(0.28))
	_draw_round_rect(img, Rect2(18, 18, 92, 92), 10, TEAL)
	_draw_round_rect_outline(img, rect, 15, accent, 5)
	_draw_relic_symbol(img, center, accent, symbol)
	img.save_png(path)


func _draw_relic_symbol(img: Image, center: Vector2, accent: Color, symbol: String) -> void:
	match symbol:
		"glove":
			_draw_ellipse(img, center + Vector2(-8, 8), Vector2(28, 24), GOLD)
			_draw_line(img, center + Vector2(10, -28), center + Vector2(10, 16), WHITE, 10)
			_draw_line(img, center + Vector2(26, -20), center + Vector2(10, 10), WHITE, 8)
		"bell":
			_draw_ellipse_outline(img, center + Vector2(0, 4), Vector2(34, 32), MINT, 8)
			_draw_line(img, center + Vector2(-34, 22), center + Vector2(34, 22), WHITE, 7)
			_draw_ellipse(img, center + Vector2(0, 34), Vector2(8, 8), GOLD)
		"heart":
			_draw_ellipse(img, center + Vector2(-14, -8), Vector2(17, 17), ROSE)
			_draw_ellipse(img, center + Vector2(14, -8), Vector2(17, 17), ROSE)
			_draw_diamond(img, center + Vector2(0, 12), 26, ROSE, 14)
		"receipt":
			_draw_round_rect(img, Rect2(center.x - 28, center.y - 36, 56, 72), 8, WHITE)
			_draw_line(img, center + Vector2(-18, -16), center + Vector2(18, -16), accent, 5)
			_draw_line(img, center + Vector2(-18, 2), center + Vector2(12, 2), accent, 5)
			_draw_line(img, center + Vector2(-18, 20), center + Vector2(18, 20), accent, 5)
		"die":
			_draw_round_rect(img, Rect2(center.x - 32, center.y - 32, 64, 64), 12, WHITE)
			for offset in [Vector2(-16, -16), Vector2(16, -16), Vector2(0, 0), Vector2(-16, 16), Vector2(16, 16)]:
				_draw_ellipse(img, center + offset, Vector2(5, 5), accent)
		"banner":
			_draw_line(img, center + Vector2(-28, -34), center + Vector2(-28, 38), WHITE, 7)
			_draw_round_rect(img, Rect2(center.x - 22, center.y - 30, 58, 38), 5, ROSE)
			_draw_line(img, center + Vector2(-8, -12), center + Vector2(22, -12), GOLD, 5)
		"seal":
			_draw_ellipse(img, center, Vector2(34, 34), GOLD)
			_draw_diamond(img, center, 20, WHITE, 6)
			_draw_line(img, center + Vector2(-22, 32), center + Vector2(-8, 16), ROSE, 6)
			_draw_line(img, center + Vector2(22, 32), center + Vector2(8, 16), ROSE, 6)
		"pocket":
			_draw_round_rect(img, Rect2(center.x - 34, center.y - 24, 68, 58), 14, COPPER)
			_draw_ellipse_outline(img, center + Vector2(0, -20), Vector2(24, 18), WHITE, 6)
			_draw_line(img, center + Vector2(-20, 8), center + Vector2(20, 8), GOLD, 6)
		"lens":
			_draw_ellipse_outline(img, center + Vector2(-8, -8), Vector2(30, 30), SKY, 8)
			_draw_line(img, center + Vector2(16, 16), center + Vector2(42, 42), WHITE, 8)
			_draw_line(img, center + Vector2(-18, -8), center + Vector2(6, -18), WHITE, 5)
		"anvil":
			_draw_round_rect(img, Rect2(center.x - 38, center.y - 4, 76, 22), 6, COPPER)
			_draw_round_rect(img, Rect2(center.x - 18, center.y + 14, 36, 28), 5, WHITE)
			_draw_line(img, center + Vector2(-28, -22), center + Vector2(28, -22), GOLD, 7)
		"void":
			_draw_ellipse(img, center, Vector2(36, 36), VIOLET)
			_draw_ellipse(img, center, Vector2(20, 20), TEAL.darkened(0.35))
			_draw_line(img, center + Vector2(-34, 0), center + Vector2(34, 0), WHITE, 5)
		"shield":
			_draw_diamond(img, center, 38, SKY, 8)
			_draw_line(img, center + Vector2(-20, 0), center + Vector2(-2, 20), WHITE, 7)
			_draw_line(img, center + Vector2(-2, 20), center + Vector2(26, -24), WHITE, 7)
		"cup":
			_draw_round_rect_outline(img, Rect2(center.x - 26, center.y - 28, 52, 42), 10, ROSE, 7)
			_draw_line(img, center + Vector2(-18, 16), center + Vector2(18, 16), WHITE, 7)
			_draw_line(img, center + Vector2(0, 14), center + Vector2(0, 38), ROSE, 7)
			_draw_line(img, center + Vector2(-22, 40), center + Vector2(22, 40), WHITE, 6)
		"hammer":
			_draw_round_rect(img, Rect2(center.x - 36, center.y - 34, 54, 24), 6, GLASS)
			_draw_line(img, center + Vector2(-2, -10), center + Vector2(32, 36), WHITE, 9)
			_draw_line(img, center + Vector2(-30, 30), center + Vector2(28, -30), SKY, 5)
		"deck":
			_draw_round_rect_outline(img, Rect2(center.x - 34, center.y - 28, 50, 64), 8, VIOLET, 6)
			_draw_round_rect_outline(img, Rect2(center.x - 14, center.y - 36, 50, 64), 8, WHITE, 6)
			_draw_diamond(img, center + Vector2(12, -4), 14, GOLD, 5)
		"echo":
			_draw_ellipse_outline(img, center, Vector2(40, 28), SKY, 7)
			_draw_ellipse_outline(img, center, Vector2(24, 16), WHITE, 5)
			_draw_line(img, center + Vector2(28, -30), center + Vector2(44, -42), SKY, 5)
			_draw_line(img, center + Vector2(28, 30), center + Vector2(44, 42), SKY, 5)
		"crown":
			_draw_line(img, center + Vector2(-38, 24), center + Vector2(38, 24), GOLD, 8)
			_draw_line(img, center + Vector2(-34, 20), center + Vector2(-22, -22), MINT, 8)
			_draw_line(img, center + Vector2(-22, -22), center + Vector2(0, 10), MINT, 8)
			_draw_line(img, center + Vector2(0, 10), center + Vector2(22, -22), MINT, 8)
			_draw_line(img, center + Vector2(22, -22), center + Vector2(34, 20), MINT, 8)
		"gauntlet":
			_draw_ellipse(img, center + Vector2(-10, 10), Vector2(26, 24), COPPER)
			_draw_line(img, center + Vector2(10, -34), center + Vector2(10, 12), WHITE, 10)
			_draw_line(img, center + Vector2(24, -28), center + Vector2(12, 12), GOLD, 8)
			_draw_line(img, center + Vector2(36, -18), center + Vector2(14, 14), COPPER, 8)
		"ledger":
			_draw_round_rect(img, Rect2(center.x - 30, center.y - 38, 60, 76), 8, COPPER)
			_draw_line(img, center + Vector2(-16, -18), center + Vector2(18, -18), WHITE, 5)
			_draw_line(img, center + Vector2(-16, 0), center + Vector2(18, 0), GOLD, 5)
			_draw_line(img, center + Vector2(-16, 18), center + Vector2(10, 18), WHITE, 5)
			_draw_line(img, center + Vector2(-30, -38), center + Vector2(-30, 38), VIOLET, 5)
		"map":
			_draw_line(img, center + Vector2(-38, -30), center + Vector2(-12, -18), WHITE, 7)
			_draw_line(img, center + Vector2(-12, -18), center + Vector2(14, -30), GOLD, 7)
			_draw_line(img, center + Vector2(14, -30), center + Vector2(38, -18), WHITE, 7)
			_draw_line(img, center + Vector2(-38, -30), center + Vector2(-38, 32), WHITE, 6)
			_draw_line(img, center + Vector2(-12, -18), center + Vector2(-12, 42), GOLD, 6)
			_draw_line(img, center + Vector2(14, -30), center + Vector2(14, 30), WHITE, 6)
			_draw_line(img, center + Vector2(38, -18), center + Vector2(38, 42), GOLD, 6)
		"mask":
			_draw_ellipse(img, center + Vector2(-18, -2), Vector2(20, 26), VIOLET)
			_draw_ellipse(img, center + Vector2(18, -2), Vector2(20, 26), VIOLET)
			_draw_ellipse(img, center + Vector2(-14, -6), Vector2(6, 6), WHITE)
			_draw_ellipse(img, center + Vector2(14, -6), Vector2(6, 6), WHITE)
			_draw_line(img, center + Vector2(-18, 22), center + Vector2(18, 22), GOLD, 5)
		"anchor":
			_draw_line(img, center + Vector2(0, -38), center + Vector2(0, 34), SKY, 8)
			_draw_ellipse_outline(img, center + Vector2(0, -34), Vector2(13, 13), WHITE, 5)
			_draw_line(img, center + Vector2(-34, 2), center + Vector2(34, 2), WHITE, 7)
			_draw_line(img, center + Vector2(-34, 2), center + Vector2(-22, 30), SKY, 7)
			_draw_line(img, center + Vector2(34, 2), center + Vector2(22, 30), SKY, 7)
		"contract":
			_draw_round_rect(img, Rect2(center.x - 30, center.y - 38, 60, 76), 8, WHITE)
			_draw_line(img, center + Vector2(-18, -18), center + Vector2(18, -18), COPPER, 5)
			_draw_line(img, center + Vector2(-18, 0), center + Vector2(14, 0), GOLD, 5)
			_draw_ellipse(img, center + Vector2(16, 26), Vector2(12, 12), ROSE)
		"furnace":
			_draw_round_rect(img, Rect2(center.x - 32, center.y - 18, 64, 52), 12, COPPER)
			_draw_ellipse(img, center + Vector2(0, 8), Vector2(20, 24), ROSE)
			_draw_line(img, center + Vector2(-18, 24), center + Vector2(0, -18), GOLD, 6)
			_draw_line(img, center + Vector2(18, 24), center + Vector2(0, -18), GOLD, 6)
			_draw_line(img, center + Vector2(-28, -28), center + Vector2(28, -28), WHITE, 7)
		"watch":
			_draw_ellipse_outline(img, center, Vector2(38, 38), GOLD, 7)
			_draw_ellipse_outline(img, center + Vector2(0, -44), Vector2(12, 8), WHITE, 5)
			_draw_line(img, center, center + Vector2(0, -24), WHITE, 6)
			_draw_line(img, center, center + Vector2(22, 12), SKY, 6)


func _draw_item_symbol(img: Image, center: Vector2, accent: Color, symbol: String) -> void:
	match symbol:
		"potion":
			_draw_round_rect(img, Rect2(center.x - 18, center.y - 28, 36, 58), 12, MINT)
			_draw_line(img, center + Vector2(-12, -34), center + Vector2(12, -34), WHITE, 7)
			_draw_ellipse(img, center + Vector2(0, 12), Vector2(18, 16), SKY)
		"smoke":
			_draw_ellipse(img, center + Vector2(-14, 10), Vector2(18, 14), SKY)
			_draw_ellipse(img, center + Vector2(10, 4), Vector2(24, 18), WHITE)
			_draw_ellipse(img, center + Vector2(26, -12), Vector2(14, 11), SKY)
			_draw_line(img, center + Vector2(-30, 32), center + Vector2(30, 32), accent, 6)
		"ticket":
			_draw_round_rect(img, Rect2(center.x - 36, center.y - 24, 72, 48), 8, GOLD)
			_draw_line(img, center + Vector2(-18, -10), center + Vector2(18, -10), WHITE, 5)
			_draw_line(img, center + Vector2(-18, 8), center + Vector2(10, 8), WHITE, 5)
			_draw_diamond(img, center + Vector2(26, 0), 10, VIOLET, 4)
		"tip":
			_draw_ellipse_outline(img, center + Vector2(-10, -4), Vector2(28, 28), VIOLET, 7)
			_draw_line(img, center + Vector2(12, 18), center + Vector2(38, 36), WHITE, 7)
			_draw_arrow(img, center + Vector2(-22, 20), center + Vector2(18, -18), GOLD, 6)
		"repair":
			_draw_line(img, center + Vector2(-34, 28), center + Vector2(28, -34), WHITE, 8)
			_draw_round_rect(img, Rect2(center.x - 14, center.y - 38, 42, 18), 6, COPPER)
			_draw_line(img, center + Vector2(-28, -18), center + Vector2(24, 34), GOLD, 6)
		"blood_money":
			_draw_ellipse(img, center + Vector2(-10, 2), Vector2(26, 26), GOLD)
			_draw_ellipse_outline(img, center + Vector2(-10, 2), Vector2(34, 34), ROSE, 6)
			_draw_diamond(img, center + Vector2(22, 18), 16, ROSE, 8)
		"heavy_debt":
			_draw_round_rect(img, Rect2(center.x - 32, center.y - 36, 64, 72), 8, COPPER)
			_draw_line(img, center + Vector2(-18, -14), center + Vector2(18, -14), WHITE, 6)
			_draw_line(img, center + Vector2(-18, 4), center + Vector2(14, 4), GOLD, 6)
			_draw_line(img, center + Vector2(-18, 22), center + Vector2(18, 22), ROSE, 6)
		"thin_bag":
			_draw_round_rect_outline(img, Rect2(center.x - 28, center.y - 24, 56, 54), 14, SKY, 7)
			_draw_line(img, center + Vector2(-16, -28), center + Vector2(16, -28), WHITE, 7)
			_draw_line(img, center + Vector2(-32, 18), center + Vector2(32, -18), ROSE, 7)
		"cursed_coin":
			_draw_ellipse(img, center, Vector2(34, 34), VIOLET)
			_draw_ellipse_outline(img, center, Vector2(42, 42), ROSE, 6)
			_draw_line(img, center + Vector2(-24, -24), center + Vector2(24, 24), WHITE, 6)
			_draw_line(img, center + Vector2(24, -24), center + Vector2(-24, 24), WHITE, 6)
		"event_coin":
			_draw_ellipse(img, center, Vector2(34, 34), GOLD)
			_draw_ellipse_outline(img, center, Vector2(44, 44), WHITE, 6)
			_draw_line(img, center + Vector2(-24, 0), center + Vector2(24, 0), COPPER, 6)
		"event_chain":
			_draw_ellipse_outline(img, center + Vector2(-20, 0), Vector2(24, 18), MINT, 7)
			_draw_ellipse_outline(img, center + Vector2(20, 0), Vector2(24, 18), WHITE, 7)
			_draw_line(img, center + Vector2(-4, 0), center + Vector2(4, 0), GOLD, 6)
		"event_reverse":
			_draw_arrow(img, center + Vector2(34, -18), center + Vector2(-34, -18), WHITE, 7)
			_draw_arrow(img, center + Vector2(-34, 18), center + Vector2(34, 18), VIOLET, 7)
		"event_manual":
			_draw_ellipse_outline(img, center, Vector2(38, 38), SKY, 7)
			_draw_line(img, center + Vector2(0, -26), center + Vector2(0, 26), WHITE, 7)
			_draw_line(img, center + Vector2(-26, 0), center + Vector2(26, 0), WHITE, 7)
		"event_quota_down":
			_draw_arrow(img, center + Vector2(0, -36), center + Vector2(0, 36), MINT, 9)
			_draw_line(img, center + Vector2(-28, -24), center + Vector2(28, -24), WHITE, 6)
			_draw_line(img, center + Vector2(-18, 0), center + Vector2(18, 0), WHITE, 6)
		"event_quota_up":
			_draw_arrow(img, center + Vector2(0, 36), center + Vector2(0, -36), ROSE, 9)
			_draw_line(img, center + Vector2(-28, 24), center + Vector2(28, 24), WHITE, 6)
			_draw_line(img, center + Vector2(-18, 0), center + Vector2(18, 0), WHITE, 6)
		"event_shop":
			_draw_round_rect(img, Rect2(center.x - 34, center.y - 22, 68, 52), 10, GOLD)
			_draw_line(img, center + Vector2(-28, -22), center + Vector2(-16, -40), WHITE, 7)
			_draw_line(img, center + Vector2(28, -22), center + Vector2(16, -40), WHITE, 7)
			_draw_line(img, center + Vector2(-18, 6), center + Vector2(18, 6), COPPER, 6)
		"event_durability":
			_draw_diamond(img, center, 38, COPPER, 8)
			_draw_line(img, center + Vector2(-22, -2), center + Vector2(-2, 22), WHITE, 7)
			_draw_line(img, center + Vector2(-2, 22), center + Vector2(26, -24), GOLD, 7)
		"event_fragile":
			_draw_diamond(img, center, 40, GLASS, 8)
			_draw_line(img, center + Vector2(-28, -28), center + Vector2(30, 30), ROSE, 7)
			_draw_line(img, center + Vector2(-6, -38), center + Vector2(20, 18), WHITE, 5)
		"event_defense":
			_draw_diamond(img, center, 42, SKY, 8)
			_draw_line(img, center + Vector2(-22, 0), center + Vector2(-4, 20), WHITE, 7)
			_draw_line(img, center + Vector2(-4, 20), center + Vector2(26, -26), MINT, 7)
		"event_danger":
			_draw_diamond(img, center, 42, ROSE, 8)
			_draw_line(img, center + Vector2(0, -28), center + Vector2(0, 10), WHITE, 8)
			_draw_ellipse(img, center + Vector2(0, 28), Vector2(7, 7), WHITE)
		"event_neutral":
			_draw_ellipse_outline(img, center, Vector2(40, 40), WHITE, 7)
			_draw_line(img, center + Vector2(-24, 0), center + Vector2(24, 0), GOLD, 6)


func _draw_round_rect(img: Image, rect: Rect2, radius: float, color: Color) -> void:
	for y in range(int(rect.position.y), int(rect.end.y)):
		for x in range(int(rect.position.x), int(rect.end.x)):
			if _inside_round_rect(Vector2(x + 0.5, y + 0.5), rect, radius):
				_blend_pixel(img, x, y, color)


func _draw_round_rect_outline(img: Image, rect: Rect2, radius: float, color: Color, width: int) -> void:
	var inner: Rect2 = rect.grow(-width)
	for y in range(int(rect.position.y), int(rect.end.y)):
		for x in range(int(rect.position.x), int(rect.end.x)):
			var point := Vector2(x + 0.5, y + 0.5)
			if _inside_round_rect(point, rect, radius) and not _inside_round_rect(point, inner, max(0.0, radius - width)):
				_blend_pixel(img, x, y, color)


func _inside_round_rect(point: Vector2, rect: Rect2, radius: float) -> bool:
	var inner: Rect2 = rect.grow(-radius)
	if point.x >= inner.position.x and point.x <= inner.end.x and point.y >= rect.position.y and point.y <= rect.end.y:
		return true
	if point.y >= inner.position.y and point.y <= inner.end.y and point.x >= rect.position.x and point.x <= rect.end.x:
		return true
	var cx: float = rect.position.x + radius if point.x < inner.position.x else rect.end.x - radius
	var cy: float = rect.position.y + radius if point.y < inner.position.y else rect.end.y - radius
	return point.distance_to(Vector2(cx, cy)) <= radius


func _draw_ellipse(img: Image, center: Vector2, radii: Vector2, color: Color) -> void:
	for y in range(int(center.y - radii.y - 2), int(center.y + radii.y + 2)):
		for x in range(int(center.x - radii.x - 2), int(center.x + radii.x + 2)):
				var d: float = pow((x + 0.5 - center.x) / radii.x, 2.0) + pow((y + 0.5 - center.y) / radii.y, 2.0)
				if d <= 1.0:
					var edge: float = clamp((1.0 - d) * 18.0, 0.0, 1.0)
					_blend_pixel(img, x, y, _alpha(color, color.a * edge))


func _draw_ellipse_outline(img: Image, center: Vector2, radii: Vector2, color: Color, width: int) -> void:
	var inner := radii - Vector2(width, width)
	for y in range(int(center.y - radii.y - 2), int(center.y + radii.y + 2)):
		for x in range(int(center.x - radii.x - 2), int(center.x + radii.x + 2)):
				var outer_d: float = pow((x + 0.5 - center.x) / radii.x, 2.0) + pow((y + 0.5 - center.y) / radii.y, 2.0)
				var inner_d: float = pow((x + 0.5 - center.x) / inner.x, 2.0) + pow((y + 0.5 - center.y) / inner.y, 2.0)
				if outer_d <= 1.0 and inner_d >= 1.0:
					var edge: float = clamp((1.0 - outer_d) * 18.0, 0.0, 1.0)
					_blend_pixel(img, x, y, _alpha(color, color.a * max(0.35, edge)))


func _draw_diamond(img: Image, center: Vector2, radius: float, color: Color, width: int) -> void:
	_draw_line(img, center + Vector2(0, -radius), center + Vector2(radius, 0), color, width)
	_draw_line(img, center + Vector2(radius, 0), center + Vector2(0, radius), color, width)
	_draw_line(img, center + Vector2(0, radius), center + Vector2(-radius, 0), color, width)
	_draw_line(img, center + Vector2(-radius, 0), center + Vector2(0, -radius), color, width)


func _draw_arrow(img: Image, start: Vector2, finish: Vector2, color: Color, width: int) -> void:
	_draw_line(img, start, finish, color, width)
	var dir := (start - finish).normalized()
	var side := Vector2(-dir.y, dir.x)
	_draw_line(img, finish, finish + dir * 38 + side * 30, color, width)
	_draw_line(img, finish, finish + dir * 38 - side * 30, color, width)


func _draw_line(img: Image, start: Vector2, finish: Vector2, color: Color, width: int) -> void:
	var min_x := int(floor(min(start.x, finish.x) - width - 2))
	var max_x := int(ceil(max(start.x, finish.x) + width + 2))
	var min_y := int(floor(min(start.y, finish.y) - width - 2))
	var max_y := int(ceil(max(start.y, finish.y) + width + 2))
	var line: Vector2 = finish - start
	var len_sq: float = max(0.001, line.length_squared())
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var t: float = clamp((p - start).dot(line) / len_sq, 0.0, 1.0)
			var closest: Vector2 = start + line * t
			var dist: float = p.distance_to(closest)
			if dist <= float(width):
				var alpha: float = clamp(float(width) - dist, 0.0, 1.0)
				_blend_pixel(img, x, y, _alpha(color, color.a * alpha))


func _blend_pixel(img: Image, x: int, y: int, src: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height() or src.a <= 0.0:
		return
	var dst := img.get_pixel(x, y)
	var out_a := src.a + dst.a * (1.0 - src.a)
	if out_a <= 0.0:
		img.set_pixel(x, y, CLEAR)
		return
	var out := Color(
		(src.r * src.a + dst.r * dst.a * (1.0 - src.a)) / out_a,
		(src.g * src.a + dst.g * dst.a * (1.0 - src.a)) / out_a,
		(src.b * src.a + dst.b * dst.a * (1.0 - src.a)) / out_a,
		out_a
	)
	img.set_pixel(x, y, out)


func _alpha(color: Color, value: float) -> Color:
	return Color(color.r, color.g, color.b, value)
