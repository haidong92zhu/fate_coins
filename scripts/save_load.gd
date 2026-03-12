extends Node

# 存档系统
var save_file = "user://fate_coins_save.json"
var game_state: Dictionary = {}

# 默认存档数据
var default_data = {
    "coins": 100,
    "current_round": 1,
    "required_coins": 1,
    "flip_count": 3,
    "max_flip_count": 2,
    "player_health": 100,
    "enemy_health": 100,
    "inventory": [],
    "equipment": {},
    "completed_rounds": 0,
    "total_earnings": 0,
    "achievements": [],
    "shop_items_owned": [],
    "play_time": 0
}

func _ready():
    print("SaveLoadSystem initialized")
    load_game()

func save_game():
    print("Saving game...")
    
    # 收集游戏状态
    game_state = {
        "coins": 100,  # 这里会从游戏状态获取实际值
        "current_round": 1,
        "required_coins": 1,
        "flip_count": 3,
        "max_flip_count": 2,
        "player_health": 100,
        "enemy_health": 100,
        "inventory": [],
        "equipment": {},
        "completed_rounds": 0,
        "total_earnings": 0,
        "achievements": [],
        "shop_items_owned": [],
        "play_time": 0,
        "last_saved": OS.get_datetime_string_from_system()
    }
    
    # 写入文件
    var file = FileAccess.open(save_file, FileAccess.WRITE)
    file.store_string(JSON.stringify(game_state))
    file.close()
    
    print("Game saved successfully!")

func load_game():
    print("Loading game...")
    
    # 检查存档文件是否存在
    if not FileAccess.file_exists(save_file):
        print("No save file found, creating new save...")
        create_default_save()
        return
    
    # 读取文件
    var file = FileAccess.open(save_file, FileAccess.READ)
    var content = file.get_as_text()
    file.close()
    
    # 解析JSON
    var json = JSON.new()
    var error = json.parse(content)
    
    if error == OK:
        game_state = json.data
        print("Game loaded successfully!")
        print("Coins: ", game_state.get("coins", 0))
        print("Round: ", game_state.get("current_round", 1))
    else:
        print("Error loading save file: ", error)
        create_default_save()

func create_default_save():
    print("Creating default save...")
    game_state = default_data.duplicate(true)
    
    # 写入默认存档
    var file = FileAccess.open(save_file, FileAccess.WRITE)
    file.store_string(JSON.stringify(game_state))
    file.close()
    
    print("Default save created!")

func delete_save():
    print("Deleting save...")
    
    if FileAccess.file_exists(save_file):
        DirAccess.remove_absolute(save_file)
        print("Save deleted!")
        create_default_save()
    else:
        print("No save file to delete")

func get_coins() -> int:
    return game_state.get("coins", 100)

func set_coins(amount: int):
    game_state["coins"] = amount
    save_game()

func get_current_round() -> int:
    return game_state.get("current_round", 1)

func set_current_round(round: int):
    game_state["current_round"] = round
    save_game()

func add_achievement(achievement_name: String):
    if achievement_name not in game_state.get("achievements", []):
        game_state["achievements"].append(achievement_name)
        print("Achievement unlocked: ", achievement_name)
        save_game()
