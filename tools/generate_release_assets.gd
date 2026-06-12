extends SceneTree

const CLEAR := Color(0, 0, 0, 0)
const INK := Color(0.010, 0.013, 0.022, 1)
const TEAL := Color(0.090, 0.140, 0.170, 1)
const MINT := Color(0.56, 0.82, 0.76, 1)
const GOLD := Color(0.86, 0.82, 0.64, 1)
const COPPER := Color(0.58, 0.66, 0.70, 1)
const ROSE := Color(0.88, 0.12, 0.20, 1)
const SKY := Color(0.42, 0.68, 0.78, 1)
const WHITE := Color(0.86, 0.90, 0.88, 1)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://textures/branding"))
	_save_app_icon("res://textures/branding/app_icon.png")
	_save_splash("res://textures/branding/boot_splash.png", Vector2i(1600, 1000))
	_save_capsule("res://textures/branding/steam_capsule_616x353.png", Vector2i(616, 353))
	_save_capsule("res://textures/branding/steam_header_920x430.png", Vector2i(920, 430))
	_save_vertical_capsule("res://textures/branding/steam_library_600x900.png", Vector2i(600, 900))
	print("Generated release branding assets")
	quit()


func _save_app_icon(path: String) -> void:
	var img := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	img.fill(INK)
	_draw_grid(img, 96, Color(0.42, 0.68, 0.78, 0.14))
	_draw_ellipse(img, Vector2(512, 566), Vector2(320, 170), Color(0, 0, 0, 0.40))
	_draw_ellipse(img, Vector2(512, 500), Vector2(330, 210), COPPER.darkened(0.18))
	_draw_ellipse(img, Vector2(512, 470), Vector2(295, 170), SKY.darkened(0.03))
	_draw_ellipse_outline(img, Vector2(512, 470), Vector2(332, 210), WHITE.darkened(0.10), 18)
	_draw_ellipse_outline(img, Vector2(512, 470), Vector2(220, 126), INK, 12)
	_draw_segment_text(img, "FC", Vector2(333, 355), 112, WHITE, 18)
	_draw_line(img, Vector2(300, 655), Vector2(724, 655), ROSE, 14)
	_draw_line(img, Vector2(354, 710), Vector2(670, 710), MINT, 9)
	img.save_png(path)


func _save_splash(path: String, size: Vector2i) -> void:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	_fill_gradient(img)
	_draw_grid(img, 80, Color(0.42, 0.68, 0.78, 0.12))
	_draw_board_motif(img, Vector2(size.x * 0.18, size.y * 0.45), 1.15)
	_draw_coin_stack(img, Vector2(size.x * 0.50, size.y * 0.48), 1.55)
	_draw_enemy_mark(img, Vector2(size.x * 0.78, size.y * 0.42), 1.20)
	_draw_segment_text(img, "FATE", Vector2(size.x * 0.24, size.y * 0.18), 76, WHITE, 12)
	_draw_segment_text(img, "COINS", Vector2(size.x * 0.23, size.y * 0.72), 62, WHITE, 10)
	_draw_segment_text(img, "CHAIN RISK", Vector2(size.x * 0.39, size.y * 0.83), 34, SKY, 6)
	_draw_line(img, Vector2(size.x * 0.24, size.y * 0.66), Vector2(size.x * 0.76, size.y * 0.66), ROSE, 7)
	img.save_png(path)


func _save_capsule(path: String, size: Vector2i) -> void:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	_fill_gradient(img)
	_draw_grid(img, 54, Color(0.42, 0.68, 0.78, 0.13))
	var scale := float(size.y) / 580.0
	_draw_board_motif(img, Vector2(size.x * 0.58, size.y * 0.55), scale * 0.72)
	_draw_enemy_mark(img, Vector2(size.x * 0.84, size.y * 0.34), scale * 0.58)
	_draw_coin_stack(img, Vector2(size.x * 0.72, size.y * 0.56), scale)
	_draw_segment_text(img, "FATE", Vector2(size.x * 0.06, size.y * 0.15), float(size.y) / 5.8, WHITE, max(5, int(size.y / 50)))
	_draw_segment_text(img, "COINS", Vector2(size.x * 0.06, size.y * 0.45), float(size.y) / 7.8, WHITE, max(4, int(size.y / 60)))
	_draw_segment_text(img, "CHAIN RISK", Vector2(size.x * 0.07, size.y * 0.74), float(size.y) / 15.0, SKY, max(3, int(size.y / 95)))
	_draw_line(img, Vector2(size.x * 0.08, size.y * 0.86), Vector2(size.x * 0.54, size.y * 0.86), ROSE, max(4, int(size.y / 80)))
	img.save_png(path)


func _save_vertical_capsule(path: String, size: Vector2i) -> void:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	_fill_gradient(img)
	_draw_grid(img, 64, Color(0.42, 0.68, 0.78, 0.12))
	_draw_board_motif(img, Vector2(size.x * 0.50, size.y * 0.38), 0.82)
	_draw_coin_stack(img, Vector2(size.x * 0.50, size.y * 0.50), 1.05)
	_draw_enemy_mark(img, Vector2(size.x * 0.72, size.y * 0.38), 0.78)
	_draw_segment_text(img, "FATE", Vector2(size.x * 0.16, size.y * 0.11), 56, WHITE, 9)
	_draw_segment_text(img, "COINS", Vector2(size.x * 0.11, size.y * 0.76), 45, WHITE, 8)
	_draw_segment_text(img, "CHAIN RISK", Vector2(size.x * 0.13, size.y * 0.88), 24, SKY, 5)
	img.save_png(path)


func _draw_coin_stack(img: Image, center: Vector2, scale: float) -> void:
	for i in range(5):
		var offset := Vector2(0, (4 - i) * 34.0 * scale)
		var body := SKY if i % 2 == 0 else COPPER.lightened(0.10)
		_draw_ellipse(img, center + offset, Vector2(170, 86) * scale, body.darkened(0.30))
		_draw_ellipse(img, center + offset + Vector2(0, -12) * scale, Vector2(155, 70) * scale, body)
		_draw_ellipse_outline(img, center + offset + Vector2(0, -7) * scale, Vector2(170, 86) * scale, MINT if i == 0 else WHITE.lightened(0.10), max(4, int(8 * scale)))
	_draw_diamond(img, center + Vector2(0, -28) * scale, 54 * scale, WHITE, max(5, int(8 * scale)))
	_draw_line(img, center + Vector2(-64, -28) * scale, center + Vector2(64, -28) * scale, ROSE, max(4, int(7 * scale)))


func _draw_board_motif(img: Image, center: Vector2, scale: float) -> void:
	var cell := 42.0 * scale
	var origin := center - Vector2(cell * 1.5, cell)
	for row in range(3):
		for col in range(4):
			var pos := origin + Vector2(col * cell, row * cell)
			_draw_rect(img, Rect2(pos, Vector2(cell * 0.82, cell * 0.82)), Color(0.03, 0.04, 0.055, 0.92), SKY.darkened(0.24), max(2, int(3 * scale)))
	for point in [Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(2, 0), Vector2(3, 0)]:
		var p := origin + Vector2(point.x * cell + cell * 0.41, point.y * cell + cell * 0.41)
		_draw_ellipse(img, p, Vector2(13, 7) * scale, GOLD)
		_draw_ellipse_outline(img, p, Vector2(15, 9) * scale, MINT, max(2, int(3 * scale)))
	var path_points := [
		origin + Vector2(cell * 0.41, cell * 1.41),
		origin + Vector2(cell * 1.41, cell * 1.41),
		origin + Vector2(cell * 2.41, cell * 1.41),
		origin + Vector2(cell * 2.41, cell * 0.41),
		origin + Vector2(cell * 3.41, cell * 0.41)
	]
	for i in range(path_points.size() - 1):
		_draw_line(img, path_points[i], path_points[i + 1], SKY, max(2, int(4 * scale)))


func _draw_enemy_mark(img: Image, center: Vector2, scale: float) -> void:
	_draw_diamond(img, center, 46 * scale, ROSE, max(4, int(7 * scale)))
	_draw_ellipse(img, center, Vector2(34, 24) * scale, Color(0.16, 0.03, 0.04, 0.92))
	_draw_ellipse(img, center + Vector2(-12, -3) * scale, Vector2(5, 5) * scale, WHITE)
	_draw_ellipse(img, center + Vector2(12, -3) * scale, Vector2(5, 5) * scale, WHITE)
	_draw_line(img, center + Vector2(-16, 14) * scale, center + Vector2(16, 14) * scale, ROSE, max(3, int(4 * scale)))


func _draw_rect(img: Image, rect: Rect2, fill: Color, border: Color, width: int) -> void:
	for y in range(int(rect.position.y), int(rect.position.y + rect.size.y)):
		for x in range(int(rect.position.x), int(rect.position.x + rect.size.x)):
			_blend_pixel(img, x, y, fill)
	_draw_line(img, rect.position, rect.position + Vector2(rect.size.x, 0), border, width)
	_draw_line(img, rect.position + Vector2(rect.size.x, 0), rect.position + rect.size, border, width)
	_draw_line(img, rect.position + rect.size, rect.position + Vector2(0, rect.size.y), border, width)
	_draw_line(img, rect.position + Vector2(0, rect.size.y), rect.position, border, width)


func _fill_gradient(img: Image) -> void:
	for y in range(img.get_height()):
		var t: float = float(y) / max(1.0, float(img.get_height() - 1))
		var row: Color = INK.lerp(Color(0.030, 0.044, 0.062), t)
		for x in range(img.get_width()):
			img.set_pixel(x, y, row)


func _draw_grid(img: Image, spacing: int, color: Color) -> void:
	for x in range(0, img.get_width(), spacing):
		_draw_line(img, Vector2(x, 0), Vector2(x, img.get_height()), color, 1)
	for y in range(0, img.get_height(), spacing):
		_draw_line(img, Vector2(0, y), Vector2(img.get_width(), y), color, 1)


func _draw_segment_text(img: Image, text: String, origin: Vector2, size: float, color: Color, width: int) -> void:
	var cursor := origin
	for raw_char in text:
		var ch := String(raw_char).to_upper()
		_draw_segment_char(img, ch, cursor, size, color, width)
		cursor.x += size * 0.78


func _draw_segment_char(img: Image, ch: String, origin: Vector2, size: float, color: Color, width: int) -> void:
	var w := size * 0.50
	var h := size
	var mid := origin.y + h * 0.50
	var right := origin.x + w
	var bottom := origin.y + h
	var segments := {
		"A": ["top", "ul", "ur", "mid", "ll", "lr"],
		"C": ["top", "ul", "ll", "bottom"],
		"E": ["top", "ul", "mid", "ll", "bottom"],
		"F": ["top", "ul", "mid", "ll"],
		"H": ["ul", "ur", "mid", "ll", "lr"],
		"I": ["top", "center", "bottom"],
		"K": ["ul", "ll", "diag_up", "diag_down"],
		"N": ["ul", "lr", "diag_down", "ll", "ur"],
		"O": ["top", "ul", "ur", "ll", "lr", "bottom"],
		"R": ["top", "ul", "ur", "mid", "ll", "diag_down"],
		"S": ["top", "ul", "mid", "lr", "bottom"],
		"T": ["top", "center"]
	}
	for segment in segments.get(ch, []):
		match String(segment):
			"top":
				_draw_line(img, origin, Vector2(right, origin.y), color, width)
			"mid":
				_draw_line(img, Vector2(origin.x, mid), Vector2(right, mid), color, width)
			"bottom":
				_draw_line(img, Vector2(origin.x, bottom), Vector2(right, bottom), color, width)
			"ul":
				_draw_line(img, origin, Vector2(origin.x, mid), color, width)
			"ur":
				_draw_line(img, Vector2(right, origin.y), Vector2(right, mid), color, width)
			"ll":
				_draw_line(img, Vector2(origin.x, mid), Vector2(origin.x, bottom), color, width)
			"lr":
				_draw_line(img, Vector2(right, mid), Vector2(right, bottom), color, width)
			"center":
				_draw_line(img, Vector2(origin.x + w * 0.5, origin.y), Vector2(origin.x + w * 0.5, bottom), color, width)
			"diag_down":
				_draw_line(img, origin, Vector2(right, bottom), color, width)
			"diag_up":
				_draw_line(img, Vector2(origin.x, bottom), Vector2(right, mid), color, width)


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
