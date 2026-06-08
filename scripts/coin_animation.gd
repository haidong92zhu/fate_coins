extends Node

# 金币动画系统
@onready var tween_node = null

func _ready():
    tween_node = create_tween()

func play_flip_animation(coin: Node2D, duration: float = 0.3):
    print("Playing flip animation for ", coin)
    
    # 创建抛掷动画
    var original_pos = coin.position
    var flip_height = 50.0
    
    var tween = create_tween()
    tween.set_parallel(false)
    
    # 第1次跳跃
    tween.tween_property(coin, "position:y", original_pos.y - flip_height, duration * 0.25)
    tween.tween_property(coin, "position:y", original_pos.y, duration * 0.25)
    
    # 第2次跳跃（更低）
    tween.tween_property(coin, "position:y", original_pos.y - flip_height * 0.5, duration * 0.25)
    tween.tween_property(coin, "position:y", original_pos.y, duration * 0.25)
    
    # 旋转
    tween.parallel().tween_property(coin, "rotation_degrees", 360.0, duration)
    
    # 缩放效果
    tween.parallel().tween_property(coin, "scale", Vector2(1.1, 1.1), duration * 0.5)
    tween.tween_property(coin, "scale", Vector2(1.0, 1.0), duration * 0.5)
    

func play_success_animation(coin: Node2D):
    print("Playing success animation")
    
    # 绿色闪光
    var tween = create_tween()
    tween.tween_property(coin, "modulate", Color.GREEN, 0.1)
    tween.tween_property(coin, "modulate", Color.WHITE, 0.2)

func play_fail_animation(coin: Node2D):
    print("Playing fail animation")
    
    # 红色闪光
    var tween = create_tween()
    tween.tween_property(coin, "modulate", Color.RED, 0.1)
    tween.tween_property(coin, "modulate", Color.WHITE, 0.2)

func play_break_animation(coin: Node2D):
    print("Playing break animation")
    
    # 破碎动画
    var tween = create_tween()
    tween.tween_property(coin, "scale", Vector2(0.1, 0.1), 0.3)
    tween.tween_callback(Callable(self, "hide_coin").bind(coin))

func hide_coin(coin: Node2D):
    coin.queue_free()

func play_collect_animation(coin: Node2D, target_pos: Vector2):
    print("Playing collect animation to ", target_pos)
    
    # 移动到目标位置并消失
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(coin, "position", target_pos, 0.5)
    tween.tween_property(coin, "scale", Vector2(0, 0), 0.5)
    tween.tween_callback(Callable(self, "remove_coin").bind(coin))

func remove_coin(coin: Node2D):
    coin.queue_free()
