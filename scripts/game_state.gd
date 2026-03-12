extends Node2D

# 玩家金币管理
var coins: int = 100
var flip_count: int = 3
var max_flip_count: int = 2
var coin_attack_power: int = 0

# 游戏状态
var current_round: int = 1
var required_coins: int = 1

func _ready():
    print("GameState initialized")
    print("Initial coins: ", coins)

func flip_coin():
    if flip_count > 0:
        flip_count -= 1
        print("Coin flipped! Remaining flips: ", flip_count)
    else:
        print("No flips remaining!")

func add_coins(amount: int):
    coins += amount
    print("Added ", amount, " coins. Total: ", coins)

func check_round_completion():
    if coins >= required_coins:
        next_round()
    else:
        print("Not enough coins! Required: ", required_coins, ", Have: ", coins)

func next_round():
    current_round += 1
    required_coins = max(1, int(required_coins * 1.3))
    flip_count = 3
    print("Round ", current_round, " started! Required coins: ", required_coins)
