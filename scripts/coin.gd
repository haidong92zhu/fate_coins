extends Node2D

class Coin:
    var type: String = "normal"  # normal, reverse, glass, bitcoin, stock, lucky
    var value: int = 1
    var flip_count: int = 0
    var max_flips: int = 3
    var attack_power: int = 1
    var position: Vector2 = Vector2(0, 0)
    
    # 特殊属性
    var break_chance: float = 0.0  # 玻璃硬币破碎概率
    var value_modifier: float = 1.0  # 价值修正
    
    func _init(_type: String = "normal"):
        type = _type
        setup_coin_type()
    
    func setup_coin_type():
        match type:
            "normal":
                value = 1
                attack_power = 1
            "reverse":
                value = 2
                attack_power = 2
                flip_count = 2  # 反面硬币需要2次抛掷
            "glass":
                value = 1
                attack_power = 1
                break_chance = 0.2  # 20%破碎
            "bitcoin":
                value = 50
                attack_power = 10
                max_flips = 999  # 无限制
            "stock":
                value = 10
                attack_power = 5
            "lucky":
                value = 4
                attack_power = 3
                value_modifier = 1.5  # 幸运硬币增加后续价值
    
    func flip() -> Dictionary:
        flip_count += 1
        
        var result = {
            "success": false,
            "value": 0,
            "broke": false,
            "attack_power": attack_power
        }
        
        # 检查是否破碎（玻璃硬币）
        if break_chance > 0 and randf() < break_chance:
            result.broke = true
            return result
        
        # 检查抛掷次数限制
        if flip_count > max_flips:
            return result
        
        # 抛掷逻辑（50%成功率）
        var success_rate = 0.5
        if type == "lucky":
            success_rate = 0.6  # 幸运硬币60%成功
        
        result.success = randf() < success_rate
        
        if result.success:
            result.value = int(value * value_modifier)
        
        return result
