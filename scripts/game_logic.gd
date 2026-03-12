extends Node

# 全局游戏状态
var game_started: bool = false
var current_state: String = "menu"  # menu, game, battle, shop, inventory
var coins_collected: int = 0
var coins_needed: int = 1
var current_round: int = 1

# 引用
onready var main_script = null
onready var game_state_script = null
onready var grid_script = null
onready var battle_system_script = null

func _ready():
    print("GameLogic initialized")

func start_game():
    print("Starting game...")
    game_started = true
    current_state = "game"
    coins_collected = 0
    coins_needed = 1
    current_round = 1
    
    # 初始化游戏状态
    if game_state_script:
        game_state_script.coins = 100
        game_state_script.flip_count = 3
    
    # 生成敌人
    if battle_system_script:
        battle_system_script.enemy_health = 100
        battle_system_script.enemy_attack_power = 10
        battle_system_script.player_health = 100
        battle_system_script.player_attack_power = 0  # 将在放置硬币时更新

func enter_shop():
    print("Entering shop...")
    current_state = "shop"

func enter_inventory():
    print("Entering inventory...")
    current_state = "inventory"

func collect_coin(amount: int):
    coins_collected += amount
    print("Coin collected! Total this round: ", coins_collected)
    
    # 更新敌人攻击力
    if battle_system_script:
        battle_system_script.update_attack_powers(0, amount)

func update_requirements():
    # 每回合需求金币数+30%
    coins_needed = max(1, int(coins_needed * 1.3))
    print("Round ", current_round, " requirement: ", coins_needed)

func check_round_end():
    if coins_collected >= coins_needed:
        print("Round complete! Coins: ", coins_collected, ", Required: ", coins_needed)
        next_round()
    else:
        print("Round not complete. Need ", coins_needed - coins_collected, " more coins")

func next_round():
    current_round += 1
    coins_collected = 0
    update_requirements()
    
    # 重置抛掷次数
    if game_state_script:
        game_state_script.flip_count = 3
    
    print("Starting round ", current_round)
    
    # 每几回合解锁新硬币类型
    if current_round == 4:
        print("Unlocked: Stock Coin, Glass Coin")
    elif current_round == 7:
        print("Unlocked: Bitcoin, Stock Market")
    elif current_round == 10:
        print("Unlocked: Lucky Coin, Angel Coin, Demon Coin")
    elif current_round == 15:
        print("Unlocked: Special Coins")

func battle_round():
    print("Battle round started")
    current_state = "battle"
    
    if battle_system_script:
        battle_system_script.enemy_turn()
        battle_system_script.player_turn()

func game_over():
    print("Game Over!")
    current_state = "menu"
    game_started = false

func victory():
    print("Victory!")
    current_state = "menu"
    game_started = false
    # 增加大量金币奖励
