extends Node2D

# UI引用
onready var coin_ui = null
onready var status_bar = null
onready var grid = null
onready var inventory = null

# 金币引用
onready var coin_normal = null
onready var coin_reverse = null
onready var coin_glass = null
onready var coin_bitcoin = null
onready var coin_stock = null
onready var coin_lucky = null

# 游戏状态
var game_state: Node

func _ready():
    print("Main initialized")
    load_resources()
    setup_ui()

func load_resources():
    # 加载金币纹理
    coin_normal = load_coin_texture("normal")
    coin_reverse = load_coin_texture("reverse")
    coin_glass = load_coin_texture("glass")
    coin_bitcoin = load_coin_texture("bitcoin")
    coin_stock = load_coin_texture("stock")
    coin_lucky = load_coin_texture("lucky")

func load_coin_texture(type: String) -> Texture2D:
    return load("res://textures/coins/coin_" + type + ".png")

func setup_ui():
    # 设置UI布局
    # 这里会在实际的Godot编辑器中设置

func on_coin_clicked(coin_type: String):
    print("Coin clicked: ", coin_type)
    
    # 根据硬币类型执行不同逻辑
    match coin_type:
        "normal":
            flip_normal_coin()
        "reverse":
            flip_reverse_coin()
        "glass":
            flip_glass_coin()
        "bitcoin":
            flip_bitcoin_coin()
        "stock":
            flip_stock_coin()
        "lucky":
            flip_lucky_coin()

func flip_normal_coin():
    print("Flipping normal coin...")
    game_state.flip_coin()
    update_status_bar()
    check_round_completion()

func flip_reverse_coin():
    print("Flipping reverse coin...")
    game_state.flip_coin()
    update_status_bar()
    check_round_completion()

func flip_glass_coin():
    print("Flipping glass coin (20% break chance)...")
    if randf() < 0.2:
        print("Glass coin broke!")
    else:
        game_state.flip_coin()
        game_state.add_coins(3)
    update_status_bar()
    check_round_completion()

func flip_bitcoin_coin():
    print("Flipping bitcoin (no flip limit)...")
    game_state.add_coins(50)
    update_status_bar()
    check_round_completion()

func flip_stock_coin():
    print("Flipping stock coin (+10% or -10%)...")
    var change = randf()
    if change < 0.5:
        print("Stock dropped 10%")
    else:
        print("Stock rose 10%")
    update_status_bar()

func flip_lucky_coin():
    print("Flipping lucky coin (increases future coin amount)...")
    game_state.flip_coin()
    game_state.add_coins(4)
    update_status_bar()
    check_round_completion()

func update_status_bar():
    # 更新状态条显示
    # 红色=成功，绿色=失败，灰色=未抛掷
    pass

func check_round_completion():
    game_state.check_round_completion()
