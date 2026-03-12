extends Node2D

# 网格尺寸
var grid_size = Vector2(4, 5)
var cell_size = Vector2(100, 100)
var coins = {}  # Dictionary to store placed coins by position

# 拖拽状态
var selected_coin_type: String = "normal"
var is_dragging = false
var drag_offset: Vector2 = Vector2(0, 0)

func _ready():
    print("Grid initialized with size: ", grid_size)
    setup_grid()

func setup_grid():
    # 创建4x5网格
    for row in range(grid_size.y):
        for col in range(grid_size.x):
            var cell_pos = Vector2(col * cell_size.x, row * cell_size.y)
            var cell = create_cell(cell_pos)
            add_child(cell)
            coins[Vector2(col, row)] = null

func create_cell(pos: Vector2) -> Control:
    var cell = Control.new()
    cell.set_position(pos)
    cell.set_size(cell_size)
    cell.add_stylebox_override("panel", StyleBoxFlat.new())
    
    # 添加虚线边框
    var style = StyleBoxFlat.new()
    style.set_bg_color(Color(0.2, 0.2, 0.2, 0.3))
    style.set_border_width(1)
    style.set_border_color(Color(0.5, 0.5, 0.5, 0.8))
    cell.add_stylebox_override("panel", style)
    
    # 连接鼠标事件
    cell.connect("mouse_entered", self, "_on_cell_entered", [Vector2(pos.x / cell_size.x, pos.y / cell_size.y)])
    cell.connect("mouse_exited", self, "_on_cell_exited")
    
    return cell

func _on_cell_entered(cell_pos: Vector2):
    if is_dragging and coins[cell_pos] == null:
        # 高亮格子
        pass

func _on_cell_exited():
    # 取消高亮
    pass

func place_coin(cell_pos: Vector2, coin_type: String):
    print("Placing ", coin_type, " at ", cell_pos)
    
    if coins.has(cell_pos) and coins[cell_pos] == null:
        var new_coin = create_coin(coin_type)
        new_coin.set_position(Vector2(cell_pos.x * cell_size.x + 20, cell_pos.y * cell_size.y + 20))
        add_child(new_coin)
        coins[cell_pos] = new_coin
        update_total_attack_power()
        return true
    return false

func create_coin(type: String) -> Node2D:
    var coin = Coin.new(type)
    return coin

func remove_coin(cell_pos: Vector2):
    if coins.has(cell_pos):
        var coin = coins[cell_pos]
        if coin:
            remove_child(coin)
            coins[cell_pos] = null
            update_total_attack_power()

func update_total_attack_power():
    var total_power = 0
    for pos in coins:
        if coins[pos]:
            total_power += coins[pos].attack_power
    
    print("Total attack power: ", total_power)
    return total_power

func flip_coins():
    for pos in coins:
        if coins[pos]:
            var result = coins[pos].flip()
            print("Coin at ", pos, " result: ", result)
            # 这里会触发抛掷动画和效果
