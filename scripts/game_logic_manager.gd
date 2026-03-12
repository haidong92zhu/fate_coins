extends Node

# 游戏状态管理器
onready var game_state = null
onready var grid = null
onready var inventory = null
onready var shop = null
onready var battle = null
onready var ui = null
onready var save_load = null
onready var coin_anim = null

# 游戏阶段
const PHASE_SETUP = "setup"
const PHASE_PLACEMENT = "placement"
const PHASE_FLIPPING = "flipping"
const PHASE_BATTLE = "battle"
const PHASE_SHOP = "shop"
const PHASE_INVENTORY = "inventory"
const PHASE_GAME_OVER = "game_over"
const PHASE_VICTORY = "victory"

var current_phase = PHASE_SETUP
var selected_coin_type = "normal"
var coins_placed = 0
var max_coins = 20  # 4x5网格

func _ready():
    print("GameLogicManager initialized")
    initialize_systems()

func initialize_systems():
    # 初始化所有系统
    if has_node("GameState"):
        game_state = get_node("GameState")
    
    if has_node("Grid"):
        grid = get_node("Grid")
    
    if has_node("Inventory"):
        inventory = get_node("Inventory")
    
    if has_node("Shop"):
        shop = get_node("Shop")
    
    if has_node("BattleSystem"):
        battle = get_node("BattleSystem")
    
    if has_node("UIManager"):
        ui = get_node("UIManager")
    
    if has_node("SaveLoad"):
        save_load = get_node("SaveLoad")
    
    print("All systems initialized!")

func start_new_game():
    print("Starting new game...")
    current_phase = PHASE_SETUP
    coins_placed = 0
    
    # 重置所有系统
    if game_state:
        game_state.coins = 100
        game_state.current_round = 1
        game_state.required_coins = 1
        game_state.flip_count = 3
    
    if inventory:
        inventory.clear_inventory()
    
    if battle:
        battle.enemy_health = 100
        battle.player_health = 100
    
    # 加载存档
    if save_load:
        save_load.load_game()
    
    # 开始放置阶段
    transition_to_phase(PHASE_PLACEMENT)

func transition_to_phase(new_phase: String):
    print("Transitioning from ", current_phase, " to ", new_phase)
    current_phase = new_phase
    update_ui_for_phase(new_phase)

func update_ui_for_phase(phase: String):
    match phase:
        PHASE_SETUP:
            if ui:
                ui.show_notification("Game Started! Place your coins.")
        PHASE_PLACEMENT:
            if ui:
                ui.show_notification("Place coins in the grid.")
        PHASE_FLIPPING:
            if ui:
                ui.show_notification("Click coins to flip them!")
        PHASE_BATTLE:
            if ui:
                ui.show_notification("Battle begins! Roll for damage!")
        PHASE_SHOP:
            if ui:
                ui.show_notification("Welcome to the shop!")
        PHASE_INVENTORY:
            if ui:
                ui.show_notification("Check your inventory.")
        PHASE_GAME_OVER:
            if ui:
                ui.show_notification("Game Over! Try again?")
        PHASE_VICTORY:
            if ui:
                ui.show_notification("Victory! You survived this round!")

func place_coin(coin_type: String, cell_pos: Vector2):
    if current_phase != PHASE_PLACEMENT:
        print("Cannot place coins in phase: ", current_phase)
        return false
    
    if coins_placed >= max_coins:
        print("Max coins reached!")
        return false
    
    # 调用网格系统放置硬币
    if grid:
        if grid.place_coin(cell_pos, coin_type):
            coins_placed += 1
            update_total_power()
            return true
    
    return false

func flip_all_coins():
    if current_phase != PHASE_PLACEMENT:
        return
    
    transition_to_phase(PHASE_FLIPPING)
    
    if game_state:
        game_state.flip_count = game_state.flip_count - coins_placed
    
    if grid:
        grid.flip_coins()
    
    # 检查是否需要进入战斗阶段
    if check_battle_ready():
        transition_to_phase(PHASE_BATTLE)

func check_battle_ready() -> bool:
    return coins_placed > 0  # 只要有硬币就进入战斗

func resolve_battle():
    print("Resolving battle...")
    
    # 计算总攻击力
    var player_power = 0
    if grid:
        player_power = grid.update_total_attack_power()
    
    var enemy_power = 50  # 敌人基础攻击力
    
    if battle:
        battle.update_attack_powers(player_power, enemy_power)
        battle.enemy_turn()
        battle.player_turn()
    
    # 检查结果
    if battle.player_health > 0:
        transition_to_phase(PHASE_VICTORY)
    else:
        transition_to_phase(PHASE_GAME_OVER)

func go_to_shop():
    transition_to_phase(PHASE_SHOP)

func go_to_inventory():
    transition_to_phase(PHASE_INVENTORY)

func next_round():
    print("Next round!")
    coins_placed = 0
    
    # 重置网格
    if grid:
        grid.clear_coins()
    
    # 增加需求
    if game_state:
        game_state.current_round += 1
        game_state.required_coins = max(1, int(game_state.required_coins * 1.3))
        game_state.flip_count = 3
    
    # 更新UI
    if ui:
        ui.update_round(game_state.current_round)
        ui.update_coin_count(game_state.coins)
        ui.update_flip_count(game_state.flip_count, game_state.max_flip_count)
    
    # 保存
    if save_load:
        save_load.save_game()
    
    transition_to_phase(PHASE_PLACEMENT)

func update_total_power():
    var total_power = 0
    if grid:
        total_power = grid.update_total_attack_power()
    
    if ui:
        ui.update_power(total_power)
