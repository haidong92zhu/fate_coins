extends Node

# 战斗系统
var enemy_attack_power: int = 0
var player_attack_power: int = 0
var enemy_health: int = 100
var player_health: int = 100

func _ready():
    print("BattleSystem initialized")

func calculate_damage(attacker_power: int, defender_health: int) -> int:
    # 简单的伤害计算公式
    var damage = attacker_power * 2 + randi() % 10
    print("Damage calculated: ", damage)
    return damage

func enemy_turn():
    print("Enemy turn!")
    var damage = calculate_damage(enemy_attack_power, player_health)
    player_health -= damage
    print("Player health: ", player_health)
    
    if player_health <= 0:
        game_over()

func player_turn():
    print("Player turn!")
    var damage = calculate_damage(player_attack_power, enemy_health)
    enemy_health -= damage
    print("Enemy health: ", enemy_health)
    
    if enemy_health <= 0:
        victory()

func update_attack_powers(player_power: int, enemy_power: int):
    player_attack_power = player_power
    enemy_attack_power = enemy_power
    print("Player power: ", player_attack_power, ", Enemy power: ", enemy_attack_power)

func game_over():
    print("Game Over!")
    # 显示游戏结束界面
    # 返回主菜单

func victory():
    print("Victory!")
    # 显示胜利界面
    # 增加金币奖励
