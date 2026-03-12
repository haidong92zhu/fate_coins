extends Node

# 商店系统
var player_money: int = 100

# 商品列表
var shop_items = [
    {
        "name": "Lucky Coin",
        "description": "Increases future coin value by 1.5x",
        "price": 20,
        "type": "coin",
        "owned": false
    },
    {
        "name": "Amulet of Speed",
        "description": "Adds 1 extra flip chance per round",
        "price": 50,
        "type": "equipment",
        "owned": false
    },
    {
        "name": "Shield of Fortune",
        "description": "Protects against critical failures",
        "price": 75,
        "type": "equipment",
        "owned": false
    },
    {
        "name": "Bag of Wealth",
        "description": "Increases starting coin by 50",
        "price": 100,
        "type": "consumable",
        "owned": false
    }
]

func _ready():
    print("ShopSystem initialized with ", shop_items.size(), " items")

func buy_item(index: int):
    if index < 0 or index >= shop_items.size():
        return false
    
    var item = shop_items[index]
    
    if player_money >= item.price:
        player_money -= item.price
        apply_item(item)
        return true
    else:
        print("Not enough money! Need: ", item.price, ", Have: ", player_money)
        return false

func apply_item(item: Dictionary):
    match item.type:
        "coin":
            print("Purchased coin: ", item.name)
            # 这里会添加到库存
        "equipment":
            print("Equipped item: ", item.name)
            # 这里会激活装备效果
        "consumable":
            print("Used consumable: ", item.name)
            # 这里会应用一次性效果

func get_item(index: int) -> Dictionary:
    if index >= 0 and index < shop_items.size():
        return shop_items[index]
    return {}

func check_affordability(price: int) -> bool:
    return player_money >= price
