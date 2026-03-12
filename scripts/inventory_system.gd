extends Node

# 库存系统
var items = []  # 存储物品的数组
var max_slots: int = 25  # 最大格数（5x5）

# 物品类型
const TYPE_COIN = "coin"
const TYPE_EQUIPMENT = "equipment"
const TYPE_CONSUMABLE = "consumable"

func _ready():
    print("InventorySystem initialized with ", max_slots, " slots")

func add_item(item_name: String, item_type: String, icon: Texture) -> bool:
    # 检查是否有空位
    if items.size() >= max_slots:
        print("Inventory full!")
        return false
    
    # 检查物品是否已存在（如果是可堆叠的）
    for item in items:
        if item.name == item_name and item.stackable:
            item.count += 1
            print("Item ", item_name, " stacked to ", item.count)
            return true
    
    # 添加新物品
    items.append({
        "name": item_name,
        "type": item_type,
        "icon": icon,
        "count": 1,
        "stackable": item_type == TYPE_COIN
    })
    
    print("Added item: ", item_name, " (", item_type, ")")
    update_ui()
    return true

func remove_item(index: int) -> bool:
    if index >= 0 and index < items.size():
        var item = items[index]
        if item.count > 1:
            item.count -= 1
            print("Removed one ", item.name, ". Remaining: ", item.count)
        else:
            items.remove_at(index)
            print("Removed item: ", item.name)
        
        update_ui()
        return true
    return false

func get_item(index: int) -> Dictionary:
    if index >= 0 and index < items.size():
        return items[index]
    return {}

func get_items_by_type(type: String) -> Array:
    var result = []
    for item in items:
        if item.type == type:
            result.append(item)
    return result

func use_item(index: int) -> bool:
    var item = get_item(index)
    
    if item.size() == 0:
        return false
    
    match item.type:
        TYPE_CONSUMABLE:
            apply_consumable(item)
            return true
        TYPE_EQUIPMENT:
            equip_item(item)
            return true
        _:
            return false

func apply_consumable(item: Dictionary):
    print("Using consumable: ", item.name)
    item.count -= 1
    
    if item.count <= 0:
        remove_item(items.find(item))
    
    # 这里会触发实际效果（根据物品名称）
    match item.name:
        "Bag of Wealth":
            print("Adding 50 starting coins!")
            # 这里的逻辑会由游戏状态处理
        "Health Potion":
            print("Restoring 50 health!")
            # 这里会调用战斗系统

func equip_item(item: Dictionary):
    print("Equipped item: ", item.name)
    # 这里会激活装备效果

func update_ui():
    # 更新库存界面
    # 这里的逻辑会由UI管理器处理
    pass

func clear_inventory():
    items.clear()
    print("Inventory cleared!")
    update_ui()

func get_total_value() -> int:
    var total = 0
    for item in items:
        total += item.count
    return total
