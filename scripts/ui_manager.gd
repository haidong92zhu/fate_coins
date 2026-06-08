extends CanvasLayer

# UI元素引用
@onready var coin_count_label = null
@onready var flip_count_label = null
@onready var round_label = null
@onready var power_label = null
@onready var status_bar = null

# 游戏状态引用
@onready var game_state = null

# 状态条颜色
const COLOR_SUCCESS = Color.RED
const COLOR_FAIL = Color.GREEN
const COLOR_PENDING = Color.GRAY

func _ready():
    print("UIManager initialized")
    load_ui_elements()

func load_ui_elements():
    # 加载UI元素引用（会在Godot编辑器中设置）
    pass

func update_coin_count(count: int):
    if coin_count_label:
        coin_count_label.text = str(count)

func update_flip_count(count: int, max_count: int):
    if flip_count_label:
        flip_count_label.text = "%d/%d" % [count, max_count]

func update_round(round: int):
    if round_label:
        round_label.text = "Round %d" % round

func update_power(power: int):
    if power_label:
        power_label.text = "Attack Power: %d" % power

func update_status_bar(current: int, total: int, results: Array):
    if status_bar:
        status_bar.max_value = total
        status_bar.value = current
        
        # 根据抛掷结果更新颜色
        var success_count = results.count(true) if results.size() > 0 else 0
        var fail_count = results.count(false) if results.size() > 0 else 0
        
        # 简化逻辑：如果有成功就用红色，否则绿色
        if success_count > 0:
            status_bar.tint_progress = COLOR_SUCCESS
        elif fail_count > 0:
            status_bar.tint_progress = COLOR_FAIL
        else:
            status_bar.tint_progress = COLOR_PENDING

func show_notification(text: String):
    print("Notification: ", text)
    # 这里会显示一个通知弹窗
    # 在实际Godot项目中会创建一个Label节点显示文本
